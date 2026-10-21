# Contas a pagar, pagamentos e recorrência

**Entrada FE-055:** Financeiro → Pagar apresenta os recortes atuais. Abrir uma
conta segue para detalhe/histórico e pagamento revisado. **Histórico e cadastros**, logo abaixo das abas, conserva pesquisa ampliada, criação, recorrência, histórico e
demais ações existentes. A integração não altera as regras abaixo.

Revisão: **20/10/2026**. [Índice](README.md).

**FE-053 — pagamento revisado implementado no código:** o botão Pagar / Amortizar
abre detalhe → formulário → revisão → confirmação, com Integral padrão, Parcial,
data/forma efetiva, edição e recuperação de envio. Ver o
[guia do piloto real](PILOTO_PAGAR_REVISADO.md) para contratos, persistência,
compatibilidade, datas, testes e limites. Receber e tema global mantêm seus
incrementos próprios. É necessário atualizar servidor e cliente correspondentes;
não representa atualização automática do aplicativo instalado.

## Para que serve e interface

Em **Contas a Pagar**, cadastrar obrigações, pesquisar/filtrar, abrir detalhes e confirmar pagamentos. Informar beneficiário, descrição, categoria, natureza, valor e vencimento. Obrigações também podem nascer da confirmação de uma compra.

`BUSINESS` representa despesa da empresa. `PERSONAL_WITHDRAWAL` representa retirada pessoal. A classificação participa do resultado gerencial; não é apenas texto de apresentação.

## Regras do backend

`POST /payables` cria um ou mais títulos. Parcelamento divide o valor em centavos entre os títulos, distribui o resto e conserva o total. Quando não são fornecidas datas individuais, as parcelas usam intervalos de 30 dias.

`POST /payables/{id}/payments` registra pagamento parcial ou total, limitado ao saldo. O fluxo atual resolve a conta interna sem exigir uma conta com saldo selecionada pelo operador. Confirmar uma despesa comum não movimenta produtos ou cestas. A entrada de produtos pertence à [compra](COMPRAS.md).

## O que mexe no banco

| Ação | Persistência |
| --- | --- |
| Criar obrigação | Insere `accounts_payable`, com valor original, saldo, natureza, vencimento, parcelas e recorrência. |
| Pagar | Insere `payable_payments`, lança débito em `cash_flow_entries` e atualiza pago/saldo/status do título. |
| Estornar pagamento | Marca pagamento `REVERSED`, devolve saldo à obrigação e registra crédito inverso. |
| Cancelar título | Exige ausência de valores pagos; marca `CANCELED`, zera saldo e registra motivo nas notas. |
| Próxima recorrência | Cria novo título `OPEN`; não confirma pagamento. |

Os status usuais são `OPEN`, `PARTIAL`, `PAID` e `CANCELED`. O estorno de pagamento usa `/payables/payments/{id}/cancel`. O cancelamento de título usa `/payables/{id}/cancel`.

## Excluir e reimportar uma importação — E5.7

**Percurso:** Financeiro → **Resumo** → **Extratos e faturas** → Documentos
enviados → **Excluir importação**. Em Conferir fatura, o botão com ícone de
lixeira e descrição **Excluir importação** abre a mesma conferência.

A tela mostra o arquivo e as contas que serão retiradas. Se a fatura havia
reunido contas já existentes de compras ou saldos anteriores, informa quais
voltarão a aparecer separadamente, com seus pagamentos preservados. As previsões
de parcelas originadas na importação saem da agenda. **Excluir esta importação**
é a única confirmação; antes dela, abrir a tela não altera os dados.

Pagamento confirmado na própria conta da fatura impede sua exclusão automática.
A tela oferece **Ver conta e pagamentos**: estornar somente um pagamento lançado
por engano, voltar e conferir a exclusão novamente. Documentos posteriores que
dependam da importação aparecem com **Ver importação relacionada**, permitindo
desfazer primeiro o documento dependente. O aplicativo não apaga pagamentos,
compras, estoque ou entradas/saídas independentes para forçar uma exclusão.

