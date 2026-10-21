"""Operational blockers, with records the operator can actually identify."""
from sqlalchemy import select, func, or_
from sqlalchemy.orm import Session
from app.models.products import Product, RecipeVersion, RecipeItem, BasketType
from app.models.sales import Sale, SaleItem, SaleRecipeReference
from app.models.production import ProductionBatch, ProductionBatchItem
from app.models.purchases import Purchase, PurchaseItem
from app.models.movements import InventoryMovement
from app.models.dispatches import ResponsiblePerson, StockDispatch, DispatchItem, DispatchReturn, DispatchLoss

def get_batch_disassembled_quantity(db, batch_id):
    return int(db.scalar(select(func.coalesce(func.sum(-InventoryMovement.quantity_delta), 0)).where(
        InventoryMovement.item_type == 'BASKET', InventoryMovement.movement_type == 'DISASSEMBLY_DEPARTURE',
        InventoryMovement.source_type == 'PRODUCTION', InventoryMovement.source_id == batch_id)) or 0)


def entry(kind, record_id, label, **target):
    return dict(kind=kind, id=record_id, label=label, target=target)


def location_name(db, location, person):
    name = {'STORE': 'Estoque da loja', 'TRANSIT': 'Em trânsito', 'RESPONSIBLE': 'Com responsável'}.get(location, location)
    responsible = db.get(ResponsiblePerson, person) if person else None
    return name + (f' · {responsible.name}' if responsible else '')


def recipe_sale_rows(db: Session, recipe: RecipeVersion):
    # Standard ready stock predates per-batch attribution. An unassigned sale
    # protects candidate recipes; a backdated sale must not bypass protection.
    has_reference = select(SaleRecipeReference.sale_item_id).where(
        SaleRecipeReference.sale_item_id == SaleItem.id).exists()
    exact_reference = select(SaleRecipeReference.sale_item_id).where(
        SaleRecipeReference.sale_item_id == SaleItem.id,
        SaleRecipeReference.recipe_version_id == recipe.id).exists()
    return db.execute(select(Sale, SaleItem).join(SaleItem).outerjoin(
        ProductionBatch, ProductionBatch.id == SaleItem.production_batch_id
    ).where(Sale.status != 'CANCELED', SaleItem.basket_type_id == recipe.basket_type_id,
        or_(ProductionBatch.recipe_version_id == recipe.id,
            SaleItem.production_batch_id.is_(None) & (exact_reference | ~has_reference))
    )).all()


def recipe_sales(db: Session, recipe: RecipeVersion):
    return list({sale.id: sale for sale, _ in recipe_sale_rows(db, recipe)}.values())


def sale_entry(sale):
    return entry('ACTIVE_SALES', sale.id,
        f"Venda nº {sale.sale_number} · {sale.customer_name or 'Cliente não informado'} · "
        f"{sale.sale_date:%d/%m/%Y}", sale_id=sale.id,
        receivable_id=sale.receivable.id if sale.receivable else None)


def recipe_blockers(db, recipe):
    blockers = [sale_entry(sale) for sale in recipe_sales(db, recipe)]
    for blocker in blockers:
        unknown = db.execute(select(SaleItem.id).where(SaleItem.sale_id == blocker['id'],
            SaleItem.basket_type_id == recipe.basket_type_id, SaleItem.production_batch_id.is_(None),
            ~select(SaleRecipeReference.sale_item_id).where(
                SaleRecipeReference.sale_item_id == SaleItem.id).exists()).limit(1)).first()
        if unknown:
            blocker['label'] += ' · Venda de estoque pronto sem receita identificada'
    for batch in db.execute(select(ProductionBatch).where(
            ProductionBatch.recipe_version_id == recipe.id)).scalars():
        if batch.status == 'CONFIRMED' and get_batch_disassembled_quantity(db, batch.id) < batch.quantity_produced:
            blockers.append(entry('PRODUCTION', batch.id,
                f"Montagem nº {batch.batch_number} · {batch.basket_type.name} · "
                f"{batch.quantity_produced - get_batch_disassembled_quantity(db, batch.id)} cesta(s) ainda não desmontada(s)",
                basket_id=batch.basket_type_id, batch_id=batch.id))
    return blockers


