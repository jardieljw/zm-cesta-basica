# Rodada de projeto: integral por padrão e acabamento mais arredondado

Data: **16/10/2026**. Situação: **comportamentos solicitados pelo usuário
demonstrados e verificados; nova amostra visual aguardando avaliação**.
Escopo: planejamento, prévia e documentação. Sem alteração no aplicativo Flutter,
na API, nas regras financeiras ou no banco.

## Retorno do usuário e decisões

Após a [rodada anterior](RODADA_FRONTEND_PAGAR_2026-10-15.md), o usuário:

1. Aceitou a etapa de revisão/conferência do pagamento.
2. Explicou que pagamentos parciais são raros em sua rotina de pagamentos.
   Solicitou integral como padrão e parcial como opção explícita.
3. Pediu que o campo de valor só apareça ao escolher parcial, com animação suave.
4. Considerou os campos anteriores retangulares demais e pediu maior
   arredondamento, citando a referência moderna da Apple.
5. Perguntou se o que via representava a implementação pretendida ou apenas
   um exemplo rápido. A [imagem enviada](referencias_frontend/rodada-integral-2026-10-16/referencia-usuario.jpg)
   foi preservada junto ao registro.

Decisões FE-014 a FE-016 na [memória do projeto](MEMORIA_E_PESQUISAS_FRONTEND.md).
A frequência dos pagamentos parciais é informação sobre a rotina do usuário,
não uma conclusão universal sobre aplicativos financeiros. Reavaliar a aplicação
desse padrão ao projetar Receber ou outros módulos.

## Comportamento da nova prévia

- Abre diretamente em Registrar pagamento para facilitar a avaliação da mudança.
- Integral começa selecionado. O valor é o **saldo atual em aberto**, sem exigir
  digitação. Uma conta originalmente de R$ 680,00, já paga em R$ 300,00, terá
  integral de R$ 380,00 no próximo registro.
- Parcial revela o campo de valor expandindo sua altura; os campos seguintes
  acompanham o movimento. Não há animação de entrada automática ao abrir a tela.
- Retornar ao integral recolhe e desativa o campo parcial. Seu valor permanece
  no rascunho para eventual retorno, mas não participa de validação ou confirmação
  enquanto estiver oculto. Um parcial inválido não bloqueia o integral.
- O campo oculto fica fora da interação e da sequência de teclado. Em parcial,
  ele passa a ser o próximo campo após a seleção. Redução de movimento elimina
  a transição, mantendo a mudança de conteúdo.
- Data, forma efetiva, observação, conferência, correção e histórico continuam
  no percurso. Nenhum valor é registrado antes da confirmação.

Integral/Parcial é uma escolha de apresentação para definir o valor enviado;
não cria status ou tipo novo no backend. A entrada manual continua respeitando
o limite existente de até o saldo. Se o valor manual igualar o saldo, a prévia
explica que ele quitará a conta, sem inventar uma proibição de domínio.

## Acabamento e fidelidade

A prévia é uma proposta interativa que orienta a experiência real a implementar.
O fluxo e a direção visual têm intenção de produto; medidas e acabamento ainda
precisam de revisão. A versão anterior priorizava a jornada e não constituía uma
especificação visual final. O que for aprovado deve ser documentado como referência
e critério para conferir a futura entrega Flutter.

Nesta amostra, os painéis usam referência de raio 32 e os campos 28; controles
de uma linha e ações têm curvas próximas de cápsulas. Campos de texto com várias
linhas mantêm uma superfície arredondada compatível com sua altura. Esses valores
são propostas do assistente para demonstrar a preferência, **não tokens finais
aprovados nem números prescritos pela Apple**. As referências antigas de raio
16 não devem ser retomadas como padrão final após este retorno do usuário.

Diferenças de renderização entre a prévia no navegador e o cliente nativo deverão
ser verificadas durante o piloto. Aprovar a prévia continua sem autorizar migração
global ou troca automática de todas as telas.

## Pesquisa e aprendizado desta rodada

Consultas em **16/10/2026**, fontes primárias:

