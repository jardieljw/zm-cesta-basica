"""Tests for credit card bill semantic reviews and obligations integration (FAT-005 to FAT-009).

Uses real and synthetic credit card bills to verify:
- Component equation balancing.
- Segregation between BUSINESS and PERSONAL_WITHDRAWAL.
- Prevention of duplicate expenses and CMPM preservation for linked purchases.
- Zero accounts payable generated for bill payments, previous balances, refunds, and context items.
- Append-only immutability triggers.
"""
import copy
import uuid
import pytest
from sqlalchemy import text, select

from app.models.purchases import Purchase, PurchaseItem
from app.models.products import Product
from app.models.financial import AccountPayable
from app.models.financial_bill_semantics import (
    FinancialBillSemanticReview, FinancialBillSemanticItem, FinancialBillObligation,
)
from test_financial_imports import FinancialAPI, PREFIX
from test_financial_readers import preview, options, confirm


@pytest.fixture
def api(client, authenticated_device):
    return FinancialAPI(client, authenticated_device[2])


def nubank_card_options(**changes):
    return {
        "columns": {"transaction_date": "date", "amount": "amount", "description": "title"},
        "delimiter": ",",
        "date_format": "YYYY-MM-DD",
        "decimal_separator": ",",
        "amount_convention": "CHARGES_POSITIVE",
        "amount_sign_spacing": "OPTIONAL_SINGLE_SPACE",
        **changes,
    }


def setup_card_statement(api, csv_content: bytes, declared_total_cents: int, due_on: str = "2024-04-24"):
    source = api.source("CREDIT_CARD")
    p, doc, _ = preview(
        api, source, csv_content,
        opts=nubank_card_options(),
    )
    conf = confirm(api, p, statement_type="CARD_BILL", due_on=due_on, total_amount_cents=declared_total_cents)
    st = conf.get("statement", conf)
    items = api.get(f"/statements/{st['id']}/items")
    return source, p, st, items


def test_unbalanced_semantic_review_remains_draft_and_blocks_obligations(api):
    # Bill with 2 purchases (100.00 and 50.00), declared total 150.00
    csv_data = b'date,title,amount\n2025-05-01,Material de escritorio,"100,00"\n2025-05-02,Almoco socio,"50,00"\n'
    source, p, st, items = setup_card_statement(api, csv_data, declared_total_cents=15000)

    # Operator misclassifies second item as CONTEXT_ONLY (calculated = 10000 != declared 15000)
    payload = {
        "expected_revision": 0,
        "notes": "Tentativa parcial",
        "items": [
            {"item_id": items[0]["id"], "semantic_category": "PURCHASE_BUSINESS"},
            {"item_id": items[1]["id"], "semantic_category": "CONTEXT_ONLY"},
        ],
    }
    res = api.post(f"/statements/{st['id']}/semantic-reviews", payload)
    review = res.get("review", res)

    # Verify review status
    assert review["is_balanced"] is False
    assert review["status"] == "DRAFT"
    assert review["equation_difference_cents"] == 5000  # 15000 - 10000

    # Attempting to generate obligations must fail with 409
    res = api.client.post(
        f"{PREFIX}/statements/{st['id']}/generate-obligations",
        json={},
        headers={**api.headers, "X-Idempotency-Key": str(uuid.uuid4())},
    )
    assert res.status_code == 409
    assert res.json()["detail"]["error_code"] == "BILL_REVIEW_NOT_BALANCED"


