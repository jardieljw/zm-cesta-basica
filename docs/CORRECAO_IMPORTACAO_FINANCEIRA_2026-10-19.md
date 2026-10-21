# Importação financeira: primeira etapa de correção

**Esclarecimento do usuário — 19/10/2026, após a entrega:** os PDFs enviados e
os dados bancários importados eram exclusivamente testes. Os lançamentos gerados
não têm valor de histórico financeiro a recuperar. Usar os PDFs disponíveis como
amostras para testar o aplicativo; não criar trabalho de preservação/recuperação
contábil dessas importações. Os registros financeiros de teste são descartáveis.
Isso não se estende a estoque, vendas, cadastros ou outros dados do aplicativo.
Nenhuma exclusão foi executada nesta atualização documental.

Data: **19/10/2026**. Implementação autorizada após a
[auditoria e pesquisa](AUDITORIA_IMPORTACAO_FINANCEIRA_2026-10-19.md).
Este guia descreve as mudanças no código, seus efeitos e a entrega de verificação.
Não certifica leitura universal nem corrige automaticamente o histórico da empresa.

## Situação da entrega inicial

**Estado atual:** a ativação posterior e o diagnóstico de alocações estão
registrados em [Entrega e próxima etapa](#entrega-e-próxima-etapa). Servidor e
cliente já foram atualizados; os parágrafos seguintes conservam o estado inicial.

Backend e Flutter foram alterados para conter os defeitos reproduzidos e oferecer
revisão explícita. **480 testes backend / 367 Flutter aprovados**, análise sem pendências e
**Windows Release compilado** em cópia isolada. A evidência consolidada, hashes,
resultado final do backend e capturas sintéticas estão em
[validação da etapa](validacoes_financeiras/correcao-2026-10-19/README.md).

O servidor que já estava em execução e o aplicativo aberto não foram substituídos.
O código novo exige atualizar cliente e servidor correspondentes. Não foi aplicada
migração, não houve escrita no banco da empresa, nem cancelamento/estorno dos
89 vínculos de obrigações e 28 movimentos `BANK_IMPORT` observados na auditoria.
Conforme esclarecimento posterior do usuário, pertencem aos testes descartáveis;
não constituem uma pendência de recuperação contábil.

## Onde usar na interface atualizada

Em **Financeiro → Extratos e faturas**, selecionar a origem e o documento, ler
e conferir a prévia, impedimentos e original. A leitura guarda evidências.
O operador deve conferir titularidade/conta/cartão; o parser não comprova esse
vínculo pelo cadastro selecionado.

- **PDF:** controles extraídos conservam sua origem. Falta de total/vencimento,
  linha monetária não interpretada, divergência ou mistura de ciclos bloqueiam
  os casos identificados. PDF protegido solicita senha transitória; senha
  incorreta permite tentar novamente. Digitalização ainda exige OCR futuro.
- **CSV:** confirmar abre **Conferir dados do documento**, com campos vazios.
  Fatura exige vencimento e total declarados; extrato exige período. Saldos,
  totais de entradas/saídas e mínimo são opcionais quando não informados.
  Nenhum campo recebe automaticamente a data de hoje, a última compra ou a soma
  das linhas como se fossem controles bancários. A confirmação do operador e
  os valores fornecidos ficam auditados como declaração, não extração do banco.
- **Fatura confirmada:** **Revisar fatura** exige escolher a finalidade de cada
  linha. Compras não são classificadas como empresa/sócio pela descrição.
  Salvar mantém versões; gerar usa a revisão vigente e salva antes as edições
  locais. Equação balanceada é uma condição necessária, não prova de dívida.
- **Extrato confirmado:** **Revisar e conciliar extrato** permite conferir cada
  ocorrência, vincular a outra evidência, confirmar uma ocorrência distinta ou
  ignorar, com motivo. Depois, vincular a movimento financeiro existente da
  mesma conta/sentido, inclusive parcialmente. O servidor verifica os saldos.
  Essa página não cria receita, despesa, dívida, recebimento ou pagamento.

Se ainda não existir a operação financeira correspondente, registrá-la no fluxo
de negócio apropriado antes da conciliação. Importação direta de dinheiro em
lote foi suspensa. A página não restaura os menus de Tesouraria arquivados.
Identidade revisada e dinheiro conciliado são condições diferentes; os avisos
do histórico não chamam mais todo vínculo de identidade de lançamento no caixa.

## Regras implementadas e limites

| Achado da auditoria | Tratamento nesta etapa | Limite restante |
| --- | --- | --- |
| AUD-01, 11, 12: controles inventados, datas trocadas e ciclos juntos | Leitor tabular preserva a data da compra e exige controles explícitos; omissões detectadas, referências compiladas, vencimentos conflitantes e múltiplos ciclos bloqueiam | Não separa automaticamente compilações em documentos/ciclos |
| AUD-02: D/C ignorado | Colunas críticas de sinal/moeda não mapeadas bloqueiam; mapeamento ambíguo também é rejeitado | Mapeamento assistido de D/C e moedas ainda não entregue |
| AUD-03: ajuste artificial de centavos | Tolerância zero nos controles alterados; diferença fica visível e revisão permanece rascunho, sem criar encargo | Divergência real precisa ser esclarecida na fonte |
| AUD-04, 05: créditos/saldo anterior gerando dívida incompleta | Geração bloqueada quando há crédito, pagamento ou saldo anterior sem modelo de alocação; nenhum título parcial é criado | Ainda implementar alocação, representação de dívida anterior e parcelas; bloquear não equivale a resolvê-las |
| AUD-06, 07, 08: ignorado, sobreposição e transferência virando dinheiro | Retirada a criação cega de caixa; revisão e conciliação explícitas reutilizam movimentos existentes | Classificação e criação assistida de novas operações bancárias continuam futuras |
| AUD-09: senha incorreta contaminando a tentativa seguinte | Falha de senha informada retorna erro recuperável antes de persistir prévia | Leitura depende de o runtime conseguir abrir o PDF com a senha correta |
| AUD-10, 13: detecção Inter e tipo incorreto | Palavra Inter delimitada; tipo de origem separado de tipo do documento; capacidades CSV divulgadas por convenção | Não homologa novos bancos |
| AUD-14: revisão antiga usada após nova divergência | Geração exige revisão vigente, sem ajuste legado de encargos; versão antiga de leitor exige reimportação | Histórico gerado antes da correção continua preservado e precisa de auditoria própria |

Há ainda bloqueio conservador de outro documento do mesmo cartão/origem com o
mesmo vencimento que já possua obrigações, evitando duplicação por reimportação.
Uma correção legítima de fatura ou duas cobranças válidas no mesmo vencimento
exigem reconciliação explícita dos vínculos; não há substituição automática.
O controle é por origem cadastrada: cadastros diferentes do mesmo cartão ainda
exigem cuidado e não constituem deduplicação bancária universal.

Uma compra de estoque só é vinculada automaticamente a um único título já
existente, aberto/parcial, de compra confirmada, com saldo suficiente e uma única
linha vinculada. Compra paga/cancelada, sem título ou com parcelas ambíguas
exige alocação específica. O vínculo conserva o título e não movimenta estoque
ou CMPM. Compras não vinculadas, gastos de sócio e encargos positivos podem gerar
os títulos previstos no fluxo existente somente após as conferências.

## Contratos de API e persistência

- `pdf_auto` passa à versão **2**, `generic_csv` à **3** e adaptadores CSV
  conhecidos à **2**. O nome interno do adaptador PDF não substitui essa versão
  global de interpretação. Relatórios/hashes anteriores permanecem imutáveis.
- O cliente consulta `/financial-imports/readers` e envia
  `expected_reader_version` na criação de prévia. A versão integra a chave
  reproduzível da tentativa. O servidor rejeita versão esperada diferente;
  o campo ausente conserva compatibilidade do hash de clientes anteriores.
- CSV de conta confronta os controles fornecidos com os movimentos. Divergência
  de total ou de abertura + líquido = fechamento retorna
  `FINANCIAL_IMPORT_CONTROL_MISMATCH`, sem confirmar o documento.
  Período divergente continua aparecendo nos controles do documento; não é
  transformado em data calculada. Controles opcionais ausentes ficam ausentes.
- `IMPORT_HEADER_DECLARED` acrescenta auditoria da confirmação CSV com
  `origin=OPERATOR_DECLARATION` e somente campos preenchidos. Não requer tabela
  nem migração nova. Autenticação, TLS, transação e idempotência centrais seguem
  sendo usados; não há acesso Flutter direto ao banco.
- `/statements/{id}/post-to-treasury` continua existindo por compatibilidade,
  mas não cria caixa. Pendências retornam `FINANCIAL_CASH_REVIEW_REQUIRED`;
  evidências já conciliadas/ignoradas retornam zero novos lançamentos. Replays
  de comandos históricos podem devolver respostas históricas, sem nova escrita.
- `/items/{id}/review` e `/reconciliations` são as rotas existentes usadas pela
  revisão bancária. A conciliação conserva `affects_ledger=false`.
- Geração usa bloqueios `FINANCIAL_REIMPORT_REQUIRED`,
  `FINANCIAL_BILL_ALLOCATION_REQUIRED`,
  `FINANCIAL_BILL_CYCLE_ALREADY_REPRESENTED`,
  `FINANCIAL_PURCHASE_ALLOCATION_REQUIRED`, `BILL_REVIEW_NOT_BALANCED` e conflito
  de revisão, mapeados para mensagens ao operador. Obrigações já geradas são
  consultadas como histórico; esse retorno não as revalida contabilmente.

Implementação: `backend/app/services/financial_pdf_readers.py`,
`financial_readers.py`, `financial_previews.py`, `financial_bill_semantics.py` e
`financial_imports.py`; cliente em `financial_import_service.dart`,
`financial_imports_view.dart`, `financial_header_review_view.dart`,
`financial_bill_review_view.dart` e `financial_bank_review_view.dart`.
Novos textos residem em `client/lib/l10n/app_pt.arb`.

## Conferência realizada

Os testes novos usam documentos sintéticos e bancos descartáveis. Cobrem os
defeitos reproduzidos, controle declarado incorreto, senha/repetição, revisão
vigente, versões, ciclo duplicado, título pago/cancelado/ausente, paginação e
fluxos válidos de geração de títulos e conciliação sem criar dinheiro.
Um caso adicional exige bloqueio mesmo quando saldo anterior e pagamento se
compensam numericamente: soma fechada não comprova a correspondência da dívida.

Releitura offline dos **7 PDFs já armazenados**, sem atualizar a base: um
extrato com **28 ocorrências** permanece legível; duas faturas divergem entre
resumo/detalhes; duas compilações ficam bloqueadas por controles/ciclos; dois
documentos continuam sem leitor. Essa rodada comprova esses bloqueios e a
preservação do caso bancário, sem substituir transcrição independente linha a
linha. Detalhes sanitizados na evidência. Reduzir confirmações indevidas não é
ampliar cobertura multibanco.

Capturas de widgets com dados sintéticos, fontes Segoe/Material reais e temas
existentes verificam as páginas novas a 390 px e a 320 px com texto 1,7×. Os
testes existentes também cobrem importação a 1200 px. Ajustados botões/rótulos
para texto ampliado. Não é certificação de cada pixel nem de Android/iPhone
físicos. Não foram alterados tema global, barra ou destinos aprovados.

## Entrega e próxima etapa

**Continuação executada — 19/10/2026:** o Release correspondente foi copiado
com seus 16 arquivos e hashes para `client/build/windows/x64/runner/Release/`,
preservando o Release anterior em `tmp/`. Cliente e servidor Python foram
iniciados, com HTTPS verificado e backup íntegro; schema já estava em fe4 e não
exigiu migração. A conexão do cliente atualizou somente o último acesso do
dispositivo; tabelas de negócio ficaram iguais ao backup. A rodada HTTPS
isolada exercitou sete PDFs, revisão/replay, conciliação parcial, anulação e
bloqueios sem alterar dinheiro. Ver [ativação](validacoes_financeiras/correcao-2026-10-19/ativacao.json)
e [runtime](validacoes_financeiras/correcao-2026-10-19/runtime-https.json).
O [diagnóstico de alocações](ALOCACOES_DE_FATURA.md) é um novo recurso apenas da
API; decisões de alocação e geração líquida continuam pendentes. As descrições
de não ativação abaixo registram a entrega anterior, não o estado desta continuação.

Release de verificação, com fontes copiadas e hashes conferidos:
`tmp/fi-client-20261019/build/windows/x64/runner/Release/`.
Usar a pasta completa; o `.exe` sozinho não leva suas dependências. Essa pasta
não substitui o aplicativo aberto nem distribui/atualiza o backend.

Antes do uso operacional, concluir a validação final registrada, preparar backup
verificado e atualizar servidor/cliente correspondentes, conferindo capacidade,
runtime PDF e origem. O backend congelado/instalador PDF continua uma entrega
separada; não certificar runtime congelado por ter compilado o Flutter.

Próximos incrementos: (1) preparar a ativação e testar o fluxo corrigido com os
PDFs fornecidos, aproveitando a validação já registrada e tratando as importações
existentes como massa de testes descartável; (2) alocação explícita de
crédito/saldo anterior/parcelas e novas operações; (3) mapeamento assistido e
homologação por layout com controles independentes; (4) avaliar OCR e fontes
estruturadas OFX/Open Finance conforme a pesquisa. A proposta anterior de
recuperação contábil dos vínculos de teste deixa de ser uma pendência. Não
generalizar descarte para a base inteira nem prometer leitura de qualquer banco.
As fontes primárias e as alternativas permanecem detalhadas na auditoria,
preservando a distinção entre evidência, proposta e implementação.
