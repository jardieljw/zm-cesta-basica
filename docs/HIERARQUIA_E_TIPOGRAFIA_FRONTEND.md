# Hierarquia de informação e tipografia

Revisão: **16/10/2026**. Versão **0.3 — Leitura recuperada escolhida**, FE-049.
**Decisão vigente FE-049:** o usuário escolheu **Leitura recuperada**, mais agradável
e equilibrada, e rejeitou a orientada como padrão: texto grande e peso espalhado
demais deixavam pouca diferença de ênfase. É contraste de hierarquia visual no
relato, não medição de contraste cromático. A
[revisão integrada](referencias_frontend/rodada-organizacao-2026-10-16/README.md)
usa a recuperada. Os papéis numéricos FE-033/FE-048 abaixo conservam a pesquisa
histórica; **não são a escala escolhida para aplicar ao produto**. Não recomendá-los
novamente como se o retorno não existisse. Família/métricas de cada plataforma
serão validadas na integração, preservando a leitura acolhida.
**Continuação FE-048:** a [comparação integrada](referencias_frontend/rodada-tipografia-2026-10-16/README.md)
aplica estes papéis à fonte recuperada. Leitura orientada e recuperada comparam
a mesma jornada, incluindo nome longo, quantias altas e ampliação do conteúdo.
Novas medidas/família continuam propostas. Os relatos documentais abaixo são
históricos; não significam que a prévia ainda precise ser criada.
O usuário autorizou continuar o planejamento e a pesquisa. Isso não confirma
os novos tamanhos, a família tipográfica ou os arranjos propostos abaixo.
Rodada documental, sem nova prévia, testes de navegador ou mudanças no Flutter.

Complementa o [manual](ARQUITETURA_FRONTEND.md), a [base visual](BASE_VISUAL_FRONTEND.md),
o [catálogo](CATALOGO_COMPONENTES_FRONTEND.md) e a
[memória de decisões e pesquisa](MEMORIA_E_PESQUISAS_FRONTEND.md).
Os valores estão nos [dados de planejamento](TOKENS_VISUAIS_PROPOSTOS.json).

## 1. Objetivo deste recorte

**Complemento FE-036:** a [inteligência informativa do produto](DESIGN_INTELIGENTE_E_ORIENTACAO_AO_USUARIO.md)
define também o que vale trazer à atenção do usuário, a partir dos dados e de
suas necessidades. A hierarquia tipográfica apresenta essa relevância; não
substitui o trabalho de identificar informações úteis e contextualizá-las.

Organizar a leitura para que a pessoa reconheça o contexto, entenda os dados
importantes e encontre a próxima ação. A ênfase acompanha a tarefa; o mesmo
tamanho de letra não deve transformar todo número em indicador principal.
Cada módulo mantém seu significado e seus serviços; os papéis de apresentação
são compartilhados. Não criar um formulário universal com todas as exceções.

Já confirmados: espaço **20** entre grupos de campos, cantos de campos **24**,
cantos de painéis **32** e destaque escolhido nas configurações com azul
**#2866ae** por padrão. Fundo e materiais continuam provisórios. O espaço 20
separa grupos completos, incluindo ajuda/erro quando presentes; não fixa sua altura.

## 2. Hierarquia por família de página — proposta

| Família | Pergunta principal | Informação em evidência | Contexto que precisa acompanhar |
| --- | --- | --- | --- |
| Visão geral | O que está acontecendo no negócio e onde preciso agir? | Resumos com significado definido e acesso às pendências. | Período, recorte, origem e disponibilidade dos dados. Diferença entre recebimentos/pagamentos não é saldo bancário. |
| Lista de Pagar/Receber | Qual é a conta ou venda que procuro? | Identificação reconhecível e saldo em aberto do registro. | Vencimento e situação em texto; vínculo à origem. A lista conserva filtros e ordenação explícitos. |
| Detalhe financeiro | O que compõe este saldo? | Identificação e saldo atual, com vencimento/situação próximos. | Valor original e histórico de pagamentos/recebimentos distinguíveis; origem consultável. |
| Formulário | O que preciso informar para registrar? | Rótulos e escolhas legíveis, integral do saldo atual como padrão. | Data, meio sem seleção antecipada e observação; valor parcial só quando escolhido. |
| Revisão | O que exatamente estou prestes a registrar? | Valor deste registro e pessoa/conta correspondente. | Data, meio e efeito esperado sobre o saldo; opção de voltar e corrigir. |
| Conclusão | O registro foi confirmado e qual é o resultado? | Mensagem do resultado e valor registrado. | Saldo restante e referência/histórico, quando disponíveis. Falta de resposta não autoriza anunciar sucesso. |
| Produtos e estoque | Qual item é este e em que unidade está contado? | Nome reconhecível, quantidade e unidade associadas. | Identificação e campos reais do módulo; custo, quantidade e valor monetário não são intercambiáveis. |
| Configurações | Qual preferência ou recurso estou alterando? | Nome da opção e valor/situação atual. | Consequência relevante da escolha e agrupamento por finalidade. |

