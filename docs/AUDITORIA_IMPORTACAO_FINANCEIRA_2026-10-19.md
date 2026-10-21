# Auditoria da importação de PDFs e CSVs — 19/10/2026

**Desdobramento posterior autorizado:** a
[primeira etapa de correção](CORRECAO_IMPORTACAO_FINANCEIRA_2026-10-19.md)
implementa os bloqueios e a revisão descritos no novo guia. Este documento
preserva a evidência da base anterior. Seus 14 testes de caracterização mostram
os defeitos antigos e não são testes de aceitação da versão corrigida.

**Conclusão: REVISÃO OBRIGATÓRIA. O fluxo atual não está homologado para qualquer
banco e não deve ser considerado seguro para lançamento financeiro em lote.**

Pedido: pesquisar como importar faturas/extratos gerais e verificar se o app está
fazendo isso corretamente. Foram auditados código, testes, arquivos armazenados
e efeitos financeiros existentes. Não foram criados, alterados ou estornados
registros na base da empresa; todas as reproduções de mutações usaram bancos
descartáveis. Esta rodada entrega diagnóstico e pesquisa, não uma correção
silenciosa das regras financeiras ou dos títulos anteriores.

## 1. Evidência e alcance

- Suíte existente: **449 backend aprovados**, 14 avisos anteriores; **356 Flutter
  aprovados**. Isso mostra compatibilidade com os casos existentes, não ausência
  das falhas abaixo.
- **14 casos adicionais de caracterização reproduziram falhas**, em ambiente
  isolado. Seu sucesso significa que o defeito foi demonstrado, não aprovado.
  [Código reproduzível](validacoes_financeiras/auditoria-2026-10-19/test_caracterizacao.py).
- Banco da empresa aberto com URI `mode=ro` e `PRAGMA query_only=ON`. Observados
  7 documentos, 10 prévias, 5 documentos confirmados, 4 revisões semânticas,
  **89 vínculos de obrigações** e **28 movimentos `BANK_IMPORT`**.
- Os 10 relatórios armazenados correspondem aos respectivos hashes. Integridade
  SQLite `ok`, nenhuma violação de chave estrangeira. Isso não valida a
  interpretação financeira.
- Releitura dos 7 PDFs armazenados reproduziu as quantidades das extrações:
  28, 22, 0, 10, 34, 39 e 0. Cinco arquivos foram reconhecidos pelo código e dois
  ficaram sem leitor. Reconhecimento não equivale a homologação.
- Os 28 vínculos bancários correspondem aos movimentos quanto ao valor e ao
  sentido crédito/débito. Classificação, origem comercial e eventual repetição
  de fatos já registrados exigem outra conferência.
- Foram renderizadas e inspecionadas páginas das duas compilações tabulares
  armazenadas. Elas reúnem tabelas/períodos e resumos; não devem ser tratadas
  automaticamente como um único documento original emitido pelo banco.
  Renderizações e extrações privadas ficam somente em `tmp/`, fora deste relatório.
- Há uma fatura com **10 obrigações** cujo vencimento foi inferido pelo leitor.
  Outras três faturas têm soma de vínculos diferente do total declarado. Essa
  diferença é indício para investigação: isoladamente não determina o valor
  correto nem autoriza cancelar títulos, pois saldos anteriores, créditos e
  vínculos existentes precisam ser demonstrados.

Não foi feita transcrição visual integral de todos os lançamentos, reconstituição
de todos os pagamentos/compras, ou homologação bancária universal. Não foram
enviados arquivos financeiros a serviços externos.

## 2. Falhas reproduzidas

### AUD-01 — Total/vencimento inventados e omissão de linha no PDF tabular — crítica

`financial_pdf_readers.parse_tabular_statement` calcula o suposto total declarado
somando o que conseguiu ler e usa a última data observada como vencimento. Uma
linha com valor ilegível é simplesmente ignorada, sem erro bloqueante. Teste:
duas linhas, uma ilegível; uma transação extraída, total fabricado e zero erros.
Código: `backend/app/services/financial_pdf_readers.py:425`, especialmente
`total_amount_cents`/`due_on` nas linhas 457/463 nesta revisão.

