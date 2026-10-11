import json
import uuid
from typing import Optional
from pydantic import BaseModel, Field
from fastapi import APIRouter, Depends, Header, Response
from sqlalchemy.orm import Session
from sqlalchemy import select, func
from app.core.database import get_db
from app.core.idempotency import process_transactional_idempotency
from app.api.deps import get_current_device
from app.models.auth import PairedDevice
from app.models.movements import InventoryMovement
from app.models.products import Product
from app.models.base import utc_now

router = APIRouter()

class StockSimulationRequest(BaseModel):
    product_id: str
    quantity_delta: int = Field(..., description="Quantidade para movimentar (positivo ou negativo)")
    reason: Optional[str] = "Simulacao de Teste Fase 1"

class StockSimulationResponse(BaseModel):
    movement_id: str
    product_id: str
    quantity_delta: int
    current_calculated_balance: int
    is_replay: bool
    operation_type: str

@router.post("/test-ops/stock-simulation", response_model=StockSimulationResponse)
def simulate_stock_movement(
    req: StockSimulationRequest,
    x_idempotency_key: Optional[str] = Header(None, alias="X-Idempotency-Key"),
    current_device: PairedDevice = Depends(get_current_device),
    db: Session = Depends(get_db),
):
    """
    Phase 1 test endpoint to validate transactional idempotency and concurrency.
    Applies an atomic inventory ledger movement under BEGIN IMMEDIATE.
    """
    op_type = "TEST_STOCK_SIMULATION"
    payload_dict = req.model_dump()

    def business_logic(session: Session):
        # Ensure product exists (or create dummy for test)
        prod = session.execute(
            select(Product).where(Product.id == req.product_id)
        ).scalar_one_or_none()

        if prod is None:
            prod = Product(
                id=req.product_id,
                name=f"Produto Teste {req.product_id}",
                category="ALIMENTACAO",
                base_unit="UNIT",
                minimum_stock=0,
                created_at=utc_now(),
                updated_at=utc_now(),
            )
            session.add(prod)
            session.flush()

        # Insert movement into ledger
        movement_id = str(uuid.uuid4())
        mov = InventoryMovement(
            id=movement_id,
            item_type="PRODUCT",
            product_id=prod.id,
            movement_type="ADJUSTMENT",
            quantity_delta=req.quantity_delta,
            source_type="ADJUSTMENT",
            source_id=movement_id,
            occurred_at=utc_now(),
            reason=req.reason,
        )
        session.add(mov)
        session.flush()

        # Calculate total balance from ledger
        balance = session.execute(
            select(func.coalesce(func.sum(InventoryMovement.quantity_delta), 0))
            .where(InventoryMovement.product_id == prod.id)
        ).scalar_one()

        res = {
            "movement_id": movement_id,
            "product_id": prod.id,
            "quantity_delta": req.quantity_delta,
            "current_calculated_balance": balance,
            "is_replay": False,
            "operation_type": op_type,
        }
        return 201, res

    result = process_transactional_idempotency(
        db=db,
        idempotency_key=x_idempotency_key,
        operation_type=op_type,
        payload=payload_dict,
        business_callback=business_logic,
    )

    db.commit()

    data = result.to_json_dict()
    if isinstance(data, dict):
        data["is_replay"] = result.is_replay
    return Response(
        content=json.dumps(data, ensure_ascii=False),
        status_code=result.status_code,
        media_type="application/json"
    )
