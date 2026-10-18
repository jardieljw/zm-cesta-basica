# Botões flutuantes e espaço no final da rolagem

## Nova arquitetura visual — planejamento em revisão

O [manual do front-end](ARQUITETURA_FRONTEND.md), iniciado em 15/10/2026,
concentra a fundação e o mapa das áreas da próxima interface. A prioridade é
mobile em Android/iPhone, com adaptação Windows; as seções implementadas abaixo
continuam sendo a referência do cliente atual.

O [plano de design](PLANO_ARQUITETURA_DE_DESIGN.md), registrado em 14/10/2026,
reúne preferências, componentes existentes, comparação visual, piloto proposto
e pendências funcionais para depois. Ainda não está implementado: o usuário
pediu alinhar a arquitetura antes de qualquer alteração no aplicativo. Os
comportamentos descritos nas seções seguintes continuam sendo a base atual.

## Cards do menu inicial — 15/10/2026

Todos os 12 atalhos do menu inicial usam `UniformNavigationGrid`, compartilhado
em `client/lib/widgets/shared/`. A largura e a altura são iguais entre todas as
seções, inclusive nos atalhos que antes ocupavam uma linha inteira. A grade usa
duas colunas quando a área disponível tem pelo menos 280 px e uma coluna abaixo
disso; um último card sozinho conserva a mesma largura dos demais.

A altura comum é calculada a partir dos maiores títulos e descrições na largura
atual, considerando fonte, idioma, escala de texto e negrito de acessibilidade.
Ícones, títulos e descrições têm alinhamento consistente. O texto pode quebrar
linha sem reticências nem redução automática da fonte. Redimensionar a janela ou
alterar a escala de texto recalcula todas as dimensões; a página continua rolável.

As seções, destinos de navegação e regras de acesso dos módulos são preservados.
Essa apresentação não altera endpoints nem tabelas. O teste
`home_cards_responsive_test.dart` verifica todos os atalhos em larguras de
320/360/390/412/600/1200 px, texto até 200%, redimensionamento, acesso ao último
card e acionamento independente dos cards. Executável e APK não foram recompilados
nesta entrega, conforme solicitado.

## Filtros responsivos — 14/10/2026

As faixas de filtros de Produtos, Tipos de Cesta, Compras, Clientes, Vendas,
Estoque, Extrato do Razão Contábil, Contas a Receber, Dashboard e Relatórios usam
`ResponsiveFilterBar`, em `client/lib/widgets/shared/`. O componente usa `Wrap`,
com espaçamento horizontal e vertical: quando a janela encolhe, os controles
passam para as linhas seguintes, sem depender de arraste horizontal com mouse.
Em janelas amplas, permanecem lado a lado quando couberem. A busca de estoque
ocupa uma linha própria, preservando espaço para digitar. Dashboard e Relatórios
mantêm o alinhamento central. Os filtros avançados de Contas a Receber e os
indicadores de Contas a Pagar também já usam quebra de linha.

As consultas, os filtros enviados à API e os registros no banco são preservados.
Os testes `inventory_filters_responsive_test.dart` e
`page_filters_responsive_test.dart` verificam visibilidade e acesso às opções,
redimensionamento da tela aberta e aplicação dos filtros em larguras de celular
e desktop. A regra vale para faixas de filtros; tabelas têm layout próprio.

## Botões flutuantes

Por preferência explícita do usuário, as sete telas de produtos, tipos de cesta,
clientes, compras, vendas, contas a pagar e receitas mantêm o botão principal
flutuando sobre o conteúdo. Não usar uma barra inferior fixa nessas páginas.

O helper `fabScrollPadding`, em `client/lib/utils/scroll_layout.dart`, acrescenta
espaço somente ao final da lista ou do conteúdo rolável. A área útil da tela fica
inteira disponível; esse espaço adicional só aparece ao chegar ao fim da rolagem.

O cálculo considera a altura do FAB estendido configurada no tema (ou o padrão
Material), a margem inferior de 16 px, uma folga de 16 px e a área segura inferior.
No tema Material 3 padrão, sem área segura adicional, são 88 px. As margens laterais
e superiores anteriores de cada tela foram preservadas.

O botão pode cobrir itens intermediários durante a rolagem, conforme o comportamento
flutuante escolhido. Ao rolar até o fim, o último item e suas ações podem subir
inteiramente acima do botão. O rodapé fixo anterior foi removido.

`client/test/fab_scroll_layout_test.dart` verifica que a lista ocupa a região do
FAB, que o controle do último item não fica sob ele no fim da rolagem e que ambos
podem ser clicados independentemente. Os casos incluem celular, desktop, área
segura, texto ampliado, teclado e botão mais alto configurado pelo tema.

## Contas a pagar — layout responsivo

O resumo, a busca, os indicadores de filtros e os cartões usam uma única rolagem
com `CustomScrollView` e `SliverList` preguiçosa. Apenas a AppBar permanece fixa.
No celular, o resumo destaca A pagar e agrupa Vencido/Valor pago; no desktop,
os três valores ficam em colunas. Os totais continuam relativos às contas exibidas
pela consulta (até 100 registros), e não representam um total geral da empresa.

Os filtros detalhados ficam em `widgets/payables/payable_filters_panel.dart`:
painel inferior no celular e diálogo no desktop. A seleção é um rascunho;
Aplicar consulta o serviço uma vez, Cancelar mantém os filtros anteriores e
Limpar limpa apenas o rascunho. Os indicadores podem ser removidos individualmente.
Mês/ano e intervalo continuam combinados pela API, conforme o contrato existente.
A busca por favorecido é aplicada pelo ícone ou Enter; atualizar não aplica texto
que ainda estava sendo digitado. Respostas antigas não substituem consultas novas.

A ação principal é um FAB circular com + e tooltip localizado Criar conta a pagar.
Usar `fabScrollPadding(context, extended: false)` para considerar seu tamanho no
final da rolagem, inclusive nos estados vazio, erro e carregamento. Não há rodapé fixo.
`widgets/shared/financial_summary_panel.dart` apenas apresenta valores já calculados.
As regras e endpoints de criação, pagamento, cancelamento e recorrência permanecem
os mesmos. `payables_responsive_test.dart` verifica geometria e filtros em larguras
360/412/1200, texto ampliado, teclado, vazio e erro.

## Padronização dos botões de criação

Nas sete telas, o FAB é circular (`CircleBorder`) e mostra apenas o ícone original:
+ em produtos, tipos de cesta e contas a pagar; person_add em clientes;
add_shopping_cart em compras; point_of_sale em vendas; playlist_add em receitas.
O nome da ação continua no tooltip localizado, acessível com mouse ou toque longo.
Os fluxos acionados são preservados. Todos usam `extended: false` no espaço final
para considerar a altura do FAB circular configurada no tema.
