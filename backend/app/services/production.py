import uuid
import datetime
from decimal import Decimal, ROUND_HALF_EVEN
from typing import Optional, List, Tuple, Dict, Union, Any
from sqlalchemy import select, func, or_, desc
from sqlalchemy.orm import Session, selectinload
from fastapi import HTTPException, status

from app.models.production import ProductionBatch, ProductionBatchItem
from app.models.products import Product, BasketType, RecipeVersion, RecipeItem
from app.models.movements import InventoryMovement
from app.models.base import utc_now
from app.schemas.production import (
    ProductionBatchCreate,
    ProductionPreviewRequest,
    ProductionPreviewResponse,
    ProductionPreviewItemResponse,
    DisassemblyRequest,
)
from app.services.inventory import (
    get_product_stock,
    get_basket_stock,
    get_batch_stock,
    get_batch_disassembled_quantity,
    record_inventory_movement,
)


def round_half_even(val: Decimal | float | int) -> int:
    """Standard banking round (half-even) returning integer."""
    d = Decimal(str(val)) if not isinstance(val, Decimal) else val
    return int(d.quantize(Decimal("1"), rounding=ROUND_HALF_EVEN))


def generate_next_batch_number(db: Session) -> int:
    """Generates next unique sequential batch number under active transaction lock."""
    stmt = select(func.coalesce(func.max(ProductionBatch.batch_number), 0))
    max_num = db.execute(stmt).scalar_one()
    return int(max_num) + 1


def calculate_ingredient_cost(quantity_base: int, unit_cost_microcents: int) -> int:
    """
    Computes ingredient line cost in integer cents from fixed-scale microcents CMPM.
    Formula: round((Q_i * CMPM_microcents) / 10000) using ROUND_HALF_EVEN.
    """
    if quantity_base <= 0 or unit_cost_microcents <= 0:
        return 0
    return int(
        (Decimal(quantity_base) * Decimal(unit_cost_microcents) / Decimal(10000))
        .quantize(Decimal("1"), rounding=ROUND_HALF_EVEN)
    )


def calculate_batch_unit_cost(total_cost_cents: int, quantity_produced: int) -> int:
    """
    Computes finished basket unit cost in integer cents.
    Formula: round(Total_cents / N_baskets) using ROUND_HALF_EVEN.
    """
    if quantity_produced <= 0 or total_cost_cents <= 0:
        return 0
    return int(
        (Decimal(total_cost_cents) / Decimal(quantity_produced))
        .quantize(Decimal("1"), rounding=ROUND_HALF_EVEN)
    )