Assim, a soma pode conferir consigo mesma enquanto faltam lançamentos. O
vencimento é obrigação civil própria: não é a data da última compra.

### AUD-02 — CSV com indicador de débito separado pode virar entrada — alta

O leitor configurado para Itaú aceita `Data;Lançamento;Valor;Tipo` e valor
`100,00;D`; mantém o valor positivo e só avisa que há coluna não mapeada.
No contrato de conta, isso representa crédito. O teste é uma variante sintética,
não afirma que todos os exports reais Itaú têm esse layout. Demonstra que um
arquivo parecido com o esperado pode passar com sentido financeiro errado.
Colunas D/C, crédito/débito, saldos, múltiplas moedas e sinais precisam integrar
o contrato do layout, não ficar sob um aviso genérico.

### AUD-03 — Diferença até 10 centavos é convertida em encargo — crítica

`financial_bill_semantics.create_semantic_review` faz
`financial_charges += difference` quando `abs(difference) <= 10`, zera a diferença
e aprova. Compra de 100,00 e total de 100,04 viram revisão aprovada com encargo
de 0,04 sem linha que o comprove. Há tolerância também em controles de seções
de pagamentos/financiamentos do leitor PDF. Isso contraria o guia de 16/10,
que exigia bloqueio sem ajuste artificial de centavos.
Código: `backend/app/services/financial_bill_semantics.py:217` e
`backend/app/services/financial_pdf_readers.py:251`/338.

### AUD-04 — Estorno não reduz os títulos gerados — crítica

Compra de 100,00 + estorno de 20,00, com total declarado de 80,00, produz revisão
balanceada; a geração cria obrigação de 100,00 e ignora o crédito para essa
finalidade. A equação aprovada e a dívida resultante são contratos diferentes.
É necessário demonstrar a alocação do crédito, sem simplesmente gerar títulos
para todas as linhas positivas.

### AUD-05 — Saldo anterior pode desaparecer da dívida — crítica

Saldo anterior de 100,00 e compra atual de 20,00, total de 120,00: revisão
balanceada e obrigação de apenas 20,00. O teste não tem obrigação prévia ligada
que represente os 100,00. É necessário distinguir dívida já representada no app
de saldo importado ainda sem vínculo. Criar outra obrigação integral cegamente
também duplicaria dívida; a solução exige vínculo/decisão explícitos.

### AUD-06 — Lançamento ignorado ainda entra na Tesouraria — crítica

`post_statement_to_treasury` percorre todos os itens. A condição de situação só
é usada depois de criar o movimento. No teste, um item marcado `IGNORE` cria
movimento mesmo assim. Usar a decisão efetiva e respeitar itens ignorados e
correções antes de qualquer lançamento.
Código: `backend/app/services/financial_imports.py:334`/428.

### AUD-07 — Sobreposição sem ID é lançada duas vezes — crítica

Dois documentos da mesma origem, contendo a mesma evidência sem identificador
confiável, podem gerar dois movimentos. O reenvio do mesmo documento/statement
é protegido; arquivos sobrepostos são outra situação. Não fundir por
dia/valor/descrição, pois fatos legítimos podem ser iguais. O correto é sinalizar
ambiguidade e exigir revisão/vínculo antes da criação automática de movimentos.

### AUD-08 — Transferência vira receita empresarial — crítica

O lançamento em lote usa crédito → `RECEITA`, débito → `DESPESA`, ambos
`BUSINESS`. Até uma linha explicitamente `transaction_kind=TRANSFER` foi
classificada como receita no teste. O dashboard inclui `BANK_IMPORT` em seus
recebimentos/pagamentos. Transferência própria, empréstimo, aporte, retirada e
liquidação de venda já registrada não têm automaticamente essa natureza.
Código: `backend/app/services/financial_imports.py:389` e
`backend/app/services/business_dashboard.py:124`.

### AUD-09 — Senha correta pode reutilizar falha da senha errada — alta

O contrato de interpretação distingue apenas `has_password=true/false`.
Uma prévia inválida com senha errada é reutilizada quando se informa a correta;
o processo nem volta a ser chamado. O teste confirmou uma única chamada.
Não guardar senha em claro nem usar hash simples de senha curta como solução:
falhas de autenticação precisam ser tentativas recuperáveis, sem cache definitivo
da interpretação malsucedida.
Código: `backend/app/services/financial_previews.py:32`/58.

