import csv
import io
import datetime
from typing import Dict, Any, List
import openpyxl
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.utils import get_column_letter

from app.schemas.reports import ReportResponse


def _format_currency_ptbr(cents: int) -> str:
    """Formats cents as Brazilian Real string: R$ 1.234,56."""
    val = (cents or 0) / 100.0
    formatted = f"{val:,.2f}".replace(",", "X").replace(".", ",").replace("X", ".")
    return f"R$ {formatted}"


def export_report_to_csv(report: ReportResponse) -> bytes:
    """Exports a report to CSV using UTF-8-SIG (Excel compatible in pt-BR)."""
    output = io.StringIO()
    writer = csv.writer(output, delimiter=";", quoting=csv.QUOTE_MINIMAL)

    # Header metadata
    writer.writerow([report.metadata.company_name])
    writer.writerow([report.metadata.title])
    writer.writerow([f"Período/Filtro: {report.metadata.filter_info.label}"])
    writer.writerow([f"Gerado em: {report.metadata.generated_at.strftime('%d/%m/%Y %H:%M:%S')}"])
    writer.writerow([])

    # Table headers
    writer.writerow(report.headers)

    # Data rows
    for row in report.rows:
        row_values = []
        for col in report.columns:
            val = row.get(col, "")
            if isinstance(val, (int, float)):
                if col.endswith("_cents") or "valor" in col or "preco" in col:
                    # Currency field
                    row_values.append(f"{(val / 100.0):.2f}".replace(".", ","))
                else:
                    row_values.append(str(val))
            elif isinstance(val, datetime.datetime):
                row_values.append(val.strftime("%d/%m/%Y %H:%M"))
            elif isinstance(val, datetime.date):
                row_values.append(val.strftime("%d/%m/%Y"))
            elif val is None:
                row_values.append("")
            else:
                row_values.append(str(val))
        writer.writerow(row_values)

    # Totals row if available
    if report.totals:
        writer.writerow([])
        totals_row = ["TOTAIS"]
        for col in report.columns[1:]:
            if col in report.totals:
                val = report.totals[col]
                if col.endswith("_cents"):
                    totals_row.append(f"{(val / 100.0):.2f}".replace(".", ","))
                else:
                    totals_row.append(str(val))
            else:
                totals_row.append("")
        writer.writerow(totals_row)

    return output.getvalue().encode("utf-8-sig")


