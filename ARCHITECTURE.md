# Arquitetura, Governança Técnica e Diretrizes Permanentes

**17/10/2026 — Receber revisado:** o [guia](docs/PILOTO_RECEBER_REVISADO.md)
registra o segundo percurso incremental, com contrato aditivo e preservação de
venda/estoque. Máquina de apresentação e motor de recuperação compartilhados,
com métodos/identificadores separados. Lista Receber usa recorte compacto e
paginação. Não altera tabelas, instalação ou organização global nesta entrega.
## ZM Cesta Básica — Sistema de Gestão de Estoque, Produção, Vendas e Financeiro

**Documento Canônico de Engenharia e Princípios de Arquitetura**  

Para entender o comportamento atual de cada fluxo, consulte o
[índice das mecânicas](docs/README.md). Os guias relacionam interface, serviços,
endpoints, tabelas, exemplos e limitações; este documento define a governança técnica.
**Versão:** 6.0 (Fases 1 a 9 Concluídas e Homologadas: Gestão Completa, Relatórios, Impressão, Backup Quente, Instalação Windows e Entrega de Produção)
**Status do Projeto:** Fases 1 a 9 Concluídas e Homologadas (compilações nativas Windows x64 e Android release APK geradas; análise estática 100% limpa)
**Topologia:** Monólito Modular em Rede Local Privada (Wi-Fi/Ethernet) sem dependência de nuvem  
**Público-alvo:** Desenvolvedores, Engenheiros de Software e Agentes de Inteligência Artificial

**16/10/2026 — piloto de pagamento revisado:** o
[guia do incremento](docs/PILOTO_PAGAR_REVISADO.md) registra o fluxo real de Pagar,
com corpo/chave persistidos, retomada, precondição aditiva do saldo na transação e
dia civil representado em UTC. Hashes legados e regras do livro-caixa preservados;
sem migração nova. Tema/navegação globais e Receber não foram migrados nesse recorte.


> **Escopo atual do cliente — 13/10/2026:** as telas de produção em lote,
> desmontagem, expedição/conferência, responsáveis e tesouraria estão arquivadas.
> As descrições dessas fases abaixo são referência histórica e de domínio.
> O backend e os dados históricos são preservados para os fluxos compartilhados.
> Consulte [client/_archive/README.md](client/_archive/README.md) antes de restaurar
> funções. Não reintroduzir menus, relatórios ou serviços exclusivos arquivados
> sem solicitação do usuário. Montagem na venda segue ativa; pagamentos não exigem seleção de contas.

> **Dashboard e financeiro simplificados:** o aplicativo usa `dashboard/business-summary`
> e `reports/business-financial-summary`, com vendas, compras, estoque, confirmações,
> pendências, custo vendido e resultado gerencial. Não exibir saldos de caixa/contas,
> depósitos manuais ou projeção de tesouraria. As confirmações preservam a auditoria
> interna; contas financeiras não são selecionadas pelo operador. Consultar
> [client/_archive/DASHBOARD.md](client/_archive/DASHBOARD.md) antes de evoluir esses fluxos.

> **Catálogo — exclusão autorizada de cadastros nunca utilizados (14/10/2026):**
> Regra original de 14/10, substituída pelo ciclo de catálogo de 20/10: produtos sem vínculos em receitas (qualquer versão), compras (qualquer status),
> itens de produção e movimentações podem ser excluídos definitivamente por uma
> ação explícita com confirmação e revalidação transacional. Embalagens nunca
> utilizadas podem ser removidas junto com o cadastro. Produtos com vínculos ou
> histórico continuam protegidos; a inativação mantém suas regras. Ver
> [docs/PRODUTOS_E_FORMAS_DE_COMPRA.md](docs/PRODUTOS_E_FORMAS_DE_COMPRA.md).

**20/10/2026 — ciclo de catálogo:** vendas não canceladas e operações/saldos ainda
válidos protegem receitas, tipos e ingredientes. Operações canceladas/desfeitas
não impedem permanentemente retirar o cadastro do catálogo. `removed_at` de
produtos, status `REMOVED` de receitas e a retirada já existente dos tipos
preservam referências históricas; cadastros nunca usados podem ser apagados.
Preço sugerido por receita e `sale_recipe_references` são aditivos pela migração
`f28f901a1048`. A referência congelada não inventa atribuição de lote onde o
estoque padrão era agregado. Ver os guias de receitas e montagens.

