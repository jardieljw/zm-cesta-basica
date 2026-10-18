# Tipografia e hierarquia na base integrada — FE-048

**16/10/2026. Proposta para revisão, em continuidade a FE-047.** A recuperação
FE-046 já foi apresentada e o usuário autorizou continuar o alinhamento em outro
chat. Esta rodada compara a leitura; não refaz a descoberta nem inicia o piloto.

## Fonte e comparação

A [fonte desta rodada](hierarquia-integrada-zm.html) deriva diretamente da
[integrada recuperada](../rodada-recuperacao-integrada-2026-10-16/mapa-integrado-recuperado-zm.html).
A primeira folha estrutural foi mantida, com troca apenas do identificador da
raiz. As extensões de FE-046, seus destinos e funções permanecem. A nova raiz é
`zm-typography-demo`. Histórico anterior permanece intacto.

O comparador apresenta **Leitura orientada**, recomendada, e **Leitura recuperada**.
Ambas acompanham o mesmo registro, etapa, filtros e rascunho, para permitir uma
comparação no contexto real da tarefa. Cada área conserva sua posição ao alternar.
Não há dois aplicativos nem um novo controle de comparação no produto planejado.

| Papel | Recuperada, base | Orientada, proposta |
| --- | --- | --- |
| Página | 23 | 24 / 30 |
| Seção | 16 | 18 / 24 |
| Corpo / rótulo de campo | 15, com entradas em 16 | 16 / 24; rótulo 16 / 22 |
| Apoio | 12–13 | 14 / 20 |
| Valor central do detalhe/revisão | 32 | 28 / 34 |
| Quantia do resumo | 21 no estreito, 23 no amplo | 24 / 30 |
| Quantia em linha de lista | Herdada do corpo | 18 / 24 |

Valores em CSS px para a demonstração, pesos 400/500. A família existente
`Segoe UI, system-ui, sans-serif` foi conservada para isolar a comparação de
hierarquia. Ela **não foi escolhida como fonte definitiva multiplataforma**.
Menor valor central e maior texto de apoio procuram equilibrar a compreensão;
não há a intenção de aumentar indistintamente todos os números.

## Adaptação e casos de leitura

No painel da comparação: aparência, fundo, formato celular/computador, texto do
conteúdo 100/150/200%, caso de leitura e movimento. Espaço 20, campos 24, painéis
32 e azul original continuam preservados. Não foram reabertos como escolhas.

O caso Cotidiano conserva os dados financeiros de FE-046. Um pagamento parcial
de 200 na conta original de 680 permite observar 480 em aberto. O caso extremo
usa fornecedor com nome longo, original **R$ 1.234.567,89**, anteriores
**R$ 234.567,89**, restante **R$ 1.000.000,00**. É teste de composição, sem
inferir que esses valores sejam usuais ou limites máximos aceitos pela API.
Trocar o caso **reinicia o exemplo**, como informa o rótulo do controle; aparência,
formato e ampliação preservam o preenchimento. A troca de caso é impedida durante
a confirmação simulada para não trocar os registros enquanto a resposta está pendente.

Na opção orientada, pares se empilham quando o espaço ou o texto exigem,
rótulos ficam próximos dos respectivos dados, título ampliado ganha toda a largura
abaixo do retorno e controles podem crescer. Seleção longa de forma tem cópia
legível abaixo do seletor quando ampliada. Texto completo não depende de hover.

Quantias usam algarismos tabulares; moeda, sinal e centavos permanecem completos.
Há oportunidades de quebra **entre grupos de milhares**, sem cortar um grupo ou
separar os centavos. Em 320 com conteúdo a 200%, uma quantia extrema ocupa várias
linhas: preservar todos os dígitos não comprova conforto de leitura. Esse limite
precisa ser avaliado com o usuário e na plataforma, antes de fechar o componente.
Não foi adotada redução automática da fonte nem abreviação para milhões.

Para que a comparação histórica continue utilizável, a leitura recuperada recebe
as mesmas salvaguardas de quebra/empilhamento **somente com texto ampliado ou no
caso extremo**. No caso cotidiano a 100%, conserva a composição e a escala de
FE-046. Não apresentar a variante de estresse como reprodução sem adaptações.

## Preservação da navegação e limite da ampliação

Barra de computador conserva coluna 140, raio 12, seleção, alinhamentos e espaços.
Navegação não recebe os estilos de conteúdo. Os cinco destinos, seus filhos e
propostas futuras continuam presentes. Os três blocos da home mantêm ordem e
finalidade, inclusive resumo financeiro e acesso ao Financeiro.

O controle chama-se **Texto do conteúdo**: ele não amplia a barra, a legenda da
prévia ou todo o navegador. É um ensaio dos papéis tipográficos, não emulação de
Dynamic Type, zoom global ou certificação de acessibilidade. A barra 140 com texto
global muito grande pode exigir adaptação própria. Isso permanece pendente, com
comparação explícita de alternativas antes de mudar sua geometria. Não limitar a
preferência de texto do sistema no aplicativo futuro para conservar a barra.

## Fontes, verificação e limites

