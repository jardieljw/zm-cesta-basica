# Primeiras regras de informação útil

Versão **0.1**, revisão **16/10/2026**, FE-039/FE-040.
Especificação de planejamento de **INT-01, INT-02 e INT-03**, a partir da
[direção de design inteligente](DESIGN_INTELIGENTE_E_ORIENTACAO_AO_USUARIO.md).
O usuário autorizou detalhar essas candidatas. Textos, disposição e parâmetros
novos são propostas para avaliação, não comportamentos já implementados.

Esta rodada usa inspeção do código e pesquisa documental. Não houve geração
de prévia, execução de navegador ou suítes, mudança de API, dados ou Flutter.

## 1. Conjunto e efeito esperado

| Regra | Ajuda oferecida | Lugar principal | Caminho proposto |
| --- | --- | --- | --- |
| INT-01 — Vencimentos | Perceber obrigações e recebimentos pendentes relevantes à data. | Início em síntese; Financeiro com os recortes. | Consultar as contas → reconhecer o título → detalhe. |
| INT-02 — Estoque mínimo | Identificar itens que merecem conferência antes de uma reposição. | Início em síntese; Estoque com os itens. | Abrir Estoque com o mesmo critério → conferir item e unidade. |
| INT-03 — Custo incompleto | Entender uma limitação do resultado gerencial apresentado. | Junto ao indicador de resultado do período. | Abrir explicação do cálculo; investigação por venda depende do contrato disponível. |

A relação com a tarefa determina a ênfase. INT-03 pertence ao valor que qualifica;
não precisa virar um aviso global. INT-01 e INT-02 podem compor uma área curta
de atenção na visão geral quando houver ocorrências. Quantidade e ordem visuais
serão avaliadas junto das demais informações, sem transformar tudo em alerta.

## 2. Evidência de capacidade e pontos ainda abertos

Inspeção em **16/10/2026**, sem execução:

| Fonte local | O que foi conferido | Limite |
| --- | --- | --- |
| [Serviço do resumo](../backend/app/services/business_dashboard.py) | Pendências OPEN/PARTIAL, vencimentos, produtos ativos abaixo do mínimo e classificação de vendas com custo incompleto. | Regra lida no código; não comprova app instalado ou nova orientação integrada. |
| [Schema do resumo](../backend/app/schemas/business_dashboard.py) e [registros](../backend/app/schemas/reports.py) | Saldos, registros financeiros, contagem/itens de estoque e `sales_without_cost_count`. | Alguns metadados de avaliação propostos abaixo não estão na resposta atual. |
| [API do dashboard](../backend/app/api/v1/dashboard.py) | Consulta de leitura `/dashboard/business-summary`, com filtros de período. | Não usar a rota histórica `/dashboard/summary` como atalho para restaurar rotinas arquivadas. |
| [Consulta de estoque no cliente](../client/lib/services/inventory_service.dart) e [tela](../client/lib/views/inventory_summary_view.dart) | Filtro `below_minimum_only=true` existe e a tela mantém escolha local de abaixo do mínimo. | A tela atual não recebe esse filtro inicial no construtor; navegação pré-filtrada ainda precisa ser integrada. |
| [Resumo de vendas](../backend/app/schemas/reports.py) e [detalhe da venda](../backend/app/api/v1/sales.py) | A lista resumida não traz a classificação de custo por venda; o detalhe serializa itens e custos. | A contagem global não entrega os IDs afetados. Não prometer lista já filtrada nem consultar cada detalhe indiscriminadamente. |

O [guia do resultado gerencial](DASHBOARD_E_FINANCEIRO.md) distingue período das
operações e posições atuais. Essa distinção governa as três regras:
pendências e estoque são posições atuais; custo incompleto acompanha as vendas
do período consultado. Não apresentar uma posição atual como retrato histórico.

## 3. Condições comuns de confiança e ciclo de vida

Antes de avaliar, identificar fonte, cobertura, período aplicável e referência
de atualidade. Proposta de estados de apresentação: **condição ativa**, **condição
não encontrada na consulta válida** e **não foi possível avaliar**. O último
não vira zero nem mensagem de tranquilização.

Uma regra muda após nova consulta pertinente; mudar a aparência ou ler a mensagem
não resolve a condição. Pagamento, estorno, cancelamento, entrada de estoque ou
alteração de mínimo podem mudar os fatos e exigem consulta/reavaliação adequada.
Não criar ocorrência nova a cada reconstrução nem compartilhar rascunho entre
registros. O estado do comando e a atualização do resumo continuam separados.

