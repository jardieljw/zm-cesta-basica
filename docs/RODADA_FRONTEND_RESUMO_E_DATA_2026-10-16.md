# Rodada de front-end — resumo rastreável e seletor de data

Data: **16/10/2026**. Situação: **prévia criada e verificada localmente;
avaliação do usuário pendente**. O aplicativo Flutter e seus dados não foram
alterados. A [memória](MEMORIA_E_PESQUISAS_FRONTEND.md) registra a continuidade;
o [manual](ARQUITETURA_FRONTEND.md) reúne os padrões em elaboração.

## 1. Retorno recebido e escopo autorizado

O usuário autorizou prosseguir com o recorte proposto na
[pesquisa empresarial](PESQUISA_FRONTEND_EMPRESARIAL_2026-10-16.md), pedindo antes
atenção à data do pagamento. A [nova foto do iPhone](referencias_frontend/rodada-resumo-e-data-2026-10-16/data-cortada-iphone.jpg)
mostra que a revisão anterior resolveu a largura externa, mas deixou o texto
cortado e desalinhado na altura.

Isso confirma que a correção anterior era incompleta no aparelho. Os testes
locais anteriores continuam sendo evidência histórica do que mediram; não devem
ser apresentados como validação do conteúdo interno do seletor nativo iOS.

- **FE-019:** roteiro de resumo/lista/origem autorizado para prévia.
- **FE-020:** novo relato de defeito na data; corrigir antes de apresentar o percurso.
- A escolha de um calendário próprio para esta amostra é solução proposta pelo
  assistente, ainda sem aprovação como componente definitivo do aplicativo.

## 2. Nova abordagem para a data

A prévia deixa de usar o `input type=date` problemático para exibir o valor.
Um botão nativo mostra a data por texto comum, com alinhamento por flex e espaço
para o ícone; ao tocar, abre um calendário em um `dialog` HTML. Os dias são
botões reais com nomes completos, seleção indicada e navegação de mês.

O valor escolhido continua sendo uma data ISO `AAAA-MM-DD`, conservada no
rascunho, na conferência e no histórico. Cancelar ou fechar não altera o valor.
O foco volta ao botão de data ao fechar; setas navegam entre dias, PageUp/PageDown
mudam o mês e, com Shift, o ano. Escape fecha pelo comportamento do diálogo.

O texto pode ocupar mais de uma linha em largura pequena ou fonte maior. Não
usar ocultação ou reticências para aparentar que uma data cortada está correta.
O calendário desta demonstração usa 16/10/2026 como referência fixa para “Hoje”.

**Limites:** não houve execução em um iPhone nesta máquina. A mudança evita a
dependência do desenho interno daquele campo nesta prévia, mas a nova amostra
ainda precisa ser observada no aparelho. Isso não define se o Flutter usará um
seletor nativo, compartilhado ou adaptado por plataforma. Esse contrato será
alinhado antes do piloto; o código HTML não será copiado para o aplicativo.

## 3. Percurso financeiro demonstrado

A amostra tem três entradas no seletor de apresentações: **Conferir a data**,
**Financeiro no celular** e **Financeiro no Windows**. A primeira abre o
formulário diretamente; as outras começam no resumo. Cada entrada mantém seu
estado local independente.

| Passo | Comportamento da prévia |
| --- | --- |
| Resumo | “Pagar hoje” soma R$ 680,00 de uma conta em aberto com vencimento em 16/10. |
| Explicação | “O que entra neste resumo?” informa saldo, vencimento e cobertura dos registros. |
| Tocar no resumo | Abre Pagar com vencimento na mesma data e situação Em aberto, incluindo títulos parciais. |
| Lista | Total e registros usam o mesmo recorte. Os R$ 600,00 que vencem em 18/10 ficam fora de hoje. |
| Detalhe | Exibe original, pago, saldo, vencimento, descrição e origem. “Origem deste registro” esclarece o lançamento manual do exemplo. |
| Pagamento | Reutiliza integral por padrão, parcial opcional, revisão, conclusão e histórico. |
| Retorno | Após integral, a conta deixa de compor o resumo. Após parcial de R$ 300,00, lista e resumo mostram R$ 380,00. O filtro e o recorte são mantidos ao voltar. |
| Windows | Os mesmos registros são comparados em uma tabela com acesso ao detalhe, em composição com navegação lateral quando há espaço. |

