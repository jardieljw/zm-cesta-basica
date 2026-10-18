# Pesquisa de front-end financeiro e empresarial — 16/10/2026

Situação: **pesquisa registrada e próximo recorte proposto**. Esta rodada não
altera o cliente Flutter, a API ou os dados. Não há uma nova prévia nesta entrega.
O [manual](ARQUITETURA_FRONTEND.md) conserva os padrões vigentes; a
[memória](MEMORIA_E_PESQUISAS_FRONTEND.md) conserva decisões e pendências.

**Atualização posterior em 16/10:** o usuário autorizou o roteiro, pedindo antes
corrigir o texto da data ainda defeituoso no iPhone. A
[rodada visual seguinte](RODADA_FRONTEND_RESUMO_E_DATA_2026-10-16.md) registra a
nova amostra e a verificação. O texto desta pesquisa preserva a situação anterior
à autorização; consultar a rodada seguinte para o estado atual.

## 1. Pedido e critério de projeto

O usuário pediu continuar pesquisando, registrar os aprendizados e projetar com
o cuidado esperado de uma grande empresa bancária, financeira, fiscal ou
empresarial. Isso acrescenta uma direção de qualidade ao projeto: clareza dos
valores, consistência entre módulos, rastreabilidade e tratamento das situações
em que a operação não ocorre como esperado.

A prioridade continua sendo o celular e a rotina da pequena empresa familiar.
Essa direção de qualidade não muda o escopo funcional já alinhado. Capacidades
bancárias, fiscais, integrações e IA continuam dependendo dos incrementos
correspondentes. As fontes abaixo orientam decisões de produto; sua consulta
não é certificação de segurança, acessibilidade ou conformidade fiscal.

## 2. Fontes primárias consultadas nesta rodada

Consulta realizada em **16/10/2026**. As sínteses são paráfrases; a aplicação
proposta ao ZM está separada da recomendação da fonte.

### RFE-01 — Visão geral ligada ao trabalho da pessoa

