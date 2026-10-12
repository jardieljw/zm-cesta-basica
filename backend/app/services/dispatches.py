import uuid
import datetime
from typing import Optional, List, Dict, Any, Tuple
from sqlalchemy import select, func, desc, and_
from sqlalchemy.orm import Session, selectinload
from fastapi import HTTPException, status

from app.models.dispatches import (
    ResponsiblePerson,
    StockDispatch,
    DispatchItem,
    DispatchReturn,
    DispatchLoss,
    DispatchExpense,
    DispatchRepayment,
    DispatchSettlement,
)
from app.models.sales import Sale, SaleItem, ReceivablePayment
from app.models.products import BasketType
from app.models.production import ProductionBatch
from app.models.movements import InventoryMovement
from app.models.base import utc_now
from app.schemas.dispatches import (
    ResponsiblePersonCreate,
    ResponsiblePersonUpdate,
    ResponsiblePersonCustodyResponse,
    CustodyBasketBalance,
    DispatchItemCreate,
    StockDispatchCreate,
    DispatchReturnCreate,
    DispatchLossCreate,
    DispatchExpenseCreate,
    DispatchRepaymentCreate,
    DispatchSettlementCreate,
    DispatchSettlementInvestigationUpdate,
    DispatchReconciliationResponse,
    DispatchItemReconciliation,
    DispatchReturnResponse,
    DispatchLossResponse,
    DispatchExpenseResponse,
    DispatchRepaymentResponse,
    DispatchSettlementResponse,
)
from app.services.inventory import (
    get_basket_stock,
    get_batch_stock,
    validate_sufficient_basket_stock,
    record_inventory_movement,
)


# ==================== RESPONSIBLE PERSONS ====================

def create_responsible_person(db: Session, data: ResponsiblePersonCreate) -> ResponsiblePerson:
    """Creates a new responsible person for basket dispatches."""
    person = ResponsiblePerson(
        id=str(uuid.uuid4()),
        name=data.name.strip(),
        phone=data.phone.strip() if data.phone else None,
        is_active=data.is_active,
        notes=data.notes.strip() if data.notes else None,
        created_at=utc_now(),
        updated_at=utc_now(),
    )
    db.add(person)
    db.flush()
    return person


def update_responsible_person(db: Session, person_id: str, data: ResponsiblePersonUpdate) -> ResponsiblePerson:
    """Updates responsible person details."""
    person = db.get(ResponsiblePerson, person_id)
    if not person:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Pessoa responsavel '{person_id}' nao encontrada.",
        )
    if data.name is not None:
        person.name = data.name.strip()
    if data.phone is not None:
        person.phone = data.phone.strip() if data.phone else None
    if data.is_active is not None:
        person.is_active = data.is_active
    if data.notes is not None:
        person.notes = data.notes.strip() if data.notes else None
    person.updated_at = utc_now()
    db.flush()
    return person


def get_responsible_person(db: Session, person_id: str) -> ResponsiblePerson:
    """Retrieves responsible person by ID."""
    person = db.get(ResponsiblePerson, person_id)
    if not person:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Pessoa responsavel '{person_id}' nao encontrada.",
        )
    return person


def list_responsible_persons(
    db: Session, is_active: Optional[bool] = None, search: Optional[str] = None
) -> List[ResponsiblePerson]:
    """Lists responsible persons with optional filters."""
    stmt = select(ResponsiblePerson)
    if is_active is not None:
        stmt = stmt.where(ResponsiblePerson.is_active == is_active)
    if search:
        stmt = stmt.where(ResponsiblePerson.name.ilike(f"%{search.strip()}%"))
    stmt = stmt.order_by(ResponsiblePerson.name.asc())
    return list(db.execute(stmt).scalars().all())


def get_responsible_person_custody(db: Session, person_id: str) -> ResponsiblePersonCustodyResponse:
    """Calculates live on-hand custody balance in TRANSIT for a responsible person."""
    person = get_responsible_person(db, person_id)

    # Query all positive transit balances for this person
    stmt = (
        select(
            InventoryMovement.basket_type_id,
            BasketType.name,
            func.coalesce(func.sum(InventoryMovement.quantity_delta), 0).label("balance"),
        )
        .join(BasketType, InventoryMovement.basket_type_id == BasketType.id)
        .where(
            InventoryMovement.location_type == "TRANSIT",
            InventoryMovement.responsible_person_id == person.id,
        )
        .group_by(InventoryMovement.basket_type_id, BasketType.name)
    )
    rows = db.execute(stmt).all()
    baskets: List[CustodyBasketBalance] = []
    total_custody = 0
    for r in rows:
        bal = int(r[2])
        if bal > 0:
            baskets.append(
                CustodyBasketBalance(
                    basket_type_id=r[0],
                    basket_type_name=r[1],
                    balance=bal,
                )
            )
            total_custody += bal

    return ResponsiblePersonCustodyResponse(
        responsible_person_id=person.id,
        responsible_person_name=person.name,
        total_custody_baskets=total_custody,
        baskets=baskets,
    )


