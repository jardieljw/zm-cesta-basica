import uuid
import threading
import time
from pathlib import Path
import pytest
from sqlalchemy import create_engine, event, select, func
from sqlalchemy.orm import sessionmaker, Session

from app.core.database import configure_sqlite_pragmas, enforce_begin_immediate, run_with_db_retry
from app.models.base import Base, utc_now
from app.models.products import Product
from app.models.movements import InventoryMovement

class InsufficientStockException(Exception):
    pass

def test_sqlite_concurrent_writers_serialize_cleanly_under_begin_immediate(tmp_path: Path):
    db_file = tmp_path / "concurrency_test.db"
    db_url = f"sqlite:///{db_file.as_posix()}"
    engine = create_engine(db_url, connect_args={"check_same_thread": False})
    event.listen(engine, "connect", configure_sqlite_pragmas)
    event.listen(engine, "begin", enforce_begin_immediate)

    Base.metadata.create_all(bind=engine)
    SessionFactory = sessionmaker(autocommit=False, autoflush=False, bind=engine)

    prod_id = "prod-arroz-5kg"
    with SessionFactory() as init_session:
        init_session.add(Product(
            id=prod_id,
            name="Arroz 5kg",
            category="ALIMENTACAO",
            base_unit="UNIT",
            minimum_stock=0
        ))
        init_session.commit()

    errors = []
    num_threads = 6
    units_per_thread = 10

    def worker_entry(worker_num: int):
        try:
            def txn():
                with SessionFactory() as s:
                    with s.begin():
                        # Artificial jitter to maximize thread interleaving
                        time.sleep(0.01)
                        mov = InventoryMovement(
                            id=str(uuid.uuid4()),
                            item_type="PRODUCT",
                            product_id=prod_id,
                            movement_type="PURCHASE",
                            quantity_delta=units_per_thread,
                            source_type="PURCHASE",
                            source_id=f"purchase-thread-{worker_num}",
                            occurred_at=utc_now(),
                        )
                        s.add(mov)

            run_with_db_retry(txn)
        except Exception as e:
            errors.append(e)

    threads = [threading.Thread(target=worker_entry, args=(i,)) for i in range(num_threads)]
    for t in threads:
        t.start()
    for t in threads:
        t.join()

    engine.dispose()

    assert len(errors) == 0, f"Encountered unexpected concurrency errors: {errors}"

    # Verify ledger consistency
    check_engine = create_engine(db_url)
    with Session(check_engine) as check_session:
        total_balance = check_session.execute(
            select(func.sum(InventoryMovement.quantity_delta)).where(InventoryMovement.product_id == prod_id)
        ).scalar()
        movement_count = check_session.execute(
            select(func.count(InventoryMovement.id)).where(InventoryMovement.product_id == prod_id)
        ).scalar()

        assert movement_count == num_threads
        assert total_balance == num_threads * units_per_thread

    check_engine.dispose()

def test_concurrency_prevents_negative_stock(tmp_path: Path):
    db_file = tmp_path / "stock_prevent_negative.db"
    db_url = f"sqlite:///{db_file.as_posix()}"
    engine = create_engine(db_url, connect_args={"check_same_thread": False})
    event.listen(engine, "connect", configure_sqlite_pragmas)
    event.listen(engine, "begin", enforce_begin_immediate)

    Base.metadata.create_all(bind=engine)
    SessionFactory = sessionmaker(autocommit=False, autoflush=False, bind=engine)

    prod_id = "prod-cesta-carne"
    initial_stock = 5
    with SessionFactory() as s:
        s.add(Product(
            id=prod_id,
            name="Cesta de Carne",
            category="CARNE",
            base_unit="UNIT",
            minimum_stock=0
        ))
        s.commit()

    with SessionFactory() as s:
        s.add(InventoryMovement(
            id="initial-stock-1",
            item_type="PRODUCT",
            product_id=prod_id,
            movement_type="ASSEMBLY_PRODUCE",
            quantity_delta=initial_stock,
            source_type="PRODUCTION",
            source_id="batch-001",
            occurred_at=utc_now()
        ))
        s.commit()

    results = []
    # Two simultaneous sales of 5 units each competing for the only 5 units in stock
    def attempt_sale(sale_id: str):
        try:
            def txn():
                with SessionFactory() as s:
                    with s.begin():
                        # Read balance inside BEGIN IMMEDIATE lock
                        current_balance = s.execute(
                            select(func.coalesce(func.sum(InventoryMovement.quantity_delta), 0))
                            .where(InventoryMovement.product_id == prod_id)
                        ).scalar()

                        time.sleep(0.02) # simulate processing latency

                        requested = 5
                        if current_balance < requested:
                            raise InsufficientStockException(
                                f"Saldo insuficiente: atual={current_balance}, solicitado={requested}"
                            )

                        mov = InventoryMovement(
                            id=str(uuid.uuid4()),
                            item_type="PRODUCT",
                            product_id=prod_id,
                            movement_type="SALE",
                            quantity_delta=-requested,
                            source_type="SALE",
                            source_id=sale_id,
                            occurred_at=utc_now()
                        )
                        s.add(mov)

            run_with_db_retry(txn)
            results.append("SUCCESS")
        except InsufficientStockException:
            results.append("INSUFFICIENT_STOCK")
        except Exception as e:
            results.append(f"ERROR: {e}")

    t1 = threading.Thread(target=attempt_sale, args=("sale-A",))
    t2 = threading.Thread(target=attempt_sale, args=("sale-B",))
    t1.start()
    t2.start()
    t1.join()
    t2.join()

    engine.dispose()

    # Exactly one sale must succeed, and the other must be rejected
    assert results.count("SUCCESS") == 1
    assert results.count("INSUFFICIENT_STOCK") == 1

    # Verify that final stock in ledger is exactly 0 and NEVER negative
    check_engine = create_engine(db_url)
    with Session(check_engine) as s:
        final_balance = s.execute(
            select(func.coalesce(func.sum(InventoryMovement.quantity_delta), 0))
            .where(InventoryMovement.product_id == prod_id)
        ).scalar()
        assert final_balance == 0
    check_engine.dispose()
