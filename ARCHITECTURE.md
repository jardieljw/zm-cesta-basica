# Arquitetura, Governança Técnica e Diretrizes Permanentes
## ZM Cesta Básica — Sistema de Gestão de Estoque, Produção, Vendas e Financeiro

**Documento Canônico de Engenharia e Princípios de Arquitetura**  
**Versão:** 5.3 (Fases 6 e 7 Homologadas: Expedição, Custódia, Contas a Pagar, Contas a Receber e Tesouraria)
**Status do Projeto:** Fases 1 a 7 Concluídas e Homologadas (167 testes backend e 71 testes Flutter aprovados; análise estática 100% limpa)
**Topologia:** Monólito Modular em Rede Local Privada (Wi-Fi/Ethernet) sem dependência de nuvem  
**Público-alvo:** Desenvolvedores, Engenheiros de Software e Agentes de Inteligência Artificial

---

## 1. Visão Geral e Princípios Fundamentais

Este documento estabelece as regras mandatórias de engenharia, governança arquitetural e boas práticas para todo o ciclo de vida do sistema **ZM Cesta Básica**. Qualquer desenvolvimento futuro — realizado por engenheiros humanos ou agentes de IA — deve obedecer estritamente a estas diretrizes.

### Os 6 Princípios Permanentes de Engenharia

### 1.1. Arquitetura Evolutiva (Monólito Modular)
O sistema é estruturado como um **Monólito Modular** de alta coesão e baixo acoplamento:
- **Separação Rígida de Responsabilidades:**
  - `estoque / inventory`: Livro-razão contábil *append-only*, sub-localizações de custódia (armazém da loja `STORE` vs. responsabilidade externa em trânsito `TRANSIT`), cálculo dinâmico de saldos e ajustes manuais de balanço com justificativa auditável.
  - `produtos / products`: Catálogo de insumos, unidades base, CMPM em escala fixa (microcentavos) e embalagens comerciais com fatores de conversão estritos.
  - `receitas / recipes`: Tipos de cesta e versionamento imutável de composições padrão.
  - `compras / purchases`: Entrada de insumos de fornecedores, conversão automática de embalagens, atualização do CMPM e estornos contábeis condicionados a saldo.
  - `montagem / production` (Fase 4 - Homologada): Ordens de montagem, consumo atômico de insumos valorizados pelo CMPM, rastreamento de lote padrão vs. personalizado com snapshot imutável, apuração do custo unitário do lote e desmontagem com triagem física de intactos (`STORE`) e perdas (`ASSEMBLY_LOSS`).
  - `vendas / sales` (Fase 5 - Homologada): Vendas de balcão e rotas, baixa atômica de produto acabado, cadastro de clientes (`customers`), contas a receber com parcelamento e quitações parciais (`sales_receivables`), congelamento do CMV e montagem simultânea sob demanda sem duplo consumo.
  - `expedicao / dispatch` (Fase 6 - Próxima / Simplificada): Registro simples de saídas físicas de cestas, vinculação à pessoa responsável (sem login/sem complexidade de frota ou roteirização), conferência física de retorno (vendidas, devolvidas intactas ao armazém, avariadas com perda e itens ainda sob custódia) e acerto financeiro segregado (dinheiro físico a repassar vs. pagamentos recebidos diretamente na conta da empresa via Pix/cartão).
  - `financeiro / financial` (Fase 7): Gestão financeira completa, tesouraria, contas financeiras da empresa (`financial_accounts`), contas a pagar de fornecedores e despesas (`accounts_payable`), distinção entre despesas empresariais e retiradas pessoais dos sócios, e livro-caixa imutável (`cash_flow_entries`).
  - `relatorios_e_impressao / reports` (Fase 8): DRE Gerencial com CMV real do razão, margens brutas, fluxo de caixa, exportação de planilhas digitais (CSV e XLSX), relatórios preenchidos automaticamente em PDF, formulários em branco A4 com espaçamento para escrita manual à caneta, e módulo de impressão direta multiplataforma no Flutter (Windows Spooler e Android Print Spooler com compatibilidade para Epson Wi-Fi e rota de contingência para salvar/compartilhar PDF).
  - `infraestrutura / core`: Segurança TLS local, certificado autoassinado com fingerprint SHA-256, pareamento por PIN de 6 dígitos, tokens Bearer com hash SHA-256 no SQLite, transações atômicas sob `BEGIN IMMEDIATE`, durabilidade `PRAGMA synchronous = FULL`, `PRAGMA journal_mode = WAL`, `IdempotencyManager` e rotinas de backup quente.
