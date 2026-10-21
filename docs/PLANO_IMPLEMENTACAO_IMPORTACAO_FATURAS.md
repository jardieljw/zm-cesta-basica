# Plano de implementação: faturas dentro de Contas a Pagar

**Situação vigente:** consultar a [retomada única](RETOMADA_IMPORTACAO_FATURAS.md).
O retorno nativo de **20/10/2026** encontrou falhas de acesso e compreensão;
E5 permanece aberta. O passo E5.6 abaixo é uma proposta de correção para alinhar
antes de implementar, sem autorização de reformulação visual global.

**Execução posterior — registro histórico de 19/10/2026:** E1–E3 implementadas conforme
[guia E1](IMPORTACAO_FATURAS_E1.md), [guia de Pagar](CONTAS_A_PAGAR.md) e
[retomada atual](RETOMADA_IMPORTACAO_FATURAS.md). E4/E5 permanecem pendentes.
As indicações de “planejado” abaixo descrevem a
rodada original de planejamento; contratos D e sequência permanecem válidos.

**Data:** 19/10/2026. **Situação:** planejado; nenhuma etapa implementada nesta
rodada. Pedido vigente: preparar a execução antes de modificar o aplicativo.
As escolhas técnicas abaixo são recomendações deste plano, não aprovações de
interface atribuídas ao usuário. Uma futura autorização para implementar permite
executar os incrementos necessários; não exige outra aprovação a cada arquivo.

Base de produto: [escopo do usuário](ESCOPO_IMPORTACAO_DE_FATURAS.md).
Base factual: [auditoria dos 19 arquivos](AUDITORIA_FATURAS_FORNECIDAS_2026-10-19.md).
Entrada curta para execução: [roteiro de retomada](RETOMADA_IMPORTACAO_FATURAS.md).

## 1. Resultado e limites da entrega

Selecionar PDF/CSV → reconhecer o conteúdo e a origem → preencher os dados →
resolver apenas dúvidas reais → confirmar → consultar as cobranças em Contas
a Pagar. Cada lançamento deve conservar banco/cartão, estabelecimento/descrição,
valor com sinal, data da compra, vencimento e parcela quando disponíveis. A
consulta deve mostrar hoje, semana, mês e parcelas dos meses seguintes.

Ler corretamente é uma parte. Integrar significa persistir relações úteis,
incluir a cobrança nos totais certos, permitir consulta/pagamento e impedir que
reimportação, crédito ou parcela futura dupliquem a dívida. A entrega exige ambas.

Não entram: novos módulos bancários, OFX, Open Finance, coleta de e-mail,
construtor universal de mapeamentos CSV, novo tema/navegação ou distribuição
comercial. Preservar as telas ativas e os fluxos de compras, estoque e pagamentos.
IA/OCR não são dependências iniciais: os PDFs auditados têm texto e as principais
linhas já foram extraídas exatamente. Avaliá-los somente por dificuldade residual
demonstrada, sem contratar API ou enviar documentos nesta etapa de planejamento.

**Limite dos dados:** índices/resumos não contêm compras individuais; vencimento
ausente e saldo histórico ainda aberto não podem ser inventados. Uma pendência
explicada não conta como importação financeira concluída. É necessário distinguir
sucesso integral, cobrança cadastrada com detalhes incompletos e evidência guardada.

## 2. Diagnóstico que não precisa ser refeito

| Achado | Consequência concreta | Tratamento no plano |
| --- | --- | --- |
| A01: arquivo troca Santander por primeiro cartão | Risco de banco/cartão errado | E1.1 e T01 |
| A02: CSV termina em cabeçalho vazio | Recadastro de dados; dados realmente ausentes | E1.3, E3.2 e T04 |
| A03: todas as linhas exigem classificação | Automação não entregue | E1.2, E2.1, E3.1 e T05 |
| A04: parcelas no texto não viram campos/agenda | Próximos meses não aparecem | E1.2, E4 e T03/T12 |
| A05: detalhes e resumo divergem em centavos | Não basta trocar parser ou afrouxar tolerância | Regra D4, E1.3 e T06 |
| A06: outubro tem dois vencimentos | Data escolhida silenciosamente | E1.3, E3.1 e T07 |
| A07: índices e vários ciclos tratados como uma fatura | Leitor inadequado, detalhes impossíveis de recuperar | E1.1, E3.2 e T08/T09 |
| A08: identificação final sem comprovação | Dados ficam em evidência, não na rotina financeira | E2/E3 e T10/T16 |

Auditoria: 19 arquivos/18 conteúdos; 3 prévias aptas, 15 bloqueadas, 1 rejeição
anterior à prévia; zero títulos e zero parcelas futuras. PDF 06 preservou 28
movimentos bancários; PDF 07/08 preservaram 39/22 linhas; CSV 05/06 preservaram
21/13 linhas, mas perderam 9/3 campos de parcela identificáveis. A diferença
detalhe versus resumo foi -6/+2 centavos nos dois PDFs bancários. Outubro também
contém vencimentos 24 e 26/10/2026. Esses são resultados observados, não metas.

Não repetir a auditoria inteira para descobrir esses fatos. Na execução, conferir
hashes/versões e repetir os casos afetados pelas alterações. As referências
independentes privadas já existem; os leitores do aplicativo não podem ser a
única fonte para validar a própria saída.

## 3. Decisões propostas e contratos de domínio

### D1 — Uma cobrança líquida por fatura, com todos os itens vinculados

Recomendação: um ciclo de cartão identifica a fatura e aponta para **um título
líquido** em `accounts_payable`. Os lançamentos ficam estruturados e acessíveis
no detalhe dessa cobrança, inclusive pela busca de estabelecimento e parcela.
Não criar um título pagável para o total e outros títulos pagáveis para suas
compras. A lista pode mostrar os itens expandidos, mas soma o título uma vez.
O usuário continua vendo cada compra; não recebe apenas uma descrição genérica
"cartão — valor total" sem acesso ao detalhamento.

| Alternativa | Avaliação |
| --- | --- |
| Título positivo por linha, crédito rateado por compra | Requer mais regras de rateio e pagamento; a arquitetura atual bloqueia créditos/saldo anterior. Não é a opção inicial. |
| Só título total, descartando os itens | Simples, mas não atende estabelecimento, descrição e parcelas. Rejeitada. |
| Título líquido + itens + agenda vinculados | Recomendada: preserva a informação e permite pagar a fatura sem duplicar totais. |

Exemplo fictício: compras de R$ 100 + R$ 50 e crédito de R$ 20 resultam em uma
cobrança de R$ 130, com os três componentes visíveis. O crédito não vira receita,
pagamento fictício ou alteração no valor original de uma das compras. Se já houver
uma cobrança comercial representando uma compra, aplicar D7 antes de ativar o título.

### D2 — Identidade e categorias automáticas separadas da finalidade econômica

- Origem = banco + relação de cartão/conta; cartões diferentes do mesmo banco
  não podem ser fundidos por instituição. Últimos dígitos são opcionais e
  insuficientes isoladamente para provar identidade; não armazenar número completo.
- Preservar origem explicitamente escolhida. Reconhecimento incompatível deve
  mostrar a dúvida, não trocar a origem. Sem seleção, sugerir pela evidência;
  dois cartões possíveis exigem uma escolha única para aquele conjunto/ciclo.