---

## 1. Visão Geral e Princípios Fundamentais

**Base de extratos/faturas — 15/10/2026:** primeiro incremento exclusivamente no
backend, documentado em [base financeira e conciliação](docs/BASE_FINANCEIRA_E_CONCILIACAO.md).
As tabelas novas preservam documentos e ocorrências conferidas separadamente do
livro-caixa. Conciliação vincula evidência a movimentos existentes; não cria
pagamentos ou dívidas. As migrações `fa0d1e2f4310`, `fb1e2f3a5411` e `fc2f3a4b6512` foram
preparadas para essa base; não criar suas tabelas no startup por `create_all`.
Há [leitores CSV multibanco e prévias versionadas](docs/IMPORTACAO_CSV_MULTIBANCO.md)
no backend. Em 16/10 foi acrescentado [PDF automático por adaptadores](docs/IMPORTACAO_PDF_FINANCEIRO.md),
com layouts Nubank/PicPay e prévia bloqueada quando houver erro. OCR, senha,
outros layouts, OFX, OAuth Gmail, integração contábil de faturas e front-end
continuam etapas posteriores. PDF reutiliza o relatório imutável de prévias;
não acrescenta migração ou efeitos ao livro-caixa.
As [correções de revisão](docs/CORRECAO_REVISAO_FINANCEIRA.md) acrescentam decisões
imutáveis e mudanças de associação dos identificadores; consultas operacionais
usam a decisão atual. Não reescrever as ocorrências ou os eventos originais.
Para retomar, consultar a [memória financeira](docs/MEMORIA_IMPLEMENTACAO_FINANCEIRA.md)
e a [homologação com originais](docs/HOMOLOGACAO_IMPORTACAO_FINANCEIRA.md).

A [arquitetura semântica de faturas](docs/ARQUITETURA_SEMANTICA_DE_FATURAS.md)
registra decisões, fontes e a evolução planejada de procedência/conferência.
READY da prévia comprova leitura, não cobertura entre formatos. Divergências
reais CSV/PDF foram verificadas; não criar obrigações ou ajustes para fechar
essas diferenças. A [conferência e procedência](docs/CONFERENCIA_E_PROCEDENCIA_DE_FATURAS.md)
foi implementada no backend, com três tabelas aditivas pela migração fd3 e
pareceres imutáveis na prévia; vínculo com statement é opcional e histórico.
VERIFIED desta camada compara transcrições e não autoriza obrigação. A base
original foi observada em fc2; fd3 foi validada somente em cópia. Integração
com títulos e liquidação continua futura.

> **Novo banco — 14/10/2026:** a criação explicitamente confirmada pelo operador
> gera backup obrigatório verificado, prepara um banco vazio com Alembic e o ativa
> no caminho central existente. Preserva pareamentos e comprovantes de manutenção,
> aguarda requisições em andamento e impede repetição da operação. Não usar esse
> fluxo como correção de histórico. Consultar
> [docs/NOVO_BANCO_DE_DADOS.md](docs/NOVO_BANCO_DE_DADOS.md).

> **Configurações por plataforma — 14/10/2026:** a edição de URL, fingerprint e
> token nas configurações é destinada ao computador. No Windows, salvar a conexão
> pode autenticar o terminal no servidor local via `pairing/local-master`, somente
> com HTTPS e endereço de loopback. Outros servidores usam token existente ou PIN.
> O Android mantém o pareamento por QR code ou preenchimento manual na tela de
> pareamento. A autenticação é confirmada por endpoint protegido, não apenas pela
> presença de um token salvo. Consulte
> [docs/CONFIGURACAO_E_AUTENTICACAO.md](docs/CONFIGURACAO_E_AUTENTICACAO.md).

Este documento estabelece as regras mandatórias de engenharia, governança arquitetural e boas práticas para todo o ciclo de vida do sistema **ZM Cesta Básica**. Qualquer desenvolvimento futuro — realizado por engenheiros humanos ou agentes de IA — deve obedecer estritamente a estas diretrizes.

### Os 6 Princípios Permanentes de Engenharia