- **Proibição de Dependências Circulares:** Módulos de domínio superior consomem serviços de módulos base, nunca o inverso.
- **Centralização de Regras de Negócio e Persistência:** Nenhuma regra de estoque, cálculo financeiro ou conversão de unidades reside no cliente Flutter. A API FastAPI é a autoridade única sobre o estado da aplicação.
- **Isolamento de Persistência:** É estritamente proibido o acesso direto ao banco SQLite por telas Flutter ou módulos não responsáveis pela persistência. Toda mutação ou consulta deve transitar exclusivamente através dos serviços de domínio e endpoints da API REST protegidos.

---

### 1.2. Evolução Segura e Preservação de Comportamento
1. **Inspeção Prévia Obrigatória:** Antes de editar código, inspecionar arquivos afetados e identificar todos os pontos de consumo.
2. **Avaliação de Impacto e Não-Regressão:** Executar a suíte completa de testes automatizados (`pytest backend/tests -v` e `flutter test`), mantendo 100% de aprovação verde (atualmente 139 testes de backend e 38 testes de front-end aprovados).
3. **Proibição de Exclusão ou Substituição Silenciosa:** Proibido remover ou alterar endpoints, schemas ou regras homologadas sem autorização explícita do usuário.
4. **Evolução do Banco via Migrações Versionadas:** Schema gerenciado exclusivamente pelo Alembic com suporte bidirecional a `upgrade()` e `downgrade()`.
5. **Rastreabilidade Contábil Imutável:** O livro-razão `inventory_movements` e o livro-caixa `cash_flow_entries` são estritamente *append-only* (protegidos por triggers nativos contra `UPDATE` e `DELETE`). Correções ocorrem exclusivamente por lançamentos reversos rastreáveis (estornos).

---

### 1.3. Front-End Adaptativo e Componentização Centralizada
- **Mobile First com Adaptação Desktop:** Experiência prioritária em Android (toque no galpão/rotas) e fluida no Windows Desktop (telas amplas, tabelas densas e atalhos de teclado).
- **Componentes Compartilhados:** Reutilização em `client/lib/widgets/shared/` de campos monetários, botões com spinner integrado, cartões padronizados e tabelas responsivas.
- **Gerenciamento de Estado:** `StatefulWidget` com serviços assíncronos desacoplados por tela e `ValueNotifier` para estados globais de aplicação.

---

### 1.4. Internacionalização (i18n) e Formatação Centralizada
- **Padrão Canônico do Flutter (`gen_l10n`):** Configurado via `l10n.yaml`, cataloga todas as mensagens em `client/lib/l10n/app_pt.arb` e gera as classes tipadas `AppLocalizations` e `AppLocalizationsPt`.
- **Zero Strings Hardcoded nos Widgets:** Todo texto visível na interface do usuário (títulos, botões, formulários, alertas, filtros, badges e mensagens de erro) deve ser consultado via `context.l10n`.
- **Formatadores Centralizados (`AppFormatters`):** Toda formatação de moeda (`R$ X,XX`), datas (`dd/MM/yyyy HH:mm`), números e quantidades físicas com unidades de medida deve utilizar `client/lib/utils/formatters.dart`.
- **Tratamento Amigável de Erros (`ApiErrorMapper`):** Códigos de erro estáveis do backend (`INSUFFICIENT_STOCK`, `IDEMPOTENCY_PAYLOAD_MISMATCH`, etc.) são traduzidos em mensagens amigáveis em português em `client/lib/utils/api_error_mapper.dart`.
- **Extensibilidade Futura:** A inclusão de novos idiomas (como inglês `en`) no futuro exige apenas a criação de `app_en.arb`, sem necessitar de alterações manuais nos widgets de interface.