- Separar `role` (compra, encargo, pagamento, crédito, saldo anterior, controle,
  oferta, desconhecido) de `purpose` (negócio, pessoal, não informado).
  Categorizar papel por leitor/coluna/seção e evidência; finalidade não se infere
  do nome da loja nem do tipo PF/PJ. Regras inequívocas preenchem automaticamente.
- Finalidade não informada não impede catalogar uma dívida comprovada. Tampouco
  pode receber `BUSINESS` por padrão e entrar silenciosamente no lucro/despesa.
  A classificação antiga continua legível, mas deixa de ser formulário obrigatório
  de todas as linhas antes da importação.

### D3 — Procedência explícita e níveis independentes de confiança

Para banco/cartão, ciclo, datas e valores de controle, conservar candidatos e
origem: documento/página ou linha CSV, campo original, leitor/versão, derivação
ou declaração do operador. Nome do arquivo serve como pista, não prova de data.
Texto bruto/descrição/observação ficam preservados junto da versão normalizada.

Separar pelo menos:

| Dimensão | Estados de domínio propostos |
| --- | --- |
| Cabeçalho/valor devido | ausente, conflitante, validado por documento, declarado/conferido pelo operador |
| Detalhes | completos e conferidos, disponíveis mas não reconciliados, somente resumo |
| Destino financeiro | pendente, histórico de consulta, dívida ativa, substituída |
| Parcela | cobrada em documento, prevista, substituída pela cobrança, cancelada com motivo |

Essas dimensões não são novos menus. A tela traduz apenas a informação útil para
decidir. `READY` da leitura não passa a significar dívida gravada. Guardar original
não deve ser apresentado como concluir a inclusão em Contas a Pagar.

### D4 — Centavos divergentes e vencimentos conflitantes

Manter cálculos em centavos inteiros/Decimal na entrada e comparações exatas.
Não criar ajuste, tolerância genérica, encargo compensatório ou total declarado
igual à soma calculada apenas para liberar o fluxo.

O total devido validado já incorpora os componentes conforme o documento: não
subtrair novamente créditos/pagamentos que o resumo já descontou. Separar valor
nominal da fatura e saldo ainda aberto após pagamentos externos comprovados ou
confirmações já registradas no aplicativo. Nunca restaurar o saldo cheio ao enriquecer
uma fatura que já recebeu pagamentos.

Há dois percursos distintos, com precondições próprias:

1. **Integração completa:** cabeçalho inequívoco/conferido, cobertura das linhas
   verificada, papéis identificados, controles e detalhe reconciliados exatamente.
2. **Cobrança pelo total comprovado, detalhe pendente:** total e vencimento
   confiáveis/conferidos permitem cadastrar a fatura pelo valor declarado. Guardar
   todas as linhas e a diferença, identificando o detalhe como não reconciliado.
   Isso não declara cobertura completa nem cria uma linha de diferença. A revisão
   deixa claro qual valor será cobrado e o que falta conferir. Só um resumo coerente
   não prova, por si só, que todos os detalhes estão certos.

O segundo percurso evita impedir o controle da dívida porque o documento possui
uma diferença real entre detalhe e resumo. Não é um botão "ignorar erros":
origem, total, vencimento e identidade do ciclo continuam obrigatórios; leitura
ambígua de um desses controles bloqueia a dívida ativa. Falha de leitura das linhas
continua pendência de correção, sem ser ocultada pelo título líquido.

Para outubro, mostrar os dois vencimentos com procedência e pedir resolver uma
vez para o ciclo. Não escolher 24, 26 ou deslocamento para dia útil automaticamente.
Uma declaração explícita pode definir o vencimento operacional, preservando a
divergência e a origem da decisão; não se torna prova de qual informação o emissor
pretendia. Oferta de quitação/mínimo/renegociação não substitui o total devido
nem cria contrato de parcelas sem evidência de contratação.

### D5 — CSV sem controle, compilações e resumos

- Detectar pelo conteúdo: extrato, fatura detalhada, compilação de ciclos ou
  índice/resumo. Extensão, nome do banco e nome "fatura" não bastam.
- CSV com `date,title,amount`: conservar leitura atual e reconhecer parcela no
  título usando a mesma normalização validada para PDF. Total calculado das linhas
  recebe esse nome; não é total declarado. Vencimento de compra não vira vencimento
  da fatura. Complementar automaticamente com documento do mesmo ciclo quando
  identidade e correspondência forem comprovadas; fora disso, pergunta de cabeçalho
  uma vez por ciclo, com campos disponíveis já preenchidos e procedência visível.
- Lista de metadados: importar o que existe por banco/ciclo e marcar "somente
  resumo". Pode originar cobrança total após conferir dados e situação em aberto;
  não produzir estabelecimento, compra ou parcela inexistente. Extratos indexados
  não originam dívida de cartão. Empréstimo/renegociação é documento de outro tipo,
  guardado com explicação; não implementar um módulo de crédito para esta amostra.
- Compilação: uma leitura pode gerar vários segmentos, cada um com origem/ciclo,
  controles, itens e pendências. Escolher/confirmar os segmentos aptos sem recadastrar
  linhas; o restante permanece pendente. Confirmar um segmento não confirma os outros.
- Resumo + PDF + CSV do mesmo ciclo enriquecem a mesma fatura. Divergência vira
  candidata à revisão; não duplicação ou escolha silenciosa do arquivo mais recente.
  Reimportação idêntica não altera estado; versão mais detalhada acrescenta evidência
  sem outro título. Se o valor devido mudar, exigir resolução do controle e revisar
  o título em transação, preservando pagamentos e saldo não negativo. Valor revisto
  abaixo do já pago é exceção de crédito/pagamento a resolver, não saldo negativo
  nem estorno automático de caixa. Até a resolução, manter a dívida vigente identificada.

### D6 — Histórico não equivale a saldo ainda devido

Os arquivos abrangem 2024–2026. Não importar cada total histórico como nova dívida
aberta nem marcar tudo como pago porque venceu. Na conferência do conjunto,
perguntar quais faturas representam saldo ainda em aberto; permitir resposta em
grupo por origem/ciclo. Sem evidência/resposta, guardar para consulta com situação
financeira pendente, fora do total confirmado a pagar. Pagamento em uma fatura
posterior só liquida/substitui uma dívida anterior com correspondência comprovada.

Saldo anterior é componente do total, não nova compra. Antes de ativar fatura que
o contém, identificar a dívida anterior representada e substituí-la na medida
comprovada. Se existir sobreposição financeira ambígua, guardar a fatura e pedir
resolver o vínculo relevante; não somar dois possíveis saldos da mesma dívida.

### D7 — Compras existentes, pagamento e resultado do negócio

Importar cria evidência/dívida, sem movimentar caixa ou estoque. Um pagamento
impresso é fato externo, não instrução para chamar `record_payable_payment`.
Quando houver pagamento já registrado, vincular a evidência ao movimento;
uma nova confirmação de desembolso continua usando o fluxo existente e idempotente.

Uma compra de insumos já cadastrada pode possuir título próprio. Com identidade
forte ou confirmação pontual do vínculo, o saldo remanescente integral representado
na fatura é transferido para a cobrança do cartão em transação única. Conservar
título, pagamentos anteriores, vínculo à compra e trilha de substituição. O título
anterior deixa de compor o aberto e não aceita outro pagamento desse saldo; usar
estado explícito de substituição, nunca `PAID` ou pagamento fictício. A primeira
versão não deve realizar transferência parcial ambígua: solicita resolução do caso.
Cancelamento/estorno posterior precisa respeitar esses vínculos, sem reabrir duas
dívidas ou alterar estoque. Similaridade de loja/data/valor só sugere candidato.

