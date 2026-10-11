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
from app.models.production import ProductionBatch, ProductionBatchItem
from app.models.products import Product, BasketType, RecipeVersion
from app.schemas.production import (
    ProductionBatchCreate,
    ProductionBatchResponse,
    ProductionBatchItemResponse,
    ProductionBatchListResponse,
    ProductionPreviewRequest,
    ProductionPreviewResponse,
    DisassemblyRequest,
    DisassemblyResponse,
    CancelBatchRequest,
)
from app.services.production import (
    preview_production,
    create_production_batch,
    disassemble_production_batch,
)
from app.services.inventory import get_batch_stock, get_basket_stock

router = APIRouter()


def serialize_batch(b: ProductionBatch, db: Session) -> ProductionBatchResponse:
    """Serializes a ProductionBatch ORM model into Pydantic schema with stock and names."""
    items = [
        ProductionBatchItemResponse(
            id=it.id,
            product_id=it.product_id,
            product_name=it.product.name if it.product else "",
            product_base_unit=it.product.base_unit if it.product else "",
            section=it.section,
            quantity_consumed_base_units=it.quantity_consumed_base_units,
            unit_cost_microcents=it.unit_cost_microcents,
            total_cost_cents=it.total_cost_cents,
        )
        for it in b.items
    ]

    current_stock = (
        get_batch_stock(db, b.id)
        if b.is_custom
        else get_basket_stock(db, b.basket_type_id)
    )

    return ProductionBatchResponse(
        id=b.id,
        batch_number=b.batch_number,
        basket_type_id=b.basket_type_id,
        basket_type_name=b.basket_type.name if b.basket_type else "",
        recipe_version_id=b.recipe_version_id,
        recipe_version_number=b.recipe_version.version_number if b.recipe_version else None,
        quantity_produced=b.quantity_produced,
        current_batch_stock=current_stock,
        status=b.status,
        is_custom=b.is_custom,
        is_direct_sale=b.is_direct_sale,
        custom_description=b.custom_description,
        occurred_at=b.occurred_at,
        unit_cost_cents=b.unit_cost_cents,
        total_cost_cents=b.total_cost_cents,
        canceled_at=b.canceled_at,
        cancellation_reason=b.cancellation_reason,
        notes=b.notes,
        items=items,
    )


@router.post("/production/preview", response_model=ProductionPreviewResponse)
def preview_assembly(
    data: ProductionBatchCreate,
    db: Session = Depends(get_db),
    current_device: PairedDevice = Depends(get_current_device),
):
    """
    Simulacao e pre-flight check da montagem de cestas (padrao ou personalizada).
    Informa saldo atual, requisitos, escassez de ingredientes e custos estimados.
    Nao altera o banco de dados.
    """
    return preview_production(db, data)


@router.get("/production/batches", response_model=ProductionBatchListResponse)
def list_batches(
    basket_type_id: Optional[str] = Query(None, description="Filtrar por tipo de cesta"),
    is_custom: Optional[bool] = Query(None, description="Filtrar por lote personalizado"),
    status_filter: Optional[str] = Query(None, alias="status", description="Filtrar por status (CONFIRMED, DISASSEMBLED)"),
    search: Optional[str] = Query(None, description="Busca por numero (#1), descricao ou observacoes"),
    start_date: Optional[datetime.datetime] = Query(None, description="Data inicial"),
    end_date: Optional[datetime.datetime] = Query(None, description="Data final"),
    page: int = Query(1, ge=1, description="Numero da pagina"),
    page_size: int = Query(50, ge=1, le=500, description="Itens por pagina"),
    db: Session = Depends(get_db),
    current_device: PairedDevice = Depends(get_current_device),
):
    """Lista as ordens de montagem e producao cadastradas com filtros e paginacao."""
    base_stmt = select(ProductionBatch).options(
        selectinload(ProductionBatch.items).selectinload(ProductionBatchItem.product),
        selectinload(ProductionBatch.basket_type),
        selectinload(ProductionBatch.recipe_version),
    )
    count_stmt = select(func.count(ProductionBatch.id))

    filters = []
    if basket_type_id:
        filters.append(ProductionBatch.basket_type_id == basket_type_id)
    if is_custom is not None:
        filters.append(ProductionBatch.is_custom == is_custom)
    if status_filter:
        filters.append(ProductionBatch.status == status_filter.strip().upper())
    if start_date:
        filters.append(ProductionBatch.occurred_at >= start_date)
    if end_date:
        filters.append(ProductionBatch.occurred_at <= end_date)
    if search:
        search_term = f"%{search.strip()}%"
        search_clauses = [
            ProductionBatch.custom_description.ilike(search_term),
            ProductionBatch.notes.ilike(search_term),
            ProductionBatch.basket_type.has(BasketType.name.ilike(search_term)),
        ]
        clean_num = search.strip().lstrip("#")
        if clean_num.isdigit():
            search_clauses.append(ProductionBatch.batch_number == int(clean_num))
        filters.append(or_(*search_clauses))

    if filters:
        base_stmt = base_stmt.where(*filters)
        count_stmt = count_stmt.where(*filters)

    total = db.execute(count_stmt).scalar_one()
    offset = (page - 1) * page_size
    query_stmt = (
        base_stmt.order_by(desc(ProductionBatch.occurred_at), desc(ProductionBatch.batch_number))
        .offset(offset)
        .limit(page_size)
    )

    batches = db.execute(query_stmt).scalars().all()
    items = [serialize_batch(b, db) for b in batches]
    total_pages = math.ceil(total / page_size) if total > 0 else 1

    return ProductionBatchListResponse(
        items=items,
        total=total,
        page=page,
        page_size=page_size,
        total_pages=total_pages,
    )


