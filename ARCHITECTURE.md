# Arquitetura, Governança Técnica e Diretrizes Permanentes
## ZM Cesta Básica — Sistema de Gestão de Estoque, Produção e Vendas

**Documento Canônico de Engenharia e Princípios de Arquitetura**  
**Versão:** 2.0 (Revisão Aprofundada Pré-Fase 4: Custódia, Repasses, CMPM, CMV Real e Integridade Financeira)  
**Status do Projeto:** Fases 1, 2 e 3 Concluídas e Homologadas (101 testes automatizados ativos e aprovados)  
**Topologia:** Monólito Modular em Rede Local Privada (Wi-Fi/Ethernet) sem dependência de nuvem  
**Público-alvo:** Desenvolvedores, Engenheiros de Software e Agentes de Inteligência Artificial

---

## 1. Visão Geral e Princípios Fundamentais

Este documento estabelece as regras mandatórias de engenharia, governança arquitetural e boas práticas para todo o ciclo de vida do sistema **ZM Cesta Básica**. Qualquer desenvolvimento futuro — realizado por engenheiros humanos ou agentes de IA — deve obedecer estritamente a estas diretrizes.

### Os 6 Princípios Permanentes de Engenharia

### 1.1. Arquitetura Evolutiva (Monólito Modular)
O sistema é estruturado como um **Monólito Modular** de alta coesão e baixo acoplamento:
- **Separação Rígida de Responsabilidades:**
  - `estoque / inventory`: Livro-razão contábil *append-only*, sub-localizações de custódia (armazém vs. rota), cálculo dinâmico de saldos e ajustes de balanço.
  - `produtos / products`: Catálogo de insumos, unidades base, CMPM (Custo Médio Ponderado Móvel) e embalagens comerciais com conversão.
  - `receitas / recipes`: Tipos de cesta e versionamento imutável de composições padrão.
  - `compras / purchases`: Entrada de insumos de fornecedores, conversão de embalagens, atualização de custo de aquisição e estornos contábeis.
  - `montagem / production` (Fase 4): Ordens de montagem, consumo de insumos valorizados pelo CMPM, lote padrão vs. personalizado e apuração do custo unitário do lote.
  - `vendas / sales` (Fase 5): Vendas de balcão e rotas, baixa de produto acabado, CMV congelado no item e fluxo atômico de montagem simultânea.
  - `expedicao / dispatch` (Fase 6): Cargas de saída, custódia de agentes comerciais sem login, conferência física de retorno e conciliação de repasses item a item.
  - `financeiro / financial` (Fase 7): Vendas fiadas, contas a receber, contas a pagar (empresariais vs. retiradas pessoais), tesouraria e livro-caixa imutável.
  - `relatorios / reports` (Fase 8): DRE Gerencial com CMV real do livro-razão, margens brutas, fluxo de caixa e exportações em planilhas.
  - `infraestrutura`: Segurança TLS, autenticação de dispositivos, backups quentes e rotinas de manutenção.
- **Proibição de Dependências Circulares:** Os módulos superiores consomem serviços dos módulos base, nunca o inverso.
- **Centralização de Regras de Negócio:** Nenhuma regra de estoque, cálculo financeiro ou conversão de unidades reside no cliente Flutter. A API FastAPI é a autoridade única sobre o estado da aplicação.

---

### 1.2. Evolução Segura e Preservação de Comportamento
1. **Inspeção Prévia Obrigatória:** Antes de editar código, inspecionar arquivos afetados e identificar todos os pontos de consumo.
2. **Avaliação de Impacto e Não-Regressão:** Executar a suíte completa de testes automatizados (`pytest backend/tests -v`), mantendo 100% de aprovação verde (atualmente 101 testes).
3. **Proibição de Exclusão ou Substituição Silenciosa:** Proibido remover ou quebrar endpoints ou regras homologadas sem autorização explícita.
4. **Evolução do Banco via Migrações Versionadas:** Schema gerenciado exclusivamente pelo Alembic com suporte a `upgrade()` e `downgrade()`.
5. **Rastreabilidade Contábil Imutável:** O livro-razão `inventory_movements` e o livro-caixa `cash_flow_entries` são estritamente *append-only*. Correções ocorrem exclusivamente por lançamentos reversos rastreáveis (estornos).

---

### 1.3. Front-End Adaptativo e Componentização Centralizada
- **Mobile First com Adaptação Desktop:** Experiência prioritária em Android (toque no galpão/rotas) e fluida no Windows Desktop (telas amplas, tabelas densas e atalhos).
- **Componentes Compartilhados:** Reutilização em `client/lib/widgets/shared/` de campos monetários (`AppMoneyField`), botões com spinner integrado (`AppButton`), cartões padronizados (`AppCard`) e tabelas responsivas (`AppDataTable`).
- **Gerenciamento de Estado:** `StatefulWidget` com serviços assíncronos desacoplados por tela e `ValueNotifier` para estados globais de aplicação.

---

