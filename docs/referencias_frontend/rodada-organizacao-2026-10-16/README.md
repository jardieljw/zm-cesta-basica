# Organização integrada com a leitura escolhida — FE-049

**16/10/2026. Continuação após retorno expresso sobre FE-048.** Fonte:
[organização integrada](organizacao-integrada-zm.html). É uma prévia com dados
fictícios; não é a nova interface aplicada ao Flutter, API ou banco.

## Escolhas do usuário e alcance

- **Manter Leitura recuperada.** A orientada foi rejeitada como padrão: textos
  grandes e peso visual espalhado demais prejudicaram a diferença de ênfase.
  O contraste referido pelo usuário foi de hierarquia/pesos, não um diagnóstico
  de razão cromática. A fonte histórica FE-048 e sua pesquisa ficam preservadas;
  não continuar recomendando a orientada como se a preferência estivesse aberta.
- **A organização integrada foi bem recebida.** Conservar caminhos fáceis de
  encontrar e reunir o planejamento no mesmo exemplo, sem voltar a estudos
  parciais como substituição do conjunto.
- **Nome central escolhido: Negócio.** O usuário respondeu à pergunta específica
  “Negócio — vendas, clientes e resultado”. A chave técnica `vendas` continua
  sendo usada na demonstração; não houve renomeação de módulos ou APIs reais.
- **Resultado do negócio fica em Negócio**, junto das vendas e clientes, saindo
  de Financeiro. O cálculo e suas limitações continuam explícitos.
- **Início curto e útil:** o objetivo é abrir e reconhecer o essencial sem
  procurar funções ou percorrer uma página extensa. Preservar financeiro,
  negócio no período e atenção atual a vencimentos/estoque. Dia/Semana/Mês
  tornam o resumo diretamente consultável na home.

Esse retorno fecha a preferência de leitura e a divisão principal das áreas.
Não equivale a comprovar integração real, acessibilidade nativa, persistência
ou concluir o aplicativo inteiro. Não reabrir escolhas visuais acolhidas sem
uma dúvida concreta ou incompatibilidade demonstrada.

## O que a revisão demonstra

Uma única leitura, recuperada, com escolha de formato no painel da apresentação.
Conserva barra de 140, raios 12 da navegação, campos 24, painéis 32, intervalo 20
entre grupos de campos e destaque configurável com azul original por padrão.
O terceiro destino muda de nome por escolha explícita; espaços/alinhamentos da
barra permanecem. O Início usa menos margens e alturas mínimas de conteúdo, sem
aumentar peso ou diminuir a tipografia escolhida.

| Área | Finalidade na prévia |
| --- | --- |
| Início | Resumo financeiro, cestas/vendas no período, atenção atual e acesso aos mesmos recortes. |
| Financeiro | Pagar/receber, títulos, registros e vencimentos. Contas/cartões e documentos continuam propostas futuras identificadas. |
| Negócio | Vendas, clientes, resultado e explicação do cálculo. Pagamentos/recebimentos conservam o domínio financeiro compartilhado. |
| Estoque | Produtos, compras, cestas/montagens e movimentações preservados. |
| Mais | Relatórios, impressão/formulários, configurações/conexão e backup preservados. |

O período é compartilhado entre os resumos do Início e de Negócio. Semana é o
valor inicial **proposto na prévia**, conservando o recorte financeiro anterior.
Escolher Dia/Semana/Mês não altera rascunhos nem confirma operações. A preferência
é restaurada na amostra; persistência por aparelho/perfil no app real é contrato
a definir. Não tratar a semana inicial como nova escolha expressa do usuário.

## Período, posição atual e coerência dos exemplos

Referência fixa dos exemplos: **16/10/2026**. Valores são calculados a partir de
fixtures em centavos, sem conexão com os dados da empresa.

| Período | Datas | Cestas / vendas | Custos / outras despesas | Resultado |
| --- | --- | --- | --- | --- |
| Dia | 16/10 | 8 / R$ 860,00 | R$ 500,00 / R$ 60,00 | R$ 300,00 |
| Semana | 12–18/10 | 32 / R$ 3.440,00 | R$ 2.050,00 / R$ 450,00 | R$ 940,00 |
| Mês | 1–31/10 | 42 / R$ 4.500,00 | R$ 2.600,00 / R$ 660,00 | R$ 1.240,00 |