O cabeçalho organiza identidade e contexto; não precisa fixar tudo no topo nem
repetir o mesmo número em vários painéis. Ações preservam o FAB sobre o conteúdo
e o espaço de rolagem acordados; esta proposta não cria barra inferior fixa.
Ordenar automaticamente por uma prioridade nova exige alinhamento próprio.

## 3. Exemplo de leitura — sem desenhar uma nova tela

Exemplo fictício de uma conta: fornecedor **Distribuidora Exemplo**, valor
original **R$ 680,00**, pagamentos anteriores **R$ 200,00**, saldo em aberto
**R$ 480,00**, vencimento **16/10/2026**.

- Na **lista**, reconhecer o fornecedor e o saldo em aberto de R$ 480,00,
  com vencimento e situação legíveis.
- No **detalhe**, entender a relação entre os R$ 680,00 originais, os R$ 200,00
  registrados e os R$ 480,00 restantes, sem somar esses valores como um total.
- Ao **registrar integral**, a referência é o saldo atual de R$ 480,00.
- Na **revisão**, o valor deste pagamento é R$ 480,00 e o saldo esperado é
  R$ 0,00. Apenas a resposta confirmada permite comunicar o resultado como efetivo.

Os números são ilustrativos; datas, estados e cálculos reais vêm do domínio.
Registrar um pagamento já feito não significa enviar dinheiro pelo aplicativo.

## 4. Papéis tipográficos — valores iniciais propostos

| Papel | Base / entrelinha | Peso | Uso pretendido |
| --- | --- | --- | --- |
| Título de página | 24 / 30 | 500 | Identificar a página; permitir quebra de nomes longos. |
| Título de seção | 18 / 24 | 500 | Agrupar informações relacionadas. |
| Identificação de item | 16 / 22 | 500 | Pessoa, fornecedor, produto ou documento em uma lista. |
| Texto principal | 16 / 24 | 400 | Conteúdo, leitura de campos e explicações principais. |
| Rótulo de campo | 16 / 22 | 500 | Identificar o campo fora da área de digitação. |
| Apoio e referência | 14 / 20 | 400 | Ajuda, origem e descrição secundária; não esconder avisos importantes aqui. |
| Valor principal | 28 / 34 | 500 | Um valor central contextualizado, como saldo no detalhe. |
| Valor de resumo | 24 / 30 | 500 | Quantias da home e resumos pares; empilhar quando necessário. Proposta demonstrada em FE-048. |
| Valor em lista | 18 / 24 | 500 | Comparar saldos entre registros, sem dominar a identificação. |
| Texto de ação | 16 / 22 | 500 | Nomear a ação com verbo e contexto quando necessário. |

São bases de planejamento, não pixels físicos nem tamanhos determinados pela
Apple/W3C. Na futura amostra web, correspondem à base em CSS px; no Flutter,
mapear para estilos lógicos que respeitem a escala de texto da plataforma.
Entrelinha não é altura fixa de campo ou botão. Esta rodada não valida os
tamanhos visualmente nem substitui os valores das amostras históricas.

**Família proposta:** começar com fonte sem serifa adequada ao sistema, ligada
ao tema e com suporte a português, pesos e números necessários. A família final
continua aberta. Consistência vem dos papéis, medidas relativas e composição;
verificar métricas em cada plataforma antes de assumir resultados idênticos.
Nenhuma fonte ou dependência foi instalada nesta rodada.