### 1.4. Internacionalização (i18n) e Formatação Centralizada
- **Repositório Central de Strings:** Rótulos e mensagens centralizados em `AppStrings` (atualmente em português brasileiro `pt-BR`), desacoplando o código de telas para suportar múltiplos idiomas no futuro.
- **Valores Monetários em Centavos:** Todo valor trafegado e armazenado é um **número inteiro em centavos** (`cents`), formatado na tela pelo pacote `intl` (`R$ X,XX`).
- **Datas em UTC:** Timestamps trafegados e armazenados em UTC ISO-8601 e formatados no fuso local no cliente.

---

### 1.5. Testes Contínuos e Qualidade
A suíte de testes deve permanecer 100% verde a cada commit, combinando testes unitários, de concorrência com `BEGIN IMMEDIATE`, de idempotência e de integração com a API.

---

## 2. Diretrizes Técnicas Aprofundadas (Revisão Pré-Fase 4)

### 2.1. Custódia de Cestas e Sub-localizações de Estoque
Para diferenciar estoque disponível no estabelecimento de cestas sob responsabilidade de intermediários:
1. **Localização Contábil (`location_type`):**
   - `STORE`: Estoque físico presente no armazém/loja física.
   - `TRANSIT`: Cestas expedidas sob custódia física de um intermediário (`commercial_agent_id`).
2. **Ciclo de Movimentação de Expedição:**
   - **Saída para Rota (`DISPATCH_TRANSFER`):**
     - Linha 1: `location_type = 'STORE'`, `quantity_delta = -N` (baixa do armazém da loja).
     - Linha 2: `location_type = 'TRANSIT'`, `commercial_agent_id = :agent_id`, `quantity_delta = +N` (entrada na custódia do agente).
     - *Saldo global da empresa permanece inalterado, mas o saldo disponível para venda no balcão da loja diminui de forma exata.*
   - **Venda na Rota (`SALE`):**
     - Linha: `location_type = 'TRANSIT'`, `commercial_agent_id = :agent_id`, `quantity_delta = -V` (baixa definitiva da cesta vendida).
   - **Retorno de Sobras Intactas (`DISPATCH_RETURN`):**
     - Linha 1: `location_type = 'TRANSIT'`, `commercial_agent_id = :agent_id`, `quantity_delta = -R`.
     - Linha 2: `location_type = 'STORE'`, `quantity_delta = +R` (devolução ao armazém).
   - **Perdas e Avarias na Rota (`DISPATCH_LOSS`):**
     - Linha: `location_type = 'TRANSIT'`, `commercial_agent_id = :agent_id`, `quantity_delta = -A` com justificativa obrigatória.
3. **Equação de Auditoria da Carga:**
   $$\text{Expedidas} = \text{Vendidas} + \text{Devolvidas} + \text{Avariadas}$$

---

### 2.2. Conciliação e Repasses com Detalhamento Item a Item
Para auditar divergências sem agregar valores cegamente:
1. **Três Estados Físicos do Dinheiro:**
   - `CLIENT_DEBT`: Venda fiada a receber do cliente final (`accounts_receivable.customer_id`).
   - `AGENT_IN_TRANSIT`: Dinheiro recebido pelo entregador, mas ainda sob custódia do intermediário.
   - `COMPANY_SETTLED`: Dinheiro recebido e conferido no caixa físico ou conta bancária da empresa.
2. **Detalhamento da Prestação de Contas (`settlement_allocations`):**
   Cada acerto (`responsible_settlements`) possui itens detalhados apontando individualmente:
   - `sale_id`: Vendas à vista realizadas na rota cujo dinheiro foi entregue.
   - `receivable_payment_id`: Cobranças de fiados antigos que o intermediário recebeu do cliente e está repassando.
   - `dispatch_item_id`: Cestas devolvidas ou avariadas.
   - `expense_voucher_id`: Despesas de viagem autorizadas (ex.: combustível com nota) abatidas do repasse.
   - `discrepancy_cents`: Divergência residual apurada por operação.

---

### 2.3. Metodologia de Custo Médio Ponderado Móvel (CMPM) e CMV Real
Para assegurar cálculo rigoroso e auditável do CMV e das margens de contribuição:
1. **Entrada de Compras de Insumos (`purchases`):**
   Ao confirmar uma compra com quantidade $Q_{compra}$ e custo unitário $C_{compra}$:
   $$CMPM_{novo} = \frac{(Estoque_{atual} \times CMPM_{antigo}) + (Q_{compra} \times C_{compra})}{Estoque_{atual} + Q_{compra}}$$
   - Esse valor atualiza o custo de referência do produto em `Product.cost_price_cents`.
   - O preço de aquisição original da nota fiscal permanece imutável em `purchase_items.unit_price_cents`.
2. **Ajustes de Estoque:**
   - Ajuste de Saída (`ADJUSTMENT_OUT`): Baixa contábil valorizada ao CMPM vigente no momento do ajuste (despesa operacional), sem alterar o CMPM unitário do saldo remanescente.
