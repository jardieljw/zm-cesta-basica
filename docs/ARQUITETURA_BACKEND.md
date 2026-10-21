# Arquitetura do Back-End, Governança Técnica e Roteiro de Implementação

Revisão Canônica: **17/10/2026**.  
Registro histórico da revisão canônica de **17/10/2026**: **442 testes de backend** e **352 testes Flutter** constavam como aprovados (100% verde).

Documentos de Referência: [ARCHITECTURE.md](../ARCHITECTURE.md), [AGENT_INSTRUCTIONS.md](../AGENT_INSTRUCTIONS.md), [backend/README.md](../backend/README.md), [docs/README.md](README.md).

> **Finalidade deste documento:** Este é o guia canônico ("guarda-costas") de arquitetura e evolução do backend do **ZM Cesta Básica**. Ele estabelece como o backend opera internamente, o que cada módulo faz, os motivos de engenharia para a prevenção de duplicidades financeiras e o catálogo exato das funções que faltam implementar. Qualquer sessão de desenvolvimento no backend DEVE consultar e respeitar as regras aqui consolidadas.

---

## 1. Como o Back-End Funciona por Dentro (Engenharia e Invariantes)

O backend do sistema é um **Monólito Modular** de alta durabilidade desenvolvido em **Python 3.14** e **FastAPI**, utilizando **SQLAlchemy** e banco de dados **SQLite local**. O sistema é 100% autônomo, executado em rede local privada (Wi-Fi/Ethernet) sem qualquer dependência de nuvem.

### 1.1. Concorrência e Durabilidade no SQLite
* **Modo WAL (`PRAGMA journal_mode = WAL`):** Leituras concorrentes nunca bloqueiam escritas, permitindo consultas simultâneas de múltiplos terminais sem travar mutações.
* **Durabilidade Total (`PRAGMA synchronous = FULL`):** Cada transação confirmada é gravada fisicamente no disco antes do retorno, protegendo os dados contra desligamentos abruptos ou falhas de energia.
* **Serialização Estrita de Escrita (`BEGIN IMMEDIATE`):**
  * Todas as operações de mutação no banco iniciam travando o acesso exclusivo de escrita no início da transação através de um listener central em [`backend/app/core/database.py`](../backend/app/core/database.py).
  * Isso elimina condições de corrida (*TOCTOU - Time-Of-Check to Time-Of-Use*) e impede que saldos de estoque físico ou financeiro fiquem negativos durante operações concorrentes.
* **Integridade Referencial e Conectividade:** `PRAGMA foreign_keys = ON` e `PRAGMA busy_timeout = 60000` (timeout de 60 segundos) ativos em todas as conexões.

### 1.2. Idempotência Transacional
* Toda operação comercial ou financeira (compras, montagens, vendas, pagamentos, recebimentos, revisões e conciliações) exige o cabeçalho `X-Idempotency-Key` (UUIDv4) com hash SHA-256 do corpo da requisição gravado na tabela `idempotency_records`.
* **Reenvios Idênticos:** Se a mesma chave com o mesmo payload for reenviada (ex.: perda de conexão após gravação), o backend retorna a resposta gravada em cache sem reprocessar regras contábeis ou duplicar estoques.
* **Conflito de Payload:** Modificações no payload com uma chave já existente resultam em `HTTP 409 Conflict`.
* **Resolução Prévia:** O replay de idempotência é avaliado antes das checagens de precondição de saldo, permitindo recuperação de recibos locais mesmo após o título estar quitado ou alterado.

### 1.3. Aritmética Comercial e Contábil Estrita (Zero Float)
* **Valores Monetários:** Valores comerciais são representados exclusivamente como números inteiros em **centavos** (`cents`), sem uso de ponto flutuante (*float*).
* **CMPM em Microcentavos:** O Custo Médio Ponderado Móvel (CMPM) unitário dos insumos na unidade base (`G`, `ML`, `UNIT`) é calculado e persistido em escala fixa de **microcentavos** (`cost_price_microcents INTEGER`, onde $1 \text{ centavo} = 10.000 \text{ microcentavos}$) com arredondamento bancário *half-even*:
  $$CMPM_{\text{novo}} = \text{round}\left(\frac{(Estoque_{\text{atual}} \times CMPM_{\text{antigo}}) + (Q_{\text{compra}} \times CustoUnitCompra_{\text{microcents}})}{Estoque_{\text{atual}} + Q_{\text{compra}}}\right)$$
