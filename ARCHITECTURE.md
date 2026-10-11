# Arquitetura, Governança Técnica e Diretrizes Permanentes
## ZM Cesta Básica — Sistema de Gestão de Estoque, Produção e Vendas

**Documento Canônico de Engenharia e Princípios de Arquitetura**  
**Versão:** 3.0 (Definitiva Pré-Fase 4: Dependências Estritas de Schema, CMPM em Microcentavos e Políticas de Negócio)  
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
  - `produtos / products`: Catálogo de insumos, unidades base, CMPM em escala fixa e embalagens comerciais com fatores de conversão.
  - `receitas / recipes`: Tipos de cesta e versionamento imutável de composições padrão.
  - `compras / purchases`: Entrada de insumos de fornecedores, conversão de embalagens, atualização de CMPM e estornos contábeis.
  - `montagem / production` (Fase 4): Ordens de montagem, consumo de insumos valorizados pelo CMPM, lote padrão vs. personalizado, apuração do custo unitário do lote e desmontagem com triagem de perdas.
  - `vendas / sales` (Fase 5): Vendas de balcão e rotas, baixa de produto acabado, cadastro base de clientes (`customers`), congelamento do CMV e montagem simultânea.
  - `expedicao / dispatch` (Fase 6): Cargas de saída, agentes comerciais (`commercial_agents`) sem login, conferência física de retorno e conciliação de repasses item a item.
  - `financeiro / financial` (Fase 7): Títulos a receber de fiados, contas a pagar (empresariais vs. retiradas pessoais), tesouraria e livro-caixa imutável.
  - `relatorios / reports` (Fase 8): DRE Gerencial com CMV real do livro-razão, margens brutas, fluxo de caixa e exportações em planilhas.
  - `infraestrutura`: Segurança TLS, autenticação de dispositivos, backups quentes e rotinas de manutenção.
- **Proibição de Dependências Circulares:** Módulos de domínio superior consomem serviços de módulos base, nunca o inverso.
- **Centralização de Regras de Negócio:** Nenhuma regra de estoque, cálculo financeiro ou conversão de unidades reside no cliente Flutter. A API FastAPI é a autoridade única sobre o estado da aplicação.

---

### 1.2. Evolução Segura e Preservação de Comportamento
1. **Inspeção Prévia Obrigatória:** Antes de editar código, inspecionar arquivos afetados e identificar todos os pontos de consumo.
2. **Avaliação de Impacto e Não-Regressão:** Executar a suíte completa de testes automatizados (`pytest backend/tests -v`), mantendo 100% de aprovação verde (atualmente 101 testes).
3. **Proibição de Exclusão ou Substituição Silenciosa:** Proibido remover ou alterar endpoints, schemas ou regras homologadas sem autorização explícita.
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
- **Valores Monetários em Centavos:** Todo valor monetário final transacionado é um **número inteiro em centavos** (`cents`), formatado na tela pelo pacote `intl` (`R$ X,XX`).
- **Datas em UTC:** Timestamps trafegados e armazenados em UTC ISO-8601 e formatados no fuso local no cliente.

---

### 1.5. Testes Contínuos e Qualidade
A suíte de testes deve permanecer 100% verde a cada commit, combinando testes unitários, de concorrência com `BEGIN IMMEDIATE`, de idempotência e de integração com a API.

---

## 2. Diretrizes Técnicas Aprofundadas e Decisões Canônicas

### 2.1. Precisão do Custo Médio Ponderado Móvel (CMPM) em Escala Fixa (Microcentavos)
Para produtos cuja unidade-base seja fracionária (gramas `G`, mililitros `ML`), o custo unitário por unidade-base pode ser uma fração de centavo (ex.: 1kg de arroz a R$ 5,50 $\rightarrow$ 1 grama custa R$ 0,0055 = 0,55 centavos). Armazenar centavos inteiros por grama geraria distorções severas de até 100% no custo das cestas.

#### Representação Numérica Exata:
- O CMPM unitário da unidade-base de estoque é representado como um **inteiro de escala fixa em microcentavos** (`cost_price_microcents INTEGER`):
  $$1 \text{ Real} = 100 \text{ centavos} = 1.000.000 \text{ microcentavos}$$
  $$1 \text{ centavo} = 10.000 \text{ microcentavos}$$
- Essa escala fixa de $10^{-4}$ centavos ($10^{-6}$ do Real) garante precisão absoluta sem imprecisões de ponto flutuante (*float*).

