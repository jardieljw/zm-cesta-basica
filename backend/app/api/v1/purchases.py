import math
import datetime
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select, func, or_, desc
from sqlalchemy.orm import Session, selectinload

from app.core.database import get_db
from app.core.idempotency import process_transactional_idempotency
from app.api.deps import get_current_device, get_idempotency_key
from app.models.auth import PairedDevice
from app.models.purchases import Purchase, PurchaseItem
from app.schemas.purchases import (
    PurchaseCreate,
    PurchaseResponse,
    PurchaseItemResponse,
    PurchaseListResponse,
    PurchaseCancelRequest,
    PurchaseCancelResponse,
)
from app.services.purchases import (
    create_purchase_entity,
    confirm_purchase_entity,
    cancel_purchase_entity,
)

router = APIRouter()

def serialize_purchase(p: Purchase) -> PurchaseResponse:
    """Serializes a Purchase ORM model with eager loaded relations into Pydantic schema."""
    items = [
        PurchaseItemResponse(
            id=it.id,
            purchase_id=it.purchase_id,
            product_id=it.product_id,
            product_name=it.product.name if it.product else "",
            product_base_unit=it.product.base_unit if it.product else "",
            packaging_id=it.packaging_id,
            packaging_name=it.packaging.name if it.packaging else None,
            packages_count=float(it.packages_count),
            quantity_in_base_units=it.quantity_in_base_units,
            unit_price_cents=it.unit_price_cents,
            total_price_cents=it.total_price_cents,
        )
        for it in p.items
    ]
    return PurchaseResponse(
        id=p.id,
        purchase_number=p.purchase_number,
        status=p.status,
        purchase_date=p.purchase_date,
        payment_mode=p.payment_mode or "CASH_IMMEDIATE",
        payment_method=p.payment_method or "DINHEIRO",
        due_date=p.due_date,
        account_id=p.account_id,
        payable_id=p.payable.id if p.payable else None,
        supplier_name=p.supplier_name,
        total_amount_cents=p.total_amount_cents,
        notes=p.notes,
        created_at=p.created_at,
        items=items,
    )

@router.get("/purchases", response_model=PurchaseListResponse)
def list_purchases(
    status_filter: Optional[str] = Query(None, alias="status", description="Filtrar por status (CONFIRMED, DRAFT, CANCELED)"),
    search: Optional[str] = Query(None, description="Busca por fornecedor ou numero da compra"),
    start_date: Optional[datetime.datetime] = Query(None, description="Data inicial"),
    end_date: Optional[datetime.datetime] = Query(None, description="Data final"),
    page: int = Query(1, ge=1, description="Numero da pagina"),
    page_size: int = Query(50, ge=1, le=500, description="Itens por pagina"),
    db: Session = Depends(get_db),
    current_device: PairedDevice = Depends(get_current_device),
):
    """Lista as compras cadastradas com filtros e paginacao."""
    base_stmt = select(Purchase).options(
        selectinload(Purchase.items).selectinload(PurchaseItem.product),
        selectinload(Purchase.items).selectinload(PurchaseItem.packaging),
        selectinload(Purchase.payable),
    )
    count_stmt = select(func.count(Purchase.id))

    filters = []
    if status_filter:
        filters.append(Purchase.status == status_filter.strip().upper())
    if start_date:
        filters.append(Purchase.purchase_date >= start_date)
    if end_date:
        filters.append(Purchase.purchase_date <= end_date)
    if search:
        search_term = f"%{search.strip()}%"
        search_clauses = [
            Purchase.supplier_name.ilike(search_term),
            Purchase.notes.ilike(search_term),
        ]
        clean_search_num = search.strip().lstrip("#")
        if clean_search_num.isdigit():
            search_clauses.append(Purchase.purchase_number == int(clean_search_num))
        filters.append(or_(*search_clauses))

    if filters:
        base_stmt = base_stmt.where(*filters)
        count_stmt = count_stmt.where(*filters)

    total = db.execute(count_stmt).scalar_one()

    offset = (page - 1) * page_size
    query_stmt = (
        base_stmt.order_by(desc(Purchase.purchase_date), desc(Purchase.purchase_number))
        .offset(offset)
        .limit(page_size)
    )

    purchases = db.execute(query_stmt).scalars().all()
    items = [serialize_purchase(p) for p in purchases]
    total_pages = math.ceil(total / page_size) if total > 0 else 1

    return PurchaseListResponse(
        items=items,
        total=total,
        page=page,
        page_size=page_size,
        total_pages=total_pages,
    )

@router.get("/purchases/{purchase_id}", response_model=PurchaseResponse)
def get_purchase(
    purchase_id: str,
    db: Session = Depends(get_db),
    current_device: PairedDevice = Depends(get_current_device),
):
    """Retorna os dados detalhados de uma compra especifica e seus itens."""
    stmt = (
        select(Purchase)
        .options(
            selectinload(Purchase.items).selectinload(PurchaseItem.product),
            selectinload(Purchase.items).selectinload(PurchaseItem.packaging),
            selectinload(Purchase.payable),
        )
        .where(Purchase.id == purchase_id)
    )
    purchase = db.execute(stmt).scalar_one_or_none()

    if not purchase:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Compra '{purchase_id}' nao encontrada.",
        )

    return serialize_purchase(purchase)

