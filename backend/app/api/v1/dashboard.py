from typing import Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.api.deps import get_current_device
from app.models.auth import PairedDevice
from app.schemas.reports import DashboardResponse
from app.services.reports import get_dashboard_data

router = APIRouter()


@router.get("/dashboard/summary", response_model=DashboardResponse)
def get_dashboard_summary(
    filter_type: str = Query("today", description="Filtro de tempo: today, date, range, month, year, all"),
    date: Optional[str] = Query(None, description="Data específica YYYY-MM-DD quando filter_type=date"),
    start_date: Optional[str] = Query(None, description="Data inicial YYYY-MM-DD quando filter_type=range"),
    end_date: Optional[str] = Query(None, description="Data final YYYY-MM-DD quando filter_type=range"),
    month: Optional[int] = Query(None, description="Mês (1 a 12) quando filter_type=month"),
    year: Optional[int] = Query(None, description="Ano quando filter_type=month ou year"),
    db: Session = Depends(get_db),
    device: PairedDevice = Depends(get_current_device),
):
    """
    Retorna o resumo operacional e financeiro consolidado do dashboard,
    incluindo cestas montadas, vendidas, saídas em rota, estoque atual,
    alertas de estoque mínimo, contas a pagar, contas a receber, repasses de rota,
    e livro-caixa com projeção financeira. Operação estritamente de leitura (read-only).
    """
    return get_dashboard_data(
        db=db,
        filter_type=filter_type,
        date_str=date,
        start_date_str=start_date,
        end_date_str=end_date,
        month=month,
        year=year,
    )
