# Homologação da importação financeira

Revisão: **16/10/2026**. Procedimento de desenvolvimento, sem tela nova e sem
migração do banco da empresa. [Índice](README.md).

## Alcance

**Continuação PDF, 16/10:** o leitor `pdf_auto` e a ferramenta
[verify_financial_pdf.py](../scripts/verify_financial_pdf.py) foram implementados
depois da rodada CSV descrita abaixo. Ler o
[guia PDF](IMPORTACAO_PDF_FINANCEIRO.md) para contrato, limites, fontes e
reprodução. Cinco originais Nubank/PicPay, 35 páginas e 151 lançamentos foram
conferidos em banco descartável, incluindo um bloqueio esperado por divergência.
[Relatório sanitizado](validacoes_financeiras/2026-10-16-pdf.json).
O estado “PDF sem parser” nas descrições históricas abaixo é anterior a isso;
OCR, senha e outros layouts continuam pendentes.
Validação final do incremento PDF: **414 testes backend e 238 Flutter aprovados**.
O guia PDF registra 28 casos novos, limites de execução e o comando sequencial
usado para concluir a suíte Flutter após travamento do executor paralelo.

[verify_financial_csv.py](../scripts/verify_financial_csv.py) recebe CSVs originais
e manifesto privado, cria SQLite descartável via Alembic e exercita as rotas
reais em cliente local em processo. Não abre servidor, consulta Gmail ou recebe
caminho de banco de produção. Não executa pagamentos. Fecha conexões e remove
somente sua própria pasta temporária.

Confere bytes originais, campos mapeados, prévia/confirmação/revisão, repetição,
sobreposição por ID, livros, backup/restauração e integridade. A revisão automática
acontece **somente no ambiente descartável autorizado** e não muda a conferência
exigida no fluxo operacional do app.

A leitura de referência não chama o parser de produção, mas compartilha o
tokenizer CSV do Python. Controles bancários do PDF precisam de conferência
separada antes de entrar no manifesto. Não se inventam saldos ausentes no CSV.

## Resultado em 16/10/2026

| Original | Leitor | Linhas | Novos eventos | IDs conhecidos |
| --- | --- | ---: | ---: | ---: |
| Nubank PF | Conhecido | 5 | 5 | 0 |
| Nubank PJ, período A | Genérico explícito | 97 | 97 | 0 |
| Nubank PJ, período B | Conhecido | 187 | 90 | 97 |

**Aprovado para essas amostras:** 289 ocorrências, 192 eventos distintos e 97
IDs sobrepostos reutilizados. Operações semelhantes com IDs diferentes
permaneceram separadas. Os controles de dois PDFs correspondentes conferiram,
os livros ficaram iguais e os originais foram recuperados byte a byte. Backup,
restauração, `integrity_check` e `foreign_key_check` passaram.

O [relatório sanitizado](validacoes_financeiras/2026-10-16-csv.json) contém apenas
aliases, quantidades e checagens, sem valores monetários, nomes, transações,
contas, documentos, caminhos dos originais ou tokens.

**Limite desta rodada CSV:** os CSVs são de um único emissor. PDFs PicPay/Santander apareceram nas
buscas, mas essa busca isolada não homologou seus leitores. PicPay foi validado
depois na rodada PDF indicada acima; Santander segue pendente. Não foi localizado CSV bancário de
outra instituição nas buscas; a homologação multibanco com originais permanece
pendente. Banco da contraparte não é banco emissor do extrato.

## Repetir com outra instituição

Rodada adicional: um novo extrato PJ teve 28 ocorrências aprovadas, sem controles
de totais fornecidos. Duas faturas CSV foram [revalidadas na versão 2](validacoes_financeiras/2026-10-16-cartoes-v2.json)
do leitor genérico: 21 e 15 linhas interpretadas. Para esses originais, configurar
`amount_sign_spacing=OPTIONAL_SINGLE_SPACE`, decimal vírgula e milhar ponto.
Foi exercitada apenas a prévia dos cartões e o bloqueio de confirmação sem
cabeçalho declarado. Não fornecer vencimento/total fictícios ao manifesto para
obter aprovação. Todos os emissores desta rodada também eram Nubank.

1. Obter original autorizado e guardá-lo fora do repositório, sem editar para
   adaptar datas, delimitadores ou remover linhas com erro.
2. Inspecionar formato e sinal. Verificar se o leitor configurável representa
   o layout; não presumir compatibilidade pela extensão CSV.
3. Usar aliases neutros. `source_group` igual identifica a mesma origem entre
   arquivos; grupos diferentes representam contas/cartões diferentes.
4. Informar cabeçalho/controles só quando comprovados. Registrar privadamente a
   origem desses controles. Não derivar dívida da fatura somando todas as linhas.
5. A partir da raiz do projeto, executar:

```powershell
& .\backend\.venv\Scripts\python.exe .\scripts\verify_financial_csv.py `
  --manifest 'C:\CAMINHO_PRIVADO\manifest.json' `
  --report '.\tmp\homologacao-financeira.json'
```

6. Conferir `status=PASS`, investigar falhas e registrar alcance/limites reais.
   Uma falha não autoriza descartar linhas.
