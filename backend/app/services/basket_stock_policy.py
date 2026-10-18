"""Shared rules for opting a basket type into ready-stock operations."""
from fastapi import HTTPException
from sqlalchemy import select, func
from sqlalchemy.orm import Session
from app.models.products import BasketType
from app.services.basket_catalog import require_catalog_entry
from app.models.movements import InventoryMovement


def require_finished_stock(basket: BasketType) -> None:
    require_catalog_entry(basket)
    if not basket.tracks_finished_stock:
        raise HTTPException(status_code=409, detail={
            "error_code": "BASKET_STOCK_DISABLED",
            "message": "Esta cesta esta configurada para montagem na venda.",
        })


def require_customization(basket: BasketType) -> None:
    if not basket.allows_customization:
        raise HTTPException(status_code=409, detail={
            "error_code": "CUSTOMIZATION_DISABLED",
            "message": "Este tipo de cesta nao permite personalizacao. Confira seu cadastro.",
        })


def validate_disable_finished_stock(db: Session, basket: BasketType) -> None:
    # Check every location/custom lot independently: aggregate balances must not
    # hide an existing ready basket in another location or under custody.
    stock = select(InventoryMovement.basket_type_id).where(
        InventoryMovement.basket_type_id == basket.id,
        InventoryMovement.item_type == "BASKET",
    ).group_by(
        InventoryMovement.production_batch_id,
        InventoryMovement.location_type,
        InventoryMovement.responsible_person_id,
        InventoryMovement.basket_type_id,
    ).having(func.sum(InventoryMovement.quantity_delta) > 0).limit(1)
    if db.execute(stock).first():
        raise HTTPException(status_code=409, detail={
            "error_code": "BASKET_STOCK_REMAINS",
            "message": "Ha cestas prontas em estoque. Resolva esse saldo antes de desativar a opcao.",
        })
