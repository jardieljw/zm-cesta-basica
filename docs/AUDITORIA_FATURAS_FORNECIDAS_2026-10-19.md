# Auditoria das faturas fornecidas em 19/10/2026

Avaliação do comportamento atual solicitada pelo usuário **antes de qualquer
correção no aplicativo**. Resultado: **o percurso automático até Contas a Pagar
ainda não atende ao uso solicitado**. As tentativas com o conjunto fornecido
produziram zero títulos a pagar e zero parcelas futuras.

## O que foi efetivamente testado

- 19 arquivos: 9 PDFs e 10 CSVs. São 18 conteúdos distintos; dois PDFs de outubro
  são idênticos byte a byte. Nenhum dos PDFs fornecidos está criptografado e
  todos possuem texto extraível. Não se demonstrou necessidade de OCR neste conjunto.
- Upload dos bytes originais, leitura, prévia, erros e tentativa de confirmação
  pela API real, em HTTPS com o certificado local validado, num servidor separado
  e banco vazio criado pelas migrações atuais. Sem alteração de leitores/regras.
- Comparação independente com `pypdf`/`Decimal`, sem importar os leitores do app,
  e inspeção visual das páginas renderizadas com Poppler. Valores monetários
  tratados em centavos inteiros, preservando sinal e multiplicidade.
- Cinco percursos com as **telas reais Flutter**, na cópia das mesmas fontes,
  conectadas ao servidor HTTPS de teste: seleção da origem, PDF bloqueado,
  formulário de cabeçalho CSV, revisão sem classificação e Contas a Pagar vazia.
- Reenvio e preservação do original; comparação das fontes do cliente com os
  136 hashes registrados e dos arquivos de backend com a evidência anterior.
  Fontes do aplicativo e arquivos enviados permaneceram inalterados.

**Limite da interface:** foi usado o executor de widgets do Flutter com rede real.
A seleção do arquivo foi fornecida pelo ponto de teste já existente na página;
não foi pilotado o seletor nativo nem a janela Windows principal. O armazenamento
de preferências foi simulado apenas no executor, e a conexão usou credencial
exclusiva do banco de teste. Isso testa o conteúdo, ações e integração das telas,
mas não certifica o seletor do sistema operacional ou aparelhos físicos.

As primeiras execuções do roteiro temporário exigiram ajustes de compilação,
espera de animação, fechamento das conexões e marcação da conferência obrigatória.
Esses foram problemas do roteiro de teste, não achados atribuídos ao aplicativo.
A execução final completou os cinco percursos em 46 segundos. Passar esses casos
de caracterização significa reproduzir os comportamentos registrados, inclusive
os defeitos, e não aprovar a funcionalidade de importação.

## Resultado por arquivo

Os aliases abaixo correspondem à ordem dos arquivos enviados. O
[índice privado com nomes e capturas](../tmp/audit-user-files-20261019/LEIA_ME.md)
permite localizar os originais sem publicar dados pessoais no projeto.

