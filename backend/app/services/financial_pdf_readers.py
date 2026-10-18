"""Local PDF layouts, with page evidence. No OCR, AI, accounts or payment writes."""
import datetime
import io
import re
import unicodedata
from decimal import Decimal

from app.schemas.financial_imports import FinancialStatementCreate, FinancialTransactionData

MAX_PAGES = 40
MAX_CHARS = 200000
MAX_WORDS = 50000
MONTHS = {name: i for i, name in enumerate("JAN FEV MAR ABR MAI JUN JUL AGO SET OUT NOV DEZ".split(), 1)}
LONG_MONTHS = {name: i for i, name in enumerate("JANEIRO FEVEREIRO MARCO ABRIL MAIO JUNHO JULHO AGOSTO SETEMBRO OUTUBRO NOVEMBRO DEZEMBRO".split(), 1)}
MONEY = r"[+\-−]?(?:R\$\s*)?\d+(?:\.\d{3})*,\d{2}"


def normalized(text):
    return "".join(c for c in unicodedata.normalize("NFD", text.upper()) if not unicodedata.combining(c))


def cents(value):
    cleaned = value.replace("R$", "").replace(" ", "").replace("−", "-")
    if not re.fullmatch(r"[+-]?\d+(?:\.\d{3})*,\d{2}", cleaned):
        raise ValueError("amount")
    return int(Decimal(cleaned.replace(".", "").replace(",", ".")) * 100)


def empty_report():
    return {"items": [], "errors": [], "warnings": [], "complete": True, "rows_read": 0,
            "blank_records": 0, "pages": [], "extracted_header": {}, "field_sources": {}, "checks": [],
            "totals": {"positive_cents": 0, "negative_cents": 0, "net_cents": 0}, "observed_dates": None}


def error(report, code, page=None):
    report["errors"].append({"code": code, "page_number": page, "fields": []})


def group_words(words):
    groups = []
    for word in sorted(words, key=lambda w: ((w["top"] + w["bottom"]) / 2, w["x0"])):
        center = (word["top"] + word["bottom"]) / 2
        if not groups or abs(center - groups[-1][0]) > 3.5:
            groups.append([center, []])
        groups[-1][1].append(word)
    lines = []
    for _, group in groups:
        group.sort(key=lambda w: w["x0"])
        lines.append({"text": " ".join(w["text"] for w in group), "words": group,
                      "bbox": [min(w["x0"] for w in group), min(w["top"] for w in group),
                               max(w["x1"] for w in group), max(w["bottom"] for w in group)]})
    return lines


def extract_pages(content, report, password=None):
    import pdfplumber
    from pdfminer.pdfdocument import PDFPasswordIncorrect
    try:
        with pdfplumber.open(io.BytesIO(content), unicode_norm="NFC", password=password) as pdf:
            if not 0 < len(pdf.pages) <= MAX_PAGES:
                error(report, "PDF_PAGE_LIMIT")
                report["complete"] = False
                return []
            pages, words_count, text_count = [], 0, 0
            for page in pdf.pages:
                words = page.extract_words(extra_attrs=["non_stroking_color"])
                words_count += len(words)
                lines = group_words(words)
                text = "\n".join(line["text"] for line in lines)
                text_count += len(text)
                if words_count > MAX_WORDS or text_count > MAX_CHARS or any(len(l["text"]) > 8000 for l in lines):
                    error(report, "PDF_CONTENT_LIMIT", page.page_number)
                    report["complete"] = False
                    return []
                if not words:
                    error(report, "PDF_OCR_OR_TEXT_REQUIRED", page.page_number)
                pages.append({"page_number": page.page_number, "width": page.width, "height": page.height,
                              "text": text, "lines": lines})
                page.close()
            return pages
    except PDFPasswordIncorrect:
        error(report, "PDF_PASSWORD_REQUIRED")
    except Exception:
        error(report, "PDF_INVALID_OR_UNREADABLE")
    report["complete"] = False
    return []


def record_header(report, field, value, page, raw):
    old = report["extracted_header"].get(field)
    if old is not None and old != value:
        error(report, "PDF_CONFLICTING_HEADER", page)
        return
    report["extracted_header"][field] = value
    report["field_sources"].setdefault(field, {"page_number": page, "raw_text": raw})