- [Apple — Segmented controls](https://developer.apple.com/design/human-interface-guidelines/segmented-controls):
  escolhas próximas podem ser agrupadas com estado de seleção reconhecível.
  Aplicação ao ZM: Integral e Parcial no mesmo controle de seleção. A prévia usa
  radios HTML nativos; não anuncia que seja um controle UIKit/SwiftUI entregue.
- [Apple — Motion](https://developer.apple.com/design/human-interface-guidelines/motion):
  movimento deve apoiar a tarefa, ser breve e respeitar preferências de redução.
  Aplicação: expansão/recolhimento de altura em 260 ms, sem bloquear a próxima
  interação. A duração foi escolhida para esta amostra; continua ajustável pelo projeto.

Aprendizados de produto e de implementação da demonstração:

1. **Priorizar o caso comum:** a tela anterior solicitava valor para qualquer
   registro e dava destaque desnecessário à exceção de pagamento parcial.
2. **Revelação exige mais que esconder visualmente:** valor, validação, foco e
   acessibilidade precisam acompanhar o modo escolhido. Um valor parcial guardado
   não pode reaparecer como valor de uma confirmação integral.
3. **Integral significa saldo restante:** reutilizar o valor nominal depois de
   um pagamento parcial seria incorreto, mesmo que os rótulos estivessem certos.
4. **Arredondamento precisa ser percebido no contexto:** os raios anteriores de
   12–18 nos controles ficaram aquém da intenção do usuário quando vistos no celular.
5. **Comunicar a fidelidade:** distinguir proposta de fluxo, direção visual,
   especificação aprovada e implementação evita que um detalhe provisório vire padrão.

## Evidências e limites

O [relatório](referencias_frontend/rodada-integral-2026-10-16/pagamento-integral-verificacao.json)
registra **7 grupos de verificação e 40 combinações de estado/largura aprovadas**,
sem erros JavaScript observados, no Edge sem janela. Inclui:

- Integral sem digitação, parcial explícito, alternância com valor anterior,
  desativação do campo oculto e integral calculado sobre o saldo restante.
- Expansão/recolhimento de altura, duração calculada de transição e ausência de
  transição com redução de movimento. Tab segue ao campo correto em cada modo.
- Pagamento parcial, revisão editável, confirmação única, falha antes de gravar,
  nova tentativa, quitação, filtros, preservação e restauração do contexto.
- Raios calculados de 32/28 e cápsula na ação; composições mobile/desktop nas
  larguras externas 780, 412, 360 e 320. Imagens foram inspecionadas visualmente.

O [arquivo da rodada](referencias_frontend/rodada-integral-2026-10-16/README.md)
preserva 15 cópias com manifesto próprio. As rodadas anteriores continuam intactas.
O teste usa substituto controlado dos ajustes; não automatiza o painel nativo do
chat. Não é validação de Safari/iPhone real, Flutter, API ou pagamento bancário.

## Ponto de retomada

- Revisão e integral por padrão estão decididos para este percurso de Pagar.
- Avaliar com o usuário a nova seleção, o movimento e o arredondamento demonstrados.
- Ainda não fechar a identidade inteira nem avançar à implementação global.
- Contrato temporal, resposta desconhecida, validação nativa e escolha do piloto
  continuam pendentes, conforme o manual e o registro anterior.

## Correção posterior: campo de data excedendo a coluna

Ainda em 16/10, o usuário enviou uma nova imagem mostrando o campo de data mais
largo que os campos de valor, forma e observação. É um defeito observado na
prévia exibida no iPhone; não comprova falha no aplicativo Flutter.

A investigação encontrou o [relato WebKit 301648](https://bugs.webkit.org/show_bug.cgi?id=301648),
que descreve cálculo incorreto de largura em campos de data com padding no iOS,
inclusive com reprodução relatada por mantenedor. Isso é compatível com a foto e
com o uso anterior de largura 100% e padding no controle, mas não comprova sozinho
a causa no aparelho do usuário. A [documentação do campo date](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/input/date)
também registra que sua apresentação varia por navegador e sistema.

**Correção:** manter o seletor nativo, movendo padding e borda para uma moldura
restrita à coluna. O input fica flexível e sem padding/borda próprios, com mínimo
de largura zero. A grade do campo usa uma coluna que pode encolher. Não foi usado
recorte para esconder a extremidade excedente do controle.

O [relatório da correção](referencias_frontend/correcao-data-2026-10-16/data-alinhada-verificacao.json)
registra 64 casos locais aprovados: Edge/WebKit, larguras externas 320/360/390/412,
fontes de data 16/20, Integral/Parcial e dimensionamento padrão/estressado.
O teste passou a comparar as bordas com os controles vizinhos e o campo pai.
Na condição forçada de cálculo como conteúdo, o controle antigo ultrapassa a
coluna; a nova moldura continua alinhada. Dados da data foram mantidos ao revisar
e voltar para editar. Imagens foram inspecionadas.

**Limites da evidência:** no WebKit Windows instalado, `type=date` se apresenta
como fallback de texto; não há o seletor nativo UIKit. Os dois motores locais
mostravam alinhamento no caso padrão anterior. A reprodução de excesso local foi
um estresse explícito de box sizing, não reprodução comprovada do defeito iOS.
A correção ainda deve ser observada no iPhone do usuário. A instrumentação isolou
a persistência do contêiner de teste para verificar o fluxo de data.

**Aprendizado permanente:** caber na janela não garante caber no painel. Um
controle pode escapar da coluna e continuar dentro da moldura geral do app.
Viewport, user agent e motor similares também não substituem o controle nativo
da plataforma. Registrar essas diferenças evita afirmar validação iOS indevida.
O [arquivo da correção](referencias_frontend/correcao-data-2026-10-16/README.md)
preserva a foto, versões, teste e evidências, com manifesto próprio.