### 1.1. Arquitetura Evolutiva (Monólito Modular)

**Integração autorizada — 14/10/2026:** o catálogo de tipos de cesta passa a
oferecer registro de montagem padrão e histórico por tipo. As páginas novas
reutilizam `production` e `inventory`, sem restaurar telas originais ou criar
livro de estoque paralelo. A revisão informa a versão da receita; a confirmação
revalida essa versão e os produtos. Reenvios incertos mantêm payload e chave
localmente para retomada segura. Não há migração de tabelas nesta integração.
Ver [Montagens e histórico](docs/MONTAGENS_E_HISTORICO.md).

**Personalização de montagem — 14/10/2026:** Registrar montagem pode copiar a
receita ativa para uma composição local, sem alterar o cadastro. Reutilizar
`AssemblyCompositionEditor` para editar produtos e quantidades por cesta. O
backend revalida `allows_customization` na prévia e na confirmação. Manter a
composição e a identidade do pedido em retomadas incertas. Saldo personalizado
permanece por lote; saldo padrão permanece por tipo. O histórico mostra o saldo
personalizado fornecido pela API. A seleção de lote na venda segue como próxima
etapa; não misturar esses estoques. Ver [Montagens](docs/MONTAGENS_E_HISTORICO.md).

**Exclusão de tipos — regra aprovada em 14/10/2026:** a lixeira distingue apagar
cadastro/receitas nunca usados de retirar do catálogo um tipo com histórico.
Para o segundo caso, o usuário confirmou conservar registros anteriores.
`removed_at` marca a retirada e `is_active=false` impede novas operações.
Vendas não canceladas, saldo por lote/local/custódia e saídas abertas bloqueiam
ambos os modos. Revalidar na transação de exclusão; consultas da interface são
informativas. Nunca apagar/desconectar movimentos, vendas ou montagens como
consequência de excluir do catálogo. Migração com backup e verificação em cópia
preenchida. Ver [Exclusão de tipos](docs/EXCLUSAO_DE_TIPOS_DE_CESTA.md).

**Leitura do mapa modular:** os módulos abaixo incluem capacidades preservadas
no backend e não correspondem todos a menus ativos. Produção em lote,
desmontagem separada, expedição, responsáveis e tesouraria tiveram as telas
arquivadas em 13/10/2026. Montagem na venda e serviços financeiros compartilhados
continuam ativos. Ver [funções arquivadas](docs/FUNCOES_ARQUIVADAS.md).
O sistema é estruturado como um **Monólito Modular** de alta coesão e baixo acoplamento:
- **Separação Rígida de Responsabilidades:**
  - `estoque / inventory`: Livro-razão contábil *append-only*, sub-localizações de custódia (armazém da loja `STORE` vs. responsabilidade externa em trânsito `TRANSIT`), cálculo dinâmico de saldos e ajustes manuais de balanço com justificativa auditável.
  - `produtos / products`: Catálogo de insumos, unidades base, CMPM em escala fixa (microcentavos) e embalagens comerciais com fatores de conversão estritos.
  - `receitas / recipes`: Tipos de cesta e versionamento imutável de composições padrão.
  - `compras / purchases`: Entrada de insumos de fornecedores, conversão automática de embalagens, atualização do CMPM e estornos contábeis condicionados a saldo.
  - `montagem / production` (Fase 4 - Homologada): Ordens de montagem, consumo atômico de insumos valorizados pelo CMPM, rastreamento de lote padrão vs. personalizado com snapshot imutável, apuração do custo unitário do lote e desmontagem com triagem física de intactos (`STORE`) e perdas (`ASSEMBLY_LOSS`).
  - `vendas / sales` (Fase 5 - Homologada): Vendas de balcão e rotas, baixa atômica de produto acabado, cadastro de clientes (`customers`), contas a receber com parcelamento e quitações parciais (`sales_receivables`), congelamento do CMV e montagem simultânea sob demanda sem duplo consumo.
  - `expedicao / dispatch` (Fase 6 histórica; interface arquivada): Backend preservado para saídas físicas, responsáveis, conferência, perdas e acertos. Essas funções não têm menus ativos no cliente atual.
  - `financeiro / financial` (Fase 7): Gestão financeira completa, tesouraria, contas financeiras da empresa (`financial_accounts`), contas a pagar de fornecedores e despesas (`accounts_payable`), distinção entre despesas empresariais e retiradas pessoais dos sócios, e livro-caixa imutável (`cash_flow_entries`).
  - `relatorios_e_impressao / reports` (Fase 8): DRE Gerencial com CMV real do razão, margens brutas, fluxo de caixa, exportação de planilhas digitais (CSV e XLSX), relatórios preenchidos automaticamente em PDF, formulários em branco A4 com espaçamento para escrita manual à caneta, e módulo de impressão direta multiplataforma no Flutter (Windows Spooler e Android Print Spooler com compatibilidade para Epson Wi-Fi e rota de contingência para salvar/compartilhar PDF).
  - `infraestrutura / core`: Segurança TLS local, certificado autoassinado com fingerprint SHA-256, pareamento por PIN de 6 dígitos, tokens Bearer com hash SHA-256 no SQLite, transações atômicas sob `BEGIN IMMEDIATE`, durabilidade `PRAGMA synchronous = FULL`, `PRAGMA journal_mode = WAL`, `IdempotencyManager` e rotinas de backup quente.