def partial_date(day, month, anchor):
    # The bank prints no year on these rows. Keep this derivation visible in
    # the preview; it is not a separately asserted purchase date.
    date = datetime.date(anchor.year, month, int(day))
    if date > anchor:
        date = date.replace(year=date.year - 1)
    return date.isoformat()


def find_in_pages(pages, pattern):
    for page in pages:
        match = re.search(pattern, normalized(page["text"]))
        if match:
            return page["page_number"], match
    return None, None


def amount_at_right(line, width, fraction=.65):
    matches = list(re.finditer(MONEY + r"$", line["text"]))
    if not matches:
        return None
    amount = matches[-1]
    last = line["words"][-1]
    if last["x0"] < width * fraction:
        return None
    return amount, last


def add_item(report, page, line, date, amount, description, **extra):
    report["rows_read"] += 1
    try:
        if report["rows_read"] > 2000:
            raise ValueError("limit")
        data = FinancialTransactionData(transaction_date=date, amount_cents=amount, description=description,
                                        **extra).model_dump(mode="json")
    except (ValueError, OverflowError):
        error(report, "PDF_INVALID_TRANSACTION", page)
        return
    report["items"].append({"position": report["rows_read"], "page_number": page,
                            "raw_text": line["text"], "bbox": line["bbox"], "data": data})


def is_green(color):
    return isinstance(color, (list, tuple)) and len(color) == 3 and all(
        abs(float(a) - b) < .002 for a, b in zip(color, (.42353, .75686, .0549)))


def is_grayscale(color):
    if isinstance(color, (int, float)):
        return 0 <= color <= 1
    return isinstance(color, (list, tuple)) and len(color) in (1, 3) and max(color) - min(color) < .002