# ==================== STOCK DISPATCHES ====================

def generate_next_dispatch_number(db: Session) -> int:
    """Generates sequential dispatch number under active transaction lock."""
    stmt = select(func.coalesce(func.max(StockDispatch.dispatch_number), 0))
    max_num = db.execute(stmt).scalar_one()
    return int(max_num) + 1


def create_dispatch(db: Session, data: StockDispatchCreate) -> StockDispatch:
    """
    Executes atomic physical stock dispatch under BEGIN IMMEDIATE:
    - Validates responsible person exists and is active.
    - Validates sufficient stock in STORE for each item.
    - Debits STORE and credits TRANSIT atomically in append-only inventory_movements.
    - Creates StockDispatch and DispatchItem records.
    """
    if not data.items:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="A expedicao deve conter ao menos uma cesta.",
        )

    person = db.get(ResponsiblePerson, data.responsible_person_id)
    if not person:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Pessoa responsavel '{data.responsible_person_id}' nao encontrada.",
        )
    if not person.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Pessoa responsavel '{person.name}' esta inativa no cadastro.",
        )

    # 1. Consolidate items with same (basket_type_id, production_batch_id) to avoid duplicate lines and prevent stock overdraft
    consolidated_items_dict: Dict[Tuple[str, Optional[str]], DispatchItemCreate] = {}
    for item in data.items:
        key = (item.basket_type_id, item.production_batch_id)
        if key in consolidated_items_dict:
            existing = consolidated_items_dict[key]
            merged_qty = existing.quantity + item.quantity
            existing_notes = (existing.notes or "").strip()
            item_notes = (item.notes or "").strip()
            merged_notes = None
            if existing_notes and item_notes:
                merged_notes = f"{existing_notes}; {item_notes}"
            elif existing_notes:
                merged_notes = existing_notes
            elif item_notes:
                merged_notes = item_notes

            unit_price = (
                item.unit_price_cents
                if (item.unit_price_cents and item.unit_price_cents > 0)
                else existing.unit_price_cents
            )
            consolidated_items_dict[key] = DispatchItemCreate(
                basket_type_id=item.basket_type_id,
                production_batch_id=item.production_batch_id,
                quantity=merged_qty,
                unit_price_cents=unit_price,
                notes=merged_notes,
            )
        else:
            consolidated_items_dict[key] = item

    items_to_process = list(consolidated_items_dict.values())

    # 2. Validate stock sufficiency in STORE for all consolidated items prior to mutation
    for item in items_to_process:
        bt = db.get(BasketType, item.basket_type_id)
        if not bt:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Tipo de cesta '{item.basket_type_id}' nao encontrado.",
            )
        if not bt.is_active:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Tipo de cesta '{bt.name}' esta inativo.",
            )

        if item.production_batch_id:
            batch = db.get(ProductionBatch, item.production_batch_id)
            if not batch:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"Lote de producao '{item.production_batch_id}' nao encontrado.",
                )
            batch_stock = get_batch_stock(db, batch.id, location_type="STORE")
            if batch_stock < item.quantity:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail={
                        "error_code": "INSUFFICIENT_STOCK",
                        "message": (
                            f"Saldo insuficiente no estoque da loja para o lote personalizado #{batch.batch_number}. "
                            f"Saldo na loja: {batch_stock}, solicitado: {item.quantity}."
                        ),
                        "production_batch_id": batch.id,
                        "current_stock": batch_stock,
                        "requested_quantity": item.quantity,
                        "location_type": "STORE",
                    },
                )
        else:
            store_stock = get_basket_stock(db, bt.id, location_type="STORE")
            if store_stock < item.quantity:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail={
                        "error_code": "INSUFFICIENT_STOCK",
                        "message": (
                            f"Saldo insuficiente no estoque da loja para a cesta '{bt.name}'. "
                            f"Saldo na loja: {store_stock}, solicitado para saida: {item.quantity}."
                        ),
                        "basket_type_id": bt.id,
                        "current_stock": store_stock,
                        "requested_quantity": item.quantity,
                        "location_type": "STORE",
                    },
                )

    dispatch_id = str(uuid.uuid4())
    dispatch_number = generate_next_dispatch_number(db)
    dispatch_date = data.dispatch_date or utc_now()

    dispatch = StockDispatch(
        id=dispatch_id,
        dispatch_number=dispatch_number,
        responsible_person_id=person.id,
        dispatch_date=dispatch_date,
        status="OPEN",
        notes=data.notes.strip() if data.notes else None,
        created_at=utc_now(),
        updated_at=utc_now(),
    )
    db.add(dispatch)

    dispatch_items: List[DispatchItem] = []
    for item in items_to_process:
        bt = db.get(BasketType, item.basket_type_id)
        unit_price = item.unit_price_cents if (item.unit_price_cents and item.unit_price_cents > 0) else 0

        d_item = DispatchItem(
            id=str(uuid.uuid4()),
            dispatch_id=dispatch.id,
            basket_type_id=item.basket_type_id,
            production_batch_id=item.production_batch_id,
            quantity=item.quantity,
            unit_price_cents=unit_price,
            notes=item.notes.strip() if item.notes else None,
        )
        dispatch_items.append(d_item)

        # Append-only movement: STORE DEBIT (-quantity)
        record_inventory_movement(
            db=db,
            item_type="BASKET",
            movement_type="DISPATCH_TRANSFER",
            quantity_delta=-item.quantity,
            source_type="DISPATCH",
            source_id=dispatch.id,
            basket_type_id=item.basket_type_id,
            production_batch_id=item.production_batch_id,
            occurred_at=dispatch_date,
            reason=f"Saida #{dispatch_number} para entrega sob custodia de {person.name}",
            location_type="STORE",
            responsible_person_id=None,
        )

        # Append-only movement: TRANSIT CREDIT (+quantity)
        record_inventory_movement(
            db=db,
            item_type="BASKET",
            movement_type="DISPATCH_TRANSFER",
            quantity_delta=+item.quantity,
            source_type="DISPATCH",
            source_id=dispatch.id,
            basket_type_id=item.basket_type_id,
            production_batch_id=item.production_batch_id,
            occurred_at=dispatch_date,
            reason=f"Custodia de rota #{dispatch_number} recebida por {person.name}",
            location_type="TRANSIT",
            responsible_person_id=person.id,
        )

    dispatch.items = dispatch_items
    db.flush()
    return dispatch