* **Congelamento do Custo da Cesta:** O custo unitário da cesta pronta é congelado de forma imutável em centavos inteiros (`unit_cost_cents`) nas tabelas `production_batches` e `sale_items`. Isso assegura congruência de 100% entre o valor dos estoques e o CMV apurado na DRE Gerencial.

### 1.4. Livros-Razão Estritamente *Append-Only*
* As tabelas [`inventory_movements`](../backend/app/models/movements.py) (estoque físico) e [`cash_flow_entries`](../backend/app/models/financial.py) (livro-caixa da tesouraria) são puramente cumulativas.
* Triggers nativos no SQLite bloqueiam qualquer instrução `UPDATE` ou `DELETE` nessas tabelas:
  ```sql
  CREATE TRIGGER trg_inventory_movements_no_update BEFORE UPDATE ON inventory_movements
  BEGIN SELECT RAISE(ABORT, 'inventory_movements is append-only: updates forbidden'); END;
  ```
* Correções ocorrem exclusivamente por lançamentos reversos rastreáveis (`is_reversal=True`, `reversal_of_id`).
* Saldos nunca são colunas editáveis diretamente: são apurados dinamicamente somando-se os deltas das movimentações.

### 1.5. Temporalidade e Fusos Horários
* Todos os carimbos de data/hora gravados nas tabelas de auditoria utilizam **UTC**.
* O dia civil operacional da empresa opera em **UTC−03 (América/São Paulo)**. Datas civis informadas pelo operador (`payment_business_date`) são convertidas para o início do dia em UTC (`03:00:00Z`) para compatibilização estrita com os filtros de período do dashboard e relatórios.

### 1.6. Isolamento e Governança de Migrações
* As suítes de teste automatizadas utilizam bancos temporários descartáveis em memória ou em diretório isolado, sendo terminantemente proibido gravar dados de teste no banco real da empresa (`backend/data/estoque.db`).
* Toda e qualquer alteração de schema deve ser realizada via migração versionada do Alembic (`alembic/versions/`). O comando `create_all` no startup do FastAPI cria apenas tabelas legadas essenciais e exclui explicitamente as tabelas de importações financeiras, que exigem aplicação manual controlada.

---

## 2. O que o Back-End Faz Hoje (Mapeamento dos Domínios)

O backend é organizado em módulos com limites de domínio estritos:

| Módulo | Entidades Principais | Comportamento e Regras Homologadas |
| :--- | :--- | :--- |
| **Produtos & Embalagens** | `Product`, `ProductPackaging` | Gerencia insumos na unidade base, estoque mínimo e embalagens de fornecedor com fatores de conversão estritos. Possui suporte a inativação lógica (`is_active = False`) e exclusão definitiva de produtos nunca utilizados (`DELETE /products/{id}/permanent`), que valida atomicamente sob `BEGIN IMMEDIATE` a ausência total de vínculos em receitas, compras, lotes e movimentos. |
| **Tipos de Cesta & Receitas** | `BasketType`, `RecipeVersion`, `RecipeItem` | Versionamento imutável de receitas padrão. Flag `tracks_finished_stock`: quando ativo, permite manter saldo pré-fabricado e venda de cestas prontas; quando inativo, força montagem na venda e rejeita ajustes manuais ou vendas como pronta. Exclusão de catálogo (`removed_at`, `is_active=False`) preserva histórico de vendas e montagens. |
| **Compras de Insumos** | `Purchase`, `PurchaseItem` | Entrada de insumos com conversão de embalagens para a unidade-base, recálculo atômico do CMPM em microcentavos, criação de contas a pagar (`accounts_payable`) ou baixa à vista no caixa. Estornos contábeis condicionados à existência de saldo físico. |
| **Montagem & Produção** | `ProductionBatch`, `ProductionBatchItem` | Ordens de montagem padrão ou personalizada (copiando receita para composição editável sem corromper o cadastro do tipo de cesta). Consumo atômico de insumos ao CMPM e congelamento do custo unitário em centavos. Triagem de desmontagem (retorno de intactos a `STORE` e perdas em `ASSEMBLY_LOSS`). |
| **Vendas & Clientes** | `Customer`, `Sale`, `SaleItem`, `SalesReceivable`, `ReceivablePayment` | Vendas balcão (`STORE`) e rotas (`TRANSIT`), montagem sob demanda sem duplo consumo, controle de limite de crédito, contas a receber (fiado) com amortizações parciais ou quitação integral com precondição de saldo (`expected_balance_cents`) e cancelamento de venda com escolha explícita do destino das cestas. |
| **Contas a Pagar & Tesouraria** | `FinancialAccount`, `AccountPayable`, `PayablePayment`, `CashFlowEntry` | Contas financeiras da empresa, títulos a pagar com suporte a parcelamento e recorrência. Segregação mandatória de despesas da empresa (`nature = 'BUSINESS'`) vs. retiradas particulares dos sócios (`nature = 'PERSONAL_WITHDRAWAL'`). Pagamento revisado com precondição atômica de saldo e dia civil. |
| **Dashboard & Relatórios** | `business_dashboard`, `reports` | `dashboard/business-summary` e `reports/business-financial-summary`: faturamento, CMV real do razão de estoque, margem bruta, contas em atraso e resultado gerencial sem mascaramento. Exportação digital (CSV e XLSX) e gerador de formulários A4 (preenchidos e em branco para escrita à mão). |
| **Base Financeira Multibanco** | `FinancialSource`, `FinancialDocument`, `FinancialStatement`, `FinancialStatementItem`, `FinancialTransaction`, `FinancialImportPreview`, `FinancialReviewCorrection`, `FinancialBillAssessment` | Base isolada de extratos, faturas e comprovantes (migrações `fa0`, `fb1`, `fc2`, `fd3`). Guarda de BLOB original e SHA-256. Leitores CSV: `csv_auto` v2, `generic_csv` v4 e adaptadores bancários v3. Leitor de entrada PDF `pdf_auto` v4; os parsers por layout usam identificadores `*_v1`. Extração via `pdfplumber` 0.11.10 em subprocesso descartável, com timeout de 20 s e limites de 10 MB/40 páginas. Parsers PDF para extrato Nubank e faturas Nubank, PicPay, Itaú, Santander e Inter. Revisão auditável de duplicidades (`NEW`/`LINK`/`IGNORE`). Conciliação com livro-caixa sem duplicar pagamentos. Conferência de procedência de faturas (`fd3`) com verificação exata de transcrições manuais. |

---

## 3. O que Devemos Fazer e Por Quê (A Conexão Negócio-Engenharia)

### 3.1. O Objetivo do Negócio
O operador da ZM Cesta Básica precisa reunir, em uma única visão centralizada, movimentações bancárias, dívidas de fornecedores e faturas de cartão de crédito de múltiplas contas (Pessoa Física e Pessoa Jurídica) e instituições financeiras. O sistema deve permitir saber exatamente o que a empresa deve e o que entrou, **sem contar a mesma operação duas vezes e sem fundir operações legítimas distintas**.

### 3.2. A Necessidade Crítica de Isolamento em Camadas (Prevenção de Duplicidades)
Se o backend criasse títulos de contas a pagar ou baixas de caixa diretamente a partir da leitura de linhas de extratos ou faturas, o sistema geraria graves distorções:

1. **Prevenção da Triplicação de Despesas:**
   * Uma compra de R$ 5.000 em arroz já entra pelo módulo de Compras, alimenta o estoque com CMPM congelado e gera uma conta a pagar de fornecedor.
   * Se essa compra foi paga no cartão de crédito corporativo, ela aparecerá na fatura do cartão. Se a fatura gerasse outro título, teríamos R$ 10.000 de despesa.
   * Quando a fatura do cartão for paga pelo banco da empresa, esse pagamento gerará uma saída de R$ 5.000 no extrato bancário. Se o extrato gerasse outra despesa, teríamos R$ 15.000 de despesa apurada para uma única compra real de R$ 5.000.
2. **Linhas que Não São Compras na Fatura:**
   * Faturas de cartão trazem linhas de saldo anterior, pagamentos intermediários da fatura passada, estornos de compras canceladas, tarifas bancárias, juros/IOF de atraso e ofertas de parcelamento/limite.
   * Tratar a soma das linhas de uma fatura como o total devido gera divergências imediatas (comprovado nos testes reais onde faturas CSV e PDF divergiam em número de linhas e redação).