def parse_card(pages, report, institution):
    header = report["extracted_header"]
    record_header(report, "statement_type", "CARD_BILL", 1, "Detected card bill layout")
    if institution == "NUBANK":
        due_page, due = find_in_pages(pages, r"FATURA\s+(\d{2})\s+([A-Z]{3})\s+(\d{4})")
        if due is None:
            error(report, "PDF_BILL_HEADER_REQUIRED")
            return
        due_date = datetime.date(int(due[3]), MONTHS[due[2]], int(due[1]))
        period_page, period = find_in_pages(pages, r"(?:TRANSACOES\s+)?DE\s+(\d{2})\s+([A-Z]{3})\s+A\s+(\d{2})\s+([A-Z]{3})")
        if period:
            end = datetime.date.fromisoformat(partial_date(period[3], MONTHS[period[4]], due_date))
            start = datetime.date.fromisoformat(partial_date(period[1], MONTHS[period[2]], end))
            record_header(report, "period_start", start.isoformat(), period_page, period[0])
            record_header(report, "period_end", end.isoformat(), period_page, period[0])
        anchor = datetime.date.fromisoformat(header.get("period_end", due_date.isoformat()))
    elif institution == "PICPAY":
        due_page, due = find_in_pages(pages, r"VENCIMENTO:\s*(\d{2})-(\d{2})-(\d{4})")
        close_page, close = find_in_pages(pages, r"FECHAMENTO:\s*(\d{2})-(\d{2})-(\d{4})")
        if due is None or close is None:
            error(report, "PDF_BILL_HEADER_REQUIRED")
            return
        due_date = datetime.date(int(due[3]), int(due[2]), int(due[1]))
        anchor = datetime.date(int(close[3]), int(close[2]), int(close[1]))
        record_header(report, "closing_on", anchor.isoformat(), close_page, close[0])
    else:
        due_page, due = find_in_pages(pages, r"VENCIMENTO[:\s]+(\d{2})[/.-](\d{2})[/.-](\d{4})")
        if due is None:
            due_page, due = find_in_pages(pages, r"VENCIMENTO\s+(\d{2})\s+([A-Z]{3})\s+(\d{4})")
            if due is not None:
                due_date = datetime.date(int(due[3]), MONTHS[due[2]], int(due[1]))
            else:
                error(report, "PDF_BILL_HEADER_REQUIRED")
                return
        else:
            due_date = datetime.date(int(due[3]), int(due[2]), int(due[1]))
        close_page, close = find_in_pages(pages, r"(?:FECHAMENTO|MELHOR DIA)[:\s]+(\d{2})[/.-](\d{2})[/.-](\d{4})")
        if close is not None:
            anchor = datetime.date(int(close[3]), int(close[2]), int(close[1]))
            record_header(report, "closing_on", anchor.isoformat(), close_page, close[0])
        else:
            anchor = due_date
    record_header(report, "due_on", due_date.isoformat(), due_page, due[0])
    report["warnings"].append({"code": "PDF_PARTIAL_DATE_YEAR_FROM_BILL_CONTEXT"})
    for page in pages:
        for index, line in enumerate(page["lines"]):
            n = normalized(line["text"])
            minimum = re.fullmatch(r"PAGAMENTO MINIMO\s+(" + MONEY + r")", n)
            if institution == "NUBANK" and minimum:
                record_header(report, "minimum_payment_cents", cents(minimum[1]), page["page_number"], line["text"])
            if institution == "PICPAY" and page["page_number"] == 1 and n == "PAGAMENTO MINIMO PAGAMENTO TOTAL" and index + 1 < len(page["lines"]):
                values_line = page["lines"][index + 1]["text"]
                values = re.fullmatch(r"(" + MONEY + r")\s+(" + MONEY + r")", values_line)
                if values:
                    record_header(report, "minimum_payment_cents", cents(values[1]), 1, line["text"] + "\n" + values_line)
    # Header controls are read only from the summary section, never offers/CET.
    summary = {}
    def summary_value(field, value, page, raw):
        if field in summary and summary[field] != value:
            error(report, "PDF_CONFLICTING_HEADER", page)
        else:
            summary[field] = value
            report["field_sources"].setdefault("summary." + field, {"page_number": page, "raw_text": raw})

    for page in pages:
        summary_page = ("RESUMO DA FATURA ATUAL" in normalized(page["text"]) if institution == "NUBANK"
                        else page["page_number"] == 1)
        if not summary_page:
            continue
        for line in page["lines"]:
            n = normalized(line["text"])
            right = amount_at_right(line, page["width"])
            if not right:
                continue
            match, last = right
            value = cents(match[0])
            if is_green(last.get("non_stroking_color")):
                value = -abs(value)
            if n.startswith(("TOTAL A PAGAR", "TOTAL DA FATURA", "TOTAL DA SUA FATURA", "TOTAL DESTA FATURA")):
                record_header(report, "total_amount_cents", abs(value), page["page_number"], line["text"])
            elif n.startswith("PAGAMENTO MINIMO"):
                record_header(report, "minimum_payment_cents", abs(value), page["page_number"], line["text"])
            elif n.startswith(("FATURA ANTERIOR", "SALDO ANTERIOR")):
                summary_value("previous", abs(value), page["page_number"], line["text"])
            elif n.startswith(("PAGAMENTO RECEBIDO", "PAGAMENTOS EFETUADOS", "PAGAMENTO EFETUADO")):
                summary_value("payments", -abs(value), page["page_number"], line["text"])
            elif n.startswith(("TOTAL DE COMPRAS", "DESPESAS DO MES", "COMPRAS DO MES", "COMPRAS NACIONAIS")):
                summary_value("purchases", value, page["page_number"], line["text"])
            elif n.startswith(("OUTROS LANCAMENTOS", "CREDITOS E ESTORNOS", "ENCARGOS", "OUTROS CREDITOS")):
                summary_value("other", value, page["page_number"], line["text"])
    report["reported_summary"] = summary
    if "total_amount_cents" not in header:
        error(report, "PDF_BILL_HEADER_REQUIRED")
    sections = []

    def finish_section():
        if not sections or "matches" in sections[-1]:
            return
        section = sections[-1]
        actual = sum(i["data"]["amount_cents"] for i in report["items"][section["first_position"] - 1:])
        tol = 10 if section.get("kind") == "PAYMENTS_AND_FINANCING" else 0
        matches = abs(actual - section["reported_amount_cents"]) <= tol
        section.update(last_position=len(report["items"]), observed_amount_cents=actual,
                       matches=matches)
        report["checks"].append({"code": "PDF_SECTION_TOTAL", "matches": section["matches"]})

    for page in pages:
        upper_page = normalized(page["text"])
        if institution == "NUBANK" and "TRANSACOES" not in upper_page:
            continue
        if institution == "PICPAY" and "TRANSACOES NACIONAIS" not in upper_page:
            continue
        if institution in ("ITAU", "SANTANDER", "INTER") and not any(k in upper_page for k in ("TRANSACOES", "LANCAMENTOS", "DEMONSTRATIVO", "COMPRAS")):
            continue
        card = None
        in_table = False
        for line in page["lines"]:
            n = normalized(line["text"])
            if re.match(r"^TRANSACOES(?: DE |$)", n) or n in ("TRANSACOES NACIONAIS", "LANCAMENTOS", "DEMONSTRATIVO", "COMPRAS"):
                in_table = True
                continue
            final = re.search(r"(?:PICPAY CARD|CARTAO|FINAL)\s+(?:FINAL\s+)?(\d{4})", n)
            if final:
                card = final[1]
            if not in_table:
                continue
            pattern = r"^(\d{2})\s+([A-Z]{3})\s+" if institution == "NUBANK" else r"^(\d{2})[/.-](\d{2})\s+"
            date = re.match(pattern, n)
            fraction = .4 if institution == "PICPAY" else (.5 if institution in ("ITAU", "SANTANDER", "INTER") else .65)
            right = amount_at_right(line, page["width"], fraction)
            if institution == "NUBANK" and not date and right:
                match, _ = right
                label = normalized(line["text"][:match.start()].strip())
                # The newer layout prints the holder's purchase subtotal before
                # masked-card rows. Bind that heading to the independently read
                # purchase control and validate every section; never hardcode a
                # person's name or discard an arbitrary money-bearing row.
                purchase_heading = (not report["items"] and not sections and "••••" in page["text"]
                    and match[0].startswith("R$") and cents(match[0]) == summary.get("purchases")
                    and 0 < len(label) <= 120 and not re.search(r"\d", label)
                    and line["bbox"][0] < page["width"] * .3)
                financing_heading = label == "PAGAMENTOS E FINANCIAMENTOS" and bool(sections)
                if purchase_heading or financing_heading:
                    finish_section()
                    sections.append({"kind": "PURCHASES" if purchase_heading else "PAYMENTS_AND_FINANCING",
                        "page_number": page["page_number"], "raw_text": line["text"],
                        "reported_amount_cents": cents(match[0]), "first_position": len(report["items"]) + 1})
                    continue
            if not date or not right:
                # Preserve note lines beneath the last transaction as evidence.
                if report["items"] and report["items"][-1]["page_number"] == page["page_number"] and n.startswith(("REFERENTE", "•", "VALOR ORIGINAL")):
                    report["items"][-1]["raw_text"] += "\n" + line["text"]
                if date and not right:
                    error(report, "PDF_UNPARSED_DATED_ROW", page["page_number"])
                elif right and not n.startswith(("SUBTOTAL", "TOTAL GERAL", "TOTAL A PAGAR", "REFERENTE", "•", "VALOR ORIGINAL")):
                    # Equal omitted credits/debits could cancel in the totals.
                    # An unknown money-bearing row must not silently disappear.
                    error(report, "PDF_UNPARSED_MONEY_ROW", page["page_number"])
                continue
            match, last = right
            amount = cents(match[0])
            description = line["text"][date.end():match.start()].strip()
            # New Nubank layout carries masked plastic identification before name.
            number = re.match(r"[•●·.]{4}\s*(\d{4})\s+", description)
            if number:
                card = number[1]
                description = description[number.end():]
            else:
                card = card if institution == "PICPAY" else None
            if institution == "NUBANK" and not match[0].startswith(("-", "−", "+")):
                color = last.get("non_stroking_color")
                if is_green(color):
                    amount = -abs(amount)
                elif not is_grayscale(color):
                    error(report, "PDF_AMOUNT_SIGN_AMBIGUOUS", page["page_number"])
                    continue
            month = MONTHS[date[2]] if institution == "NUBANK" else int(date[2])
            extra = {"card_last_four": card} if card else {}
            installment = re.search(r"(?:PARCELA\s*|PARC\s*| -\s*)(\d{1,3})/(\d{1,3})\s*$", description, re.I)
            if installment:
                extra.update(installment_number=int(installment[1]), total_installments=int(installment[2]))
            add_item(report, page["page_number"], line, partial_date(date[1], month, anchor), amount, description, **extra)
    finish_section()
    report["section_controls"] = sections
    if len(summary) == 4 and "total_amount_cents" in header:
        net = sum(i["data"]["amount_cents"] for i in report["items"])
        expected_net = summary["payments"] + summary["purchases"] + summary["other"]
        tol = 10 if sections and any(s.get("kind") == "PAYMENTS_AND_FINANCING" for s in sections) else 0
        report["checks"].append({"code": "PDF_REPORTED_BILL_EQUATION", "matches": summary["previous"] + expected_net == header["total_amount_cents"]})
        report["checks"].append({"code": "PDF_SUMMARY_DETAILS", "matches": abs(net - expected_net) <= tol})
        if not all(c["matches"] for c in report["checks"]):
            error(report, "PDF_SUMMARY_DETAIL_MISMATCH")
    elif "total_amount_cents" in header and report["items"]:
        net = sum(i["data"]["amount_cents"] for i in report["items"])
        report["checks"].append({"code": "PDF_SECTION_TOTAL", "matches": net == header["total_amount_cents"]})
        if not all(c["matches"] for c in report["checks"]):
            error(report, "PDF_SUMMARY_DETAIL_MISMATCH")
    else:
        error(report, "PDF_SUMMARY_CONTROLS_REQUIRED")


