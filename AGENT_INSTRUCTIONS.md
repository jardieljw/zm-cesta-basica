# Instruções Mandatórias para Agentes de Desenvolvimento (AI / Pair Programming)
## ZM Cesta Básica — Sistema de Gestão de Estoque e Produção

Este documento estabelece as **diretrizes e o protocolo operacional obrigatório** para qualquer agente de inteligência artificial ou desenvolvedor automatizado que venha a atuar neste projeto em sessões futuras.

---

## 1. Regra de Entrada e Ordem de Consulta de Documentos

No início de qualquer sessão de trabalho, o agente DEVE consultar as seguintes fontes na seguinte ordem de prioridade:

1. **[ARCHITECTURE.md](file:///c:/Users/jardi/Desktop/ZM%20CESTA%20B%C3%81SICA/ARCHITECTURE.md):** Fonte canônica da verdade sobre decisões arquiteturais, princípios de engenharia permanentes, backlog futuro de negócios (financeiro, fiado, conferência) e mapa de fases.
2. **[Especificacao_Sistema_Estoque_Cestas.md](file:///c:/Users/jardi/Desktop/ZM%20CESTA%20B%C3%81SICA/Especificacao_Sistema_Estoque_Cestas.md):** Especificação original aprovada do produto e regras de domínio da empresa.
3. **[backend/README.md](file:///c:/Users/jardi/Desktop/ZM%20CESTA%20B%C3%81SICA/backend/README.md) e [client/README.md](file:///c:/Users/jardi/Desktop/ZM%20CESTA%20B%C3%81SICA/client/README.md):** Estrutura física de diretórios, convenções de código e comandos de execução.

---

## 2. Protocolo de Pré-Implementação e Evolução Segura

Antes de produzir código ou aplicar qualquer alteração em arquivos existentes:

1. **Checagem de Saúde do Projeto:**
   - Execute a suíte de testes com `& ".\backend\.venv\Scripts\python.exe" -m pytest backend/tests -v`. O projeto deve estar com **100% dos testes aprovados** antes do início de qualquer tarefa.
   - Verifique o status do Git com `git status` para garantir que o ambiente está limpo.
2. **Mapeamento de Impacto:**
   - Identifique os arquivos e módulos afetados pela alteração solicitada.
   - Analise se a mudança toca em regras de outros módulos já homologados.
3. **Preservação de Comportamento:**
   - **Proibição de remoção ou substituição silenciosa:** Nenhuma regra de negócio, validação, tabela ou endpoint pode ser alterado de maneira incompatível sem explicação de impacto e autorização explícita do usuário.
   - O livro-razão contábil (`inventory_movements`) é estritamente **append-only**. Nunca altere ou apague movimentações existentes.
4. **Validação Contínua (Não-Regressão):**
   - Ao concluir uma alteração, execute a suíte completa de testes. Todos os 101 testes anteriores devem continuar passando, além dos novos testes criados para cobrir a funcionalidade adicionada.

---

## 3. Diretrizes de Backend (Python / FastAPI / SQLite)

- **Transações de Escrita:** Sempre utilizar `BEGIN IMMEDIATE` para mutações no banco de dados SQLite. Isso previne deadlocks e corridas de concorrência (*TOCTOU*), garantindo que saldos nunca fiquem negativos.
- **Idempotência:** Toda operação comercial (compras, montagens, vendas, ajustes) deve ser envolvida no `IdempotencyManager` com `X-Idempotency-Key` e hash SHA-256 do payload.
- **Migrações:** Toda alteração no banco de dados deve ser gerada e versionada via **Alembic** (`alembic revision -m "..."`). Proibido alterar o schema manualmente sem migração.
- **Valores Monetários:** Sempre trafegar e armazenar valores monetários como números inteiros de **centavos** (`cents`), sem uso de ponto flutuante (*float*).
- **Valores Temporais:** Todos os carimbos de data/hora gravados no banco devem estar em **UTC**.

---

## 4. Diretrizes de Front-End (Flutter / Dart)

- **Abordagem Mobile First com Responsividade Desktop:** As telas devem ser fluidas e usáveis em smartphones/tablets Android, bem como em telas amplas do Windows Desktop.
- **Componentes Compartilhados:** Reutilizar componentes padronizados para formulários, botões, tabelas, cartões e diálogos. Evitar duplicar lógicas de exibição e máscaras entre telas.
- **Localização e i18n Centralizado:** Não fixar textos literais espalhados no código quando for possível obter de ponto centralizado. Utilizar utilitários centralizados para formatar moedas (`CurrencyFormatter`) e datas (`DateFormatter`).
- **Comunicação Segura com o Servidor:** Utilizar exclusivamente o `ApiClient`, que realiza validação de impressão digital SHA-256 do certificado TLS local e injeta tokens de autenticação de dispositivo.

---

## 5. Próxima Etapa do Projeto

O projeto concluiu e homologou as **Fases 1, 2 e 3** (101 testes automatizados).

A próxima fase planejada é a **Fase 4: Motor de Montagem e Produção de Cestas (Padrão e Personalizadas)**:
- Consumo atômico de insumos (`ASSEMBLY_CONSUME`) e entrada de cestas acabadas (`ASSEMBLY_PRODUCE`).
- Rastreamento unívoco de lotes de cestas personalizadas via `production_batch_id`.
- Desmontagem e estorno de cestas condicionados a saldo em estoque.
- Telas de ordens de montagem e produção no cliente Flutter.

**REGRA DE OURO:** Não inicie a implementação da Fase 4 sem a autorização prévia e expressa do usuário.