def get_dispatch(db: Session, dispatch_id: str) -> StockDispatch:
    """Retrieves full stock dispatch with all items, responsible person and closures."""
    stmt = (
        select(StockDispatch)
        .options(
            selectinload(StockDispatch.responsible_person),
            selectinload(StockDispatch.items).selectinload(DispatchItem.basket_type),
            selectinload(StockDispatch.items).selectinload(DispatchItem.production_batch),
            selectinload(StockDispatch.returns).selectinload(DispatchReturn.basket_type),
            selectinload(StockDispatch.losses).selectinload(DispatchLoss.basket_type),
            selectinload(StockDispatch.expenses),
            selectinload(StockDispatch.repayments),
            selectinload(StockDispatch.settlements),
            selectinload(StockDispatch.sales),
        )
        .where(StockDispatch.id == dispatch_id)
    )
    dispatch = db.execute(stmt).scalar_one_or_none()
    if not dispatch:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Saida fisica '{dispatch_id}' nao encontrada.",
        )
    return dispatch


def list_dispatches(
    db: Session,
    responsible_person_id: Optional[str] = None,
    status_filter: Optional[str] = None,
    start_date: Optional[datetime.datetime] = None,
    end_date: Optional[datetime.datetime] = None,
    limit: int = 50,
    offset: int = 0,
) -> List[StockDispatch]:
    """Lists stock dispatches with filters."""
    stmt = (
        select(StockDispatch)
        .options(
            selectinload(StockDispatch.responsible_person),
            selectinload(StockDispatch.items).selectinload(DispatchItem.basket_type),
            selectinload(StockDispatch.settlements),
        )
    )
    if responsible_person_id:
        stmt = stmt.where(StockDispatch.responsible_person_id == responsible_person_id)
    if status_filter:
        stmt = stmt.where(StockDispatch.status == status_filter)
    if start_date:
        stmt = stmt.where(StockDispatch.dispatch_date >= start_date)
    if end_date:
        stmt = stmt.where(StockDispatch.dispatch_date <= end_date)

    stmt = stmt.order_by(desc(StockDispatch.dispatch_date), desc(StockDispatch.dispatch_number)).limit(limit).offset(offset)
    return list(db.execute(stmt).scalars().all())