Para pagamentos de faturas:

- Manter um `PayablePayment` e um débito real de caixa por confirmação. Não dividir
  o livro-caixa em pagamentos artificiais para cada item da fatura.
- Conservar uma composição tipada do pagamento: estoque, despesa do negócio,
  pessoal e não classificado, com soma exata igual ao desembolso. Reutilizar campos
  existentes quando suficientes; adicionar colunas opcionais no pagamento para
  essa composição e referência à revisão, sem escondê-la em `notes`.
- Usar vínculos/finalidades comprovados. Crédito sem finalidade definida numa
  fatura mista não autoriza presumir redução proporcional da despesa empresarial;
  a parte sem composição demonstrável fica não classificada. Se a finalidade
  de todo o líquido for inequívoca, classificar o líquido nessa finalidade.
- Para pagamento parcial de composição conhecida, distribuir centavos pelo saldo
  remanescente das partes, proporcionalmente, com maiores restos e desempate estável.
  Gravar a composição usada; estorno reverte exatamente essa composição, sem
  recalcular pela classificação atual. Não ratear créditos ambíguos para fechar lucro.
- Centralizar a leitura dessa composição para dashboard e relatório ativo.
  Não classificado participa do total efetivamente pago e aparece como pendência,
  mas não é despesa operacional presumida. Estoque mantém o custo vendido existente.

Não construir agora um editor contábil completo para reclassificar pagamentos
antigos. Uma mudança posterior de finalidade após pagamento não pode reescrever
o livro-caixa nem refazer a composição histórica silenciosamente.

### D8 — Parcelas futuras e troca por cobrança efetiva

Uma linha `3/10` com valor da parcela permite criar a ocorrência atual e **sete**
previsões, não dez novos títulos. O valor impresso é o da parcela; não dividir
novamente esse valor pela quantidade total. `10/10` não gera previsão restante.

Guardar série, número/total, origem, item de partida, competência prevista,
valor/dia estimados e procedência. Sem calendário comprovado, usar mês seguinte
e mesmo dia civil limitado ao último dia do mês; marcar como estimativa, sem
aplicar feriados/dias úteis por conta própria. Não usar `+30 dias`. Sem dia base
confiável, mostrar mês previsto, sem inventar vencimento exato.

Previsões ficam em estrutura própria e aparecem na mesma consulta de Contas
a Pagar, identificadas e totalizadas separadamente. Não são títulos `OPEN`
pagáveis nem alteram caixa/resultado. Quando o documento informar cronograma
real, conservar a distinção entre valor informado e projeção calculada.

Ao chegar a fatura seguinte, vincular parcela real à série e substituir a previsão
correspondente atomicamente. Somar uma vez: parcela real compõe o líquido da nova
fatura; previsão substituída sai da estimativa. Ausência de uma linha na nova fatura
não prova cancelamento. Não encerrar previsão automaticamente por ausência.

Identidade forte ou vínculo de série já confirmado permite automação. Sem ID,
comparar origem/cartão, descrição preservada/normalizada, sequência, valor e mês;
correspondência única continua candidata se não provar identidade. Pedir resolução
da série ambígua, não classificar todas as compras. Até resolver, retirar o par
possivelmente sobreposto da soma de estimativa livre, apresentando-o como pendente
de vínculo; manter a cobrança real no total confirmado. Preservar duas compras
iguais legítimas e multiplicidade. Estorno/cancelamento só encerra série quando
a evidência disser a quais parcelas se refere.

## 4. Persistência e contratos: mudança mínima proposta

Reutilizar `FinancialDocument`, `FinancialImportPreview`, `FinancialStatement`,
`FinancialStatementItem`, `FinancialTransaction`, pareceres/evidências existentes,
`AccountPayable` e `PayablePayment`. Evitar um segundo livro de contas a pagar.
Documentos/previas/revisões continuam versionados e imutáveis; projeção e estado
operacional são derivados, com alterações registradas e fatos antigos preservados.

### 4.1 Estruturas novas e extensões previstas

Nomes abaixo são contrato proposto para orientar a implementação; a migração deve
reutilizar estruturas equivalentes se já existirem quando a execução começar.

| Estrutura | Conteúdo mínimo e restrições |
| --- | --- |
| `financial_bill_cycles` | `source_id`, identidade não nula do ciclo, referência, statement/revisão vigente, título líquido opcional e único, estados de controle/detalhe/destino, revisão operacional. Banco/card vêm da origem; datas conflitantes não definem duas identidades. Um ciclo sem identidade suficiente permanece pendente. |
| `financial_bill_payable_links` | Relações tipadas do ciclo com título principal, títulos/saldos anteriores substituídos e compras existentes; valor representado, item quando aplicável, revisão/autoria e reversão referenciada. Sem linha positiva de "diferença". Proteger um mesmo saldo contra duas representações ativas. |
| `financial_installment_occurrences` | Série e origem, número/total, item de partida, mês/data/valor previstos ou informados, estado e item/ciclo real substituto. Unicidade por série+número; uma ocorrência real não confirma duas previsões ativas. |
| Extensões em evidência/revisão | Segmento estável para múltiplos ciclos; vínculo ao ciclo; papéis neutros separados de finalidade; procedência e candidatos de controle. Reutilizar pareceres para registrar decisão de controle e novas revisões, sem alterar resultados antigos. |
| Extensões em título/pagamento | Origem/ciclo acessíveis por relação; estado de substituição e finalidade não informada tratados em todos os consumidores; composição opcional tipada do pagamento e revisão de origem. Linhas legadas mantêm significado anterior. |

Itens e descrições não precisam de outra tabela de lançamentos paralela: reaproveitar
os itens/transações existentes e sua multiplicidade. Não persistir identidade,
saldo, parcela ou classificação somente numa concatenação de descrição ou no JSON
genérico de auditoria. Campos de procedência podem usar JSON tipado/versionado;
valores e relações que determinam totais precisam de contrato e validação explícitos.

Não flexibilizar `is_balanced` da revisão antiga para dizer que um detalhe divergente
fechou. O título líquido do novo fluxo verifica D4 e guarda seu nível de completude.
Adequar os vínculos/triggers do gerador legado ou manter percurso separado por
versão explícita; nunca desabilitar globalmente os bloqueios antigos.

### 4.2 API e transação

- Evoluir o resultado da prévia de forma versionada/aditiva: tipo de conteúdo,
  segmentos, campos/candidatos/procedência, papéis, parcelas, totais calculados e
  declarados separados, pendências e capacidade de cadastrar cobrança/detalhes.
- Manter confirmação atual de segmento único compatível. Para múltiplos segmentos,
  usar confirmação explícita por IDs estáveis; retornar statement/ciclo/título e
  previsões efetivamente gravados. Nunca confirmar silenciosamente o primeiro ciclo.
- O comando final de integração recebe revisão esperada, decisões pontuais e
  segmentos selecionados; retorna IDs, reutilizações, pendências e efeito financeiro.
  Reutilizar `confirm`/`generate-obligations` quando os contratos comportarem isso;
  se não, adicionar um único comando orquestrador e reutilizar os mesmos serviços.
  A UI deve ter uma confirmação final, não obrigar o usuário a executar cada API.
