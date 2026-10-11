# Arquitetura, Governança Técnica e Diretrizes Permanentes
## ZM Cesta Básica — Sistema de Gestão de Estoque, Produção e Vendas

**Documento Canônico de Engenharia e Princípios de Arquitetura**  
**Versão:** 1.0 (Consolidado após homologação da Fase 3)  
**Status do Projeto:** Fases 1, 2 e 3 Concluídas e Homologadas (101 testes automatizados)  
**Topologia:** Monólito Modular em Rede Local Privada (Wi-Fi/Ethernet) sem dependência de nuvem  
**Público-alvo:** Desenvolvedores, Engenheiros de Software e Agentes de Inteligência Artificial

---

## 1. Visão Geral e Princípios Fundamentais

Este documento estabelece as regras mandatórias de engenharia, governança arquitetural e boas práticas para todo o ciclo de vida do sistema **ZM Cesta Básica**. Qualquer desenvolvimento futuro — realizado por engenheiros humanos ou agentes de IA — deve obedecer estritamente a estas diretrizes.

### Os 6 Princípios Permanentes de Engenharia

### 1.1. Arquitetura Evolutiva (Monólito Modular)
O sistema é estruturado como um **Monólito Modular** de alta coesão e baixo acoplamento:
- **Separação Rígida de Responsabilidades:**
  - `estoque / inventory`: Livro-razão contábil *append-only*, cálculo dinâmico de saldos e ajustes de balanço.
  - `produtos / products`: Catálogo de insumos, unidades base e embalagens comerciais com fatores de conversão.
  - `receitas / recipes`: Tipos de cesta e versionamento imutável de composições padrão.
  - `compras / purchases`: Entrada de insumos de fornecedores, conversão de embalagens e estornos contábeis.
  - `montagem / production` (Fase 4): Ordens de montagem, consumo atômico de insumos e rastreabilidade de lotes personalizados.
  - `vendas / sales` (Fase 5): Vendas de balcão e encomendas, emissão de comprovantes e fluxo atômico de montagem simultânea.
  - `financeiro / financial` (Fase Futura): Vendas fiadas, contas a receber, contas a pagar, recebimentos, repasses e fluxo de caixa.
  - `conferencia / dispatch` (Fase Futura): Auditoria de expedição e conferência de saídas físicas de mercadorias.
  - `relatorios / reports` (Fase 6): Indicadores gerenciais, CMV, margens e exportações em planilhas.
  - `configuracoes & infraestrutura`: Segurança TLS, autenticação de dispositivos, backups quentes e rotinas de manutenção.
- **Proibição de Dependências Circulares:** Os módulos comunicam-se através de serviços e contratos bem definidos. Módulos de domínio superior (vendas, montagem) dependem de módulos de domínio base (estoque, produtos), nunca o inverso.
- **Centralização de Regras de Negócio:** Nenhuma regra de estoque, cálculo financeiro ou conversão de unidades pode residir no cliente Flutter ou em triggers isolados sem espelhamento no serviço de domínio. A API FastAPI é a autoridade única sobre o estado da aplicação.
- **Isolamento de Impacto:** Modificações internas em um módulo (ex.: adicionar um campo informativo em compras) não devem exigir alterações generalizadas nos demais módulos.

---

### 1.2. Evolução Segura e Preservação de Comportamento
Toda modificação no sistema deve seguir o protocolo de evolução segura:
1. **Inspeção Prévia Obrigatória:** Antes de editar código, deve-se inspecionar os arquivos afetados, compreender os contratos existentes e identificar todos os pontos de consumo.
2. **Avaliação de Impacto e Não-Regressão:** Toda proposta de alteração deve preservar as funcionalidades já aprovadas e homologadas. A suíte completa de testes automatizados (`pytest backend/tests -v`) deve ser executada antes e depois de qualquer intervenção, mantendo 100% de aprovação.
3. **Proibição de Exclusão ou Substituição Silenciosa:** Nenhuma regra comercial, endpoint, tabela ou coluna pode ser removida silenciosamente. Qualquer quebra de compatibilidade ou descontinuação requer justificativa técnica explícita e autorização expressa do responsável pelo projeto.
4. **Evolução do Banco via Migrações Versionadas:**
   - O schema do banco de dados SQLite evolui exclusivamente através do **Alembic**.
   - Scripts de migração devem ser reversíveis (`upgrade()` e `downgrade()`) e compatíveis com a preservação de dados históricos existentes.
   - Proibido executar `DROP TABLE` ou apagar dados produtivos.