7. Publicar somente relatório sanitizado; manifesto, originais e extrações ficam
   fora do Git. Os testes permanentes usam arquivos sintéticos.

Manifesto mínimo inteiramente sintético:

```json
{
  "samples": [{
    "label": "banco_a_periodo_1",
    "source_group": "conta_a",
    "source_type": "BANK_ACCOUNT",
    "holder_type": "PJ",
    "currency": "BRL",
    "path": "C:/CAMINHO_PRIVADO/extrato.csv",
    "reader_id": "generic_csv",
    "options": {
      "columns": {
        "transaction_date": "Data",
        "amount": "Valor",
        "description": "Historico",
        "external_id": "Identificador"
      },
      "delimiter": ";",
      "encoding": "utf-8-sig",
      "date_format": "DD/MM/YYYY",
      "decimal_separator": ",",
      "amount_convention": "CREDITS_POSITIVE",
      "external_id_namespace": "banco:transacao"
    },
    "statement": {"statement_type": "BANK_STATEMENT"}
  }]
}
```

No leitor conhecido, usar `nubank_account_csv` sem `options`. Para cartão, usar
`CREDIT_CARD`, convenção `CHARGES_POSITIVE`/`CHARGES_NEGATIVE`, e `CARD_BILL` com
vencimento/total declarados. Isso prepara novos casos; não comprova cartões reais
já homologados. Sem ID, cada ocorrência segue como evento novo na revisão do teste.

`reported_control_checks=0` significa controles não fornecidos, não valores zero.
Datas observadas não substituem o período declarado. A caracterização visual
de PDF nesta rodada CSV foi limitada às páginas de controles/layout. A ferramenta
CSV não interpreta PDF; usar a ferramenta PDF posterior para essa finalidade.

Até 20 amostras por execução, respeitando limites da API. `FAIL` informa código
estável sem imprimir corpo HTTP ou dados bancários. Se o relatório solicitado
for um arquivo de entrada, a execução recusa sobrescrevê-lo. A restauração usa
apenas outro arquivo dentro da pasta descartável. Nunca usar o banco da empresa
como destino de uma validação.

## Continuidade

Validação inicial da ferramenta: **337 testes backend e 238 Flutter aprovados**.
Os quatro testes novos da ferramenta usam somente dados sintéticos e verificam
isolamento das conexões, limpeza do banco descartável, ausência de dados privados
no relatório, reenvio e recusa de sobrescrita de arquivos de entrada.

Após a correção monetária e revalidação das faturas: **363 testes backend e 238
Flutter aprovados**. Os 26 casos adicionais usam exclusivamente dados sintéticos.
Cartões reais continuam sem confirmação por falta de cabeçalho declarado.

**Atualização posterior de 16/10:** os PDFs correspondentes foram localizados e
total/vencimento conferidos nas páginas indicadas no
[relatório do cruzamento](validacoes_financeiras/2026-10-16-faturas-cruzamento.json).
Foram observadas diferenças de linhas, valores e descrições entre formatos e
uma diferença entre detalhes e resumo do próprio PDF. O resultado é
`REVIEW_REQUIRED`, com `coverage_approved=false`; não houve confirmação de
nenhuma fatura. Portanto, a pendência atual é resolver cobertura/divergências,
e não somente preencher o cabeçalho. Não invalidar o teste anterior de leitura
do CSV nem ampliá-lo como prova de completude. A
[arquitetura semântica](ARQUITETURA_SEMANTICA_DE_FATURAS.md) conserva o método,
as fontes, limites e decisões. A comparação de multiconjuntos monetários é um
diagnóstico; não é algoritmo de identidade ou conciliação.

A [memória financeira](MEMORIA_IMPLEMENTACAO_FINANCEIRA.md) registra decisões,
fontes, aprendizados e próxima ação. Depois da homologação de outro emissor,
revisar acesso global/backup antes de uso operacional; ampliar leitores e integrar
dívidas/interface de forma controlada. Gmail automático permanece futuro.

## Procedência implementada — continuação de 16/10

O [guia de conferência](CONFERENCIA_E_PROCEDENCIA_DE_FATURAS.md) descreve as novas
rotas e a migração fd3. Um parecer pode existir na prévia sem confirmar fatura;
cabeçalho desconhecido é aceito como pendência, sem valor/data inventados.
Os [originais foram exercitados](validacoes_financeiras/2026-10-16-procedencia-faturas.json)
para guardar transcrição do cabeçalho e observações. Não foram transcritos todos
os detalhes no endpoint novo: cobertura continuou pendente e confirmação com
parecer foi bloqueada. Isso não resolve as diferenças dos arquivos.

A [cópia preenchida](validacoes_financeiras/2026-10-16-migracao-conferencia-faturas.json)
passou de fc2 para fd3, com 41 tabelas anteriores preservadas. O original foi
aberto somente para leitura e mostrou fc2 nesta observação; não aplicar fd3 por
efeito colateral de teste. Validação final: **386 backend/238 Flutter aprovados**.
Sem criação de obrigações, pagamentos ou eventos reais no banco da empresa.