#### Fórmulas de Cálculo e Conversão:
1. **Entrada de Compra (`purchases`):**
   Ao comprar quantidade $Q_{\text{compra}}$ na unidade base por um custo total de $T_{\text{cents}}$ centavos:
   $$CustoUnitCompra_{\text{microcents}} = \text{round}\left(\frac{T_{\text{cents}} \times 10.000}{Q_{\text{compra}}}\right)$$
   $$CMPM_{\text{novo}} = \text{round}\left(\frac{(Estoque_{\text{atual}} \times CMPM_{\text{antigo}}) + (Q_{\text{compra}} \times CustoUnitCompra_{\text{microcents}})}{Estoque_{\text{atual}} + Q_{\text{compra}}}\right)$$
2. **Consumo na Montagem de Cestas (`production_batches`):**
   Ao consumir $Q_i$ unidades-base do insumo $i$ na produção de um lote de $N_{\text{cestas}}$ cestas:
   $$CustoInsumo_{\text{cents}} = \text{round}\left(\frac{Q_i \times CMPM_{i\_microcents}}{10.000}\right)$$
   $$CustoUnitCesta_{\text{cents}} = \text{round}\left(\frac{\sum CustoInsumos_{\text{cents}} + CustoEmbalagem_{\text{cents}}}{N_{\text{cestas}}}\right)$$
3. **Arredondamento:** Todas as divisões utilizam arredondamento bancário padronizado (*half-even* / `Decimal.quantize(..., rounding=ROUND_HALF_EVEN)`).
4. **Consistência do CMV:** O custo unitário da cesta pronta é congelado em centavos inteiros (`unit_cost_cents`) nas tabelas `production_batches` e `sale_items`, assegurando congruência de 100% entre os valores monetários cobrados, os custos baixados e a DRE.

---

### 2.2. Custódia de Cestas e Sub-localizações de Estoque
Para diferenciar o estoque disponível no estabelecimento das cestas sob responsabilidade de intermediários:
1. **Localização Contábil (`location_type`):**
   - `STORE`: Estoque físico presente no armazém/loja física.
   - `TRANSIT`: Cestas expedidas sob custódia física de um intermediário (`commercial_agent_id`).
2. **Ciclo Contábil da Expedição:**
   - **Saída para Rota (`DISPATCH_TRANSFER`):**
     - Linha 1: `location_type = 'STORE'`, `quantity_delta = -N` (baixa do armazém da loja).
     - Linha 2: `location_type = 'TRANSIT'`, `commercial_agent_id = :agent_id`, `quantity_delta = +N` (entrada na custódia do agente).
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

### 2.3. Conciliação e Repasses com Detalhamento Item a Item
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

### 2.4. Contas a Pagar e Prevenção de Duplicidades Financeiras
1. **Fato Gerador vs. Liquidação Financeira:**
   - Compras de estoque a prazo (`payment_condition = 'CREDIT_TERM'`) geram títulos em `accounts_payable` com status `OPEN`. Elas **NÃO** geram lançamento imediato no livro-caixa (`cash_flow_entries`).
   - Compras à vista (`payment_condition = 'CASH_IMMEDIATE'`) geram o título e a liquidação atômica associada debitando a conta financeira da empresa em `cash_flow_entries`.
2. **Parcelamento:** Títulos de fornecedores suportam parcelas com vencimentos e valores independentes.
3. **Classificação entre Despesas Empresariais e Pessoais:**
   - `nature = 'BUSINESS'`: Despesas operacionais do negócio (insumos, energia, aluguel, manutenção, frete). Computadas na DRE Operacional.
   - `nature = 'PERSONAL_WITHDRAWAL'`: Retiradas particulares, pró-labore ou despesas pessoais dos sócios. Deduzem saldo das contas financeiras da empresa, mas são **excluídas da apuração de lucro operacional da DRE**.

---

### 2.5. Políticas de Negócio Padrão Consolidadas
Ficam estabelecidas como diretrizes canônicas do sistema as seguintes 4 regras:

1. **Divergências de Repasse de Intermediários:**
   Toda divergência apurada em prestação de contas permanece inicialmente com status `PENDING_INVESTIGATION`. Somente após deliberação explícita do gestor a divergência poderá ser convertida e registrada como:
   - `AGENT_DEBT` (dívida do intermediário a abater no acerto futuro); ou
   - `OPERATIONAL_LOSS` (perda/quebra operacional aprovada da empresa).