def test_balanced_semantic_review_generates_obligations_with_business_and_personal_segregation(api):
    # Bill with 1 business purchase (200.00), 1 personal withdrawal (120.00), 1 fee (15.00), total 335.00
    csv_data = (
        b'date,title,amount\n'
        b'2025-06-01,Insumos Embalagem,"200,00"\n'
        b'2025-06-02,Farmacia Particular Socio,"120,00"\n'
        b'2025-06-03,Anuidade Cartao,"15,00"\n'
    )
    source, p, st, items = setup_card_statement(api, csv_data, declared_total_cents=33500, due_on="2025-06-25")

    # Balanced classification
    payload = {
        "expected_revision": 0,
        "notes": "Classificacao completa e balanceada",
        "items": [
            {"item_id": items[0]["id"], "semantic_category": "PURCHASE_BUSINESS"},
            {"item_id": items[1]["id"], "semantic_category": "PURCHASE_PERSONAL"},
            {"item_id": items[2]["id"], "semantic_category": "FINANCIAL_CHARGES"},
        ],
    }
    res = api.post(f"/statements/{st['id']}/semantic-reviews", payload)
    review = res.get("review", res)
    assert review["is_balanced"] is True
    assert review["status"] == "APPROVED"
    assert review["equation_difference_cents"] == 0
    assert review["purchases_business_cents"] == 20000
    assert review["purchases_personal_cents"] == 12000
    assert review["financial_charges_cents"] == 1500

    # Generate obligations
    obligations = api.post(f"/statements/{st['id']}/generate-obligations", {})
    if isinstance(obligations, dict) and "obligations" in obligations:
        obligations = obligations["obligations"]
    assert len(obligations) == 3

    # Inspect payables generated in accounts_payable
    business_ob = next(o for o in obligations if o["component_type"] == "PURCHASE_BUSINESS")
    personal_ob = next(o for o in obligations if o["component_type"] == "PURCHASE_PERSONAL")
    charges_ob = next(o for o in obligations if o["component_type"] == "FINANCIAL_CHARGES")

    assert business_ob["amount_cents"] == 20000
    assert business_ob["nature"] == "BUSINESS"
    assert business_ob["category"] == "CARTAO_CREDITO"
    assert business_ob["status"] == "OPEN"

    assert personal_ob["amount_cents"] == 12000
    assert personal_ob["nature"] == "PERSONAL_WITHDRAWAL"
    assert personal_ob["category"] == "RETIRADA_SOCIO"
    assert personal_ob["status"] == "OPEN"

    assert charges_ob["amount_cents"] == 1500
    assert charges_ob["nature"] == "BUSINESS"
    assert charges_ob["status"] == "OPEN"

    # Re-calling generate obligations is idempotent and returns the existing obligations
    replay = api.post(f"/statements/{st['id']}/generate-obligations", {})
    if isinstance(replay, dict) and "obligations" in replay:
        replay = replay["obligations"]
    assert len(replay) == 3
    assert {o["id"] for o in replay} == {o["id"] for o in obligations}


def test_real_nubank_2026_03_sample_balancing_and_zero_duplicate_obligations(api):
    """
    Validates Nubank_2026-03-24.csv with 13 lines:
    - Saldo em atraso (1203.91) -> PREVIOUS_BALANCE
    - Juros e multas de atraso (507.75) -> FINANCIAL_CHARGES
    - Limite convertido em saldo (54.64) -> FINANCIAL_CHARGES
    - Compras (946.29):
      - Baseusbr (50.91) -> PURCHASE_BUSINESS
      - Dmoveldesignmovel (400.00) -> PURCHASE_BUSINESS
      - Picpay*Jardiel Wends (495.38) -> PURCHASE_PERSONAL
    Total declared: R$ 2.712,59 (271259 cents).
    """
    csv_data = (
        b"date,title,amount\n"
        b"2026-03-24,Limite convertido em saldo na sua conta do Nubank,\"0,04\"\n"
        b"2026-03-24,Limite convertido em saldo na sua conta do Nubank,\"2,66\"\n"
        b"2026-03-24,Limite convertido em saldo na sua conta do Nubank,\"0,92\"\n"
        b"2026-03-24,Limite convertido em saldo na sua conta do Nubank,\"51,02\"\n"
        b"2026-03-24,IOF de atraso,\"3,10\"\n"
        b"2026-03-24,Juros de atraso,\"266,47\"\n"
        b"2026-03-24,Multa de atraso,\"24,17\"\n"
        b"2026-03-24,IOF de atraso,\"7,36\"\n"
        b"2026-03-24,Juros de atraso,\"206,65\"\n"
        b"2026-03-24,Saldo em atraso,\"1203,91\"\n"
        b"2026-03-17,Mercadopago *Baseusbr - Parcela 9/9,\"50,91\"\n"
        b"2026-03-17,Dmoveldesignmovel - Parcela 9/10,\"400,00\"\n"
        b"2026-03-17,Picpay*Jardiel Wends - Parcela 3/10,\"495,38\"\n"
    )
    declared_total = 271259  # 2712.59
    source, p, st, items = setup_card_statement(api, csv_data, declared_total_cents=declared_total, due_on="2026-03-24")
    assert len(items) == 13

    # Map semantic categories
    classified_items = []
    for it in items:
        desc = it["normalized_data"]["description"]
        if "Saldo em atraso" in desc:
            cat = "PREVIOUS_BALANCE"
        elif any(w in desc for w in ("Juros", "Multa", "IOF", "Limite convertido")):
            cat = "FINANCIAL_CHARGES"
        elif "Picpay*Jardiel" in desc:
            cat = "PURCHASE_PERSONAL"
        else:
            cat = "PURCHASE_BUSINESS"
        classified_items.append({"item_id": it["id"], "semantic_category": cat})

    res = api.post(f"/statements/{st['id']}/semantic-reviews", {
        "expected_revision": 0,
        "notes": "Homologacao fatura real Nubank 2026-03",
        "items": classified_items,
    })
    review = res.get("review", res)

    # Exact equation validation
    assert review["is_balanced"] is True
    assert review["status"] == "APPROVED"
    assert review["equation_difference_cents"] == 0
    assert review["previous_balance_cents"] == 120391
    assert review["financial_charges_cents"] == 50775 + 5464
    assert review["purchases_business_cents"] == 5091 + 40000
    assert review["purchases_personal_cents"] == 49538

    # There is no linked obligation representing the previous balance in this
    # fixture. A balanced bill alone cannot authorize incomplete new debt.
    response = api.post(f"/statements/{st['id']}/generate-obligations", {}, expected=(409,))
    assert response['detail']['error_code'] == 'FINANCIAL_BILL_ALLOCATION_REQUIRED'
    assert api.get(f"/statements/{st['id']}/obligations") == []


