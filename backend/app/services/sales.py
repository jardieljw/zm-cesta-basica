import uuid
import datetime
from typing import Optional, List, Tuple, Dict, Any
from sqlalchemy import select, func, desc
from sqlalchemy.orm import Session, selectinload
from fastapi import HTTPException, status

from app.models.sales import Sale, SaleItem, SalesReceivable
from app.models.customers import Customer
from app.models.products import BasketType, RecipeVersion
from app.models.production import ProductionBatch
from app.models.movements import InventoryMovement
from app.models.dispatches import StockDispatch, ResponsiblePerson
from app.models.base import utc_now
from app.schemas.sales import SaleCreate, SaleCancelRequest, SaleItemCreate
from app.schemas.production import (
    ProductionBatchCreate,
    ProductionPreviewRequest,
    CustomItemInput,
)
from app.services.inventory import (
    get_basket_stock,
    get_batch_stock,
    record_inventory_movement,
)
from app.services.production import (
    create_production_batch,
    preview_production,
)
from app.services.customers import get_customer_debt_balance


def generate_next_sale_number(db: Session) -> int:
    """Generates the next sequential unique sale number under active transaction."""
    stmt = select(func.coalesce(func.max(Sale.sale_number), 0))
    max_num = db.execute(stmt).scalar_one()
    return int(max_num) + 1


def _resolve_standard_basket_cost(db: Session, basket_type_id: str) -> int:
    """
    Resolves the unit cost for a standard basket sold from stock.
    Prefers the latest confirmed production batch unit cost; falls back to active recipe preview.
    """
    stmt = (
        select(ProductionBatch.unit_cost_cents)
        .where(
            ProductionBatch.basket_type_id == basket_type_id,
            ProductionBatch.status == "CONFIRMED",
            ProductionBatch.is_custom.is_(False),
        )
        .order_by(desc(ProductionBatch.occurred_at), desc(ProductionBatch.batch_number))
        .limit(1)
    )
    last_cost = db.execute(stmt).scalar_one_or_none()
    if last_cost is not None and last_cost > 0:
        return int(last_cost)

    # Fallback to current recipe preview for 1 unit
    try:
        preview = preview_production(
            db,
            ProductionPreviewRequest(basket_type_id=basket_type_id, quantity_produced=1, is_custom=False),
        )
        return int(preview.estimated_unit_cost_cents)
    except Exception:
        return 0