- **Proibição de Dependências Circulares:** Módulos de domínio superior consomem serviços de módulos base, nunca o inverso.
- **Centralização de Regras de Negócio e Persistência:** Nenhuma regra de estoque, cálculo financeiro ou conversão de unidades reside no cliente Flutter. A API FastAPI é a autoridade única sobre o estado da aplicação.
- **Isolamento de Persistência:** É estritamente proibido o acesso direto ao banco SQLite por telas Flutter ou módulos não responsáveis pela persistência. Toda mutação ou consulta deve transitar exclusivamente através dos serviços de domínio e endpoints da API REST protegidos.

---

### 1.2. Evolução Segura e Preservação de Comportamento

**Contrato permanente — reforçado pelo usuário em 14/10/2026:** consultar
[regras de integridade e evolução](docs/REGRAS_DE_INTEGRIDADE_E_EVOLUCAO.md).
Preservar histórico, referências, unidades, datas e valores registrados ao evoluir
a interface e o backend. Distinguir ocultar um campo de apagar sua informação;
validar migrações sobre dados existentes e prever recuperação. Não interpretar
uma preferência funcional como autorização para enfraquecer essas proteções.
1. **Inspeção Prévia Obrigatória:** Antes de editar código, inspecionar arquivos afetados e identificar todos os pontos de consumo.
2. **Avaliação de Impacto e Não-Regressão:** Executar a suíte completa de testes automatizados (`pytest backend/tests -v` e `flutter test`), mantendo 100% de aprovação verde.
   - **Isolamento de testes:** redirecionar também a engine usada no startup e
     fábricas internas de sessão para bancos temporários; substituir apenas
     get_db não protege contra SessionLocal ou lifespan. Restaurar settings ao
     fim da fixture. Testes nunca gravam no banco real da empresa.
3. **Proibição de Exclusão ou Substituição Silenciosa:** Proibido remover ou alterar endpoints, schemas ou regras homologadas sem autorização explícita do usuário.
4. **Evolução do Banco via Migrações Versionadas:** Schema gerenciado exclusivamente pelo Alembic com suporte bidirecional a `upgrade()` e `downgrade()`.
5. **Rastreabilidade Contábil Imutável:** O livro-razão `inventory_movements` e o livro-caixa `cash_flow_entries` são estritamente *append-only* (protegidos por triggers nativos contra `UPDATE` e `DELETE`). Correções ocorrem exclusivamente por lançamentos reversos rastreáveis (estornos).

---

### 1.3. Front-End Adaptativo e Componentização Centralizada

**Entrega FE-055 — 17/10/2026:** navegação nas cinco áreas, tema compartilhado, preferências locais de aparência e resumos ligados aos serviços existentes estão implementados. Validação final: 334 testes Flutter, 436 de backend, análise sem pendências e build Windows Release concluído. Consultar [integração da interface aprovada](docs/INTEGRACAO_INTERFACE_APROVADA.md) e [evidências](docs/validacoes_frontend/fe-055-integracao-2026-10-17/README.md). As notas de planejamento abaixo são históricas nesse recorte. Regras do domínio permanecem no backend; não foram introduzidos IA, migrações ou novas dependências de execução. Fidelidade integral de todas as telas e homologação em aparelhos Android/iPhone ainda não estão certificadas.