def export_report_to_xlsx(report: ReportResponse) -> bytes:
    """Exports a report to a professionally formatted Excel spreadsheet using openpyxl."""
    wb = openpyxl.Workbook()
    ws = wb.active
    ws.title = report.metadata.report_type[:30].replace("/", "-")

    # Styles
    title_font = Font(name="Calibri", size=14, bold=True, color="1F497D")
    meta_font = Font(name="Calibri", size=10, italic=True, color="595959")
    header_font = Font(name="Calibri", size=11, bold=True, color="FFFFFF")
    header_fill = PatternFill(start_color="1F497D", end_color="1F497D", fill_type="solid")
    alt_fill = PatternFill(start_color="F2F5F8", end_color="F2F5F8", fill_type="solid")
    total_font = Font(name="Calibri", size=11, bold=True, color="000000")
    total_fill = PatternFill(start_color="E6EEF4", end_color="E6EEF4", fill_type="solid")
    
    thin_border = Border(
        left=Side(style="thin", color="D9D9D9"),
        right=Side(style="thin", color="D9D9D9"),
        top=Side(style="thin", color="D9D9D9"),
        bottom=Side(style="thin", color="D9D9D9")
    )
    total_border = Border(
        top=Side(style="thin", color="1F497D"),
        bottom=Side(style="double", color="1F497D")
    )

    # Title block
    ws.append([report.metadata.company_name])
    ws.cell(row=1, column=1).font = Font(name="Calibri", size=11, bold=True, color="595959")
    
    ws.append([report.metadata.title])
    ws.cell(row=2, column=1).font = title_font

    ws.append([f"Período: {report.metadata.filter_info.label} | Emissão: {report.metadata.generated_at.strftime('%d/%m/%Y %H:%M:%S')}"])
    ws.cell(row=3, column=1).font = meta_font
    ws.append([]) # Empty row

    # Headers
    header_row_idx = 5
    ws.append(report.headers)
    for col_idx in range(1, len(report.headers) + 1):
        cell = ws.cell(row=header_row_idx, column=col_idx)
        cell.font = header_font
        cell.fill = header_fill
        cell.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)
    ws.row_dimensions[header_row_idx].height = 24

    # Data rows
    curr_row_idx = header_row_idx + 1
    for r_idx, row in enumerate(report.rows):
        row_vals = []
        for col in report.columns:
            val = row.get(col, "")
            row_vals.append(val)
        ws.append(row_vals)

        # Style and format cells
        is_even = (r_idx % 2 == 1)
        for col_idx, col in enumerate(report.columns, start=1):
            cell = ws.cell(row=curr_row_idx, column=col_idx)
            cell.border = thin_border
            if is_even:
                cell.fill = alt_fill

            val = cell.value
            if col.endswith("_cents") or "valor" in col or "preco" in col:
                if isinstance(val, (int, float)):
                    cell.value = val / 100.0
                    cell.number_format = '"R$" #,##0.00'
                    cell.alignment = Alignment(horizontal="right")
            elif isinstance(val, int):
                cell.number_format = '#,##0'
                cell.alignment = Alignment(horizontal="right")
            elif isinstance(val, datetime.datetime):
                cell.value = val.strftime("%d/%m/%Y %H:%M")
                cell.alignment = Alignment(horizontal="center")
            elif isinstance(val, datetime.date):
                cell.value = val.strftime("%d/%m/%Y")
                cell.alignment = Alignment(horizontal="center")
            else:
                cell.alignment = Alignment(horizontal="left")

        curr_row_idx += 1

    # Totals Row
    if report.totals:
        totals_row_vals = ["TOTAIS"]
        for col in report.columns[1:]:
            if col in report.totals:
                totals_row_vals.append(report.totals[col])
            else:
                totals_row_vals.append("")
        ws.append(totals_row_vals)

        for col_idx, col in enumerate(report.columns, start=1):
            cell = ws.cell(row=curr_row_idx, column=col_idx)
            cell.font = total_font
            cell.fill = total_fill
            cell.border = total_border
            val = cell.value
            if col.endswith("_cents") or "valor" in col:
                if isinstance(val, (int, float)):
                    cell.value = val / 100.0
                    cell.number_format = '"R$" #,##0.00'
                    cell.alignment = Alignment(horizontal="right")
            elif isinstance(val, int):
                cell.number_format = '#,##0'
                cell.alignment = Alignment(horizontal="right")
        curr_row_idx += 1

    # Adjust column widths
    for col in ws.columns:
        max_len = 0
        col_letter = get_column_letter(col[0].column)
        for cell in col:
            # Skip title row from max_len calculation
            if cell.row < 5:
                continue
            if cell.value:
                max_len = max(max_len, len(str(cell.value)))
        ws.column_dimensions[col_letter].width = max(max_len + 4, 12)

    buf = io.BytesIO()
    wb.save(buf)
    return buf.getvalue()