| Alias | Documento | Resultado no fluxo atual |
| --- | --- | --- |
| PDF 01 | Consolidado geral de bancos, 3 páginas | Zero itens reconhecidos; bloqueado por ausência de cabeçalho de uma fatura única. O arquivo é uma relação de documentos, não compras individuais. |
| PDF 02 | Nubank detalhado de dois vencimentos, 2 páginas | 34 linhas reconhecidas, mas os ciclos permanecem juntos; zero campos estruturados de parcela. Bloqueado por cabeçalhos conflitantes/total ausente. |
| PDF 03 | Nubank com resumos e lançamentos de vários meses, 1 página | 5 linhas reconhecidas de 12 na tabela/CSV correspondente; há linhas quebradas entre colunas. Bloqueado por ciclos múltiplos, controles e linha monetária não interpretada. |
| PDF 04 | Resumos de outros bancos, 2 páginas | Layout não suportado; zero itens. O documento oferece principalmente totais/metadados de faturas, sem a lista de compras desses bancos. |
| PDF 05 | Relação de extratos PJ, 1 página | Layout não suportado; zero itens. É um índice de extratos, não os movimentos de conta. |
| PDF 06 | Extrato bancário PJ de agosto a outubro, 5 páginas | 28 ocorrências lidas e confirmadas como evidência. Datas e valores com sinal coincidiram com a referência independente. Não gera contas a pagar, corretamente para esse fluxo de extrato. |
| PDF 07 | Fatura bancária Nubank de dezembro, 7 páginas | 39 ocorrências e 3 parcelas estruturadas. Valores com sinal e descrições coincidiram com a leitura independente. Confirmação bloqueada por diferença entre detalhe e resumo. |
| PDF 08 | Fatura bancária Nubank de outubro, 6 páginas | 22 ocorrências e 2 parcelas estruturadas, ambas finais. Confirmação bloqueada por diferença entre detalhe e resumo. Há ainda conflito de vencimento no próprio documento. |
| PDF 09 | Segunda cópia da fatura de outubro, 6 páginas | Mesmo conteúdo de PDF 08. Documento e prévia foram reutilizados; não criou segunda fatura. |
| CSV 01 | Banco Inter, 3 linhas | Leitor sugerido não aceita os cabeçalhos. É resumo de faturas, sem compras ou parcelas individuais. |
| CSV 02 | Consolidado geral, 47 linhas | Layout incompatível com leitor sugerido; mistura bancos/ciclos/documentos, não é uma fatura única. |
| CSV 03 | Itaú, 7 linhas | Cabeçalhos não aceitos pelo leitor sugerido. É resumo de faturas, incluindo saldo credor e valores ausentes. |
| CSV 04 | Mercado Pago, 5 linhas | Leitor sugerido usa convenção de conta bancária, incompatível com origem cartão: erro `FINANCIAL_IMPORT_SIGN_MISMATCH`. O conteúdo também é resumo de faturas. |
| CSV 05 | Nubank de abril, 21 linhas | Leitura exata de datas/descrições/valores; 9 parcelas apenas no texto, zero campos de parcela. Confirmação exige cabeçalho manual. Ensaio assistido não gerou títulos. |
| CSV 06 | Nubank de março, 13 linhas | Leitura exata de datas/descrições/valores; 3 parcelas apenas no texto, zero campos de parcela. Confirmação exige cabeçalho manual. Ensaio assistido não gerou títulos. |
| CSV 07 | Nubank de julho/agosto, 12 linhas | Leitor sugerido não aceita o layout. Mapeamento explícito adicional pela API leu 12 linhas, mas isso não é o fluxo automático da tela nem prova de 12 dívidas: há totais e componentes misturados. |
| CSV 08 | Relação de extratos PJ, 7 linhas | Layout incompatível. Não contém os movimentos dos extratos. |
| CSV 09 | PicPay, 8 linhas | Tela sugere leitor de cartão Nubank; layout incompatível. O arquivo é resumo de faturas/renegociação, sem as compras individuais. |
| CSV 10 | Santander, 5 linhas | Cabeçalhos não aceitos pelo leitor sugerido. É resumo de faturas, com campos ausentes. |

O resultado primário dos 19 arquivos foi: **3 prévias aptas à conferência**
(o extrato e dois CSVs detalhados), **15 prévias bloqueadas** e **1 rejeição antes
de criar prévia** (Mercado Pago). Isso conta a cópia idêntica como arquivo submetido,
não como novo documento. A prévia adicional por mapeamento de CSV 07 é diagnóstico
separado e não entra como sucesso automático.

## Achados que afetam o uso solicitado

### A01 — Escolher arquivo pode trocar a origem já selecionada

Reproduzido na tela: selecionar Santander e depois escolher seu CSV mudou a
origem para o primeiro cartão cadastrado, Nubank no ambiente de teste. O leitor
também passou a Nubank. `_pickDocument` prioriza o primeiro cartão quando o nome
do arquivo contém “fatura”, sem preservar a origem escolhida ou reconhecer banco.

O operador consegue selecionar a origem novamente depois do arquivo, mas isso
não atende à expectativa de categorização confiável. A validação de tipo conta/
cartão não certifica a instituição ou o cartão. Não foi forçada uma importação
numa origem errada para criar dívida.

### A02 — CSV não termina em preenchimento automático

Os CSVs detalhados contêm `date`, `title` e `amount`; vencimento/total declarado
não estão nessas colunas. A tela “Guardar para revisão” exige primeiro marcar
a conferência e depois abre um segundo formulário com vencimento/valores vazios.
Não é uma simples confirmação de campos preenchidos automaticamente.