A resposta atual não fornece um campo explícito `reference_date`/`as_of` do
servidor para essas orientações. `filter_info` descreve o filtro, não é garantia
de data de avaliação para todo bloco. Antes da integração, alinhar como o módulo
obtém data de negócio e atualidade confiáveis. Horário de recebimento no aparelho
pode indicar quando a consulta chegou, mas não substitui a referência do domínio.
Não acrescentar campos de API nesta rodada nem reconstruir datas por rótulos.

## 4. INT-01 — Vencimentos relevantes

### Benefício, dados e grupos

Reduzir esforço para encontrar o que está pendente de pagar/receber, sem misturar
obrigações e recebimentos. Usar títulos identificados por módulo e ID, situação,
saldo remanescente em centavos, vencimento civil e data de negócio **D**.

Elegibilidade proposta para a orientação: título OPEN ou PARTIAL com saldo maior
que zero. Estados conflitantes precisam de tratamento do domínio; a apresentação
não inventa um status ou converte uma conta quitada em aberta.

| Grupo | Condição de data proposta | Valor apresentado |
| --- | --- | --- |
| Vencidas | Vencimento anterior a D. | Saldo atual ainda pendente dos títulos do grupo. |
| Vencem hoje | Vencimento igual a D. | Saldo atual dos títulos que vencem nessa data. |
| Próximos vencimentos | D < vencimento ≤ D + H dias corridos. | Saldo atual dos títulos do intervalo, com as datas explicitadas. |

**H = 3 dias confirmado em FE-040:** o usuário respondeu “Próximos 3 dias” à
pergunta específica. A janela começa amanhã e inclui o terceiro dia, mantendo
hoje separado. Exemplo para D = 16/10: próximos vencimentos de 17 a 19/10,
inclusive. Não criar configuração do aplicativo por consequência dessa escolha.

Hoje e próximos vencimentos são grupos separados; uma conta não aparece duas
vezes no mesmo resumo. Pagar e Receber também permanecem separados, sem um
“saldo líquido” que sugira dinheiro disponível. Recebimento esperado não é receita
confirmada em banco. “Vencida” pode coexistir com parcial, sem substituir seu status.

### Referência temporal e período da página

O serviço atual de resumo do negócio avalia atraso pelo dia de negócio e conserva vencimento como data
civil, embora o transporte o represente com horário/fuso. Não converter o vencimento
para outro dia pela localização do aparelho. Não usar o fim do filtro mensal como D.

**Lacuna de integração FE-050:** essa regra é do
[resumo](../backend/app/services/business_dashboard.py). As listas de
[Pagar](../backend/app/services/financial.py) e
[Receber](../backend/app/services/receivables.py) usam comparação de instante com
`utc_now()` em `overdue_only`; os serializadores também avaliam `is_overdue`
por instante. Logo, uma conta do dia pode ser classificada de modo diferente.
Inspeção estática em 16/10/2026, sem reprodução no banco da empresa. Alinhar a
semântica antes de ligar atalho e lista; ver
[L-03 das jornadas](JORNADAS_FINANCEIRAS_E_PRONTIDAO_DO_PILOTO.md).

**Atualização FE-053:** o [piloto real de Pagar](PILOTO_PAGAR_REVISADO.md) harmonizou
`overdue_only` e `is_overdue` de Pagar com o dia de negócio. A divergência descrita
na inspeção FE-050 foi harmonizada também em Receber pelo
[incremento FE-054](PILOTO_RECEBER_REVISADO.md), em 17/10/2026. Nenhuma mudança de
vencimentos armazenados foi feita por essas correções. Isso não implementa os
novos atalhos de Início/Financeiro descritos nesta proposta.

Proposta: rotular esse conjunto como **posição atual**, com referência verificável,
mesmo se a pessoa estiver vendo operações de outro mês. Se abrir uma consulta
histórica de vencimentos, nomear seu intervalo; ela não vira “o que vence hoje”.
Virada do dia, retorno ao app e atualização dos títulos precisam de política de
reavaliação. Sem dados atuais confiáveis, indicar avaliação indisponível/anterior.

### Mensagem, destino e encerramento