3. **Segregação PF vs. PJ e Cartão vs. Caixa:**
   * Despesas particulares de sócios passadas no cartão da empresa devem ser pagas na fatura, mas classificadas como `PERSONAL_WITHDRAWAL` para abater o caixa sem distorcer o lucro operacional do negócio na DRE.
4. **O Modelo em 5 Camadas Estanques:**
   $$\text{1. Documento Original (BLOB)} \longrightarrow \text{2. Leitura & Prévia (Sintaxe)} \longrightarrow \text{3. Procedência & Conferência (Controles)} \longrightarrow \text{4. Revisão Semântica (Classificação)} \longrightarrow \text{5. Integração de Obrigações (Pagar / Caixa)}$$

---

## 4. O Catálogo Exato do que Falta Fazer no Back-End

As pendências técnicas do backend estão organizadas em duas frentes:

### A. Domínio de Faturas e Importações Financeiras (Fronteira Principal)

1. **Classificação Semântica Auditável das Linhas de Fatura (Decisão FAT-005 - IMPLEMENTADA):**
   * *Status:* Entregue com migração `fe4b5c6d8714` e tabelas `financial_bill_semantic_reviews` e `financial_bill_semantic_items`.
   * *Comportamento:* Categorização de cada linha entre `PURCHASE_BUSINESS`, `PURCHASE_PERSONAL`, `BILL_PAYMENT`, `PREVIOUS_BALANCE`, `FINANCIAL_CHARGES`, `REFUND_CREDIT` e `CONTEXT_ONLY`. Validação matemática estrita da equação da fatura:
     $$\text{Total Declarado} = \text{Saldo Anterior} + \text{Compras PJ} + \text{Compras PF} + \text{Encargos} - \text{Pagamentos} - \text{Créditos}$$
     Somente faturas com diferença zero são promovidas a `status = 'APPROVED'` e ficam aptas à geração de obrigações.

2. **Integração de Faturas com Contas a Pagar (`accounts_payable`) (Decisões FAT-006 a FAT-009 - IMPLEMENTADA):**
   * *Status:* Entregue com motor de consolidação e tabela `financial_bill_obligations`.
   * *Comportamento:*
     * **Vínculo com Compras Existentes:** Compras em `purchases` reaproveitam o título a pagar existente (`component_type = 'PURCHASE_LINKED'`), sem duplicar despesa ou recalcular CMPM.
     * **Novos Títulos Auditados:** Gera títulos com categoria `CARTAO_CREDITO` e segregação estrita entre `BUSINESS` e `PERSONAL_WITHDRAWAL` (retiradas de sócios).
     * **Zero Duplicação de Fatura Anterior/Créditos:** Linhas de `BILL_PAYMENT`, `PREVIOUS_BALANCE`, `REFUND_CREDIT` e `CONTEXT_ONLY` geram ZERO títulos a pagar.
     * **Idempotência Transacional:** Geração protegida sob `BEGIN IMMEDIATE` com replay idempotente seguro.
   * *Front-End Integrado:* Tela `FinancialBillReviewView` no Flutter com cálculo de equação em tempo real, seleção de categorias e disparo de geração de obrigações.
3. **Ampliação Multibanco (Novos Adaptadores de Leitura):**
   * *Registro histórico na revisão canônica de 17/10/2026:* suporte descrito para Nubank (conta CSV/PDF e cartão PDF) e PicPay (cartão PDF); leitores para Santander, Banco do Brasil, Itaú e Caixa ainda constavam como pendentes.
   * *Estado do código conferido em 21/10/2026:* implementados os leitores CSV `csv_auto` v2, `generic_csv` v4 e adaptadores v3 para Nubank, Nu Empresas, Itaú, Santander, Inter, Mercado Pago, Banco do Brasil, Bradesco e Caixa; para PDF, parsers de extrato Nubank e de faturas Nubank, PicPay, Itaú, Santander e Inter.
   * *Evidência de testes existente:* `test_multibank_readers.py` contém casos para adaptadores CSV, amostras reais de CSV Nubank e PDF Nu Empresas e layouts PDF sintéticos para Itaú, Santander e Inter. A existência desses casos não comprova execução recente nem homologação de todos os layouts com documentos reais.
   * *O que falta:* ampliar a validação com amostras reais representativas e registrar homologação por layout; novos adaptadores ficam condicionados a instituições prioritárias ainda não cobertas.