5. **Rastreabilidade e Não-Destrutividade Contábil:**
   - O livro-razão de estoque (`inventory_movements`) é estritamente *append-only*.
   - Cancelamentos de compras, vendas ou montagens são operados via **lançamento de contrapartida contábil reversa** (estorno), preservando o histórico da transação original com status cancelado.

---

### 1.3. Front-End Adaptativo e Componentização Centralizada
O aplicativo cliente desenvolvido em **Flutter** deve atender aos seguintes critérios:
- **Mobile First com Adaptação Desktop:**
  - A experiência principal de operação ágil na fábrica ou galpão é focada em smartphones/tablets Android via Wi-Fi.
  - Em telas maiores (Windows Desktop), a interface deve se adaptar naturalmente utilizando layouts fluidos, *split views*, painéis laterais e atalhos de teclado, sem desperdiçar espaço nem exigir dois códigos distintos.
- **Design System Centralizado:**
  - Cores, tipografia, espaçamentos, bordas e sombras padronizados através de `ThemeData` central.
  - Uso de componentes de UI compartilhados e reutilizáveis localizados em diretório comum (`client/lib/widgets/` ou `client/lib/core/ui/`):
    - `AppTextField` / `AppMoneyField`: Campos de formulário com formatação e validação visual de erro.
    - `AppButton`: Botões de ação primária, secundária e perigosa com suporte nativo a estado de carregamento (*spinner* integrado).
    - `AppCard`: Cartões informativos e recipientes de dados estruturados.
    - `AppTable` / `AppListTile`: Visualização consistente de dados tabulares e listas.
    - `FeedbackSnackbar` / `ErrorDialog`: Tratamento amigável e consistente de respostas da API e erros de rede.
    - `AppLoadingIndicator`: Indicador padrão de requisições assíncronas.
- **Módulos de Interface Independentes:** As telas de cada módulo operacional (`views/`) consom seus respectivos serviços (`services/`) e modelos (`models/`), desacopladas entre si e compartilhando apenas o núcleo de rede, autenticação e componentes visuais.

---

### 1.4. Internacionalização (i18n) e Localização Centralizada
Embora a interface seja atualmente em **português brasileiro (pt-BR)**, a arquitetura deve estar desacoplada de textos *hardcoded*:
- **Estratégia Centralizada de Strings:**
  - Textos de telas, rótulos, botões, mensagens de erro e diálogos devem ser obtidos a partir de um repositório centralizado de localização (ex.: classe `AppStrings` ou biblioteca de localização do Flutter), preparando o sistema para múltiplos idiomas sem necessidade de refatorar telas no futuro.
- **Formatação Numérica e Monetária Centralizada:**
  - Toda moeda é manipulada internamente na API e no banco como **número inteiro de centavos** (`cents`), eliminando erros de arredondamento de ponto flutuante.
  - No cliente, a formatação para o usuário final deve utilizar função centralizada (ex.: `CurrencyFormatter.format(cents) -> "R$ 1.250,50"` baseada em `intl`).
- **Formatação de Datas:**
  - Todas as datas trafegadas na API e armazenadas no SQLite utilizam **UTC** em formato ISO-8601 (`YYYY-MM-DDTHH:MM:SSZ`).
  - No cliente, a exibição deve converter para o fuso local do dispositivo usando formatador centralizado (ex.: `DateFormatter.formatDateTime(dt) -> "11/10/2026 14:30"`).

---

### 1.5. Testes Contínuos, Qualidade e Governança
- **Pirâmide de Testes Automatizados:**
  - Testes Unitários de Schemas e Validadores: validação estrita de entradas, whitespace trimming, normalização.
  - Testes de Serviços e Regras de Negócio: cálculo de estoques, conversões de embalagem, versionamento de receitas.
  - Testes de Concorrência e Transação: validação de `BEGIN IMMEDIATE` sob multithreading, prevenção de saldo negativo e tolerância a lock.
  - Testes de Idempotência: prevenção de duplicação por chave repetida e bloqueio em payloads divergentes.
  - Testes de Integração de API (Rotas FastAPI): verificação de status HTTP, serialização de resposta e autenticação de dispositivo.
- **Critério de Aceitação Contínuo:** Nenhum commit ou avanço de fase é autorizado se qualquer teste automatizado existente falhar. A suíte deve permanecer com **100% de aprovação verde**.

---

### 1.6. Backlog de Negócio Futuro Mapeado (Novos Requisitos)
Para manter o alinhamento de longo prazo sem iniciar a implementação prematura, os seguintes módulos de negócio estão formalmente mapeados para as fases posteriores:

1. **Vendas Fiadas e Gestão de Clientes a Prazo:**
   - Cadastro detalhado de clientes comerciais e pessoas físicas (Nome/Razão Social, CPF/CNPJ, Telefone, Endereço de Entrega, Limite de Crédito e Status de Adimplência).
   - Venda na modalidade a prazo (`SALE_ON_CREDIT` / Fiado): gera a baixa de estoque normalmente, mas registra o valor pendente no financeiro em vez de entrada em caixa imediata.
   - Histórico de compras por cliente e saldo devedor acumulado.
2. **Contas a Receber (Títulos e Cobrança):**
   - Geração de títulos a receber vinculados à venda, com datas de vencimento acordadas.
   - Baixa de recebimentos parciais ou integrais com registro da data, valor pago, meio de pagamento (dinheiro, PIX, transferência) e saldo remanescente.
   - Relatório de títulos vencidos, a vencer e clientes inadimplentes.
3. **Conferência de Saídas e Expedição:**
   - Fluxo de separação e conferência física de mercadorias (*checklist* de expedição) antes da saída para entrega.
   - Validação da composição física da cesta contra a receita do lote ou pedido do cliente.
   - Registro de responsável pela conferência e horário de saída do veículo.
4. **Recebimentos e Repasses:**
   - Prestação de contas de entregadores/motoristas que recebem pagamentos na entrega (dinheiro ou comprovante PIX).
   - Fechamento de rota e repasse financeiro diário com conciliação do montante recebido contra os pedidos entregues.
5. **Contas a Pagar a Fornecedores:**
   - Registro de obrigações financeiras originadas de compras a prazo registradas no sistema.
   - Controle de parcelas, datas de vencimento e quitação de duplicatas de fornecedores.
6. **Fluxo de Caixa e DRE Gerencial:**
   - Livro-caixa com movimentações de entradas reais (vendas à vista + recebimentos de fiados) e saídas reais (pagamento de compras, despesas operacionais).
   - Demonstração do resultado operacional com apuração do Custo da Mercadoria Vendida (CMV real baseado nas movimentações contábeis de saída) e margem de contribuição.
7. **Dashboards Financeiros e Gerenciais:**
   - Indicadores visuais na tela inicial (para usuários autorizados): Faturamento do dia/mês, Valor do estoque a preço de custo, Contas a receber vencendo hoje, Total fiado em aberto e Top cestas mais vendidas.

---

## 2. Mapa Geral de Fases e Estado do Projeto

```
[FASE 1] Fundação Arquitetural, TLS, Pareamento, WAL & Esqueleto Flutter ----> [CONCLUÍDA & HOMOLOGADA]
[FASE 2] Produtos, Embalagens/Conversões e Receitas Imutáveis -----------------> [CONCLUÍDA & HOMOLOGADA]
[FASE 3] Livro-Razão Append-Only, Compras com Conversão e Ajustes ------------> [CONCLUÍDA & HOMOLOGADA]
======================================= PONTO DE CONTROLE ATUAL ========================================
[FASE 4] Motor de Montagem e Produção de Cestas (Padrão e Personalizadas) ----> [AGUARDANDO AUTORIZAÇÃO]
[FASE 5] Vendas, Baixa de Cestas e Venda com Montagem Simultânea -------------> [PLANEJADA]
[FASE 6] Relatórios Gerenciais, CMV, Margens e Exportações --------------------> [PLANEJADA]
[FASE 7] Instalação Windows, Agendador de Tarefas e Entrega ------------------> [PLANEJADA]
[FASE 8+] Módulos Financeiros Avançados, Contas a Receber/Pagar & Expedição -> [BACKLOG FORMALIZADO]
```

---

## 3. Guia de Orientação para Agentes de IA nas Próximas Sessões

Ao iniciar qualquer nova sessão de trabalho neste projeto, o agente de IA **DEVE**:
1. Ler este arquivo (`ARCHITECTURE.md`) e o arquivo [`Especificacao_Sistema_Estoque_Cestas.md`](file:///c:/Users/jardi/Desktop/ZM%20CESTA%20B%C3%81SICA/Especificacao_Sistema_Estoque_Cestas.md).
2. Executar a suíte de testes com `& ".\backend\.venv\Scripts\python.exe" -m pytest backend/tests -v` para confirmar que o ponto de partida está 100% verde (101 testes passando).
3. Verificar o status do Git com `git status` para certificar-se de que a árvore de trabalho está limpa antes de iniciar qualquer modificação.
4. **Nunca avançar de fase ou implementar código de fases futuras sem a autorização prévia e explícita do usuário.**
5. Tratar toda operação de escrita como atômica sob `BEGIN IMMEDIATE`, garantir proteção de idempotência em mutações e manter o livro-razão estritamente *append-only*.