---

### 1.5. Testes Contínuos e Qualidade
A suíte de testes deve permanecer 100% verde a cada commit, combinando:
- Testes unitários de serviços e schemas.
- Testes de concorrência com `BEGIN IMMEDIATE` e `busy_timeout`.
- Testes de idempotência via `X-Idempotency-Key`.
- Testes de integridade contábil do razão *append-only*.
- Testes de widgets, formatadores e internacionalização no Flutter.

---

## 2. Diretrizes Técnicas e Decisões Canônicas de Negócio

### 2.1. Precisão do Custo Médio Ponderado Móvel (CMPM) em Escala Fixa (Microcentavos)
Para produtos cuja unidade-base seja fracionária (gramas `G`, mililitros `ML`), o custo unitário por unidade-base pode ser uma fração de centavo (ex.: 1kg de arroz a R$ 5,50 $\rightarrow$ 1 grama custa R$ 0,0055 = 0,55 centavos).
- **Representação Numérica Exata:**
  O CMPM unitário da unidade-base de estoque é representado como um **inteiro de escala fixa em microcentavos** (`cost_price_microcents INTEGER`):
  $$1 \text{ Real} = 100 \text{ centavos} = 1.000.000 \text{ microcentavos}$$
  $$1 \text{ centavo} = 10.000 \text{ microcentavos}$$
- **Fórmulas de Cálculo:**
  1. Entrada de Compra (`purchases`):
     $$CustoUnitCompra_{\text{microcents}} = \text{round}\left(\frac{T_{\text{cents}} \times 10.000}{Q_{\text{compra}}}\right)$$
     $$CMPM_{\text{novo}} = \text{round}\left(\frac{(Estoque_{\text{atual}} \times CMPM_{\text{antigo}}) + (Q_{\text{compra}} \times CustoUnitCompra_{\text{microcents}})}{Estoque_{\text{atual}} + Q_{\text{compra}}}\right)$$
  2. Consumo na Produção (`production_batches`):
     $$CustoInsumo_{\text{cents}} = \text{round}\left(\frac{Q_i \times CMPM_{i\_microcents}}{10.000}\right)$$
     $$CustoUnitCesta_{\text{cents}} = \text{round}\left(\frac{\sum CustoInsumos_{\text{cents}} + CustoEmbalagem_{\text{cents}}}{N_{\text{cestas}}}\right)$$
- **Congelamento do Custo Unitário:** O custo unitário da cesta pronta é congelado de forma imutável em centavos inteiros (`unit_cost_cents`) nas tabelas `production_batches` e `sale_items`, assegurando congruência de 100% entre o estoque, os valores cobrados e o CMV na DRE.

---

### 2.2. Saídas Físicas, Custódia e Integração com o Domínio de Vendas (Prevenção de Dupla Baixa)
A rotina operacional de uma pequena empresa de cestas básicas envolve a saída física de mercadorias sob responsabilidade temporária de colaboradores ou entregadores:
1. **Pessoas Responsáveis (`responsible_persons`):** Cadastro simples de quem retira as cestas (nome, telefone, status ativo; sem contas de login ou credenciais criptográficas).
2. **Registro de Saída Física (`stock_dispatches` e `dispatch_items`):**
   - Registra data, horário, pessoa responsável e quantidade por tipo de cesta.
   - O armazém da loja registra a saída temporária (`DISPATCH_TRANSFER`), reduzindo o saldo disponível no galpão (`STORE`) e transferindo a custódia contábil para a pessoa responsável (`TRANSIT`).