**Direção de produto — 15/10/2026:** o
[manual de arquitetura do front-end](docs/ARQUITETURA_FRONTEND.md) registra a
fundação da próxima interface, com prioridade mobile em Android e iPhone e
adaptação para Windows. O usuário escolheu abrir na visão geral do negócio,
com acesso direto ao Financeiro. A área financeira deverá reunir pagar e
receber e comportar a evolução de contas, cartões, extratos e faturas, conforme
os contratos próprios. O trabalho atual continua sendo de planejamento gradual;
navegação, tema global e integração nativa iOS ainda precisam de suas entregas.

**Planejamento visual — 14/10/2026:** consultar o
[plano da nova arquitetura de design](docs/PLANO_ARQUITETURA_DE_DESIGN.md).
O usuário solicitou alinhamento do plano e comparação de direções visuais antes
de implementar. O documento é um rascunho de proposta; não autoriza aplicar um
tema global nem alterar telas, regras financeiras ou dados nesta etapa.

- **Botões flutuantes e rolagem:** manter a ação principal como FAB sobre o conteúdo, conforme preferência do usuário. Reservar espaço apenas no final da rolagem com `fabScrollPadding`, em `client/lib/utils/scroll_layout.dart`. Não criar uma barra fixa que reduza a área visível. O espaço considera a altura do botão no tema, margem e área segura. Consulte [docs/LAYOUT_E_ACOES_DE_PAGINA.md](docs/LAYOUT_E_ACOES_DE_PAGINA.md).
- **Mobile First com Adaptação Desktop:** Experiência prioritária em Android (toque no galpão/rotas) e fluida no Windows Desktop (telas amplas, tabelas densas e atalhos de teclado).
- **Filtros acessíveis em janelas estreitas:** opções não podem ficar cortadas e depender de um arraste horizontal indisponível para o mouse. Preferir `Wrap` para filtros rápidos, distribuindo-os em novas linhas conforme a largura. Se uma faixa horizontal for necessária, oferecer navegação visível e utilizável com mouse e toque. Verificar redimensionamento com a tela aberta e acesso à última opção. Reutilizar `ResponsiveFilterBar` em `client/lib/widgets/shared/` nas faixas de filtros das páginas; consultar [layout e ações](docs/LAYOUT_E_ACOES_DE_PAGINA.md).
- **Componentes Compartilhados:** Reutilização em `client/lib/widgets/shared/` de campos monetários, botões com spinner integrado, cartões padronizados e tabelas responsivas.
- **Gerenciamento de Estado:** `StatefulWidget` com serviços assíncronos desacoplados por tela e `ValueNotifier` para estados globais de aplicação.

#### Transições suaves de conteúdo condicionado a escolhas

**Diretriz aprovada pelo usuário em 14/10/2026:** quando uma escolha mostra,
oculta ou substitui informações, evitar mudanças bruscas de altura e posição.
Usar animação curta e discreta de tamanho e opacidade, com entrada e saída
suaves. O espaço do conteúdo ocultado deve se recolher gradualmente, sem deixar
um vazio permanente; ao reaparecer, deve se expandir da mesma forma.

- Manter os controles principais estáveis e preservar preenchimento, foco e
  rolagem. Não reconstruir ou limpar campos apenas para animar uma informação.
- Coordenar tamanho e opacidade para que os campos seguintes se desloquem
  suavemente. Preferir recursos declarativos do Flutter, como `AnimatedSize`
  e `AnimatedSwitcher`, e reutilizar um componente compartilhado quando o
  padrão se repetir. Evitar lógica de animação duplicada em cada tela.
- Como referência visual, usar duração aproximada de 200–250 ms e curva suave,
  ajustando ao componente. A interação e a regra de negócio não devem aguardar
  o fim da animação. Alternâncias rápidas devem convergir à escolha mais recente.
- Respeitar a preferência de redução de movimento da plataforma. Conteúdo
  oculto não deve continuar recebendo interação ou sendo anunciado como visível
  por recursos de acessibilidade. A seleção deve ser identificável além da cor.