def parse_account(pages, report):
    header = report["extracted_header"]
    record_header(report, "statement_type", "BANK_STATEMENT", 1, "Detected bank statement layout")
    first = pages[0]
    period = re.search(r"(\d{2}) DE ([A-Z]+) DE (\d{4}) A (\d{2}) DE ([A-Z]+) DE (\d{4})", normalized(first["text"]))
    if not period:
        error(report, "PDF_BANK_PERIOD_REQUIRED")
        return
    for name, offset in (("period_start", 0), ("period_end", 3)):
        value = datetime.date(int(period[3 + offset]), LONG_MONTHS[period[2 + offset]], int(period[1 + offset]))
        record_header(report, name, value.isoformat(), 1, period[0])
    for line in first["lines"]:
        n = normalized(line["text"])
        for label, field in (("SALDO INICIAL", "opening_balance_cents"), ("SALDO FINAL DO PERIODO", "closing_balance_cents"),
                             ("TOTAL DE ENTRADAS", "total_inflows_cents"), ("TOTAL DE SAIDAS", "total_outflows_cents")):
            match = re.search(label + r"\s+([+\-]?\s*\d+(?:\.\d{3})*,\d{2})$", n)
            if match:
                value = cents(match[1])
                record_header(report, field, abs(value) if field.startswith("total_") else value, 1, line["text"])
        if n == "MOVIMENTACOES":
            break
    current_date, direction = None, None
    for page in pages:
        in_body = False
        for line in page["lines"]:
            n = normalized(line["text"])
            if page["page_number"] > 1 and re.search(r"\d{2} DE [A-Z]+ DE \d{4} A \d{2} DE [A-Z]+ DE \d{4}", n):
                in_body = True
                continue
            if n == "MOVIMENTACOES":
                in_body = True
                continue
            if n.startswith(("TEM ALGUMA DUVIDA", "O SALDO LIQUIDO", "NAO NOS RESPONSABILIZAMOS", "ASSEGURAMOS")):
                in_body = False
            if not in_body:
                continue
            date = re.match(r"^(\d{2})\s+([A-Z]{3})\s+(\d{4})\s+", n)
            if date:
                current_date = datetime.date(int(date[3]), MONTHS[date[2]], int(date[1])).isoformat()
            if "TOTAL DE ENTRADAS" in n or "TOTAL DE SAIDAS" in n:
                direction = 1 if "TOTAL DE ENTRADAS" in n else -1
                continue
            right = amount_at_right(line, page["width"])
            if right:
                match, _ = right
                if current_date is None or direction is None:
                    # Repeated statement headers have money only before the period.
                    if page["page_number"] > 1 and not re.match(r"^(SALDO|TOTAL|R\$)", n):
                        error(report, "PDF_BANK_CONTEXT_REQUIRED", page["page_number"])
                    continue
                description = line["text"][:match.start()].strip()
                if normalized(description).startswith(("SALDO", "CPF", "CNPJ")):
                    continue
                add_item(report, page["page_number"], line, current_date, abs(cents(match[0])) * direction, description)
            elif report["items"] and current_date and not date:
                # Full counterpart continuation remains in raw evidence; no guessed parsing.
                if not re.match(r"^\d+ DE \d+$", n) and len(report["items"][-1]["raw_text"]) + len(line["text"]) < 8000:
                    report["items"][-1]["raw_text"] += "\n" + line["text"]
    amounts = [i["data"]["amount_cents"] for i in report["items"]]
    for field, actual in (("total_inflows_cents", sum(a for a in amounts if a > 0)),
                          ("total_outflows_cents", -sum(a for a in amounts if a < 0))):
        if field not in header:
            error(report, "PDF_BANK_CONTROLS_REQUIRED")
        else:
            report["checks"].append({"code": "PDF_" + field.upper(), "matches": header[field] == actual})
    if "opening_balance_cents" in header and "closing_balance_cents" in header:
        report["checks"].append({"code": "PDF_BALANCE_EQUATION", "matches": header["opening_balance_cents"] + sum(amounts) == header["closing_balance_cents"]})
    else:
        error(report, "PDF_BANK_CONTROLS_REQUIRED")
    if not all(c["matches"] for c in report["checks"]):
        error(report, "PDF_BANK_TOTAL_MISMATCH")


