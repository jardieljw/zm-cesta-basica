# Importação CSV de bancos e cartões

Revisão: **16/10/2026**. Implementado no backend para validação pela API, sem
tela nova. Estado da instalação deve ser conferido por revisão Alembic;
a nova migração fd3 não foi aplicada nesta rodada. [Índice](README.md).

## Fluxo implementado

O mesmo fluxo atende instituições diferentes: **original → leitor versionado →
prévia → confirmação do documento → revisão das ocorrências → conciliação**.
A instituição pertence à origem financeira, que identifica uma conta ou relação
de cartão PF/PJ. Não existe cadastro de dívida ou saldo específico de um banco.
Confirmar a prévia cria evidências pendentes; revisar não executa pagamentos.

Há adaptadores especializados e um leitor configurável, com contrato de saída comum:

| Leitor | Alcance |
| --- | --- |
| `generic_csv`, versão `2` | Mapeamento explícito para CSV de qualquer instituição cujo formato se enquadre no contrato abaixo; conta ou cartão. Opção de espaço após sinal monetário. |
| `nubank_account_csv`, versão `1` | Layout conhecido de conta: `Data,Valor,Identificador,Descrição`, data `DD/MM/YYYY`, valor decimal com ponto, identificador obrigatório e namespace `nubank:account`. BRL e conta bancária. |
| `nubank_card_csv`, versão `1` | Layout conhecido de cartão Nubank: `date,title,amount`, data `YYYY-MM-DD`, valor com vírgula decimal e ponto de milhar, identificador de namespace `nubank:card`. |
| `nu_empresas_account_csv`, versão `1` | Layout Nubank PJ: `Data,Valor,Identificador,Descrição`, namespace `nubank:pj_account`. |
| `itau_account_csv` / `itau_card_csv`, versão `1` | Layouts Itaú com delimitador `;`, colunas `Data;Lançamento;Valor`, decimal vírgula, milhar ponto. |
| `santander_account_csv` / `santander_card_csv`, versão `1` | Layouts Santander com delimitador `;`, colunas `Data;Documento;Histórico;Valor`. |
| `inter_account_csv` / `inter_card_csv`, versão `1` | Layouts Banco Inter com delimitador `;`, colunas `Data Lançamento;Histórico;Valor`. |
| `mercadopago_csv`, versão `1` | Layout Mercado Pago com delimitador `;`, colunas `Data;Descrição;Valor`. |
| `bb_account_csv`, versão `1` | Layout Banco do Brasil com delimitador `;`, colunas `Data;Historico;Numero do Documento;Valor;Saldo`. |
| `bradesco_account_csv`, versão `1` | Layout Bradesco com delimitador `;`, colunas `Data;Histórico;Docto.;Valor;Saldo`. |
| `caixa_account_csv`, versão `1` | Layout Caixa Econômica com delimitador `;`, colunas `Data Mov.;Nr. Doc.;Historico;Valor;Saldo`. |

Os leitores bancários conhecidos são adaptadores especializados declarados em `READERS`.
Todos utilizam centavos exatos via `Decimal`, rejeitam perda de precisão, suportam
separadores de milhar e delimitadores bancários padrão brasileiros.

## Contrato de interpretação

- UTF-8, com ou sem BOM, ou Windows-1252 escolhido explicitamente; separador
  vírgula, ponto e vírgula ou tabulação. CSV com aspas e descrições em várias
  linhas é aceito. Não há tentativa automática entre codificações.
- Colunas obrigatórias: data, valor com sinal e descrição. O mapeamento usa o
  nome exato do cabeçalho; nomes repetidos e campos obrigatórios ausentes geram erro.
- Opcionais: identificador externo, horário, data de compra, data de lançamento,
  nome/documento da contraparte, final do cartão e número/total de parcelas.
  Dados não mapeados continuam no original e no texto bruto; a prévia avisa que
  existem colunas não interpretadas. Acrescentar campos depende de uso real.
- Datas `DD/MM/YYYY`, `YYYY-MM-DD` ou `MM/DD/YYYY`, explicitamente escolhidas.
  `date_kind` informa se a data principal é de compra, lançamento ou apenas como
  apresentada. Datas de compra/lançamento não substituem uma à outra. Horário
  ausente fica nulo; não se presume fuso, nem horário a partir da emissão.
- Decimal e milhar explicitamente configurados, com agrupamento validado.
  Valores são convertidos para centavos com `Decimal`, sem floats, sem
  arredondar precisão excedente. Valor zero/subtotal não é transação válida.
- `amount_sign_spacing` é `ADJACENT` por padrão. A opção explícita
  `OPTIONAL_SINGLE_SPACE` aceita um único espaço ASCII após `+` ou `-`, por
  exemplo `- 12,34`, além dos sinais adjacentes. Não elimina espaços dentro dos
  números, não aceita tabulação/espaço Unicode após o sinal, sinais duplicados,
  agrupamento inválido ou precisão excedente. O original e o texto bruto são
  preservados; a configuração acompanha a prévia. O adaptador de conta Nubank
  continua estrito. A versão 2 gera novas prévias; resultados anteriores não
  são reescritos. O novo campo padrão também integra o hash das opções, podendo
  gerar outra prévia para documentos processados antes desta atualização.