Rótulos propostos: “A pagar · vencem hoje”, “A receber · vencidas” e “A pagar ·
próximos vencimentos”, acompanhados de contagem, saldo e datas quando pertinentes.
Evitar “Você precisa pagar agora”: o usuário pode já ter pago e ainda não registrado.

A ação abre o mesmo conjunto de contas, com situação/período coerentes e critérios
visíveis. Preservar o retorno. Detalhar transporte dos filtros antes do piloto;
não supor navegação já pronta. Um resumo completo não conduz a uma primeira página
limitada que pareça representar todo o conjunto sem indicar sua cobertura.

Após confirmação de pagamento/recebimento, consultar o saldo atualizado. Parcial
continua no grupo pelo saldo que restar; quitação ou cancelamento retira o título
quando o domínio confirmar. Estorno pode reabri-lo. Se falhar somente a consulta
posterior, comunicar isso sem oferecer registrar novamente a operação confirmada.

### Exemplo e conferência planejada

Exemplo fictício: D = 16/10/2026 e H = 3 dias, conforme preferência confirmada.

| Conta pendente | Vencimento | Saldo | Grupo esperado |
| --- | --- | --- | --- |
| A, parcial | 15/10 | R$ 200,00 | Vencidas |
| B, parcial | 16/10 | R$ 480,00 | Hoje |
| C, aberta | 17/10 | R$ 150,00 | Próximos |
| D, aberta | 19/10 | R$ 90,00 | Próximos, limite incluído |
| E, aberta | 20/10 | R$ 70,00 | Fora da janela |
| F, quitada | 14/10 | R$ 0,00 | Fora dos grupos de pendência |

Para essa amostra: vencidas 200, hoje 480, próximos 240; não há sobreposição.
Antes da integração, conferir datas-limite, pagamento parcial, quitação/estorno,
cancelamento, consulta incompleta e aparelho com fuso diferente. São casos
planejados, não testes executados nesta rodada.

## 5. INT-02 — Produtos abaixo do mínimo cadastrado

### Benefício e condição

Ajudar a conferir quais produtos merecem atenção antes de decidir reposição.
O serviço atual já seleciona produtos ativos cujo saldo em STORE é estritamente
menor que `minimum_stock`, fornecendo ID, nome, SKU, unidade-base, saldo, mínimo
e diferença. A nova apresentação deve reutilizar esse significado.

Proposta de síntese: **“3 produtos abaixo do mínimo cadastrado”**. O número é
quantidade de produtos distintos, não soma de unidades. Em cada item, mostrar
nome, quantidade atual, mínimo e unidade. Se fizer sentido, apresentar a diferença
para o mínimo; ela não é automaticamente a quantidade recomendada de compra.

Não somar kg com unidades, inferir ausência de configuração porque mínimo é zero,
ou declarar data de ruptura sem outra análise. Saldo igual ao mínimo não satisfaz
a condição atual. A precisão e a formatação seguem unidade/formatadores do domínio.

### Lugar, ação e reavaliação

No Início, usar síntese curta quando a condição existir. Em Estoque, listar os
itens para investigação. Ação proposta: **“Conferir estoque”**, abrindo o filtro
já disponível no serviço e na tela. Falta integrar a passagem desse critério inicial
à navegação e preservar o retorno; não tratar o link como funcionalidade entregue.

Alterar a quantidade, o mínimo ou a condição ativa do produto pode mudar a lista.
Reavaliar após consultar o domínio. Abrir o item não cria compra nem movimentação.
Se houver zero itens em consulta válida, o destaque de atenção sai; o estoque
continua consultável. Falha ou dados anteriores não autorizam anunciar que o
estoque está suficiente para todas as vendas ou montagens futuras.

### Exemplo e conferência planejada

| Produto ativo | Saldo / mínimo | Resultado |
| --- | --- | --- |
| Arroz, unidade-base un | 8 / 10 | Abaixo; diferença de 2 un para o mínimo |
| Outro produto, un | 10 / 10 | Não está abaixo |
| Produto com mínimo zero, un | 0 / 0 | Não está abaixo; não inferir configuração ausente |
| Produto inativo | 3 / 5 | Fora do conjunto de ativos dessa regra |

Conferir limite de igualdade, unidades distintas, produto inativo, alteração de
mínimo, atualização parcial e retorno do destino pré-filtrado. Esses casos ainda
precisam de validação da composição e da integração.

## 6. INT-03 — Limitação por custo incompleto

### Evidência e rótulo preciso