No ensaio assistido pela API, foram transcritos vencimento e total da relação
consolidada fornecida, conservando sua origem como declaração. Também foram
criadas classificações **de cenário de teste**, sem alegar que o uso empresarial/
pessoal real pudesse ser inferido da loja. As duas revisões ficaram desequilibradas
em relação a esses controles e a geração retornou `BILL_REVIEW_NOT_BALANCED`.
Nenhum valor foi ajustado, nem foi usada a soma das linhas como total declarado.
Os controles da relação consolidada não foram eleitos como verdade bancária.

### A03 — Classificação manual linha a linha permanece obrigatória

Após confirmação assistida do CSV de março, a tela real mostrou 13 itens com
classificação ainda por escolher e totais classificados zerados. As três linhas
visíveis na captura estavam sem classificação; o código inicializa todos os
itens como `UNCLASSIFIED` na ausência de revisão salva. Não existe nesse percurso
a catalogação automática solicitada. A classificação inclui empresa/sócio, além
de compra/encargo/crédito, ampliando o trabalho manual.

### A04 — Parcelas reconhecíveis no CSV não preenchem os campos próprios

Comparação independente: CSV 05 tem 9 descrições com número/total de parcela;
CSV 06 tem 3. Os 34 lançamentos conservaram texto/data/valor exatamente, mas
nenhum recebeu `installment_number`/`total_installments`. O leitor PDF dos
originais bancários preencheu esses campos em 3 e 2 linhas, respectivamente.

A geração atual cria apenas a cobrança/parcela da ocorrência importada. Não
cria a agenda das parcelas restantes nem sua substituição sem duplicidade pela
fatura seguinte. Não foram geradas parcelas artificiais para “testar” uma função
que não existe. A consulta por dias/semanas/meses com **dívidas importadas** não
pôde ser homologada porque nenhum título foi produzido.

### A05 — Os bloqueios dos PDFs bancários não são só falta de leitor

Na referência independente, as 39 linhas de dezembro e 22 de outubro tiveram
os mesmos valores com sinal e descrições do aplicativo. A inspeção visual cobriu
as páginas de resumo e todos os detalhes. Ao somar os valores impressos:

- dezembro: diferença de **6 centavos a menos** no líquido dos detalhes em
  relação ao líquido dos componentes do resumo;
- outubro: diferença de **2 centavos a mais**, além de diferença de 1 centavo
  entre um subtotal impresso da seção de financiamento e “Outros lançamentos”
  no resumo. São comparações distintas, não ajustes a aplicar.

Os resumos fecham suas próprias equações. As diferenças acima também aparecem
na leitura independente dos detalhes; não se demonstrou que sejam simplesmente
centavos perdidos pelo parser. Não foi investigada com o emissor a causa ou a
condição bancária desses valores. Não houve tolerância ou encargo compensatório.

### A06 — Vencimento conflitante em outubro não recebe alerta específico

A capa informa **26/10/2026**; cabeçalhos internos e boleto mostram **24/10/2026**.
A prévia adotou 24/10, com procedência da página interna, mas não apresentou
`PDF_CONFLICTING_HEADER` para essa divergência. O bloqueio observado é o dos
totais. Resolver somente os centavos não resolveria a dúvida sobre o vencimento.
O nome do arquivo não foi usado como prova da data correta.

O documento também distingue oferta de quitação à vista e total da fatura.
Esses valores não devem virar duas dívidas nem ser confundidos com compras.
A prévia conservou o total do resumo, sem importar as opções de renegociação
como novas parcelas contratadas.

### A07 — Parte do material não contém os detalhes esperados

Sete dos dez CSVs são listas/resumos de documentos: instituição, referência,
data de e-mail, vencimento, total e indicação de anexo. Não possuem campos de
estabelecimento, compra individual e parcela. Há vencimentos/totais vazios e
menções a documentos protegidos que **não são os próprios originais protegidos**.

Os PDFs 01/04/05 também são compilações ou índices. O PDF 02 reúne duas faturas
com linhas detalhadas; o PDF 03 mistura resumos de meses e encargos. São formatos
distintos de uma única fatura original. Nos PDFs de índice há colunas que passam
da borda visual da página, embora parte do texto ainda possa ser extraída.

É possível melhorar a importação do que efetivamente consta nesses arquivos,
mas nem código nem IA recuperam compras ou parcelas que não foram incluídas.
Isso não isenta o aplicativo de ler os detalhes disponíveis ou de explicar a
limitação com clareza. A reprodução do CSV 07 mostrou que o formato configurável
consegue ler as linhas, mas ainda não interpretar/separar corretamente os ciclos
e distinguir total, subtotal e lançamento.

### A08 — Identificação completa em Contas a Pagar não está comprovada