def cancel_dispatch(db: Session, dispatch_id: str, reason: str) -> StockDispatch:
    """
    Cancels an open dispatch if no subsequent operations (sales, returns, losses, repayments) have occurred:
    - Atomically reverses STORE and TRANSIT movements.
    - Sets dispatch status to CANCELED.
    """
    dispatch = get_dispatch(db, dispatch_id)
    if dispatch.status != "OPEN":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Apenas saidas abertas podem ser canceladas. Status atual: {dispatch.status}.",
        )

    # Check for dependent operations
    if dispatch.sales:
        confirmed_sales = [s for s in dispatch.sales if s.status == "CONFIRMED"]
        if confirmed_sales:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Nao e possivel cancelar a saida #{dispatch.dispatch_number} pois ha {len(confirmed_sales)} venda(s) registrada(s). Cancele as vendas primeiro.",
            )
    if dispatch.returns:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Nao e possivel cancelar a saida #{dispatch.dispatch_number} pois ha devolucoes registradas.",
        )
    if dispatch.losses:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Nao e possivel cancelar a saida #{dispatch.dispatch_number} pois ha perdas registradas.",
        )
    if dispatch.repayments:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Nao e possivel cancelar a saida #{dispatch.dispatch_number} pois ha repasses financeiros registrados.",
        )

    # Reverse DISPATCH_TRANSFER movements
    mov_stmt = select(InventoryMovement).where(
        InventoryMovement.source_type == "DISPATCH",
        InventoryMovement.source_id == dispatch.id,
        InventoryMovement.movement_type == "DISPATCH_TRANSFER",
    )
    movements = list(db.execute(mov_stmt).scalars().all())

    for m in movements:
        # If m was STORE (-Q), reverse into STORE (+Q). If m was TRANSIT (+Q), reverse into TRANSIT (-Q).
        record_inventory_movement(
            db=db,
            item_type=m.item_type,
            movement_type="REVERSAL",
            quantity_delta=-m.quantity_delta,
            source_type="DISPATCH",
            source_id=dispatch.id,
            basket_type_id=m.basket_type_id,
            production_batch_id=m.production_batch_id,
            reversal_of_id=m.id,
            occurred_at=utc_now(),
            reason=f"Cancelamento da Saida #{dispatch.dispatch_number}: {reason.strip()}",
            location_type=m.location_type,
            responsible_person_id=m.responsible_person_id,
        )

    dispatch.status = "CANCELED"
    dispatch.updated_at = utc_now()
    if dispatch.notes:
        dispatch.notes += f" | Cancelado: {reason.strip()}"
    else:
        dispatch.notes = f"Cancelado: {reason.strip()}"
    db.flush()
    return dispatch


# ==================== RETURNS & LOSSES ====================

def record_dispatch_return(db: Session, dispatch_id: str, data: DispatchReturnCreate) -> DispatchReturn:
    """
    Records return of intact baskets from TRANSIT back to STORE:
    - Validates responsible person has sufficient stock in TRANSIT.
    - Debits TRANSIT and credits STORE atomically in append-only ledger.
    """
    dispatch = get_dispatch(db, dispatch_id)
    if dispatch.status == "CANCELED":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Saida #{dispatch.dispatch_number} esta cancelada.",
        )
    if dispatch.status == "CONCLUDED":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Saida #{dispatch.dispatch_number} ja esta concluida e nao permite novas devolucoes.",
        )

    bt = db.get(BasketType, data.basket_type_id)
    if not bt:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Tipo de cesta '{data.basket_type_id}' nao encontrado.",
        )

    # Validate stock in TRANSIT
    if data.production_batch_id:
        transit_stock = get_batch_stock(
            db, data.production_batch_id, location_type="TRANSIT", responsible_person_id=dispatch.responsible_person_id
        )
    else:
        transit_stock = get_basket_stock(
            db, data.basket_type_id, location_type="TRANSIT", responsible_person_id=dispatch.responsible_person_id
        )

    if transit_stock < data.quantity:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={
                "error_code": "INSUFFICIENT_STOCK",
                "message": (
                    f"Saldo sob custodia de '{dispatch.responsible_person.name}' e insuficiente para devoluco da cesta '{bt.name}'. "
                    f"Saldo em transito: {transit_stock}, solicitado: {data.quantity}."
                ),
                "basket_type_id": bt.id,
                "current_stock": transit_stock,
                "requested_quantity": data.quantity,
                "location_type": "TRANSIT",
            },
        )

    returned_at = data.returned_at or utc_now()
    ret = DispatchReturn(
        id=str(uuid.uuid4()),
        dispatch_id=dispatch.id,
        basket_type_id=data.basket_type_id,
        production_batch_id=data.production_batch_id,
        quantity=data.quantity,
        returned_at=returned_at,
        notes=data.notes.strip() if data.notes else None,
        created_at=utc_now(),
    )
    db.add(ret)

    # Ledger: TRANSIT DEBIT (-quantity)
    record_inventory_movement(
        db=db,
        item_type="BASKET",
        movement_type="DISPATCH_RETURN",
        quantity_delta=-data.quantity,
        source_type="DISPATCH_RETURN",
        source_id=ret.id,
        basket_type_id=data.basket_type_id,
        production_batch_id=data.production_batch_id,
        occurred_at=returned_at,
        reason=f"Retorno intacto da Saida #{dispatch.dispatch_number} ({dispatch.responsible_person.name})",
        location_type="TRANSIT",
        responsible_person_id=dispatch.responsible_person_id,
    )

    # Ledger: STORE CREDIT (+quantity)
    record_inventory_movement(
        db=db,
        item_type="BASKET",
        movement_type="DISPATCH_RETURN",
        quantity_delta=+data.quantity,
        source_type="DISPATCH_RETURN",
        source_id=ret.id,
        basket_type_id=data.basket_type_id,
        production_batch_id=data.production_batch_id,
        occurred_at=returned_at,
        reason=f"Entrada por devolucao da Saida #{dispatch.dispatch_number} ({bt.name})",
        location_type="STORE",
        responsible_person_id=None,
    )

    db.flush()
    return ret


