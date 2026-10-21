# Importação automática de PDFs financeiros

**Percurso E5.7 — 20/10/2026:** Documentos enviados oferece **Ver documento**
e **Excluir importação**. Faturas reconhecidas abrem Conferir fatura; documentos
antigos compatíveis têm a leitura atualizada, e caminhos anteriores ficam em
Outras opções. A tela distingue documento guardado de conta efetivamente adicionada
a Pagar. Reimportação deliberada e desfazimento preservam pagamentos/compras
independentes. Contratos, instruções e limites no [guia vigente](CONTAS_A_PAGAR.md)
e situação de ativação/aceitação na [retomada](RETOMADA_IMPORTACAO_FATURAS.md).
As entregas abaixo são históricas.

**E3 — 19/10/2026:** `pdf_auto` v4 separa ciclos e índices dos formatos fornecidos;
recompõe células quebradas por coordenadas e linhas partidas entre páginas.
Conserva resumos adicionais, controles e observações, sem inventar compras.
Decisão de vencimento/conferência: [guia vigente](CONTAS_A_PAGAR.md#conferência-guiada-e-consultas--e3).
Sem nova migração, build ou ativação; as versões abaixo são históricas.

**E1 — 19/10/2026:** `pdf_auto` v3, [normalização e controles versionados](IMPORTACAO_FATURAS_E1.md).
Parcelas compartilhadas com CSV, candidatos de vencimento com procedência e
conflito explícito; diferenças de centavos preservadas. Código sem ativação.


**Entrega posterior — 19/10/2026:** a [primeira etapa de correção](CORRECAO_IMPORTACAO_FINANCEIRA_2026-10-19.md)
implementa controles exatos, cabeçalho CSV declarado, revisão vigente e
conciliação explícita, com bloqueio de alocações ainda não representadas.
Consultar esse guia e a evidência antes de usar descrições históricas abaixo.
Código/build não atualizam automaticamente o app ou servidor em execução.

**Prioridade de retomada — 19/10/2026:** a
[auditoria da importação atual](AUDITORIA_IMPORTACAO_FINANCEIRA_2026-10-19.md)
reproduziu 14 falhas após ampliações de 17–18/10, incluindo datas/ciclos,
controles artificiais e efeitos em obrigações/Tesouraria. A implementação atual
não está homologada para qualquer banco; suspender operacionalmente lançamentos
em lote até as correções. Os resultados de 16/10 abaixo são históricos e não
certificam as novas rotas. Nenhum lançamento real foi alterado pela auditoria.

Revisão: **16/10/2026**. Implementada no backend para validação pela API;
sem tela Flutter, distribuição ou migração do banco da empresa nesta rodada.
[Índice](README.md). [Memória de continuidade](MEMORIA_IMPLEMENTACAO_FINANCEIRA.md).

## Prioridade e alcance real

O usuário priorizou enviar o PDF e extrair as informações antes da revisão
semântica de faturas. O objetivo continua multibanco. O primeiro incremento
detecta o formato automaticamente e usa adaptadores para os documentos
disponíveis; não exige escolher Nubank na requisição.

| Documento com texto | Adaptador v1 | Evidência com original |
| --- | --- | --- |
| Fatura Nubank, dois layouts | `nubank_card_pdf_v1` | 19 e 16 lançamentos; segunda amostra bloqueada por divergência do próprio PDF |
| Fatura PicPay | `picpay_card_pdf_v1` | 14 lançamentos, inclusive pagamentos anteriores e parcelas |
| Extrato Nubank PF/PJ | `nubank_account_pdf_v1` | 5 e 97 lançamentos; continuações em outras páginas |
| Outro layout com texto | Sem adaptador confirmado | Texto por página preservado; `PDF_LAYOUT_UNSUPPORTED` bloqueia confirmação |
| Página sem texto, incluindo digitalização | OCR pendente | `PDF_OCR_OR_TEXT_REQUIRED`; não informa sucesso parcial |
| PDF protegido por senha | Solicitação e nova tentativa implementadas | `PDF_PASSWORD_REQUIRED` permite solicitar senha e tentar novamente; cobertura simulada e limites descritos abaixo |

**Atualização do fluxo de senha — implementação, testes e homologação:**

- **Implementado:** o cliente solicita a senha após `PDF_PASSWORD_REQUIRED` e
  permite reenviar a importação ou o reprocessamento. O backend recebe a senha
  e a encaminha pelo runtime/worker ao parâmetro `password` de `pdfplumber.open`.
  Referências: [cliente](../client/lib/views/financial_imports_view.dart),
  [prévias](../backend/app/services/financial_previews.py),
  [runtime](../backend/app/services/financial_pdf_runtime.py),
  [worker](../backend/app/services/financial_pdf_worker.py) e
  [extrator](../backend/app/services/financial_pdf_readers.py).
- **Cobertura automatizada existente:**
  [test_multibank_readers.py](../backend/tests/test_multibank_readers.py)
  simula senha ausente, incorreta e aceita substituindo `pdfplumber.open`;
  [test_financial_import_safety.py](../backend/tests/test_financial_import_safety.py)
  simula o extrator para verificar nova tentativa após senha incorreta;
  [test_financial_pdf.py](../backend/tests/test_financial_pdf.py) verifica que
  o erro simulado não reproduz a senha no relatório; e
  [multibank_and_password_import_test.dart](../client/test/multibank_and_password_import_test.dart)
  verifica o diálogo e o reenvio no Flutter com API simulada.
- **Limite de homologação:** os testes citados usam dados sintéticos e
  substituições das dependências; não comprovam a descriptografia de um PDF
  bancário realmente criptografado. Homologação exige evidência com amostras
  reais autorizadas por formato/layout, incluindo leitura e conferência dos
  dados. O fluxo implementado não representa suporte universal a PDFs
  protegidos nem garante que o layout do documento seja reconhecido.

Portanto, **“qualquer PDF, todas as informações” ainda não está entregue**.
PDF é uma apresentação visual, sem contrato universal de transações. A base
generalista recebe outros bancos, conserva os originais e informa a limitação;
novo banco exige caracterizar seu layout e homologar um adaptador. Santander
não foi homologado. Não prometer OCR, leitura de tabelas arbitrárias ou campos
ausentes no documento. OFX e Gmail automático permanecem futuros.

## Dados e comportamento

O leitor extrai datas, valores em centavos, descrição e parcelas/final do cartão
quando identificados, cabeçalho da fatura ou do extrato e controles de totais.
Preserva texto por página, texto de cada ocorrência, página, posição visual,
versão do leitor e origem textual dos campos de cabeçalho/controles. A posição
visual está na prévia; a ocorrência confirmada conserva página e texto.

Informações que não têm campo normalizado, como detalhes de contraparte e
explicações de encargos, continuam no texto e no original. Publicidade,
simulações e ofertas não viram transações. Não foram criadas tabelas para esses
conteúdos. Hora/fuso permanecem ausentes nas cinco amostras. Datas parciais de
fatura recebem ano pelo contexto explícito de ciclo/fechamento e aviso
`PDF_PARTIAL_DATE_YEAR_FROM_BILL_CONTEXT`; isso não comprova uma data de compra
separada. Conferir a origem selecionada: o leitor não valida automaticamente a
titularidade/identidade da conta ou cartão contra o cadastro.

Convenções preservadas: entrada de conta positiva, saída negativa; compra de
cartão positiva, crédito/pagamento negativo. No layout antigo Nubank, créditos
sem sinal são verdes. O adaptador usa a cor observada, além do texto; uma cor
inesperada bloqueia a leitura em vez de inverter valores por suposição. Em
outro layout há sinal Unicode de menos. PicPay usa coluna de valores na metade
esquerda da página e subtotais que não incluem pagamentos anteriores.

São conferidos total de entradas/saídas e equação de saldo nos extratos. Nas
faturas, saldo anterior + movimentos líquidos deve fechar o total declarado,
e os detalhes devem corresponder ao resumo. Essas verificações não substituem
conferência de autenticidade, titularidade ou significado comercial. Uma
diferença bloqueia a confirmação legada inteira; na integração atual da fatura,
é possível aceitar detalhes pendentes pelo total conferido, conservando a
diferença explícita. Não há ajuste artificial de centavos.
Linhas monetárias desconhecidas na tabela também bloqueiam: débitos/créditos
omitidos poderiam se compensar no total. Subtotais por titular e seção do novo
layout Nubank são guardados e conferidos separadamente em `section_controls`;
nome de titular não é transação e não foi codificado como nome fixo no leitor.

`READY` permite criar **ocorrências pendentes de revisão**, sem novos eventos
canônicos, dívidas ou pagamentos. Não equivale a `VERIFIED` da
[procedência](CONFERENCIA_E_PROCEDENCIA_DE_FATURAS.md). A revisão de identidade e
duplicidade continua separada; dia/valor/descrição semelhantes não autorizam
fusão. A comparação PDF/CSV no teste não determina identidade de transação.

## Contrato da API

Prefixo `/api/v1/financial-imports`, sempre com dispositivo ativo autenticado.
Mutações exigem `X-Idempotency-Key`.

1. `POST /documents?filename=exemplo.pdf`, bytes originais e
   `Content-Type: application/pdf`: preserva/reutiliza o BLOB pelo hash.
2. `POST /documents/{id}/previews`:

```json
{"source_id":"origem-cadastrada","currency":"BRL","reader_id":"pdf_auto"}
```

3. Consultar a prévia, `GET /previews/{id}/items`, `/errors` e `/pages`.
   Páginas: `offset`, `limit` padrão 5 e máximo 40; texto simples para a futura
   interface, nunca HTML executável. Itens/erros mantêm paginação existente.
4. `POST /previews/{id}/confirm`, com origem/hash esperados e tipo
   `BANK_STATEMENT` ou `CARD_BILL`. O cabeçalho extraído é preenchido pelo
   servidor. Valor manual que contradiga o PDF retorna
   `FINANCIAL_PDF_HEADER_CONFLICT`. As regras de cabeçalho continuam válidas.

`GET /readers` agora inclui `pdf_auto` versão 1, sem mapeamento CSV. O resultado
traz `detected_reader`, instituição/tipo detectados, `pages_count`,
`extracted_header`, `reported_summary` das faturas, `field_sources`, `checks`,
avisos e contagens. Texto de páginas e itens não é incluído nas listas de
resumos. A instituição detectada não comprova a titularidade selecionada.
Origem de conta usada para fatura, ou vice-versa, produz
`PDF_SOURCE_TYPE_MISMATCH`. Os adaptadores atuais exigem BRL.

Reenvio com o mesmo documento/origem/contrato reutiliza a prévia e não relê o
PDF. Alterar um adaptador exige elevar a versão externa de `pdf_auto` para
gerar nova interpretação, conservando a anterior e suas decisões. Prévia nova
não desfaz revisão/conciliação antiga e não herda parecer anterior.

## Execução, persistência e limites

`financial_pdf_readers.py` extrai texto/geometria/cor com pdfplumber 0.11.10 e
aplica os adaptadores. `financial_pdf_worker.py` recebe bytes pela entrada do
processo e retorna JSON. `financial_pdf_runtime.py` executa esse processo local
com o Python do servidor; não usa serviço de IA ou conversor externo.

`financial_previews.prepare_pdf_preview` lê o original imutável e encerra a
transação antes de chamar o processo. A criação da prévia então revalida o
hash, a origem e o dispositivo e grava resultado/auditoria/idempotência numa
transação. A extração demorada não mantém a trava de escrita SQLite. O teste
abre outra transação `BEGIN IMMEDIATE` durante a extração para conferir isso.

Limites: original de 10 MiB, até 40 páginas, 50 mil palavras, 200 mil caracteres
de texto, 8 mil caracteres por linha, 2 mil transações, resposta do processo
até 8 MiB e tempo de 20 segundos. Um processo de extração por servidor Python;
outro pedido simultâneo recebe 503/`PDF_PROCESSING_BUSY` para tentar novamente.
Falha/tempo excedido indisponibilizam a tentativa, sem guardar prévia inválida
que impediria repetir. Erros não ecoam conteúdo nem traceback; respostas
financeiras conservam `no-store`.

**Limite de segurança:** processo separado contém falha/tempo de execução;
não é sandbox de permissões nem impõe teto rígido de memória do sistema
operacional. A avaliação de consumo e o isolamento reforçado para arquivos
hostis devem preceder uma exposição pública. A biblioteca não executa scripts
do PDF como um visualizador. Testado em execução Python do backend Windows;
executável congelado retorna `PDF_RUNTIME_UNAVAILABLE`, pois seu processo de
extração ainda precisa de empacotamento/homologação próprios.

Não há nova migração para este incremento: `financial_documents` guarda o
original, `financial_import_previews.result` guarda o relatório imutável, e
`financial_statements`/`financial_statement_items` guardam a confirmação
pendente e a página. Backup inclui todos esses dados. A migração fd3, anterior
a este trabalho, continua necessária para a API completa e foi validada apenas
em cópia. O original da empresa não foi migrado aqui. SQLite/backups continuam
sem nova criptografia de aplicação nesta entrega.

## Homologação, reprodução e aprendizados

[Relatório sanitizado](validacoes_financeiras/2026-10-16-pdf.json): cinco PDFs,
35 páginas e 151 lançamentos. Quatro confirmações pendentes e um bloqueio
esperado. `PASS` significa que os resultados e o bloqueio corresponderam às
referências; não que todo documento foi aprovado. Originais, referências e
extrações permanecem fora do Git. Nenhum arquivo real virou fixture.

Nas faturas, foram comparados valores assinados em ordem com transcrição
visual anterior; PicPay teve nova inspeção da página inteira de lançamentos.
Nos extratos, foram comparados multiconjuntos de data/valor com os CSVs já
homologados, conservando multiplicidade, pois a ordenação de créditos/débitos
no PDF difere do CSV. A primeira tentativa do verificador usou formato decimal
errado da referência e ordem incompatível; corrigiu-se **a referência do teste**,
sem alterar PDFs ou transações, antes de obter a aprovação registrada.

O teste não afirma ter revisado individualmente todas as descrições/contrapartes
dos 151 lançamentos nem todos os layouts de cada emissor. As diferenças entre
PDF e CSV de cartões continuam pendentes na
[arquitetura semântica](ARQUITETURA_SEMANTICA_DE_FATURAS.md).

`scripts/verify_financial_pdf.py` recebe manifesto privado com caminho/hash,
tipo/titularidade, adaptador/status esperado, contagens, controles e valores
independentemente conferidos (`signed_values_cents` em ordem, ou
`date_amount_pairs` com multiplicidade). Cria SQLite descartável via Alembic,
exercita API, repetição, confirmação/bloqueio, backup e integridade. Não aceita
caminho de banco da empresa, não revisa itens automaticamente e recusa relatório
que sobrescreva uma entrada. Exemplo, a partir da raiz:

```powershell
& .\backend\.venv\Scripts\python.exe .\scripts\verify_financial_pdf.py `
  --manifest 'C:\PASTA_PRIVADA\pdf-manifest.json' `
  --report '.\tmp\homologacao-pdf.json'
```

Casos permanentes em `test_financial_pdf.py` e
`test_financial_pdf_homologation_tool.py` usam PDFs sintéticos, incluindo cor,
colunas, continuação de página, limites, erro de senha simulado, formato desconhecido,
divergências, revogação, recuperação e ausência de gravação financeira.
O cabeçalho/itens extraídos passam também pelas validações estruturais antes
de READY; mínimo negativo/acima do total bloqueia a prévia. Localizadores de
período/vencimento apontam para a página onde a informação foi encontrada,
que pode ser diferente da capa.

Validação final: **414 testes backend e 238 Flutter aprovados**, partindo de
386/238, mais `pip check` sem dependências incompatíveis. Foram adicionados
28 casos permanentes. Flutter precisou ser repetido com `--concurrency=1`
após travamento da execução paralela; não foi alterado nesta entrega.
Os avisos de depreciação prévios do backend e de fonte PDF do Flutter
permaneceram. Toda a validação usou bancos isolados, sem migração do original.

## Decisões e fontes consultadas em 16/10/2026

- **PDF-001 — adaptadores, não regex universal:** a documentação
  [pypdf — Why Text Extraction is hard](https://pypdf.readthedocs.io/en/stable/user/extract-text.html#why-text-extraction-is-hard)
  explica posicionamento, ausência de estrutura semântica e limites de OCR.
  Aplicação: separar leitura do texto e interpretação do banco. Os controles
  bloqueantes são decisão deste projeto, não garantia fornecida pela biblioteca.
- **PDF-002 — texto, geometria e cor:**
  [pdfplumber — Extracting text](https://github.com/jsvine/pdfplumber#extracting-text)
  documenta palavras/coordenadas/atributos; o projeto informa melhor funcionamento
  com PDFs gerados digitalmente. Escolhido porque os originais mostraram créditos
  indicados por cor e tabela em meia página. Texto linear isolado não bastou.
- **PDF-003 — versão reproduzível:**
  [pdfplumber 0.11.10 no PyPI](https://pypi.org/project/pdfplumber/0.11.10/),
  distribuição MIT. Dependência direta e transitivas fixadas no projeto;
  mudança de biblioteca exige revalidação e versão de interpretação.
- **PDF-004 — preservar e conferir:**
  [OWASP File Upload Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/File_Upload_Cheat_Sheet.html)
  orienta validação em camadas, limites e acesso restrito. Aplicação parcial:
  assinatura/tamanho/tipo, autenticação, limites, processo local e erros
  sanitizados. Não equivale a certificação de segurança ou sandbox completo.
- **PDF-005 — sem IA nesta etapa:** escolha baseada nos layouts disponíveis e
  na possibilidade de conferir regras determinísticas localmente. Não é
  conclusão de que IA ou OCR nunca serão úteis; ambos exigem avaliação própria.
- **PDF-006 — coerência não cria dívida:** conserva FAT-001/FAT-005 e a separação
  entre leitura, revisão, obrigações e pagamentos do projeto.
- **PDF-007 — ampliar por evidência:** próximo incremento recomendado é obter
  original de outro banco prioritário, caracterizar suas páginas e homologar
  novo adaptador. Se os arquivos efetivamente usados forem digitalizados ou
  protegidos, priorizar o fluxo correspondente. Não avançar automaticamente
  para IA/Gmail ou criação de dívidas por existir uma prévia READY.