3. **Consumo Direto do Domínio de Vendas da Fase 5 (Sem Duplicações):**
   - Toda venda realizada a partir de cestas que estão sob custódia de um responsável deve ser registrada **uma única vez**, utilizando o endpoint e serviço oficial de vendas da Fase 5 (`POST /api/v1/sales`).
   - **Regra Mandatória de Baixa de Estoque:** A baixa de estoque dessa venda deve incidir **exclusivamente sobre as unidades sob custódia (`TRANSIT`)** daquele responsável, e **NUNCA novamente sobre o estoque da loja (`STORE`)**.
   - As vendas realizadas diretamente no balcão da loja (`sale_mode = 'DIRECT_STORE'`) continuam mantendo o comportamento homologado da Fase 5, baixando o estoque físico da loja (`STORE`).
   - A venda mantém o vínculo com seu registro original (`sales`), com o responsável (`responsible_person_id`), com a saída física correspondente (`dispatch_id`), com o cliente cadastrado (ou consumidor final) e com o CMV unitário congelado na venda.
   - **Proibição de Sistemas Paralelos:** É terminantemente proibido criar um segundo mecanismo de vendas, outro cadastro de clientes ou um subsistema paralelo de contas a receber para a Fase 6. Toda operação comercial deve transitar pelo modelo único consolidado na Fase 5.

> [!NOTE]
> **Diagnóstico de Incompatibilidade Técnica Atual e Extensão Mínima Necessária:**
> - *Situação Atual (Fases 1 a 5):* A tabela `inventory_movements` possui chaves para `product_id`, `basket_type_id` e `production_batch_id`, mas não possui as colunas `location_type` (`STORE` vs `TRANSIT`) nem `responsible_person_id`. O método `get_basket_stock()` soma todos os deltas cegamente e `create_sale()` dá baixa assumindo o estoque geral da loja.
> - *Extensão Mínima na Fase 6:* Na migração da Fase 6, adicionar a coluna `location_type` (com valor padrão `'STORE'` para dados existentes e suporte a `'TRANSIT'`) e `responsible_person_id` (nulo para movimentos da loja) em `inventory_movements`. Ajustar `create_sale` para que, quando `sale_mode == 'COMMERCIAL_ROUTE'` e `responsible_person_id` estiver presente, a validação de saldo e o registro do delta negativo de venda (`SALE`) ocorram em `location_type = 'TRANSIT'` sob o responsável, impedindo qualquer desconto duplo no armazém da loja.

---

### 2.3. Conferência de Estoque, Equação de 4 Termos e Tratamento de Divergências
No retorno da pessoa responsável ao término do dia ou da rota, o sistema realiza o fechamento operacional:
1. **Equação Canônica Completa de Conferência de Cestas:**
   Contempla rigorosamente todas as possibilidades físicas, incluindo itens ainda não acertados ou pendentes:
   $$\text{Quantidade Retirada} = \text{Vendidas} + \text{Devolvidas Intactas} + \text{Avariadas ou Perdidas} + \text{Ainda sob Custódia / Não Localizadas}$$
2. **Diretrizes Estritas de Movimentação Contábil:**
   - **Devolvidas Intactas:** Cestas perfeitas que retornaram ao armazém retornam formalmente ao estoque vendável da loja (`STORE`) através de uma movimentação reversa de trânsito (`DISPATCH_RETURN`: $\Delta = -R$ em `TRANSIT`, $\Delta = +R$ em `STORE`).
   - **Avariadas ou Danificadas:** Itens avariados **NÃO podem voltar automaticamente ao estoque vendável**. Devem ser baixados de `TRANSIT` como perda contábil (`DISPATCH_LOSS`: $\Delta = -A$ em `TRANSIT`) com justificativa textual obrigatória, impedindo qualquer retorno fictício ao estoque disponível.
   - **Ainda sob Custódia / Não Conferidos:** Cestas que permaneceram com o responsável para o dia seguinte ou que ainda não foram conferidas **NÃO são tratadas automaticamente como vendidas, devolvidas ou perdidas**. Permanecem formalmente como saldo sob custódia (`TRANSIT`) até conferência efetiva.
   - **Divergências Não Resolvidas:** Diferenças entre o total retirado e a soma dos itens justificados permanecem registradas com status `PENDING_INVESTIGATION`. **É expressamente proibido forçar um fechamento artificialmente conciliado com saldo zerado.**
   - **Rastreabilidade do Fechamento:** O acerto registra quem conferiu (auditor/operador), carimbo de data/hora UTC e todas as quantidades e valores apurados.

