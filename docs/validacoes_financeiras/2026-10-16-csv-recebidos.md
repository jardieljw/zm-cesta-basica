# Nova rodada de originais recebidos — 16/10/2026

Complementa a [memória financeira](../MEMORIA_IMPLEMENTACAO_FINANCEIRA.md) e o
[procedimento de homologação](../HOMOLOGACAO_IMPORTACAO_FINANCEIRA.md).

## Evidências e alcance

Foram localizados três CSVs originais novos no Gmail autorizado: duas faturas
de cartão e um extrato PJ, todos emitidos pelo Nubank. Originais e manifesto
permaneceram fora do repositório. Tamanhos baixados conferiram com os metadados.
O OFX também oferecido no e-mail estava marcado como não suportado pelo conector
e não foi lido. O PDF correspondente ao extrato não foi inspecionado nesta rodada.

O extrato PJ passou em `scripts/verify_financial_csv.py`: 28 ocorrências e 28
eventos novos no banco descartável. Um grupo de operações semelhantes com IDs
distintos permaneceu separado. Passaram comparação dos campos, bytes originais,
reenvio de documento/prévia/confirmação, livros inalterados, backup/restauração,
integridade e chaves estrangeiras. Não foram fornecidos controles bancários de
saldo/totais; isso não equivale a conferência desses controles. A migração até
`fc2f3a4b6512` ocorreu apenas no banco descartável. Nenhuma gravação ou migração
foi realizada no banco da empresa.

## Cartões: leitura parcial e bloqueios confirmados

Ambos os originais têm apenas `date,title,amount`. O índice exibido na prévia do
conector não pertence ao arquivo. Usam data ISO, vírgula decimal e ponto de
milhar. A configuração explícita `generic_csv`, `CHARGES_POSITIVE` representa
esses separadores; não usar a configuração monetária do extrato da conta.

- Amostra A: 21 linhas, 17 aceitas pelo parser, 4 `CSV_INVALID_ROW`. Valores
  negativos com espaço entre sinal e número são incompatíveis com a gramática
  atual. O documento inteiro deve permanecer bloqueado, sem omitir as quatro
  linhas nem alterar o original para fazê-lo passar.
- Amostra B: 15 linhas, 15 aceitas pelo parser com configuração explícita.
  Isso comprova leitura dos campos, não confirmação ou conciliação da fatura.

Não houve confirmação de nenhuma fatura. Os CSVs não fornecem vencimento nem
total declarado, obrigatórios para `CARD_BILL`. Não inferir esses campos do nome
do arquivo ou da soma das linhas: há compras, parcelas, pagamentos, créditos,
saldo anterior e encargos. Também não trazem IDs individuais nem horários.
Parcelas estão no texto descritivo, sem colunas próprias; não foram extraídas
automaticamente nem transformadas em obrigações a pagar.

## Próxima ação

**Atualização posterior, ainda em 16/10:** a incompatibilidade monetária foi
corrigida por opção explícita do leitor genérico v2. As duas amostras agora têm
21 e 15 linhas válidas. Ver [relatório da revalidação](2026-10-16-cartoes-v2.json)
e [memória atualizada](../MEMORIA_IMPLEMENTACAO_FINANCEIRA.md). A descrição abaixo
preserva o diagnóstico inicial; a confirmação das faturas continua pendente.

Tratar explicitamente o formato monetário com sinal separado, preservando a
validação estrita, o original e testes sintéticos de casos aceitos/rejeitados.
Antes de confirmar cartão, obter a fatura completa ou controles declarados
verificados e definir o tratamento semântico de cada tipo de lançamento.
Não deduplicar automaticamente linhas sem ID por data/valor/descrição.
Homologação de outra instituição continua pendente: estas amostras são Nubank.

Nenhum código foi alterado nesta rodada. Foi executado o verificador isolado
existente e a leitura direta pelo parser; as suítes completas não foram
reexecutadas. Resultados sanitizados detalhados ficaram junto aos originais na
pasta temporária privada, sujeitos à limpeza do sistema.
