# Instruções Mandatórias para Agentes de Desenvolvimento (AI / Pair Programming)
## ZM Cesta Básica — Sistema de Gestão de Estoque, Produção, Vendas e Financeiro

Este documento estabelece as **diretrizes e o protocolo operacional obrigatório** para qualquer agente de inteligência artificial ou desenvolvedor automatizado que venha a atuar neste projeto em sessões futuras.

---

## 1. Regra de Entrada e Ordem de Consulta de Documentos

No início de qualquer sessão de trabalho, o agente DEVE consultar as seguintes fontes na seguinte ordem de prioridade:

1. **[ARCHITECTURE.md](file:///c:/Users/jardi/Desktop/ZM%20CESTA%20B%C3%81SICA/ARCHITECTURE.md):** Fonte canônica da verdade sobre decisões arquiteturais, governança modular, princípios de engenharia permanentes, preparação de IA futura, simplificação da Fase 6, consistência de vendas/custódia e especificações de relatórios/impressão da Fase 8.
2. **[Especificacao_Sistema_Estoque_Cestas.md](file:///c:/Users/jardi/Desktop/ZM%20CESTA%20B%C3%81SICA/Especificacao_Sistema_Estoque_Cestas.md):** Especificação original aprovada do produto e regras de domínio da empresa.
3. **[backend/README.md](file:///c:/Users/jardi/Desktop/ZM%20CESTA%20B%C3%81SICA/backend/README.md) e [client/README.md](file:///c:/Users/jardi/Desktop/ZM%20CESTA%20B%C3%81SICA/client/README.md):** Estrutura física de diretórios, convenções de código e comandos de execução.

---

## 2. Protocolo de Pré-Implementação e Governança de Evolução Segura

Antes de produzir código ou aplicar qualquer alteração em arquivos existentes:

1. **Checagem de Saúde do Projeto:**
   - Execute a suíte de testes do backend com `& ".\backend\.venv\Scripts\python.exe" -m pytest backend/tests -q`. O projeto deve estar com **100% dos testes aprovados** (atualmente 167 testes).
   - Execute a suíte de testes do Flutter com `& "C:\dev\flutter\bin\flutter.bat" test` (atualmente 71 testes).
   - Verifique o status do Git com `git status` para garantir que o ambiente está consistente.
2. **Mapeamento de Impacto e Limites Modulares:**
   - Respeite rigorosamente a divisão modular: `estoque`, `produtos`, `receitas`, `compras`, `produção`, `vendas`, `expedição`, `financeiro`, `relatorios_e_impressao` e `core`.
   - **Isolamento de Persistência:** É estritamente proibido o acesso direto ao banco de dados SQLite por telas ou módulos não responsáveis pela persistência. Toda leitura ou mutação deve transitar exclusivamente através dos serviços de domínio e endpoints da API REST.
   - Novos recursos devem utilizar os serviços e interfaces existentes, sem contornar as validações centrais.
3. **Preservação de Comportamento e Contratos:**
   - **Proibição de remoção ou substituição silenciosa:** Nenhuma regra de negócio, validação, tabela ou endpoint pode ser alterado de maneira incompatível sem explicação de impacto e autorização explícita do usuário.
   - O livro-razão contábil (`inventory_movements`) e o livro-caixa (`cash_flow_entries`) são estritamente **append-only**. Nunca altere ou apague movimentações existentes.
4. **Tratamento Padronizado de Erros:**
   - A API backend deve emitir códigos de erro estáveis e estruturados (`INSUFFICIENT_STOCK`, `IDEMPOTENCY_PAYLOAD_MISMATCH`, etc.).
   - O cliente Flutter deve mapear esses códigos de erro para mensagens amigáveis em português por meio do `ApiErrorMapper`, sem expor stack traces ou termos técnicos ao operador.
5. **Migrações de Banco de Dados:**
   - Toda alteração estrutural no SQLite deve ser implementada via migração versionada do Alembic (`alembic revision -m "..."`).
   - Respeitar a cadeia sequencial de dependências das tabelas, preservando `PRAGMA foreign_keys = ON` sem dependências circulares.
6. **Validação Contínua (Não-Regressão):**
   - Ao concluir uma alteração, execute as suítes completas de testes. Todos os testes anteriores devem continuar passando, além dos novos testes criados para cobrir a funcionalidade adicionada.

---

## 3. Diretrizes de Backend (Python / FastAPI / SQLite)

- **Transações de Escrita:** Sempre utilizar `BEGIN IMMEDIATE` para mutações no banco de dados SQLite. Isso previne deadlocks e corridas de concorrência (*TOCTOU*), garantindo que saldos nunca fiquem negativos.
- **Idempotência:** Toda operação comercial (compras, montagens, vendas, saídas, acertos, ajustes, baixas) deve ser envolvida no `IdempotencyManager` com `X-Idempotency-Key` e hash SHA-256 do payload.
- **Valores Monetários e de Custo:**
  - Valores monetários comerciais são sempre números inteiros de **centavos** (`cents`), sem ponto flutuante (*float*).
  - O Custo Médio Ponderado Móvel (CMPM) unitário na unidade-base é mantido em escala fixa de **microcentavos** (`cost_price_microcents INTEGER`, onde 1 centavo = 10.000 microcentavos) com arredondamento bancário *half-even*, congelando o custo unitário da cesta pronta em centavos inteiros (`unit_cost_cents`).
- **Valores Temporais:** Todos os carimbos de data/hora gravados no banco devem estar em **UTC**.

---

## 4. Diretrizes de Front-End (Flutter / Dart)

- **Abordagem Mobile First com Responsividade Desktop:** As telas devem ser fluidas e usáveis em smartphones/tablets Android, bem como em telas amplas do Windows Desktop.
- **Componentes Compartilhados:** Reutilizar componentes padronizados em `client/lib/widgets/shared/` para formulários, botões, tabelas, cartões e diálogos. Evitar duplicar lógicas de exibição e máscaras entre telas.
- **Internacionalização e Formatação Centralizada:**
  - Todos os textos visíveis devem ser obtidos exclusivamente via `context.l10n`, utilizando o catálogo `client/lib/l10n/app_pt.arb` e código gerado por `flutter gen-l10n`. Proibido manter strings hardcoded nos widgets.
  - Formatações de moeda (`R$ X,XX`), datas e números com unidade de medida devem utilizar o utilitário centralizado `AppFormatters`.
- **Comunicação Segura com o Servidor:** Utilizar exclusivamente o `ApiClient`, que realiza validação de impressão digital SHA-256 do certificado TLS local e injeta tokens de autenticação de dispositivo.

---

## 5. Diretrizes da Simplificação da Fase 6 e Consistência Operacional

A Fase 6 atende à rotina real de uma pequena empresa de cestas básicas e rege a custódia temporária de mercadorias:

### 5.1. Vendas sob Custódia e Prevenção de Dupla Baixa de Estoque
- Toda venda de cesta colocada sob custódia de um responsável deve ser registrada **uma única vez** no serviço de vendas da Fase 5 (`sales`).
- **Baixa de Estoque Exclusiva de Trânsito:** A baixa de estoque dessa venda incide **exclusivamente sobre as unidades sob custódia (`TRANSIT`)**, e **NUNCA novamente sobre o estoque da loja (`STORE`)**.
- Vendas realizadas diretamente no balcão da loja (`DIRECT_STORE`) mantêm o comportamento homologado da Fase 5 (baixa de `STORE`).
- A venda mantém o vínculo com a saída (`dispatch_id`), o responsável (`responsible_person_id`), o cliente e o CMV congelado.
- **Proibição de Sistemas Paralelos:** Proibido criar outro subsistema de vendas, títulos ou clientes para a Fase 6.
- **Extensão Mínima de Arquitetura:** A Fase 6 adicionará `location_type` (`STORE` vs `TRANSIT`) e `responsible_person_id` em `inventory_movements`, ajustando `create_sale` para validar e baixar o saldo correto dependendo do `sale_mode`.

### 5.2. Conferência de Estoque e Equação de 4 Termos
- **Equação Canônica:**
  $$\text{Quantidade Retirada} = \text{Vendidas} + \text{Devolvidas Intactas} + \text{Avariadas ou Perdidas} + \text{Ainda sob Custódia / Não Localizadas}$$
- **Devolvidas Intactas:** Retornam formalmente ao estoque vendável do galpão (`STORE`) após conferência (`DISPATCH_RETURN`).
- **Avariadas ou Perdidas:** Baixadas de `TRANSIT` como perda operacional (`DISPATCH_LOSS`) com justificativa textual obrigatória, **sem retorno fictício ao estoque vendável**.
- **Itens Ainda sob Custódia / Não Conferidos:** Não são tratados como vendidos, devolvidos ou perdidos; permanecem sob a custódia pendente da pessoa responsável.
- **Divergências Não Resolvidas:** Registradas como pendências de investigação (`PENDING_INVESTIGATION`). É proibido forçar um fechamento artificialmente conciliado.
- **Auditoria do Fechamento:** O fechamento registra quem conferiu, quando ocorreu (timestamp UTC) e todos os valores apurados.

### 5.3. Acerto Financeiro e Segregação de Meios de Pagamento
- **Dinheiro Físico em Mãos:** Papel-moeda recebido na rota que deve ser entregue fisicamente ao caixa da empresa.
- **Pagamentos Recebidos Diretamente na Conta da Empresa:** Pix ou cartões creditados diretamente na conta da ZM já ingressaram no patrimônio da empresa e **NÃO devem ser cobrados em dinheiro físico do entregador**.
- **Cobranças de Fiados Antigos:** Amortizações de títulos da Fase 5 recolhidas pelo entregador com identificação do meio de pagamento.
- **Despesas Autorizadas Abatidas:** Gastos aceitos (combustível, pedágio) com valor, justificativa e autorização formal.
- **Divergências Financeiras:** Mantidas como `PENDING_INVESTIGATION`.
- **Prevenção de Duplicidades:** Faturamento bruto $\neq$ dinheiro físico a entregar. Não gerar lançamentos duplicados de caixa.

### 5.4. Preservação Estrita das Fases Concluídas (1 a 5)
- É expressamente proibido resolver divergências operacionais por exclusões (`DELETE`), alterações silenciosas (`UPDATE` sem rastreio) ou lançamentos fictícios. As correções ocorrem exclusivamente por lançamentos reversos rastreáveis.

---

## 6. Diretrizes do Módulo de Relatórios, Planilhas e Impressão (Fase 8)

1. **Modalidades de Saída:**
   - **Relatórios Preenchidos:** PDFs gerados automaticamente a partir dos dados do sistema com totais consolidados.
   - **Formulários em Branco:** Documentos A4 para escrita manual à caneta, com linhas altas e confortáveis (8 a 10 mm), colunas largas e checkboxes de conferência (sem tabelas comprimidas nem fontes minúsculas).
   - **Planilhas Digitais:** Arquivos CSV e XLSX para consulta e auditoria externa.
   - **Documentos PDF Paginados:** Papel comum A4, margens de 15 mm, paginação `Página X de Y` e cabeçalho padrão ZM.
2. **Os 4 Formulários Canônicos Obrigatórios (Preenchidos e em Branco):**
   - **Formulário A:** Vendas fiadas, pagamentos e quitação.
   - **Formulário B:** Contas a pagar.
   - **Formulário C:** Saídas e conferência diária.
   - **Formulário D:** Conferência física do estoque (balanço/inventário).
3. **Impressão Direta Multiplataforma (Flutter):**
   - Uso dos pacotes `pdf` e `printing`.
   - Geração de PDF vetorial em memória e envio ao spooler nativo do sistema operacional (Windows Print Spooler no desktop e Android Print Framework no mobile).
   - Pré-visualização com `PdfPreview` e botão de imprimir pelo próprio app, sem exigir Excel ou visualizadores externos.
   - **Compatibilidade Epson Wi-Fi:** Integração direta com drivers ESC/P-R do Windows e Mopria Print Service / Epson Print Enabler no Android. Proibido o uso de protocolos proprietários crus ou sockets diretos.
   - **Rota de Contingência:** Botões diretos para Salvar PDF no disco local e Compartilhar PDF caso a impressora física esteja inacessível.
4. **Padrão de Templates Reutilizáveis:**
   - `DocumentBuilder` com `ReportHeader`, `ReportFooter` e `ReportTableTheme` compartilhados entre todos os formulários.

---

## 7. Diretrizes para Futura Integração com IA (Preparação Arquitetural)

> [!IMPORTANT]
> **NÃO IMPLEMENTE IA NEM ADICIONE DEPENDÊNCIAS DE IA NESTE MOMENTO.**
> Esta seção rege o design para quando a funcionalidade for formalmente autorizada.

1. **Arquitetura Desacoplada (Provider Pattern):**
   - Adaptadores intercambiáveis (`GeminiProviderAdapter`, `OpenAIProviderAdapter`, `MockProvider`) sob interface `BaseAIProvider`.
2. **Custódia Segura de Chaves:**
   - Chaves de API mantidas exclusivamente nas variáveis de ambiente do backend. Proibido no cliente Flutter.
3. **Acesso Declarativo e Proibição de SQL Arbitrário:**
   - A IA **NUNCA** terá acesso a conexões diretas do SQLite nem permissão para rodar comandos SQL livres.
   - Acesso estrito por ferramentas declarativas autorizadas do backend (`get_stock_ruptures()`, `simulate_basket_production()`, etc.).
4. **Human-in-the-Loop Obrigatório:**
   - Toda proposta de alteração comercial/financeira deve ser retornada como `AIProposal` e exigir confirmação manual do operador humano.
5. **Operação Offline por Padrão:**
   - O sistema opera 100% autônomo offline em rede local sem IA. O recurso de IA é o único dependente de Internet quando acionado e pode ser desativado via `AI_ENABLED=false`.
6. **Trilha de Auditoria:**
   - Registro permanente em `ai_interaction_logs`.

---

## 8. Próxima Etapa do Projeto

O projeto concluiu e homologou as **Fases 1, 2, 3, 4 e 5** (139 testes backend ativos, 38 testes Flutter aprovados, compilações nativas Windows e Android validadas, internacionalização completa com `context.l10n`).

A próxima fase planejada é a **Fase 6: Saídas Físicas, Responsáveis por Cestas e Conferência Operacional (Simplificada)**:
- Cadastro simples de pessoas responsáveis por entregas (`responsible_persons`).
- Registro de saídas físicas de cestas do galpão (`stock_dispatches` e `dispatch_items`).
- Extensão mínima de `inventory_movements` com `location_type` e `responsible_person_id` para baixar cestas vendidas em rota de `TRANSIT`, sem duplo desconto em `STORE`.
- Conferência física de retorno (vendidas, devolvidas intactas ao armazém `STORE`, avariadas com justificativa `DISPATCH_LOSS` e itens pendentes sob custódia).
- Acerto financeiro segregado (dinheiro físico a repassar vs. pagamentos recebidos diretamente na conta da empresa) e fechamento auditável (`dispatch_settlements`).

**REGRA DE OURO:** Não inicie a implementação da Fase 6 sem a autorização prévia e expressa do usuário.
