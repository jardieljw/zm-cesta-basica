"""Bounded, deterministic file readers, independent of persistence and bank accounts.

Every adapter returns the same evidence contract. Values are never evaluated as
formulas. Raw records and the uploaded original remain available for inspection.
"""
import csv
import datetime
import io
import re
from dataclasses import dataclass
from decimal import Decimal

from pydantic import ValidationError

from app.schemas.financial_imports import FinancialTransactionData
from app.schemas.financial_readers import CSVOptions
from app.services.financial_normalization import normalize_card_data, control_kind

MAX_ROWS = 2000
MAX_COLUMNS = 100
MAX_RECORD_CHARS = 8000
MAX_PHYSICAL_LINES = 10000


@dataclass(frozen=True)
class CSVReader:
    id: str
    version: str
    options: CSVOptions | None = None
    media_type: str = "text/csv"


import unicodedata


def normalized(text: str) -> str:
    return "".join(c for c in unicodedata.normalize("NFD", text.upper()) if not unicodedata.combining(c)).strip()


READERS = {
    "pdf_auto": CSVReader("pdf_auto", "4", media_type="application/pdf"),
    "csv_auto": CSVReader("csv_auto", "2"),
    "generic_csv": CSVReader("generic_csv", "4"),
    "nubank_account_csv": CSVReader("nubank_account_csv", "3", CSVOptions(
        columns={"transaction_date": "Data", "amount": "Valor", "external_id": "Identificador", "description": "Descrição"},
        date_format="DD/MM/YYYY", decimal_separator=".", amount_convention="CREDITS_POSITIVE",
        external_id_namespace="nubank:account",
    )),
    "nubank_card_csv": CSVReader("nubank_card_csv", "3", CSVOptions(
        columns={"transaction_date": "date", "description": "title", "amount": "amount"},
        date_format="YYYY-MM-DD", decimal_separator=",", thousands_separator=".", amount_convention="CHARGES_POSITIVE",
        amount_sign_spacing="OPTIONAL_SINGLE_SPACE", date_kind="PURCHASE",
    )),
    "nu_empresas_account_csv": CSVReader("nu_empresas_account_csv", "3", CSVOptions(
        columns={"transaction_date": "Data", "amount": "Valor", "external_id": "Identificador", "description": "Descrição"},
        date_format="DD/MM/YYYY", decimal_separator=".", amount_convention="CREDITS_POSITIVE",
        external_id_namespace="nubank:pj_account",
    )),
    "itau_account_csv": CSVReader("itau_account_csv", "3", CSVOptions(
        columns={"transaction_date": "Data", "description": "Lançamento", "amount": "Valor"},
        delimiter=";", date_format="DD/MM/YYYY", decimal_separator=",", thousands_separator=".",
        amount_convention="CREDITS_POSITIVE",
    )),
    "itau_card_csv": CSVReader("itau_card_csv", "3", CSVOptions(
        columns={"transaction_date": "Data", "description": "Lançamento", "amount": "Valor"},
        delimiter=";", date_format="DD/MM/YYYY", decimal_separator=",", thousands_separator=".",
        amount_convention="CHARGES_POSITIVE", date_kind="PURCHASE",
    )),
    "santander_account_csv": CSVReader("santander_account_csv", "3", CSVOptions(
        columns={"transaction_date": "Data", "description": "Histórico", "amount": "Valor", "external_id": "Documento"},
        delimiter=";", date_format="DD/MM/YYYY", decimal_separator=",", thousands_separator=".",
        amount_convention="CREDITS_POSITIVE", external_id_namespace="santander:account",
    )),
    "santander_card_csv": CSVReader("santander_card_csv", "3", CSVOptions(
        columns={"transaction_date": "Data", "description": "Descricao", "amount": "Valor"},
        delimiter=";", date_format="DD/MM/YYYY", decimal_separator=",", thousands_separator=".",
        amount_convention="CHARGES_POSITIVE", date_kind="PURCHASE",
    )),
    "inter_account_csv": CSVReader("inter_account_csv", "3", CSVOptions(
        columns={"transaction_date": "Data Lançamento", "description": "Histórico", "amount": "Valor"},
        delimiter=";", date_format="DD/MM/YYYY", decimal_separator=",", thousands_separator=".",
        amount_convention="CREDITS_POSITIVE",
    )),
    "inter_card_csv": CSVReader("inter_card_csv", "3", CSVOptions(
        columns={"transaction_date": "Data", "description": "Descricao", "amount": "Valor"},
        delimiter=";", date_format="DD/MM/YYYY", decimal_separator=",", thousands_separator=".",
        amount_convention="CHARGES_POSITIVE", date_kind="PURCHASE",
    )),
    "mercadopago_csv": CSVReader("mercadopago_csv", "3", CSVOptions(
        columns={"transaction_date": "Data", "description": "Descrição", "amount": "Valor"},
        delimiter=";", date_format="DD/MM/YYYY", decimal_separator=",", thousands_separator=".",
        amount_convention="CREDITS_POSITIVE",
    )),
    "bb_account_csv": CSVReader("bb_account_csv", "3", CSVOptions(
        columns={"transaction_date": "Data", "description": "Historico", "amount": "Valor", "external_id": "Numero do Documento"},
        delimiter=";", date_format="DD/MM/YYYY", decimal_separator=",", thousands_separator=".",
        amount_convention="CREDITS_POSITIVE", external_id_namespace="bb:account",
    )),
    "bradesco_account_csv": CSVReader("bradesco_account_csv", "3", CSVOptions(
        columns={"transaction_date": "Data", "description": "Histórico", "amount": "Valor", "external_id": "Docto."},
        delimiter=";", date_format="DD/MM/YYYY", decimal_separator=",", thousands_separator=".",
        amount_convention="CREDITS_POSITIVE", external_id_namespace="bradesco:account",
    )),
    "caixa_account_csv": CSVReader("caixa_account_csv", "3", CSVOptions(
        columns={"transaction_date": "Data Mov.", "description": "Historico", "amount": "Valor", "external_id": "Nr. Doc."},
        delimiter=";", date_format="DD/MM/YYYY", decimal_separator=",", thousands_separator=".",
        amount_convention="CREDITS_POSITIVE", external_id_namespace="caixa:account",
    )),
}


