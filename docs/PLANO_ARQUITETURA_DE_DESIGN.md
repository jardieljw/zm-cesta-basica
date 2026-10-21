# Plano da nova arquitetura de design

**Entrega FE-055 — 17/10/2026:** integração principal concluída e build Windows
Release gerado; 334 testes Flutter, 436 de backend e análise sem pendências.
Ver [evidências finais](validacoes_frontend/fe-055-integracao-2026-10-17/README.md).
Não equivale à certificação visual de todas as telas/aparelhos.

**Diretriz FE-055 preservada:** integração fiel à referência
FE-052, após rejeição do usuário à interface intermediária. Comparação de todas
as telas, mesmos tamanho/tema/escala/dados; corrigir divergências visuais, não
apenas falhas funcionais. Retomar pelo [guia de integração](INTEGRACAO_INTERFACE_APROVADA.md)
e pela memória. Não publicar no Sites: pedido revogado antes de criação.

**Prioridade vigente FE-054 — 17/10/2026:** [Receber revisado](PILOTO_RECEBER_REVISADO.md)
entrega o segundo percurso real e compartilha apresentação/retomada com Pagar.
Lista financeira compacta, venda de origem e saldo civil usam serviços reais.
Continuar pela organização das áreas principais e seus resumos, conservando
FE-052/Leitura recuperada. Não voltar à descoberta visual nem criar aprovações
para ajustes rotineiros autorizados. Prévia, código, build e instalação são
evidências distintas. Os relatos FE-053 e anteriores abaixo são históricos.

Revisão: **16/10/2026**. Situação: **rascunho para alinhamento com o usuário**.

**Prioridade atual FE-053:** [primeiro piloto real de Pagar](PILOTO_PAGAR_REVISADO.md)
implementado incrementalmente após “Show vamo embora”. Fluxo completo, retomada,
precondição de saldo e data civil usam API/serviços reais e testes isolados.
Continuar por Receber e depois pelas áreas principais; não reiniciar descoberta
ou criar aprovações para cada ajuste rotineiro do recorte autorizado. Tema e
navegação globais continuam por integrar; versão instalada não foi substituída.

**Consolidação visual FE-052:** revisão agrupada de acabamento concluída na
[fonte integrada](referencias_frontend/rodada-acabamento-2026-10-16/README.md):
vidro suave, cores da referência inicial, extrato e filtros recolhidos. Não
repetir descoberta ou novas comparações de tipografia. Continuar para a integração
recortada pelas jornadas FE-050; não atribuir ao HTML capacidades de envio real.
Recomendação de primeiro piloto mantém Pagar sobre título existente; tratar os
contratos concretos sem aplicar tema/navegação globalmente como efeito colateral.

**Consolidação FE-050:** jornadas e estados financeiros consolidados no
[contrato de preparação do piloto](JORNADAS_FINANCEIRAS_E_PRONTIDAO_DO_PILOTO.md),
com diferenças verificadas entre demonstração e código. Fechar os contratos de
envio estável, saldo revisado, data, atraso e consultas; alinhar o primeiro
incremento real pelo recorte documentado. Recomendação do agente: Pagar sobre
título existente. Sem nova prévia ou mudança Flutter/API; FE-049 permanece a
referência visual acolhida após “SHOW, VAMOS PROSSEGUIR”.

**Decisões FE-049:** consolidar a organização acolhida e concluir as
jornadas/estados e seus contratos. Usuário escolheu Leitura recuperada, pediu
home curta com Dia/Semana/Mês, moveu resultado para a área de vendas e escolheu
**Negócio** como seu novo nome. A
[revisão integrada](referencias_frontend/rodada-organizacao-2026-10-16/README.md)
reúne esse ajuste e conserva os caminhos anteriores. Não reabrir a disputa de
fontes/pesos ou voltar a estudos parciais. Próximas lacunas devem ser concretas;
piloto real, versionamento e integração continuam etapas próprias.

**Histórico FE-048:** avaliar a
[comparação de tipografia e hierarquia](referencias_frontend/rodada-tipografia-2026-10-16/README.md),
criada a partir da fonte integrada recuperada, conforme a continuação FE-047.
Recomendação do agente: Leitura orientada, com rótulos e apoios mais legíveis e
ênfase proporcional à tarefa. Comparar com Leitura recuperada; não inferir
aceitação de medidas/fonte pelo simples uso dos controles. Concluir este
alinhamento antes de tratar os próximos detalhes visuais e consolidar o piloto.
Sem nova descoberta, recuperação repetida, Flutter/API ou commit geral.