Origem, instituição, descrição, últimos dígitos e parcelas existem em partes da
base de evidências. Entretanto, como zero títulos foi gerado por esses arquivos,
não foi possível aprovar a apresentação final por banco/cartão/estabelecimento,
valor, vencimento e parcela na lista. A implementação atual de geração concatena
nome da origem e descrição; a consulta padrão de títulos não entrega todos esses
dados em campos bancários próprios. Não é correto afirmar que o cadastro de
origem sozinho conclui essa categorização na experiência final.

## O que funcionou e foi preservado

- Os CSVs detalhados e a compilação PDF correspondente coincidiram em 21 e 13
  linhas, inclusive datas/descrições/valores. A leitura do app desses CSVs também
  coincidiu com a referência. As divergências antigas entre outros arquivos
  não devem ser atribuídas automaticamente a estas amostras reenviadas.
- O extrato bancário apresentou 28 datas/valores com sinal iguais à referência,
  mantendo o fluxo de evidência separado da geração de dívidas.
- Upload conservou bytes; reenvios reutilizaram as prévias; a duplicata exata
  reutilizou documento e prévia. Isso não homologa deduplicação de futuras
  parcelas nem de faturas diferentes que cobrem a mesma dívida.
- Não houve criação indevida de título, caixa ou movimento de estoque nas
  tentativas. O bloqueio de uma leitura incompleta/diferente permaneceu ativo.

## Resultado no banco isolado e limites

Ao terminar os percursos, havia 18 documentos, 20 prévias (incluindo reuso em
origens de teste e o mapeamento adicional) e 4 documentos confirmados como
evidência, contando os ramos assistidos. Havia **zero `accounts_payable`, zero
`cash_flow_entries` e zero `inventory_movements`**. Integridade e FKs aprovadas.
A tela Contas a Pagar exibiu “Nenhuma obrigação a pagar encontrada”.

Não houve pagamento, estorno, limpeza, migração ou importação de teste na base
principal. A etapa API comparou suas tabelas antes/depois e permaneceu igual;
os percursos Flutter usaram exclusivamente a conexão do banco isolado. Os 19
arquivos de entrada conservaram os hashes. As fontes do cliente correspondem
aos 136 arquivos previamente validados e à cópia usada no executor.

As suítes gerais não foram repetidas: o pedido era auditar o comportamento
atual sem corrigir código. Os resultados anteriores de 488 backend/367 Flutter
não são usados aqui como prova de importação bem-sucedida.

## Avaliação para a próxima decisão

O trabalho necessário está no fluxo principal, não na adição de módulos extras:
preservar a origem escolhida, interpretar os formatos fornecidos conforme seu
conteúdo, separar parcelas/ciclos, reduzir a classificação manual e representar
o valor devido sem duplicidade. As divergências de fonte e vencimento precisam
de tratamento explícito antes de gerar cobrança confiável.

Não se demonstrou necessidade de IA neste conjunto. Há texto e valores extraíveis,
e as leituras independentes confirmaram os itens de dois PDFs bancários e dois
CSVs detalhados. IA pode ser avaliada depois para ajudar na interpretação de
layout/contexto; não resolveria por si só dados ausentes ou divergências da fonte.

**Nenhuma correção foi implementada nesta rodada.** O próximo passo permanece
a avaliação desta auditoria com o usuário, antes de escolher a solução.

**Continuidade posterior — 19/10/2026:** o usuário solicitou um
[plano detalhado de implementação](PLANO_IMPLEMENTACAO_IMPORTACAO_FATURAS.md),
com [roteiro curto de retomada](RETOMADA_IMPORTACAO_FATURAS.md). Planejamento
preparado; esta auditoria conserva os resultados do comportamento anterior,
sem tratá-los como correções realizadas.

## Evidências

- [Resultado sanitizado](validacoes_financeiras/arquivos-fornecidos-2026-10-19/resultado.json).
- [Índice privado e capturas das telas](../tmp/audit-user-files-20261019/LEIA_ME.md).
- Código vigente observado: `financial_pdf_readers.py`, `financial_readers.py`,
  `financial_previews.py`, `financial_bill_semantics.py`, `financial_imports_view.dart`,
  `financial_bill_review_view.dart`, `financial_header_review_view.dart` e `payables_view.dart`.

Originais, valores, descrições, hashes privados, credencial temporária e imagens
com dados pessoais não foram incorporados à evidência sanitizada/Git.