def parse_tabular_statement(pages, report):
    whole = normalized("\n".join(p["text"] for p in pages))
    is_card = "FATURA" in whole or "CARD" in whole
    st_type = "CARD_BILL" if is_card else "BANK_STATEMENT"
    inst = "NUBANK" if ("NUBANK" in whole or "NU PAGAMENTOS" in whole) else "OTHER"
    report.update(detected_reader="tabular_statement_pdf_v1", detected_source_type=st_type, detected_institution=inst)
    record_header(report, "statement_type", st_type, 1, "Layout tabular de extrato/fatura")
    for page in pages:
        m_due = re.search(r"VENCIMENTO\s+(\d{2})/(\d{2})/(\d{4})", normalized(page["text"]))
        if m_due:
            d, m, y = m_due[1], m_due[2], m_due[3]
            record_header(report, "due_on", f"{y}-{m}-{d}", page["page_number"], m_due[0])
            break
    for page in pages:
        in_table = False
        for line in page["lines"]:
            n = normalized(line["text"])
            if any(h in n for h in ("DATE TITLE AMOUNT", "DATA TITULO VALOR", "DATA LANCAMENTO VALOR", "FATURA_REFERENCIA DATA_LANCAMENTO")):
                in_table = True
                continue
            if not in_table:
                continue
            m = re.match(r"^(\d{4}-\d{2}-\d{2})\s+(.+?)\s+([+\-]?\s*\d+(?:\.\d{3})*,\d{2})$", line["text"].strip())
            m2 = re.match(r"^\d{4}-\d{2}-\d{2}\s+(\d{4}-\d{2}-\d{2})\s+(.+?)\s+([+\-]?\s*\d+(?:\.\d{3})*,\d{2})(?:\s+.*)?$", line["text"].strip()) if not m else None
            matched = m or m2
            if matched:
                tx_date, desc, amt_str = matched[1], matched[2].strip(), matched[3].replace(" ", "").replace("−", "-")
                amt = cents(amt_str)
                add_item(report, page["page_number"], line, tx_date, amt, desc)
    if report["items"]:
        total = sum(i["data"]["amount_cents"] for i in report["items"])
        if is_card and "total_amount_cents" not in report["extracted_header"]:
            record_header(report, "total_amount_cents", total, 1, "Total calculado dos itens")
        dates = [i["data"]["transaction_date"] for i in report["items"]]
        if "period_start" not in report["extracted_header"] and dates:
            record_header(report, "period_start", min(dates), 1, "Data inicial observada")
            record_header(report, "period_end", max(dates), 1, "Data final observada")
        if "due_on" not in report["extracted_header"] and dates and is_card:
            record_header(report, "due_on", max(dates), 1, "Vencimento inferido da ultima data")


