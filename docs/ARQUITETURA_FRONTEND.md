# Arquitetura do front-end e padrões do aplicativo

**Prioridade vigente FE-055 — 17/10/2026:** integrar a interface FE-052 aos
serviços existentes, com fidelidade de todas as telas e sem novos pilotos de
outra aparência. O [guia de integração](INTEGRACAO_INTERFACE_APROVADA.md) descreve
o código e o que ainda falta conferir. Cinco áreas/resumos reais e tema comum
estão no código; isso não é prova de equivalência visual completa nem de
instalação atualizada. O pedido de publicar no Sites foi revogado. Relatos
FE-054 e anteriores abaixo são históricos e não limitam a autorização FE-055.

**Fechamento técnico FE-055:** cinco áreas e serviços reais no cliente,
334 Flutter / 436 backend, análise sem pendências e Windows Release compilado.
Ver [evidências e limites](validacoes_frontend/fe-055-integracao-2026-10-17/README.md).
A revisão visual integral e os dispositivos físicos não foram certificados.

**Situação atual FE-054 — 17/10/2026:** [Receber revisado](PILOTO_RECEBER_REVISADO.md)
integrado ao Flutter/API, com consulta da venda de origem, filtros recolhidos,
extrato e paginação. Pagar/Receber compartilham a máquina de apresentação e o
motor de tentativa, com adaptadores tipados e contratos próprios. Fonte visual
FE-052 preservada; a navegação/tema globais e a instalação continuam separados.
Próximo: integrar as áreas principais e resumos reais à referência acolhida,
sem reabrir leitura, destinos ou medidas. Ver o registro atual e a evidência
FE-054 para resultados de validação; não confundir implementação com instalação.

Versão documental: **0.30 — Pagar e Receber revisados**. Revisão: **17/10/2026**.

Este é o manual vivo para orientar pessoas e agentes que evoluam o front-end.
Reúne decisões acordadas, propostas em revisão e os contratos de apresentação.
O [plano de design](PLANO_ARQUITETURA_DE_DESIGN.md) organiza a sequência de
trabalho; [ARCHITECTURE.md](../ARCHITECTURE.md) conserva a governança geral;
os [guias das mecânicas](README.md) descrevem o comportamento implementado.

A [memória e pesquisas](MEMORIA_E_PESQUISAS_FRONTEND.md) preserva o contexto,
os motivos, as fontes, os aprendizados técnicos e o estado para retomada.
As [prévias e referências](referencias_frontend/README.md) também estão copiadas
no projeto. Ao retomar após compactação, ler esses registros antes de propor
novas decisões; mantê-los atualizados a cada rodada relevante.

**Entrega anterior FE-053:** planejamento visual consolidado e primeiro incremento
real entregue no código: [pagamento revisado de Pagar](PILOTO_PAGAR_REVISADO.md).
A nova navegação global, o módulo financeiro unificado e o tema de todas as telas
ainda não foram implementados por este chat.
Itens marcados como proposta não devem ser tratados como decisões finais.

Usuário autorizou seguir após a indicação desse recorte. API existente foi
estendida de forma aditiva para saldo revisado/dia civil e capacidade do servidor;
cliente conserva comando e chave, faz revisão e trata confirmação/consulta como
resultados distintos. Não repetir autorização para ajustes desse piloto. Próximo
recorte é Receber, mantendo métodos/efeitos próprios e a direção visual FE-052.
Ver guia e evidência para distinguir código, testes, compilação e versão instalada.

**Continuação vigente FE-052:** a
[revisão integrada de acabamento](referencias_frontend/rodada-acabamento-2026-10-16/README.md)
reúne vidro/cores da referência inicial e listas como extrato, com filtros
compactos recolhidos. Usuário rejeitou o bloco grande de filtros e pediu adiantar
o conjunto respeitando arquitetura e acordos. Organização FE-049, Leitura
recuperada, cinco destinos e medidas conservados; não reabrir escolhas fechadas.
Fonte integrada atualizada por nova revisão; nenhuma fonte histórica editada.
O próximo incremento real continua limitado pelo contrato FE-050, sem migração
global inferida da aparência. Ver o registro atual para origem e verificações.