O indicador atual `sales_without_cost_count` acompanha as vendas CONFIRMED do
período consultado. **A regra lida no serviço marca uma venda quando não há itens
ou quando algum item tem `total_cost_cents <= 0`.** Não equivale apenas a campo
ausente e não deve ser reimplementada como uma comparação do custo total da venda.
Uma venda com alguns itens de custo positivo ainda pode estar sinalizada.

Por isso, propor **“Resultado com custo incompleto”**, com texto de apoio como
“Há 2 vendas sinalizadas neste período”. A explicação informa que o resultado usa
os custos registrados e tem a limitação apontada pelo cálculo atual. Não afirmar
que o usuário preencheu algo errado, que toda venda com custo zero é inválida ou
que o lucro deve ser corrigido para um valor estimado.

Essa classificação já existe no backend; julgar se todo custo não positivo
representa incompletude em qualquer negócio é outra decisão de domínio. Não
alterar essa regra, custos históricos ou fórmulas por causa do texto do aviso.

### Apresentação e próximo passo honesto

Ativar a explicação quando a contagem válida for maior que zero, junto de lucro
bruto/resultado gerencial e com o período visível. Manter o valor calculado e sua
limitação, sem substituir por zero, sem ocultar a origem e sem aviso modal a cada
entrada na página. Se a contagem não estiver disponível, a qualidade é desconhecida.

Primeiro caminho proposto: **“Entender o resultado”**, abrindo uma explicação
contextual do cálculo, escopo e limitação. A API atual fornece a contagem, mas a
lista resumida de vendas não fornece um indicador/IDs dos casos sinalizados.
O detalhe da venda contém custos; isso não torna eficiente ou pronto consultar
todos os detalhes para reconstruir a lista. Uma futura investigação filtrada por
venda exige contrato apropriado e comparação com a mesma classificação do serviço.

Não oferecer “Corrigir custos” como ação pronta: atualizar o custo atual de um
produto não é uma correção dos custos congelados de uma venda anterior. Qualquer
regularização histórica precisa respeitar a [arquitetura e integridade](../ARCHITECTURE.md)
e seu fluxo próprio, sem mutação silenciosa.

### Ciclo e conferência planejada

Mudar o período pode ativar ou retirar a explicação. Nova consulta atualiza o
indicador; ler ou fechar a explicação não muda sua causa. Sem reprocessamento
autorizado, não prometer que editar um cadastro fará esse aviso desaparecer.

Conferir: zero e múltiplas vendas sinalizadas, venda sem itens, um item com custo
zero/não positivo, mistura de itens, venda cancelada excluída e período sem vendas.
Preço de venda zero não é a condição examinada por esta regra. Fonte desconhecida
ou consulta falha também não equivale a contagem zero. Casos documentados, sem
execução de novos testes nesta rodada.

## 7. Pesquisa, referências e limites

Consultas e inspeções em **16/10/2026**. Regras numéricas acima derivam do código
e das propostas explicitadas, não de uma regra universal de UX.