Pesquisa anterior aproveitada: [papéis e fontes primárias](../../HIERARQUIA_E_TIPOGRAFIA_FRONTEND.md#7-pesquisa-primária-aplicação-e-limites).
Pesquisa dirigida desta rodada, consultada em **16/10/2026**:

- [W3C WAI — Understanding SC 1.4.12, Text Spacing](https://www.w3.org/WAI/WCAG22/Understanding/text-spacing.html),
  seções Success Criterion e Intent: o conteúdo deve admitir alterações de
  espaçamento sem perda de conteúdo/função; os valores citados não são a métrica
  obrigatória de desenho padrão. Aplicação: ensaio separado na home extrema.
  Limite: esse caso não cobre todos os componentes nem certifica WCAG/Flutter.
- [WHATWG — HTML Standard, 4.5.28, The wbr element](https://html.spec.whatwg.org/multipage/text-level-semantics.html#the-wbr-element):
  uma oportunidade de quebra não força uma nova linha. Aplicação inferida pelo
  agente: permitir quebra entre grupos de milhares mantendo a sequência textual.
  Limite: a especificação não recomenda esse desenho para dinheiro nem comprova
  leitura assistiva ou preferência do usuário. A abertura de
  [MDN — wbr](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/wbr)
  serviu à localização do recurso; a fundamentação técnica é a fonte normativa.

O [script](check-hierarquia-integrada.cjs) e o
[relatório](hierarquia-verificacao.json) registram os resultados locais. O helper
de ajustes é original com provedor de anotações simulado; o painel real do usuário
não foi automatizado. Capturas são inspecionadas separadamente das medidas.
WebKit no Windows não é Safari/iPhone. Sem API real, banco da empresa, testes
assistivos, recuperação de rede ou implementação Flutter nesta rodada.

**Resultado final:** cinco grupos do comparador e três de
[continuidade/restauração/Receber](continuidade-verificacao.json) por motor
Edge/WebKit. São **640 composições** no total, sem erro JavaScript observado.
As cinco capturas de botões da barra coincidem byte a byte com a base recuperada,
nas duas leituras e em cada motor, na condição normal 1024/claro/100%. Isso não
afirma identidade de toda a altura da barra ou de todas as telas após ampliar.
Os casos de espaçamento extra são adicionais à matriz. A
[verificação de continuidade](check-restauracao-e-receber.cjs) confirma ausência
de gravação extra ao restaurar, ajustes funcionando depois e integral de Receber
com seus próprios códigos.

As larguras externas testadas são 320/390/768/1024; o contêiner local de inspeção
tem 16 de margem em cada lateral. Assim, no caso externo 320, a moldura do app
mede 288. O relatório conserva as medidas internas observadas. Capturas da home
feitas após o pagamento parcial de teste mostram A pagar 1.080,00; a fonte começa
em 1.280,00, como FE-046. Não é mudança do conjunto de contas.

**Aprendizado local:** a opção longa de um seletor nativo WebKit contribuía com
largura além do próprio controle a 200%, mesmo com a caixa medida corretamente.
Limitar a coluna da grade não bastou. No caso ampliado/extremo, a revisão usa o
mesmo `select` com aparência controlada e indicador Lucide, preservando teclado
e seleção nativa; a opção completa fica legível na cópia abaixo quando ampliada.
Não é defeito reproduzido no Flutter/iPhone. O título também passou a ocupar
uma linha de composição própria abaixo do retorno quando ampliado; a seta
decorativa da ação principal é omitida para dar espaço ao seu texto.

A primeira captura da referência no WebKit era feita antes de a seleção do
comparador estabilizar e podia produzir medidas zero. A verificação final aguarda
a renderização e captura a referência antes de fechar aquela página. Isso é
correção da instrumentação, não evidência de uma falha na barra do produto.

Checagem das suítes existentes: **363 backend e 238 Flutter aprovados**. A primeira
tentativa restrita falhou na criação de temporários e a segunda não progrediu;
as execuções concluídas usaram o ambiente local fora dessa restrição, com banco
descartável. Avisos de depreciação/fontes existentes não foram corrigidos neste
recorte. Esses testes não comprovam a interface proposta.

## Continuação

O [manifesto](manifesto.json) conserva hashes de 24 arquivos, excluindo este README
e o próprio manifesto. O [registro de origem](origem-e-alteracoes.json) identifica
a base FE-046 e as alterações. O gerador preservado aceita `--output-dir` somente
para uma pasta nova, evitando sobrescrever este histórico. Sua reprodução local
gerou exatamente os mesmos bytes da fonte apresentada; apontador, cópia de
exibição e links locais também foram conferidos. Isso continua sendo preservação
local, sem um marco Git.

Avaliar a **Leitura orientada** contra a recuperada, especialmente os apoios,
o equilíbrio dos números e a composição com texto grande. Tamanhos/fonte seguem
propostos até retorno específico; não escolher Pagar como piloto de implementação
por ele ter sido usado nesta demonstração. Fundo, vidro, cores semânticas e
valores finais de movimento continuam para etapas próprias. Não executar o
roteiro inteiro de FE-047 nesta rodada. Preservação local ainda não é commit Git.
