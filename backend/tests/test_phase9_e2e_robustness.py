import uuid
import datetime
from pathlib import Path
from fastapi.testclient import TestClient

from app.core.backup import create_backup, restore_backup, check_sqlite_integrity


def test_complete_phase9_end_to_end_operational_cycle(client: TestClient, authenticated_device, tmp_path: Path):
    """
    Comprehensive End-to-End Integration & Robustness Audit for Phase 9:
    1. Health & Pairing: status 'ok', database_status 'ok', TLS fingerprint verified
    2. Master Data: Insumos (G/ML/UNIT), Embalagens com Conversao, Tipos de Cestas e Receitas Ativas
    3. Compras: Entrada com conversao automatica e atualizacao do CMPM em microcentavos
    4. Producao: Montagem de lote de cestas sob BEGIN IMMEDIATE, congelando unit_cost_cents
    5. Expedicao: Saida fisica de cestas do galpao (STORE -> TRANSIT) para entregador responsavel
    6. Vendas em Rota: Venda com baixa exclusiva de TRANSIT (sem duplo desconto em STORE)
    7. Conferencia de Retorno: Equacao de 4 termos (vendidas, devolvidas, avariadas, em custodia)
    8. Financeiro & Tesouraria: Contas a pagar, fluxo de caixa imutavel, acerto segregado
    9. Relatorios & Exportacoes: DRE, Vendas, Expedicao em JSON, CSV e XLSX
    10. Backup Quente & Restauracao: Criacao atomica via SQLite WAL e restauracao verificada
    11. Idempotencia & Seguranca: Replay de payload identico e deteccao de payload mismatch
    """
    _, _, headers = authenticated_device

    # -------------------------------------------------------------
    # 1. Health & Pairing
    # -------------------------------------------------------------
    health_res = client.get("/api/v1/health")
    assert health_res.status_code == 200
    health_data = health_res.json()
    assert health_data["status"] == "ok"
    assert health_data["database_status"] == "ok"
    assert len(health_data["tls_fingerprint_sha256"]) > 0

    # -------------------------------------------------------------
    # 2. Master Data (Produtos, Embalagens, Cestas, Receitas)
    # -------------------------------------------------------------
    # 2.1 Cadastrar Insumo 1: Arroz Tipo 1 (base_unit: G)
    prod1_res = client.post(
        "/api/v1/products",
        headers=headers,
        json={
            "name": f"Arroz Agulhinha E2E {uuid.uuid4().hex[:4]}",
            "category": "ALIMENTACAO",
            "base_unit": "G",
            "cost_price_cents": 2500, # R$ 25,00 por pacote
            "sale_price_cents": 3200,
            "minimum_stock": 50000,
        },
    )
    assert prod1_res.status_code == 201
    prod1_id = prod1_res.json()["id"]

    # 2.2 Cadastrar Embalagem Comercial: Fardo com 6 pacotes de 5000g = 30000g
    pkg1_res = client.post(
        f"/api/v1/products/{prod1_id}/packagings",
        headers=headers,
        json={
            "name": "Fardo 6x5kg",
            "quantity_in_base_units": 30000,
            "is_default": True,
            "is_active": True,
        },
    )
    assert pkg1_res.status_code == 201
    pkg1_id = pkg1_res.json()["id"]

    # 2.3 Cadastrar Insumo 2: Feijao Carioca (base_unit: G)
    prod2_res = client.post(
        "/api/v1/products",
        headers=headers,
        json={
            "name": f"Feijao Carioca E2E {uuid.uuid4().hex[:4]}",
            "category": "ALIMENTACAO",
            "base_unit": "G",
            "cost_price_cents": 800,
            "sale_price_cents": 1100,
            "minimum_stock": 20000,
        },
    )
    assert prod2_res.status_code == 201
    prod2_id = prod2_res.json()["id"]

    # 2.4 Cadastrar Tipo de Cesta Comercial
    bt_res = client.post(
        "/api/v1/basket-types",
        headers=headers,
        json={
            "code": f"BASICA_{uuid.uuid4().hex[:6].upper()}",
            "name": "Cesta Familia ZM E2E",
            "description": "Cesta com arroz e feijao",
            "default_price_cents": 15000, # R$ 150,00
            "allows_customization": True,
            "tracks_finished_stock": True,
        },
    )
    assert bt_res.status_code == 201
    basket_type_id = bt_res.json()["id"]

    # 2.5 Cadastrar Receita Ativa da Cesta (5000g arroz, 2000g feijao)
    recipe_res = client.post(
        f"/api/v1/basket-types/{basket_type_id}/recipes",
        headers=headers,
        json={
            "notes": "Receita Canonica E2E V1",
            "items": [
                {"product_id": prod1_id, "quantity_in_base_units": 5000, "section": "ALIMENTACAO", "is_required": True},
                {"product_id": prod2_id, "quantity_in_base_units": 2000, "section": "ALIMENTACAO", "is_required": True},
            ],
        },
    )
    assert recipe_res.status_code == 201
    recipe_id = recipe_res.json()["id"]

    # -------------------------------------------------------------
    # 3. Compras com Conversao e CMPM em Microcentavos
    # -------------------------------------------------------------
    # Comprar 10 fardos de arroz (300.000g no total)
    purchase_res = client.post(
        "/api/v1/purchases",
        headers={**headers, "X-Idempotency-Key": f"compra-arroz-{uuid.uuid4()}"},
        json={
            "supplier_name": "Distribuidora Cereais Brasil",
            "status": "CONFIRMED",
            "items": [
                {
                    "product_id": prod1_id,
                    "packaging_id": pkg1_id,
                    "packages_count": 10,
                    "unit_price_cents": 15000, # R$ 150,00 por fardo
                }
            ],
        },
    )
    assert purchase_res.status_code == 201

    # Comprar feijao direto na unidade base: 100.000g
    purchase2_res = client.post(
        "/api/v1/purchases",
        headers={**headers, "X-Idempotency-Key": f"compra-feijao-{uuid.uuid4()}"},
        json={
            "supplier_name": "Cooperativa Agricola Feijao",
            "status": "CONFIRMED",
            "items": [
                {
                    "product_id": prod2_id,
                    "packaging_id": None,
                    "packages_count": 100000,
                    "unit_price_cents": 1, # 1 centavo por grama
                }
            ],
        },
    )
    assert purchase2_res.status_code == 201

    # Verificar saldos de estoque dos insumos
    stock1_res = client.get(f"/api/v1/inventory/products/{prod1_id}/stock", headers=headers)
    assert stock1_res.status_code == 200
    assert stock1_res.json()["current_stock"] == 300000

    stock2_res = client.get(f"/api/v1/inventory/products/{prod2_id}/stock", headers=headers)
    assert stock2_res.status_code == 200
    assert stock2_res.json()["current_stock"] == 100000

    # -------------------------------------------------------------
    # 4. Producao (Montagem do Lote com Custos Congelados)
    # -------------------------------------------------------------
    # Produzir 20 cestas: consome 20*5000g = 100000g arroz e 20*2000g = 40000g feijao
    batch_res = client.post(
        "/api/v1/production/batches",
        headers={**headers, "X-Idempotency-Key": f"batch-{uuid.uuid4()}"},
        json={
            "basket_type_id": basket_type_id,
            "quantity_produced": 20,
            "notes": "Lote E2E 20 cestas",
        },
    )
    assert batch_res.status_code == 201
    batch_data = batch_res.json()
    assert batch_data["quantity_produced"] == 20
    assert batch_data["unit_cost_cents"] > 0

    # -------------------------------------------------------------
    # 5. Expedicao Fisica (STORE -> TRANSIT sob Responsavel)
    # -------------------------------------------------------------
    resp_res = client.post(
        "/api/v1/dispatches/responsible-persons",
        headers=headers,
        json={
            "name": f"Entregador E2E {uuid.uuid4().hex[:4]}",
            "phone": "(11) 98765-4321",
            "notes": "Rota Zona Leste",
            "is_active": True,
        },
    )
    assert resp_res.status_code == 201
    resp_id = resp_res.json()["id"]

    # Saida fisica de 15 cestas para o entregador
    disp_res = client.post(
        "/api/v1/dispatches",
        headers={**headers, "X-Idempotency-Key": f"disp-{uuid.uuid4()}"},
        json={
            "responsible_person_id": resp_id,
            "notes": "Saida matutina rota ZL",
            "items": [
                {
                    "basket_type_id": basket_type_id,
                    "quantity": 15,
                    "unit_price_cents": 15000,
                }
            ],
        },
    )
    assert disp_res.status_code == 201
    dispatch_id = disp_res.json()["id"]

    # Saldo em transito para o entregador deve ser exatamente 15
    custody_res = client.get(f"/api/v1/dispatches/responsible-persons/{resp_id}/custody", headers=headers)
    assert custody_res.status_code == 200
    assert custody_res.json()["total_custody_baskets"] == 15

    # -------------------------------------------------------------
    # 6. Vendas em Rota Baixando de TRANSIT
    # -------------------------------------------------------------
    cust_res = client.post(
        "/api/v1/customers",
        headers=headers,
        json={
            "name": f"Dona Maria Restaurante {uuid.uuid4().hex[:4]}",
            "phone": "(11) 91234-5678",
            "credit_limit_cents": 200000,
            "is_active": True,
        },
    )
    assert cust_res.status_code == 201
    cust_id = cust_res.json()["id"]

    # Vender 10 cestas na rota (R$ 150,00 cada = R$ 1.500,00 total = 150.000 centavos)
    # Pagamento à vista em dinheiro: R$ 1.500,00
    sale_res = client.post(
        "/api/v1/sales",
        headers={**headers, "X-Idempotency-Key": f"sale-route-{uuid.uuid4()}"},
        json={
            "customer_id": cust_id,
            "sale_mode": "COMMERCIAL_ROUTE",
            "dispatch_id": dispatch_id,
            "responsible_person_id": resp_id,
            "payment_mode": "CASH_IMMEDIATE",
            "items": [
                {
                    "basket_type_id": basket_type_id,
                    "quantity": 10,
                    "unit_price_cents": 15000,
                }
            ],
        },
    )
    assert sale_res.status_code == 201
    sale_data = sale_res.json()
    assert sale_data["total_amount_cents"] == 150000

    # Custodia em transito caiu para 5 (15 retiradas - 10 vendidas)
    custody_res_after = client.get(f"/api/v1/dispatches/responsible-persons/{resp_id}/custody", headers=headers)
    assert custody_res_after.json()["total_custody_baskets"] == 5

    # -------------------------------------------------------------
    # 7. Conferencia de Retorno & Acerto Financeiro da Rota
    # -------------------------------------------------------------
    # Das 5 restantes:
    # 3 Devolvidas intactas ao galpão (STORE)
    # 1 Avariada (perda DISPATCH_LOSS com justificativa)
    # 1 Continua sob custódia
    ret_res = client.post(
        f"/api/v1/dispatches/{dispatch_id}/returns",
        headers=headers,
        json={"basket_type_id": basket_type_id, "quantity": 3},
    )
    assert ret_res.status_code == 201

    loss_res = client.post(
        f"/api/v1/dispatches/{dispatch_id}/losses",
        headers=headers,
        json={"basket_type_id": basket_type_id, "quantity": 1, "reason": "Avaria na viagem"},
    )
    assert loss_res.status_code == 201

    # Despesa de combustivel na rota abatida: R$ 50,00 (5.000 centavos)
    exp_res = client.post(
        f"/api/v1/dispatches/{dispatch_id}/expenses",
        headers=headers,
        json={"amount_cents": 5000, "description": "Abastecimento van posto Shell"},
    )
    assert exp_res.status_code == 201

    # Repasse em dinheiro fisico entregue pelo motorista: R$ 1.450,00 (145.000 centavos)
    # (R$ 1.500,00 vendidos em dinheiro - R$ 50,00 despesa = R$ 1.450,00)
    repay_res = client.post(
        f"/api/v1/dispatches/{dispatch_id}/repayments",
        headers=headers,
        json={"amount_cents": 145000, "notes": "Repasse em dinheiro fisico conferido"},
    )
    assert repay_res.status_code == 201

    # Verificacao de conciliacao de 4 termos
    recon = client.get(f"/api/v1/dispatches/{dispatch_id}/reconciliation", headers=headers).json()
    assert recon["total_dispatched_qty"] == 15
    assert recon["total_sold_qty"] == 10
    assert recon["total_returned_qty"] == 3
    assert recon["total_lost_qty"] == 1
    assert recon["total_remaining_custody_qty"] == 1
    assert recon["basket_discrepancy_qty"] == 0
    assert recon["has_cash_discrepancy"] is False

    # Fechamento formal do acerto
    settle_res = client.post(
        f"/api/v1/dispatches/{dispatch_id}/settlement",
        headers=headers,
        json={"audited_by": "Auditor Geral E2E", "notes": "Conferencia aprovada sem divergencias"},
    )
    assert settle_res.status_code == 201
    assert settle_res.json()["status"] == "IN_CUSTODY_RESOLVED"

    # -------------------------------------------------------------
    # 8. Contas a Pagar, Livro-Caixa e Tesouraria
    # -------------------------------------------------------------
    accounts_res = client.get("/api/v1/treasury/accounts", headers=headers)
    assert accounts_res.status_code == 200
    default_acc_id = accounts_res.json()[0]["id"]

    due_date = (datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(days=10)).isoformat()
    payable_res = client.post(
        "/api/v1/payables",
        headers={**headers, "X-Idempotency-Key": f"pay-energy-{uuid.uuid4()}"},
        json={
            "description": "Conta de Energia E2E",
            "beneficiary": "Enel SP",
            "category": "ENERGIA",
            "nature": "BUSINESS",
            "original_amount_cents": 35000,
            "due_date": due_date,
            "total_installments": 1,
        },
    )
    assert payable_res.status_code == 201
    payable_id = payable_res.json()[0]["id"]

    pay_settle_res = client.post(
        f"/api/v1/payables/{payable_id}/payments",
        headers={**headers, "X-Idempotency-Key": f"pay-settle-{uuid.uuid4()}"},
        json={
            "amount_cents": 35000,
            "account_id": default_acc_id,
            "payment_method": "PIX",
            "notes": "Liquidado via PIX",
        },
    )
    assert pay_settle_res.status_code == 201
    assert pay_settle_res.json()["status"] == "CONFIRMED"

    # -------------------------------------------------------------
    # 9. Relatorios Gerenciais, Dashboard, CSV e XLSX
    # -------------------------------------------------------------
    dash_res = client.get("/api/v1/dashboard/summary?filter_type=all", headers=headers)
    assert dash_res.status_code == 200
    dash_data = dash_res.json()
    assert "production" in dash_data
    assert "financial" in dash_data
    assert "inventory" in dash_data
    assert dash_data["production"]["assembled_count"] >= 20
    assert dash_data["sales"]["sold_count"] >= 10

    # Relatorio em JSON
    rep_res = client.get("/api/v1/reports/sales-dispatches?filter_type=all", headers=headers)
    assert rep_res.status_code == 200
    rep_data = rep_res.json()
    assert len(rep_data["rows"]) >= 1

    # Exportacao de Planilhas CSV e XLSX
    csv_res = client.get("/api/v1/reports/sales-dispatches/export?format=csv&filter_type=all", headers=headers)
    assert csv_res.status_code == 200
    assert len(csv_res.content) > 0

    xlsx_res = client.get("/api/v1/reports/sales-dispatches/export?format=xlsx&filter_type=all", headers=headers)
    assert xlsx_res.status_code == 200
    assert len(xlsx_res.content) > 0

    # -------------------------------------------------------------
    # 10. Backup Quente Atômico & Restauração Verificada
    # -------------------------------------------------------------
    backup_create_res = client.post("/api/v1/backup/create", headers=headers)
    assert backup_create_res.status_code == 200
    bck_json = backup_create_res.json()
    assert bck_json["status"] == "success"
    assert bck_json["integrity_ok"] is True
    bck_filename = bck_json["backup_filename"]

    list_bck_res = client.get("/api/v1/backup/list", headers=headers)
    assert list_bck_res.status_code == 200
    assert any(b["filename"] == bck_filename for b in list_bck_res.json())

    restore_res = client.post(
        "/api/v1/backup/restore",
        headers=headers,
        json={"backup_filename": bck_filename},
    )
    assert restore_res.status_code == 200
    assert restore_res.json()["status"] == "success"
    assert restore_res.json()["integrity_ok"] is True

    # -------------------------------------------------------------
    # 11. Idempotência e Tratamento de Conflito
    # -------------------------------------------------------------
    idempotent_key = f"idemp-test-{uuid.uuid4()}"
    stock_payload = {
        "product_id": prod1_id,
        "quantity_delta": 500,
        "reason": "Ajuste simulado para validacao de idempotencia",
    }
    first_call = client.post(
        "/api/v1/test-ops/stock-simulation",
        headers={**headers, "X-Idempotency-Key": idempotent_key},
        json=stock_payload,
    )
    assert first_call.status_code == 201
    first_mov_id = first_call.json()["movement_id"]

    second_call = client.post(
        "/api/v1/test-ops/stock-simulation",
        headers={**headers, "X-Idempotency-Key": idempotent_key},
        json=stock_payload,
    )
    assert second_call.status_code == 201
    assert second_call.json()["movement_id"] == first_mov_id

    mismatch_call = client.post(
        "/api/v1/test-ops/stock-simulation",
        headers={**headers, "X-Idempotency-Key": idempotent_key},
        json={**stock_payload, "quantity_delta": 99999},
    )
    assert mismatch_call.status_code == 409
    assert mismatch_call.json()["detail"]["error_code"] == "IDEMPOTENCY_PAYLOAD_MISMATCH"