---

### 2.4. Acerto Financeiro, Segregação de Meios de Pagamento e Prevenção de Duplicidades
Para evitar qualquer confusão entre faturamento total da rota e o dinheiro físico que deve entrar no cofre da empresa:
1. **Segregação Obrigatória dos Meios de Pagamento:**
   - **Dinheiro Físico em Mãos:** Papel-moeda recebido pelo responsável proveniente de vendas à vista na rota ou de cobranças de fiados. Este montante físico **deve ser conferido e entregue em mãos à empresa**.
   - **Pagamentos Recebidos Diretamente na Conta da Empresa:**
     - Quando o cliente da rota realiza o pagamento via Pix utilizando a chave CNPJ/QR Code da empresa ou passa cartão em maquininha da loja, o dinheiro entra diretamente na conta bancária da ZM.
     - **Regra Fundamental de Conciliação:** Esse valor já ingressou no patrimônio da empresa e **NÃO deve ser cobrado em dinheiro físico do entregador**. O sistema reconhece a liquidação da venda/recebível, mas não adiciona esse valor ao montante em espécie esperado da prestação de contas do responsável.
   - **Pagamentos Recebidos pelo Responsável:** Pagamentos que transitaram por conta/maquininha do próprio entregador devem ser repassados integralmente à empresa.
   - **Cobranças de Vendas Fiadas Anteriores:** Quando o entregador recolhe parcelas de títulos antigos (`sales_receivables` gerados na Fase 5), o acerto registra a amortização formal no título e discrimina se o valor foi pago em dinheiro em mãos ou via Pix direto na conta da empresa.
   - **Despesas Autorizadas Abatidas:** Gastos de viagem autorizados (ex.: combustível, pedágio) que podem ser abatidos do repasse em dinheiro, contendo valor em centavos, justificativa textual e comprovante/autorização formal.
2. **Equação Canônica do Repasse em Dinheiro Físico:**
   $$\text{Dinheiro Físico a Entregar} = \text{Vendas à Vista em Dinheiro} + \text{Cobranças de Fiado em Dinheiro} - \text{Despesas de Viagem Autorizadas}$$
3. **Divergências de Caixa:**
   Diferenças entre o dinheiro físico esperado e o dinheiro entregue permanecem como pendências financeiras (`PENDING_INVESTIGATION`), sem mascaramento contábil.
4. **Prevenção de Duplicidades Financeiras:**
   A conciliação da Fase 6 conecta vendas da Fase 5 e amortizações de fiado sem gerar lançamentos duplicados no livro-caixa da tesouraria da Fase 7.

---

### 2.5. Contas a Pagar e Prevenção de Duplicidades Financeiras (Fase 7)
1. **Fato Gerador vs. Liquidação Financeira:**
   - Compras de estoque a prazo geram títulos em `accounts_payable` com status `OPEN`, sem movimentar caixa de imediato (`cash_flow_entries`).
   - Compras à vista geram o título e a liquidação atômica associada debitando a conta financeira da empresa em `cash_flow_entries`.
2. **Classificação entre Despesas Empresariais e Pessoais:**
   - `nature = 'BUSINESS'`: Despesas operacionais do negócio (insumos, energia, aluguel, manutenção, frete). Computadas na DRE Operacional.
   - `nature = 'PERSONAL_WITHDRAWAL'`: Retiradas particulares, pró-labore ou despesas pessoais dos sócios. Deduzem saldo das contas financeiras da empresa, mas são **excluídas da apuração de lucro operacional da DRE**.

---

### 2.6. Módulo de Relatórios, Planilhas Digitais, Formulários A4 e Impressão Direta (Fase 8)

Para apoiar a gestão diária, o arquivamento formal e a rotina manual de prancheta e caneta no galpão, a Fase 8 fornecerá um motor completo de relatórios e impressão com 4 modalidades de saída:

```
                               ┌────────────────────────────────────────────────────────┐
                               │       Backend FastAPI & Banco de Dados SQLite          │
                               │  (Consultas Otimizadas, Agregações, CSV/XLSX Exporters)│
                               └───────────────────────────┬────────────────────────────┘
                                                           │ JSON / CSV / XLSX
                                                           ▼
                               ┌────────────────────────────────────────────────────────┐
                               │           Cliente Flutter (Desktop e Mobile)           │
                               │    Módulo de Relatórios & Gerador de Documentos A4     │
                               └─────────────┬────────────────────────────┬─────────────┘
                                             │                            │
                 ┌───────────────────────────┴──────────┐                 │
                 ▼                                      ▼                 ▼
   ┌───────────────────────────┐          ┌───────────────────────────┐ ┌──────────────────────┐
   │ Relatórios Preenchidos A4 │          │ Formulários em Branco A4  │ │ Planilhas Digitais   │
   │ (Dados Reais do Sistema)  │          │ (Para Escrita Manual)     │ │ (Exportação CSV/XLSX)│
   └─────────────┬─────────────┘          └─────────────┬─────────────┘ └──────────────────────┘
                 │                                      │
                 └───────────────────┬──────────────────┘
                                     │
                                     ▼
                        ┌───────────────────────────┐
                        │   Motor de Impressão      │
                        │   (pdf + printing)        │
                        └─────────────┬─────────────┘
                                      │
               ┌──────────────────────┴──────────────────────┐
               ▼                                             ▼
  ┌─────────────────────────────┐               ┌─────────────────────────────┐
  │ Windows Print Spooler       │               │ Android Print Spooler       │
  │ (Impressoras do Windows,    │               │ (Android Print Framework,   │
  │  USB, Rede, Epson Wi-Fi)    │               │  Mopria, Epson Print)       │
  └─────────────────────────────┘               └─────────────────────────────┘
               │                                             │
               └──────────────────────┬──────────────────────┘
                                      ▼
                        ┌───────────────────────────┐
                        │   Rota de Contingência    │
                        │   (Salvar / Exportar PDF) │
                        └───────────────────────────┘
```

#### 2.6.1. As 4 Modalidades de Saída de Dados
1. **Relatórios Preenchidos Automaticamente:** Gerados em PDF paginado a partir dos dados reais gravados no sistema, com filtros por data, período, cliente ou responsável, incluindo totais consolidados e indicadores operacionais.
2. **Formulários em Branco Próprios para Impressão e Preenchimento Manual à Caneta:** Modelos formatados especificamente para uso em prancheta no armazém ou na rua. Possuem linhas amplas com altura confortável para escrita à mão (mínimo de 8 a 10 mm por linha), cabeçalho legível, colunas largas para valores e observações, e caixas de seleção (*checkboxes*) para vistos e conferência. **É proibido o uso de tabelas supercomprimidas ou fontes minúsculas.**
3. **Planilhas Digitais (CSV e XLSX):** Arquivos tabulares estruturados para exportação, permitindo aos gestores abrir os dados em Excel, LibreOffice ou Google Planilhas para auditorias externas ou análises contábeis customizadas.
4. **Documentos PDF Paginados para Papel Comum A4:** Layouts profissionais com margens seguras (mínimo de 15 mm para evitar cortes em qualquer impressora jato de tinta ou laser), cabeçalho padronizado da empresa, numeração clara de páginas (`Página X de Y`) e carimbo de data/hora de emissão.

---

#### 2.6.2. Os 4 Formulários Canônicos Obrigatórios (Preenchidos e em Branco)

##### Formulário A: Vendas Fiadas, Pagamentos e Quitação
- **Campos Obrigatórios:** Data da venda; Identificação do cliente ou venda; Tipo de cesta; Quantidade; Valor total; Data prevista para pagamento (vencimento); Data efetiva do pagamento; Valor recebido e saldo restante; Campo formal de confirmação de quitação (visto/assinatura); Observações.

##### Formulário B: Contas a Pagar
- **Campos Obrigatórios:** Descrição da obrigação; Beneficiário ou fornecedor; Categoria da despesa; Valor nominal; Data de vencimento; Data efetiva de pagamento; Valor pago e saldo restante (parcial); Forma de pagamento; Campo de confirmação de quitação; Observações/NF.

