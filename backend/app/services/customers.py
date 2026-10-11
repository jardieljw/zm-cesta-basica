import uuid
import datetime
from typing import Optional, List, Tuple, Dict
from sqlalchemy import select, func, or_, desc
from sqlalchemy.orm import Session
from fastapi import HTTPException, status

from app.models.customers import Customer
from app.models.sales import Sale, SalesReceivable, ReceivablePayment
from app.models.base import utc_now
from app.schemas.customers import (
    CustomerCreate,
    CustomerUpdate,
    CustomerResponse,
    CustomerStatementEntry,
    CustomerStatementResponse,
)


def get_customer_debt_balance(db: Session, customer_id: str) -> int:
    """Calculates active unpaid debt balance in cents across all open/partial receivables."""
    stmt = (
        select(func.coalesce(func.sum(SalesReceivable.balance_cents), 0))
        .where(
            SalesReceivable.customer_id == customer_id,
            SalesReceivable.status.in_(["OPEN", "PARTIAL"]),
        )
    )
    return int(db.execute(stmt).scalar_one() or 0)


def _clean_optional_str(val: Optional[str]) -> Optional[str]:
    if val is None:
        return None
    s = val.strip()
    return s if s else None


def create_customer(db: Session, data: CustomerCreate) -> Customer:
    """Creates a new customer with optional document uniqueness check."""
    clean_name = data.name.strip()
    clean_doc = _clean_optional_str(data.document_cpf_cnpj)

    if clean_doc:
        existing = db.execute(
            select(Customer).where(Customer.document_cpf_cnpj == clean_doc)
        ).scalar_one_or_none()
        if existing:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail={
                    "error_code": "CUSTOMER_DOCUMENT_CONFLICT",
                    "message": f"Ja existe um cliente cadastrado com o documento '{clean_doc}'.",
                    "existing_customer_id": existing.id,
                },
            )

    customer = Customer(
        id=str(uuid.uuid4()),
        name=clean_name,
        document_cpf_cnpj=clean_doc,
        phone=_clean_optional_str(data.phone),
        address=_clean_optional_str(data.address),
        credit_limit_cents=data.credit_limit_cents,
        is_active=True,
        notes=_clean_optional_str(data.notes),
        created_at=utc_now(),
        updated_at=utc_now(),
    )
    db.add(customer)
    db.flush()
    return customer


def update_customer(db: Session, customer_id: str, data: CustomerUpdate) -> Customer:
    """Updates an existing customer."""
    customer = db.get(Customer, customer_id)
    if not customer:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Cliente '{customer_id}' nao encontrado.",
        )

    if data.document_cpf_cnpj is not None:
        clean_doc = _clean_optional_str(data.document_cpf_cnpj)
        if clean_doc:
            existing = db.execute(
                select(Customer).where(
                    Customer.document_cpf_cnpj == clean_doc,
                    Customer.id != customer_id,
                )
            ).scalar_one_or_none()
            if existing:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail={
                        "error_code": "CUSTOMER_DOCUMENT_CONFLICT",
                        "message": f"Ja existe outro cliente com o documento '{clean_doc}'.",
                    },
                )
        customer.document_cpf_cnpj = clean_doc

    if data.name is not None:
        customer.name = data.name.strip()
    if data.phone is not None:
        customer.phone = _clean_optional_str(data.phone)
    if data.address is not None:
        customer.address = _clean_optional_str(data.address)
    if data.credit_limit_cents is not None:
        customer.credit_limit_cents = data.credit_limit_cents
    if data.is_active is not None:
        customer.is_active = data.is_active
    if data.notes is not None:
        customer.notes = _clean_optional_str(data.notes)

    customer.updated_at = utc_now()
    db.flush()
    return customer


def delete_customer(db: Session, customer_id: str) -> Customer:
    """Soft-deletes (inactivates) a customer, preserving full relational history."""
    customer = db.get(Customer, customer_id)
    if not customer:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Cliente '{customer_id}' nao encontrado.",
        )
    customer.is_active = False
    customer.updated_at = utc_now()
    db.flush()
    return customer


def get_customer(db: Session, customer_id: str) -> Tuple[Customer, int]:
    """Retrieves customer and current open debt balance."""
    customer = db.get(Customer, customer_id)
    if not customer:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Cliente '{customer_id}' nao encontrado.",
        )
    debt = get_customer_debt_balance(db, customer.id)
    return customer, debt