### AUD-10 — “Internacionais” pode acionar o leitor Inter — média

A condição `"INTER" in whole` reconhece até a palavra `INTERNACIONAIS` em
documento de outro banco. O teste produziu instituição detectada `INTER`.
Neste caso a leitura permaneceu bloqueada; é falso reconhecimento, não prova
de lançamento incorreto. Reconhecer banco/tipo por características independentes
do cabeçalho, com detecção de ambiguidade.

### AUD-11 — Data de referência substitui data da compra — crítica

Em tabela com `FATURA_REFERENCIA DATA_LANCAMENTO`, a linha
`2026-10-20 2026-10-01 Loja exemplo 10,00` é interpretada com transação em
20/10; 01/10 fica dentro da descrição. A primeira data não é necessariamente o
fato bancário. O mesmo padrão foi observado nas descrições das 10 ocorrências
de uma compilação armazenada.

### AUD-12 — Duas faturas são agrupadas sob um vencimento — crítica

Documento sintético com faturas de outubro/novembro: o leitor reúne os itens,
soma os valores e conserva o primeiro vencimento. Uma das compilações privadas
inspecionadas também contém mais de um ciclo. Deve separar documentos/ciclos com
identidade e controles próprios ou bloquear a importação como fatura única.

### AUD-13 — Tipo da origem confundido com tipo do documento — alta

O leitor tabular informa `CARD_BILL` em `detected_source_type`, mas a origem
usa `CREDIT_CARD`. A API gera `PDF_SOURCE_TYPE_MISMATCH` até quando o operador
escolheu um cartão. Isso não deve ser “resolvido” criando origem de tipo errado
ou ignorando a checagem. O teste distingue esse defeito do bloqueio legítimo de
uma fatura Nubank enviada como conta bancária, presente na base observada.

### AUD-14 — Revisão antiga autoriza geração após revisão atual divergente — alta

A geração aceita `review_id` de revisão antiga aprovada, mesmo havendo revisão
atual `DRAFT` e não balanceada. O teste gerou obrigação por essa rota.
É necessário revalidar a revisão vigente/precondição na transação da geração,
sem apagar revisões anteriores.

## 3. Outros problemas confirmados por inspeção

- O Flutter também fabrica cabeçalhos de CSV: vencimento pela última transação
  ou por hoje, total pela soma das linhas, saldo inicial zero e saldo final pelo
  líquido. Isso transforma ausência de dado em controle aparentemente declarado.
  Local: `client/lib/views/financial_imports_view.dart:1375`–1397 nesta revisão.
- A geração direta no Flutter classifica descrições por palavras e envia
  aprovação/geração: tudo que não encaixa nas regras vira `PURCHASE_BUSINESS`.
  Isso não comprova uso empresarial nem vínculo com compra/obrigação existente.
  A consulta usa somente `limit=500`, embora o contrato possa conter mais itens.
  Local: `_launchCardBillDirect`, linha 207 em diante.
- A frase da tela “não cria contas a pagar, pagamentos ou conciliação automática”
  só descreve o staging original, mas hoje há outras ações que escrevem nos
  livros/títulos. A interface deve distinguir leitura, revisão, vínculo e
  lançamento, explicando o efeito de cada confirmação.
- `GET /readers` anuncia `BANK_ACCOUNT` para todos os leitores com configuração
  CSV, inclusive cartões. A lista de capacidades precisa corresponder ao contrato.
- `pdf_auto` permanece versão 1 apesar de ampliações e mudanças de interpretação.
  A versão precisa subir quando a interpretação mudar; preservar prévias antigas.
- Os testes Itaú/Santander/Inter PDF encontrados usam PDFs sintéticos. Não há
  evidência suficiente nesta rodada para dizer que todos os layouts reais desses
  bancos foram homologados. Os testes de originais têm caminhos privados fixos;
  parte deles pode não rodar quando os arquivos faltam. Automatizar manifesto
  separado e relatório explícito de cobertura, sem incorporar dados privados.

## 4. Pesquisa: como ampliar a importação corretamente

