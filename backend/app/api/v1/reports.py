import datetime
from typing import Optional
from fastapi import APIRouter, Depends, Query, Response, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.api.deps import get_current_device
from app.models.auth import PairedDevice
from app.schemas.reports import ReportResponse
from app.schemas.form_print import FormExportRequest
from app.services.business_dashboard import get_business_financial_report
from app.services.reports import (
    get_report_sales_dispatches,
    get_report_assembly,
    get_report_purchases_movements,
    get_report_receivables,
    get_report_payables,
    get_report_dispatch_settlements,
    get_report_physical_inventory,
    get_report_financial_summary,
    get_blank_form_data,
)
from app.services.report_exporters import (
    export_report_to_csv,
    export_report_to_xlsx,
    export_blank_template_to_xlsx,
)

router = APIRouter()


@router.get("/reports/business-financial-summary", response_model=ReportResponse)
def business_financial_report(
    filter_type: str = Query("today"),
    date: Optional[str] = Query(None),
    start_date: Optional[str] = Query(None),
    end_date: Optional[str] = Query(None),
    month: Optional[int] = Query(None, ge=1, le=12),
    year: Optional[int] = Query(None, ge=2000, le=2200),
    db: Session = Depends(get_db),
    device: PairedDevice = Depends(get_current_device),
):
    return get_business_financial_report(db, filter_type=filter_type, date_str=date,
        start_date_str=start_date, end_date_str=end_date, month=month, year=year)


@router.get("/reports/sales-dispatches", response_model=ReportResponse)
def report_sales_dispatches(
    filter_type: str = Query("today"),
    date: Optional[str] = Query(None),
    start_date: Optional[str] = Query(None),
    end_date: Optional[str] = Query(None),
    month: Optional[int] = Query(None),
    year: Optional[int] = Query(None),
    basket_type_id: Optional[str] = Query(None),
    customer_id: Optional[str] = Query(None),
    responsible_id: Optional[str] = Query(None),
    sale_mode: Optional[str] = Query(None),
    include_dispatches: bool = Query(True),
    db: Session = Depends(get_db),
    device: PairedDevice = Depends(get_current_device),
):
    return get_report_sales_dispatches(
        db=db,
        filter_type=filter_type,
        date_str=date,
        start_date_str=start_date,
        end_date_str=end_date,
        month=month,
        year=year,
        basket_type_id=basket_type_id,
        customer_id=customer_id,
        responsible_id=responsible_id,
        sale_mode=sale_mode,
        include_dispatches=include_dispatches,
    )


@router.get("/reports/assembly", response_model=ReportResponse)
def report_assembly(
    filter_type: str = Query("today"),
    date: Optional[str] = Query(None),
    start_date: Optional[str] = Query(None),
    end_date: Optional[str] = Query(None),
    month: Optional[int] = Query(None),
    year: Optional[int] = Query(None),
    basket_type_id: Optional[str] = Query(None),
    is_custom: Optional[bool] = Query(None),
    db: Session = Depends(get_db),
    device: PairedDevice = Depends(get_current_device),
):
    return get_report_assembly(
        db=db,
        filter_type=filter_type,
        date_str=date,
        start_date_str=start_date,
        end_date_str=end_date,
        month=month,
        year=year,
        basket_type_id=basket_type_id,
        is_custom=is_custom,
    )


@router.get("/reports/purchases-movements", response_model=ReportResponse)
def report_purchases_movements(
    filter_type: str = Query("today"),
    date: Optional[str] = Query(None),
    start_date: Optional[str] = Query(None),
    end_date: Optional[str] = Query(None),
    month: Optional[int] = Query(None),
    year: Optional[int] = Query(None),
    product_id: Optional[str] = Query(None),
    movement_type: Optional[str] = Query(None),
    db: Session = Depends(get_db),
    device: PairedDevice = Depends(get_current_device),
):
    return get_report_purchases_movements(
        db=db,
        filter_type=filter_type,
        date_str=date,
        start_date_str=start_date,
        end_date_str=end_date,
        month=month,
        year=year,
        product_id=product_id,
        movement_type=movement_type,
    )


@router.get("/reports/receivables", response_model=ReportResponse)
def report_receivables(
    filter_type: str = Query("today"),
    date: Optional[str] = Query(None),
    start_date: Optional[str] = Query(None),
    end_date: Optional[str] = Query(None),
    month: Optional[int] = Query(None),
    year: Optional[int] = Query(None),
    status: Optional[str] = Query(None),
    customer_id: Optional[str] = Query(None),
    db: Session = Depends(get_db),
    device: PairedDevice = Depends(get_current_device),
):
    return get_report_receivables(
        db=db,
        filter_type=filter_type,
        date_str=date,
        start_date_str=start_date,
        end_date_str=end_date,
        month=month,
        year=year,
        status_filter=status,
        customer_id=customer_id,
    )