A retirada é lógica: o documento sai da lista e os seus efeitos saem dos
valores correntes; arquivo, leituras, revisões e histórico do desfazimento ficam
preservados internamente. Uma conta própria sem pagamento é cancelada e retirada
das consultas comuns. Não há lançamento artificial de caixa ou arredondamento.

Selecionar o mesmo arquivo novamente recupera a leitura. A conta cancelada não
volta ao aberto só por selecionar ou ler o arquivo: é preciso escolher adicionar
a Contas a Pagar e **Salvar fatura**. O título existente é reutilizado em nova
revisão, sem duplicar a dívida ou as séries de parcelas. Também é possível guardar
o documento sem recolocar a conta no financeiro. Resposta perdida retoma o mesmo
comando; mudanças de pagamentos/vínculos exigem conferir novamente o resultado.

Em **Documentos enviados**, prévias do mesmo arquivo são agrupadas pelo PDF/CSV
original. O cartão resume a leitura mais recente; **Ver as N leituras deste
arquivo** expande data, origem e situação das leituras anteriores para abrir uma
delas. Reprocessamentos do mesmo conteúdo são leituras do arquivo, não novos
documentos. A situação de uma fatura conta apenas títulos abertos ou parciais;
títulos pertencentes a uma importação retirada aparecem como histórico guardado.

**Persistência:** migração aditiva `f17e8f901037` cria
`financial_import_removals`, com geração, visibilidade e efeitos registrados em
transação auditada. A proteção de contas substituídas passa a permitir somente
restauração explicitamente registrada nessa exclusão, sem alterar valores ou
pagamentos anteriores. Leituras/revisões/vínculos originais continuam imutáveis.
Consultas de documentos, contas, evidências ativas e agenda consideram a retirada.
`GET /financial-imports/documents/{id}/removal` apresenta efeitos e impedimentos;
`POST /financial-imports/documents/{id}/remove` exige snapshot e chave de reenvio.
A capacidade `import_removal_version=1` exige servidor e migração correspondentes.

## Fatura única de cartão — E2

Disponível no Release Windows **1.0.4+5**, com servidor e migrações
correspondentes ativados na base de testes autorizada. A situação da verificação
nativa e os limites ficam na [retomada](RETOMADA_IMPORTACAO_FATURAS.md). Após ler uma fatura atual na
importação financeira, o aplicativo abre diretamente **Conferir fatura**, com revisão da origem,
total, vencimento e situação da dívida. O padrão é **Guardar por enquanto; decidir depois**. Guardar no histórico ou manter pendente conserva evidência;
Escolher **Adicionar a Contas a Pagar: esta fatura ainda precisa ser paga** cria a conta pelo total conferido. A confirmação
final é única e abre o título existente em **Contas a Pagar**. Em seu detalhe,
**Itens da fatura** conserva compras, créditos, datas e parcelas atuais.

Compra de R$ 100,00 + compra de R$ 50,00 − crédito de R$ 20,00 gera **um título de
R$ 130,00 e três componentes**, sem somar os itens novamente. Total zero ou credor
fica informativo, sem título positivo ou compensação automática em outro ciclo.
Pagamento impresso em uma fatura anterior não produz baixa de caixa.

A lista tem a ação principal **Ver documento** em todos os tipos; faturas compatíveis abrem **Conferir fatura**. Documentos antigos de cartão ganham leitura atualizada quando o formato é reconhecido.
**Outras opções deste documento** reúne os acessos anteriores, fora da tarefa principal;
**Consultar leitura original** conserva a leitura imutável para auditoria. A
classificação econômica é opcional. Ao reabrir a mesma leitura confirmada, o
resultado salvo aparece sem solicitar novamente o vencimento e sem criar cobrança.
**Adicionar esta fatura a Contas a Pagar** aparece quando a fatura positiva está somente guardada. A escolha abre a revisão com o destino preenchido; é necessário conferir e salvar. **Alterar conferência salva** continua disponível para as demais revisões; o resultado oferece
acesso ao título existente e às **Parcelas dos próximos meses**.
O seletor do Windows é a janela usada em **Selecionar documento**, antes de
**Ler documento**. Após ler, a conferência abre dentro do aplicativo.