- Cada segmento é atômico: evidência confirmada, ciclo, título, vínculos e previsões
  ou nenhum desses efeitos novos. Para lote, resposta por segmento e reenvio seguro;
  falha em um não pode marcar todos como concluídos. Preparar leitura fora da trava.
- Usar `BEGIN IMMEDIATE`, `IdempotencyManager`, chave por operação/conteúdo/segmento
  e revisão esperada. Timeout/repetição/conflito entre clientes não criam outro
  título, série ou pagamento. Conflito retorna estado recuperável, sem reenvio cego.
- Consulta de títulos inclui `financial_source`, ciclo, completude, contagem/detalhes
  dos itens e dados da parcela. Filtros por origem, estabelecimento e período devem
  ser do servidor. Total do filtro é calculado sobre todo o resultado, não só a
  página carregada. Estimativas e pendências não entram no total confirmado.

### 4.3 Migrações e compatibilidade

Partida registrada: Alembic `fe4b5c6d8714`, 48 tabelas. Verificar novamente na
execução, sem assumir que permaneceu igual. Criar migrações versionadas aditivas,
testadas desde banco vazio e cópia preenchida; sem `create_all` no startup.
Adicionar tabelas financeiras à lista de readiness/exclusão de criação automática.

Validar FKs, índices, CHECKs nomeados, unicidades, triggers de imutabilidade e
reversões. Não depender de `UNIQUE` com coluna anulável para impedir duplicidade
de ciclo. Preferir evitar reconstrução das tabelas de evidência; se indispensável,
preservar explicitamente dados e proteções na migração e testar inserções inválidas.
Não editar migrações históricas. Migração não cria dívidas retroativas, pagamentos,
finalidades ou parcelas a partir das importações de teste antigas.

Cliente e servidor devem negociar a capacidade/versão do novo fluxo. Leitor antigo
continua evidência histórica; reprocessamento gera nova prévia. Cliente incompatível
recebe orientação de atualização e não tenta o gerador antigo como fallback.

## 5. Etapas executáveis e critérios de saída

Sequência: **E1 → E2 → E3 → E4 → E5**. Subtarefas permitem parar em pontos seguros;
não exigem chats novos ou nova autorização a cada uma. Não abrir uma etapa de
"completude bancária" depois delas. E1 isolada não é entrega da função ao usuário.

### E1 — Corrigir entrada, normalização e controles

**Objetivo:** dados corretos, origem preservada e dúvidas localizadas; zero efeito
financeiro antes da confirmação. A01/A02/A03/A04/A05/A06.

1. **E1.1:** preservar seleção; detectar conteúdo antes de leitor por banco;
   impedir a sugestão Mercado Pago de conta para cartão e fallback PicPay→Nubank.
   Devolver sugestão/ambiguidade utilizável, sem lista de opções técnicas para o usuário.
2. **E1.2:** extrair parcelas de CSV e PDF por normalizador compartilhado; conservar
   texto, sinais e observações. Preencher papel automaticamente quando inequívoco,
   separando finalidade; validar `1 ≤ atual ≤ total`, datas e dinheiro.
3. **E1.3:** coletar controles com procedência, comparar todos os vencimentos
   relevantes, distinguir total/mínimo/oferta/subtotal e diferença detalhe/resumo.
   Vincular complemento compatível sem tomar compilação como verdade bancária.
   Codificar capacidades e pendências D3/D4/D5 no contrato versionado.

**Arquivos principais:** `client/lib/views/financial_imports_view.dart`
(`_pickDocument`, `_suggestReader`), `client/lib/services/financial_import_service.dart`,
`backend/app/services/financial_readers.py`, `financial_pdf_readers.py`,
`financial_previews.py`, `backend/app/schemas/financial_readers.py`.
Normalizador compartilhado pode ficar em módulo pequeno em `backend/app/services/`;
não duplicar regex monetária/de parcelas no Flutter.

**Verificar:** T01–T07; CSV 05/06 mantêm 21/13 linhas e passam a 9/3 parcelas
estruturadas; PDF 06 mantém 28 movimentos; PDF 07/08 mantêm 39/22 linhas e 3/2
parcelas; divergências preservadas, outubro acusa ambas as datas. Leitor de conta
não é forçado a cartão. Saída inclui teste positivo de cabeçalho completo e casos
de dado ausente; não declarar resolvida a integração financeira nesta etapa.

### E2 — Integrar a cobrança real ao banco e aos pagamentos existentes

**Dependência:** contratos E1. **Objetivo:** primeira entrega de ponta a ponta
de fatura de ciclo único, com saldo líquido e detalhamento, inclusive créditos.

1. **E2.1:** implementar ciclo, vínculos, finalidade neutra e sua migração conforme
   seção 4; a tabela de agenda fica para E4. Primeiro teste positivo completo com dados sintéticos públicos e
   referência exata; testar resumo isolado e detalhe divergente como estados distintos.
2. **E2.2:** substituir a restrição "só positivos, sem créditos" pelo comando
   de integração D1/D4. Total zero/saldo credor não cria título positivo; mantém
   fatura e crédito informativo, sem compensá-lo automaticamente em outro ciclo.
   Documento com pagamento anterior não recebe nova baixa automática.
3. **E2.3:** concluir duplicidade por ciclo, substituição comprovada de saldo
   anterior/título comercial, revisões concorrentes e tratamento de títulos legados.
   Duplicata por hash é só o primeiro caso, não toda a deduplicação.
4. **E2.4:** integrar pagamento/estorno, composição e relatórios D7; testar
   compra de insumos previamente registrada, crédito genérico, fatura mista e
   finalidade não informada. Corrigir o fallback atual do dashboard que considera
   qualquer saída não pessoal/não estoque uma despesa operacional.
5. **E2.5:** adaptar o mínimo das telas existentes para confirmar uma fatura e
   abrir seu título/detalhes. Não deixar esta etapa apenas como API ou diagnóstico.

**Arquivos principais:** modelos/schemas `financial_imports.py`,
`financial_bill_semantics.py`, `financial.py`; serviços `financial_previews.py`,
`financial_bill_semantics.py`, `financial_imports.py`, `financial.py`,
`business_dashboard.py`; APIs `financial_imports.py`/`payables.py`; schemas
`business_dashboard.py`; `backend/alembic/versions/`. Novo serviço de ciclos
em `backend/app/services/financial_bill_cycles.py` pode concentrar a orquestração.
Flutter: serviço de importação, `financial_bill_review_view.dart`,
`financial_header_review_view.dart`, `payables_view.dart`, modelo/serviço de títulos.
Consumidores adicionais de natureza/status devem ser encontrados por busca
direcionada; preservar contratos de relatórios ativos e compatibilidade legada.

**Verificar:** T05/T06/T10/T11/T14/T15. Uma confirmação cria um título líquido
com itens acessíveis; reenvio cria zero adicionais; pagamento parcial e estorno
conservam saldo e composição; importação não movimenta caixa/estoque. Demonstrar
também PDF 07 como cobrança com detalhe pendente, se controles e situação em aberto
forem explicitamente conferidos, sem chamar essa amostra de sucesso integral.

### E3 — Concluir os formatos fornecidos e simplificar a conferência

**Dependência:** E1/E2. **Objetivo:** tratar o conjunto do usuário sem recadastro
de linhas, com compilações, histórico e consultas úteis. A02/A03/A07/A08.

