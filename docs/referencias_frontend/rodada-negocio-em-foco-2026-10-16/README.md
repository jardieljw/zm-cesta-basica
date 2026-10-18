# Negócio em foco — revisão conectada, 16/10/2026

**FE-041 — prévia para avaliação.** O usuário pediu ver o que estava sendo
planejado, depois de várias rodadas documentais. Esta apresentação reúne as
regras INT-01/02/03 e a jornada financeira. Não autoriza implementação no app.

## O que revisar

- Na visão geral, abrir Vencem hoje, Contas vencidas e Próximos 3 dias.
  Para a referência fictícia de 16/10/2026, o último grupo inclui 17–19/10.
- Abrir Conferir estoque: são três produtos abaixo do mínimo, com quantidade
  atual, mínimo e diferença por produto. Diferença não é ordem de compra.
- Abrir Entender o resultado: explicação dos valores e da limitação de custo
  em duas vendas, sem prometer correção histórica ou uma lista filtrada pronta.
- Em Financeiro, seguir lista → detalhe → registro → revisão → confirmação
  simulada → retorno. Pagar e Receber usam integral do saldo restante por padrão.
  Parcial revela seu campo; editar conserva o preenchimento e voltar conserva
  o recorte. A confirmação altera somente os exemplos locais da prévia.
- Comparar No celular e No Windows. Em Mais, experimentar aparência, fundo e
  destaque. O painel de ajustes reúne aparência, fundo, movimento e texto.

## Decisões e propostas

**FE-042 — preservar a base aceita:** a primeira composição preparada nesta
rodada enfatizava atenção e omitia o resumo A pagar/A receber e Seu negócio hoje.
O usuário perguntou pela homepage anterior e alertou que perder acordos deixaria
o projeto bagunçado. A fonte anterior continua intacta. A revisão conserva seus
três blocos: financeiro, negócio hoje e atenção. As novas regras entram nessa
estrutura. A conferência verifica explicitamente a presença desses blocos.

**FE-043 — indicadores distinguíveis:** o usuário observou que Valor das vendas
e Resultado gerencial pareciam iguais. O primeiro exemplo repetia R$ 1.240 nos
dois, apesar de períodos diferentes; isso prejudicou a compreensão. Vendas de
hoje passam a R$ 860 fictícios; resultado de 1–16/10 continua R$ 1.240, com fórmula
descrita e nome proposto Resultado do negócio. O detalhe mostra vendas 4.500,
custos 2.600 e outras despesas pagas 660. Não altera o cálculo real do backend.

Conserva espaço entre campos 20, campos 24, painéis 32 e destaque configurável,
com azul #2866ae por padrão. Tipografia, composição, fundo e novos textos estão
em avaliação. Apresenta a entrada do calendário estudada em FE-031, de 240 ms;
a redução de movimento do sistema prevalece sobre a opção padrão da prévia.
Não registrar a apresentação como aprovação de cada medida ou do piloto real.

## Evidência e limites

O [relatório](negocio-em-foco-verificacao.json) registra quatro grupos por motor
Edge/WebKit no Windows, 20 combinações de página/dispositivo/largura/texto por motor
(40 no total) e nenhum erro JavaScript observado. Cobre pagamento parcial,
valor integral sem campo oculto, calendário, validação, edição, atualização de
saldo, destinos informativos, Windows e redução de movimento.

O helper original de ajustes foi exercitado com provedor de anotações simulado;
o painel real da janela do usuário não foi automatizado. Há dez capturas: início
claro/escuro, Windows, formulário em 390 e calendário em 320, por motor, além da
conferência da largura do calendário e do contorno/altura do campo de data.
Não são testes em aparelho iPhone/Android nem do Flutter.

Persistência usa o estado oferecido pelo hospedeiro; rascunho e escolhas são
restauráveis, mas a pilha exata de navegação e uma confirmação em andamento não
são retomadas como transação. Não há API, banco real ou integração bancária.
Não simula indisponibilidade/resultado desconhecido nesta rodada; consultar o
catálogo anterior para esses estados e definir contrato antes do piloto real.

As [regras](../../REGRAS_DE_INFORMACAO_UTIL_FRONTEND.md) e a
[composição](../../COMPOSICAO_DAS_PAGINAS_FRONTEND.md) conservam fontes originais,
fundamentação e lacunas de integração. Nenhuma pesquisa nova de design foi
necessária para reunir este conjunto já estudado. Próximo passo: colher o retorno
sobre utilidade, prioridade e percurso, antes de outro incremento.

## Preservação

O [manifesto](manifesto.json) registra origem, tamanho e SHA-256 das 14 cópias.
Fonte, contêiner de inspeção e verificação permanecem distintos. O script usa
caminhos locais e aceita PREVIEW_DIR/PLAYWRIGHT_MODULE/TWEAK_HELPER_PATH para
adaptação. Não editar estas cópias históricas para outra rodada.