def parse_local(content, password=None):
    report = empty_report()
    pages = extract_pages(content, report, password=password)
    # Public page text is available for unknown layouts too; geometry stays internal.
    report["pages"] = [{"page_number": p["page_number"], "text": p["text"]} for p in pages]
    report["pages_count"] = len(pages)
    if not pages or report["errors"]:
        return report
    whole = normalized("\n".join(p["text"] for p in pages))
    try:
        if ("NU PAGAMENTOS" in whole or "NUBANK" in whole or "NU FINANCEIRA" in whole) and "MOVIMENTACOES" in whole and "SALDO INICIAL" in whole:
            report.update(detected_reader="nubank_account_pdf_v1", detected_source_type="BANK_ACCOUNT", detected_institution="NUBANK")
            parse_account(pages, report)
        elif "RESUMO DA FATURA ATUAL" in whole and "FATURA" in whole and ("NUBANK" in whole or "NU PAGAMENTOS" in whole):
            report.update(detected_reader="nubank_card_pdf_v1", detected_source_type="CREDIT_CARD", detected_institution="NUBANK")
            parse_card(pages, report, "NUBANK")
        elif "PICPAY" in whole and "TOTAL DA FATURA" in whole and "TRANSACOES NACIONAIS" in whole:
            report.update(detected_reader="picpay_card_pdf_v1", detected_source_type="CREDIT_CARD", detected_institution="PICPAY")
            parse_card(pages, report, "PICPAY")
        elif ("ITAU" in whole or "CLICK" in whole) and ("TOTAL DA SUA FATURA" in whole or "TOTAL DA FATURA" in whole or "RESUMO DA FATURA" in whole or "FATURA" in whole) and any(k in whole for k in ("LANCAMENTOS", "TRANSACOES", "COMPRAS")):
            report.update(detected_reader="itau_card_pdf_v1", detected_source_type="CREDIT_CARD", detected_institution="ITAU")
            parse_card(pages, report, "ITAU")
        elif "SANTANDER" in whole and ("TOTAL DA SUA FATURA" in whole or "TOTAL DA FATURA" in whole or "FATURA" in whole) and any(k in whole for k in ("DEMONSTRATIVO", "TRANSACOES", "COMPRAS")):
            report.update(detected_reader="santander_card_pdf_v1", detected_source_type="CREDIT_CARD", detected_institution="SANTANDER")
            parse_card(pages, report, "SANTANDER")
        elif ("INTER" in whole or "BANCO INTER" in whole) and ("TOTAL DA FATURA" in whole or "FATURA" in whole) and any(k in whole for k in ("TRANSACOES", "LANCAMENTOS", "EXTRATO")):
            report.update(detected_reader="inter_card_pdf_v1", detected_source_type="CREDIT_CARD", detected_institution="INTER")
            parse_card(pages, report, "INTER")
        elif any(h in whole for h in ("DATE TITLE AMOUNT", "DATA TITULO VALOR", "DATA LANCAMENTO VALOR", "FATURA_REFERENCIA")):
            parse_tabular_statement(pages, report)
        else:
            error(report, "PDF_LAYOUT_UNSUPPORTED")
    except (ValueError, KeyError, OverflowError):
        error(report, "PDF_LAYOUT_AMBIGUOUS")
    if not report["items"] and not report["errors"]:
        error(report, "PDF_NO_TRANSACTIONS")
    if not report["errors"]:
        try:
            FinancialStatementCreate(document_id="pdf", source_id="pdf", **report["extracted_header"],
                items=[{k: v for k, v in item.items() if k in {"position", "page_number", "raw_text", "data"}}
                       for item in report["items"]])
        except ValueError:
            error(report, "PDF_INVALID_HEADER_OR_ITEMS")
    amounts = [i["data"]["amount_cents"] for i in report["items"]]
    report["totals"] = {"positive_cents": sum(a for a in amounts if a > 0), "negative_cents": -sum(a for a in amounts if a < 0), "net_cents": sum(amounts)}
    dates = [i["data"]["transaction_date"] for i in report["items"]]
    report["observed_dates"] = {"first": min(dates), "last": max(dates)} if dates else None
    report["warnings"].append({"code": "PDF_VERIFY_SELECTED_SOURCE_AND_ORIGINAL"})
    return report