3. **Montagem de Cestas (`production_batches`):**
   - Ao produzir um lote de cestas, cada insumo consumido é valorizado pelo seu CMPM no momento da montagem:
     $$CustoInsumos_{batch} = \sum_{i} (QtdConsumida_i \times CMPM_i)$$
   - O custo unitário apurado do lote é gravado de forma **imutável** em `production_batches.unit_cost_cents`:
     $$CustoUnitCesta_{batch} = \frac{CustoInsumos_{batch} + CustoEmbalagem}{QtdCestasProduzidas}$$
4. **Custo Médio das Cestas Padrão Prontas:**
   Cestas padrão mantidas em estoque herdam o CMPM das ordens de montagem acumuladas.
5. **Apuração do CMV Real nas Vendas (`sales`):**
   - Ao vender uma cesta, o custo unitário do momento da venda é congelado em `sale_items.unit_cost_cents`.
   - CMV de cada item: $\text{CMV}_{item} = \text{Quantidade} \times \text{unit\_cost\_cents}$.
   - DRE Gerencial:
     $$\text{Margem Bruta} = \text{Receita Líquida de Vendas} - \sum \text{CMV}_{itens\_vendidos}$$

---

### 2.4. Contas a Pagar e Prevenção de Duplicidades Financeiras
1. **Fato Gerador vs. Liquidação Financeira:**
   - Compras de estoque a prazo (`payment_condition = 'CREDIT_TERM'`) geram títulos em `accounts_payable` com status `OPEN`. Elas **NÃO** geram lançamento imediato no livro-caixa (`cash_flow_entries`).
   - Compras à vista (`payment_condition = 'CASH_IMMEDIATE'`) geram o título e a liquidação atômica associada debitando a conta financeira da empresa em `cash_flow_entries`.
   - Essa segregação impede categoricamente a dupla contagem de saídas de caixa.
2. **Parcelamento:** Títulos de fornecedores suportam parcelamento com vencimentos e valores independentes (`payable_installments` ou parcelas com sufixo `/01`, `/02`).
3. **Classificação entre Despesas Empresariais e Pessoais:**
   - `nature = 'BUSINESS'`: Despesas operacionais do negócio (insumos, energia, aluguel, manutenção, frete). Computadas na DRE Operacional.
   - `nature = 'PERSONAL_WITHDRAWAL'`: Retiradas particulares, pró-labore ou despesas pessoais dos sócios. Deduzem saldo das contas financeiras da empresa, mas são **excluídas da apuração de lucro operacional da DRE**, preservando a análise real do negócio.

---

### 2.5. Integridade do Livro de Fluxo de Caixa (`cash_flow_entries`)
1. **Razão Financeiro Imutável:**
   - Entradas de dinheiro reais: `entry_type = 'INFLOW'`.
   - Saídas de dinheiro reais: `entry_type = 'OUTFLOW'`.
   - Transferências entre contas da empresa geram par de lançamentos atômico correlacionado (`OUTFLOW` na origem, `INFLOW` no destino).
2. **Cálculo Auditável de Saldo:**
   $$\text{Saldo}(\text{conta}) = \text{initial\_balance\_cents} + \sum \text{INFLOW} - \sum \text{OUTFLOW}$$
3. **Consistência de Títulos:**
   O saldo devedor de qualquer título de contas a receber ou a pagar é matematicamente validado contra a soma dos pagamentos amortizados:
   $$\text{balance\_cents} = \text{original\_amount\_cents} + \text{interest\_cents} - \text{discount\_cents} - \sum \text{payments.amount\_cents}$$

---

## 3. Mapa Geral de Fases Revisado

```
[FASE 1] Fundação Arquitetural, TLS, Pareamento, WAL & Esqueleto Flutter ----> [CONCLUÍDA & HOMOLOGADA]
[FASE 2] Produtos, Embalagens/Conversões e Receitas Imutáveis -----------------> [CONCLUÍDA & HOMOLOGADA]
[FASE 3] Livro-Razão Append-Only, Compras com Conversão e Ajustes ------------> [CONCLUÍDA & HOMOLOGADA]
═══════════════════════════════════════ PONTO DE CONTROLE ATUAL ════════════════════════════════════════
[FASE 4] Motor de Montagem e Produção de Cestas (Padrão, Personalizadas e CMPM) [AGUARDANDO AUTORIZAÇÃO]
[FASE 5] Vendas de Cestas, Saídas Físicas e Venda com Montagem Simultânea ------> [PLANEJADA]
[FASE 6] Expedição, Conferência de Saídas e Prestação de Contas de Agentes ----> [PLANEJADA]
[FASE 7] Gestão Financeira Completa (Clientes, Contas a Receber/Pagar, Caixa) -> [PLANEJADA]
[FASE 8] Fluxo de Caixa, DRE Gerencial, CMV Real, Margens e Relatórios --------> [PLANEJADA]
[FASE 9] Instalação Windows, Agendador de Tarefas e Entrega Final -------------> [PLANEJADA]
```