def record_dispatch_loss(db: Session, dispatch_id: str, data: DispatchLossCreate) -> DispatchLoss:
    """
    Records damaged or lost baskets written off from TRANSIT:
    - Validates mandatory textual reason.
    - Validates responsible person has sufficient stock in TRANSIT.
    - Debits TRANSIT without returning anything to STORE.
    """
    dispatch = get_dispatch(db, dispatch_id)
    if dispatch.status == "CANCELED":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Saida #{dispatch.dispatch_number} esta cancelada.",
        )
    if dispatch.status == "CONCLUDED":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Saida #{dispatch.dispatch_number} ja esta concluida e nao permite novos registros de perda.",
        )

    bt = db.get(BasketType, data.basket_type_id)
    if not bt:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Tipo de cesta '{data.basket_type_id}' nao encontrado.",
        )

    if not data.reason or not data.reason.strip():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Justificativa textual obrigatoria para registro de perda/avaria.",
        )

    if data.production_batch_id:
        transit_stock = get_batch_stock(
            db, data.production_batch_id, location_type="TRANSIT", responsible_person_id=dispatch.responsible_person_id
        )
    else:
        transit_stock = get_basket_stock(
            db, data.basket_type_id, location_type="TRANSIT", responsible_person_id=dispatch.responsible_person_id
        )

    if transit_stock < data.quantity:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={
                "error_code": "INSUFFICIENT_STOCK",
                "message": (
                    f"Saldo sob custodia de '{dispatch.responsible_person.name}' e insuficiente para baixa de perda. "
                    f"Saldo em transito: {transit_stock}, solicitado: {data.quantity}."
                ),
                "basket_type_id": bt.id,
                "current_stock": transit_stock,
                "requested_quantity": data.quantity,
                "location_type": "TRANSIT",
            },
        )

    occurred_at = data.occurred_at or utc_now()
    loss = DispatchLoss(
        id=str(uuid.uuid4()),
        dispatch_id=dispatch.id,
        basket_type_id=data.basket_type_id,
        production_batch_id=data.production_batch_id,
        quantity=data.quantity,
        occurred_at=occurred_at,
        reason=data.reason.strip(),
        created_at=utc_now(),
    )
    db.add(loss)

    # Ledger: TRANSIT LOSS DEBIT (-quantity) (No STORE entry!)
    record_inventory_movement(
        db=db,
        item_type="BASKET",
        movement_type="DISPATCH_LOSS",
        quantity_delta=-data.quantity,
        source_type="DISPATCH_LOSS",
        source_id=loss.id,
        basket_type_id=data.basket_type_id,
        production_batch_id=data.production_batch_id,
        occurred_at=occurred_at,
        reason=f"Perda/Avaria na Saida #{dispatch.dispatch_number}: {data.reason.strip()}",
        location_type="TRANSIT",
        responsible_person_id=dispatch.responsible_person_id,
    )

    db.flush()
    return loss


# ==================== EXPENSES & REPAYMENTS ====================

def record_dispatch_expense(db: Session, dispatch_id: str, data: DispatchExpenseCreate) -> DispatchExpense:
    """Records an authorized route expense deducting from expected cash."""
    dispatch = get_dispatch(db, dispatch_id)
    if dispatch.status == "CANCELED":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Saida #{dispatch.dispatch_number} esta cancelada.",
        )
    if dispatch.status == "CONCLUDED":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Saida #{dispatch.dispatch_number} ja esta concluida e nao permite novas despesas.",
        )

    expense = DispatchExpense(
        id=str(uuid.uuid4()),
        dispatch_id=dispatch.id,
        expense_date=data.expense_date or utc_now(),
        amount_cents=data.amount_cents,
        description=data.description.strip(),
        receipt_ref=data.receipt_ref.strip() if data.receipt_ref else None,
        authorized_by=data.authorized_by.strip() if data.authorized_by else None,
        created_at=utc_now(),
    )
    db.add(expense)
    db.flush()
    return expense