def export_blank_template_to_xlsx(template_type: str, report: Optional[ReportResponse] = None) -> bytes:
    """
    Generates a formatted XLSX model with spacious rows (26-28pt) for clipboard audit and handwriting.
    When report is provided with data rows, populates real data cells while maintaining generous line height.
    When report is empty or None, generates 20 blank lines.
    """
    wb = openpyxl.Workbook()
    ws = wb.active

    header_font = Font(name="Calibri", size=11, bold=True, color="FFFFFF")
    header_fill = PatternFill(start_color="34495E", end_color="34495E", fill_type="solid")
    meta_font = Font(name="Calibri", size=10, italic=True, color="595959")
    title_font = Font(name="Calibri", size=14, bold=True, color="1F497D")
    total_font = Font(name="Calibri", size=11, bold=True, color="000000")
    total_fill = PatternFill(start_color="E6EEF4", end_color="E6EEF4", fill_type="solid")

    thin_border = Border(
        left=Side(style="thin", color="A6A6A6"),
        right=Side(style="thin", color="A6A6A6"),
        top=Side(style="thin", color="A6A6A6"),
        bottom=Side(style="thin", color="A6A6A6")
    )
    total_border = Border(
        top=Side(style="thin", color="34495E"),
        bottom=Side(style="double", color="34495E")
    )

    has_real_data = bool(
        report
        and report.metadata.report_type.startswith("audit-")
        and len(report.rows) > 0
    )
    templates = {
        "payments": {
            "title": "Tabela de Pagamentos de Cestas (Auditoria e Conferência Física)" if has_real_data else "Tabela de Pagamentos de Cestas (Formulário em Branco)",
            "headers": [
                "Data Venda", "Cliente / Identificação", "Tipo de Cesta", "Qtd",
                "Valor Total (R$)", "Data Prevista", "Data Pagamento", "Valor Recebido (R$)",
                "Saldo Restante (R$)", "Quitação / Visto", "Observações"
            ],
            "sheet_name": "Pagamentos Cestas"
        },
        "payables": {
            "title": "Tabela de Contas a Pagar (Auditoria e Conferência Física)" if has_real_data else "Tabela de Contas a Pagar (Formulário em Branco)",
            "headers": [
                "Descrição da Obrigação", "Beneficiário / Fornecedor", "Categoria", "Valor (R$)",
                "Data Vencimento", "Data Pagamento", "Forma Pagamento", "Quitação / Visto", "Observações / NF"
            ],
            "sheet_name": "Contas a Pagar"
        },
        "dispatch_conference": {
            "title": "Folha de Conferência de Saídas de Cestas (Auditoria Física)" if has_real_data else "Folha de Conferência de Saídas de Cestas (Formulário em Branco)",
            "headers": [
                "Data / Horário", "Responsável", "Tipo de Cesta", "Qtd Retirada", "Preço Unit. (R$)",
                "Personalizações", "Vendidas", "Devolvidas", "Avariadas", "Custódia", "Visto Conferência"
            ],
            "sheet_name": "Conferência Saídas"
        },
        "physical_inventory": {
            "title": "Folha de Contagem Física de Estoque (Auditoria e Balanço)" if has_real_data else "Folha de Contagem Física de Estoque (Formulário em Branco)",
            "headers": [
                "Produto / Cesta", "Unidade", "Saldo Sistema", "Quantidade Física (Contada)",
                "Diferença (+/-)", "Observações e Justificativa", "Assinatura / Visto"
            ],
            "sheet_name": "Contagem Física"
        }
    }

    cfg = templates.get(template_type, templates["payments"])
    ws.title = cfg["sheet_name"]

    # Header block
    ws.append(["ZM Cesta Básica"])
    ws.cell(row=1, column=1).font = Font(name="Calibri", size=11, bold=True, color="595959")
    ws.append([report.metadata.title if report else cfg["title"]])
    ws.cell(row=2, column=1).font = title_font
    sub_label = report.metadata.filter_info.label if report else "Modelo Oficial para Preenchimento Manual à Caneta e Conferência de Prancheta"
    ws.append([sub_label])
    ws.cell(row=3, column=1).font = meta_font
    ws.append([])

    # Table headers
    headers = report.headers if report else cfg["headers"]
    ws.append(headers)
    header_row_idx = 5
    for col_idx in range(1, len(headers) + 1):
        cell = ws.cell(row=header_row_idx, column=col_idx)
        cell.font = header_font
        cell.fill = header_fill
        cell.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)
    ws.row_dimensions[header_row_idx].height = 26

    curr_row_idx = header_row_idx + 1

    if has_real_data:
        # Populate real rows
        for r_idx, row in enumerate(report.rows):
            row_vals = []
            for col in report.columns:
                val = row.get(col, "")
                row_vals.append(val)
            ws.append(row_vals)
            ws.row_dimensions[curr_row_idx].height = 26

            for col_idx, col in enumerate(report.columns, start=1):
                cell = ws.cell(row=curr_row_idx, column=col_idx)
                cell.border = thin_border
                val = cell.value

                if col.endswith("_cents") or "valor" in col or "preco" in col:
                    if isinstance(val, (int, float)) and val != "":
                        cell.value = val / 100.0
                        cell.number_format = '"R$" #,##0.00'
                        cell.alignment = Alignment(horizontal="right", vertical="center")
                    else:
                        cell.alignment = Alignment(horizontal="center", vertical="center")
                elif isinstance(val, int):
                    cell.number_format = '#,##0'
                    cell.alignment = Alignment(horizontal="right", vertical="center")
                elif isinstance(val, datetime.datetime):
                    cell.value = val.strftime("%d/%m/%Y %H:%M")
                    cell.alignment = Alignment(horizontal="center", vertical="center")
                elif isinstance(val, datetime.date):
                    cell.value = val.strftime("%d/%m/%Y")
                    cell.alignment = Alignment(horizontal="center", vertical="center")
                else:
                    cell.alignment = Alignment(horizontal="left", vertical="center")

            curr_row_idx += 1

        # Totals row if available
        if report.totals:
            totals_row_vals = ["TOTAIS"]
            for col in report.columns[1:]:
                if col in report.totals:
                    totals_row_vals.append(report.totals[col])
                else:
                    totals_row_vals.append("")
            ws.append(totals_row_vals)
            ws.row_dimensions[curr_row_idx].height = 26

            for col_idx, col in enumerate(report.columns, start=1):
                cell = ws.cell(row=curr_row_idx, column=col_idx)
                cell.font = total_font
                cell.fill = total_fill
                cell.border = total_border
                val = cell.value
                if col.endswith("_cents") or "valor" in col or "preco" in col:
                    if isinstance(val, (int, float)):
                        cell.value = val / 100.0
                        cell.number_format = '"R$" #,##0.00'
                        cell.alignment = Alignment(horizontal="right", vertical="center")
                elif isinstance(val, int):
                    cell.number_format = '#,##0'
                    cell.alignment = Alignment(horizontal="right", vertical="center")
            curr_row_idx += 1

    else:
        # Blank rows (20 rows with comfortable height of 28pt for handwriting)
        for r in range(curr_row_idx, curr_row_idx + 20):
            ws.append(["" for _ in headers])
            ws.row_dimensions[r].height = 28
            for col_idx in range(1, len(headers) + 1):
                cell = ws.cell(row=r, column=col_idx)
                cell.border = thin_border
        curr_row_idx += 20

    # Footer Signatures
    footer_row_idx = curr_row_idx + 2
    ws.cell(row=footer_row_idx, column=2, value="_____________________________________________")
    ws.cell(row=footer_row_idx + 1, column=2, value="Assinatura do Responsável")
    sig_col = max(3, len(headers) - 1)
    ws.cell(row=footer_row_idx, column=sig_col, value="_____________________________________________")
    ws.cell(row=footer_row_idx + 1, column=sig_col, value="Visto do Auditor / Conferente")

    # Column widths
    for col in ws.columns:
        col_letter = get_column_letter(col[0].column)
        max_len = 0
        for cell in col:
            if cell.row < 5:
                continue
            if cell.value:
                max_len = max(max_len, len(str(cell.value)))
        ws.column_dimensions[col_letter].width = max(max_len + 4, 16)

    buf = io.BytesIO()
    wb.save(buf)
    return buf.getvalue()