Fonte: [SAP Fiori for iOS — Overview Page](https://www.sap.com/design-system/fiori-design-ios/page-types/overview).

**O que a fonte orienta:** a visão geral destaca informações relevantes para
as tarefas, incluindo exceções e itens urgentes. Um indicador pode abrir uma
lista filtrada. Conteúdo de acesso frequente merece visibilidade contextual.

**Aplicação proposta:** ligar um resumo de vencimentos aos títulos que o compõem,
mantendo o filtro ao voltar. **Limite:** não copiar a estrutura inteira do SAP,
suas medidas ou sua tecnologia; a aparência segue a direção visual do ZM.

### RFE-02 — Ausência de dados precisa de explicação própria

Fonte: [IBM Carbon — Empty states](https://www.carbondesignsystem.com/building-blocks/core/patterns/empty-states).

**O que a fonte orienta:** primeiro uso, busca sem resultado e impedimento de
carregamento pedem mensagens diferentes, contextualizadas e com próximo passo
quando houver uma ação útil.

**Aplicação proposta:** distinguir “Nenhuma conta vence nesta data” de “Não foi
possível consultar as contas”. **Limite:** um estado vazio não resolve sozinho
cache, rede ou política de atualização; esses contratos ainda precisam ser definidos.

### RFE-03 — Densidade de informação deve servir à tarefa

Fonte: [IBM Carbon — Data table](https://www.carbondesignsystem.com/building-blocks/core/components/data-table/guidelines).

**O que a fonte orienta:** tabelas ajudam a localizar e comparar registros;
informações suplementares podem ser reveladas por expansão. Quando a expansão
fica apertada, cabe abrir um detalhe dedicado.

**Aplicação proposta:** celular com valor, vencimento, pessoa e situação bem
legíveis; computador com colunas comparáveis e acesso ao mesmo detalhe.
**Limite:** a lista móvel e a tabela no Windows são propostas do ZM. Não importar
automaticamente medidas de linhas, biblioteca React ou ações em lote do Carbon.

### RFE-04 — Resposta perdida não comprova falha da operação

Fontes: [Stripe — Advanced error handling](https://docs.stripe.com/error-low-level)
e [Stripe — Idempotent requests](https://docs.stripe.com/api/idempotent_requests).

**O que a fonte orienta:** uma falha de comunicação pode deixar o resultado
desconhecido. Novas tentativas da mesma operação precisam preservar sua
identidade e seus parâmetros, dentro das condições do serviço.

**Aplicação proposta:** distinguir rejeição confirmada de resultado ainda não
conhecido, preservando o registro para consulta ou repetição segura.
**Limite:** as regras da Stripe não são o contrato do ZM. Retenção, recuperação
após reiniciar e suporte dos endpoints locais precisam ser conferidos; não
adotar prazos, webhooks ou dependências da Stripe por analogia.

### Limites de acesso às referências

O site público de design do Goldman Sachs não pôde ser aberto pela ferramenta;
o endereço de documentação ligado pela página da Wise redirecionou para 404.
Não foram usados como evidência de recomendações. Não instalar ferramentas ou
dependências sugeridas dentro de páginas pesquisadas para realizar esta rodada.

## 3. Consequências propostas para a arquitetura do ZM

As regras financeiras abaixo partem também dos guias locais de
[Contas a Pagar](CONTAS_A_PAGAR.md), [dashboard](DASHBOARD_E_FINANCEIRO.md) e
[base financeira e conciliação](BASE_FINANCEIRA_E_CONCILIACAO.md). São aplicações
de projeto, não novas regras de negócio nem capacidades já entregues.

| Questão | Critério de apresentação proposto |
| --- | --- |
| O que significa este número? | Definir nome, significado, moeda, período ou data de posição, cobertura e origem antes de criar o indicador. A explicação complementar pode ficar no detalhe. |
| Como conferir a soma? | Abrir os registros que a compõem, com os mesmos critérios. Paginação não pode transformar soma parcial em total geral. |
| Qual é a confiabilidade do que aparece? | Separar situação do título, situação de revisão do documento e disponibilidade da consulta. Uma conta `PARTIAL` pode estar vencida; uma tela desatualizada não muda o status financeiro da conta. |
| Como acompanhar a origem? | Mostrar a operação de origem e os vínculos existentes, com histórico acessível. Documento recebido, dívida reconhecida e pagamento confirmado permanecem distintos. |
| Como evitar telas sobrecarregadas? | Definir informação essencial, explicação complementar e detalhe por tarefa. No Windows, comparar registros; no celular, priorizar leitura e toque. |
| Como retomar após um problema? | Preservar campos e contexto; explicar se há rejeição conhecida ou resultado ainda em verificação. Bloquear cliques repetidos sozinho não garante ausência de duplicidade. |
| Como reutilizar entre módulos? | Compartilhar apresentação de valores, datas, situações, origem e estados de consulta. Cada módulo conserva seus campos, regras e ações. |

Um “contrato de indicador” será uma especificação de apresentação ligada ao
domínio: pergunta respondida, critério de inclusão, data usada, fonte da soma,
cobertura e destino ao tocar. Não é uma nova API aprovada nem cálculo financeiro
duplicado dentro dos widgets.

Exemplo de distinção do domínio já existente: valor vendido, valor recebido,
resultado gerencial e saldo bancário têm significados diferentes. O painel
atual não entrega demonstração fiscal completa nem deve restaurar a tesouraria
arquivada. A conta interna resolvida ao registrar pagamento também não comprova
qual banco foi utilizado. Uma aparência bancária não modifica esses fatos.

## 4. Próximo recorte proposto: do resumo à origem de uma conta

**Por que agora:** já avaliamos a revisão de um pagamento e a seleção
Integral/Parcial. Conectar esse percurso a um resumo verificável testa a utilidade
da entrada do Financeiro, além do acabamento do formulário. Reutiliza o que foi
aprendido e permite avaliar uma decisão de cada vez.

**Decisão a discutir na próxima prévia:** o resumo permite entender o que precisa
de atenção e chegar aos registros corretos com pouco esforço?

Percurso fictício, com data de referência fixa em **16/10/2026**:

| Passo | O que a pessoa encontra | O que estamos avaliando |
| --- | --- | --- |
| Financeiro | “Pagar hoje · R$ 680,00 · 1 conta”, com a data de referência compreensível. | Clareza do valor e da ação disponível. |
| Tocar no resumo | Lista com vencimento em 16/10/2026 e saldo em aberto. | Resumo e lista usam o mesmo recorte. Vencidas de outros dias não entram silenciosamente. |
| Abrir a conta | Fornecedor de exemplo, vencimento, original R$ 680,00, pago R$ 0,00, aberto R$ 680,00 e origem “Despesa cadastrada no app”. | A pessoa consegue explicar de onde veio a obrigação. Sem vínculo de compra fictício apresentado como real. |
| Registrar e revisar | Reaproveitar a jornada aprovada como base, com integral do saldo atual por padrão. | Consistência com as decisões anteriores. Registro de pagamento já realizado. |
| Voltar após confirmação | No cenário integral, o título fica quitado e o resumo deixa de incluí-lo. Período, filtros e ponto da lista são preservados quando ainda fizerem sentido. | Coerência entre detalhe, lista e resumo, sem resultado otimista apresentado como confirmado. |

Na simulação, um segundo título de R$ 600,00 com vencimento em 18/10 fica fora
desse resumo de “hoje”. O exemplo demonstra critérios; não afirma que existe um
endpoint pronto para esse cartão. O mapeamento deve ser revalidado antes do piloto.

A mesma próxima amostra deve permitir comparar três condições do resumo:
dados carregados, nenhuma conta na data e consulta indisponível. Dados anteriores,
quando houver contrato para mantê-los, precisam ser identificados como tal.

**Escopo contido:** um resumo, uma lista filtrada e um detalhe, aproveitando o
fluxo de Pagar. A posição e a prioridade finais desses elementos ainda serão
avaliadas com o usuário. Contas, cartões, Receber e importações terão rodadas
próprias; documentos em revisão não compõem esse total automaticamente.

**Antes de um piloto real:** detalhar também resultado desconhecido ao salvar,
datas e horários do registro, idempotência e atualização dos dados. A primeira
prévia simula falha conhecida antes de gravar; isso não demonstra recuperação
de uma gravação cujo retorno se perdeu.

## 5. Continuidade e evidência desta rodada

- **Direção confirmada pelo usuário:** rigor de projeto financeiro/empresarial
  e pesquisa contínua, mantendo o processo gradual e os registros (FE-018).
- **Proposta do assistente:** próximo recorte “Pagar hoje → lista → origem da
  conta” (FE-019). Ao encerrar esta pesquisa, ainda não tinha sido escolhido.
  Autorizado posteriormente para prévia, conforme atualização no início do arquivo.
- **Artefato esperado depois:** prévia navegável de celular e Windows com os
  três estados de consulta descritos; preservar as versões anteriores.
- **Pendência naquela etapa:** confirmação do alinhamento da data no iPhone real.
  Uma foto posterior confirmou texto incorreto; ver FE-020 e a rodada seguinte.
- **Verificação desta entrega:** fontes consultadas, coerência dos registros e
  ligações locais. Sem nova verificação de navegador ou suíte do aplicativo.

Esta rodada não fecha o desenho de todo o Financeiro. Seu papel é transformar
a direção de qualidade em critérios observáveis para a próxima conversa.