def preview_production(
    db: Session, data: Union[ProductionPreviewRequest, ProductionBatchCreate]
) -> ProductionPreviewResponse:
    """
    Pre-flight simulation for production assembly.
    Validates recipe/custom items, computes live ingredient requirements,
    detects shortages and calculates estimated unit and total batch costs.
    """
    basket_type = db.get(BasketType, data.basket_type_id)
    if not basket_type:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Tipo de cesta '{data.basket_type_id}' nao encontrado.",
        )
    if not basket_type.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Tipo de cesta '{basket_type.name}' esta inativo e nao pode ser montado.",
        )

    preview_items: List[ProductionPreviewItemResponse] = []
    missing_items: List[ProductionPreviewItemResponse] = []
    recipe_version_number: Optional[int] = None

    if not data.is_custom:
        # Load active recipe version
        recipe_stmt = (
            select(RecipeVersion)
            .options(
                selectinload(RecipeVersion.items).selectinload(RecipeItem.product)
            )
            .where(
                RecipeVersion.basket_type_id == basket_type.id,
                RecipeVersion.status == "ACTIVE",
            )
        )
        recipe = db.execute(recipe_stmt).scalar_one_or_none()
        if not recipe or not recipe.items:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Cesta '{basket_type.name}' nao possui receita ativa cadastrada com ingredientes.",
            )
        recipe_version_number = recipe.version_number

        for r_item in recipe.items:
            prod = r_item.product
            req_qty = r_item.quantity_in_base_units * data.quantity_produced
            current_stk = get_product_stock(db, prod.id)
            is_suff = current_stk >= req_qty
            missing_qty = max(0, req_qty - current_stk)

            microcents = prod.cost_price_microcents or (prod.cost_price_cents * 10000)
            item_cost = calculate_ingredient_cost(req_qty, microcents)

            p_item = ProductionPreviewItemResponse(
                product_id=prod.id,
                product_name=prod.name,
                product_base_unit=prod.base_unit,
                section=r_item.section,
                quantity_per_basket=r_item.quantity_in_base_units,
                quantity_required=req_qty,
                current_stock=current_stk,
                is_sufficient=is_suff,
                missing_quantity=missing_qty,
                unit_cost_microcents=microcents,
                total_cost_cents=item_cost,
            )
            preview_items.append(p_item)
            if not is_suff:
                missing_items.append(p_item)
    else:
        # Custom basket preview
        if not data.custom_items:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Montagem personalizada exige ao menos um insumo na lista de composicao.",
            )

        # Consolidate duplicate products if provided
        consolidated: Dict[str, Tuple[int, str]] = {}
        for c_item in data.custom_items:
            sec = c_item.section or "PERSONALIZADO"
            if c_item.product_id in consolidated:
                prev_qty, _ = consolidated[c_item.product_id]
                consolidated[c_item.product_id] = (prev_qty + c_item.quantity_in_base_units, sec)
            else:
                consolidated[c_item.product_id] = (c_item.quantity_in_base_units, sec)

        for prod_id, (qty_per_basket, sec) in consolidated.items():
            prod = db.get(Product, prod_id)
            if not prod:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"Produto '{prod_id}' nao encontrado.",
                )
            if not prod.is_active:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Produto '{prod.name}' esta inativo.",
                )

            req_qty = qty_per_basket * data.quantity_produced
            current_stk = get_product_stock(db, prod.id)
            is_suff = current_stk >= req_qty
            missing_qty = max(0, req_qty - current_stk)

            microcents = prod.cost_price_microcents or (prod.cost_price_cents * 10000)
            item_cost = calculate_ingredient_cost(req_qty, microcents)

            p_item = ProductionPreviewItemResponse(
                product_id=prod.id,
                product_name=prod.name,
                product_base_unit=prod.base_unit,
                section=sec,
                quantity_per_basket=qty_per_basket,
                quantity_required=req_qty,
                current_stock=current_stk,
                is_sufficient=is_suff,
                missing_quantity=missing_qty,
                unit_cost_microcents=microcents,
                total_cost_cents=item_cost,
            )
            preview_items.append(p_item)
            if not is_suff:
                missing_items.append(p_item)

    total_cost_cents = sum(it.total_cost_cents for it in preview_items)
    unit_cost_cents = calculate_batch_unit_cost(total_cost_cents, data.quantity_produced)

    return ProductionPreviewResponse(
        can_produce=len(missing_items) == 0,
        basket_type_id=basket_type.id,
        basket_type_name=basket_type.name,
        recipe_version_number=recipe_version_number,
        quantity_produced=data.quantity_produced,
        estimated_unit_cost_cents=unit_cost_cents,
        estimated_total_cost_cents=total_cost_cents,
        items=preview_items,
        missing_items=missing_items,
    )