1. **E3.1:** reunir dados preenchidos, banco/cartão, total, vencimento e exceções
   na conferência existente. Retirar classificação de finalidade por linha e
   formulário vazio como percurso padrão. Mostrar só perguntas indispensáveis,
   inclusive quais saldos históricos continuam abertos. Confirmação final retorna
   resultado real e acesso a Contas a Pagar; guardar evidência é resultado distinto.
   **Texto confirmado pelo usuário em 19/10/2026:** quando o documento tiver sido
   lido e a confirmação depender de resolver vencimentos conflitantes, substituir
   “Leitura bloqueada” por **“Documento lido · confira o vencimento para continuar”**.
   Mostrar as datas com procedência e oferecer o caminho para decidir qual usar.
   Reservar mensagens de falha de leitura para problemas reais de extração;
   outras pendências devem explicar seu motivo específico. Ajuste previsto para
   E3, aplicado no código; situação e evidências na retomada única.
2. **E3.2:** adaptadores específicos dos formatos auditados: CSV de metadados,
   CSV 07 por referência, PDF 02 por ciclo e PDF 03 por células/coordenadas com
   recomposição de linhas quebradas. PDF 01/04/05 são índices: reaproveitar
   normalização de resumo, sem simular compras. Separar todas as 12 linhas de
   PDF 03/CSV 07 por papel antes de contar lançamentos financeiros.
3. **E3.3:** enriquecer mesmo ciclo com PDF/CSV/resumo em qualquer ordem,
   comparando multiconjunto e identidade disponível. Divergências de redação,
   valores, totais ou multiplicidade não são sobrescritas silenciosamente.
4. **E3.4:** filtros existentes recebem banco/cartão, estabelecimento e atalhos
   Hoje, Esta semana (segunda a domingo), Este mês, Próximo mês. Usar dia civil
   de São Paulo; não deslocar vencimento por UTC. Respeitar padrão comum de filtros
   e mostrar o intervalo. Total considera todo o filtro, mesmo com paginação.
5. **E3.5:** revisão visual agrupada das telas alteradas, celular e Windows, com
   componentes/tema existentes e textos em `app_pt.arb`. Não redesenhar navegação.

**Arquivos principais:** leitores/prévias/schemas da E1; serviços de ciclo da E2;
`client/lib/views/financial_imports_view.dart`, `financial_header_review_view.dart`,
`financial_bill_review_view.dart`, `payables_view.dart`,
`client/lib/widgets/payables/payable_filters_panel.dart`,
`client/lib/models/account_payable.dart`, `client/lib/services/payable_service.dart`,
API `backend/app/api/v1/payables.py`, serviço `financial.py`, l10n e testes correspondentes.

**Verificar:** T04/T07/T08/T09/T10/T16 e matriz da seção 6. O usuário não escolhe
leitor, sinal, colunas ou finalidade para cada linha. Um resumo continua resumo;
extrato continua extrato. Conferir consultas com dívida importada positiva, não
uma lista vazia. Pendências específicas continuam visíveis e fora dos totais indevidos.

### E4 — Parcelas dos próximos meses e continuidade sem duplicação

**Dependência:** ciclos e consulta E2/E3. **Objetivo:** entregar D8, sem duplicar
o valor atual nem tratar estimativa como boleto emitido.

1. **E4.1:** migração da agenda e criação automática de restantes com regra
   mensal, limites de data, centavos e procedência. Não usar a rotina genérica
   `create_account_payable(total_installments=...)`: ela divide um total e usa
   aproximação de 30 dias, enquanto o valor importado normalmente já é a parcela.
2. **E4.2:** mostrar agenda e totais separados na consulta financeira existente;
   dia desconhecido aparece no mês, sem data exata fabricada. Não permitir pagar
   uma previsão como se fosse título confirmado.
3. **E4.3:** próxima fatura substitui previsões por ocorrências reais; preservar
   séries ambíguas, multiplicidade, divergência de valor/dia, cancelamento
   comprovado e importação fora de ordem. Mesmo arquivo ou evidência equivalente
   não cria outra série nem reativa previsão substituída.

**Arquivos principais:** `backend/app/models/financial_imports.py` ou módulo próprio
de agenda, migração nova, serviço pequeno `financial_installments.py`, integração
no serviço de ciclos e consultas de títulos; schemas/APIs e modelos/serviços/views
Flutter da E3. Não mexer em recorrência de aluguel ou parcelamento manual alheio.

**Verificar:** T12/T13/T16. Caso sintético `3/10` → sete previsões, `10/10` → zero;
31/jan → último dia de fevereiro sem deriva acumulada do dia-base; ano bissexto;
fatura seguinte altera previsto para real e não soma duas vezes. Usar parcelas
reais do conjunto como verificação adicional, sem fabricar seu calendário bancário.

### E5 — Homologar, registrar limites e atualizar o aplicativo

**Dependência:** E1–E4. **Objetivo:** demonstrar a função que será usada, não só
aprovar testes unitários ou deixar o servidor ligado.

1. **E5.1:** executar a matriz privada dos 19 arquivos em base isolada migrada,
   primeiro isoladamente e depois no mesmo conjunto; ordem inversa, reimportação,
   PDF+CSV, mesmos bytes com nomes diferentes, falha/reenvio e próxima fatura.
   Referência independente compara campos e multiplicidade, além de saldo final.
2. **E5.2:** teste de telas reais com API HTTPS real, incluindo confirmação,
   detalhes e filtros com títulos existentes. Testar também o seletor nativo e a
   janela Windows do build final, manualmente se a automação não estiver disponível;
   registrar limite como pendente, não simular aprovação. Android/iPhone não ficam
   certificados por um teste de widgets/Windows; não criar empacotamento iOS agora.
3. **E5.3:** executar suítes afetadas a cada etapa e suítes gerais/análise antes
   da entrega; construir somente depois das fontes finais. Registrar versão,
   migrações, hashes, resultados e correspondência entre código e build instalado.
4. **E5.4:** backup consistente e plano de restauração antes de migração/ativação
   principal; testar a migração em cópia. Atualizar servidor e cliente compatíveis.
   Reversão de versão preserva novos dados; não executar downgrade destrutivo ou
   restaurar backup antigo sobre operações novas sem tratar essas operações.
5. **E5.5:** só importar documentos selecionados na base principal depois da
   homologação do comportamento. Valores/datas/saldos ainda ambíguos dependem
   das respostas concretas da conferência; ensaio não autoriza inventá-las.
   Importações antigas de teste são descartáveis, mas sua limpeza não inclui
   compras, vendas, estoque ou toda a base. Limpar apenas se fizer parte da execução
   autorizada, com escopo e referências verificados.

**Saída:** relatório final por amostra com destino/IDs/pendências, prova de títulos
e agenda nos filtros, saldos antes/depois, duplicidade zero e efeitos de pagamento
e estorno esperados. Atualizar guias das mecânicas e memórias na mesma entrega.
Se uma amostra ficar sem dado necessário, dizer exatamente qual e o que está
importado; não declarar "todos os PDFs homologados" pelo simples fim do roteiro.

### E5.6 — Corrigir o percurso de faturas antes de encerrar a homologação

**Execução autorizada pelo usuário em 20/10/2026; implementada e ativada no Release 1.0.3+4. Aceitação nativa pendente; E5 permanece aberta.**
Prioridade confirmada: fazer a importação funcionar de forma compreensível para
um usuário comum. O usuário rejeitou a apresentação atual das duas conferências,
mas adiou a reforma visual/padronização geral para evitar retrabalho e custo.
O recorte funcional foi planejado antes da implementação. Seu exemplo de chegar à solução a partir
do aviso expressa uma necessidade de continuidade; **não é pedido de inserir
links**, nem aprovação de um componente, layout ou texto específico.