4. **Tratamento de Senha em PDFs e Suporte a OCR:**
   * *Registro histórico na revisão canônica de 17/10/2026:* o documento registrava `PDF_PASSWORD_REQUIRED` para faturas protegidas, `PDF_OCR_OR_TEXT_REQUIRED` para digitalizações sem texto e listava o recebimento de senha como pendente.
   * *Estado do código conferido em 21/10/2026:* a prévia PDF aceita o campo opcional `password` e o worker o encaminha ao `pdfplumber`; senha ausente ou incorreta continua retornando `PDF_PASSWORD_REQUIRED`.
   * *Evidência de testes existente:* `test_multibank_pdf_password_decryption_flow` simula a aceitação e a rejeição substituindo `pdfplumber.open`; `test_wrong_password_does_not_poison_correct_password_retry` simula o fluxo da API com o extrator substituído. Esses casos cobrem os caminhos simulados, não PDFs bancários protegidos reais, suporte universal ou homologação.
   * *O que falta:* pipeline local de OCR para documentos digitalizados sem texto extraível (`PDF_OCR_OR_TEXT_REQUIRED`).
5. **Aplicação Segura da Migração `fd3a4b5c7613` em Produção:**
   * *Registro histórico de 17/10/2026:* a migração `fd3a4b5c7613` (as 3 tabelas de conferência e pareceres de faturas) foi validada apenas em cópia de teste; o banco da empresa `estoque.db` foi observado em `fc2f3a4b6512`.
   * *Atualização documentada em 20/10/2026:* [a retomada financeira](RETOMADA_IMPORTACAO_FATURAS.md) registra `f39a012b2159`, descendente de `fd3a4b5c7613` na cadeia Alembic, aplicada após backup validado e ativada localmente. Esse registro não comprova aplicação em produção nem homologação integral, e não identifica a observação histórica de `estoque.db` como o ambiente de produção.
   * *Critério para produção:* não tratar a ativação local como prova de implantação. Antes de afirmar disponibilidade em produção, confirmar evidência de backup quente verificado e aplicação formal do Alembic naquele ambiente; acompanhar o estado corrente pela retomada canônica.
6. **Harmonização de Segurança e Autenticação Global:**
   * *Situação atual:* As rotas novas de `/financial-imports` exigem estritamente token Bearer de dispositivo ativo. As rotas legadas em `backend/app/api/deps.py` ainda toleram fallback do mestre local no loopback.
   * *O que falta:* Unificar a política de autenticação global do backend conforme documentado em [PESQUISA_PROXIMO_INCREMENTO_FINANCEIRO.md](PESQUISA_PROXIMO_INCREMENTO_FINANCEIRO.md).

---

### B. Domínio Comercial e Estoque de Cestas (Fronteira Secundária)

7. **Seleção de Lote Customizado Produzido na Venda ([docs/EVOLUCAO_DO_MODULO_DE_CESTAS.md](EVOLUCAO_DO_MODULO_DE_CESTAS.md)):**
   * *Situação atual:* O backend já permite registrar montagens personalizadas antecipadas (gerando `production_batches` com saldo próprio). Na venda, o operador vende cestas prontas padrão ou monta na hora.
   * *O que falta:* Estender o serviço de vendas (`create_sale`) para permitir selecionar e abater explicitamente o saldo de um `production_batch_id` personalizado pré-fabricado em estoque.

---

## 5. Protocolo Obrigatório de Pré-Implementação

Para qualquer alteração no código do backend:
1. **Checagem de Saúde:** Executar `& ".\backend\.venv\Scripts\python.exe" -m pytest backend/tests -q`. 100% dos testes devem passar.
2. **Isolamento de Banco:** Testes devem redirecionar a engine e `SessionLocal` para banco descartável, nunca tocando em `estoque.db`.
3. **Transações:** Todas as mutações de domínio devem utilizar `BEGIN IMMEDIATE`.
4. **Idempotência:** Mutações comerciais/financeiras devem aceitar e validar `X-Idempotency-Key`.
5. **Preservação de Histórico:** Jamais emitir `DELETE` ou `UPDATE` nas tabelas append-only (`inventory_movements`, `cash_flow_entries`, `financial_bill_*`). Correções sempre ocorrem por estornos ou novas decisões imutáveis.
6. **Alembic:** Qualquer alteração de tabela deve ser acompanhada de migração versionada bidirecional (`upgrade` e `downgrade`).