def create_production_batch(db: Session, data: ProductionBatchCreate) -> ProductionBatch:
    """
    Executes atomic production assembly under active BEGIN IMMEDIATE transaction lock.
    Performs strict stock sufficiency validation of all ingredients before mutating ledger.
    Appends ASSEMBLY_CONSUME movements for ingredients and ASSEMBLY_PRODUCE movement for finished baskets.
    Preserves exact microcents CMPM precision and immutably freezes unit_cost_cents.
    """
    basket_type = db.get(BasketType, data.basket_type_id)
    if not basket_type:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Tipo de cesta '{data.basket_type_id}' nao encontrado.",
        )
    if not basket_type.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Tipo de cesta '{basket_type.name}' esta inativo e nao pode ser montado.",
        )

    batch_id = str(uuid.uuid4())
    batch_num = generate_next_batch_number(db)
    occurred = data.occurred_at or utc_now()

    if not data.is_custom:
        # 1. Standard Basket Assembly
        recipe_stmt = (
            select(RecipeVersion)
            .options(
                selectinload(RecipeVersion.items).selectinload(RecipeItem.product)
            )
            .where(
                RecipeVersion.basket_type_id == basket_type.id,
                RecipeVersion.status == "ACTIVE",
            )
        )
        recipe = db.execute(recipe_stmt).scalar_one_or_none()
        if not recipe or not recipe.items:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Cesta '{basket_type.name}' nao possui receita ativa cadastrada com ingredientes.",
            )

        # Atomic pre-validation of all ingredients
        missing_items = []
        for r_item in recipe.items:
            req_qty = r_item.quantity_in_base_units * data.quantity_produced
            current_stk = get_product_stock(db, r_item.product_id)
            if current_stk < req_qty:
                missing_items.append({
                    "product_id": r_item.product_id,
                    "product_name": r_item.product.name,
                    "current_stock": current_stk,
                    "required_quantity": req_qty,
                    "missing_quantity": req_qty - current_stk,
                })

        if missing_items:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail={
                    "error_code": "INSUFFICIENT_STOCK",
                    "message": f"Estoque insuficiente para produzir {data.quantity_produced} cesta(s) '{basket_type.name}'.",
                    "missing_items": missing_items,
                },
            )

        # Calculate costs and build batch items
        batch_items: List[ProductionBatchItem] = []
        total_batch_cost = 0

        for r_item in recipe.items:
            consumed_qty = r_item.quantity_in_base_units * data.quantity_produced
            prod = r_item.product
            microcents = prod.cost_price_microcents or (prod.cost_price_cents * 10000)
            item_cost = calculate_ingredient_cost(consumed_qty, microcents)
            total_batch_cost += item_cost

            b_item = ProductionBatchItem(
                id=str(uuid.uuid4()),
                batch_id=batch_id,
                product_id=prod.id,
                quantity_consumed_base_units=consumed_qty,
                section=r_item.section,
                unit_cost_microcents=microcents,
                total_cost_cents=item_cost,
            )
            batch_items.append(b_item)

        unit_cost = calculate_batch_unit_cost(total_batch_cost, data.quantity_produced)

        batch = ProductionBatch(
            id=batch_id,
            batch_number=batch_num,
            basket_type_id=basket_type.id,
            recipe_version_id=recipe.id,
            quantity_produced=data.quantity_produced,
            status="CONFIRMED",
            is_custom=False,
            is_direct_sale=data.is_direct_sale,
            custom_description=None,
            occurred_at=occurred,
            unit_cost_cents=unit_cost,
            total_cost_cents=total_batch_cost,
            notes=data.notes.strip() if data.notes else None,
        )
        batch.items = batch_items
        db.add(batch)

        # Ledger movements:
        # a) Consume ingredients (item_type=PRODUCT, basket_type_id=None, production_batch_id=None)
        for r_item in recipe.items:
            consumed_qty = r_item.quantity_in_base_units * data.quantity_produced
            record_inventory_movement(
                db=db,
                item_type="PRODUCT",
                movement_type="ASSEMBLY_CONSUME",
                quantity_delta=-consumed_qty,
                source_type="PRODUCTION",
                source_id=batch.id,
                product_id=r_item.product_id,
                basket_type_id=None,
                production_batch_id=None,
                occurred_at=occurred,
                reason=f"Consumo de insumos para montagem do lote #{batch.batch_number} ({basket_type.name})",
            )

        # b) Produce finished standard baskets (item_type=BASKET, basket_type_id=ID, production_batch_id=None)
        record_inventory_movement(
            db=db,
            item_type="BASKET",
            movement_type="ASSEMBLY_PRODUCE",
            quantity_delta=+data.quantity_produced,
            source_type="PRODUCTION",
            source_id=batch.id,
            product_id=None,
            basket_type_id=basket_type.id,
            production_batch_id=None,
            occurred_at=occurred,
            reason=f"Entrada de cestas acabadas do lote #{batch.batch_number} ({basket_type.name})",
        )

        db.flush()
        return batch

    else:
        # 2. Custom Basket Assembly
        if not data.custom_description or not data.custom_description.strip():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Descricao obrigatoria para montagem de cesta personalizada.",
            )
        if not data.custom_items:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Montagem personalizada exige ao menos um insumo na lista de composicao.",
            )

        # Consolidate duplicate products if provided
        consolidated: Dict[str, Tuple[int, str]] = {}
        for c_item in data.custom_items:
            sec = c_item.section or "PERSONALIZADO"
            if c_item.product_id in consolidated:
                prev_qty, _ = consolidated[c_item.product_id]
                consolidated[c_item.product_id] = (prev_qty + c_item.quantity_in_base_units, sec)
            else:
                consolidated[c_item.product_id] = (c_item.quantity_in_base_units, sec)

        # Atomic pre-validation of all ingredients
        missing_items = []
        for prod_id, (qty_per_basket, sec) in consolidated.items():
            prod = db.get(Product, prod_id)
            if not prod:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"Produto '{prod_id}' nao encontrado.",
                )
            if not prod.is_active:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Produto '{prod.name}' esta inativo.",
                )
            req_qty = qty_per_basket * data.quantity_produced
            current_stk = get_product_stock(db, prod.id)
            if current_stk < req_qty:
                missing_items.append({
                    "product_id": prod.id,
                    "product_name": prod.name,
                    "current_stock": current_stk,
                    "required_quantity": req_qty,
                    "missing_quantity": req_qty - current_stk,
                })

        if missing_items:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail={
                    "error_code": "INSUFFICIENT_STOCK",
                    "message": f"Estoque insuficiente para produzir {data.quantity_produced} cesta(s) personalizada(s).",
                    "missing_items": missing_items,
                },
            )

        # Calculate costs and build immutable snapshot items
        batch_items = []
        total_batch_cost = 0

        for prod_id, (qty_per_basket, sec) in consolidated.items():
            prod = db.get(Product, prod_id)
            consumed_qty = qty_per_basket * data.quantity_produced
            microcents = prod.cost_price_microcents or (prod.cost_price_cents * 10000)
            item_cost = calculate_ingredient_cost(consumed_qty, microcents)
            total_batch_cost += item_cost

            b_item = ProductionBatchItem(
                id=str(uuid.uuid4()),
                batch_id=batch_id,
                product_id=prod.id,
                quantity_consumed_base_units=consumed_qty,
                section=sec,
                unit_cost_microcents=microcents,
                total_cost_cents=item_cost,
            )
            batch_items.append(b_item)

        unit_cost = calculate_batch_unit_cost(total_batch_cost, data.quantity_produced)

        batch = ProductionBatch(
            id=batch_id,
            batch_number=batch_num,
            basket_type_id=basket_type.id,
            recipe_version_id=None,
            quantity_produced=data.quantity_produced,
            status="CONFIRMED",
            is_custom=True,
            is_direct_sale=data.is_direct_sale,
            custom_description=data.custom_description.strip(),
            occurred_at=occurred,
            unit_cost_cents=unit_cost,
            total_cost_cents=total_batch_cost,
            notes=data.notes.strip() if data.notes else None,
        )
        batch.items = batch_items
        db.add(batch)

        # Ledger movements:
        # a) Consume ingredients (item_type=PRODUCT, basket_type_id=None, production_batch_id=None)
        for prod_id, (qty_per_basket, sec) in consolidated.items():
            consumed_qty = qty_per_basket * data.quantity_produced
            record_inventory_movement(
                db=db,
                item_type="PRODUCT",
                movement_type="ASSEMBLY_CONSUME",
                quantity_delta=-consumed_qty,
                source_type="PRODUCTION",
                source_id=batch.id,
                product_id=prod_id,
                basket_type_id=None,
                production_batch_id=None,
                occurred_at=occurred,
                reason=f"Consumo de insumos para lote personalizado #{batch.batch_number} ({batch.custom_description})",
            )

        # b) Produce finished custom baskets (item_type=BASKET, basket_type_id=ID, production_batch_id=BATCH_ID)
        record_inventory_movement(
            db=db,
            item_type="BASKET",
            movement_type="ASSEMBLY_PRODUCE",
            quantity_delta=+data.quantity_produced,
            source_type="PRODUCTION",
            source_id=batch.id,
            product_id=None,
            basket_type_id=basket_type.id,
            production_batch_id=batch.id,
            occurred_at=occurred,
            reason=f"Entrada de cestas personalizadas do lote #{batch.batch_number} ({batch.custom_description})",
        )

        db.flush()
        return batch