def record_dispatch_repayment(db: Session, dispatch_id: str, data: DispatchRepaymentCreate) -> DispatchRepayment:
    """Records cash repayment / handover by the responsible person to the company."""
    dispatch = get_dispatch(db, dispatch_id)
    if dispatch.status == "CANCELED":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Saida #{dispatch.dispatch_number} esta cancelada.",
        )
    if dispatch.status == "CONCLUDED":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Saida #{dispatch.dispatch_number} ja esta concluida e nao permite novos repasses.",
        )

    repayment = DispatchRepayment(
        id=str(uuid.uuid4()),
        dispatch_id=dispatch.id,
        repayment_date=data.repayment_date or utc_now(),
        amount_cents=data.amount_cents,
        payment_method=data.payment_method,
        received_by=data.received_by.strip() if data.received_by else None,
        notes=data.notes.strip() if data.notes else None,
        created_at=utc_now(),
    )
    db.add(repayment)
    db.flush()
    return repayment


# ==================== RECONCILIATION & SETTLEMENT ====================

def calculate_dispatch_reconciliation(db: Session, dispatch_id: str) -> DispatchReconciliationResponse:
    """
    Calculates live comprehensive reconciliation for a dispatch:
    - 4-term physical equation: Dispatched = Sold + Returned + Lost + Remaining in Custody
    - Segregated financial equation:
      Expected Cash = Cash Sales + Cash Debt Collected - Route Expenses
      Actual Repaid = sum(repayments)
      Pending Cash = Expected Cash - Actual Repaid
      Direct Company Receipts = Pix/Cards received straight into company account (not owed in cash)
    - Discrepancy flags and detailed item breakdowns.
    """
    dispatch = get_dispatch(db, dispatch_id)

    # 1. Fetch confirmed sales linked to this dispatch
    sales_stmt = (
        select(Sale)
        .options(selectinload(Sale.items).selectinload(SaleItem.basket_type))
        .where(
            Sale.dispatch_id == dispatch.id,
            Sale.status == "CONFIRMED",
        )
    )
    sales = list(db.execute(sales_stmt).scalars().all())

    # 2. Fetch receivable payments collected during this dispatch
    rec_pay_stmt = (
        select(ReceivablePayment)
        .where(
            ReceivablePayment.dispatch_id == dispatch.id,
            ReceivablePayment.status == "CONFIRMED",
        )
    )
    rec_payments = list(db.execute(rec_pay_stmt).scalars().all())

    # 3. Item breakdown computation
    # Aggregate dispatched per basket_type
    dispatched_map: Dict[str, Tuple[str, Optional[str], int]] = {}
    for it in dispatch.items:
        key = it.basket_type_id
        b_name = it.basket_type.name if it.basket_type else key
        prev = dispatched_map.get(key, (b_name, it.production_batch_id, 0))
        dispatched_map[key] = (b_name, it.production_batch_id, prev[2] + it.quantity)

    # Aggregate sold per basket_type
    sold_map: Dict[str, int] = {}
    for s in sales:
        for it in s.items:
            sold_map[it.basket_type_id] = sold_map.get(it.basket_type_id, 0) + it.quantity

    # Aggregate returned per basket_type
    returned_map: Dict[str, int] = {}
    for ret in dispatch.returns:
        returned_map[ret.basket_type_id] = returned_map.get(ret.basket_type_id, 0) + ret.quantity

    # Aggregate lost per basket_type
    lost_map: Dict[str, int] = {}
    for loss in dispatch.losses:
        lost_map[loss.basket_type_id] = lost_map.get(loss.basket_type_id, 0) + loss.quantity

    items_recon: List[DispatchItemReconciliation] = []
    total_dispatched = 0
    total_sold = 0
    total_returned = 0
    total_lost = 0
    total_remaining = 0
    total_basket_discrepancy = 0

    for b_id, (b_name, batch_id, d_qty) in dispatched_map.items():
        s_qty = sold_map.get(b_id, 0)
        r_qty = returned_map.get(b_id, 0)
        l_qty = lost_map.get(b_id, 0)

        # Remaining custody in TRANSIT for this person
        if batch_id:
            rem_qty = get_batch_stock(
                db, batch_id, location_type="TRANSIT", responsible_person_id=dispatch.responsible_person_id
            )
        else:
            rem_qty = get_basket_stock(
                db, b_id, location_type="TRANSIT", responsible_person_id=dispatch.responsible_person_id
            )

        # Discrepancy = Dispatched - (Sold + Returned + Lost + Remaining)
        # Note: If remaining custody includes other dispatches, capped at d_qty - (s+r+l)
        accounted_qty = s_qty + r_qty + l_qty + rem_qty
        discrepancy = d_qty - accounted_qty

        items_recon.append(
            DispatchItemReconciliation(
                basket_type_id=b_id,
                basket_type_name=b_name,
                production_batch_id=batch_id,
                dispatched_qty=d_qty,
                sold_qty=s_qty,
                returned_qty=r_qty,
                lost_qty=l_qty,
                remaining_custody_qty=rem_qty,
                discrepancy_qty=discrepancy,
            )
        )

        total_dispatched += d_qty
        total_sold += s_qty
        total_returned += r_qty
        total_lost += l_qty
        total_remaining += rem_qty
        total_basket_discrepancy += discrepancy

    # 4. Financial Calculations
    cash_sales_cents = sum(s.total_amount_cents for s in sales if s.payment_mode == "CASH_IMMEDIATE")
    direct_company_sales_cents = sum(s.total_amount_cents for s in sales if s.payment_mode in ["PIX", "CARD"])
    credit_sales_cents = sum(s.total_amount_cents for s in sales if s.payment_mode == "CREDIT_TERM")

    cash_debt_collected_cents = sum(p.amount_cents for p in rec_payments if p.payment_method == "CASH")
    direct_company_debt_cents = sum(p.amount_cents for p in rec_payments if p.payment_method in ["PIX", "CARD"])

    direct_company_received_cents = direct_company_sales_cents + direct_company_debt_cents
    expenses_cents = sum(e.amount_cents for e in dispatch.expenses)

    expected_cash_cents = (cash_sales_cents + cash_debt_collected_cents) - expenses_cents
    actual_repaid_cash_cents = sum(r.amount_cents for r in dispatch.repayments)
    pending_cash_cents = expected_cash_cents - actual_repaid_cash_cents
    cash_discrepancy_cents = actual_repaid_cash_cents - expected_cash_cents

    has_basket_disc = total_basket_discrepancy != 0
    has_cash_disc = cash_discrepancy_cents != 0

    # Latest settlement
    latest_settlement = None
    if dispatch.settlements:
        sorted_settlements = sorted(dispatch.settlements, key=lambda s: s.settled_at, reverse=True)
        latest_s = sorted_settlements[0]
        latest_settlement = DispatchSettlementResponse.model_validate(latest_s)

    returns_list = [
        DispatchReturnResponse(
            id=r.id,
            dispatch_id=r.dispatch_id,
            basket_type_id=r.basket_type_id,
            basket_type_name=r.basket_type.name if r.basket_type else None,
            production_batch_id=r.production_batch_id,
            quantity=r.quantity,
            returned_at=r.returned_at,
            notes=r.notes,
            created_at=r.created_at,
        )
        for r in dispatch.returns
    ]

    losses_list = [
        DispatchLossResponse(
            id=l.id,
            dispatch_id=l.dispatch_id,
            basket_type_id=l.basket_type_id,
            basket_type_name=l.basket_type.name if l.basket_type else None,
            production_batch_id=l.production_batch_id,
            quantity=l.quantity,
            occurred_at=l.occurred_at,
            reason=l.reason,
            created_at=l.created_at,
        )
        for l in dispatch.losses
    ]

    expenses_list = [
        DispatchExpenseResponse(
            id=e.id,
            dispatch_id=e.dispatch_id,
            expense_date=e.expense_date,
            amount_cents=e.amount_cents,
            description=e.description,
            receipt_ref=e.receipt_ref,
            authorized_by=e.authorized_by,
            created_at=e.created_at,
        )
        for e in dispatch.expenses
    ]

    repayments_list = [
        DispatchRepaymentResponse(
            id=rep.id,
            dispatch_id=rep.dispatch_id,
            repayment_date=rep.repayment_date,
            amount_cents=rep.amount_cents,
            payment_method=rep.payment_method,
            received_by=rep.received_by,
            notes=rep.notes,
            created_at=rep.created_at,
        )
        for rep in dispatch.repayments
    ]

    return DispatchReconciliationResponse(
        dispatch_id=dispatch.id,
        dispatch_number=dispatch.dispatch_number,
        responsible_person_id=dispatch.responsible_person_id,
        responsible_person_name=dispatch.responsible_person.name,
        dispatch_date=dispatch.dispatch_date,
        dispatch_status=dispatch.status,
        total_dispatched_qty=total_dispatched,
        total_sold_qty=total_sold,
        total_returned_qty=total_returned,
        total_lost_qty=total_lost,
        total_remaining_custody_qty=total_remaining,
        basket_discrepancy_qty=total_basket_discrepancy,
        cash_sales_cents=cash_sales_cents,
        direct_company_received_cents=direct_company_received_cents,
        credit_sales_cents=credit_sales_cents,
        cash_debt_collected_cents=cash_debt_collected_cents,
        expenses_cents=expenses_cents,
        expected_cash_cents=expected_cash_cents,
        actual_repaid_cash_cents=actual_repaid_cash_cents,
        pending_cash_cents=pending_cash_cents,
        cash_discrepancy_cents=cash_discrepancy_cents,
        has_basket_discrepancy=has_basket_disc,
        has_cash_discrepancy=has_cash_disc,
        items_reconciliation=items_recon,
        returns=returns_list,
        losses=losses_list,
        expenses=expenses_list,
        repayments=repayments_list,
        latest_settlement=latest_settlement,
    )