@router.get("/production/batches/{batch_id}", response_model=ProductionBatchResponse)
def get_batch(
    batch_id: str,
    db: Session = Depends(get_db),
    current_device: PairedDevice = Depends(get_current_device),
):
    """Retorna os dados detalhados e o snapshot de composicao de um lote de producao."""
    stmt = (
        select(ProductionBatch)
        .options(
            selectinload(ProductionBatch.items).selectinload(ProductionBatchItem.product),
            selectinload(ProductionBatch.basket_type),
            selectinload(ProductionBatch.recipe_version),
        )
        .where(ProductionBatch.id == batch_id)
    )
    batch = db.execute(stmt).scalar_one_or_none()
    if not batch:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Lote de producao '{batch_id}' nao encontrado.",
        )
    return serialize_batch(batch, db)


@router.post(
    "/production/batches",
    response_model=ProductionBatchResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_batch(
    data: ProductionBatchCreate,
    db: Session = Depends(get_db),
    current_device: PairedDevice = Depends(get_current_device),
    idempotency_key: Optional[str] = Depends(get_idempotency_key),
):
    """
    Confirma e executa uma ordem de montagem (padrao ou personalizada).
    Valida atomicamente todos os estoques sob BEGIN IMMEDIATE.
    Lanca consumo de insumos e entrada de cestas prontas no mesmo lote transacional.
    Protegido contra envio duplicado via X-Idempotency-Key.
    """
    def _execute(session: Session):
        batch = create_production_batch(session, data)
        # Reload with relationships
        stmt = (
            select(ProductionBatch)
            .options(
                selectinload(ProductionBatch.items).selectinload(ProductionBatchItem.product),
                selectinload(ProductionBatch.basket_type),
                selectinload(ProductionBatch.recipe_version),
            )
            .where(ProductionBatch.id == batch.id)
        )
        loaded = session.execute(stmt).scalar_one()
        response_model = serialize_batch(loaded, session)
        return status.HTTP_201_CREATED, response_model.model_dump(mode="json")

    result = process_transactional_idempotency(
        db=db,
        idempotency_key=idempotency_key,
        operation_type="PRODUCTION_BATCH",
        payload=data.model_dump(mode="json"),
        business_callback=_execute,
    )
    return result.to_json_dict()


@router.post(
    "/production/batches/{batch_id}/disassemble",
    response_model=DisassemblyResponse,
)
def disassemble_batch(
    batch_id: str,
    data: DisassemblyRequest,
    db: Session = Depends(get_db),
    current_device: PairedDevice = Depends(get_current_device),
    idempotency_key: Optional[str] = Depends(get_idempotency_key),
):
    """
    Desmonta cestas acabadas com triagem fisica de insumos.
    Insumos intactos retornam ao estoque (STORE); itens avariados sao registrados como perda (ASSEMBLY_LOSS).
    Exige saldo em estoque de cestas prontas (rejeita desmontar cestas ja vendidas).
    """
    def _execute(session: Session):
        batch, intact_count, loss_count = disassemble_production_batch(session, batch_id, data)
        qty_dis = data.quantity_to_disassemble or batch.quantity_produced
        resp = DisassemblyResponse(
            batch_id=batch.id,
            batch_number=batch.batch_number,
            quantity_disassembled=qty_dis,
            status=batch.status,
            intact_items_returned=intact_count,
            loss_items_recorded=loss_count,
            occurred_at=datetime.datetime.now(datetime.timezone.utc),
            message=f"Lote #{batch.batch_number} desmontado com sucesso. {intact_count} insumo(s) retornados ao estoque e {loss_count} perda(s) registradas.",
        )
        return status.HTTP_200_OK, resp.model_dump(mode="json")

    result = process_transactional_idempotency(
        db=db,
        idempotency_key=idempotency_key,
        operation_type="PRODUCTION_DISASSEMBLE",
        payload={"batch_id": batch_id, **data.model_dump(mode="json")},
        business_callback=_execute,
    )
    return result.to_json_dict()


@router.post(
    "/production/batches/{batch_id}/cancel",
    response_model=DisassemblyResponse,
)
def cancel_batch(
    batch_id: str,
    data: CancelBatchRequest,
    db: Session = Depends(get_db),
    current_device: PairedDevice = Depends(get_current_device),
    idempotency_key: Optional[str] = Depends(get_idempotency_key),
):
    """
    Estorno completo de um lote de producao com retorno de 100% dos insumos ao estoque.
    Exige que as cestas acabadas ainda estejam disponiveis em estoque.
    """
    disassembly_request = DisassemblyRequest(
        quantity_to_disassemble=None,
        reason=data.reason,
        triage_items=None,
    )

    def _execute(session: Session):
        batch, intact_count, loss_count = disassemble_production_batch(
            session, batch_id, disassembly_request
        )
        resp = DisassemblyResponse(
            batch_id=batch.id,
            batch_number=batch.batch_number,
            quantity_disassembled=batch.quantity_produced,
            status=batch.status,
            intact_items_returned=intact_count,
            loss_items_recorded=0,
            occurred_at=datetime.datetime.now(datetime.timezone.utc),
            message=f"Lote #{batch.batch_number} estornado com sucesso. Todos os insumos retornaram ao estoque.",
        )
        return status.HTTP_200_OK, resp.model_dump(mode="json")

    result = process_transactional_idempotency(
        db=db,
        idempotency_key=idempotency_key,
        operation_type="PRODUCTION_CANCEL",
        payload={"batch_id": batch_id, "reason": data.reason},
        business_callback=_execute,
    )
    return result.to_json_dict()