def disassemble_production_batch(
    db: Session, batch_id: str, data: DisassemblyRequest
) -> Tuple[ProductionBatch, int, int, int]:
    """
    Executes disassembly / reversal of finished baskets under active BEGIN IMMEDIATE transaction lock.
    Enforces that finished baskets are actually on-hand before permitting disassembly (cannot disassemble sold baskets).
    Performs item-by-item triage:
      - Intact ingredients return to physical stock (STORE) via DISASSEMBLY_RETURN.
      - Damaged/violated ingredients are recorded as accounting loss (ASSEMBLY_LOSS) without fictitious stock return.
    """
    stmt = (
        select(ProductionBatch)
        .options(
            selectinload(ProductionBatch.items).selectinload(ProductionBatchItem.product),
            selectinload(ProductionBatch.basket_type),
        )
        .where(ProductionBatch.id == batch_id)
    )
    batch = db.execute(stmt).scalar_one_or_none()
    if not batch:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Lote de producao '{batch_id}' nao encontrado.",
        )

    if batch.status != "CONFIRMED":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Apenas lotes confirmados podem ser desmontados ou estornados. Status atual: {batch.status}.",
        )

    already_disassembled = get_batch_disassembled_quantity(db, batch.id)
    remaining_in_batch = batch.quantity_produced - already_disassembled
    if remaining_in_batch <= 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Lote #{batch.batch_number} ja foi integralmente desmontado.",
        )

    qty_to_disassemble = data.quantity_to_disassemble if data.quantity_to_disassemble is not None else remaining_in_batch
    if qty_to_disassemble <= 0 or qty_to_disassemble > remaining_in_batch:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                f"Quantidade a desmontar ({qty_to_disassemble}) invalida. "
                f"Saldo restante do lote: {remaining_in_batch} "
                f"(produzido: {batch.quantity_produced}, ja desmontado: {already_disassembled})."
            ),
        )

    # Validate that finished baskets are available in stock
    if batch.is_custom:
        current_finished_stock = get_batch_stock(db, batch.id)
    else:
        current_finished_stock = get_basket_stock(db, batch.basket_type_id)

    if current_finished_stock < qty_to_disassemble:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={
                "error_code": "INSUFFICIENT_STOCK",
                "message": (
                    f"Saldo de cestas acabadas insuficiente para desmontagem. "
                    f"Saldo atual em estoque: {current_finished_stock}, solicitado para desmontar: {qty_to_disassemble}. "
                    "Nao e permitido desmontar cestas que ja foram vendidas ou expedidas."
                ),
                "current_stock": current_finished_stock,
                "requested_disassembly": qty_to_disassemble,
            },
        )

    # Process triage per item
    batch_product_ids = {it.product_id for it in batch.items}
    triage_map: Dict[str, Any] = {}
    if data.triage_items:
        for t in data.triage_items:
            if t.product_id not in batch_product_ids:
                prod = db.get(Product, t.product_id)
                prod_name = prod.name if prod else t.product_id
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Produto '{prod_name}' na triagem nao pertence a composicao deste lote.",
                )
            if t.product_id in triage_map:
                prod = db.get(Product, t.product_id)
                prod_name = prod.name if prod else t.product_id
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Produto '{prod_name}' informado em duplicidade na triagem.",
                )
            triage_map[t.product_id] = t

    intact_returned_count = 0
    loss_recorded_count = 0
    now = utc_now()

    for item in batch.items:
        consumed_per_basket = item.quantity_consumed_base_units // batch.quantity_produced
        total_consumed_for_disassembly = consumed_per_basket * qty_to_disassemble

        if item.product_id in triage_map:
            triage = triage_map[item.product_id]
            if triage.intact_quantity + triage.loss_quantity != total_consumed_for_disassembly:
                prod = item.product or db.get(Product, item.product_id)
                prod_name = prod.name if prod else item.product_id
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=(
                        f"Divergencia na triagem do produto '{prod_name}': a soma de intactos ({triage.intact_quantity}) "
                        f"e avariados ({triage.loss_quantity}) deve totalizar exatamente {total_consumed_for_disassembly}."
                    ),
                )
            intact_qty = triage.intact_quantity
            loss_qty = triage.loss_quantity
            loss_reason = triage.loss_reason
        else:
            # Default: 100% intact returns to inventory
            intact_qty = total_consumed_for_disassembly
            loss_qty = 0
            loss_reason = None

        prod = item.product or db.get(Product, item.product_id)
        unit = prod.base_unit if prod else "un"

        # a) Return intact items to stock (STORE)
        if intact_qty > 0:
            record_inventory_movement(
                db=db,
                item_type="PRODUCT",
                movement_type="DISASSEMBLY_RETURN",
                quantity_delta=+intact_qty,
                source_type="PRODUCTION",
                source_id=batch.id,
                product_id=item.product_id,
                basket_type_id=None,
                production_batch_id=None,
                occurred_at=now,
                reason=f"Retorno de insumos intactos da desmontagem do lote #{batch.batch_number}: {data.reason}",
            )
            intact_returned_count += 1

        # b) Log damaged/loss items as ASSEMBLY_LOSS WITHOUT fictitious inventory entry!
        if loss_qty > 0:
            record_inventory_movement(
                db=db,
                item_type="PRODUCT",
                movement_type="ASSEMBLY_LOSS",
                quantity_delta=0,
                source_type="PRODUCTION",
                source_id=batch.id,
                product_id=item.product_id,
                basket_type_id=None,
                production_batch_id=None,
                occurred_at=now,
                reason=f"Perda/avaria contabil na desmontagem do lote #{batch.batch_number}: {loss_qty} {unit} descartados. Motivo: {loss_reason or data.reason}",
            )
            loss_recorded_count += 1

    # c) Deduct finished baskets from stock
    record_inventory_movement(
        db=db,
        item_type="BASKET",
        movement_type="DISASSEMBLY_DEPARTURE",
        quantity_delta=-qty_to_disassemble,
        source_type="PRODUCTION",
        source_id=batch.id,
        product_id=None,
        basket_type_id=batch.basket_type_id,
        production_batch_id=batch.id if batch.is_custom else None,
        occurred_at=now,
        reason=f"Baixa de cestas acabadas por desmontagem do lote #{batch.batch_number}: {data.reason}",
    )

    # If all produced baskets in the batch were disassembled cumulatively:
    if (already_disassembled + qty_to_disassemble) >= batch.quantity_produced:
        batch.status = "DISASSEMBLED"
        batch.canceled_at = now
        batch.cancellation_reason = data.reason

    db.flush()
    return batch, intact_returned_count, loss_recorded_count, qty_to_disassemble