#### Achados e alcance

| Evidência | Implicação para a correção |
| --- | --- |
| Usuário abriu o seletor nativo, escolheu PDF e chegou à conferência. | Essa parte do percurso foi observada; o seletor é a janela anterior à leitura, não algo que deveria abrir depois dela. Não conta como confirmação completa da fatura. |
| Processo aberto aponta para o Release E5; executável e três fontes inspecionadas coincidem com a evidência do build. | Não atribuir os sintomas a esquecimento de compilação. As falhas abaixo estão nas fontes entregues. |
| `AppFinanceView` exibe `Histórico e cadastros` somente com `c.error != null`. | No sucesso, desaparece o acesso a `PayablesView`, onde existem pesquisa por banco/cartão, todos os períodos e agenda. O filtro compacto de Financeiro → Pagar é outro controle; o roteiro anterior misturou os dois. O usuário não deve precisar provocar erro nem conhecer a arquitetura para encontrá-los. |
| Prévia com 22 itens conserva conflito 24/26, seis `PDF_CONFLICTING_HEADER` por página e diferença de +2 centavos. A tela mapeia vários códigos para a mesma mensagem genérica. | Explicar que ler os lançamentos e conhecer vencimento/total são verificações distintas. Agrupar pela causa e pelo campo afetado; conservar as páginas como evidência consultável, sem apresentar seis problemas independentes. Distinguir o conflito de data da diferença monetária. |
| A prévia orienta escolher vencimento, mas os controles de escolha estão em `FinancialBillIntegrationView`. | A instrução deve permitir resolver a questão sem procurar outra tela ou recomeçar o fluxo. Escolher o mecanismo após comparar as opções; não presumir que deva ser um link. |
| `_launchCardBillDirect` e outras ações abrem `FinancialBillReviewView`, enquanto a cobrança líquida usa outra view. | Há destinos sobrepostos com rótulos diferentes. Mapear ações por estado/documento e deixar um caminho principal inequívoco; manter histórico e funções legadas necessárias, sem apagar dados ou exigir classificação de cada compra. |
| O ensaio HTTPS monta importação e Pagar diretamente. | Sua aprovação não prova que esses destinos sejam alcançáveis a partir da entrada real do aplicativo. Regressão deve começar pelo mesmo caminho que o usuário utiliza. |

#### Alternativas comparadas

| Alternativa | Consequência |
| --- | --- |
| Corrigir apenas o acesso ausente e acrescentar explicações espalhadas | Recupera parte da navegação, mas mantém a busca por ações e a sobreposição das revisões. Insuficiente para fechar o relato. |
| Corrigir o acesso e organizar o percurso funcional com os componentes visuais existentes | **Recomendação para alinhar:** resolver perguntas no contexto, reduzir decisões e apresentar resultado/destino claros, sem trocar tema ou iniciar reforma estética. Pode exigir ajustes pontuais de texto e composição funcional; isso precisa ser alinhado antes da implementação. |
| Refazer agora o design de todo o aplicativo | Amplia escopo/custo e contraria a prioridade atual. Adiado; usar o manual e o catálogo existentes como base de um planejamento próprio posterior. |

#### Sequência do recorte autorizado

1. **Restabelecer o caminho real de Pagar.** Definir acesso encontrável em sucesso,
   lista vazia e erro, com contexto/filtros preservados. Conferir o alcance comum
   de Pagar/Receber para evitar regressão. O nome/posição do acesso ainda é uma
   escolha de apresentação, não uma exigência de manter o rótulo antigo.
2. **Especificar a conferência pela tarefa.** Para cada situação, registrar o que
   foi lido, o que está incerto, a consequência, o próximo passo e o resultado
   após agir. Começar pelo caso real de 22 lançamentos: conflito de vencimento e
   diferença monetária são assuntos distintos; não dizer apenas que o documento
   inteiro está bloqueado. Cada pergunta precisa ter seu controle acessível no
   contexto; a entrada atual abre a conferência unificada, e a leitura original fica disponível para consulta.
3. **Investigar antes de pedir intervenção.** Conferir nos originais se 24 e 26
   representam realmente vencimentos concorrentes ou datas de funções diferentes.
   Preencher automaticamente origem/controles quando houver evidência compatível,
   reaproveitar decisões já confirmadas do mesmo ciclo e reconhecer reimportação.
   Só solicitar decisão quando restar dúvida real. Não escolher data por maioria,
   nome de arquivo ou conveniência; não compensar centavos nem afirmar saldo real.
4. **Eliminar sobreposição de ações.** Comparar os destinos por estado: documento
   lido, fatura já guardada, cobrança existente, resumo e evidência histórica.
   Definir uma ação principal por tarefa e explicar funções opcionais pelo
   resultado que produzem. Classificação econômica continua opcional e separada
   do registro da cobrança. Distinguir consultar, resolver pendência e confirmar;
   conservar histórico, reenvio seguro e proteção contra duplicidade.
5. **Validar e entregar o recorte aprovado.** Ao implementar, testar os estados
   afetados e o percurso pela entrada real do aplicativo, incluindo retorno após
   resolver uma questão. Depois das fontes finais, executar verificações gerais
   proporcionais, gerar novo build, conferir versão/hashes e atualizar o app.
   Repetir o percurso nativo com instruções iguais às ações efetivamente visíveis.
   Não pedir ao usuário que depure código ou adivinhe termos financeiros.

#### Critérios adicionais de saída, preservando T01–T16

- Partindo de Financeiro → Pagar com consulta bem-sucedida, o usuário consegue
  localizar a cobrança de teste, seus itens, pesquisa por origem e agenda.
- A prévia distingue lançamentos lidos de dados ainda incertos; informa quais
  ações estão disponíveis e por quê. Uma causa repetida em páginas não vira uma
  lista de bloqueios genéricos. Evidência original permanece acessível.
- Uma decisão disponível é feita no ponto indicado, conserva os dados e produz
  retorno coerente. Pendência resolvida não continua apresentada como atual;
  a prévia imutável original continua preservada para auditoria.
- Dados comprovados são reaproveitados; perguntas necessárias são específicas.
  Mantêm-se as diferenças −6/+2, a comparação distinta de 1 centavo e as regras
  de vencimento, parcelas, finalidade, histórico e duplicidade do plano.
- Ações com nomes diferentes não levam à mesma tarefa sem motivo explícito.
  O resultado da confirmação permite chegar à cobrança existente e à agenda,
  sem decorar telas antigas ou recadastrar/classificar cada linha.
- Aceitação inclui o usuário conseguir explicar o que foi lido, o que falta e
  onde agir, sem um instrutor externo. T16 passa pela entrada de produção e pelo
  build final; testes que montam destinos isolados continuam apenas apoio.