##### Formulário C: Saídas Físicas e Conferência Diária
- **Campos Obrigatórios:** Data e horário; Pessoa responsável; Tipo e quantidade de cestas retiradas; Preço/valor correspondente; Identificação de personalizações; Conferência de retorno (vendidas, devolvidas intactas, avariadas, sob custódia e total em dinheiro recolhido); Campos para conferência de ambas as partes (assinaturas) e observações.

##### Formulário D: Conferência Física do Estoque (Auditoria / Balanço)
- **Campos Obrigatórios:** Nome do produto, insumo ou cesta; Unidade de medida; Saldo registrado no sistema; Quantidade física contada; Diferença apurada (sobra/falta); Observações e justificativa obrigatória do ajuste; Assinatura do responsável e data.

---

#### 2.6.3. Arquitetura de Impressão Direta no Aplicativo Flutter
1. **Geração Nativa de PDF no Cliente:** Uso de `pdf` e `printing`, montando o documento em memória sem depender de visualizadores externos.
2. **Integração com Spoolers Nativos:** Windows Print Spooler no desktop e Android Print Framework no mobile.
3. **Pré-visualização no App (`PdfPreview`):** Exibição em tela com opção direta de impressão e configuração de cópias.
4. **Compatibilidade Epson Wi-Fi:** Integração direta através dos drivers padrão ESC/P-R do Windows e Mopria Print Service / Epson Print Enabler no Android. Proibido o uso de protocolos proprietários crus ou sockets de baixo nível.
5. **Rota de Contingência:** Botões destacados para **Salvar PDF Localmente** e **Compartilhar PDF**, garantindo continuidade mesmo com impressora offline.

---

#### 2.6.4. Padrão de Templates Reutilizáveis (`DocumentBuilder` / `ReportTemplate`)
Centralização de layout visual em `ReportHeaderWidget`, `ReportFooterWidget` e `ReportTableTheme`. Todas as strings localizadas em `client/lib/l10n/app_pt.arb`.

---

### 2.7. Preservação Estrita das Fases Concluídas (1 a 5)
- O livro-razão contábil `inventory_movements` é estritamente *append-only*.
- O histórico de vendas, clientes e contas a receber da Fase 5 é inviolável.
- **É expressamente vedado resolver qualquer divergência operacional por meio de exclusões físicas (`DELETE`), alterações silenciosas (`UPDATE` sem rastreio) ou lançamentos fictícios.** Toda correção deve ocorrer por lançamentos reversos rastreáveis e justificativas auditáveis.

---

## 3. Diretrizes de Governança de Evolução Segura

### 3.1. Como Adicionar Novas Funcionalidades
Pipeline de desenvolvimento: Modelos SQLAlchemy $\rightarrow$ Migração Alembic $\rightarrow$ Schemas Pydantic $\rightarrow$ Serviços de Domínio sob `BEGIN IMMEDIATE` $\rightarrow$ Endpoints REST com `IdempotencyManager` $\rightarrow$ Testes de regressão $\rightarrow$ Interface Flutter com `context.l10n` e `ApiErrorMapper`.

### 3.2. Tratamento de Erros e Resiliência
Códigos de erro padronizados (`INSUFFICIENT_STOCK`, `IDEMPOTENCY_PAYLOAD_MISMATCH`, etc.) mapeados para mensagens amigáveis em português no Flutter via `ApiErrorMapper`.

---

## 4. Arquitetura para Futura Integração com Inteligência Artificial (Opcional)

Nenhum código de IA adicionado neste momento. Arquitetura desacoplada via Provider Pattern (`BaseAIProvider`, `GeminiProviderAdapter`, `OpenAIProviderAdapter`), chaves de API mantidas exclusivamente no backend, proibição de comandos SQL arbitrários, *Human-in-the-Loop* mandatório (`AIProposal`), operação 100% offline por padrão e feature flag `AI_ENABLED=false`.

---

## 5. Sequência Canônica de Dependências de Tabelas e Fases (Fases 5 a 9)