- Conta usa `CREDITS_POSITIVE`; cartão usa `CHARGES_POSITIVE` ou
  `CHARGES_NEGATIVE`, conforme o sinal das cobranças no arquivo. A segunda opção
  inverte o sinal para o contrato interno. Não se conclui o sinal pela descrição.
- A moeda precisa ser declarada e coincidir com a origem; não há câmbio ou soma
  de moedas diferentes. O arquivo deve representar uma única origem/moeda.
- Identificadores externos têm até **255 caracteres**, preservando maiúsculas,
  minúsculas e zeros iniciais. Sua identidade é origem + namespace + ID. Use o
  mesmo namespace estável para a mesma identificação em importações posteriores.
  Não usar nome do arquivo ou chave da requisição como namespace. IDs ausentes
  não são fabricados a partir de data/valor. IDs repetidos no próprio arquivo
  geram erro para investigação; operações semelhantes com IDs distintos continuam
  separadas. Sem ID, correspondências exigem decisão humana.

O SQLite não limita o conteúdo pelo comprimento declarado em `VARCHAR(200)`;
as duas colunas históricas de identidade foram mantidas para evitar reconstruir
tabelas imutáveis referenciadas. O contrato validado aceita e conserva 255
caracteres. Essa decisão é específica do SQLite; uma troca de banco deve migrar
as declarações para a capacidade correta.

## API e exemplo sintético

Prefixo `/api/v1/financial-imports`. Todas as rotas exigem Bearer válido de
dispositivo ativo; POST exige também `X-Idempotency-Key`. Consultar primeiro
`GET /readers` e cadastrar/selecionar a origem em `/sources`.

1. Enviar o original em `POST /documents?filename=exemplo.csv`, corpo binário,
   `Content-Type: text/csv`. Resposta fornece `document.id`.
2. Criar prévia em `POST /documents/{document_id}/previews`:

```json
{
  "source_id": "ID-DA-ORIGEM",
  "currency": "BRL",
  "reader_id": "generic_csv",
  "options": {
    "columns": {
      "transaction_date": "Data",
      "amount": "Valor",
      "description": "Historico",
      "external_id": "Referencia"
    },
    "delimiter": ";",
    "encoding": "utf-8-sig",
    "date_format": "DD/MM/YYYY",
    "date_kind": "BOOKING",
    "decimal_separator": ",",
    "thousands_separator": ".",
    "amount_convention": "CREDITS_POSITIVE",
    "external_id_namespace": "banco:transacao"
  }
}
```

3. Consultar `GET /previews/{id}`, `/items` e `/errors`. Itens/erros são
   paginados com `limit` até 500 e `offset`. Itens incluem linha inicial/final,
   texto bruto, dados normalizados e candidatos atuais a duplicidade. A prévia
   informa quantidades, totais das linhas válidas e datas observadas; erros
   podem deixar esses totais parciais. `complete=false` indica interrupção por
   limite/sintaxe. Somente `READY` permite confirmar.
4. Confirmar `POST /previews/{id}/confirm`:

```json
{
  "expected_source_id": "ID-DA-ORIGEM",
  "expected_result_sha256": "HASH-DEVOLVIDO-NA-PREVIA",
  "statement_type": "BANK_STATEMENT",
  "period_start": "2025-07-01",
  "period_end": "2025-07-31"
}
```

5. Conferir `GET /statements/{id}/items` e usar `/items/{id}/review` conforme o
   [contrato da base financeira](BASE_FINANCEIRA_E_CONCILIACAO.md). Para cartão,
   confirmar `CARD_BILL`, vencimento e total declarado na fatura; o CSV de
   transações pode não trazer esses campos. Nunca deduzir a dívida pela soma de
   compras e pagamentos anteriores. Não preencher saldos ou totais ausentes.

Quando fornecidos, entradas/saídas declaradas são comparadas às somas das linhas
e à equação dos saldos. O período é comparado às datas observadas, sem afirmar
que isso prova cobertura completa do extrato. Divergências aparecem em `checks`
e permanecem para conferência, sem gerar ajuste. Parcelas podem apresentar data
original fora do período da fatura.

`GET /previews?document_id=...&source_id=...` consulta o histórico. Candidatos
com `EXTERNAL_ID_CONFLICT` indicam fatos conflitantes; a revisão bloqueia a fusão.
Sugestões mudam conforme novas operações são conferidas, e são revalidadas na
decisão. Não são decisões congeladas na prévia.

## Rastreabilidade, erros e recuperação

`financial_import_previews` guarda versão do leitor, configuração, hashes,
resultado, autor e instante UTC. É imutável, com proteção também no SQLite.
`financial_statements.preview_id` preserva o vínculo com a interpretação usada.
O original acompanha o backup no próprio SQLite. Reenvio idêntico reutiliza a
prévia; confirmação idêntica reutiliza o cabeçalho. O processamento e sua chave
de idempotência são gravados atomicamente, com rollback em falha.