def create_sale(db: Session, data: SaleCreate) -> Sale:
    """
    Executes atomic sale creation under active transaction lock.
    - Validates customer and credit limits for CREDIT_TERM.
    - Validates finished stock sufficiency OR executes simultaneous on-demand assembly.
    - Preserves exact CMPM cost congelation (CMV).
    - Appends immutable ledger movements.
    - Creates sales_receivables for credit sales.
    """
    if not data.items:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="A venda deve conter ao menos um item.",
        )

    sale_id = str(uuid.uuid4())
    sale_number = generate_next_sale_number(db)
    sale_date = data.sale_date or utc_now()

    customer = None
    if data.customer_id:
        customer = db.get(Customer, data.customer_id)
        if not customer:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Cliente '{data.customer_id}' nao encontrado.",
            )
        if not customer.is_active:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Cliente '{customer.name}' esta inativo no cadastro.",
            )

    # Validate payment mode rules
    if data.payment_mode == "CREDIT_TERM":
        if not customer:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Vendas a prazo (fiado) exigem a selecao obrigatoria de um cliente cadastrado ativo.",
            )

    # Calculate total sale amount
    calculated_total_amount_cents = 0
    for item in data.items:
        line_gross = item.quantity * item.unit_price_cents
        line_net = line_gross - item.discount_cents
        if line_net < 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Desconto de {item.discount_cents} centavos excede o valor bruto do item ({line_gross} centavos).",
            )
        calculated_total_amount_cents += line_net

    # Credit limit validation for CREDIT_TERM
    if data.payment_mode == "CREDIT_TERM" and customer:
        current_debt = get_customer_debt_balance(db, customer.id)
        total_new_debt = current_debt + calculated_total_amount_cents
        if customer.credit_limit_cents > 0 and total_new_debt > customer.credit_limit_cents:
            if not data.allow_credit_override:
                exceeded_by = total_new_debt - customer.credit_limit_cents
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail={
                        "error_code": "CREDIT_LIMIT_EXCEEDED",
                        "message": (
                            f"Limite de credito excedido para o cliente '{customer.name}'. "
                            f"Limite: {customer.credit_limit_cents}, Divida atual: {current_debt}, "
                            f"Nova venda: {calculated_total_amount_cents}, Total projetado: {total_new_debt}."
                        ),
                        "customer_id": customer.id,
                        "credit_limit_cents": customer.credit_limit_cents,
                        "current_debt_cents": current_debt,
                        "sale_amount_cents": calculated_total_amount_cents,
                        "exceeded_by_cents": exceeded_by,
                    },
                )

    # Due date for CREDIT_TERM
    due_date = data.due_date
    if data.payment_mode == "CREDIT_TERM" and not due_date:
        due_date = sale_date + datetime.timedelta(days=30)

    # Determine payment_status
    payment_status = "PENDING" if data.payment_mode == "CREDIT_TERM" else "PAID"
    cust_name = customer.name if customer else (data.customer_name.strip() if data.customer_name else None)

    # Resolve dispatch and custody responsible person
    resolved_resp_id = None
    resp_person_obj = None
    if data.dispatch_id:
        dispatch = db.get(StockDispatch, data.dispatch_id)
        if not dispatch:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Saida #{data.dispatch_id} nao encontrada.",
            )
        if dispatch.status != "OPEN":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Saida #{dispatch.dispatch_number} nao esta aberta (status atual: {dispatch.status}).",
            )
        if data.responsible_person_id and data.responsible_person_id != dispatch.responsible_person_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Responsavel informado diverge do responsavel da saida fisica.",
            )
        resolved_resp_id = dispatch.responsible_person_id
        resp_person_obj = dispatch.responsible_person
    elif data.responsible_person_id:
        resp_person_obj = db.get(ResponsiblePerson, data.responsible_person_id)
        if not resp_person_obj:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Pessoa responsavel '{data.responsible_person_id}' nao encontrada.",
            )
        if not resp_person_obj.is_active:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Pessoa responsavel '{resp_person_obj.name}' esta inativa.",
            )
        resolved_resp_id = resp_person_obj.id

    target_location = "TRANSIT" if (data.sale_mode == "COMMERCIAL_ROUTE" and resolved_resp_id) else "STORE"
    target_resp_id = resolved_resp_id if target_location == "TRANSIT" else None

    sale = Sale(
        id=sale_id,
        sale_number=sale_number,
        customer_id=customer.id if customer else None,
        dispatch_id=data.dispatch_id,
        responsible_person_id=resolved_resp_id,
        status="CONFIRMED",
        sale_mode=data.sale_mode,
        payment_mode=data.payment_mode,
        payment_status=payment_status,
        sale_date=sale_date,
        customer_name=cust_name,
        payment_method=data.payment_mode,
        total_amount_cents=calculated_total_amount_cents,
        notes=data.notes.strip() if data.notes else None,
    )
    db.add(sale)

    # Process items and inventory
    sale_items: List[SaleItem] = []

    for item in data.items:
        basket_type = db.get(BasketType, item.basket_type_id)
        if not basket_type:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Tipo de cesta '{item.basket_type_id}' nao encontrado.",
            )
        if not basket_type.is_active:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Tipo de cesta '{basket_type.name}' esta inativo.",
            )

        line_net = (item.quantity * item.unit_price_cents) - item.discount_cents
        item_unit_cost = 0
        resolved_batch_id = item.production_batch_id

        if item.assemble_on_demand:
            # 1. Simultaneous Assembly on Demand
            if item.is_custom:
                if not item.custom_description or not item.custom_description.strip():
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail="Descricao obrigatoria para montagem simultanea de cesta personalizada.",
                    )
                if not item.custom_items:
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail="Montagem simultanea de cesta personalizada exige lista de insumos.",
                    )
                batch_data = ProductionBatchCreate(
                    basket_type_id=basket_type.id,
                    quantity_produced=item.quantity,
                    is_custom=True,
                    is_direct_sale=True,
                    custom_description=item.custom_description.strip(),
                    custom_items=[
                        CustomItemInput(
                            product_id=ci.product_id,
                            quantity_in_base_units=ci.quantity_in_base_units,
                            section=ci.section or "PERSONALIZADO",
                        )
                        for ci in item.custom_items
                    ],
                    occurred_at=sale_date,
                    notes=f"Montagem simultanea na Venda #{sale_number}",
                )
            else:
                batch_data = ProductionBatchCreate(
                    basket_type_id=basket_type.id,
                    quantity_produced=item.quantity,
                    is_custom=False,
                    is_direct_sale=True,
                    occurred_at=sale_date,
                    notes=f"Montagem simultanea na Venda #{sale_number}",
                )

            # Atomically produces batch and consumes ingredients
            prod_batch = create_production_batch(db, batch_data)
            resolved_batch_id = prod_batch.id
            item_unit_cost = prod_batch.unit_cost_cents

            # Record sale departure for the just-produced baskets
            record_inventory_movement(
                db=db,
                item_type="BASKET",
                movement_type="SALE",
                quantity_delta=-item.quantity,
                source_type="SALE",
                source_id=sale.id,
                basket_type_id=basket_type.id,
                production_batch_id=prod_batch.id if prod_batch.is_custom else None,
                occurred_at=sale_date,
                reason=f"Venda #{sale_number} ({basket_type.name}) - Montagem simultanea",
            )

        elif item.production_batch_id:
            # 2. Sell pre-assembled custom batch from stock
            batch = db.get(ProductionBatch, item.production_batch_id)
            if not batch:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"Lote de producao '{item.production_batch_id}' nao encontrado.",
                )
            if batch.status != "CONFIRMED":
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Lote #{batch.batch_number} nao esta confirmado (status atual: {batch.status}).",
                )
            if batch.basket_type_id != basket_type.id:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Lote #{batch.batch_number} nao pertence a cesta '{basket_type.name}'.",
                )
            current_batch_stock = get_batch_stock(
                db, batch.id, location_type=target_location, responsible_person_id=target_resp_id
            )
            if current_batch_stock < item.quantity:
                loc_label = f"sob custodia de '{resp_person_obj.name}'" if target_location == "TRANSIT" and resp_person_obj else "em estoque na loja"
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail={
                        "error_code": "INSUFFICIENT_STOCK",
                        "message": (
                            f"Saldo insuficiente {loc_label} para o lote personalizado #{batch.batch_number}. "
                            f"Saldo atual: {current_batch_stock}, solicitado: {item.quantity}."
                        ),
                        "production_batch_id": batch.id,
                        "current_stock": current_batch_stock,
                        "requested_quantity": item.quantity,
                        "location_type": target_location,
                    },
                )
            item_unit_cost = batch.unit_cost_cents
            resolved_batch_id = batch.id

            record_inventory_movement(
                db=db,
                item_type="BASKET",
                movement_type="SALE",
                quantity_delta=-item.quantity,
                source_type="SALE",
                source_id=sale.id,
                basket_type_id=basket_type.id,
                production_batch_id=batch.id,
                occurred_at=sale_date,
                reason=f"Venda #{sale_number} ({basket_type.name}) - Lote personalizado #{batch.batch_number}",
                location_type=target_location,
                responsible_person_id=target_resp_id,
            )

        else:
            # 3. Sell standard baskets from pre-assembled stock
            current_finished_stock = get_basket_stock(
                db, basket_type.id, location_type=target_location, responsible_person_id=target_resp_id
            )
            if current_finished_stock < item.quantity:
                loc_label = f"sob custodia de '{resp_person_obj.name}'" if target_location == "TRANSIT" and resp_person_obj else "de cestas prontas na loja"
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail={
                        "error_code": "INSUFFICIENT_STOCK",
                        "message": (
                            f"Saldo insuficiente {loc_label} para '{basket_type.name}'. "
                            f"Saldo atual: {current_finished_stock}, solicitado: {item.quantity}. "
                            "Se desejar montar na hora, marque a opcao de montagem imediata."
                        ),
                        "basket_type_id": basket_type.id,
                        "current_stock": current_finished_stock,
                        "requested_quantity": item.quantity,
                        "location_type": target_location,
                    },
                )
            item_unit_cost = _resolve_standard_basket_cost(db, basket_type.id)

            record_inventory_movement(
                db=db,
                item_type="BASKET",
                movement_type="SALE",
                quantity_delta=-item.quantity,
                source_type="SALE",
                source_id=sale.id,
                basket_type_id=basket_type.id,
                production_batch_id=None,
                occurred_at=sale_date,
                reason=f"Venda #{sale_number} ({basket_type.name}) - {'Rota sob custodia' if target_location == 'TRANSIT' else 'Cestas prontas em estoque'}",
                location_type=target_location,
                responsible_person_id=target_resp_id,
            )

        sale_item = SaleItem(
            id=str(uuid.uuid4()),
            sale_id=sale.id,
            basket_type_id=basket_type.id,
            production_batch_id=resolved_batch_id,
            quantity=item.quantity,
            unit_price_cents=item.unit_price_cents,
            discount_cents=item.discount_cents,
            total_cents=line_net,
            unit_cost_cents=item_unit_cost,
            total_cost_cents=item_unit_cost * item.quantity,
        )
        sale_items.append(sale_item)

    sale.items = sale_items

    # Create SalesReceivable if credit sale
    if data.payment_mode == "CREDIT_TERM" and customer:
        receivable = SalesReceivable(
            id=str(uuid.uuid4()),
            sale_id=sale.id,
            customer_id=customer.id,
            due_date=due_date or (sale_date + datetime.timedelta(days=30)),
            original_amount_cents=calculated_total_amount_cents,
            paid_amount_cents=0,
            balance_cents=calculated_total_amount_cents,
            status="OPEN",
            notes=f"Fiado ref. Venda #{sale.sale_number}",
            created_at=utc_now(),
            updated_at=utc_now(),
        )
        db.add(receivable)

    db.flush()
    return sale