```
[FASE 5: Vendas, Clientes & Fiado Base] ----------------------> [CONCLUÍDA & HOMOLOGADA]
  ├── Cria tabela `customers`
  ├── Modifica `sales` (customer_id FK, payment_mode, sale_mode)
  └── Cria tabela base `sales_receivables` e `receivable_payments` (Saldo devedor e amortizações)
        │
        ▼
[FASE 6: Saídas Físicas, Responsáveis & Conferência] ----------> [AGUARDANDO AUTORIZAÇÃO]
  ├── Cria `responsible_persons` (Cadastro simples de colaboradores/entregadores)
  ├── Cria `stock_dispatches` e `dispatch_items` (Saída física STORE -> TRANSIT)
  ├── Estende `inventory_movements` (location_type e responsible_person_id)
  ├── Modifica `sales` (dispatch_id e responsible_person_id opcionais para vendas em rota)
  └── Cria `dispatch_settlements` (Conferência de 4 termos e acerto financeiro segregado)
        │
        ▼
[FASE 7: Gestão Financeira Completa & Tesouraria] ------------> [PLANEJADA]
  ├── Cria contas financeiras `financial_accounts` (Caixa da Loja, Bancos)
  ├── Cria contas a pagar `accounts_payable` e `payable_payments` (Compras e Despesas)
  ├── Cria livro-caixa imutável `cash_flow_entries` (Append-Only)
  └── Integra recebimentos da Fase 5 e repasses da Fase 6 à tesouraria da empresa
        │
        ▼
[FASE 8: Relatórios, Planilhas, Formulários A4 & Impressão] --> [PLANEJADA]
  ├── Consultas consolidadas de DRE Gerencial, Margens e Fluxo de Caixa
  ├── Exportadores para Planilhas Digitais (CSV e XLSX)
  ├── Gerador de Formulários Paginados A4 (Preenchidos e em Branco para Preenchimento Manual)
  └── Módulo de Impressão Direta Flutter (Spoolers Windows e Android, Epson Wi-Fi e Contingência PDF)
        │
        ▼
[FASE 9: Instalação Windows, Agendador & Validação de Impressão] [PLANEJADA]
  ├── Instalador local do Windows e configuração do serviço automático
  ├── Rotinas de backup agendado
  └── Validação em Hardware Real (Impressão física em Windows e Android com Epson Wi-Fi)
```

---

## 6. Mapa Geral de Fases Atualizado

```
[FASE 1] Fundação Arquitetural, TLS, Pareamento, WAL & Esqueleto Flutter ----> [CONCLUÍDA & HOMOLOGADA]
[FASE 2] Produtos, Embalagens/Conversões e Receitas Imutáveis -----------------> [CONCLUÍDA & HOMOLOGADA]
[FASE 3] Livro-Razão Append-Only, Compras com Conversão e Ajustes ------------> [CONCLUÍDA & HOMOLOGADA]
[FASE 4] Motor de Montagem e Produção (Lotes Padrão/Custom, CMPM Microcentavos,
         Triagem de Desmontagem, i18n Flutter e Compilações Nativas) --------> [CONCLUÍDA & HOMOLOGADA]
[FASE 5] Vendas de Cestas, Cadastro de Clientes, Vendas a Prazo e Montagem
         Simultânea (139 testes backend, 38 testes Flutter) ------------------> [CONCLUÍDA & HOMOLOGADA]
═══════════════════════════════════════ PONTO DE CONTROLE ATUAL ════════════════════════════════════════
[FASE 6] Saídas Físicas, Responsáveis por Cestas e Conferência Operacional ---> [AGUARDANDO AUTORIZAÇÃO]
[FASE 7] Gestão Financeira Completa (Contas a Pagar, Tesouraria e Caixa) ------> [PLANEJADA]
[FASE 8] Relatórios Gerenciais, DRE, Planilhas (CSV/XLSX), Formulários A4
         e Módulo de Impressão Direta (Multiplataforma / Epson Wi-Fi) ---------> [PLANEJADA]
[FASE 9] Instalação Windows, Agendador, Validação de Impressão e Entrega -----> [PLANEJADA]
```