def money_cents(value, options):
    # Reject excess precision rather than rounding financial evidence.
    decimal = re.escape(options.decimal_separator)
    whole = r"[0-9]+"
    if options.thousands_separator:
        grouping = re.escape(options.thousands_separator)
        whole = rf"(?:[0-9]+|[0-9]{{1,3}}(?:{grouping}[0-9]{{3}})+)"
    sign = r"(?:[+-] ?)?" if options.amount_sign_spacing == "OPTIONAL_SINGLE_SPACE" else r"[+-]?"
    if not re.fullmatch(rf"{sign}{whole}(?:{decimal}[0-9]{{1,2}})?", value):
        raise ValueError("amount_cents")
    # Only normalize a validated ASCII space after the sign. Never strip all
    # internal whitespace: it could merge digits or hide malformed grouping.
    if value.startswith(("- ", "+ ")):
        value = value[0] + value[2:]
    normalized = value.replace(options.thousands_separator, "") if options.thousands_separator else value
    cents = int(Decimal(normalized.replace(options.decimal_separator, ".")) * 100)
    return -cents if options.amount_convention == "CHARGES_NEGATIVE" else cents


def date_value(value, options):
    fmt = {"DD/MM/YYYY": "%d/%m/%Y", "YYYY-MM-DD": "%Y-%m-%d", "MM/DD/YYYY": "%m/%d/%Y"}[options.date_format]
    parsed = datetime.datetime.strptime(value, fmt).date()
    if parsed.strftime(fmt) != value:
        raise ValueError("date")
    return parsed.isoformat()


