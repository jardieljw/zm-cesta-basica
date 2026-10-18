"""Explicit permanent deletion of unused catalog entries; preserve all history."""
from fastapi import HTTPException, status
from sqlalchemy import select, or_
from sqlalchemy.orm import Session, selectinload
from app.models.products import Product, ProductPackaging, RecipeItem
from app.models.purchases import PurchaseItem
from app.models.production import ProductionBatchItem
from app.models.movements import InventoryMovement
from app.schemas.products import ProductDeletionCheck, ProductDeletionResponse


def _get_product(db: Session, product_id: str) -> Product:
    product = db.execute(select(Product).options(selectinload(Product.packagings))
                         .where(Product.id == product_id)).scalar_one_or_none()
    if product is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND,
            detail={"error_code": "NOT_FOUND", "message": "Produto não encontrado."})
    return product


def _usage_reasons(db: Session, product_id: str):
    package_ids = select(ProductPackaging.id).where(ProductPackaging.product_id == product_id)
    references = [
        ("RECIPES", select(RecipeItem.id).where(RecipeItem.product_id == product_id)),
        ("PURCHASES", select(PurchaseItem.id).where(or_(
            PurchaseItem.product_id == product_id, PurchaseItem.packaging_id.in_(package_ids)))),
        ("PRODUCTION", select(ProductionBatchItem.id).where(ProductionBatchItem.product_id == product_id)),
        ("MOVEMENTS", select(InventoryMovement.id).where(InventoryMovement.product_id == product_id)),
    ]
    # Any version/status counts, including drafts, cancellations and old recipes.
    return [reason for reason, query in references if db.execute(query.limit(1)).first() is not None]


def check_product_deletion(db: Session, product_id: str) -> ProductDeletionCheck:
    product = _get_product(db, product_id)
    reasons = _usage_reasons(db, product.id)
    return ProductDeletionCheck(id=product.id, name=product.name, can_delete=not reasons, reasons=reasons)


def delete_unused_product(db: Session, product_id: str) -> ProductDeletionResponse:
    # Recheck inside the same BEGIN IMMEDIATE transaction used for deletion.
    # A prior UI check is advisory; it cannot bypass new references or history.
    product = _get_product(db, product_id)
    reasons = _usage_reasons(db, product.id)
    if reasons:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail={
            "error_code": "PRODUCT_HAS_HISTORY",
            "message": "Este produto possui vínculos ou histórico e não pode ser excluído definitivamente.",
            "reasons": reasons,
        })
    response = ProductDeletionResponse(id=product.id, name=product.name, deleted=True,
                                      removed_packagings_count=len(product.packagings))
    # Only unused dependent catalog packagings cascade; no transaction rows deleted.
    db.delete(product)
    db.flush()
    return response