def cancel_sale(db: Session, sale_id: str, data: SaleCancelRequest) -> Sale:
    """
    Cancels a confirmed sale:
    - Rejects if receivable already received payments (requires reversal first).
    - Appends REVERSAL movements to return finished baskets to stock.
    - Marks sale and receivable as CANCELED.
    """
    stmt = (
        select(Sale)
        .options(
            selectinload(Sale.items),
            selectinload(Sale.receivable).selectinload(SalesReceivable.payments),
        )
        .where(Sale.id == sale_id)
    )
    sale = db.execute(stmt).scalar_one_or_none()
    if not sale:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Venda '{sale_id}' nao encontrada.",
        )

    if sale.status != "CONFIRMED":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Apenas vendas confirmadas podem ser canceladas. Status atual: {sale.status}.",
        )

    if sale.receivable:
        if sale.receivable.paid_amount_cents > 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=(
                    f"Nao e possivel cancelar a venda #{sale.sale_number} porque ha pagamentos ja recebidos "
                    f"no valor de {sale.receivable.paid_amount_cents} centavos. Estorne os pagamentos antes."
                ),
            )
        sale.receivable.status = "CANCELED"
        sale.receivable.balance_cents = 0
        sale.receivable.updated_at = utc_now()

    # Reverse SALE movements
    mov_stmt = select(InventoryMovement).where(
        InventoryMovement.source_type == "SALE",
        InventoryMovement.source_id == sale.id,
        InventoryMovement.movement_type == "SALE",
    )
    movements = list(db.execute(mov_stmt).scalars().all())

    for m in movements:
        record_inventory_movement(
            db=db,
            item_type=m.item_type,
            movement_type="REVERSAL",
            quantity_delta=-m.quantity_delta, # reverse negative into positive
            source_type="SALE",
            source_id=sale.id,
            basket_type_id=m.basket_type_id,
            production_batch_id=m.production_batch_id,
            reversal_of_id=m.id,
            occurred_at=utc_now(),
            reason=f"Estorno da Venda #{sale.sale_number}: {data.reason.strip()}",
            location_type=m.location_type,
            responsible_person_id=m.responsible_person_id,
        )

    sale.status = "CANCELED"
    sale.payment_status = "CANCELED"
    sale.canceled_at = utc_now()
    sale.cancellation_reason = data.reason.strip()
    db.flush()
    return sale