A identidade do ciclo é origem/cartão + mês do vencimento confirmado. Outra
conferência cria revisão imutável do mesmo ciclo, preservando o título e seus
pagamentos. Reenvio idêntico é reutilizado; revisão concorrente vencida é recusada.
Resumo sem detalhes e detalhe divergente são estados distintos: o operador deve
aceitar expressamente o detalhe pendente, e a diferença permanece visível, sem
ajuste artificial. A E3 permite decidir o vencimento conflitante com procedência,
conforme a conferência guiada abaixo.

Ao enriquecer o ciclo com outro resumo, componentes comprovados anteriormente
continuam conservados se o novo arquivo os omitir. Componentes fornecidos e
divergentes exigem revisão explícita. Um resumo sem linhas de detalhe mantém
**Somente resumo**, sem apresentar diferença calculada contra compras ausentes;
essa diferença só existe quando há detalhes para comparar.

O papel da linha (compra, pagamento, crédito etc.) é separado de sua finalidade.
O padrão é **Finalidade não informada**, sem classificação por estabelecimento.
Isso permite registrar uma dívida comprovada e pagá-la sem presumir despesa
empresarial. Negócio → Resultado mostra os pagamentos sem finalidade separadamente;
eles entram no total pago, mas não reduzem o resultado como despesa operacional.
O relatório financeiro ativo usa o mesmo cálculo.

| Ação E2 | Persistência e proteção |
| --- | --- |
| Confirmar fatura | `financial_bill_cycles` mantém identidade/revisão e título opcional; `financial_bill_cycle_revisions` conserva controles, diferença, procedência e composição. `financial_bill_cycle_items` preserva papel/finalidade de cada item da evidência. |
| Declarar saldo aberto positivo | Cria ou atualiza um `accounts_payable` líquido com natureza `UNCLASSIFIED`. A importação não lança caixa nem estoque. |
| Substituir obrigação já existente | `financial_bill_payable_links` exige vínculo explícito, motivo e saldo integral conferido. O título antigo vira `SUBSTITUTED`, conserva valores/pagamentos e aponta `superseded_by_id`; deixa de compor o aberto. |
| Pagar a fatura | Um `payable_payments` e um débito, com composição imutável em `stock_cents`, `business_cents`, `personal_cents`, `unclassified_cents`, cuja soma é o valor pago. |
| Pagar parcialmente / estornar | Distribuição proporcional por maiores restos inteiros; estorno reutiliza a composição original e um crédito inverso, sem recalcular a classificação histórica. |

Estoque exige compra confirmada e comprovação de que a linha representa seu saldo
integral. Saldo anterior exige ciclo anterior do mesmo cartão; títulos legados
ativos do mesmo ciclo precisam de substituição integral explícita. Títulos
retirados por uma exclusão de importação registrada são preservados para auditoria,
mas não bloqueiam uma nova revisão como cobranças ativas. Vínculos parciais ou
ambíguos são recusados. Cancelar compra/título ou estornar pagamento antigo que
reabriria um saldo já representado também é recusado. Esses vínculos e a
classificação econômica explícita têm seletores opcionais na E3. A finalidade
continua neutra por padrão; conferir uma fatura não exige classificar cada linha.

Crédito sem finalidade comprovada em uma fatura mista mantém o total como não
classificado. Uma nova revisão não pode reduzir o total abaixo do já pago nem
apagar sua composição. Parcelas futuras aparecem na agenda E4, sem criar títulos
futuros por inferência. Os filtros por banco/loja estão descritos abaixo.

## Conferência guiada e consultas — E3