O mês seleciona o intervalo civil; operações exemplificadas são conhecidas até
16/10, sem previsão de vendas ou lucro futuro. Não confundir o fim do intervalo
com a data de avaliação. Resultado conserva a composição já documentada em
[regras de informação](../../REGRAS_DE_INFORMACAO_UTIL_FRONTEND.md#9-vendas-e-resultado-precisam-explicar-coisas-diferentes--fe-043).
Os exemplos Dia/Semana são novos dados ilustrativos, não fórmulas novas no backend.

**A pagar/receber:** saldo atual em aberto dos títulos cujo vencimento pertence
ao período escolhido. Não é o movimento de dinheiro nesse intervalo nem uma
posição histórica do saldo. Os mesmos títulos de FE-046 dão 680 a pagar e zero
a receber no dia; 1.280/1.950 na semana e no mês, pois todos vencem naquela semana.
Cada quantia da home abre a lista correspondente com os mesmos critérios.

**Precisa da sua atenção — Agora:** hoje, atrasadas e estoque não mudam de data
porque o resumo foi trocado para mês ou semana. A síntese informa o que vence
hoje e a existência de atrasos, mantendo acesso ao Financeiro. Lá, hoje,
atrasadas e próximos três dias aparecem separados para Pagar **e** Receber.
Estoque aponta o mínimo cadastrado; não é previsão de falta nem compra sugerida.
Consulta real indisponível/incompleta não poderá produzir “Sem atrasadas”.

**Resultado:** fica somente em Negócio, com período, custos e outras despesas;
limitação de custo incompleto acompanha o indicador quando presente. O detalhe
explica o cálculo, sem prometer correção histórica ou lista de vendas por custo.
Vendas podem não ter sido recebidas; resultado não representa saldo bancário.
Mover o indicador não muda os responsáveis pelas regras ou duplica cálculos reais.

## Home em uma tela: objetivo e limites

O objetivo confirmado é uma visão geral enxuta nas condições usuais. A revisão
remove altura mínima vazia do conteúdo da home e comprime margens, mantendo a
leitura recuperada. Não se aplica altura fixa, corte de conteúdo, `overflow:hidden`
ou redução de fonte para forçar encaixe em uma tela. Dados importantes continuam
acessíveis quando a altura disponível for menor ou o texto crescer.

Nos testes, home ficou em até **835,96 CSS px** nas larguras externas 390/422,
com claro/escuro e três períodos, dentro da referência de altura 844. Isso inclui
a legenda de demonstração, que não faz parte do app real. O contêiner tem 16 de
margem de cada lado: 422 externos correspondem a 390 de app; 390 a 358.
Não comprova encaixe em todo aparelho: teclado, áreas seguras, fontes, orientação,
texto ampliado e conteúdo maior precisam da validação nativa. Em 320×640 e com
ampliação, rolagem acessível é a contingência; a home não vira um painel cortado.

## Evidência e continuidade

O [manifesto](manifesto.json) registra 18 arquivos, excluindo este README e o
próprio manifesto. A [origem](origem-e-alteracoes.json) preserva a ligação com
FE-048, a escolha da variante e as alterações intencionais. O gerador arquivado
exige uma pasta nova com `--output-dir`; a reprodução local produziu bytes
idênticos à fonte exibida. A cópia da conversa e o apontador foram conferidos.

[Verificação reproduzível](check-organizacao.cjs) e
[relatório](organizacao-verificacao.json): cinco grupos e 90 composições por
motor Edge/WebKit, **180 no total**, sem erro JavaScript observado. Inclui
períodos/recortes, posição atual, localização do resultado, nomes/destinos,
contexto por área, medidas da barra, pagamento parcial, revisão/edição,
restauração do período sem gravação extra e home com conteúdo ampliado.
Helper original com provedor simulado; sem automação do painel real do usuário.

Saúde do app existente nesta rodada: **363 testes backend e 238 Flutter
aprovados**, com bancos temporários isolados. Essas suítes não implementam nem
homologam a nova interface. Nenhum código Flutter/API/banco, dependência ou
distribuição foi alterado nesta rodada. Não há commit Git.

Pesquisa anterior e fundamentação foram aproveitadas; esta rodada é aplicação
do retorno do usuário e dos contratos já documentados. Não houve nova pesquisa
externa nem alegação de que uma fonte determine esse nome ou desenho de home.

Próximo recorte: terminar a organização das jornadas e dos estados relevantes,
apontando o que já está demonstrado e o que falta integrar; consolidar os padrões
reutilizáveis e os contratos. Depois, marco de versionamento com escopo restrito
e escolha/alinhamento de piloto pequeno. Não reiniciar tipografia nem implementar
todo o aplicativo a partir da aprovação desta referência.