- Tratar carregamento, sucesso e erro como estados distintos. Não apresentar
  falha de consulta como saldo zero nem aplicar resposta antiga a outra seleção.

**Aplicação na Nova Venda — implementada no código em 14/10/2026:**
usar “Pronta” à esquerda e “Montar” à direita, com o toggle no meio. “Pronta”
é o padrão e usa verde; “Montar” usa laranja. O toggle acompanha a cor da opção
selecionada, cujo nome também é destacado. A explicação correspondente aparece
abaixo. O indicador “Cestas prontas disponíveis: X” aparece somente em “Pronta”,
para o tipo de cesta selecionado. Ao escolher “Montar”, o indicador desaparece
com redução suave de opacidade e altura; os campos seguintes sobem suavemente.
Ao voltar a “Pronta”, ele reaparece com expansão suave e consulta o saldo atual,
mostrando o estado de carregamento enquanto aguarda a resposta. Antes de
selecionar um tipo, orientar a seleção sem exibir um saldo fictício.

Esta diretriz trata da apresentação: os contratos de venda e a persistência
mantêm suas regras. `AnimatedReveal`, em
`client/lib/widgets/shared/animated_reveal.dart`, centraliza a transição do
indicador. A tela distingue carregamento, falha e saldo zero, permite repetir
uma consulta com erro e ignora respostas anteriores à seleção/consulta atual.
O comportamento depende de recompilar e distribuir o cliente atualizado.

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

**Política de estoque de cestas — 14/10/2026:** `tracks_finished_stock` ligado
permite cesta pronta ou montagem na venda; desligado exige montagem na venda.
O backend rejeita venda pronta, produção antecipada e ajuste de cestas quando
desligado. Desativar com saldo pronto é bloqueado. Os movimentos de montagem e
cancelamento continuam preservados; um cancelamento pode devolver cestas físicas,
exigindo ativar a opção para vendê-las como prontas. Ver
[tipos de cesta](docs/TIPOS_DE_CESTA.md) e
[proposta de evolução](docs/EVOLUCAO_DO_MODULO_DE_CESTAS.md).
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

> **Interface arquivada:** esta seção conserva as regras do backend e do
> histórico de custódia. Não descreve uma rotina disponível nos menus atuais
> nem autoriza restaurar telas de expedição ou responsáveis.
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

> **Conferência de expedição arquivada na interface.** As regras abaixo
> continuam como referência para os registros e serviços preservados.
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

> **Acerto de rota arquivado na interface.** Não confundir esta rotina
> histórica com os recebimentos e pagamentos ativos de balcão.
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

> **Escopo atual:** a seção conserva o projeto original do módulo. A interface
> oferece seis relatórios e formulários A, B e D. Relatórios exclusivos de
> montagem/expedição, formulário C e visões de tesouraria estão arquivados.
> Dashboard e financeiro usam as consultas simplificadas. Ver
> [relatórios atuais](docs/RELATORIOS_E_IMPRESSAO.md).

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
[FASE 6: Saídas Físicas, Responsáveis & Conferência] ----------> [CONCLUÍDA & HOMOLOGADA]
  ├── Cria `responsible_persons` (Cadastro simples de colaboradores/entregadores)
  ├── Cria `stock_dispatches` e `dispatch_items` (Saída física STORE -> TRANSIT)
  ├── Estende `inventory_movements` (location_type e responsible_person_id)
  ├── Modifica `sales` (dispatch_id e responsible_person_id opcionais para vendas em rota)
  └── Cria `dispatch_settlements` (Conferência de 4 termos e acerto financeiro segregado)
        │
        ▼
[FASE 7: Gestão Financeira Completa & Tesouraria] ------------> [CONCLUÍDA & HOMOLOGADA]
  ├── Cria contas financeiras `financial_accounts` (Caixa da Loja, Bancos)
  ├── Cria contas a pagar `accounts_payable` e `payable_payments` (Compras e Despesas)
  ├── Cria livro-caixa imutável `cash_flow_entries` (Append-Only)
  └── Integra recebimentos da Fase 5 e repasses da Fase 6 à tesouraria da empresa
        │
        ▼