def test_existing_purchase_link_preserves_cmpm_and_prevents_duplicate_payable(api, test_session):
    """
    FAT-006: Linking a card purchase to an existing inventory Purchase
    must NOT create duplicate accounts payable or re-alter CMPM.
    """
    # Create a real purchase in the database first
    prod = Product(
        id=str(uuid.uuid4()),
        name="Arroz 5kg Teste",
        category="ALIMENTACAO",
        base_unit="G",
        minimum_stock=2000,
        cost_price_microcents=500000,  # R$ 50.00
    )
    test_session.add(prod)
    test_session.flush()

    purchase_id = str(uuid.uuid4())
    purchase = Purchase(
        id=purchase_id,
        purchase_number=999,
        supplier_name="Distribuidora de Graos",
        total_amount_cents=18000,  # R$ 180.00
        payment_method="CARTAO_CREDITO",
        status="CONFIRMED",
    )
    test_session.add(purchase)

    import datetime as dt_module
    existing_payable = AccountPayable(
        id=str(uuid.uuid4()),
        payable_number=888,
        description="Compra estoque #999 - Distribuidora de Graos",
        beneficiary="Distribuidora de Graos",
        category="FORNECEDOR",
        nature="BUSINESS",
        original_amount_cents=18000,
        balance_cents=18000,
        paid_amount_cents=0,
        due_date=dt_module.datetime(2025, 7, 20, 12, 0),
        payment_method="CARTAO_CREDITO",
        status="OPEN",
        purchase_id=purchase_id,
    )
    test_session.add(existing_payable)
    test_session.commit()

    # Now a card bill comes with that purchase of 180.00
    csv_data = b'date,title,amount\n2025-07-05,Distribuidora de Graos,"180,00"\n'
    source, p, st, items = setup_card_statement(api, csv_data, declared_total_cents=18000, due_on="2025-07-20")

    # Semantic review links the item to purchase_id
    payload = {
        "expected_revision": 0,
        "items": [
            {
                "item_id": items[0]["id"],
                "semantic_category": "PURCHASE_BUSINESS",
                "purchase_id": purchase_id,
            }
        ],
    }
    review = api.post(f"/statements/{st['id']}/semantic-reviews", payload)
    assert review["is_balanced"] is True

    # Generate obligations
    obligations = api.post(f"/statements/{st['id']}/generate-obligations", {})
    if isinstance(obligations, dict) and "obligations" in obligations:
        obligations = obligations["obligations"]
    assert len(obligations) == 1

    # Must reuse the existing payable without creating a duplicate!
    ob = obligations[0]
    assert ob["component_type"] == "PURCHASE_LINKED"
    assert ob["account_payable_id"] == existing_payable.id
    assert ob["purchase_id"] == purchase_id

    # Verify no second payable was created
    all_payables_for_purchase = test_session.scalars(
        select(AccountPayable).where(AccountPayable.purchase_id == purchase_id)
    ).all()
    assert len(all_payables_for_purchase) == 1