Incluída no mesmo Release. Em **Documentos financeiros**, índices
e compilações oferecem **Conferir ciclos do documento**. A origem é preenchida
quando há uma única correspondência compatível; ambiguidades exigem escolha.
Cada segmento tem comando e resultado próprios: confirmar um não confirma os
outros. Índices de extratos e renegociações guardam evidência, sem gerar dívida.
Resumo de cartão conserva total/vencimento disponíveis e a indicação de que não
contém compras; ausência de dados não é substituída pela soma ou data atual.

**Conferir fatura** reúne banco/cartão, controles, diferença e itens.
Oferece controles já lidos do mesmo cartão para complementar CSV, com origem e
versão vinculadas. Compilação continua identificada como compilação fornecida.
No conflito, mostra **“Documento lido · confira o vencimento para continuar”**,
as datas e páginas, e permite escolher uma delas. A confirmação registra motivo,
candidatos e escolha, sem apagar a diferença entre resumo e detalhe.

Se **Salvar fatura** estiver desativado, um aviso no alto da tela informa a próxima
etapa pendente e oferece um atalho até ela. A conferência final fica no fim dos
controles, depois da escolha do destino; quando houver diferença entre os itens e
o total, a caixa para guardar a diferença aparece antes. Se o servidor recusar a
confirmação por um vínculo conhecido, o aviso explica a ação e rola até a área
destacada em vermelho. Conflito de ciclo ou de arquivo com várias faturas orienta
voltar aos documentos, pois não há um campo nesta tela para resolver esses casos.

Cobranças existentes aparecem como candidatas de vínculo; só a escolha explícita
comprova a representação do saldo integral. A finalidade pode ser informada em
uma seção opcional do item, sem inferência pelo estabelecimento. Saldo anterior
comprovado continua sujeito ao vínculo exigido pela E2 antes de ativar cobrança.
Histórico/pendência não entram automaticamente no aberto; o resultado distingue
evidência guardada, saldo credor e cobrança efetivamente criada ou atualizada.

Resumo, PDF e CSV do mesmo ciclo enriquecem a mesma cobrança em qualquer ordem.
Comparação usa multiconjunto de data/descrição/valor/parcela/identidade: repetições
legítimas são conservadas. Diferenças de redação, multiplicidade e controles exigem
aceite explícito da revisão. Resumo posterior conserva itens, finalidades,
procedência original, vínculos e pagamentos; não restaura saldo já pago.

Em **Financeiro → Pagar → Histórico e cadastros → Filtros**, há banco ou
cartão, estabelecimento e atalhos **Todos os períodos / Hoje / Esta semana / Este mês / Próximo mês**.
**Todos os períodos** limpa somente as restrições de data, conservando banco/cartão
e os demais filtros. O acesso à consulta completa aparece em sucesso, lista vazia e erro;
o filtro compacto da aba Pagar continua sendo uma consulta distinta.
Semana vai de segunda a domingo; o intervalo civil fica visível. Usa a data do
negócio fornecida pelo servidor, com contingência civil UTC−03. O resumo representa
todo o filtro, antes da paginação, contando a fatura uma vez mesmo que vários
itens correspondam à loja. Sem filtro de origem/loja, títulos comuns permanecem.
Se o resumo completo falhar, a interface identifica os valores como somente dos
registros carregados, sem apresentá-los como total completo.

**Contratos E3:** `pdf_auto` v4, `csv_auto` v2; capacidades
`bill_review_version=2`, `segments_version=1`, `payable_filter_version=1`.
`POST /financial-imports/previews/{id}/select-segment` recebe hash do pai, chave do
segmento e origem; reutiliza a seleção. A integração acrescenta
`due_conflict_resolved`, `control_preview_id` e `accept_content_change`, mantendo
o comando v1 da E2. `GET /payables` e `GET /payables/summary` usam os mesmos filtros,
incluindo `source_id`, `source_query` e `merchant`; summary ignora paginação.
Sem nova migração E3: prévias/revisões conservam seleção, comparação, procedência
e decisão em suas estruturas existentes. Exige o schema E2 e cliente/servidor
correspondentes; não há fallback para gerador ou servidor incompatível.

