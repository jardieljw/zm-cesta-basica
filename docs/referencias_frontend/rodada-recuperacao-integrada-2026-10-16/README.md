# Recuperação da prévia integrada — 16/10/2026, FE-046

**Situação: demonstração para revisão do usuário.** Após a auditoria FE-045,
o usuário autorizou prosseguir. Esta rodada recupera a estrutura do mapa original
e incorpora os ajustes alinhados. Não implementa Flutter, API ou banco de dados.

## Base e alterações intencionais

A [fonte integrada](mapa-integrado-recuperado-zm.html) começou por uma cópia do
[mapa original](../mapa-navegavel-zm.html). A primeira folha de estilo estrutural
foi conservada integralmente, exceto pelo identificador único da nova raiz.
O [registro de origem](origem-e-alteracoes.json) identifica a fonte, os hashes
e as extensões. O original e todas as rodadas anteriores permanecem intactos.

- Barra lateral: mesma coluna 140, botões com raio 12, espaçamento, alinhamento,
  seleção ampla e ausência da marca extra na barra. Não recebeu os raios de campos.
- Home: conserva ordem e composição de resumo financeiro semanal, negócio hoje
  e atenção. O resultado não foi acrescentado como um grande cartão novo na home.
- Destinos: preservados Início, Financeiro, Vendas, Estoque e Mais, com suas
  entradas anteriores. Posição de cada área conservada ao alternar.
- Conteúdo: painéis 32, campos 24, intervalo 20 entre grupos de formulário e
  ações principais arredondadas dentro do conteúdo. A moldura e navegação são
  papéis distintos; não foram redesenhadas para aplicar esses raios globalmente.
- Financeiro: Pagar e Receber com lista, detalhe, registro, revisão, edição,
  confirmação simulada, histórico e saldo. Integral usa o saldo restante;
  Parcial revela o campo suavemente e seu valor oculto fica fora do integral.
- Data: botão com calendário controlado, entrada de 240 ms, teclado e redução
  de movimento. Forma de pagamento/recebimento começa sem seleção.
- Preferências: Mais → Configurações e conexão → Aparência, com destaque
  escolhível e azul original por padrão. Aparência/fundo/movimento têm ajustes
  compartilhados na comparação. Não há controles de raio para revogar medidas.
- Informações úteis: Financeiro → Resumo apresenta hoje, vencidas e próximos
  três dias separados, além da explicação de resultado/custo incompleto.
  O atalho Arroz abaixo do mínimo da home abre o recorte correspondente.

## Exemplos e limites de navegação

Dados são fictícios. Foi mantido o conjunto financeiro original: alimentos 680,
embalagens 600, Ana 1.250 em aberto, Bruno com original 900 e 200 recebidos.
Assim, o resumo semanal inicial é 1.280 a pagar e 1.950 a receber.
Vendas de hoje são 860 em oito cestas; resultado de 1–16/10 é 1.240, calculado
com vendas 4.500, custos 2.600 e outras despesas pagas 660. Diferença de conceito
e de período é explícita. Registrar recebimento não altera o valor vendido.
As compras ilustradas são de produtos; sua quitação não foi tratada como nova
despesa operacional para recalcular o resultado fictício.

Relatórios, impressão, conexão, backup e composições de cestas conservam páginas
demonstrativas de localização; não executam suas operações reais. Contas/cartões
e documentos continuam identificados como propostas da interface. A amostra não
é comprovação de integração com os serviços financeiros desenvolvidos em paralelo.

## Evidência

O [relatório final](mapa-integrado-recuperado-verificacao.json) registra cinco
grupos por motor Edge/WebKit no Windows, 32 combinações por motor (64 no total),
sem erros JavaScript observados. Cobre a barra contra a referência, os destinos,
contexto por área, Pagar/Receber, calendário, erros, edição, recortes e preferências.

As capturas da barra original e recuperada têm **bytes idênticos** por motor
na comparação em largura 1024, tema claro e escala normal. Também foram comparados
estilos calculados, coordenadas, largura e altura dos itens. Isso comprova essas
condições locais; não equivale a teste em aparelho nem a identidade de todo o app.
Há seis capturas por motor: home celular, home computador, home escura,
formulário e o par de barras. O helper de ajustes é original com provedor
simulado; a interface do painel real do usuário não foi automatizada.

Durante a verificação, restaurar estado com um campo focado produziu uma gravação
extra. Foi adicionada proteção de restauração aos eventos de edição e salvamento.
O teste final verifica ausência de gravação na restauração, manutenção do
rascunho e funcionamento dos ajustes depois dela. O objeto de preferências
permanece estável e ecos conhecidos de estado não substituem uma edição nova.

Texto em escala normal nesta rodada; tipografia ampliada permanece parte do
alinhamento e validação posteriores. Não há homologação iPhone/Android, operação
offline garantida, recuperação real de resposta desconhecida ou teste de API.
Histórico ilustrativo guarda oito registros recentes e agrega valores anteriores;
restauração não retoma uma confirmação em andamento como transação real.

## Continuidade e preservação

O [manifesto](manifesto.json) cobre 17 arquivos: 16 cópias da rodada e o registro
de origem. Este README e o manifesto não integram sua própria lista de hashes.
Os caminhos de Node/Playwright do teste são locais e configuráveis por variáveis
de ambiente. Não editar estas cópias depois da apresentação; uma alteração
posterior precisa de outra revisão identificada.

O [registro da referência atual](../../REFERENCIA_ATUAL_FRONTEND.json) distingue
a base acolhida, esta candidata integrada e os estudos parciais. Próximo passo:
colher retorno sobre a recuperação, principalmente barra, caminhos e jornadas.
Novos tamanhos tipográficos, fundo definitivo, aplicação de vidro e escolha do
piloto continuam por alinhar. Não abrir outra expansão por silêncio do usuário.
Arquivos preservados localmente; nenhum commit foi criado nesta rodada.