## 5. Dinheiro, datas e unidades

Propostas de apresentação para avaliar nas famílias já conhecidas:

- Toda quantia importante tem um rótulo preciso: “Saldo em aberto”, “Valor deste
  pagamento”, “Total da venda”. Evitar “Saldo” sem contexto quando houver ambiguidade.
- Conservar moeda, sinal, centavos e precisão definidos pelos formatadores do
  domínio. Não abreviar quantias críticas para “mil”, esconder dígitos ou
  alterar arredondamento para caber no espaço.
- Quando a fonte permitir, usar algarismos tabulares nas colunas de valores e
  quantias que mudam; isso não transforma nomes, códigos e todo texto em fonte
  monoespaçada. Em tabelas comparativas, propor alinhamento de valores à direita.
- Se a quantia não couber, reorganizar a linha em blocos, mantendo o valor completo.
  Não reduzir automaticamente a letra abaixo da preferência do usuário.
- Quantidades mantêm unidade identificável: unidade, kg e composição de cesta
  não podem perder seu significado ao mudar de página ou plataforma.
- Datas têm finalidade nomeada: vencimento, pagamento e emissão são conceitos
  distintos. Texto relativo como “Vence hoje” complementa a data acessível no detalhe.
- Situações são escritas e não dependem apenas da cor. Destaque escolhido pelo
  usuário não modifica o significado de atraso, erro ou confirmação.

## 6. Adaptação e leitura assistiva — critérios para a revisão futura

1. Nomes, instruções e mensagens podem crescer e quebrar linha. A pessoa deve
   conseguir obter a identificação completa; tooltip não é a única saída no celular.
2. Se texto maior ou largura menor impedir leitura em duas colunas, empilhar
   identificação, valor e contexto. Considerar largura disponível e escala de
   texto, não apenas um modelo de aparelho ou breakpoint fixo.
3. Não limitar a escala do sistema nem usar redução automática de fonte para
   preservar a composição original. Reavaliar a composição antes de cortar conteúdo.
4. Título, rótulo, valor, ajuda e erro precisam de relações semânticas e ordem
   de leitura coerentes. Rótulo persistente e texto digitado não se substituem.
5. Foco, teclado, FAB, barras da plataforma e áreas seguras não podem impedir
   acesso a conteúdo essencial ou à ação correspondente.
6. Documentos A4 têm perfil tipográfico próprio e unidades de impressão. Não
   copiar medidas da tela para PDF nem contrariar os formulários em branco já definidos.

Planejar conferência com português real, nomes longos, quantias grandes e
negativas quando permitidas pelo domínio, ajuda/erro multilinha, tema claro/escuro
e texto ampliado. Referências web: texto a 200% e reorganização em largura
equivalente a 320 CSS px. São verificações distintas; não são receita de escala
linear idêntica no Flutter, nem homologação nativa ou certificação WCAG completa.
Tabelas que realmente precisem de duas dimensões têm exceção específica; ela
não libera o cabeçalho, filtros ou restante da página para transbordar.

## 7. Pesquisa primária, aplicação e limites

Consultas realizadas em **16/10/2026**. Sem transcrição extensa de fontes:

| Fonte | Aprendizado | Aplicação proposta ao ZM | Limite |
| --- | --- | --- | --- |
| [Apple — Get started with Dynamic Type, WWDC24](https://developer.apple.com/videos/play/wwdc2024/10074/) | Estilos de texto e composição devem responder ao tamanho escolhido; exemplos passam de arranjo horizontal a vertical. | Definir papéis semânticos e reorganizar linhas quando o texto cresce. | Lido o texto/transcrição, não teste SwiftUI/UIKit. APIs demonstradas não comprovam comportamento Flutter/iOS. |
| [SAP — Object Page Header](https://developers.sap.com/concepts/fiori-elements-object-page-header/) | O cabeçalho de registro reúne identificação e contexto relevante. | Manter pessoa/documento reconhecível junto do valor e da situação pertinentes à tarefa. | Consultada a página conceitual. Não adotar SAPUI5, suas anotações, densidade ou toda a organização de ações. |
| [W3C — Resize Text, 1.4.4](https://www.w3.org/WAI/WCAG22/Understanding/resize-text.html) | O critério trata ampliação de texto a 200% sem perda de conteúdo/função, com condições e exceções descritas. | Planejar crescimento de texto e controles, em vez de alturas fechadas. | Critério web; leitura documental, sem teste de conformidade nesta rodada. |
| [W3C — Reflow, 1.4.10](https://www.w3.org/WAI/WCAG22/Understanding/reflow.html) | Conteúdo deve se reorganizar na dimensão de referência; partes que exigem duas dimensões têm exceções. | Planejar empilhamento e manter filtros, identificação e ações acessíveis. | Referência de 320 CSS px não equivale a escolher um aparelho ou certificar todo o aplicativo. |

Consulta complementar ao [Material 3 — Applying type](https://m3.material.io/styles/typography/applying-type)
retornou apenas conteúdo indexado sobre papéis de texto; a abertura direta não
forneceu texto legível. Não usar isso para afirmar conferência completa da escala
Material. A abertura direta da HIG Typography também exigiu JavaScript; a fonte
Apple efetivamente lida acima foi a transcrição oficial da WWDC.

**Inferências de projeto:** a escala numérica, a ênfase variável entre lista/
detalhe/revisão, os algarismos tabulares e os exemplos financeiros são propostas
do ZM. Não atribuir esses valores específicos às fontes pesquisadas.

## 8. Situação, verificação e próximo recorte

Entregue agora: pesquisa documentada, hierarquia por família, escala inicial
proposta e critérios de revisão. Nenhuma preferência tipográfica nova é tratada
como aprovação do usuário. Arquivos estruturados e links locais foram conferidos;
não houve nova prévia, execução de navegador ou suítes do aplicativo nesta rodada.

**Continuação FE-034:** a [composição das páginas](COMPOSICAO_DAS_PAGINAS_FRONTEND.md)
detalha esse recorte em documento, incluindo conteúdo longo, situações e retorno.
O conjunto está preparado para futura revisão visual agrupada de composição,
tipografia, fundo e movimento. Nenhuma prévia foi gerada nessa continuação;
novos arranjos/medidas e escolha do piloto real continuam abertos.

## 9. Comparação aplicada à fonte integrada — FE-048

Em continuidade ao encaminhamento FE-047, a
[rodada visual](referencias_frontend/rodada-tipografia-2026-10-16/README.md) conserva
a organização recuperada e compara a escala anterior com os papéis propostos.
O apoio cresce para 14, o corpo/rótulo para 16 e a seção para 18; o valor central
passa de 32 para 28 para equilibrar a leitura. Home usa 24 nos resumos. Fonte
existente conservada para isolar essa decisão, sem escolha final de família.

O crescimento reorganiza pares, linhas e detalhes; título ampliado ocupa a
largura abaixo do retorno. Quantias extremas podem quebrar entre grupos de
milhares, preservando centavos e texto completo. É uma proposta de contingência:
ausência de corte não prova conforto. Apoios e valores não se tornam menos
importantes por precisarem de mais de uma linha.

**Limite explícito:** 100/150/200% ampliam os papéis do conteúdo, sem modificar a
barra. Navegação ampliada global, zoom e escalas reais Android/iOS continuam
pendentes. Preservar a geometria normal não autoriza limitar o texto do sistema;
qualquer conflito da coluna 140 deve voltar com evidência e alternativas.

Pesquisa dirigida em **16/10/2026**: [W3C WAI — Text Spacing, SC 1.4.12](https://www.w3.org/WAI/WCAG22/Understanding/text-spacing.html)
fundamenta testar alterações de entrelinha/espaços sem tratar esses valores como
estilo padrão obrigatório; [WHATWG — The wbr element, 4.5.28](https://html.spec.whatwg.org/multipage/text-level-semantics.html#the-wbr-element)
fundamenta a oportunidade de quebra na amostra web. A aplicação entre grupos de
milhares é inferência do agente, não recomendação financeira dessas fontes.
Não há teste de leitor de tela ou equivalência automática no Flutter.

Origem, diferenças entre variantes, fontes, casos, resultados e limites estão
na pasta da rodada. Após a apresentação, registrar o alcance real do retorno;
nenhum ajuste de controle ou silêncio confirma cada medida proposta.