Evidência, testes e próximo incremento estão na
[retomada única](RETOMADA_IMPORTACAO_FATURAS.md). Seletor nativo e aparelhos
físicos não são certificados por testes de widgets/HTTPS; A agenda E4 está descrita abaixo; homologação final/ativação ficam em E5.

**Contratos E2 preservados:** `GET /financial-imports/capabilities` anuncia `bill_cycle_version=1`;
`GET /financial-imports/previews/{id}/bill-integration` prepara a conferência;
o parâmetro opcional `reference=AAAA-MM` consulta a revisão do mês informado
quando o arquivo não traz vencimento, inclusive após conflito concorrente.
`POST /financial-imports/previews/{id}/integrate-bill` recebe a versão 1, origem/hash,
revisão esperada, controles, situação, motivo e decisões/vínculos opcionais, com
`X-Idempotency-Key`. `GET /financial-imports/bill-cycles/{id}` e o detalhe de Pagar
expõem os componentes. O pagamento revisado da fatura informa
`expected_bill_revision`; o servidor recusa composição alterada mesmo com saldo
igual. O gerador legado não pode criar obrigações adicionais para uma evidência
já integrada ao ciclo.

**Migração:** `ff5c6d7e9815`, após `fe4b5c6d8714`, adiciona quatro tabelas, vínculo
opcional no título e campos opcionais no pagamento. Dados legados permanecem
intactos e sem classificação retroativa. As novas evidências e composições têm
FKs, checks, unicidade e proteção contra alteração/exclusão; downgrade recusa
descartar ciclos ou pagamentos com composição. Validada em bases descartáveis e
cópia preenchida; aplicada à base atual de testes na E5, após backup verificado.

Referências: [serviço de ciclos](../backend/app/services/financial_bill_cycles.py),
[composição dos pagamentos](../backend/app/services/financial_payment_composition.py),
[tela de confirmação](../client/lib/views/financial_bill_integration_view.dart),
[testes de integração](../backend/tests/test_financial_bill_cycles.py) e
[teste da migração](../backend/tests/test_financial_bill_cycle_migration.py).

## Agenda das parcelas importadas — E4

Em **Financeiro → Contas a Pagar**, abaixo dos filtros, **Parcelas dos próximos
meses → Consultar agenda e vínculos** abre a agenda do mesmo recorte. O total
confirmado da fatura continua separado das **Estimativas livres** e das
**Estimativas aguardando vínculo**. Os totais cobrem todo o filtro, inclusive
quando a agenda tem mais páginas. Banco/cartão, estabelecimento, favorecido,
categoria e período vêm do servidor; filtros de situação de título, finalidade
ou somente atrasadas excluem previsões, pois elas não têm esses estados.

Uma compra `3/10` de R$ 100,01 gera sete previsões de R$ 100,01, sem dividir o
valor da parcela nem criar títulos adicionais. `10/10` não gera restante. O mês
avança pelo calendário; o dia-base 31 limita fevereiro e volta a 31 em março,
inclusive no ano bissexto. Não presume feriados nem calendário bancário. Na
conferência, **Estimar os próximos vencimentos pelo dia desta fatura** pode ser
desmarcado: a agenda conserva o mês e mostra **Dia desconhecido · somente mês
previsto**. Um filtro parcial de dias inclui essa previsão se atravessa seu mês,
sem apresentar um dia exato. A fatura atual ainda exige seu vencimento conferido.

