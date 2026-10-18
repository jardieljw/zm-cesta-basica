"""Remove unused basket types physically; retain referenced types outside the catalog."""
from fastapi import HTTPException
from sqlalchemy import select, func
from sqlalchemy.orm import Session, selectinload
from app.models.products import BasketType, RecipeVersion
from app.models.production import ProductionBatch
from app.models.sales import Sale, SaleItem
from app.models.movements import InventoryMovement
from app.models.dispatches import StockDispatch, DispatchItem, DispatchReturn, DispatchLoss
from app.models.base import utc_now
from app.schemas.recipes import BasketDeletionCheck, BasketDeletionResponse


def require_catalog_entry(basket: BasketType) -> None:
    if basket.removed_at is not None:
        raise HTTPException(status_code=409, detail={
            'error_code': 'BASKET_REMOVED',
            'message': 'Este tipo de cesta foi excluido do catalogo e permanece somente no historico.',
        })


def _get_basket(db: Session, basket_id: str) -> BasketType:
    basket = db.execute(select(BasketType).options(selectinload(BasketType.recipes))
                        .where(BasketType.id == basket_id)).scalar_one_or_none()
    if basket is None:
        raise HTTPException(status_code=404, detail={'error_code': 'NOT_FOUND', 'message': 'Cesta nao encontrada.'})
    return basket


def _history_reasons(db: Session, basket_id: str) -> list[str]:
    references = [
        ('SALES', SaleItem), ('PRODUCTION', ProductionBatch), ('MOVEMENTS', InventoryMovement),
        ('DISPATCHES', DispatchItem), ('DISPATCHES', DispatchReturn), ('DISPATCHES', DispatchLoss),
    ]
    return list(dict.fromkeys(reason for reason, model in references
        if db.execute(select(model.id).where(model.basket_type_id == basket_id).limit(1)).first()))


def _blocking_reasons(db: Session, basket_id: str) -> list[str]:
    reasons = []
    active_sale = select(SaleItem.id).join(Sale, Sale.id == SaleItem.sale_id).where(
        SaleItem.basket_type_id == basket_id, Sale.status != 'CANCELED')
    if db.execute(active_sale.limit(1)).first():
        reasons.append('ACTIVE_SALES')
    # Do not let opposite balances across locations/custom lots hide a basket.
    stock = select(InventoryMovement.basket_type_id).where(
        InventoryMovement.basket_type_id == basket_id, InventoryMovement.item_type == 'BASKET',
    ).group_by(InventoryMovement.production_batch_id, InventoryMovement.location_type,
               InventoryMovement.responsible_person_id, InventoryMovement.basket_type_id
    ).having(func.sum(InventoryMovement.quantity_delta) != 0).limit(1)
    if db.execute(stock).first():
        reasons.append('STOCK_REMAINS')
    for model in (DispatchItem, DispatchReturn, DispatchLoss):
        active_dispatch = select(model.id).join(StockDispatch, StockDispatch.id == model.dispatch_id).where(
            model.basket_type_id == basket_id, StockDispatch.status.not_in(['CONCLUDED', 'CANCELED']))
        if db.execute(active_dispatch.limit(1)).first():
            reasons.append('ACTIVE_DISPATCHES')
            break
    return reasons


def check_basket_deletion(db: Session, basket_id: str) -> BasketDeletionCheck:
    basket = _get_basket(db, basket_id)
    history = _history_reasons(db, basket.id)
    reasons = _blocking_reasons(db, basket.id)
    if basket.removed_at is not None:
        reasons.append('REMOVED')
    return BasketDeletionCheck(id=basket.id, name=basket.name, can_delete=not reasons,
        deletion_mode='CATALOG_ONLY' if history else 'PERMANENT', reasons=reasons, history_reasons=history)


def delete_basket_from_catalog(db: Session, basket_id: str) -> BasketDeletionResponse:
    basket = _get_basket(db, basket_id)
    if basket.removed_at is not None:
        return BasketDeletionResponse(id=basket.id, name=basket.name, deleted=True, deletion_mode='CATALOG_ONLY')
    # Advisory UI checks cannot bypass references/stock introduced before confirmation.
    check = check_basket_deletion(db, basket.id)
    if not check.can_delete:
        raise HTTPException(status_code=409, detail={
            'error_code': 'BASKET_DELETE_BLOCKED', 'message': 'Resolva as vendas e o estoque antes de excluir a cesta.',
            'reasons': check.reasons,
        })
    response = BasketDeletionResponse(id=basket.id, name=basket.name, deleted=True, deletion_mode=check.deletion_mode)
    if check.deletion_mode == 'PERMANENT':
        response.removed_recipes_count = len(basket.recipes)
        for recipe in basket.recipes:
            db.delete(recipe)  # Only never-used recipes and their catalog ingredients.
        db.flush()
        db.delete(basket)
    else:
        basket.is_active = False
        basket.removed_at = utc_now()
    db.flush()
    return response