def execute_dispatch_settlement(db: Session, dispatch_id: str, data: DispatchSettlementCreate) -> DispatchSettlement:
    """
    Executes formal closing / settlement:
    - Calculates live 4-term physical and segregated financial reconciliation.
    - If discrepancies are 0 and no items remain in custody, marks RESOLVED and CONCLUDED.
    - If remaining items are legitimately in custody and cash is fully repaid, marks IN_CUSTODY_RESOLVED.
    - If unresolved physical or financial discrepancies exist, marks PENDING_INVESTIGATION.
    """
    dispatch = get_dispatch(db, dispatch_id)
    if dispatch.status == "CANCELED":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Saida #{dispatch.dispatch_number} esta cancelada e nao pode ser conferida.",
        )
    if dispatch.status == "CONCLUDED":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Saida #{dispatch.dispatch_number} ja esta concluida e nao pode ser conferida novamente.",
        )

    recon = calculate_dispatch_reconciliation(db, dispatch.id)

    # Determine status
    if recon.basket_discrepancy_qty == 0 and recon.cash_discrepancy_cents == 0:
        if recon.total_remaining_custody_qty == 0:
            settlement_status = "RESOLVED"
            dispatch.status = "CONCLUDED"
        else:
            settlement_status = "IN_CUSTODY_RESOLVED"
            dispatch.status = "CONCLUDED"
    else:
        settlement_status = "PENDING_INVESTIGATION"
        dispatch.status = "PENDING_INVESTIGATION"

    settled_at = data.settled_at or utc_now()
    settlement = DispatchSettlement(
        id=str(uuid.uuid4()),
        dispatch_id=dispatch.id,
        audited_by=data.audited_by.strip(),
        settled_at=settled_at,
        total_dispatched_qty=recon.total_dispatched_qty,
        total_sold_qty=recon.total_sold_qty,
        total_returned_qty=recon.total_returned_qty,
        total_lost_qty=recon.total_lost_qty,
        total_remaining_custody_qty=recon.total_remaining_custody_qty,
        basket_discrepancy_qty=recon.basket_discrepancy_qty,
        expected_cash_cents=recon.expected_cash_cents,
        actual_repaid_cash_cents=recon.actual_repaid_cash_cents,
        cash_discrepancy_cents=recon.cash_discrepancy_cents,
        direct_company_received_cents=recon.direct_company_received_cents,
        status=settlement_status,
        notes=data.notes.strip() if data.notes else None,
        investigation_notes=data.investigation_notes.strip() if data.investigation_notes else None,
        created_at=utc_now(),
        updated_at=utc_now(),
    )
    db.add(settlement)
    dispatch.updated_at = utc_now()
    db.flush()
    return settlement


def update_settlement_investigation(
    db: Session, dispatch_id: str, data: DispatchSettlementInvestigationUpdate
) -> DispatchSettlement:
    """Updates investigation notes on an existing settlement and optionally resolves it."""
    stmt = (
        select(DispatchSettlement)
        .where(DispatchSettlement.dispatch_id == dispatch_id)
        .order_by(desc(DispatchSettlement.settled_at))
        .limit(1)
    )
    settlement = db.execute(stmt).scalar_one_or_none()
    if not settlement:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Nenhum fechamento registrado para a saida '{dispatch_id}'.",
        )

    if settlement.investigation_notes:
        settlement.investigation_notes += f"\n[{utc_now().strftime('%Y-%m-%d %H:%M:%S')}] {data.investigation_notes.strip()}"
    else:
        settlement.investigation_notes = f"[{utc_now().strftime('%Y-%m-%d %H:%M:%S')}] {data.investigation_notes.strip()}"

    if data.mark_as_resolved:
        settlement.status = "RESOLVED"
        dispatch = db.get(StockDispatch, dispatch_id)
        if dispatch:
            dispatch.status = "CONCLUDED"
            dispatch.updated_at = utc_now()

    settlement.updated_at = utc_now()
    db.flush()
    return settlement
