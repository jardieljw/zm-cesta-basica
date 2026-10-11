import datetime
from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.idempotency import process_transactional_idempotency
from app.api.deps import get_current_device, get_idempotency_key
from app.models.auth import PairedDevice
from app.models.sales import Sale
from app.schemas.sales import (
    SaleCreate,
    SaleResponse,
    SaleItemResponse,
    SaleCancelRequest,
)
from app.services.sales import (
    create_sale,
    cancel_sale,
    get_sale,
    list_sales,
)

router = APIRouter()


def serialize_sale(s: Sale) -> SaleResponse:
    items = [
        SaleItemResponse(
            id=it.id,
            basket_type_id=it.basket_type_id,
            basket_type_name=it.basket_type.name if it.basket_type else None,
            production_batch_id=it.production_batch_id,
            quantity=it.quantity,
            unit_price_cents=it.unit_price_cents,
            discount_cents=it.discount_cents,
            total_cents=it.total_cents,
            unit_cost_cents=it.unit_cost_cents,
            total_cost_cents=it.total_cost_cents,
        )
        for it in s.items
    ]
    total_cost = sum(it.total_cost_cents for it in items)
    gross_margin = s.total_amount_cents - total_cost

    rec_id = s.receivable.id if s.receivable else None
    rec_due = s.receivable.due_date if s.receivable else None
    rec_bal = s.receivable.balance_cents if s.receivable else None
    rec_st = s.receivable.status if s.receivable else None

    return SaleResponse(
        id=s.id,
        sale_number=s.sale_number,
        customer_id=s.customer_id,
        customer_name=s.customer.name if s.customer else s.customer_name,
        status=s.status,
        sale_mode=s.sale_mode,
        payment_mode=s.payment_mode,
        payment_status=s.payment_status,
        sale_date=s.sale_date,
        total_amount_cents=s.total_amount_cents,
        total_cost_cents=total_cost,
        gross_margin_cents=gross_margin,
        canceled_at=s.canceled_at,
        cancellation_reason=s.cancellation_reason,
        notes=s.notes,
        items=items,
        receivable_id=rec_id,
        receivable_due_date=rec_due,
        receivable_balance_cents=rec_bal,
        receivable_status=rec_st,
    )


@router.post("/sales", response_model=SaleResponse, status_code=status.HTTP_201_CREATED)
def post_sale(
    data: SaleCreate,
    db: Session = Depends(get_db),
    device: PairedDevice = Depends(get_current_device),
    idempotency_key: Optional[str] = Depends(get_idempotency_key),
):
    """
    Registra uma nova venda com suporte a estoque acabado ou montagem simultanea,
    congelando custos (CMV) e gerando titulos a receber quando fiado.
    Envolvido em transacao idempotente via X-Idempotency-Key.
    """
    def callback(session: Session):
        sale = create_sale(session, data)
        resp = serialize_sale(sale).model_dump(mode="json")
        return status.HTTP_201_CREATED, resp

    result = process_transactional_idempotency(
        db=db,
        idempotency_key=idempotency_key,
        operation_type="SALE_CREATE",
        payload=data.model_dump(mode="json"),
        business_callback=callback,
    )

    return JSONResponse(status_code=result.status_code, content=result.to_json_dict())


@router.get("/sales", response_model=List[SaleResponse])
def get_sales(
    customer_id: Optional[str] = Query(None),
    status: Optional[str] = Query(None),
    payment_mode: Optional[str] = Query(None),
    start_date: Optional[datetime.datetime] = Query(None),
    end_date: Optional[datetime.datetime] = Query(None),
    limit: int = Query(100, ge=1, le=500),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db),
    device: PairedDevice = Depends(get_current_device),
):
    """Consulta historico de vendas com filtros."""
    sales = list_sales(
        db=db,
        customer_id=customer_id,
        status=status,
        payment_mode=payment_mode,
        start_date=start_date,
        end_date=end_date,
        limit=limit,
        offset=offset,
    )
    return [serialize_sale(s) for s in sales]


@router.get("/sales/{sale_id}", response_model=SaleResponse)
def get_sale_by_id(
    sale_id: str,
    db: Session = Depends(get_db),
    device: PairedDevice = Depends(get_current_device),
):
    """Consulta detalhes de uma venda especifica."""
    sale = get_sale(db, sale_id)
    return serialize_sale(sale)


@router.post("/sales/{sale_id}/cancel", response_model=SaleResponse)
def post_cancel_sale(
    sale_id: str,
    data: SaleCancelRequest,
    db: Session = Depends(get_db),
    device: PairedDevice = Depends(get_current_device),
    idempotency_key: Optional[str] = Depends(get_idempotency_key),
):
    """
    Cancela uma venda confirmada, estornando movimentacoes de estoque de forma rastreavel
    e cancelando titulos a receber pendentes.
    """
    def callback(session: Session):
        sale = cancel_sale(session, sale_id, data)
        resp = serialize_sale(sale).model_dump(mode="json")
        return status.HTTP_200_OK, resp

    result = process_transactional_idempotency(
        db=db,
        idempotency_key=idempotency_key,
        operation_type="SALE_CANCEL",
        payload={"sale_id": sale_id, **data.model_dump(mode="json")},
        business_callback=callback,
    )

    return JSONResponse(status_code=result.status_code, content=result.to_json_dict())