def list_customers(
    db: Session,
    search: Optional[str] = None,
    is_active: Optional[bool] = None,
    limit: int = 100,
    offset: int = 0,
) -> List[Tuple[Customer, int]]:
    """Lists customers with optional filters and computed debt balance."""
    stmt = select(Customer)
    if is_active is not None:
        stmt = stmt.where(Customer.is_active == is_active)
    if search:
        s = f"%{search.strip()}%"
        stmt = stmt.where(
            or_(
                Customer.name.ilike(s),
                Customer.document_cpf_cnpj.ilike(s),
                Customer.phone.ilike(s),
            )
        )
    stmt = stmt.order_by(Customer.name.asc()).limit(limit).offset(offset)
    customers = list(db.execute(stmt).scalars().all())

    # Map current debt for all listed customers in a single query
    if not customers:
        return []

    c_ids = [c.id for c in customers]
    debt_stmt = (
        select(
            SalesReceivable.customer_id,
            func.coalesce(func.sum(SalesReceivable.balance_cents), 0).label("debt"),
        )
        .where(
            SalesReceivable.customer_id.in_(c_ids),
            SalesReceivable.status.in_(["OPEN", "PARTIAL"]),
        )
        .group_by(SalesReceivable.customer_id)
    )
    debt_map = dict(db.execute(debt_stmt).all())

    return [(c, int(debt_map.get(c.id, 0))) for c in customers]


def get_customer_statement(db: Session, customer_id: str) -> CustomerStatementResponse:
    """Generates a complete financial statement with sales history and receivable payments."""
    customer, debt = get_customer(db, customer_id)

    # 1. Fetch sales
    sales_stmt = (
        select(Sale)
        .where(Sale.customer_id == customer_id, Sale.status == "CONFIRMED")
        .order_by(desc(Sale.sale_date))
    )
    sales = list(db.execute(sales_stmt).scalars().all())

    # 2. Fetch payments
    payments_stmt = (
        select(ReceivablePayment, SalesReceivable, Sale)
        .join(SalesReceivable, ReceivablePayment.receivable_id == SalesReceivable.id)
        .outerjoin(Sale, SalesReceivable.sale_id == Sale.id)
        .where(
            SalesReceivable.customer_id == customer_id,
            ReceivablePayment.status == "CONFIRMED",
        )
        .order_by(desc(ReceivablePayment.payment_date))
    )
    payments = db.execute(payments_stmt).all()

    entries: List[CustomerStatementEntry] = []

    for s in sales:
        entry_type = "SALE_CREDIT" if s.payment_mode == "CREDIT_TERM" else "SALE_IMMEDIATE"
        desc_text = f"Venda #{s.sale_number} ({s.payment_mode})"
        entries.append(
            CustomerStatementEntry(
                id=s.id,
                occurred_at=s.sale_date,
                entry_type=entry_type,
                description=desc_text,
                amount_cents=s.total_amount_cents,
                reference_id=s.id,
            )
        )

    for p, rec, s_ref in payments:
        sale_ref_str = f"#{s_ref.sale_number}" if s_ref else f"#{rec.sale_id[:8]}"
        entries.append(
            CustomerStatementEntry(
                id=p.id,
                occurred_at=p.payment_date,
                entry_type="RECEIVABLE_PAYMENT",
                description=f"Pagamento de Fiado (Venda {sale_ref_str}) via {p.payment_method}",
                amount_cents=p.amount_cents,
                reference_id=rec.id,
            )
        )

    # Sort chronological desc
    entries.sort(key=lambda x: x.occurred_at, reverse=True)

    available_credit = (
        max(0, customer.credit_limit_cents - debt)
        if customer.credit_limit_cents > 0
        else None
    )

    cust_resp = CustomerResponse(
        id=customer.id,
        name=customer.name,
        document_cpf_cnpj=customer.document_cpf_cnpj,
        phone=customer.phone,
        address=customer.address,
        credit_limit_cents=customer.credit_limit_cents,
        is_active=customer.is_active,
        notes=customer.notes,
        current_debt_cents=debt,
        created_at=customer.created_at,
        updated_at=customer.updated_at,
    )

    return CustomerStatementResponse(
        customer=cust_resp,
        credit_limit_cents=customer.credit_limit_cents,
        current_debt_cents=debt,
        available_credit_cents=available_credit,
        entries=entries,
    )