**Pesquisa dirigida — 20/10/2026:**
[GOV.UK Design System, Error message — clareza, especificidade e consistência](https://design-system.service.gov.uk/components/error-message/)
fundamenta explicar o problema e a forma de resolvê-lo, preservando os dados.
[W3C, Understanding SC 3.3.3: Error Suggestion](https://www.w3.org/WAI/WCAG22/Understanding/error-suggestion.html)
orienta oferecer ajuda conhecida para corrigir o erro. Aplicação ao ZM: explicar
a condição e tornar a decisão alcançável, sem transferir falhas do serviço ao
operador. Limites: referências web não prescrevem o componente Flutter, não
aprovam um layout e não certificam acessibilidade nativa; o projeto conserva
tema/navegação e a fundamentação de design inteligente existentes.

**Resultado do recorte:** acesso visível sob Pagar/Receber em sucesso/vazio/erro;
atalho Todos os períodos conserva os filtros de origem; faturas atuais abrem
Conferir fatura diretamente, com uma opção por data e todas as páginas. A mesma
leitura recupera a decisão salva, sem nova cobrança. Resultado oferece título e
agenda; classificação continua opcional. O PDF de 22 itens realmente informa
26 na capa e 24 nos cabeçalhos internos, portanto não há desempate automático.
A abertura móvel foi encurtada após retorno do usuário sobre a captura de
320 px/texto 170%; também conferida em 390 px/texto normal e desktop.

**Retorno nativo posterior — 20/10/2026:** o usuário confirmou os filtros e a
visualização/rolagem dos itens da cobrança 90 por **Pagar e amortizar**. A
conferência continua incompreensível para ele; caminhos legados/extratos não
foram unificados, e excluir/desfazer uma importação está ausente. Não considerar
E5.6 aceita nem E5 concluída. O caso HISTORY mostrado já estava salvo pelo agente
no ensaio; orientar a procurar decisões nele foi inadequado. Pagamento e agenda
não foram confirmados pelo usuário. O novo requisito e a direção de simplificação
estão no [esclarecimento do escopo](ESCOPO_IMPORTACAO_DE_FATURAS.md#esclarecimento-vigente--20102026).
Próximo trabalho exige planejar o fluxo compreensível e o desfazimento completo,
sem inserir exclusão apenas do PDF nem confundir reformulação visual adiada com
correção funcional. Nenhum novo código/build/dado alterado neste registro.
566 testes backend, 405 Flutter, HTTPS pela entrada real e análise limpa dão
suporte técnico, sem substituir compreensão/aceitação nativa. Evidências e
pendências vigentes ficam na [retomada](RETOMADA_IMPORTACAO_FATURAS.md).
Padronização visual global permanece um trabalho posterior separado.

### E5.7 — Simplificar a tarefa e permitir desfazer uma importação

**Autorização:** após o retorno nativo, o usuário mandou executar as correções
necessárias; não transferir tarefas de desenvolvimento para ele nem exigir outra
autorização para o recorte. A reforma visual global continua separada.

**Implementado:** Ver documento é a entrada principal em toda a lista; leituras
antigas compatíveis de cartão são atualizadas ao abrir, e os acessos anteriores
ficam em Outras opções. Situação guardada e conta em Pagar têm mensagens distintas;
a fatura guardada oferece adicionar ao financeiro. OCR/conciliação deixam de ser
conhecimento exigido no percurso comum. Escolhas atuais de vencimento/destino são
preservadas ao reimportar e conferir novamente.

Excluir importação apresenta os efeitos e exige confirmação única com snapshot.
Retira contas/previsões próprias e devolve contas de compras/saldos anteriores à
situação separada, preservando valores/pagamentos. Conta própria já paga exige
estorno explícito do pagamento incorreto; documento posterior dependente oferece
acesso direto à sua retirada antes da anterior. Reimportar o arquivo não ativa
a conta automaticamente; a confirmação reutiliza o título em nova revisão.
Arquivo/revisões originais e auditoria ficam preservados, sem nova dívida duplicada.

**Persistência:** migração `f17e8f901037`, estado em `financial_import_removals`,
proteção SQL de restauração restrita à retirada registrada e projeções ativas de
documentos/contas/agenda/evidências. Nova capacidade `import_removal_version=1`;
contratos e procedimento no [guia de Pagar](CONTAS_A_PAGAR.md#excluir-e-reimportar-uma-importação--e57).
Matriz/leitores anteriores preservados; as condições sem retirada mantêm o contrato
financeiro. Não apagar provas para compensar erros nem estornar pagamentos sem
intenção explícita. Testes, ativação e limites finais ficam na retomada única.

## 6. Aceitação por arquivo fornecido

Aliases mantêm a correspondência da auditoria; originais e valores pessoais ficam
fora do Git. "Cadastro possível" abaixo depende de identidade, controles,
situação em aberto e ausência de sobreposição conforme D3–D7.

| Amostra | Resultado exigido após implementação |
| --- | --- |
| PDF 01 | Resumos separados por origem/ciclo; sem compras inventadas; enriquecer ciclos existentes; não abrir todo histórico automaticamente. |
| PDF 02 | Dois segmentos de 21/13 linhas, parcelas estruturadas iguais aos CSV 05/06; complemento de controle identificado; não duplicar se CSV veio antes. |
| PDF 03 | Recuperar as 12 linhas tabulares disponíveis, separar ciclos e controles/encargos; preservar resumos adicionais sem misturá-los com compras. |
| PDF 04 | Resumos por banco/ciclo/tipo; total ausente/ambíguo vira pendência; não alegar suporte a compras originais desses bancos só por ler o resumo. |
| PDF 05 | Índice de extratos, histórico/evidência; zero dívidas de cartão inventadas. |
| PDF 06 | Manter 28 ocorrências exatas e fluxo de extrato; zero dívida gerada só porque contém saídas. |
| PDF 07 | Manter 39 linhas/3 parcelas; diferença -6 centavos preservada; cadastro pelo total validado com detalhe pendente ou integração completa somente se a divergência for efetivamente esclarecida. |
| PDF 08 | Manter 22 linhas/2 parcelas finais; diferença +2 e comparação distinta de 1 centavo visíveis; vencimentos 24/26 explícitos; sem título ativo enquanto data/controles estiverem sem decisão. |
| PDF 09 | Reutilizar PDF 08; zero nova fatura/título/série. |
| CSV 01 | Três resumos Inter interpretados sem recadastrar linhas; nenhum estabelecimento/parcela inventado. |
| CSV 02 | 47 linhas de metadados preservadas e segmentadas por origem/tipo/ciclo; não somar duplicatas dos demais arquivos. |
| CSV 03 | Sete resumos Itaú; saldo credor e campos ausentes não viram dívida positiva fictícia. |
| CSV 04 | Cinco resumos Mercado Pago no tipo correto; eliminar sugestão incompatível de sinal antes da prévia. |
| CSV 05 | 21 linhas exatas, nove parcelas estruturadas, cabeçalho complementado quando comprovado; demais faltas resolvidas uma vez por ciclo. |
| CSV 06 | 13 linhas exatas, três parcelas estruturadas, mesmo tratamento de cabeçalho; nenhuma classificação manual obrigatória das 13 linhas. |
| CSV 07 | 12 linhas lidas automaticamente pelo conteúdo, separadas em ciclos/papéis; não criar 12 títulos nem duplicar PDF 03. |
| CSV 08 | Sete resumos de extratos; não inventar seus movimentos ou dívidas. |
| CSV 09 | Oito resumos/tipos PicPay, inclusive documento de renegociação identificado; não usar leitor Nubank nem contratar parcelas por oferta. |
| CSV 10 | Cinco resumos Santander, origem preservada e campos ausentes explícitos. |

## 7. Casos de teste e evidência necessária

Os casos abaixo especificam comportamento; adaptar os testes existentes em vez
de duplicar suites. Fixtures públicas devem ser sintéticas e representar a forma
dos problemas. Arquivos do usuário e referências independentes ficam privados.

| ID | Caso e condição objetiva de aprovação |
| --- | --- |
| T01 | Escolha explícita Santander continua Santander após arquivo; instituição incompatível e dois cartões possíveis geram pergunta localizada. |
| T02 | Datas, descrições, sinal, centavos e multiplicidade coincidem com referência independente; controles/ofertas não entram como compras. |
| T03 | Parcela em texto/coluna/seção vira campo válido; padrões ambíguos não viram parcela; `1/1`, `3/10`, `10/10` e inválidos cobertos. |
| T04 | CSV sem vencimento/total não os inventa; complemento confiável preenche; declaração fica identificada; soma calculada não é total declarado. |
| T05 | Compra/encargo/pagamento/crédito/controle reconhecidos sem finalidade manual por linha; finalidade desconhecida não bloqueia dívida comprovada nem altera lucro. |
| T06 | Diferença de um centavo já é detectada; caminhos completo versus detalhe pendente respeitam D4; zero linha compensatória. |
| T07 | Conflito 24/26 preservado com procedência; ação final depende de decisão; nome do arquivo não decide. |
| T08 | Arquivo com múltiplos ciclos/bancos confirma segmentos selecionados; falha/reenvio não duplica segmentos concluídos. |
| T09 | Resumo sem compras, extrato, saldo credor, total ausente e renegociação têm destino próprio; zero dívida fictícia. |
| T10 | Compra100+compra50-crédito20 → título130 e três componentes; filtros por banco/loja/dia/semana/mês funcionam; títulos comuns continuam visíveis. |
| T11 | Saldo anterior já representado, compra com título e pagamento existente não duplicam dívida/caixa/estoque; dois eventos iguais legítimos não são colapsados. |
| T12 | Agenda gera apenas parcelas restantes; datas mensais sem deriva, estimativa separada, real substitui prevista uma vez e não altera parcela já paga. |
| T13 | Mesmo PDF duas vezes, PDF+CSV, resumo antes/depois, ciclo seguinte, fora de ordem e duas séries parecidas: multiplicidade e vínculo corretos; ambiguidade explícita; enriquecer fatura paga não restaura dívida nem gera estorno automático. |
| T14 | Pagamento parcial, total e estorno: caixa e saldo exatos, composição conservada, finalidade não classificada exposta, estoque não contado novamente como despesa. |
| T15 | Timeout após commit, dois clientes, revisão vencida, migração vazia/preenchida e escrita inválida: unicidade, rollback, FKs e imutabilidade permanecem. |
| T16 | Percurso real selecionar→preenchido→conferir→Contas a Pagar→detalhes→filtros→próximos meses; conferência não recadastra cada linha; total do filtro independe da página. |

Testes existentes de partida: backend `test_financial_readers.py`,
`test_financial_pdf.py`, `test_financial_imports.py`,
`test_financial_semantic_obligations.py`, `test_financial_import_safety.py`,
`test_financial_statement_post_treasury.py`, testes de migração financeira e
`test_business_dashboard.py`; Flutter `financial_pdf_import_test.dart`,
`financial_header_review_test.dart`, `financial_semantic_obligations_test.dart`,
`multibank_and_password_import_test.dart` e testes de Pagar/filtros/pagamentos.
O diagnóstico em `test_financial_bill_allocations.py` continua apoio, não critério
substituto pelo fluxo de geração funcionando.

**Critério final:** T01–T16 e matriz sem omissões silenciosas. Separar resultados
integrais, cobrança com detalhes pendentes e somente evidência; pendências reais
não podem ser contadas como casos aprovados integralmente. Conservar efeitos
esperados, não exigir zero caixa num teste que efetivamente confirma pagamento.

## 8. Pesquisa dirigida realizada e aplicação

Consulta de fontes primárias em **19/10/2026**. Não foi feita pesquisa de APIs de
bancos ou de IA porque elas não resolvem um impedimento demonstrado desta etapa.
As escolhas D1–D8 são decisões de engenharia para este app, não regras bancárias
atribuídas às bibliotecas abaixo.

| Dúvida | Fonte e aprendizado | Aplicação e limite |
| --- | --- | --- |
| Como recuperar colunas/linhas quebradas sem trocar de stack? | [pdfplumber, documentação oficial, Extracting text/tables](https://github.com/jsvine/pdfplumber#extracting-text): palavras com coordenadas, recortes e extração de tabelas. | Usar geometria na compilação PDF 03 e conservar o leitor que já acertou os originais. A biblioteca não decide o papel financeiro nem prova cobertura. |
| Como impedir duplicatas com campos ausentes? | [SQLite, CREATE TABLE, §3.6–3.7](https://www.sqlite.org/lang_createtable.html#unique_constraints): `UNIQUE` considera valores NULL distintos; CHECKs têm semântica própria de NULL. | Identidade ativa de ciclo não nula e validação explícita; testar concorrência. Documento sem identidade suficiente fica pendente. Não basta uma constraint com campos opcionais. |
| Como evoluir o SQLite preservando regras? | [Alembic, Batch migrations, constraints e FKs](https://alembic.sqlalchemy.org/en/latest/batch.html#dealing-with-constraints): reconstrução exige atenção a constraints e referências. | Preferir alterações aditivas; testar dados, constraints e triggers no banco preenchido. Fonte não certifica a migração deste projeto nem dispensa backup. |
| Como projetar mês seguinte sem acrescentar biblioteca? | [Python, calendar.monthrange](https://docs.python.org/3/library/calendar.html#calendar.monthrange): fornece quantidade de dias do mês. | Calcular ano/mês e limitar o dia-base; testar fevereiro e mudança de ano. Não determina vencimento bancário, feriados ou condições contratuais. |

Não atualizar dependências apenas porque a documentação consultada aponta uma
versão mais nova. Verificar a API na versão fixada do projeto ao implementar.

## 9. Economia de tempo/tokens e manutenção do plano

O ganho esperado vem de reutilizar diagnóstico, mapa de arquivos, decisões e
casos de aceitação. Não existe garantia de que planejar e implementar gastem
menos tokens totais que uma execução direta, nem estimativa numérica confiável
antes do trabalho. O plano não substitui testar arquivos financeiros reais.

- Usar o roteiro curto de retomada e ler apenas seções da etapa, depois das
  leituras obrigatórias do projeto. Não reenviar todos os PDFs/textos no contexto.
- Reutilizar hashes e referências privadas; executar comparações locais que
  retornem diferenças/contagens, não dumps de dados pessoais ou de centenas de linhas.
- Alterar o menor conjunto coerente; reaproveitar normalizadores, fluxo de
  pagamento, componentes e testes existentes. Não escrever um segundo plano de
  alocações ou fazer novo estudo visual geral para concluir esta função.
- Pesquisar somente uma dúvida ainda aberta. Registrar fonte/aplicação neste
  arquivo; não repetir pesquisa cuja premissa e versão não mudaram.
- Testar o recorte durante a etapa, suítes completas antes da entrega e novamente
  apenas por novas alterações/falhas. Resultados antigos não validam fontes novas.
- Ao encerrar incremento, atualizar um único estado no roteiro: concluído,
  arquivos/contratos alterados, testes e limites, próximo item concreto. Não copiar
  o plano inteiro para cada memória; elas apontam para este documento.

**Próxima ação ao autorizar execução:** E1.1 e E1.2, com T01/T02/T03, preservando
o trabalho local existente. Avançar depois para os controles E1.3 e a primeira
integração completa E2. Não começar construindo funcionalidades fora deste recorte.