Fontes primárias consultadas em **19/10/2026**. As recomendações abaixo são
conclusões de engenharia aplicadas ao projeto; nenhuma biblioteca citada
certifica contabilidade ou cobertura universal por si só.

| Abordagem | O que a fonte sustenta | Aplicação proposta e limite |
| --- | --- | --- |
| Texto, geometria e tabelas | [pypdf: extração e ausência de semântica](https://pypdf.readthedocs.io/en/stable/user/extract-text.html) explica texto posicionado, dificuldades de tabelas e diferença entre PDF digital, escaneado e com OCR. [pdfplumber](https://github.com/jsvine/pdfplumber) fornece palavras, coordenadas, cores e tabelas, com melhor adequação a PDFs digitais. | Manter extração geométrica para originais digitais, preservar página/trecho e separar leitura de interpretação financeira. Não aplicar OCR a todo PDF por padrão nem prometer leitura universal com regex. |
| Análise de layout e OCR | [Docling: formatos](https://docling-project.github.io/docling/usage/supported_formats/) e [exemplo oficial de OCR e estrutura de tabelas](https://github.com/docling-project/docling/blob/main/docs/examples/full_page_ocr.py) mostram conversão estruturada com opções de motores OCR. [OCRmyPDF: introdução](https://ocrmypdf.readthedocs.io/en/latest/introduction.html) descreve camada de texto pesquisável. | Avaliar pipeline local de OCR apenas nas páginas que precisarem. A saída ainda exige reconstrução de linhas/colunas, validação de valores e evidência; OCR não define compra, pagamento ou dívida. Não instalado nem homologado nesta auditoria. |
| Tabelas configuráveis/ML | [Camelot: documentação do projeto](https://github.com/camelot-dev/camelot) apresenta parsers geométricos, continuação entre páginas e caminhos opcionais de ML/OCR. | Comparar em corpus local contra os extratores existentes, medindo cobertura de linhas, células e sinais. Métrica de precisão estrutural não prova que o total financeiro ou a natureza estejam corretos. Novos recursos são opcionais e precisam de empacotamento/validação. |
| CSV explícito | [Python: módulo csv](https://docs.python.org/3/library/csv.html) explica variações de delimitador/formato e configuração de dialetos. | Detectar estrutura para propor mapeamento, confirmar colunas e convencão monetária; tratar D/C, duas colunas de valor, encoding, datas e moeda. Layout desconhecido exige configuração/revisão, não uma etiqueta de banco genérica. |
| Dados bancários estruturados | [BCB: Open Finance](https://www.bcb.gov.br/meubc/faqs/s/open-finance) e [tipos de dados compartilháveis](https://www.bcb.gov.br/meubc/faqs/p/tipos-de-dados-e-servicos-que-podem-ser-compartilhados-com-o-open-finance) incluem contas/extratos e cartões/faturas, com consentimento. | Avaliar integração apropriada ao ecossistema como caminho futuro para dados estruturados. Não é simplesmente chamar API de qualquer banco, nem substitui consentimento, cobertura, identidade e conciliação. Não implementado aqui. |
| Proteção dos arquivos | [OWASP: File Upload Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/File_Upload_Cheat_Sheet.html) orienta validação em camadas, limites, controle de acesso e isolamento. | Conservar original/hash e autenticação; processamento limitado e separado, sem executar instruções do conteúdo ou enviar documentos a conversores públicos. Processo separado não constitui sandbox completo de memória/permissões. |

Páginas tentadas do Camelot ReadTheDocs, de segurança OCRmyPDF e duas rotas
Atlassian do Open Finance não retornaram conteúdo utilizável; não servem de
fundamentação. Foram usadas as fontes primárias acessíveis acima. Nenhum serviço
de nuvem/IA recebeu os documentos armazenados.

### Pipeline recomendado

1. Receber e preservar original/hash; distinguir arquivo do banco de compilação
   ou transcrição. Detectar páginas, proteção, texto e tipo provável.
2. Extrair texto/geometria digital; usar OCR local nas páginas necessárias.
   Extratores/modelos podem sugerir estrutura, sem lançar dinheiro.
3. Identificar conta/cartão, titularidade, instituição, moeda e ciclos com
   evidências. Contraparte e palavra isolada não comprovam emissor. Separar ciclos.
4. Reconstruir todas as linhas, inclusive continuações; marcar trechos ilegíveis,
   valores ambíguos e campos ausentes. Não inventar data, saldo ou total declarado.
5. Conferir por controles independentes: extrato com saldo inicial + créditos −
   débitos = saldo final; fatura com componentes declarados e respectivos detalhes.
   Soma dos itens extraídos não pode ser usada como prova independente dessa soma.
   Divergências monetárias bloqueiam, sem criar encargo para fechar centavos.
6. Mostrar revisão com origem de cada campo, limitações e abrangência. Aceitar
   adaptação assistida de layout novo, conservando a distinção entre dado do
   documento e decisão manual. IA/OCR podem propor; o operador e os controles
   precisam conseguir verificar e corrigir.
7. Resolver identidade/duplicidade e conciliar com os registros existentes.
   Usar ID confiável com namespace da origem; sem ele, semelhança gera candidato,
   nunca fusão ou lançamento automático como se fosse fato novo confirmado.
8. Para faturas, representar obrigação, compra/parcela, crédito, encargo, saldo
   anterior e pagamento com vínculos próprios. Validar o efeito líquido e impedir
   dupla dívida/despesa. Para contas, classificar natureza e conciliar antes de
   lançar transferências, aportes, empréstimos ou liquidações já cadastradas.
9. Confirmar a operação por contrato idempotente, com revisão vigente e dados
   revalidados na transação. Preservar fatos/revisões históricos e recuperação.
10. Homologar por banco, tipo, versão/layout e período, com originais autorizados
    e oráculo independente. Incluir scans, senha, duas colunas, sinais, múltiplos
    ciclos, estornos, sobreposição PDF/CSV, reenvio e falhas de conexão.

Isso oferece alcance multibanco progressivo e um caminho assistido para layouts
novos. Não permite anunciar “qualquer PDF de qualquer banco com garantia total”.

## 5. Prioridade para correção e recuperação

1. **Conter efeitos:** suspender operacionalmente lançamentos em lote até corrigir
   as rotas. Não reabrir bloqueios por tolerância, tipo trocado ou dado fabricado.
2. **Corrigir leitura/cabeçalho:** datas, ciclos, controles, linhas omitidas, D/C,
   cache de senha e versão. Testar sem gravar nos livros da empresa.
3. **Corrigir revisão e efeitos:** decisão efetiva de itens, revisão vigente,
   conciliação prévia, créditos, saldo anterior e natureza. Atualizar o fluxo do
   Flutter para revisão explícita e mensagens correspondentes ao comportamento.
4. **Auditar o histórico em cópia:** inventariar os 89 vínculos de obrigações e os
   28 movimentos, relacionando original, ciclo, título, compra, crédito e pagamento.
   Listar diferenças com justificativas. Somente então propor correções auditáveis
   e estornos próprios, sem apagar ou reescrever os registros.
5. **Expandir cobertura:** corpus de originais de outros bancos, pipeline de
   layout/OCR e eventual integração estruturada, depois homologação/empacotamento.

Esta auditoria não publicou, instalou ou ativou uma correção financeira. Não é
necessária migração para ler o relatório. Mudanças em dados existentes exigem
plano concreto de recuperação e autorização correspondente.

## 6. Reprodução

Executar a partir da raiz, com o ambiente Python do backend existente:

```powershell
$env:PYTHONPATH = 'backend;backend/tests'
& .\backend\.venv\Scripts\python.exe -m pytest `
  docs/validacoes_financeiras/auditoria-2026-10-19/test_caracterizacao.py `
  -p conftest -q --basetemp=tmp/audit-import-reproduction
```

Resultado observado: **14 reproduções concluídas**. Esses testes são um dossier
de caracterização do estado auditado, separados da suíte de aceitação: depois
de corrigir um defeito, a asserção correspondente deve falhar e ser substituída
por uma regressão permanente que exija o comportamento correto.

Logs de execução completos ficam em `tmp/audit-import-20261019-*.log` e
`tmp/audit-import-reproduction-final.log`. O
[resumo sanitizado](validacoes_financeiras/auditoria-2026-10-19/resumo.json)
conserva somente contagens, resultados e limites, sem dados pessoais, contas,
senhas, transações individuais ou conteúdo dos documentos.