- [GOV.UK — Warning text](https://design-system.service.gov.uk/components/warning-text/):
  reservar ênfase de aviso para informação importante. Aplicação proposta:
  proporcionalidade, evitando tratar qualquer indicador como uma urgência.
  Não transportar seus exemplos legais para conclusões sobre o negócio.
- [SAP Learning — Overview Pages](https://learning.sap.com/courses/discovering-sap-s-4hana-embedded-analytics/working-with-overview-pages_be723c43-51c9-46cd-bd7e-20973fb41aff):
  relação entre visão geral, investigação e ação, já consultada na pesquisa
  anterior. Aplicação: resumo e destino devem representar o mesmo recorte.
- [GOV.UK — Notification banner](https://design-system.service.gov.uk/components/notification-banner/)
  e [Carbon — Notification](https://www.carbondesignsystem.com/building-blocks/core/components/notification/guidelines):
  referências anteriores para contexto e uso proporcional de mensagens; manter
  INT-03 junto do resultado em vez de repetir um aviso em todas as páginas.
- A abertura de [SAP — Overview Page Cards](https://www.sap.com/design-system/fiori-design-web/v1-108/page-types/floorplans/overview-page-ovp/overview-page-card)
  nesta rodada retornou somente cabeçalho, sem corpo suficiente. Não fundamenta
  uma nova regra ou alegação de conferência integral dessa página.

Fontes locais primárias estão ligadas na seção 2. Seus limites importam: código
inspecionado é evidência de estrutura/regra, não de teste ou disponibilidade no
instalado. Propostas de linguagem, prioridade, horizonte e navegação são do ZM.

## 8. Situação e próxima entrega agrupada

**FE-041:** [Negócio em foco](referencias_frontend/rodada-negocio-em-foco-2026-10-16/README.md)
apresenta agora o conjunto abaixo, a pedido do usuário: INT-01 abre o recorte
financeiro; INT-02 abre os produtos abaixo do mínimo; INT-03 explica o resultado.
Verificação local com dados fictícios concluída. Textos, prioridade e composição
continuam em avaliação; as lacunas de integração não foram resolvidas no app.

Detalhamento das três candidatas concluído como proposta, com horizonte de três
dias confirmado em FE-040. Antes da integração, alinhar data/atualidade, navegação com critérios iniciais e
investigação de vendas por qualidade de custo. Não ocultar essas lacunas em uma
prévia: os comportamentos ainda simulados devem ser identificados como tal.

Próxima revisão visual proposta: incluir uma síntese de orientação e seu caminho
na jornada já preparada, junto de tipografia/fundo/movimento. INT-03 pode ser
avaliada como explicação contextual, sem prometer correção histórica. Selecionar
o conjunto mínimo para a pergunta da rodada; não gerar três prévias separadas.

Validação desta entrega: fontes locais, links e coerência documental.
Condições/casos foram especificados, não implementados nem testados no app.

## 9. Vendas e resultado precisam explicar coisas diferentes — FE-043

O usuário apontou que os dois indicadores pareciam iguais. Além do jargão,
o exemplo visual repetia R$ 1.240 em vendas do dia e resultado de 1–16/10.
Esse acaso não ajuda a ensinar os conceitos e não deve ser preservado como regra.

**Valor das vendas:** total das vendas confirmadas no recorte, inclusive a prazo.
Não desconta o custo vendido nem significa que o dinheiro já foi recebido.
**Resultado do negócio** é o nome mais simples proposto para o indicador atual:
valor das vendas − custo registrado das cestas vendidas − outras despesas do
negócio pagas no período. O custo pode ter limitações, que devem permanecer junto
do indicador. Não equivale ao saldo bancário nem comprova lucro fiscal/contábil.

Fonte local primária conferida em 16/10/2026:
[cálculo e descrições atuais do resumo](../backend/app/services/business_dashboard.py),
função `get_business_dashboard`, composição do FinancialSummary e descrição dos
indicadores. Outras despesas excluem compras de estoque vinculadas e retiradas
pessoais; a mudança de linguagem da prévia não muda essa classificação do backend.

Exemplo do mesmo período para compreender o cálculo: vendas R$ 4.500, custos
R$ 2.600, lucro bruto R$ 1.900, outras despesas pagas R$ 660, resultado R$ 1.240.
Na home revisada, vendas de hoje são R$ 860, em oito cestas; o resultado continua
de 1–16/10 e explicita o período. Comparar períodos diferentes exige rótulos
claros; numa comparação futura de desempenho, usar recortes equivalentes.

Aprendizado de apresentação derivado do retorno do usuário: números distintos
não bastam. Explicar o significado, manter o período visível e abrir a composição
do resultado. Nome e disposição novos continuam propostas para avaliação.

## 10. Localização e home por período — FE-049

Usuário pediu expressamente mover **Resultado do negócio** para a área de vendas
e escolheu o nome **Negócio**, com vendas/clientes/resultado. Portanto INT-03
fica junto do resultado nessa área e em sua explicação; não permanece no resumo
do Financeiro. Cálculo, qualidade, período e limite bancário acima continuam.

Na home curta, Dia/Semana/Mês selecionam o recorte do resumo; INT-01/INT-02
mantêm atenção à posição atual. Mostrar mês de vencimentos não muda a data de
“hoje”, não transforma a dívida atual em posição histórica e não desloca o
estoque para o último dia do mês. Cada quantia abre o recorte que a compõe.
A síntese de atenção informa hoje/atrasos e conduz ao Financeiro, com os grupos
separados para Pagar/Receber. Ausência de dados atuais não pode produzir
tranquilização. A [revisão integrada](referencias_frontend/rodada-organizacao-2026-10-16/README.md)
demonstra esse recorte; as garantias reais de consulta permanecem para o piloto.