**Histórico FE-046:** revisar a
[prévia integrada recuperada](referencias_frontend/rodada-recuperacao-integrada-2026-10-16/README.md),
criada após autorização do usuário e verificada localmente contra o mapa original.
A [auditoria](AUDITORIA_CONTINUIDADE_FRONTEND_2026-10-16.md) preserva a falha e a
matriz de acordos; o [registro atual](REFERENCIA_ATUAL_FRONTEND.json) identifica
a candidata integrada para a continuação. Barra, hierarquia, destinos e contexto
foram recuperados na prévia; retorno ainda pendente. Próximo passo é avaliar
essa recuperação antes de ampliar o design. Sem Flutter/API ou commit nesta rodada.
Os relatos de rodadas abaixo são históricos, não a prioridade vigente.

**Escopo original do planejamento, antes de FE-053:** esta etapa autorizava pesquisa, planejamento e prévias de comparação. Não autorizava
implementar o novo tema, alterar telas, mudar regras financeiras ou distribuir
uma versão. As fases abaixo são propostas; só avançar para código depois do
alinhamento do plano e da aprovação explícita do primeiro incremento.
Esse alinhamento foi recebido para Pagar em FE-053, conforme o registro vigente;
não usar este parágrafo histórico para pedir nova autorização do mesmo recorte.

**Atualização de escopo em 15/10/2026:** o
[manual da arquitetura de front-end](ARQUITETURA_FRONTEND.md) passa a concentrar
as decisões e padrões permanentes em elaboração; este arquivo mantém o plano
e o estudo inicial de filtros. O usuário pediu projetar a estrutura completa
por partes, com prioridade Android/iPhone e adaptação Windows. A organização em
Início, Financeiro, Vendas, Estoque e Mais, a direção visual e a visão geral foram
aceitas como base na demonstração navegável. A abertura escolhida é a visão geral
do negócio com acesso direto ao Financeiro. O próximo recorte de planejamento é
um percurso cotidiano em Pagar: localizar uma conta, entender seu detalhe,
registrar um pagamento realizado, conferir e acompanhar saldo/histórico. Será
demonstrado em prévia com dados fictícios, antes do piloto de implementação.
A [rodada de Pagar](RODADA_FRONTEND_PAGAR_2026-10-15.md) tem prévia verificada;
seu retorno foi registrado na revisão de 16/10 abaixo.
**Retorno de 16/10:** conferência aceita; integral do saldo atual passa a ser o
padrão, com parcial opcional e revelação suave do campo. O usuário pediu curvas
mais amplas. A [rodada revisada](RODADA_FRONTEND_INTEGRAL_2026-10-16.md) demonstra
esse comportamento e o acabamento novo; medidas ainda em avaliação.
A revisão posterior da data trata o transbordamento mostrado no iPhone; ver
[correção e limites de verificação](referencias_frontend/correcao-data-2026-10-16/README.md).
Contas a Pagar e Contas a Receber integrarão a mesma área financeira, preparada
para a evolução de importações. Consultar o
[plano financeiro](PLANO_IMPORTACAO_E_CONCILIACAO_FINANCEIRA.md) e revalidar seus
contratos em desenvolvimento. A aprovação da prévia como referência visual não
fixa uma variante, paleta ou medida final, nem autoriza implementação global.

**Pesquisa empresarial de 16/10:** o usuário pediu projetar com o rigor de uma
grande aplicação financeira, fiscal e empresarial, continuando a pesquisa e o
registro dos aprendizados. A [nova rodada de pesquisa](PESQUISA_FRONTEND_EMPRESARIAL_2026-10-16.md)
documenta fontes primárias, critérios de informação e limites. O recorte
Financeiro → Pagar hoje → lista filtrada → origem da conta foi autorizado pelo
usuário na mensagem seguinte, pedindo antes corrigir a data ainda cortada no
iPhone. A [nova rodada visual](RODADA_FRONTEND_RESUMO_E_DATA_2026-10-16.md)
entrega a amostra com calendário próprio e os três estados de consulta. Está
verificada localmente; data no aparelho, hierarquia e acabamento em avaliação.
Receber e os demais percursos continuam no plano; não há autorização de código
no aplicativo.