@router.get("/reports/payables", response_model=ReportResponse)
def report_payables(
    filter_type: str = Query("today"),
    date: Optional[str] = Query(None),
    start_date: Optional[str] = Query(None),
    end_date: Optional[str] = Query(None),
    month: Optional[int] = Query(None),
    year: Optional[int] = Query(None),
    status: Optional[str] = Query(None),
    beneficiary: Optional[str] = Query(None),
    category: Optional[str] = Query(None),
    nature: Optional[str] = Query(None),
    db: Session = Depends(get_db),
    device: PairedDevice = Depends(get_current_device),
):
    return get_report_payables(
        db=db,
        filter_type=filter_type,
        date_str=date,
        start_date_str=start_date,
        end_date_str=end_date,
        month=month,
        year=year,
        status_filter=status,
        beneficiary=beneficiary,
        category=category,
        nature=nature,
    )


@router.get("/reports/dispatch-settlements", response_model=ReportResponse)
def report_dispatch_settlements(
    filter_type: str = Query("today"),
    date: Optional[str] = Query(None),
    start_date: Optional[str] = Query(None),
    end_date: Optional[str] = Query(None),
    month: Optional[int] = Query(None),
    year: Optional[int] = Query(None),
    responsible_id: Optional[str] = Query(None),
    status: Optional[str] = Query(None),
    db: Session = Depends(get_db),
    device: PairedDevice = Depends(get_current_device),
):
    return get_report_dispatch_settlements(
        db=db,
        filter_type=filter_type,
        date_str=date,
        start_date_str=start_date,
        end_date_str=end_date,
        month=month,
        year=year,
        responsible_id=responsible_id,
        status_filter=status,
    )


@router.get("/reports/physical-inventory", response_model=ReportResponse)
def report_physical_inventory(
    category: Optional[str] = Query(None),
    only_below_min: bool = Query(False),
    db: Session = Depends(get_db),
    device: PairedDevice = Depends(get_current_device),
):
    return get_report_physical_inventory(
        db=db,
        category=category,
        only_below_min=only_below_min,
    )


@router.get("/reports/financial-summary", response_model=ReportResponse)
def report_financial_summary(
    filter_type: str = Query("today"),
    date: Optional[str] = Query(None),
    start_date: Optional[str] = Query(None),
    end_date: Optional[str] = Query(None),
    month: Optional[int] = Query(None),
    year: Optional[int] = Query(None),
    db: Session = Depends(get_db),
    device: PairedDevice = Depends(get_current_device),
):
    return get_report_financial_summary(
        db=db,
        filter_type=filter_type,
        date_str=date,
        start_date_str=start_date,
        end_date_str=end_date,
        month=month,
        year=year,
    )