@router.post(
    "/purchases",
    response_model=PurchaseResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_purchase(
    data: PurchaseCreate,
    db: Session = Depends(get_db),
    current_device: PairedDevice = Depends(get_current_device),
    idempotency_key: Optional[str] = Depends(get_idempotency_key),
):
    """
    Registra uma nova compra de fornecedor.
    Converte automaticamente embalagens comerciais para unidades base de estoque.
    Se status for CONFIRMED, lanca movimentacoes contabeis no livro-razao e atualiza precos de custo.
    Protegido contra repeticao acidental via X-Idempotency-Key.
    """
    def _execute(session: Session):
        purchase = create_purchase_entity(session, data)
        # Reload with relationships
        stmt = (
            select(Purchase)
            .options(
                selectinload(Purchase.items).selectinload(PurchaseItem.product),
                selectinload(Purchase.items).selectinload(PurchaseItem.packaging),
            )
            .where(Purchase.id == purchase.id)
        )
        loaded = session.execute(stmt).scalar_one()
        response_model = serialize_purchase(loaded)
        return status.HTTP_201_CREATED, response_model.model_dump(mode="json")

    result = process_transactional_idempotency(
        db=db,
        idempotency_key=idempotency_key,
        operation_type="PURCHASES",
        payload=data.model_dump(mode="json"),
        business_callback=_execute,
    )

    return result.to_json_dict()

@router.post(
    "/purchases/{purchase_id}/confirm",
    response_model=PurchaseResponse,
)
def confirm_purchase(
    purchase_id: str,
    db: Session = Depends(get_db),
    current_device: PairedDevice = Depends(get_current_device),
    idempotency_key: Optional[str] = Depends(get_idempotency_key),
):
    """
    Confirma uma compra previamente salva como rascunho (DRAFT).
    Lanca as movimentacoes no estoque e atualiza precos de custo.
    """
    def _execute(session: Session):
        purchase = confirm_purchase_entity(session, purchase_id)
        stmt = (
            select(Purchase)
            .options(
                selectinload(Purchase.items).selectinload(PurchaseItem.product),
                selectinload(Purchase.items).selectinload(PurchaseItem.packaging),
            )
            .where(Purchase.id == purchase.id)
        )
        loaded = session.execute(stmt).scalar_one()
        response_model = serialize_purchase(loaded)
        return status.HTTP_200_OK, response_model.model_dump(mode="json")

    result = process_transactional_idempotency(
        db=db,
        idempotency_key=idempotency_key,
        operation_type="PURCHASES_CONFIRM",
        payload={"purchase_id": purchase_id},
        business_callback=_execute,
    )

    return result.to_json_dict()

@router.post(
    "/purchases/{purchase_id}/cancel",
    response_model=PurchaseCancelResponse,
)
def cancel_purchase(
    purchase_id: str,
    payload: Optional[PurchaseCancelRequest] = None,
    db: Session = Depends(get_db),
    current_device: PairedDevice = Depends(get_current_device),
    idempotency_key: Optional[str] = Depends(get_idempotency_key),
):
    """
    Realiza o estorno e cancelamento contabil de uma compra confirmada.
    Valida estritamente se o estoque atual e suficiente para reverter a compra sem gerar saldo negativo.
    Lanca movimentos reversos PURCHASE_CANCEL no livro-razao sem excluir registros fisicamente.
    """
    cancel_reason = payload.reason if payload else None

    def _execute(session: Session):
        purchase, reversal_count = cancel_purchase_entity(session, purchase_id, cancel_reason)
        stmt = (
            select(Purchase)
            .options(
                selectinload(Purchase.items).selectinload(PurchaseItem.product),
                selectinload(Purchase.items).selectinload(PurchaseItem.packaging),
            )
            .where(Purchase.id == purchase.id)
        )
        loaded = session.execute(stmt).scalar_one()
        purchase_resp = serialize_purchase(loaded)

        cancel_resp = PurchaseCancelResponse(
            purchase=purchase_resp,
            reversal_movements_count=reversal_count,
            message=(
                f"Compra #{purchase.purchase_number} cancelada com sucesso. "
                f"{reversal_count} movimentacoes de estorno registradas no razao."
            ),
        )
        return status.HTTP_200_OK, cancel_resp.model_dump(mode="json")

    request_payload = {
        "purchase_id": purchase_id,
        "reason": cancel_reason,
    }

    result = process_transactional_idempotency(
        db=db,
        idempotency_key=idempotency_key,
        operation_type="PURCHASES_CANCEL",
        payload=request_payload,
        business_callback=_execute,
    )

    return result.to_json_dict()