def product_blockers(db, product_id):
    blockers = []
    recipes = db.execute(select(RecipeVersion).join(RecipeItem).join(BasketType).where(
        RecipeItem.product_id == product_id, RecipeVersion.status != 'REMOVED',
        BasketType.removed_at.is_(None))).scalars().unique().all()
    for recipe in recipes:
        blockers.append(entry('RECIPES', recipe.id,
            f"{recipe.basket_type.name} · receita {recipe.version_number} · "
            f"{'em uso' if recipe.status == 'ACTIVE' else 'inativa'}",
            basket_id=recipe.basket_type_id, recipe_number=recipe.version_number))
        blockers.extend(sale_entry(sale) for sale in recipe_sales(db, recipe))
    for batch in db.execute(select(ProductionBatch).join(ProductionBatchItem).where(
            ProductionBatchItem.product_id == product_id)).scalars().unique():
        if batch.status == 'CONFIRMED' and get_batch_disassembled_quantity(db, batch.id) < batch.quantity_produced:
            blockers.append(entry('PRODUCTION', batch.id,
                f"Montagem nº {batch.batch_number} · {batch.basket_type.name}",
                basket_id=batch.basket_type_id, batch_id=batch.id))
        for sale in db.execute(select(Sale).join(SaleItem).where(
                SaleItem.production_batch_id == batch.id, Sale.status != 'CANCELED')).scalars():
            blockers.append(sale_entry(sale))
    for purchase in db.execute(select(Purchase).join(PurchaseItem).where(
            PurchaseItem.product_id == product_id, Purchase.status != 'CANCELED')).scalars().unique():
        blockers.append(entry('PURCHASES', purchase.id,
            f"Compra nº {purchase.purchase_number} · {purchase.supplier_name or 'Fornecedor não informado'} · "
            + {'DRAFT': 'Rascunho', 'CONFIRMED': 'Confirmada'}.get(purchase.status, purchase.status),
            purchase_id=purchase.id))
    balances = db.execute(select(InventoryMovement.location_type,
        InventoryMovement.responsible_person_id, func.sum(InventoryMovement.quantity_delta)).where(
        InventoryMovement.product_id == product_id).group_by(InventoryMovement.location_type,
        InventoryMovement.responsible_person_id)).all()
    product = db.get(Product, product_id)
    for location, person, balance in balances:
        if balance:
            blockers.append(entry('STOCK_REMAINS', product_id,
                f"Saldo de estoque: {balance} " + {'UNIT': 'un', 'G': 'g', 'ML': 'ml'}.get(product.base_unit, product.base_unit)
                + ' · ' + location_name(db, location, person), product_id=product_id))
    return list({(x['kind'], x['id'], x['label']): x for x in blockers}.values())


def basket_blockers(db, basket_id):
    blockers = [sale_entry(sale) for sale in db.execute(select(Sale).join(SaleItem).where(
        SaleItem.basket_type_id == basket_id, Sale.status != 'CANCELED')).scalars().unique()]
    for batch in db.execute(select(ProductionBatch).where(ProductionBatch.basket_type_id == basket_id)).scalars():
        if batch.status == 'CONFIRMED' and get_batch_disassembled_quantity(db, batch.id) < batch.quantity_produced:
            blockers.append(entry('PRODUCTION', batch.id,
                f"Montagem nº {batch.batch_number} · "
                f"{batch.quantity_produced - get_batch_disassembled_quantity(db, batch.id)} cesta(s) ainda não desmontada(s)",
                basket_id=basket_id, batch_id=batch.id))
    balances = db.execute(select(InventoryMovement.location_type, InventoryMovement.responsible_person_id,
        InventoryMovement.production_batch_id, func.sum(InventoryMovement.quantity_delta)).where(
        InventoryMovement.basket_type_id == basket_id, InventoryMovement.item_type == 'BASKET').group_by(
        InventoryMovement.location_type, InventoryMovement.responsible_person_id,
        InventoryMovement.production_batch_id)).all()
    for location, person, batch_id, balance in balances:
        if balance:
            blockers.append(entry('STOCK_REMAINS', batch_id or basket_id,
                f'Saldo de {balance} cesta(s) · ' + location_name(db, location, person),
                basket_id=basket_id, **({'batch_id': batch_id} if batch_id else {})))
    for model in (DispatchItem, DispatchReturn, DispatchLoss):
        for dispatch in db.execute(select(StockDispatch).join(model, model.dispatch_id == StockDispatch.id).where(
                model.basket_type_id == basket_id, StockDispatch.status.not_in(['CONCLUDED', 'CANCELED']))).scalars().unique():
            blockers.append(entry('ACTIVE_DISPATCHES', dispatch.id,
                f'Saída nº {dispatch.dispatch_number} · {dispatch.responsible_person.name} · Ainda não concluída'))
    blockers = list({(x['kind'], x['id'], x['label']): x for x in blockers}.values())
    return blockers