Ao importar outra fatura, a parcela real já compõe a cobrança líquida. Sem
identificador de série comprovado, correspondências por origem, descrição,
sequência, valor/data disponíveis e mês são candidatas, inclusive quando únicas.
A agenda mostra valor/dia real e estimado, compra de origem e multiplicidade.
**Vincular à série** confirma a continuidade; **É outra compra** conserva uma
compra distinta. Ambas exigem motivo. Até decidir, as séries candidatas ficam
fora da soma livre; essa retenção conservadora abrange as previsões da série,
pois sua identidade permanece em dúvida. Uma parcela já vinculada não pode ser
ocupada por duas ocorrências reais. A decisão substitui a previsão uma vez;
reenvio, PDF/CSV/resumo equivalentes e enriquecimento de fatura paga não reativam
previsões nem restauram o saldo. Importação fora de ordem conserva os fatos e
pede vínculo quando necessário. Divergências continuam explícitas na revisão.

Ausência de parcela não cancela série. **Registrar cancelamento comprovado** só
aparece quando existe crédito/estorno da mesma origem: selecionar a evidência,
a primeira parcela cancelada e registrar o motivo comprovado pelo documento.
A decisão mantém o histórico e não altera uma cobrança real ou um pagamento;
parcela substituída continua real mesmo se a série posteriormente for cancelada.
Previsões não têm ação de pagar nem IDs de título; o endpoint de pagamento as
recusa. Não movimentam caixa, estoque ou resultado gerencial.

**Persistência/contrato:** migração aditiva `f06d7e8f0926`, após `ff5c6d7e9815`,
cria `financial_installment_series`, `financial_installment_occurrences`,
`financial_installment_forecasts` e `financial_installment_decisions`, com FKs,
checks, unicidades e triggers de imutabilidade/consistência. A integração do ciclo
grava suas ocorrências/previsões na mesma transação e devolve IDs de séries,
previsões e pendências. Não projeta importações antigas durante a migração.
O estado da agenda deriva de evidências e decisões preservadas; não há segundo
livro de contas a pagar. Downgrade com dados de agenda é recusado; reversão da
aplicação deve preservar as tabelas e os fatos novos.

`GET /financial-imports/capabilities` anuncia `installment_agenda_version=1`;
cliente incompatível exige atualização. `GET /payables/summary` acrescenta
`installments`, sem misturar os totais; `GET /financial-imports/installments`
retorna agenda paginada, totais completos, pendências e evidências de estorno.
`POST /financial-imports/installments/decisions` exige autenticação, chave de
idempotência, snapshot da agenda, revisão da ocorrência, decisão e motivo.
Conflito atualiza a consulta; falha incerta mantém o mesmo corpo/chave para
reenviar. O comando de integração aceita `estimate_installment_day` (padrão
verdadeiro). A recorrência e o parcelamento manual existentes não mudaram.

Implementação: [agenda](../backend/app/services/financial_installments.py),
[modelos](../backend/app/models/financial_installments.py),
[tela](../client/lib/views/financial_installment_agenda_view.dart) e
[testes](../backend/tests/test_financial_installments.py).
Situação das validações e ativação: [retomada única](RETOMADA_IMPORTACAO_FATURAS.md).

## Exemplo e limites

Obrigação de R$ 300,00: pagar R$ 100,00 deixa R$ 200,00 em aberto. Estornar esse pagamento volta a R$ 300,00. Uma retirada pessoal paga aparece separada das despesas operacionais no dashboard.

A recorrência usa ação explícita `/payables/{id}/next-recurrence`, não um agendamento automático pelo simples cadastro. Os intervalos atuais são semanal +7 dias, mensal +30 dias e anual +365 dias; não representam cálculo por mês do calendário.

Uma obrigação de compra pode ter vínculo `purchase_id`. Esse vínculo evita descontar novamente compras de estoque como outras despesas no cálculo gerencial. Não cancelar só o título esperando estornar a entrada de estoque: são operações diferentes.

## Onde conferir

- [Tela](../client/lib/views/payables_view.dart) e [serviço](../client/lib/services/payable_service.dart).
- [API](../backend/app/api/v1/payables.py), [serviço financeiro](../backend/app/services/financial.py), [modelos](../backend/app/models/financial.py).
- [Testes](../backend/tests/test_payables.py).