O exemplo usa uma despesa manual fictícia, sem vínculo com compra ou documento
importado. Essa escolha é conteúdo da amostra, não mudança nas regras de origem
das obrigações reais. Os valores e somas da prévia são locais e demonstrativos;
o domínio do aplicativo continua responsável pelos cálculos reais.

Nos controles de design das duas apresentações de resumo, **Consulta financeira**
permite comparar:

- Com contas para hoje: R$ 680,00 e acesso à conta correspondente.
- Sem contas para hoje: mensagem específica e acesso à semana, que conserva a
  conta de R$ 600,00. A conta de hoje não faz parte dos dados desse cenário.
- Consulta indisponível: explica a falha e oferece tentar novamente; nenhum
  valor é apresentado como zero confirmado. A recuperação é simulada.

Contas bancárias, cartões, Receber, importações e resultado desconhecido ao
salvar continuam em rodadas próprias. Esta é uma amostra do percurso, não a
composição completa ou final da entrada do Financeiro.

## 4. Pesquisa e aprendizados adicionais

Consulta em **16/10/2026**, com fontes primárias:

- [MDN — input date](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/input/date):
  aparência depende do navegador e sistema, enquanto o valor é normalizado.
- [MDN — Advanced form styling](https://developer.mozilla.org/en-US/docs/Learn_web_development/Extensions/Forms/Advanced_form_styling):
  estilizar a caixa externa não dá controle completo sobre partes internas de
  seletores de data. A fonte admite um controle próprio quando esse domínio
  visual é necessário; a escolha concreta acima é uma aplicação ao ZM.
- [MDN — dialog](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/dialog):
  o elemento oferece abertura modal por `showModal()`, fechamento e comportamento
  de foco. A amostra usa o elemento nativo e botões, sem simular um modal por divs.

**Aprendizado da falha anterior:** medir apenas o retângulo do campo não prova
que os caracteres cabem ou estão centralizados. A verificação nova inclui os
retângulos do texto, o espaço para o ícone, as margens internas e os vizinhos.
Uma captura do aparelho prevalece sobre uma suposição de equivalência entre
WebKit Windows e Safari/iOS.

**Aprendizado do fluxo:** o indicador e a lista precisam compartilhar o critério
de vencimento e saldo. O estado parcial pode permanecer em aberto; um filtro
“Em aberto” que removesse títulos parciais quebraria a conferência do resumo.

## 5. Evidência preservada e limites

[Arquivo da rodada](referencias_frontend/rodada-resumo-e-data-2026-10-16/README.md):
19 cópias com manifesto SHA-256, incluindo fonte, contêiner, verificação,
relatório, 14 capturas e a foto do usuário. As versões anteriores foram mantidas.

O [relatório](referencias_frontend/rodada-resumo-e-data-2026-10-16/financeiro-origem-data-verificacao.json)
registra **64 combinações de geometria da data**: dois motores, dois modos de
pagamento, quatro larguras externas (320/360/390/780), dois temas e dois tamanhos
do texto da data (16/20). O contêiner de teste tem margens próprias; a largura
interna está registrada em cada caso. Não é teste de ampliação de todo o sistema.

Foram verificados oito grupos em cada motor, sem erros JavaScript observados:
geometria do texto; calendário/teclado/foco/revisão; meses/anos/bissexto; resumo
até integral; parcial e saldo restante; tabela e retorno; vazio/indisponível;
ajustes após restauração simulada. A confirmação repetida no mesmo botão gera
um único pagamento na simulação.

Os motores são Edge e WebKit instalados no Windows. Não representam homologação
de iPhone, Android ou Flutter. O vínculo dos controles e a persistência foram
instrumentados para isolar a lógica local; o painel nativo e a restauração real
do hospedeiro não foram automatizados. O teste aguarda o fechamento assíncrono
do diálogo antes de conferir o foco.

Filtros e recorte de retorno foram conferidos. A rolagem externa da conversa,
uso de leitor de tela no aparelho e recuperação de uma gravação com retorno
perdido permanecem sem validação nesta entrega. Não houve novas suítes do app,
instalação de dependências, migração ou acesso ao banco da empresa.

## 6. Ponto de retomada

Avaliar primeiro a leitura e a seleção da data no iPhone com esta amostra.
Depois, avaliar se “Pagar hoje” e sua explicação levam à conta esperada no celular
e no Windows. Registrar o retorno antes de fechar componente, hierarquia e
tokens definitivos. Receber continua como adaptação posterior, com sua própria
frequência de pagamentos parciais a entender.