**Rodada seguinte em 16/10:** a amostra de resumo/data recebeu retorno
ótimo/perfeito e o usuário pediu continuar. Em pergunta específica, confirmou
que geralmente os clientes quitam o fiado inteiro. A
[rodada de Receber](RODADA_FRONTEND_RECEBER_2026-10-16.md) demonstra integral do
saldo atual por padrão e parcial opcional, com vínculo à venda preservado. O
[padrão de movimento](PADROES_DE_MOVIMENTO_FRONTEND.md) documenta animações
durante o planejamento, com implementação futura no piloto. Avaliar a nova
jornada e os efeitos, depois consolidar componentes/estados mínimos.
**Retorno posterior (FE-024):** o usuário aceitou a demonstração de Receber e
movimento como referência. O próximo recorte proposto é o catálogo mínimo de
componentes e estados, ainda em planejamento.

**Rodada do catálogo (FE-025):** o usuário pediu continuar. O
[catálogo mínimo](CATALOGO_COMPONENTES_FRONTEND.md) foi documentado e demonstrado
com campos/escolhas, ações/respostas e resumo/lista. Registra responsabilidades,
estados, fontes e o que aproveitar da base Flutter. Os exemplos de consulta
anterior e recuperação de confirmação são simulações, com contrato real pendente.
**Retorno posterior (FE-026):** “Tá ótimo”, com elogio à elegância, aparência e
arquitetura. Direção e apresentação do catálogo aceitas como referência.
Próximo recorte proposto: alinhar o primeiro conjunto de papéis visuais; depois
alinhar o piloto. A etapa continua sendo planejamento, com medidas e contratos
técnicos ainda por formalizar.

**Rodada atual (FE-027):** novo pedido para continuar, preservado na retomada
após interrupção. A [base visual](BASE_VISUAL_FRONTEND.md) demonstra pares de cor,
formas e espaço compartilhados, com [valores propostos](TOKENS_VISUAIS_PROPOSTOS.json).
Inclui pesquisa de contraste e revisão da mudança de tema para conservar leitura.
Aguardar retorno da combinação; depois alinhar hierarquia tipográfica. Sem
migração do tema do aplicativo ou início do piloto.

**Retorno FE-028/FE-029:** espaço entre campos em **20** confirmado; destaque
configurável nas configurações do aplicativo, com azul original #2866ae como
padrão. Outros ajustes testados não são escolhas finais. O relato de controles
sem efeito gerou a [rodada de correção](RODADA_FRONTEND_AJUSTES_2026-10-16.md),
com reprodução e teste do mecanismo original. **FE-030** confirma depois campos
24 px e painéis 32 px. A pergunta sobre movimento compartilhado foi esclarecida,
sem escolha de modo. Avaliar fundo e então tipografia; o trabalho continua
limitado ao plano e à prévia.

**Continuidade do trabalho:** consultar a
[memória de decisões, pesquisas e aprendizados](MEMORIA_E_PESQUISAS_FRONTEND.md)
e as [prévias preservadas](referencias_frontend/README.md). As seções de diagnóstico,
piloto e sequência abaixo conservam o estudo inicial de filtros. Contas a Receber
continua candidato anterior, a reavaliar; a etapa atual é a base visual do
catálogo derivado de Pagar e Receber, ainda em planejamento.

## 1. Resultado pretendido e preferências já registradas

**Ponto atual de revisão, FE-041:** depois das rodadas de especificação,
o usuário pediu a apresentação visual. A [prévia conectada Negócio em foco](referencias_frontend/rodada-negocio-em-foco-2026-10-16/README.md)
reúne vencimentos, estoque mínimo, explicação de resultado e jornada financeira
no celular/Windows. Colher retorno sobre utilidade, prioridade e percurso antes
de mais detalhamento. Não representa implementação nem escolha do piloto real.

**Direção de produto ampliada, FE-036:** seguir a
[documentação específica de design inteligente](DESIGN_INTELIGENTE_E_ORIENTACAO_AO_USUARIO.md).
Projetar também quais informações os dados permitem antecipar e trazer ao
usuário, em quais telas e com que benefício, e não apenas sua apresentação.
Antes da próxima revisão agrupada, especificar poucas oportunidades confiáveis
e ligá-las às jornadas existentes. FE-039/FE-040 detalham as
[três primeiras regras](REGRAS_DE_INFORMACAO_UTIL_FRONTEND.md), com próximos
vencimentos de três dias confirmados e lacunas de integração identificadas.
Candidatas e arquitetura são propostas;
o princípio de orientação proativa foi explicitamente confirmado pelo usuário.

