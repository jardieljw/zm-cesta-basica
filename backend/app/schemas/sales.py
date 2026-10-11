import datetime
from typing import Optional, List
from pydantic import BaseModel, ConfigDict, Field

class SaleItemCustomIngredient(BaseModel):
    product_id: str
    quantity_in_base_units: int = Field(..., gt=0, description="Quantidade consumida na unidade base")
    section: Optional[str] = Field("PERSONALIZADO", description="Secao/divisao (Alimentacao, Limpeza, etc.)")

class SaleItemCreate(BaseModel):
    basket_type_id: str = Field(..., description="ID do tipo de cesta")
    quantity: int = Field(..., gt=0, description="Quantidade de cestas vendidas")
    unit_price_cents: int = Field(..., ge=0, description="Preco unitario negociado em centavos")
    discount_cents: int = Field(default=0, ge=0, description="Desconto total aplicado neste item em centavos")
    assemble_on_demand: bool = Field(default=False, description="Se True, executa a montagem/producao simultanea no momento da venda")
    is_custom: bool = Field(default=False, description="Se True, cesta de composicao personalizada")
    custom_description: Optional[str] = Field(None, description="Descricao da cesta personalizada")
    custom_items: Optional[List[SaleItemCustomIngredient]] = Field(None, description="Ingredientes da cesta personalizada")
    production_batch_id: Optional[str] = Field(None, description="ID do lote acabado de cesta personalizada ja em estoque")

class SaleCreate(BaseModel):
    customer_id: Optional[str] = Field(None, description="ID do cliente cadastrado (obrigatorio para CREDIT_TERM)")
    customer_name: Optional[str] = Field(None, max_length=200, description="Nome do cliente avulso / balcao")
    sale_mode: str = Field(default="DIRECT_STORE", description="DIRECT_STORE (balcao) ou COMMERCIAL_ROUTE (rota)")
    payment_mode: str = Field(default="CASH_IMMEDIATE", description="CASH_IMMEDIATE, PIX, CARD, CREDIT_TERM")
    sale_date: Optional[datetime.datetime] = Field(None, description="Data da venda (UTC, padrao now)")
    due_date: Optional[datetime.datetime] = Field(None, description="Data de vencimento para venda fiada (padrao 30 dias)")
    allow_credit_override: bool = Field(default=False, description="Se True, confirma liberacao manual caso o limite de credito seja excedido")
    notes: Optional[str] = Field(None, description="Observacoes gerais da venda")
    items: List[SaleItemCreate] = Field(..., min_length=1, description="Itens vendidos")

class SaleCancelRequest(BaseModel):
    reason: str = Field(..., min_length=3, description="Justificativa obrigatoria do cancelamento/estorno")

class SaleItemResponse(BaseModel):
    id: str
    basket_type_id: str
    basket_type_name: Optional[str] = None
    production_batch_id: Optional[str] = None
    quantity: int
    unit_price_cents: int
    discount_cents: int
    total_cents: int
    unit_cost_cents: int
    total_cost_cents: int

    model_config = ConfigDict(from_attributes=True)

class SaleResponse(BaseModel):
    id: str
    sale_number: int
    customer_id: Optional[str] = None
    customer_name: Optional[str] = None
    status: str
    sale_mode: str
    payment_mode: str
    payment_status: str
    sale_date: datetime.datetime
    total_amount_cents: int
    total_cost_cents: int
    gross_margin_cents: int
    canceled_at: Optional[datetime.datetime] = None
    cancellation_reason: Optional[str] = None
    notes: Optional[str] = None
    items: List[SaleItemResponse]
    receivable_id: Optional[str] = None
    receivable_due_date: Optional[datetime.datetime] = None
    receivable_balance_cents: Optional[int] = None
    receivable_status: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)