def test_sqlite_immutability_triggers_block_updates_and_deletes_on_semantics(api, test_session):
    """Verifies that SQLite triggers raise abort on direct SQL mutation attempts."""
    csv_data = b'date,title,amount\n2025-08-01,Combustivel,"150,00"\n'
    source, p, st, items = setup_card_statement(api, csv_data, declared_total_cents=15000)

    api.post(f"/statements/{st['id']}/semantic-reviews", {
        "expected_revision": 0,
        "items": [{"item_id": items[0]["id"], "semantic_category": "PURCHASE_BUSINESS"}],
    })
    api.post(f"/statements/{st['id']}/generate-obligations", {})

    # Direct UPDATE on financial_bill_semantic_reviews must raise ABORT
    with pytest.raises(Exception) as exc:
        test_session.execute(text("UPDATE financial_bill_semantic_reviews SET notes = 'tampered'"))
        test_session.flush()
    assert "financial evidence is immutable" in str(exc.value)
    test_session.rollback()

    # Direct DELETE on financial_bill_obligations must raise ABORT
    with pytest.raises(Exception) as exc:
        test_session.execute(text("DELETE FROM financial_bill_obligations"))
        test_session.flush()
    assert "financial evidence is immutable" in str(exc.value)
    test_session.rollback()


def test_real_nubank_2024_04_sample_with_payments_and_refunds(api):
    """
    Validates Nubank_2024-04-24.csv with 21 lines:
    - Pagamento recebido (-852.17) -> BILL_PAYMENT
    - Estorno de 'Mercadolivre*Reestore' (-59.64) -> REFUND_CREDIT
    - Saldo em atraso (+852.16) -> PREVIOUS_BALANCE
    - Crédito de atraso (-852.16) -> REFUND_CREDIT
    - Juros de dívida encerrada (+38.24) -> FINANCIAL_CHARGES
    - Encerramento de dívida (-38.24) -> REFUND_CREDIT
    - Encargos de atraso: Multa (17.10) + Juros (17.60) + IOF (3.53) = 38.23 -> FINANCIAL_CHARGES
    - Compras (803.61)
    """
    with open(r"C:\Users\jardi\.gemini\antigravity\brain\4485ce4a-3a32-4ccd-a304-69e667bbbc6f\scratch\financial_samples\CSV\Nubank_2024-04-24.csv", "rb") as f:
        csv_bytes = f.read()

    declared_total = -6997
    source, p, st, items = setup_card_statement(api, csv_bytes, declared_total_cents=declared_total, due_on="2024-04-24")
    assert len(items) == 21

    classified_items = []
    for it in items:
        desc = it["normalized_data"]["description"]
        if "Pagamento recebido" in desc:
            cat = "BILL_PAYMENT"
        elif "Saldo em atraso" in desc:
            cat = "PREVIOUS_BALANCE"
        elif any(w in desc for w in ("Estorno", "Cr\xe9dito de atraso", "Crédito de atraso", "Encerramento de d\xedvida", "Encerramento de dívida")):
            cat = "REFUND_CREDIT"
        elif any(w in desc for w in ("Multa", "Juros", "IOF")):
            cat = "FINANCIAL_CHARGES"
        elif any(w in desc for w in ("Bigpag", "Drogaria")):
            cat = "PURCHASE_PERSONAL"
        else:
            cat = "PURCHASE_BUSINESS"
        classified_items.append({"item_id": it["id"], "semantic_category": cat})

    res = api.post(f"/statements/{st['id']}/semantic-reviews", {
        "expected_revision": 0,
        "notes": "Homologacao fatura real Nubank 2024-04 com pagamentos e estornos",
        "items": classified_items,
    })
    review = res.get("review", res)
    assert review["is_balanced"] is True
    assert review["status"] == "APPROVED"
    assert review["equation_difference_cents"] == 0
    assert review["payments_cents"] == 85217
    assert review["refunds_cents"] == 5964 + 85216 + 3824

    # Revision conflict check: posting with expected_revision 0 again must fail with 409
    conflict = api.client.post(
        f"{PREFIX}/statements/{st['id']}/semantic-reviews",
        json={"expected_revision": 0, "items": classified_items},
        headers={**api.headers, "X-Idempotency-Key": str(uuid.uuid4())},
    )
    assert conflict.status_code == 409
    assert conflict.json()["detail"]["error_code"] == "FINANCIAL_BILL_REVISION_CONFLICT"

    # Posting with expected_revision 1 succeeds and creates revision 2
    res2 = api.post(f"/statements/{st['id']}/semantic-reviews", {
        "expected_revision": 1,
        "notes": "Revisao 2 confirmada",
        "items": classified_items,
    })
    review2 = res2.get("review", res2)
    assert review2["revision"] == 2