def parse_csv(content: bytes, options: CSVOptions, *, exact_headers=False):
    result = {"items": [], "errors": [], "warnings": [], "blank_records": 0,
              "complete": True, "rows_read": 0}

    def error(code, line=None, fields=None):
        result["errors"].append({"code": code, "line": line, "fields": fields or []})

    try:
        decoded = content.decode(options.encoding, errors="strict")
    except UnicodeError:
        error("CSV_ENCODING")
        return result
    if any(ord(char) < 32 and char not in "\r\n\t" for char in decoded):
        error("CSV_CONTROL_CHARACTER")
        return result
    # Use CSV's physical newline semantics, not str.splitlines (which also
    # splits Unicode separators that csv.reader treats as ordinary field text).
    physical = io.StringIO(decoded, newline="").readlines()
    if len(physical) > MAX_PHYSICAL_LINES or any(len(line) > MAX_RECORD_CHARS for line in physical):
        error("CSV_LIMIT")
        result["complete"] = False
        return result
    reader = csv.reader(io.StringIO(decoded, newline=""), delimiter=options.delimiter, strict=True)
    try:
        header = next(reader, [])
        if not header or len(header) > MAX_COLUMNS or any(not h or len(h) > 100 for h in header) or len(set(header)) != len(header):
            error("CSV_HEADER")
            return result
        columns = {field: name for field, name in options.columns.model_dump().items() if name is not None}
        resolved = {}
        for field, name in columns.items():
            if name in header:
                resolved[field] = name
            else:
                norm = normalized(name)
                match = next((h for h in header if normalized(h) == norm), None)
                if match:
                    resolved[field] = match
                else:
                    resolved[field] = None
        if any(h is None for h in resolved.values()) or (exact_headers and set(header) != set(resolved.values())):
            error("CSV_LAYOUT_MISMATCH")
            return result
        indexes = {field: header.index(resolved[field]) for field, name in columns.items()}
        if len(set(indexes.values())) != len(indexes):
            error("CSV_AMBIGUOUS_COLUMNS")
            return result
        critical_unmapped = {'D/C', 'C/D', 'DC', 'CD', 'TIPO', 'TIPO DE LANCAMENTO',
                            'CREDITO/DEBITO', 'DEBITO/CREDITO', 'CREDITO', 'DEBITO',
                            'ENTRADAS', 'SAIDAS', 'MOEDA', 'CURRENCY'}
        if any(normalized(h) in critical_unmapped for h in set(header) - set(resolved.values())):
            error("CSV_DIRECTION_MAPPING_REQUIRED")
            return result
        if set(header) - set(resolved.values()):
            result["warnings"].append({"code": "UNMAPPED_COLUMNS_PRESERVED_IN_ORIGINAL", "count": len(set(header) - set(resolved.values()))})
        previous_line = reader.line_num
        for row in reader:
            start, end = previous_line + 1, reader.line_num
            previous_line = end
            if not row or all(not value.strip() for value in row):
                result["blank_records"] += 1
                continue
            result["rows_read"] += 1
            if result["rows_read"] > MAX_ROWS:
                error("CSV_ROW_LIMIT", start)
                result["complete"] = False
                break
            raw = "".join(physical[start - 1:end])
            if len(row) != len(header) or len(raw) > MAX_RECORD_CHARS:
                error("CSV_ROW_SHAPE", start)
                continue
            values = {field: row[index].strip() for field, index in indexes.items()}
            data = {"date_kind": options.date_kind}
            field = None
            try:
                kind = control_kind(values['description']) if options.amount_convention != 'CREDITS_POSITIVE' else None
                if kind:
                    value = money_cents(values['amount'], options)
                    control_field = {'TOTAL': 'total_amount_cents', 'MINIMUM': 'minimum_payment_cents'}.get(kind, kind.lower())
                    result.setdefault('controls', []).append({'field': control_field, 'value': value,
                        'kind': kind, 'line_start': start, 'raw_text': raw})
                    if kind in {'TOTAL', 'MINIMUM'}:
                        candidates = result.setdefault('header_candidates', {}).setdefault(control_field, [])
                        candidates.append({'value': value, 'line_start': start, 'raw_text': raw})
                        if len({c['value'] for c in candidates}) == 1:
                            result.setdefault('extracted_header', {})[control_field] = value
                        else:
                            result.setdefault('extracted_header', {}).pop(control_field, None)
                            error('CSV_CONFLICTING_HEADER', start, [control_field])
                    continue
                for field, value in values.items():
                    if field not in {"transaction_date", "amount", "description"} and not value:
                        continue
                    if field in {"transaction_date", "purchase_date", "booking_date"}:
                        data[field] = date_value(value, options)
                    elif field == "amount":
                        data["amount_cents"] = money_cents(value, options)
                    elif field in {"installment_number", "total_installments"}:
                        if not re.fullmatch(r"[0-9]{1,4}", value):
                            raise ValueError(field)
                        data[field] = int(value)
                    else:
                        data[field] = value
                if "external_id" in data:
                    data["external_id_namespace"] = options.external_id_namespace
                elif exact_headers:
                    field = "external_id"
                    raise ValueError(field)
                role = None
                if options.amount_convention != 'CREDITS_POSITIVE':
                    role = normalize_card_data(data)
                data = FinancialTransactionData.model_validate(data).model_dump(mode="json")
            except ValidationError as exc:
                error("CSV_INVALID_ROW", start, sorted({str(e["loc"][0]) if e["loc"] else "row" for e in exc.errors()}))
                continue
            except (ValueError, OverflowError):
                error("CSV_INVALID_ROW", start, [field])
                continue
            result["items"].append({"position": result["rows_read"], "line_start": start, "line_end": end,
                                    "raw_text": raw, "data": data,
                                    "role": role or 'UNKNOWN', "purpose": 'UNSPECIFIED'})
    except csv.Error:
        error("CSV_SYNTAX", reader.line_num)
        result["complete"] = False
    if not result["rows_read"] and not result["errors"]:
        error("CSV_NO_TRANSACTIONS")
    items = result["items"]
    amounts = [i["data"]["amount_cents"] for i in items]
    result["totals"] = {"positive_cents": sum(a for a in amounts if a > 0),
                        "negative_cents": -sum(a for a in amounts if a < 0), "net_cents": sum(amounts)}
    dates = [i["data"]["transaction_date"] for i in items]
    result["observed_dates"] = {"first": min(dates), "last": max(dates)} if dates else None
    # Equal reliable IDs in one file are ambiguous, even if their values agree.
    # No ID is manufactured from date/value/description.
    identities = {}
    for item in items:
        data = item["data"]
        if data["external_id"] is not None:
            identity = (data["external_id_namespace"], data["external_id"])
            if identity in identities:
                error("CSV_REPEATED_EXTERNAL_ID", item["line_start"], ["external_id"])
            identities[identity] = item["position"]
    return result