[FASE 8: Relatórios, Planilhas, Formulários A4 & Impressão] --> [CONCLUÍDA & HOMOLOGADA]
  ├── Consultas consolidadas de DRE Gerencial, Margens e Fluxo de Caixa
  ├── Exportadores para Planilhas Digitais (CSV e XLSX)
  ├── Gerador de Formulários Paginados A4 (Preenchidos e em Branco para Preenchimento Manual)
  └── Módulo de Impressão Direta Flutter (Spoolers Windows e Android, Epson Wi-Fi e Contingência PDF)
        │
        ▼
[FASE 9: Auditoria Final, Backup, Instalação & Entrega] -------> [CONCLUÍDA & HOMOLOGADA]
  ├── Instalador local do Windows, firewall e tarefas agendadas automáticas (Task Scheduler)
  ├── CLI e rotinas de backup quente online com integridade SQLite verificada e retenção
  ├── Teste E2E de ciclo de vida operacional ponta a ponta (registro histórico da entrega original: 180 testes backend e 93 testes Flutter; não representa contagem atual)
  ├── Compilações nativas de produção (Windows x64 Release .exe e Android Release APK 74.1MB)
  └── Manuais operacionais, de instalação, backup/DRP e impressão Epson Wi-Fi
```

---

## 6. Mapa Geral de Fases Atualizado

**Registro histórico de implementação e homologação.** “Concluída” abaixo
significa que a fase foi entregue originalmente, não que suas telas estejam
ativas. Fase 4: telas de produção/desmontagem arquivadas, motor compartilhado
ativo. Fase 6: interface arquivada. Fase 7: tesouraria arquivada, contas a pagar e
pagamentos ativos. Fase 8: relatórios reduzidos e financeiro simplificado.

```
[FASE 1] Fundação Arquitetural, TLS, Pareamento, WAL & Esqueleto Flutter ----> [CONCLUÍDA & HOMOLOGADA]
[FASE 2] Produtos, Embalagens/Conversões e Receitas Imutáveis -----------------> [CONCLUÍDA & HOMOLOGADA]
[FASE 3] Livro-Razão Append-Only, Compras com Conversão e Ajustes ------------> [CONCLUÍDA & HOMOLOGADA]
[FASE 4] Motor de Montagem e Produção (Lotes Padrão/Custom, CMPM Microcentavos,
         Triagem de Desmontagem, i18n Flutter e Compilações Nativas) --------> [CONCLUÍDA & HOMOLOGADA]
[FASE 5] Vendas de Cestas, Cadastro de Clientes, Vendas a Prazo e Montagem
         Simultânea (139 testes backend, 38 testes Flutter) ------------------> [CONCLUÍDA & HOMOLOGADA]
[FASE 6] Saídas Físicas, Responsáveis por Cestas e Conferência Operacional ---> [CONCLUÍDA & HOMOLOGADA]
[FASE 7] Gestão Financeira Completa (Contas a Pagar, Tesouraria e Caixa) ------> [CONCLUÍDA & HOMOLOGADA]
[FASE 8] Relatórios Gerenciais, DRE, Planilhas (CSV/XLSX), Formulários A4
         e Módulo de Impressão Direta (Multiplataforma / Epson Wi-Fi) ---------> [CONCLUÍDA & HOMOLOGADA]
[FASE 9] Auditoria Final, Robustez, Backup Quente, Instalação e Entrega ------> [CONCLUÍDA & HOMOLOGADA]
══════════════════════════ PROJETO 100% CONCLUÍDO E ENTREGUE ══════════════════════════════
```


### Retirada de importação financeira — decisão E5.7, 20/10/2026

O usuário autorizou concluir a simplificação e o desfazimento de importações.
A retirada é um estado auditado em `financial_import_removals`, sem apagar as
leituras/revisões originais. Uma transação valida snapshot e dependências, retira
as contas/previsões próprias e devolve contas de compras/saldos anteriores à sua
situação individual, mantendo valores e pagamentos. A exceção na proteção SQL
de conta substituída exige o registro desse desfazimento e preserva seus valores;
uma reabertura arbitrária continua proibida. Reimportar recupera o documento e
exige confirmação para restabelecer a conta existente, em nova revisão. Nenhum
pagamento ou estoque é fabricado para compensar uma retirada. Procedimento e
contratos no [guia de Pagar](docs/CONTAS_A_PAGAR.md#excluir-e-reimportar-uma-importação--e57).