Criar uma identidade moderna para ZM Cesta Básica, com controles arredondados,
profundidade perceptível, hierarquia de texto e resposta animada às interações.
O padrão deve ser reutilizável sem reconstruir cada página, mantendo a separação
entre apresentação, serviços do cliente, regras do backend e persistência.

Preferências fornecidas pelo usuário:

- Painel de filtros alinhado na própria página, com resumo e lista usando a
  mesma largura e margens. As opções de cada página dependem de seu domínio.
- Espaçamento de campos de 24 px e cantos de painéis de 16 px, escolhidos na
  prévia anterior. São referências para a próxima revisão, não um tema global
  já aprovado. No Flutter, converter a intenção para unidades lógicas.
  Em 16/10 o usuário pediu mais arredondamento: não manter 16 como padrão final.
  A amostra posterior testou painéis 32 e campos 28, além de controles em cápsula.
  A escolha atual é espaço 20 (FE-028), campos 24 e painéis 32 (FE-030),
  substituindo as referências anteriores para esses papéis.
- Seleções por opções reais; cliente e cesta não devem exigir memória de nomes
  nem digitação de identificadores. Busca ajuda a encontrar a opção.
- Períodos escolhidos em calendário; valores com formatação automática.
- Rótulos diretos, como Em aberto, Parcial, Vencidas, Pagas e Canceladas;
  substituir jargão visível, como Títulos, por Contas quando conservar o sentido.
- Texto principal e explicação com hierarquia diferente. Exemplo: Confirmada
  em destaque; Aumenta o estoque em estilo secundário, legível.
- Animações discretas para escolhas, abertura de seleções e mudanças de altura;
  preservação de foco, preenchimento e preferência de redução de movimento.
- Prioridade mobile em Android e iPhone, com experiência adaptada para Windows.
  A base inspecionada ainda contém somente projetos nativos Android e Windows;
  a integração e validação de iOS são entregas a realizar.
- Preservar o FAB e o espaço no fim da rolagem. A página principal será revista
  depois; não incluí-la automaticamente no primeiro incremento.

## 2. Direções visuais a comparar antes de decidir

O usuário pediu comparar as duas direções em uma prévia antes de escolher.

**Revisão solicitada na comparação:** oferecer modos claro (fundo branco),
escuro (fundo preto), personalizado e seguir o chat; separar cor de fundo da
cor de destaque. A direção Vidro deve demonstrar transparência e desfoque
ajustáveis. Os controles de espaçamento e cantos precisam continuar funcionando
depois de restaurar escolhas. Esses ajustes pertencem à prévia de planejamento;
a direção final e a entrega de temas no aplicativo continuam em discussão.

| Direção | Composição e materiais | Interação a avaliar |
| --- | --- | --- |
| Camadas suaves | Resumo integrado, painéis sólidos, bordas discretas, sombras suaves e controles arredondados. | Seleções que se expandem junto ao campo e movimentam o restante do conteúdo suavemente. |
| Vidro nos controles | Resumo em cartões separados, grupos de controles com profundidade maior e acabamento luminoso; dados sobre superfícies legíveis. | Menus elevados sobre o conteúdo, abertura suave e resposta de relevo ao pressionar. |

A prévia usa dados fictícios identificados e não acessa API ou banco. Serve para
comparar composição, acabamento e uso; não comprova desempenho no Flutter nem
reproduz o material nativo da Apple.

Referências consultadas em 14/10/2026:

- [Apple: Materials](https://developer.apple.com/design/human-interface-guidelines/materials):
  profundidade e hierarquia; Liquid Glass concentrado em controles e navegação,
  com uso moderado. A direção proposta para ZM é uma adaptação desses princípios.
- [Apple: Adopting Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass):
  formas mais arredondadas e controles que respondem às interações.
- [Apple: Pickers](https://developer.apple.com/design/human-interface-guidelines/pickers):
  seleção de valores e datas por controles adequados ao conteúdo.
- [Apple: Motion](https://developer.apple.com/design/human-interface-guidelines/motion):
  movimento como resposta e comunicação de estado.
- [Microsoft: Materials in Windows](https://learn.microsoft.com/en-us/windows/apps/design/signature-experiences/materials):
  materiais com funções diferentes, incluindo Acrylic em superfícies transitórias.
- [Android: Material Design 3](https://developer.android.com/develop/ui/compose/designsystems/material3):
  sistema de tema, formas, tipografia, componentes e movimento. É referência
  visual; não implica migrar o cliente Flutter para Compose.

## 3. Diagnóstico inicial do código — inspeção de 14/10/2026

| Base existente | O que preservar ou evoluir no plano |
| --- | --- |
| `client/lib/main.dart` | Tema Material 3 claro, azul, definido diretamente no ponto de entrada. Extrair a definição sem trocar silenciosamente o tema de todas as telas. |
| `widgets/shared/responsive_filter_bar.dart` | Resolve acesso a filtros rápidos com Wrap; manter para grupos curtos. Não usá-lo como única organização de formulários detalhados. |
| `widgets/shared/animated_reveal.dart` e `animated_content_size.dart` | Já centralizam transições de aproximadamente 220 ms e redução de movimento. Evoluir a base existente quando necessário. |
| `widgets/shared/financial_summary_panel.dart` | Apresenta métricas monetárias já calculadas. Não passar contagens como se fossem centavos; compor ou estender com tipos de métricas explícitos. |
| `widgets/payables/payable_filters_panel.dart` | Já distingue rascunho de filtros e aplicação; hoje usa painel inferior no celular e diálogo no desktop. Reaproveitar o comportamento sem trocar sua composição automaticamente. |
| `utils/formatters.dart`, `l10n/` e `utils/scroll_layout.dart` | Manter formatação, traduções e espaço para FAB centralizados. Máscara de entrada monetária ainda precisa de contrato próprio. |
| `views/receivables_view.dart` | Calendários já existem. Cliente e cesta são campos de texto usados como IDs; status e vencimento são escolhas independentes; resumo e filtros precisam de composição comum. |

A inspeção mostrou oportunidades reais de reutilização. Não há motivo para
reescrever a arquitetura do backend nem introduzir uma biblioteca de UI nesta
etapa. Compatibilidade dos efeitos e eventual necessidade de dependências serão
avaliadas depois da escolha visual.

## 4. Arquitetura de apresentação proposta

| Camada | Responsabilidade | Local sugerido; nomes ainda provisórios |
| --- | --- | --- |
| Tokens | Cores semânticas, espaçamentos, formas, elevação, tipografia e movimento. | `client/lib/theme/` |
| Tema | Traduz os tokens para ThemeData e temas de campos, botões, menus, cartões e calendários. | `client/lib/theme/app_theme.dart` |
| Primitivos | Campo com rótulo/ajuda/erro, superfície, seletor, campo monetário e seletor de período. | `client/lib/widgets/shared/` |
| Composições | Cabeçalho, resumo, filtros rápidos, grade de filtros detalhados e ações. | `client/lib/widgets/shared/` |
| Adaptadores de tela | Opções, valores selecionados, rascunho/aplicação e mapeamento para cada serviço. | Tela ou módulo correspondente; extrair estado somente se reduzir complexidade real. |
| Serviços e domínio | Consultas, validação comercial e gravações pelos contratos existentes. | Serviços atuais do cliente e do backend. |

Os componentes recebem dados e callbacks; não buscam diretamente na API, não
abrem SQLite e não decidem o significado comercial de um status. Cada módulo
mantém seu modelo de filtro tipado. Não criar um formulário universal baseado
em mapas que concentre todas as regras e exceções do aplicativo.

### Tokens a fechar na revisão

- Paleta: FE-028 confirma azul original #2866ae por padrão e destaque escolhível
  nas configurações. Fechar os demais papéis semânticos e pares de aparência.
- Formas: a referência inicial de painéis 16/campos 14–16 foi superada pelo pedido
  de 16/10 por mais curvas. FE-030 confirma painéis 32/campos 24; cápsulas
  em controles de uma linha e ações continuam como direção. Validar a tradução
  em unidades lógicas no piloto; não aplicar um raio único
  a todo elemento nem tratar esses números como exigência da Apple.
- Espaçamento: escala compartilhada, com 20 nos grupos de campos (FE-028); margens e
  espaçamento interno menores no celular quando necessário, sem comprimir texto.
- Tipografia: título, valor, rótulo, opção e descrição com hierarquia definida;
  descrição em peso regular e tom secundário, sem depender de itálico ou cor.
  A [proposta FE-033](HIERARQUIA_E_TIPOGRAFIA_FRONTEND.md) registra pesquisa,
  papéis, bases numéricas e critérios de adaptação. Não há confirmação dos novos
  tamanhos/família nem nova prévia nesta rodada. A composição das famílias foi
  detalhada em FE-034 para revisão conjunta; agrupar ajustes conforme FE-032.
- Profundidade: escolher a direção na prévia; sombras, luminosidade e eventual
  transparência devem ter alternativa sólida e custo medido nas plataformas.
- Movimento: resposta curta ao pressionar e transições de cerca de 200–250 ms
  para conteúdo condicionado. Confirmar valores pela prévia e pelo piloto.
- Tema escuro: preparar cores semânticas; decidir sua entrega separadamente.
  O cliente hoje possui apenas o tema claro configurado.

### Comportamentos compartilhados a especificar

**Continuação FE-034:** a [composição das páginas](COMPOSICAO_DAS_PAGINAS_FRONTEND.md)
organiza os blocos de lista, detalhe, registro e revisão e propõe preservação de
contexto, rascunho e retorno. Inclui alternativas e limites de recuperação/
concorrência para o piloto. Próxima revisão visual: conjunto conectado com
tipografia, fundo e movimento pendentes, sem nova geração nesta rodada.

1. **Seleção:** listas curtas sem busca; listas extensas com busca e seleção de
   cadastro real. Exibir nome e identificação secundária quando houver homônimos;
   enviar ID. Histórico precisa encontrar cadastros inativos e mais de 100
   clientes, usando busca/paginação existentes, sem limitar à primeira página.
2. **Datas:** rótulo persistente, resumo do intervalo e calendário. Abrir com
   período atual; cancelar preserva a seleção; confirmar atualiza o rascunho.
   Validar início/fim e documentar fuso e limites inclusivos. Preservar o contrato
   atual da API; eventual correção de fronteiras temporais terá análise própria.
3. **Moeda:** prefixo e milhares automáticos; referência proposta `1234,50` →
   `R$ 1.234,50`, sem exigir ponto. Manter cursor, colagem e edição; distinguir
   campo vazio de zero. Parser compartilhado em centavos inteiros e validação de
   mínimo ≤ máximo, sem tratar entrada inválida silenciosamente como zero.
4. **Aplicação:** proposta para formulário detalhado: editar prepara rascunho;
   Aplicar consulta; Limpar limpa rascunho; Atualizar repete a consulta aplicada.
   Filtros rápidos podem aplicar imediatamente quando já fizer parte do fluxo.
   Esta alteração de interação precisa ser validada no piloto, pois hoje Limpar
   em Contas a Receber também consulta imediatamente.
5. **Estados:** normal, foco, seleção, pressionado, desabilitado, carregando,
   vazio e erro. Erro não vira saldo zero; respostas antigas não substituem
   novas consultas; abrir/fechar menus preserva foco e seleção.
6. **Adaptação:** grade pela largura disponível e escala do texto; uma coluna
   quando duas não couberem. Mouse/teclado, toque, teclado virtual e áreas
   seguras afetam interação. Windows estreito também precisa refluência.

## 5. Piloto inicialmente proposto: Contas a Receber

O piloto depende do alinhamento do mapa geral e da área Financeiro, conforme a
revisão de 15/10/2026. Sua escolha e escopo serão reavaliados nessa organização;
ainda não é uma tarefa de implementação.

- Resumo, filtros e resultados no mesmo eixo, com uma rolagem de conteúdo.
- Preservar total de saldo e contagens atuais, referentes à consulta retornada,
  que hoje é limitada a 100 registros. Não apresentar como total global.
- Painel alinhado, dividido em situação, períodos, cliente/cesta e valores.
- Cliente e cesta com seletores reais, calendário para os dois períodos e
  máscara monetária. Manter os filtros de valor sobre **valor original**, como
  o backend já faz; não reinterpretá-los como saldo restante.
- Rótulos propostos: Contas em aberto, Contas parciais e Contas na listagem.
  Evitar mudar quantidade de contas para quantidade de pagamentos.
- Situação em uma única seleção: Todas, Em aberto, Parcial, Vencidas, Pagas,
  Canceladas. Vencidas é um filtro derivado; não é novo status persistido.

| Seleção proposta | Contrato existente da consulta |
| --- | --- |
| Todas | Sem status; `overdue_only=false`. |
| Em aberto / Parcial / Pagas / Canceladas | Status `OPEN` / `PARTIAL` / `PAID` / `CANCELED`; `overdue_only=false`. |
| Vencidas | Sem status específico; `overdue_only=true`, que inclui OPEN e PARTIAL com vencimento ultrapassado. |

Uma conta parcialmente paga pode estar vencida. Uma conta quitada depois do prazo
pode ter histórico de atraso, mas não deve aparecer como dívida vencida atual.
O backend já limita o filtro vencido a OPEN/PARTIAL. Unificar a escolha na
interface evita a combinação Pagas + Vencidas sem alterar registros.

Revisar os nomes e a hierarquia dos indicadores no piloto sem alterar cálculos,
baixa, recebimento ou estorno. Ações financeiras permanecem com seus serviços.

## 6. Adoção posterior por página

| Página | Padrão a reutilizar | Filtros e pontos próprios |
| --- | --- | --- |
| Produtos e insumos | Busca, filtros rápidos, cartões e ações. | Cadastro; não adicionar período sem finalidade definida. |
| Tipos de cesta | Busca, seleções, cartões e ações. | Cadastro; coordenar com trabalho de cestas no outro chat. Não alterar suas funcionalidades aqui. |
| Clientes | Busca, situação e seleção por cadastro. | Ativos/inativos; cadastros usados no histórico continuam consultáveis. |
| Posição de estoque | Busca, filtros rápidos e lista responsiva. | Saldo atual; período só se houver uma consulta histórica específica aprovada. |
| Vendas | Grade, seletor de período e situação. | Tela hoje filtra status e condição de pagamento (`payment_mode`); não confundir com forma/meio. `SaleService` e API já aceitam início/fim. Acrescentar o controle em incremento funcional definido. |
| Compras | Grade, período, situação e busca. | API já aceita início/fim; `PurchaseService.getPurchases` ainda não os expõe. Planejar integração, não filtrar só os itens da página no cliente. |
| Histórico de movimentações | Período e tipo de movimento. | Serviço aceita datas; tela hoje envia produto/tipo. Integrar consulta em incremento próprio. |
| Contas a Pagar | Tema dos controles, resumo e seletores. | Já tem composição responsiva e filtros em rascunho. Decidir se migra para painel alinhado após comparar o piloto; não trocar automaticamente. |
| Dashboard e Relatórios | Seletores de período, hierarquia e ações. | Hoje possuem Hoje, Data, Intervalo, Mês, Ano e Tudo. Preservar seus contratos e sentido das métricas. |
| Formulários | Campos, seleções, descrições, moeda e movimento. | Usam os mesmos primitivos; não precisam de barra de filtros. Priorizar depois das listas e do piloto. |
| Página principal | Tokens e componentes quando autorizada. | Revisão visual adiada pelo usuário; globalizar o tema não deve redesenhá-la por efeito colateral. |

## 7. Problemas funcionais de compras registrados para depois

Estes itens foram relatados pelo usuário e não são corrigidos nesta etapa.

| Item | Trabalho futuro e confirmação necessária |
| --- | --- |
| Rascunho sem editar/excluir na lista | Verificar edição, descarte ou cancelamento permitido pelo domínio. Backend já cancela rascunho; a lista inspecionada só mostra cancelar para CONFIRMED. Não prometer exclusão física sem analisar vínculos. |
| Rascunho exibido como Pago/liquidado | Reproduzir e distinguir intenção de pagamento de pagamento realizado. A lista usa `payment_mode` para o texto; a rotina financeira se destina à confirmação. O relato não comprova que houve débito indevido no banco. |
| Condição de pagamento em rascunho | Proposta do usuário: pedir pagamento ao confirmar. Definir apresentação, preservação de rascunhos antigos e contrato antes de mudar persistência. |
| Boleto sem data clara | Hoje o vencimento aparece pela condição CREDIT_TERM, não pela forma BOLETO. Confirmar depois: vencimento do boleto, data efetiva do pagamento ou ambos em seus momentos respectivos. Boleto pode já estar pago; o meio não determina sozinho a situação. |
| Data da compra não selecionável | Avaliar data comercial da compra separadamente de criação/auditoria, filtros e pagamento. Preservar datas existentes. |
| Pago/liquidado e Pendente/em aberto | Proposta de simplificação visível: Pago e Em aberto. Verificar sentido no domínio e textos antes de substituir. |
| Confirmada — aumenta estoque com mesmo destaque | O componente de opção com descrição secundária deve resolver o padrão visual; a regra de estoque continua no backend. |

## 8. Sequência de execução e pontos de revisão

Aplicar o [método de planejamento da seção 8.1 do manual](ARQUITETURA_FRONTEND.md),
explicitado em FE-035 e ligado às instruções de entrada dos agentes. O
[roteiro de revisão conjunta](COMPOSICAO_DAS_PAGINAS_FRONTEND.md) prepara a próxima
prévia com perguntas e limites concretos; não houve geração nesta continuação.

| Etapa | Entrega | Condição para avançar |
| --- | --- | --- |
| Alinhamento atual | Este plano e comparação de duas direções. | Usuário escolhe direção e revisa pendências; sem código de produção. |
| Especificação visual | Paleta, tokens, estados de controles e exemplos de menu, calendário, moeda e texto em desktop/celular. | Aparência e comportamento acordados antes de programar. |
| Fundação compartilhada | Tema extraído e primitivos mínimos usados pelo piloto. | Aprovação explícita deste incremento; tema do piloto limitado ao seu escopo. Sem mudança global de `ThemeData` enquanto outras telas não forem revisadas. |
| Piloto Contas a Receber | Composição, seleções e mapeamento de filtros definidos acima. | Testes, revisão visual e uso com janela estreita/desktop aprovados. |
| Adoção gradual | Grupos de páginas: cadastros/estoque; históricos; financeiro/relatórios; formulários. | Escopo de cada grupo definido e validado; datas ausentes como incrementos próprios. |
| Consolidação | Remover estilos duplicados já migrados, documentar padrões finais e planejar tema global. | Regressão visual das páginas restantes; home e tema escuro conforme decisão específica. |

Cada entrega deve ser revisável e reversível no código, preservando alterações
locais dos outros chats. Não fazer migração visual de todas as páginas em uma só
mudança. Novas dependências, backend e banco só entram se um incremento específico
demonstrar a necessidade e tiver seu escopo alinhado.

## 9. Critérios de aceitação da futura implementação

- Mesmas margens entre resumo, filtros e lista; sem campos cortados ou ações
  inacessíveis ao redimensionar com a tela aberta.
- Validar larguras 320/360/412/768/1200, textos ampliados, nomes longos, teclado
  virtual, mouse/teclado e redução de movimento. iPhone exige validação futura
  no ambiente da plataforma, além de uma prévia de tamanho.
- Calendários e menus com foco correto; Esc/voltar cancela; seleção identificável
  por texto/marca além da cor; leitura acessível e alvos de toque adequados.
- Pagas + Vencidas impossível na escolha; vencidas inclui parcial pendente;
  cliente/cesta selecionados enviam IDs corretos e incluem opções históricas.
- Moeda mantém centavos exatos, cursor/colagem e valores vazios; intervalo de
  datas e limites monetários são validados antes da consulta.
- Aplicar, Limpar, Atualizar e erro seguem o contrato acordado; respostas antigas
  e falhas não produzem números ou estados falsos.
- Todas as strings do Flutter em `context.l10n`; formatos pelo catálogo e
  utilitários centrais; componentes compartilhados sem regra financeira.
- Medir fluidez das transições e custo dos efeitos em Windows e Android.
  Legibilidade permanece com efeitos reduzidos ou acabamento sólido.
- Executar `flutter analyze`, testes apropriados e suítes completas antes da
  entrega de código; compilar somente os alvos acordados para distribuição.

Base verificada antes deste registro: **220 testes backend e 165 testes Flutter
aprovados em 14/10/2026**. São testes do código existente, não validação da nova
arquitetura visual. Nenhum widget de produção foi implementado nesta etapa.

## 10. Decisões ainda abertas

1. Escolher Camadas suaves, Vidro nos controles ou combinar partes das prévias.
2. Confirmar paleta, hierarquia, formas e intensidade de profundidade.
3. Validar a interação proposta de rascunho, Aplicar, Limpar e Atualizar.
4. Definir se tema escuro fica para uma fase própria e quais páginas migram após
   o piloto. Confirmar separadamente a futura revisão da página principal.
5. Ao retomar compras, esclarecer datas do boleto e o comportamento de pagamento
   em rascunhos; editar e excluir rascunhos foi implementado em 20/10/2026.

As próximas revisões devem atualizar este documento com decisão, data e escopo,
sempre distinguindo preferência, proposta aprovada e comportamento implementado.
