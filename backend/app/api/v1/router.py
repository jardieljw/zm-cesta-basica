from fastapi import APIRouter
from app.api.v1.health import router as health_router
from app.api.v1.auth import router as auth_router
from app.api.v1.backup import router as backup_router
from app.api.v1.test_ops import router as test_ops_router
from app.api.v1.products import router as products_router
from app.api.v1.basket_types import router as basket_types_router
from app.api.v1.inventory import router as inventory_router
from app.api.v1.purchases import router as purchases_router
from app.api.v1.production import router as production_router

api_v1_router = APIRouter()

api_v1_router.include_router(health_router, tags=["Health"])
api_v1_router.include_router(auth_router, tags=["Auth & Pairing"])
api_v1_router.include_router(backup_router, tags=["Backup & Restore"])
api_v1_router.include_router(test_ops_router, tags=["Test Operations"])
api_v1_router.include_router(products_router, tags=["Products & Packagings"])
api_v1_router.include_router(basket_types_router, tags=["Basket Types & Recipes"])
api_v1_router.include_router(inventory_router, tags=["Inventory & Ledger"])
api_v1_router.include_router(purchases_router, tags=["Purchases"])
api_v1_router.include_router(production_router, tags=["Production & Assembly"])