@router.get("/reports/{report_type}/export")
def export_report(
    report_type: str,
    format: str = Query("csv", description="Formato de exportação: csv ou xlsx"),
    filter_type: str = Query("today"),
    date: Optional[str] = Query(None),
    start_date: Optional[str] = Query(None),
    end_date: Optional[str] = Query(None),
    month: Optional[int] = Query(None),
    year: Optional[int] = Query(None),
    basket_type_id: Optional[str] = Query(None),
    customer_id: Optional[str] = Query(None),
    responsible_id: Optional[str] = Query(None),
    product_id: Optional[str] = Query(None),
    category: Optional[str] = Query(None),
    status: Optional[str] = Query(None),
    nature: Optional[str] = Query(None),
    sale_mode: Optional[str] = Query(None),
    include_dispatches: bool = Query(True),
    is_custom: Optional[bool] = Query(None),
    movement_type: Optional[str] = Query(None),
    only_below_min: bool = Query(False),
    db: Session = Depends(get_db),
    device: PairedDevice = Depends(get_current_device),
):
    """
    Exporta qualquer relatório para arquivo CSV ou XLSX com formatação exata de moeda e números.
    """
    format_lower = format.lower()
    if format_lower not in ["csv", "xlsx"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Formato inválido. Use 'csv' ou 'xlsx'."
        )

    # Resolve report data
    if report_type == "sales-dispatches":
        report_data = get_report_sales_dispatches(
            db=db, filter_type=filter_type, date_str=date, start_date_str=start_date,
            end_date_str=end_date, month=month, year=year, basket_type_id=basket_type_id,
            customer_id=customer_id, responsible_id=responsible_id, sale_mode=sale_mode,
            include_dispatches=include_dispatches,
        )
    elif report_type == "assembly":
        report_data = get_report_assembly(
            db=db, filter_type=filter_type, date_str=date, start_date_str=start_date,
            end_date_str=end_date, month=month, year=year, basket_type_id=basket_type_id,
            is_custom=is_custom,
        )
    elif report_type == "purchases-movements":
        report_data = get_report_purchases_movements(
            db=db, filter_type=filter_type, date_str=date, start_date_str=start_date,
            end_date_str=end_date, month=month, year=year, product_id=product_id,
            movement_type=movement_type,
        )
    elif report_type == "receivables":
        report_data = get_report_receivables(
            db=db, filter_type=filter_type, date_str=date, start_date_str=start_date,
            end_date_str=end_date, month=month, year=year, status_filter=status, customer_id=customer_id
        )
    elif report_type == "payables":
        report_data = get_report_payables(
            db=db, filter_type=filter_type, date_str=date, start_date_str=start_date,
            end_date_str=end_date, month=month, year=year, status_filter=status, category=category, nature=nature
        )
    elif report_type == "dispatch-settlements":
        report_data = get_report_dispatch_settlements(
            db=db, filter_type=filter_type, date_str=date, start_date_str=start_date,
            end_date_str=end_date, month=month, year=year, responsible_id=responsible_id, status_filter=status
        )
    elif report_type == "physical-inventory":
        report_data = get_report_physical_inventory(
            db=db, category=category, only_below_min=only_below_min,
        )
    elif report_type == "business-financial-summary":
        report_data = get_business_financial_report(
            db, filter_type=filter_type, date_str=date, start_date_str=start_date,
            end_date_str=end_date, month=month, year=year,
        )
    elif report_type == "financial-summary":
        report_data = get_report_financial_summary(
            db=db, filter_type=filter_type, date_str=date, start_date_str=start_date,
            end_date_str=end_date, month=month, year=year
        )
    else:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Tipo de relatório desconhecido: '{report_type}'"
        )

    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    if format_lower == "csv":
        content = export_report_to_csv(report_data)
        filename = f"relatorio_{report_type}_{timestamp}.csv"
        return Response(
            content=content,
            media_type="text/csv; charset=utf-8",
            headers={"Content-Disposition": f'attachment; filename="{filename}"'}
        )
    else:
        content = export_report_to_xlsx(report_data)
        filename = f"relatorio_{report_type}_{timestamp}.xlsx"
        return Response(
            content=content,
            media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            headers={"Content-Disposition": f'attachment; filename="{filename}"'}
        )


@router.get("/reports/blank-templates/{form_type}", response_model=ReportResponse)
def get_blank_template(
    form_type: str,
    filled: bool = Query(False, description="Se true, preenche o modelo com dados reais do sistema para auditoria"),
    db: Session = Depends(get_db),
    device: PairedDevice = Depends(get_current_device),
):
    """
    Retorna o modelo de formulário canônico.
    Quando filled=false: colunas com linhas em branco para preenchimento manual à caneta.
    Quando filled=true: os mesmos modelos preenchidos com os dados reais do aplicativo para auditoria física.
    """
    try:
        return get_blank_form_data(form_type=form_type, db=db, filled=filled)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))


@router.get("/reports/blank-templates/{form_type}/export")
def export_blank_template_xlsx(
    form_type: str,
    filled: bool = Query(False, description="Se true, exporta modelo preenchido com dados reais para auditoria"),
    db: Session = Depends(get_db),
    device: PairedDevice = Depends(get_current_device),
):
    """
    Gera e exporta um arquivo XLSX modelo com linhas amplas (26-28pt) para auditoria física e escrita manual.
    """
    valid_types = ["payments", "payables", "dispatch_conference", "physical_inventory"]
    if form_type not in valid_types:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Modelo de formulário desconhecido: '{form_type}'. Opções: {valid_types}"
        )
    report_data = get_blank_form_data(form_type=form_type, db=db, filled=filled)
    content = export_blank_template_to_xlsx(form_type, report=report_data)
    prefix = "auditoria_preenchida" if filled else "modelo_vazio"
    filename = f"{prefix}_{form_type}.xlsx"
    return Response(
        content=content,
        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'}
    )


@router.post('/reports/blank-templates/{form_type}/export')
def export_configured_form(
    form_type: str, request: FormExportRequest,
    device: PairedDevice = Depends(get_current_device),
):
    """Export the displayed snapshot with presentation options. No database writes."""
    try:
        canonical = get_blank_form_data(form_type)
        report = request.report
        if report.metadata.report_type not in {f'blank-{form_type}', f'audit-{form_type}'}:
            raise ValueError('O documento não corresponde ao modelo selecionado.')
        if len(report.columns) != len(report.headers) or any(c not in canonical.columns for c in report.columns):
            raise ValueError('Colunas incompatíveis com o modelo.')
        content = export_blank_template_to_xlsx(form_type, report=report, options=request.options)
    except ValueError as exc:
        raise HTTPException(status_code=422, detail={'error_code': 'VALIDATION_ERROR', 'message': str(exc)})
    return Response(content=content, media_type='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        headers={'Content-Disposition': f'attachment; filename="formulario_{form_type}.xlsx"'})