**Retorno visual FE-051:** o usuário destacou cores, vidro e apresentação das
contas na captura inicial de Contas a Receber. A
[base visual, seção 8](BASE_VISUAL_FRONTEND.md#8-aproveitar-o-acabamento-da-referência-inicial--fe-051)
registra o aproveitamento proposto desse acabamento sobre FE-049, preservando
Leitura recuperada, navegação e medidas. Não confundir a preferência com novos
parâmetros já aprovados ou com funções bancárias; fonte atual permanece intacta.

**Continuação FE-050:** após “SHOW, VAMOS PROSSEGUIR”, a organização FE-049 fica
acolhida como referência para a próxima etapa. As
[jornadas financeiras e preparação do piloto](JORNADAS_FINANCEIRAS_E_PRONTIDAO_DO_PILOTO.md)
consolidam estados e contratos confrontados com o código atual: identidade do
envio, saldo revisado, data civil, atraso e cobertura/atualização das consultas.
Pagar sobre título existente é recomendação de primeiro recorte, ainda não escolha
do usuário. Fonte visual intacta; sem implantação Flutter/API nesta rodada.

**Decisões FE-049:** usuário escolheu expressamente a **Leitura recuperada**,
rejeitando o excesso de tamanho/peso da orientada. A organização integrada foi
bem recebida. Escolheu **Negócio** como nome central: vendas, clientes e resultado,
com este último retirado do Financeiro. Início deve ser curto e reunir o essencial,
com Dia/Semana/Mês e atenção atual a vencimentos/estoque. A
[revisão integrada](referencias_frontend/rodada-organizacao-2026-10-16/README.md)
demonstra esse recorte na mesma base, preservando os demais caminhos/medidas.
Não reabrir a disputa tipográfica nem ampliar a home sem uma necessidade concreta.
Próximo trabalho: concluir jornadas/estados e contratos reutilizáveis antes do
piloto pequeno, com seu escopo próprio. Sem implementação Flutter/API ou commit.

**Histórico FE-048:** em continuidade ao encaminhamento FE-047, a
[comparação de leitura](referencias_frontend/rodada-tipografia-2026-10-16/README.md)
parte diretamente da integrada FE-046. Compara hierarquia recuperada e orientada
na mesma jornada, com apoios maiores, valores contextualizados, nomes longos,
quantias altas e conteúdo ampliado em claro/escuro. Barra, destinos e medidas
confirmadas preservados. Papéis/família seguem propostos; colher retorno sobre
a leitura antes de fechar outros detalhes visuais. Sem Flutter/API ou commit.
Consultar o [registro atual](REFERENCIA_ATUAL_FRONTEND.json) para fonte e evidências.

**Histórico FE-046:** após a [auditoria de continuidade](AUDITORIA_CONTINUIDADE_FRONTEND_2026-10-16.md),
o usuário autorizou a recuperação. A [prévia integrada recuperada](referencias_frontend/rodada-recuperacao-integrada-2026-10-16/README.md)
reutiliza a estrutura do mapa original, mantém a barra e os destinos e incorpora
as jornadas financeiras. Conferência local concluída; retorno do usuário pendente.
O [registro da referência atual](REFERENCIA_ATUAL_FRONTEND.json) aponta para a
fonte candidata e sua origem. Consultá-lo antes de editar; fontes históricas
permanecem como comparação. Próximo passo é revisar a recuperação antes de nova
expansão. Cópias locais não equivalem a versionamento Git ou implementação Flutter.

## 1. Direção estabelecida pelo usuário

| Decisão | Situação |
| --- | --- |
| Projetar por etapas, alinhando antes de implementar cada incremento. | Confirmada em 15/10/2026. |
| Priorizar experiência mobile em Android e iPhone; manter experiência própria e confortável no Windows. | Confirmada em 15/10/2026. |
| Abrir em uma visão geral do negócio, com acesso direto ao Financeiro. | Escolhida pelo usuário em 15/10/2026. |
| Usar Início, Financeiro, Negócio, Estoque e Mais, com navegação inferior no celular e lateral no computador. | Base acolhida em 15/10/2026; FE-049 renomeia Vendas para Negócio por escolha explícita, sem retirar suas funções. |
| Manter a Leitura recuperada, com diferenças de peso/tamanho proporcionais. | Escolhida em FE-049; orientada rejeitada por parecer grande e pesada demais. Referência web aceita, sem homologação de métricas nativas. |
| Manter Início enxuto, com o essencial e escolha Dia/Semana/Mês. | Direção FE-049. Objetivo de caber numa tela usual; texto ampliado/menor altura continuam acessíveis por rolagem quando necessário. |
| Colocar resultado do negócio junto de vendas/clientes em Negócio; Financeiro concentra pagar/receber e vencimentos. | Localização e nome escolhidos em FE-049; cálculo e origem financeira preservados. |
| Reunir Contas a Pagar e Contas a Receber na mesma área Financeiro. | Direção confirmada; organização interna a detalhar. |
| Manter a conferência antes de confirmar o registro de pagamento em Pagar. | Aceita pelo usuário em 16/10/2026. |
| Começar em pagamento integral do saldo atual; oferecer parcial com campo de valor revelado suavemente. | Solicitado em 16/10/2026; demonstrado na nova prévia. |
| Começar também o recebimento de fiado em integral do saldo atual, com parcial opcional. | Confirmado em pergunta específica de 16/10/2026: geralmente quitam o saldo inteiro (FE-022). |
| Usar curvas mais amplas, cantos de campos 24 e de painéis 32, com controles de uma linha próximos de cápsulas. | Direção solicitada em 16/10/2026; raios confirmados explicitamente em FE-030. |
| Usar espaço 20 entre campos e permitir escolher destaque nas configurações, com azul original #2866ae por padrão. | Confirmado em FE-028; configuração real ainda por implementar. |
| Destacar vencimentos nos próximos três dias, com hoje e atrasadas separados. | Horizonte escolhido na pergunta específica FE-040; demais detalhes da regra INT-01 estão propostos no documento de regras. |
| Preparar a área financeira para contas, cartões, extratos, faturas e revisão de importações. | Requisito de evolução; respeitar os contratos do trabalho financeiro em andamento. |
| Preparar interface para futura importação de documentos de compras/DANFE. | Requisito futuro; sem leitor ou fluxo implementado nesta etapa. |
| Manter funções atuais de estoque, cestas, vendas, cadastros, documentos, impressão, conexão e backup. | Escopo funcional preservado; apresentação será revista por etapas. |
| Compartilhar padrões visuais e de interação entre módulos, com responsabilidades e dependências explícitas. | Diretriz de arquitetura. |
| Projetar com o rigor esperado de uma grande aplicação financeira e empresarial, pesquisando e registrando os aprendizados continuamente. | Direção solicitada em 16/10/2026 (FE-018); preservar simplicidade da rotina e evolução por etapas. |
| Usar os dados do app para interpretar situações, antecipar necessidades e apresentar informação útil nas telas e momentos certos, transmitindo cuidado sem depender de IA. | Definição explícita do usuário em FE-036; referência detalhada em design inteligente. Novas regras serão alinhadas por etapas. |
| Usar a prévia apreciada pelo usuário como referência de aparência moderna, arredondamento, profundidade e movimento. | Direção visual aceita como base em 15/10/2026; variante, cores e medidas finais ainda em revisão. |

O negócio inicial é uma pequena empresa familiar de entrega de cestas, sem
atendimento em loja e com entrega pela própria família. A interface deve
privilegiar essa rotina. Rotinas de gestão de vários entregadores ou telas
arquivadas só entram por uma necessidade futura explicitamente definida.

A adaptação a outros negócios será obtida por composição de módulos e contratos
estáveis. Trocar um módulo requer avaliar seus consumidores e seus vínculos com
dados existentes. Organização em arquivos, interfaces, dependências e migração
de apresentação fazem parte desse trabalho.

## 2. Base atual e capacidades futuras

Inspeção realizada em 15/10/2026:

- O cliente usa Flutter, com `views`, `services`, `models`, `core`, `l10n`,
  `utils` e componentes compartilhados em `widgets/shared`.
- O tema atual é Material 3 claro, definido em `client/lib/main.dart`. A prévia
  comparativa ainda não é um tema aplicado ao Flutter.
- Há projetos nativos Android e Windows. `client/ios` ainda não existe na
  estrutura inspecionada. O iPhone passa a orientar o projeto desde agora;
  sua integração nativa, permissões, plugins e validação serão uma entrega própria.
- O scanner de pareamento tratado no outro chat é Android. Considerar câmera,
  rede local, armazenamento seguro, arquivos e impressão também na futura
  integração iOS, com validação no ambiente da plataforma.
- A configuração atual usa a API local. Conexão, disponibilidade do servidor e
  pareamento continuam sendo parte da experiência. O requisito mobile não
  implica, por si só, acesso ao servidor fora da rede local ou gravação offline.
- O trabalho financeiro em outro chat evoluiu durante o planejamento. Os guias
  atuais descrevem [base e conciliação](BASE_FINANCEIRA_E_CONCILIACAO.md) e
  [leitores CSV multibanco](IMPORTACAO_CSV_MULTIBANCO.md) implementados no backend,
  sem telas novas. Migrações preparadas não comprovam aplicação no banco da
  empresa. Revalidar contratos e capacidades antes de detalhar a integração visual.

Referências locais: [cliente](../client/README.md),
[conexão e pareamento](CONFIGURACAO_E_AUTENTICACAO.md),
[layout atual](LAYOUT_E_ACOES_DE_PAGINA.md) e
[plano financeiro](PLANO_IMPORTACAO_E_CONCILIACAO_FINANCEIRA.md).

## 3. Primeira etapa: mapa do aplicativo

**Base aceita em 15/10/2026:** a demonstração navegável foi bem recebida quanto
à aparência, apresentação, organização e utilidade da visão geral. Adotar os
cinco destinos abaixo como ponto de partida para detalhar os percursos. Essa
aceitação permite avançar o projeto; os detalhes internos de cada área continuam
sendo alinhados por etapas.

| Área | Conteúdo principal | Observação |
| --- | --- | --- |
| Início | Resumo financeiro, cestas/vendas por Dia/Semana/Mês, atenção atual e atalhos. | Destino inicial confirmado. Curto nas condições usuais; não ocultar informações ou reduzir texto para forçar encaixe. |
| Financeiro | Pagar, receber, contas, cartões, extratos, faturas e documentos em revisão. | Capacidades atuais e futuras devem estar identificadas. |
| Negócio | Vendas, clientes, resultado do negócio e sua composição/limites. | Nome escolhido em FE-049. Registros de recebimento continuam usando o domínio financeiro; resultado não é saldo bancário. |
| Estoque | Produtos, compras de entrada, cestas/composição, montagens, posição e histórico. | Organização inicial para o negócio de cestas; rotas específicas por função. |
| Mais | Relatórios, impressão/formulários, configurações, conexão e backup. | Ações frequentes também podem ter acesso contextual nas páginas pertinentes. |

No celular, a base usa navegação inferior com ícone e nome para os cinco destinos;
no computador, navegação lateral. Os percursos seguintes deverão verificar essa
composição com formulários, teclado, ações e conteúdo extenso. No Windows,
avaliar o aproveitamento de espaço para lista e detalhe quando a tarefa justificar.
Os destinos e os dados são compartilhados, preservando a posição de cada área ao
alternar. A composição depende da largura útil, entrada por toque ou mouse/teclado,
escala de texto e convenções da plataforma.

**Continuidade da referência, FE-044:** o mapa navegável original continua sendo
a base da organização, além da home. A prévia Negócio em foco é um estudo parcial
de informações úteis e jornada financeira; não substitui o mapa completo nem
retira do plano clientes, compras, cestas/montagens, movimentações, relatórios,
impressão, conexão ou backup. Contas/cartões e extratos/faturas conservam sua
identificação de capacidade futura na referência. A comparação das omissões
está na seção 8.2 da [composição das páginas](COMPOSICAO_DAS_PAGINAS_FRONTEND.md).
Uma nova apresentação integrada deve conservar esses pontos de entrada e a
continuidade por área, distinguindo caminho demonstrativo de função implementada.

A regra existente sobre FAB trata da ação principal da página e do espaço no
fim da rolagem. A navegação entre áreas deve compor-se com essa ação sem encobrir
itens, teclado ou áreas seguras.

## 4. Separação de responsabilidades proposta

| Parte | Responsabilidade | Limites |
| --- | --- | --- |
| Estrutura do aplicativo | Destinos, navegação, contexto de conexão, tema e serviços compartilhados. | Recebe os pontos de entrada dos módulos; evita regras de cestas, banco ou compras. |
| Sistema de design | Tokens, componentes, estados visuais, acessibilidade e padrões de composição. | Recebe dados e ações; não decide se uma dívida deve ser baixada ou um estoque movimentado. |
| Módulo funcional | Telas, estado de apresentação, filtros e jornadas do domínio correspondente. | Expõe contratos e pontos de entrada; evita importar detalhes internos de outro módulo. |
| Dados do cliente | Serviços da API, modelos tipados e transformação necessária à apresentação. | Reutiliza o ApiClient e os contratos do servidor. |
| Backend | Regras de negócio, transações, idempotência, histórico e persistência. | Continua sendo a autoridade das operações comerciais e financeiras. |
| Integração nativa | Câmera, seleção de arquivos, compartilhamento, impressão e credenciais. | Isola diferenças Android/iOS/Windows; informa suporte e falhas à apresentação. |

A camada de estado deve guardar seleção, filtros, progresso e ações de cada
jornada separadamente dos widgets de aparência. Quando uma tela exigir estado
complexo, propor sua extração para um controlador/view model testável. Reaproveitar
os serviços existentes; escolher bibliotecas e reorganizar diretórios no incremento
apropriado, após mapear os consumidores. Os nomes finais de pastas ainda não estão
fechados. As telas atuais podem coexistir com a estrutura nova durante a migração.

### Contrato mínimo de um módulo

Cada módulo deverá documentar:

1. Finalidade, pontos de entrada, rotas e ações que oferece às outras áreas.
2. Modelos e serviços que consome, com dependências permitidas.
3. Estado de apresentação, filtros, paginação e comportamento ao retornar à tela.
4. Componentes e famílias de página reutilizados.
5. Estados de carregamento, ausência de dados, erro, progresso e conclusão.
6. Capacidades por plataforma e comportamento quando um recurso está indisponível.
7. Textos localizados, acesso a dados sensíveis e apresentação de documentos.
8. Evidências de validação e efeito de habilitar, substituir ou desativar a área.

Desativar a apresentação de um módulo conserva dados e referências históricas.
Integrações entre módulos usam contratos explícitos. Por exemplo, Estoque oferece
uma compra como origem ao Financeiro; a tela financeira consulta o documento pelo
contrato correspondente, preservando a operação original.

## 5. Área Financeiro: capacidade prevista, detalhes em outra etapa

O objetivo é apresentar as informações financeiras de maneira coesa, com
navegação clara entre obrigações, recebimentos, contas, cartões e documentos.
A organização interna será detalhada em percursos curtos, a partir do mapa aceito.

| Assunto | Contrato de apresentação a preservar |
| --- | --- |
| Pagar e receber | Duas visões da mesma área, com suas regras e ações próprias. |
| Contas e cartões | Exibir instituição, identificação adequada e titularidade PF/PJ quando o domínio fornecer. Consolidar somente quando moeda, escopo e significado forem compatíveis. |
| Extratos e movimentações | Mostrar período, origem, valores e datas conforme o documento; preservar informação parcial sem fabricar horário. |
| Faturas | Manter ciclo, vencimento, compras/parcelas, créditos, encargos e pagamentos conforme o contrato financeiro. |
| Importações e revisão | Acompanhar documento recebido, análise, ambiguidades, sugestões, revisão e confirmação. Estados concretos virão da API estabilizada. |
| Conciliação | Exibir a relação entre documento e operação já existente, com divergências e histórico de decisão. |

O front-end deve distinguir dados recebidos, dados conferidos e efeitos financeiros
confirmados. Documento importado não deve aparecer como dívida paga ou saldo
efetivo apenas por ter sido recebido. Compra, item de fatura e pagamento mantêm
seus vínculos, sem somas duplicadas. Classificações e totalizações financeiras
continuam nos serviços do domínio.

Uma revisão de PDF, OFX, CSV ou de documento de compra pode compartilhar
componentes de seleção, progresso, comparação e confirmação. Cada domínio
conserva seus campos e validações. Para DANFE, o futuro fluxo de revisão deverá
explicitar itens, unidades e efeitos da confirmação de compra antes de uma
entrada de estoque. Suporte a cada banco/formato será validado por incremento.

## 6. Padrões que serão detalhados progressivamente

O [catálogo mínimo de componentes](CATALOGO_COMPONENTES_FRONTEND.md), iniciado
em FE-025, reúne contratos, responsabilidades, estados e exemplos extraídos das
jornadas aceitas. A primeira proposta mostra campos/escolhas, ações/respostas
e resumo/lista. Direção e apresentação aceitas como referência em FE-026;
estados adicionais, contratos técnicos e tokens continuam por formalizar.
O catálogo não é uma biblioteca Flutter já implementada.

A [base visual](BASE_VISUAL_FRONTEND.md) detalha a rodada FE-027: papéis de cor,
pares claro/escuro, contorno essencial, formas e espaço compartilhados nas
amostras. Os [valores estruturados](TOKENS_VISUAIS_PROPOSTOS.json) são propostas,
sem aplicação ao tema do cliente. FE-028 confirma espaço 20 e preferência de
destaque com azul original por padrão. FE-030 confirma campos 24 e painéis 32;
fundo continua por fechar. Medidas são referências da prévia a traduzir para
unidades lógicas no piloto.

A [hierarquia e tipografia](HIERARQUIA_E_TIPOGRAFIA_FRONTEND.md), FE-033, propõe
papéis de leitura por família, escala inicial, apresentação de valores e
reorganização quando o texto cresce. Os novos tamanhos e a família não foram
confirmados. A proposta documental foi aplicada à comparação integrada FE-048,
sem alteração Flutter. O controle de texto amplia apenas o conteúdo; não
comprova navegação com escala global, zoom nem Dynamic Type. Preservar a barra
normal não permite limitar a preferência de texto do sistema na implementação.

A [composição das páginas](COMPOSICAO_DAS_PAGINAS_FRONTEND.md), FE-034, detalha
lista, detalhe, registro e revisão, com contexto de retorno e estados separados.
Recomenda detalhe dedicado na primeira revisão e prepara o conjunto para uma
futura prévia agrupada. Arranjos e novos contratos continuam propostas.

| Bloco | Conteúdo a especificar na etapa correspondente |
| --- | --- |
| Identidade e tema | Cores semânticas, aparência clara/escura, destaque, superfícies, profundidade e uso de vidro. |
| Tipografia e espaço | [Papéis, hierarquia por tarefa e escala inicial proposta](HIERARQUIA_E_TIPOGRAFIA_FRONTEND.md); texto ampliado reorganiza a composição. Espaço 20 confirmado. |
| Movimento | Feedback, revelação, transições, interrupção e redução conforme a plataforma; ver o [padrão de movimento](PADROES_DE_MOVIMENTO_FRONTEND.md). |
| Controles | Botões, FAB, seleções, busca, datas, moeda, quantidade, validação e descrições secundárias. |
| Famílias de página | Visão geral, lista/detalhe, formulário, revisão/confirmar, seleção de documentos e configurações. |
| Listagens e filtros | Busca, aplicação de filtros, ordenação, paginação, seleção e preservação de contexto. |
| Estados | Carregamento, vazio inicial, nenhum resultado de filtro, falha, dados anteriores, progresso e sucesso. |
| Documentos | Pré-visualização, impressão, exportação, compartilhamento e formulários para preenchimento à caneta. |
| Plataforma e acessibilidade | Teclado, foco, voltar, leitor de tela, toque, áreas seguras, câmera e redução de movimento. |

Textos visíveis continuam no catálogo de traduções. Datas, valores e unidades
usam utilitários centrais. Campos ausentes têm apresentação própria; não viram
zero, horário inventado ou texto técnico. Totais calculados só sobre a página
carregada precisam indicar esse escopo. Informação desatualizada, indisponível
ou incompleta deve ficar distinguível de um resultado válido.

### Critérios em elaboração para informação financeira

A [pesquisa empresarial de 16/10](PESQUISA_FRONTEND_EMPRESARIAL_2026-10-16.md)
explicita fontes, aplicações propostas e limites. O pedido de rigor empresarial
é confirmado; os critérios de interação abaixo ainda serão avaliados em prévias:

- Cada indicador tem significado, moeda, período/data de posição, cobertura,
  origem e destino definidos. Seu detalhe permite conferir os registros da soma.
- Situação do título, revisão de documento e disponibilidade da consulta são
  dimensões distintas. Consulta indisponível não apresenta um zero confirmado.
- Uma rejeição conhecida e um retorno perdido ao salvar exigem tratamentos
  diferentes. Preservar a identidade da operação depende do contrato local;
  desabilitar o botão não substitui proteção contra duplicidade.
- Celular e Windows compartilham o significado e as ações, com composições
  próprias para leitura, toque e comparação. Detalhes secundários são revelados
  quando ajudam a tarefa.

Esses critérios complementam o domínio existente; não transferem os cálculos
financeiros aos widgets nem constituem comprovação de conformidade fiscal.

O movimento é projetado e demonstrado durante o planejamento, depois integrado
ao Flutter com as jornadas aprovadas. A [especificação inicial](PADROES_DE_MOVIMENTO_FRONTEND.md)
separa efeitos já demonstrados, propostas de duração e itens abertos. Reutilizar
os auxiliares existentes quando adequado, verificando os sinais de redução de
movimento de Android e iPhone no SDK efetivamente usado.

Verificar a largura dos controles contra a área útil de seu campo/painel e os
controles vizinhos, além da janela inteira. Conferir também os caracteres e o
alinhamento interno: a nova foto do usuário comprovou falha de texto apesar da
largura externa corrigida. Uma prévia com viewport de iPhone ou WebKit desktop
não comprova comportamento do seletor nativo iOS. A
[revisão posterior da data](RODADA_FRONTEND_RESUMO_E_DATA_2026-10-16.md)
usa botão com calendário na amostra; sua validação no aparelho e a escolha do
seletor Flutter continuam pendentes. Não tratar esse código HTML como implementação.

Exibir apenas dados que ajudem a tarefa. Identificadores e detalhes de diagnóstico
ficam fora do fluxo comum; dados bancários e pessoais são mascarados quando o
contexto permitir. Prévias e testes usam exemplos fictícios.

Os componentes existentes de filtros responsivos, resumo financeiro, animação,
rolagem do FAB e documentos são candidatos à evolução/reutilização. Antes de
criar outro componente, revisar o que existe e seus consumidores.

## 7. Processo de projeto e implementação

### Apresentar cada decisão com exemplos

O usuário esclareceu em 15/10/2026 que uma tabela abstrata não é suficiente
para avaliar a proposta. Cada rodada de alinhamento deve:

1. Mostrar telas conectadas em uma prévia navegável, com uma tarefa cotidiana
   curta e dados de exemplo. Quando a adaptação fizer parte da decisão, mostrar
   as composições de celular e computador.
2. Explicar qual decisão está em avaliação e marcar capacidades futuras. A
   aparência exploratória não representa funcionalidade entregue.
3. Pedir retorno sobre o percurso concreto: onde a pessoa procuraria a função,
   qual rótulo usaria e em que ponto esperaria outro comportamento.
4. Registrar o que foi acordado e escolher apenas a próxima questão a detalhar.

A primeira demonstração cobre Início → Financeiro → Pagar → detalhe de conta,
e Estoque → Cestas e montagens → tipo de cesta. Também permite alternar áreas
preservando o ponto da navegação. Essas são demonstrações locais; continuam
sem implementação no cliente Flutter ou comunicação com o banco.

### Base estudada: acompanhar e registrar um pagamento

**Andamento em 16/10/2026:** o usuário aceitou a conferência da
[primeira rodada](RODADA_FRONTEND_PAGAR_2026-10-15.md) e pediu integral por padrão,
parcial opcional com revelação animada e mais arredondamento. A
[rodada revisada](RODADA_FRONTEND_INTEGRAL_2026-10-16.md) já demonstra e verifica
essas mudanças. Avaliar agora o acabamento e a interação da nova amostra;
não promover os valores de geometria a tokens finais automaticamente.
Após relato de transbordamento da data no iPhone, a primeira revisão limitou a
moldura à coluna. Nova foto confirmou que o texto ainda estava cortado. A
[rodada posterior](RODADA_FRONTEND_RESUMO_E_DATA_2026-10-16.md) passou a exibir a
data por botão com calendário, verificando também os limites dos caracteres.
A observação dessa nova amostra no iPhone continua pendente.

Detalhar uma jornada cotidiana do Financeiro, começando por Pagar:

1. Encontrar uma conta a partir do resumo ou da lista, mantendo período e filtros.
2. Abrir o detalhe e entender origem, vencimento, situação, valor original,
   pagamentos anteriores e saldo em aberto.
3. Registrar um pagamento realizado: integral do saldo atual selecionado por
   padrão; parcial revela o campo de valor. Data e forma efetiva usam o contrato
   correspondente. O rótulo comunica registro; execução de transferência bancária
   não faz parte desta jornada. Valor parcial oculto não entra no cálculo integral.
4. Conferir os dados e apresentar a conclusão com o saldo e o histórico atualizados.

Exemplo fictício demonstrado: uma conta de R$ 680,00 recebe um pagamento
de R$ 300,00; a conclusão mostra R$ 380,00 em aberto e o registro no histórico.
O exemplo serve para avaliar clareza e comportamento visual. Revalidar valores,
estados, datas e permissões com o domínio antes de qualquer implementação real.
Na revisão de 16/10, escolher Parcial é necessário para digitar os R$ 300,00;
o próximo integral usa os R$ 380,00 restantes. A prévia deve evoluir até representar
o fluxo e o acabamento aprovados, que orientarão a conferência da entrega Flutter.

A rodada deve mostrar esse percurso no celular e a composição correspondente
no computador. Incluir preenchimento inválido, envio em andamento e falha que
preserve os campos; avaliar revisão e prevenção de envio repetido. Extrair os
padrões de lista, detalhe, formulário e conclusão somente após avaliar o uso.
Receber será uma próxima adaptação, conservando suas próprias regras. Contas,
cartões e importações terão percursos próprios em rodadas posteriores.

### Rodada autorizada em 16/10: resumo e origem do valor

O usuário autorizou o recorte FE-019, solicitando corrigir primeiro a data (FE-020):
demonstrar
**Financeiro → Pagar hoje → lista filtrada → origem da conta**, reaproveitando
a jornada de pagamento. A [nova amostra](RODADA_FRONTEND_RESUMO_E_DATA_2026-10-16.md)
foi criada com entradas para conferir a data, explorar o resumo no celular e
explorar no Windows. Compara consulta carregada, sem contas na data e indisponível.
Integral de R$ 680,00 retira a conta do resumo; parcial de R$ 300,00 mantém
R$ 380,00 tanto no resumo como na lista em aberto. A conta de R$ 600,00 que vence
em 18/10 não entra no recorte de 16/10. Todos são dados fictícios.

O usuário considerou essa amostra ótima/perfeita e pediu continuar. Ela fica
aceita como referência para avançar a Receber; a homologação do aplicativo no
aparelho permanece uma etapa de implementação. A posição global dos indicadores,
os tokens numéricos e o seletor Flutter definitivo não foram congelados.

As informações úteis da visão geral devem indicar período, significado do valor
e acesso à ação correspondente. Valores indisponíveis ou incompletos conservam
essa indicação. Essa direção não pressupõe uma função de inteligência artificial.

### Base aceita: receber o saldo de uma venda fiada

O usuário confirmou integral como padrão também em Receber (FE-022). A
[nova rodada](RODADA_FRONTEND_RECEBER_2026-10-16.md) demonstra lista, detalhe,
venda de origem, registro, revisão, conclusão e histórico no celular/Windows.
Exemplo: venda de R$ 150,00 já recebeu R$ 50,00; o integral agora é R$ 100,00.
O parcial de R$ 40,00 deixa R$ 60,00, usados pelo integral seguinte.

A mesma amostra acrescenta transições curtas de página e entrada de calendário,
além da revelação do parcial, com comparação de movimento reduzido. O usuário
aceitou a demonstração como referência (FE-024). A formalização dos tempos e
curvas compartilhados continua no catálogo de componentes. O recebimento conserva o vínculo à
venda, não cria outra venda e não movimenta estoque novamente.

### Base aceita: catálogo mínimo de componentes e estados

O usuário autorizou continuar o planejamento (FE-025). O
[catálogo inicial](CATALOGO_COMPONENTES_FRONTEND.md) demonstra padrões de
campos/escolhas, ações/respostas e resumo/lista, com contratos para futuros
agentes e mapeamento da base existente. Os novos estados de consulta anterior
e resultado desconhecido são propostas; cache e recuperação reais continuam
dependentes do contrato técnico. A situação do registro, a disponibilidade da
consulta e o andamento do comando são dimensões distintas.

O retorno posterior “Tá ótimo” destacou elegância, aparência agradável e
arquitetura inteligente (FE-026). Direção e apresentação ficam aceitas como
referência, sem congelar todos os detalhes. Estorno, várias vendas do mesmo cliente,
data/hora e resposta desconhecida precisam de contratos próprios antes da
integração correspondente.

### Rodada atual: cores, formas e espaço compartilhados

O pedido de continuar autoriza FE-027; a retomada após interrupção conserva esse
recorte. A [proposta visual](BASE_VISUAL_FRONTEND.md) mantém os três exemplos do
catálogo, com ajustes compartilhados e pares de aparência. Distingue separadores
de contornos de campos, destaque de avisos financeiros e origem da cor de sua
tonalidade legível em cada tema. Medidas e paleta continuam por escolher.

Uma inspeção revelou que interpolar só o fundo durante troca de tema podia
reduzir a leitura temporariamente. A nova amostra troca texto/fundo juntos;
isso não é relato de defeito no Flutter. Após retorno, registrar a combinação
preferida e alinhar a hierarquia tipográfica. O piloto real continua por definir.

### Etapas

**Cadência FE-032:** registrar e agrupar ajustes simples, sem gerar/exibir uma
nova prévia a cada mudança. Retomar apresentação visual por pedido do usuário
ou quando houver um conjunto significativo para revisar. O estudo local de
calendário da [rodada FE-031](RODADA_FRONTEND_CALENDARIO_2026-10-16.md) já estava
testado quando essa preferência chegou e não foi apresentado nem aprovado.

**Retorno FE-028/FE-029:** o usuário confirmou espaço 20 e personalização do
destaque e relatou ajustes sem resposta. A
[correção da prévia](RODADA_FRONTEND_AJUSTES_2026-10-16.md) reproduz conflito entre
edição e restauração antiga, com revisão testada usando o helper original.
Controles movidos para testar não definem escolhas finais. No retorno seguinte,
**FE-030**, o usuário confirmou explicitamente campos 24 e painéis 32. Movimento
compartilhado foi explicado como política comum às três amostras, sem escolha
de modo nesta resposta; ver [padrões de movimento](PADROES_DE_MOVIMENTO_FRONTEND.md).

| Etapa | Decisão/entrega | Situação |
| --- | --- | --- |
| Fundação | Objetivo, plataformas, modularidade e documento de referência. | Registrada nesta versão. |
| Mapa e navegação | Áreas principais, página inicial e relações entre módulos. | Organização e visão geral aceitas como base em 15/10/2026. |
| Identidade e controles | Tema, tokens, aparência e comportamento demonstrados em amostras de celular/desktop. | Direção visual aceita como base; padrões finais a fechar nos percursos. |
| Famílias de página | Exemplos de lista, detalhe, formulário, revisão e documento. | Pagar/resumo/data e Receber/movimento aceitos como referência. Integral como padrão confirmado em ambos os percursos. |
| Catálogo mínimo | Contratos dos componentes, exemplos e estados; base para pessoas e agentes futuros. | Direção/apresentação aceitas como referência em FE-026; detalhes técnicos e tokens por formalizar. |
| Base visual | Papéis de cor, pares de aparência, formas e espaço aplicados ao catálogo. | Espaço 20 e destaque configurável confirmados em FE-028; campos 24/painéis 32 em FE-030. Fundo e tipografia por alinhar; dados estruturados ainda não são tema Flutter. |
| Hierarquia e tipografia | Contexto e ênfase por tarefa; papéis de texto, valores e adaptação. | FE-048 compara leitura recuperada/orientada na base integrada; conteúdo ampliado e dados extremos demonstrados. Tamanhos/família continuam em avaliação; navegação ampliada global exige estudo próprio. |
| Composição e continuidade | Blocos de lista/detalhe/registro/revisão, retorno e situações de consulta/comando. | Proposta documental FE-034 pesquisada; conjunto preparado para futura revisão visual agrupada, sem gerar outra prévia nesta rodada. |
| Contratos técnicos | Estado, serviços, componentes e integração das jornadas escolhidas. | Planejada; alinhar com a API financeira em andamento. |
| Piloto | Primeiro incremento real, pequeno e verificável. | Ainda sem autorização de implementação; Contas a Receber é candidato anterior, a reavaliar dentro da área Financeiro. |
| Adoção gradual | Migrar grupos de telas e integrações nativas. | Planejada; manter o restante funcionando. |

Cada rodada deve fechar uma decisão relevante, atualizar este manual e deixar
claro o próximo ponto. Depois de um incremento ter seu escopo autorizado,
ajustes rotineiros dentro dele podem prosseguir sem renegociar cada arquivo.
Novas regras, ampliação de escopo ou efeitos nos dados exigem o alinhamento
correspondente. Aprovar a aparência de uma prévia não aprova o redesenho inteiro.

## 8. Como um agente deve usar este manual

1. Consultar a governança geral, este manual, o plano, a memória de pesquisas
   e os guias do módulo; conferir o estado da próxima sessão e as prévias salvas.
2. Distinguir decisão confirmada, proposta e comportamento implementado.
3. Identificar a etapa autorizada e os contratos/componentes já existentes.
4. Propor a menor alteração coerente com o padrão; mapear consumidores antes
   de mover arquivos, alterar um componente compartilhado ou mudar contratos.
5. Preservar traduções, regras financeiras, dados, compatibilidade e alterações
   locais de outros trabalhos. Revalidar contratos ainda em desenvolvimento.
6. Validar proporções de celular e desktop, redimensionamento, texto ampliado,
   teclado, estados de falha e as plataformas efetivamente disponíveis.
7. Registrar o que foi implementado, o que foi testado e o que continua pendente.
   A cada rodada, atualizar decisões e pesquisas com data, fonte, motivo, alcance,
   situação e próximo passo, preservando hipóteses descartadas com seu motivo.

O manual orienta a consistência; as garantias de dados continuam no código,
backend, banco e testes. A implementação deve seguir também o
[contrato de integridade](REGRAS_DE_INTEGRIDADE_E_EVOLUCAO.md).

### 8.1 — Método de planejamento

**Diretriz do usuário, FE-035, 16/10/2026:** trabalhar com prudência, pesquisa,
confirmação de detalhes, comparação de opções, caminho incremental e design
inteligente. Esta seção consolida o método de trabalho, acessível também pelas
instruções de entrada. Registra critérios, decisões, evidências e limites que
outro agente precisa conseguir retomar.

1. **Começar pela tarefa e pelo contexto.** Identificar o que a pessoa pretende
   fazer e a menor etapa útil. Consultar o estado atual, decisões confirmadas e
   contratos do módulo antes de sugerir outro padrão ou uma função nova.
   Investigar também o que os dados permitem trazer à atenção da pessoa e qual
   informação útil ela talvez ainda não saiba que precisa procurar.
   **Preservar a base aceita, FE-042:** decisões confirmadas e estruturas já
   acolhidas são requisitos da próxima rodada. Na home, conservar resumo
   A pagar/A receber, Seu negócio hoje e Precisa da sua atenção. Não substituir
   a página por um recorte de estudo sem identificá-lo e conservar sua referência.
   Conferir a presença desses blocos antes de apresentar uma evolução e registrar
   o que mudou. Ajustes rotineiros não exigem repetir aprovações; remover ou
   substituir uma decisão aceita deve voltar ao alinhamento, com motivo e exemplo.
2. **Investigar a dúvida certa.** Separar conhecimento já registrado de dúvida
   ainda relevante. Pesquisar fontes primárias quando necessário e conferir
   fatos mutáveis. Registrar URL, data, síntese, aplicação ao ZM e limite da fonte.
   Conforme FE-038, incluir links diretos e clicáveis às fontes originais junto
   do aprendizado, com título/autor ou organização e localização relevante
   quando útil. Referência a outro documento interno não substitui esses links.
   Evitar pesquisa repetida sem uma pergunta concreta ou mudança de contexto.
3. **Comparar opções com consequências.** Quando houver alternativas reais,
   explicar adequação à tarefa, leitura no celular, acessibilidade, complexidade
   e integração. Escolher uma recomendação proporcional à rotina da empresa;
   a origem em um grande design system não torna uma opção automaticamente melhor.
4. **Propor um recorte pequeno e coerente.** Separar confirmado, proposto,
   demonstrado e implementado. Conferir significado de valores, disponibilidade
   dos dados, ações e retorno. A apresentação não inventa saldo, permissões,
   confirmação ou garantias que os serviços ainda não oferecem.
5. **Confirmar o que precisa da pessoa.** Perguntar sobre preferência ou rotina
   quando isso mudar materialmente a proposta e a resposta não estiver registrada.
   Avançar no trabalho independente enquanto a dúvida estiver aberta. Não pedir
   aprovação a cada arquivo, repetir escolhas confirmadas ou converter silêncio,
   elogio geral ou movimento de um controle em aprovação de detalhes novos.
6. **Revisar com evidência proporcional.** Agrupar ajustes simples. Uma prévia
   deve responder uma pergunta visual relevante num conjunto pequeno de telas
   e estados, não reaparecer a cada mudança de raio ou texto. Conferir o que foi
   efetivamente mostrado; diferenciar documentação, teste local, simulação,
   aparelho real e integração. No planejamento documental, não gerar evidência
   visual nova apenas para atualizar o registro.
7. **Guardar o aprendizado e deixar a continuação clara.** Atualizar memória,
   manual e plano conforme o que mudou. Registrar decisão, origem, motivo,
   alcance, situação, hipótese descartada e próxima ação. Preservar referências
   históricas sem mantê-las como orientação vigente quando forem superadas.

Neste projeto, **design inteligente** também inclui interpretar os dados,
relacionar fatos, antecipar necessidades e apresentar proativamente informações
úteis no lugar e no momento certos, transmitindo cuidado. Regras, cálculos e
preferências conhecidas podem sustentar essa experiência sem IA.
Clareza, adaptação e continuidade apoiam essa direção, mas não a esgotam.

A [documentação específica de design inteligente](DESIGN_INTELIGENTE_E_ORIENTACAO_AO_USUARIO.md),
FE-036, conserva a intenção completa, pesquisas, aplicações, catálogo de
oportunidades, critérios de relevância, confiança nos dados e contrato de cada
orientação. Consultá-la ao projetar conteúdo e não substituí-la por um resumo.
Ela amplia o planejamento da inteligência informativa; regras particulares e
execução de operações continuam com alinhamento e contratos próprios.

As [primeiras regras de informação útil](REGRAS_DE_INFORMACAO_UTIL_FRONTEND.md),
FE-039/FE-040, detalham vencimentos, estoque mínimo e limitação de custo. Usam
campos/regras conferidos no código, com propostas de mensagem/destino e lacunas
registradas. Próximos vencimentos abrangem os três dias seguintes, com hoje e
atrasadas separados, por escolha explícita do usuário. Não constituem implementação.

**Revisão FE-041:** o usuário pediu ver o planejado após as rodadas documentais.
A [prévia Negócio em foco](referencias_frontend/rodada-negocio-em-foco-2026-10-16/README.md)
reúne essas regras, seus destinos e o percurso financeiro no celular/Windows,
com dados fictícios. Composição, tipografia, fundo e novos textos aguardam
avaliação. Próximo passo é colher o retorno sobre esse conjunto, preservando
as medidas e preferências já confirmadas, antes de ampliar o plano.

O limite de implementação continua o já acordado: alinhar o primeiro incremento
real antes de aplicar a arquitetura nova. Uma vez autorizado esse incremento,
executar seus ajustes rotineiros sem renegociar cada detalhe. Este método não
cria uma nova sequência de aprovações nem substitui as regras de integridade.

## 9. Fontes e revisão das decisões

Referências oficiais consultadas em 15/10/2026:

- [Flutter — arquitetura](https://docs.flutter.dev/app-architecture/guide):
  responsabilidades separadas para interface, estado e dados; adaptar a
  recomendação ao projeto e à complexidade de cada função.
- [Flutter — interfaces adaptativas](https://docs.flutter.dev/ui/adaptive-responsive/general):
  abstrair conteúdo comum e escolher a composição a partir das dimensões disponíveis.
- [Flutter — adaptações de plataforma](https://docs.flutter.dev/ui/adaptive-responsive/platform-adaptations):
  compartilhar conteúdo e lógica preservando decisões de interação de cada plataforma.
- [Apple — navegação por abas](https://developer.apple.com/design/human-interface-guidelines/tab-bars):
  destinos principais reconhecíveis, rotulados e com estado preservado.
- [Apple — materiais](https://developer.apple.com/design/human-interface-guidelines/materials):
  profundidade e materiais usados para estabelecer hierarquia e legibilidade.
- [GOV.UK — prototipagem](https://www.gov.uk/service-manual/design/making-prototypes):
  explorar e compartilhar propostas por interações antes de construir o produto.
- [Nielsen Norman Group — wireflows](https://www.nngroup.com/articles/wireflows/):
  conectar telas e percursos de uso para discutir decisões em seu contexto.

Pesquisa complementar de **16/10/2026**: SAP Fiori para visão geral, IBM Carbon
para estados sem dados e tabelas, Stripe para falhas de comunicação e identidade
de operações. URLs, sínteses, aplicações ao ZM e limites estão na
[pesquisa de front-end financeiro e empresarial](PESQUISA_FRONTEND_EMPRESARIAL_2026-10-16.md).
O [registro posterior de resumo e data](RODADA_FRONTEND_RESUMO_E_DATA_2026-10-16.md)
acrescenta MDN sobre seletores de data e diálogo, o retorno do iPhone e os limites
da nova verificação local.
O [padrão de movimento](PADROES_DE_MOVIMENTO_FRONTEND.md) acrescenta Apple HIG,
Flutter e conferência do SDK local, com limites específicos da redução por plataforma.

As referências informam o projeto; as escolhas acima são adaptadas ao negócio,
com sua situação registrada. A cada decisão, registrar data, motivo, alcance e
situação. Os valores explorados nos controles de uma prévia não devem
ser promovidos automaticamente a tokens definitivos do aplicativo.

Checagem de saúde executada antes de atualizar os documentos em 15/10/2026:
**279 testes backend e 238 testes Flutter aprovados**. Essa evidência corresponde
ao código existente durante a elaboração; não é validação de uma nova interface
ou comprovação de entrega da integração financeira em desenvolvimento.
