from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.api.deps import get_current_device, get_idempotency_key
from app.models.auth import PairedDevice
from app.models.customers import Customer
from app.schemas.customers import (
    CustomerCreate,
    CustomerUpdate,
    CustomerResponse,
    CustomerStatementResponse,
)
from app.services.customers import (
    create_customer,
    update_customer,
    delete_customer,
    get_customer,
    list_customers,
    get_customer_statement,
)

router = APIRouter()


def serialize_customer(c: Customer, debt: int) -> CustomerResponse:
    return CustomerResponse(
        id=c.id,
        name=c.name,
        document_cpf_cnpj=c.document_cpf_cnpj,
        phone=c.phone,
        address=c.address,
        credit_limit_cents=c.credit_limit_cents,
        is_active=c.is_active,
        notes=c.notes,
        current_debt_cents=debt,
        created_at=c.created_at,
        updated_at=c.updated_at,
    )


@router.get("/customers", response_model=List[CustomerResponse])
def get_customers(
    search: Optional[str] = Query(None, description="Busca textual por nome, documento ou telefone"),
    is_active: Optional[bool] = Query(None, description="Filtra por status ativo/inativo"),
    limit: int = Query(100, ge=1, le=500),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db),
    device: PairedDevice = Depends(get_current_device),
):
    """Retorna lista de clientes com filtro e saldo devedor atual apurado."""
    results = list_customers(db, search=search, is_active=is_active, limit=limit, offset=offset)
    return [serialize_customer(c, debt) for c, debt in results]


@router.post("/customers", response_model=CustomerResponse, status_code=status.HTTP_201_CREATED)
def post_customer(
    data: CustomerCreate,
    db: Session = Depends(get_db),
    device: PairedDevice = Depends(get_current_device),
):
    """Cadastra um novo cliente."""
    customer = create_customer(db, data)
    db.commit()
    return serialize_customer(customer, debt=0)


@router.get("/customers/{customer_id}", response_model=CustomerResponse)
def get_customer_by_id(
    customer_id: str,
    db: Session = Depends(get_db),
    device: PairedDevice = Depends(get_current_device),
):
    """Retorna dados de um cliente especifico com saldo devedor."""
    customer, debt = get_customer(db, customer_id)
    return serialize_customer(customer, debt)


@router.put("/customers/{customer_id}", response_model=CustomerResponse)
def put_customer(
    customer_id: str,
    data: CustomerUpdate,
    db: Session = Depends(get_db),
    device: PairedDevice = Depends(get_current_device),
):
    """Atualiza dados cadastrais de um cliente."""
    customer = update_customer(db, customer_id, data)
    db.commit()
    _, debt = get_customer(db, customer.id)
    return serialize_customer(customer, debt)


@router.delete("/customers/{customer_id}", response_model=CustomerResponse)
def remove_customer(
    customer_id: str,
    db: Session = Depends(get_db),
    device: PairedDevice = Depends(get_current_device),
):
    """Inativa (soft-delete) um cliente, preservando historico relacional."""
    customer = delete_customer(db, customer_id)
    db.commit()
    _, debt = get_customer(db, customer.id)
    return serialize_customer(customer, debt)


@router.get("/customers/{customer_id}/statement", response_model=CustomerStatementResponse)
def get_statement(
    customer_id: str,
    db: Session = Depends(get_db),
    device: PairedDevice = Depends(get_current_device),
):
    """Retorna o extrato completo de compras, fiados e amortizacoes do cliente."""
    return get_customer_statement(db, customer_id)