2. **Juros e Multas por Atraso (Fiado):**
   Ficam **desativados inicialmente**. O sistema cobra estritamente os valores nominais negociados. A estrutura de dados mantém os campos preparados para futura ativação parametrizada de taxas de juros/multa.
3. **Limites de Crédito para Vendas Fiadas:**
   O limite de crédito gera um **alerta informativo** na interface no momento da venda, permitindo **liberação manual autorizada pelo operador** (não gera bloqueio automático rígido). O valor `credit_limit_cents = 0` significa **ausência de limite configurado** (cliente sem teto pré-estipulado), e não bloqueio imediato.
4. **Desmontagem Parcial de Cestas:**
   A ordem de desmontagem opera com **conferência item a item por produto**. Ingredientes íntegros retornam ao estoque do armazém (`STORE`). Ingredientes violados, avariados ou inutilizáveis são lançados como perda contábil (`ASSEMBLY_LOSS`) com registro de despesa, **sendo estritamente proibido o retorno fictício de itens avariados ao estoque**.

---

## 3. Ordem Estrita de Criação de Tabelas e Dependências entre Fases

Para garantir integridade referencial absoluta (`foreign_keys = ON`) e eliminar retrabalho em migrações:

| Fase | Tabelas Criadas / Modificadas | Dependências e Justificativa de Sequenciamento |
| :--- | :--- | :--- |
| **Fase 4** *(Montagem)* | Índices de produção e colunas de custo em `production_batches` e `production_batch_items` | Depende apenas das Fases 2 e 3 (já existentes). Não cria clientes nem agentes. |
| **Fase 5** *(Vendas)* | Criação de **`customers`** e expansão de `sales` (`customer_id REFERENCES customers(id)`, `sale_mode`, `payment_mode`) | **`customers` nasce na Fase 5** para que a venda possa referenciá-la imediatamente. O ciclo financeiro de cobrança fica para a Fase 7. |
| **Fase 6** *(Expedição)* | Criação de **`commercial_agents`**, **`dispatch_orders`**, **`dispatch_items`**, **`responsible_settlements`**, **`settlement_allocations`**; adição em `sales` de `dispatch_order_id` e `agent_id` | Vínculos de vendas com expedição e agentes **só são adicionados nesta fase**, quando as entidades de expedição passam a existir. |
| **Fase 7** *(Financeiro)* | Criação de **`financial_accounts`**, **`accounts_receivable`**, **`receivable_payments`**, **`accounts_payable`**, **`payable_payments`**, **`cash_flow_entries`** | Cria a tesouraria, títulos de fiado vinculados a `customers` e `sales`, e títulos a pagar vinculados a `purchases`. |
| **Fase 8** *(Relatórios)* | Views e queries analíticas de DRE Gerencial, CMV Real e Fluxo de Caixa | Não adiciona DDL de transação; consome dados consolidados de todas as fases anteriores. |
| **Fase 9** *(Entrega)* | Scripts de automação do Windows e instaladores | Finalização de entrega e empacotamento. |

---

## 4. Mapa Geral de Fases do Projeto

```
[FASE 1] Fundação Arquitetural, TLS, Pareamento, WAL & Esqueleto Flutter ----> [CONCLUÍDA & HOMOLOGADA]
[FASE 2] Produtos, Embalagens/Conversões e Receitas Imutáveis -----------------> [CONCLUÍDA & HOMOLOGADA]
[FASE 3] Livro-Razão Append-Only, Compras com Conversão e Ajustes ------------> [CONCLUÍDA & HOMOLOGADA]
═══════════════════════════════════════ PONTO DE CONTROLE ATUAL ════════════════════════════════════════
[FASE 4] Motor de Montagem e Produção de Cestas (Padrão, Personalizadas e CMPM) [AGUARDANDO AUTORIZAÇÃO]
[FASE 5] Vendas de Cestas, Cadastro de Clientes e Venda com Montagem Simultânea [PLANEJADA]
[FASE 6] Expedição, Agentes Comerciais e Prestação de Contas Detalhada --------> [PLANEJADA]
[FASE 7] Gestão Financeira Completa (Contas a Receber/Pagar, Caixa e Tesouraria) [PLANEJADA]
[FASE 8] Fluxo de Caixa, DRE Gerencial, CMV Real, Margens e Relatórios --------> [PLANEJADA]
[FASE 9] Instalação Windows, Agendador de Tarefas e Entrega Final -------------> [PLANEJADA]
```
