import datetime
from typing import Optional
from sqlalchemy import String, Integer, DateTime, Text, ForeignKey, event, DDL
from sqlalchemy.orm import Mapped, mapped_column, relationship, Session
from app.models.base import Base, utc_now

class InventoryMovement(Base):
    __tablename__ = "inventory_movements"

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    item_type: Mapped[str] = mapped_column(String(20), nullable=False) # PRODUCT, BASKET
    product_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("products.id"), nullable=True, index=True)
    basket_type_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("basket_types.id"), nullable=True, index=True)
    production_batch_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("production_batches.id"), nullable=True, index=True)
    movement_type: Mapped[str] = mapped_column(String(30), nullable=False, index=True) # PURCHASE, PURCHASE_CANCEL, ASSEMBLY_CONSUME, ASSEMBLY_PRODUCE, SALE, ADJUSTMENT_IN, ADJUSTMENT_OUT, LOSS, REVERSAL
    quantity_delta: Mapped[int] = mapped_column(Integer, nullable=False) # + entry, - departure
    source_type: Mapped[str] = mapped_column(String(30), nullable=False) # PURCHASE, PRODUCTION, SALE, ADJUSTMENT
    source_id: Mapped[str] = mapped_column(String(36), nullable=False, index=True)
    reversal_of_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("inventory_movements.id"), nullable=True)
    location_type: Mapped[str] = mapped_column(String(20), nullable=False, default="STORE", index=True) # STORE, TRANSIT
    responsible_person_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("responsible_persons.id"), nullable=True, index=True)
    occurred_at: Mapped[datetime.datetime] = mapped_column(DateTime, default=utc_now, nullable=False, index=True)
    reason: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    reversal_parent: Mapped[Optional["InventoryMovement"]] = relationship(remote_side=[id])
    product: Mapped[Optional["Product"]] = relationship("app.models.products.Product")
    basket_type: Mapped[Optional["BasketType"]] = relationship("app.models.products.BasketType")
    production_batch: Mapped[Optional["ProductionBatch"]] = relationship("app.models.production.ProductionBatch")
    responsible_person: Mapped[Optional["app.models.dispatches.ResponsiblePerson"]] = relationship("app.models.dispatches.ResponsiblePerson")


@event.listens_for(Session, "before_flush")
def enforce_inventory_movements_append_only(session, flush_context, instances):
    """Enforces strictly append-only ledger: physical UPDATE or DELETE is strictly rejected."""
    for obj in session.dirty:
        if isinstance(obj, InventoryMovement) and session.is_modified(obj, include_collections=False):
            raise ValueError("Violacao de Livro-Razao: Registros de inventory_movements sao estritamente append-only e nao podem ser alterados.")
    for obj in session.deleted:
        if isinstance(obj, InventoryMovement):
            raise ValueError("Violacao de Livro-Razao: Registros de inventory_movements sao estritamente append-only e nao podem ser excluidos.")


# SQLite engine-level triggers ensuring append-only even on direct raw SQL execution
_trg_update_ddl = DDL("""
CREATE TRIGGER IF NOT EXISTS trg_prevent_inventory_movements_update
BEFORE UPDATE ON inventory_movements
BEGIN
    SELECT RAISE(ABORT, 'inventory_movements is append-only: updates are forbidden');
END;
""")

_trg_delete_ddl = DDL("""
CREATE TRIGGER IF NOT EXISTS trg_prevent_inventory_movements_delete
BEFORE DELETE ON inventory_movements
BEGIN
    SELECT RAISE(ABORT, 'inventory_movements is append-only: deletes are forbidden');
END;
""")

event.listen(
    InventoryMovement.__table__,
    "after_create",
    _trg_update_ddl.execute_if(dialect="sqlite"),
)
event.listen(
    InventoryMovement.__table__,
    "after_create",
    _trg_delete_ddl.execute_if(dialect="sqlite"),
)