def get_sale(db: Session, sale_id: str) -> Sale:
    """Retrieves full sale with items and receivable information."""
    stmt = (
        select(Sale)
        .options(
            selectinload(Sale.items).selectinload(SaleItem.basket_type),
            selectinload(Sale.receivable),
            selectinload(Sale.customer),
            selectinload(Sale.responsible_person),
            selectinload(Sale.dispatch),
        )
        .where(Sale.id == sale_id)
    )
    sale = db.execute(stmt).scalar_one_or_none()
    if not sale:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Venda '{sale_id}' nao encontrada.",
        )
    return sale


def list_sales(
    db: Session,
    customer_id: Optional[str] = None,
    status: Optional[str] = None,
    payment_mode: Optional[str] = None,
    start_date: Optional[datetime.datetime] = None,
    end_date: Optional[datetime.datetime] = None,
    limit: int = 100,
    offset: int = 0,
) -> List[Sale]:
    """Lists sales with optional filtering."""
    stmt = (
        select(Sale)
        .options(
            selectinload(Sale.items).selectinload(SaleItem.basket_type),
            selectinload(Sale.receivable),
            selectinload(Sale.customer),
            selectinload(Sale.responsible_person),
            selectinload(Sale.dispatch),
        )
    )
    if customer_id:
        stmt = stmt.where(Sale.customer_id == customer_id)
    if status:
        stmt = stmt.where(Sale.status == status)
    if payment_mode:
        stmt = stmt.where(Sale.payment_mode == payment_mode)
    if start_date:
        stmt = stmt.where(Sale.sale_date >= start_date)
    if end_date:
        stmt = stmt.where(Sale.sale_date <= end_date)

    stmt = stmt.order_by(desc(Sale.sale_date), desc(Sale.sale_number)).limit(limit).offset(offset)
    return list(db.execute(stmt).scalars().all())