Uma correção de mapeamento produz outra prévia, conservando a anterior. Isso
**não desfaz decisões já concluídas** nem altera um evento canônico antigo.
A [correção auditável da revisão](CORRECAO_REVISAO_FINANCEIRA.md) possui fluxo
próprio, que bloqueia operações com conciliação ativa e preserva as associações
anteriores. Não usar reprocessamento como substituto dessa correção. A revisão
global de acesso/backup documentada na pesquisa continua pendente.

Limites: arquivo até 10 MiB, até 2.000 registros, 100 colunas, 8.000 caracteres
por registro/linha física e 10.000 linhas físicas. Linhas vazias são contadas;
linhas inválidas não são omitidas silenciosamente: **qualquer erro bloqueia a
confirmação inteira**. Cabeçalho conhecido alterado é recusado. Fórmulas são
texto, nunca executadas. Erros informam código, linha e campo, sem ecoar valores.

## Migração e validação

`fb1e2f3a5411` sucede `fa0d1e2f4310`. Acrescenta a tabela de prévias e colunas
opcionais de procedência/datas; não reinterpreta registros antigos nem recria
as tabelas de histórico. A inversa é recusada se a base financeira estiver
preenchida. O startup não substitui a migração e a API retorna 503 se faltarem
tabelas/colunas. Aplicar no servidor somente após backup verificado e conferência
de integridade; o banco da empresa permanece sem essas migrações nesta entrega.

Testes sintéticos cobrem múltiplos layouts, conta/cartão, precisão, identidades,
períodos sobrepostos, concorrência, erro/repetição, recuperação, imutabilidade e
migração com evidência anterior preenchida sob `foreign_keys=ON`.

Resultado desta entrega: **313 testes backend e 238 testes Flutter aprovados**.
A migração sobre cópia do banco local preservou os registros das **30 tabelas
anteriores**, seus índices e gatilhos, com `integrity_check` e `foreign_key_check`
aprovados. O original permaneceu na revisão `f9c0d1e2f309`; a cópia de validação
chegou à `fb1e2f3a5411`. Não foram importados documentos pessoais reais no banco
da empresa. Compatibilidade com arquivos reais de outras instituições ainda
precisa de homologação controlada, além dos casos sintéticos.

Atualização de **16/10/2026**: três CSVs originais Nubank PF/PJ foram
[homologados em banco descartável](HOMOLOGACAO_IMPORTACAO_FINANCEIRA.md),
incluindo períodos sobrepostos. Isso não homologa CSVs de outros emissores.
A [memória financeira](MEMORIA_IMPLEMENTACAO_FINANCEIRA.md) registra decisões,
fontes, resultados e o ponto de retomada.

Duas faturas CSV originais foram revalidadas com a versão 2 e configuração
explícita: 21 e 15 linhas, sem erros de leitura. Isso valida a prévia, não a
confirmação da fatura: os arquivos não fornecem vencimento/total declarado nem
IDs individuais. O bloqueio por cabeçalho ausente permaneceu ativo e nenhum
evento ou obrigação foi criado. Ver [evidências desta rodada](validacoes_financeiras/2026-10-16-cartoes-v2.json).

Conferência posterior encontrou os PDFs e comprovou seus cabeçalhos, mas também
diferenças em relação aos CSVs. As amostras continuam sem confirmação por
divergências pendentes. READY não prova cobertura integral da fatura; consultar
a [arquitetura semântica e fontes](ARQUITETURA_SEMANTICA_DE_FATURAS.md).

A [procedência/conferência](CONFERENCIA_E_PROCEDENCIA_DE_FATURAS.md) já está
implementada por API separada na prévia. `assessment_id` opcional vincula a
confirmação ao parecer atual sem substituir o fluxo legado. VERIFIED do parecer
compara transcrições e não autoriza gerar obrigações. Leitura mais recente da
base original mostrou fc2; fd3 foi validada somente em cópia preenchida.

Código: `backend/app/services/financial_readers.py`, `financial_previews.py`,
schemas `financial_readers.py`, API/modelos `financial_imports.py` e testes
`backend/tests/test_financial_readers.py`, `test_financial_imports_migration.py`.

**Continuação de 16/10 — PDF primeiro:** por solicitação do usuário, a mesma
base recebeu o leitor automático `pdf_auto`, para layouts Nubank/PicPay,
com resultado/páginas imutáveis e erros bloqueantes. Isso não modifica os
contratos/hashes dos leitores CSV. Consultar o
[guia PDF](IMPORTACAO_PDF_FINANCEIRO.md) e o
[relatório dos cinco originais](validacoes_financeiras/2026-10-16-pdf.json).
As diferenças CSV/PDF descritas acima não foram corrigidas apagando linhas ou
ajustando valores; nova interpretação conserva ambos os originais.