def detect_csv(content, source_type=None, *, institution=None, holder_type=None):
    """Inspect bounded headers, never filenames or bank names in counterparties.

    Institution is deliberately not proven by a shared column layout.
    Unsupported/ambiguous results remain consultable evidence.
    """
    empty = {'items': [], 'errors': [], 'warnings': [], 'blank_records': 0,
             'rows_read': 0, 'complete': True, 'totals': {'positive_cents': 0,
             'negative_cents': 0, 'net_cents': 0}, 'observed_dates': None}
    try:
        text = content.decode('utf-8-sig', errors='strict')
    except UnicodeError:
        empty['errors'].append({'code': 'CSV_ENCODING', 'fields': []})
        return empty
    header_line = text.split('\n', 1)[0]
    if len(header_line) > MAX_RECORD_CHARS:
        empty['errors'].append({'code': 'CSV_LIMIT', 'fields': []})
        return empty
    candidates = []
    for delimiter in (',', ';', '\t'):
        try:
            header = next(csv.reader([header_line], delimiter=delimiter, strict=True))
        except csv.Error:
            continue
        columns = {normalized(h) for h in header}
        if {'INSTITUICAO', 'TIPO_DOCUMENTO', 'REFERENCIA_MES_ANO'} <= columns:
            from app.services.financial_compilations import csv_compilation
            return csv_compilation(text, delimiter)
        if {'FATURA_REFERENCIA', 'DATA_LANCAMENTO', 'DESCRICAO', 'VALOR_RS'} <= columns:
            from app.services.financial_compilations import csv_compilation
            return csv_compilation(text, delimiter)
        for reader in READERS.values():
            if reader.options is None or reader.options.delimiter != delimiter:
                continue
            required = {normalized(h) for h in reader.options.columns.model_dump().values() if h}
            if required <= columns:
                candidates.append(reader.id)
    # Select the compatible interpretation, without claiming institution identity.
    compatible = [rid for rid in candidates if source_type is None or
                  (source_type == 'BANK_ACCOUNT') == (READERS[rid].options.amount_convention == 'CREDITS_POSITIVE')]
    if len(compatible) > 1 and institution:
        # Source selection may disambiguate compatible layouts. It never makes
        # an incompatible header compatible, nor proves who issued the file.
        bank = normalized(institution)
        preferred = None
        if 'NUBANK' in bank and holder_type in {'PF', 'PJ'}:
            preferred = 'nubank_account_csv' if holder_type == 'PF' else 'nu_empresas_account_csv'
        elif 'SANTANDER' in bank:
            preferred = 'santander_card_csv' if source_type == 'CREDIT_CARD' else 'santander_account_csv'
        elif re.search(r'\bINTER\b', bank):
            preferred = 'inter_card_csv' if source_type == 'CREDIT_CARD' else 'inter_account_csv'
        elif 'ITAU' in bank:
            preferred = 'itau_card_csv' if source_type == 'CREDIT_CARD' else 'itau_account_csv'
        if preferred in compatible:
            compatible = [preferred]
    if len(compatible) != 1:
        empty.update(content_type='UNKNOWN', reader_candidates=candidates, detected_reader=None)
        empty['errors'].append({'code': 'FINANCIAL_READER_AMBIGUOUS' if candidates else 'CSV_LAYOUT_MISMATCH', 'fields': []})
        return empty
    selected = READERS[compatible[0]]
    result = parse_csv(content, selected.options)
    result.update(detected_reader=selected.id, detected_reader_version=selected.version,
                  detected_source_type='BANK_ACCOUNT' if selected.options.amount_convention == 'CREDITS_POSITIVE' else 'CREDIT_CARD',
                  content_type='BANK_STATEMENT' if selected.options.amount_convention == 'CREDITS_POSITIVE' else 'DETAILED_CARD_BILL',
                  reader_candidates=candidates)
    return result
