# Conferência e procedência de faturas

Revisão: **16/10/2026**. Implementado no backend, sem nova interface.
[Índice](README.md). Fundamentação: [arquitetura semântica](ARQUITETURA_SEMANTICA_DE_FATURAS.md),
decisões FAT-001 a FAT-010. Integração de obrigações e pagamentos continua futura.

## Alcance implementado

A conferência começa na **prévia**, antes de criar um statement. Permite registrar
cabeçalho desconhecido (`header=null`), documentos faltantes e divergências sem
fabricar valor ou vencimento. Cada revisão é um retrato completo, imutável,
assinado pelo dispositivo autenticado, com instante UTC e revisão sequencial.

São três perguntas distintas:

1. O leitor conseguiu interpretar o arquivo? Continua `READY`/`INVALID` da prévia.
2. A transcrição manual das evidências corresponde à prévia exata? Resultado
   da conferência: `REVIEW_REQUIRED` ou `VERIFIED`.
3. Isso autoriza gerar contas a pagar? **Não.** Todas as respostas desta camada
   trazem `can_generate_obligations=false` e `affects_ledger=false`.

`VERIFIED` significa somente concordância dos campos transcritos e cobertura
das linhas da prévia selecionada. `semantic_status=NOT_REVIEWED`. O backend não
lê o PDF, verifica titular no documento nem autentica uma transcrição manual.
`identity_reason`, origem, moeda, ciclo e localizador são declarações do operador;
o servidor valida suas referências e consistência. Não anunciar certificação
automática da fatura ou validação de autenticidade.

## Persistência e integridade

Migração aditiva `fd3a4b5c7613`, após `fc2f3a4b6512`:

| Tabela | Conteúdo |
| --- | --- |
| `financial_bill_assessments` | Prévia, revisão, cabeçalho ou desconhecido, motivo, resoluções, resultado calculado, quantidade fechada de evidências, autor e instante. |
| `financial_bill_evidence` | Associação tipada ao documento original, papel HEADER/DETAILS, posição, hash do BLOB e declarações estruturadas, validadas pelo schema. |
| `financial_bill_assessment_links` | Associação entre conferência e statement confirmado pelo fluxo opcional que exige parecer. |

Não há alteração/reconstrução das tabelas anteriores, duplicação dos BLOBs,
livro de obrigações paralelo ou substituição de fatos. Campos de evidência em
JSON têm contrato explícito; não são entrada arbitrária de metadados bancários.
FKs, restrições de unicidade e gatilhos protegem a base. UPDATE/DELETE das três
tabelas são recusados. A quantidade declarada e as posições únicas impedem
acrescentar evidência a uma conferência já completa. A gravação de pai, filhos,
auditoria e idempotência ocorre numa transação; interrupção reverte tudo.

A API exige Bearer de dispositivo ativo e `X-Idempotency-Key` nas mutações.
Limites de corpo e tratamento de erros sem ecoar valores são os existentes do
módulo. Auditoria registra referências/contagens; transcrições e justificativas
ficam no recurso financeiro protegido, não são copiadas para logs gerais.

## API

Prefixo `/api/v1/financial-imports`:

| Rota | Uso |
| --- | --- |
| `GET /previews/{id}/bill-assessment` | Parecer mais recente; sem parecer, revisão 0 e NOT_ASSESSED. |
| `POST /previews/{id}/bill-assessments` | Acrescenta revisão com controle de concorrência. |
| `GET /previews/{id}/bill-assessments` | Histórico de revisões, em ordem crescente, paginado. |
| `GET /bill-assessments/{id}/evidence` | Documentos, hashes, localizadores e declarações daquela revisão, paginados. |
| `GET /statements/{id}/bill-assessments` | Vínculos históricos; `is_current` distingue revisão atual de superada. |

Paginação: `limit` de 1 a 500 e `offset` não negativo. Selecionar a origem/cartão,
enviar os originais por `/documents`, gerar a prévia e então conferir. Arquivos
com o mesmo nome não são associados automaticamente.

Exemplo **sintético**, com referências substituíveis por IDs reais de teste:

```json
{
  "expected_revision": 0,
  "expected_source_id": "ID-CARTAO",
  "expected_result_sha256": "HASH-DA-PREVIA",
  "reason": "Conferencia manual do cabecalho e dos detalhes",
  "header": {"due_on": "2025-08-10", "total_amount_cents": 10000},
  "evidence": [{
    "document_id": "ID-PDF",
    "role": "HEADER",
    "source_id": "ID-CARTAO",
    "currency": "BRL",
    "identity_reason": "Origem e ciclo conferidos no documento",
    "page_number": 1,
    "header": {"due_on": "2025-08-10", "total_amount_cents": 10000}
  }, {
    "document_id": "ID-PDF",
    "role": "DETAILS",
    "source_id": "ID-CARTAO",
    "currency": "BRL",
    "identity_reason": "Detalhes da mesma origem e ciclo",
    "page_number": 2,
    "header": {"due_on": "2025-08-10", "total_amount_cents": 10000},
    "items": [{
      "preview_position": 1,
      "transaction_date": "2025-07-10",
      "amount_cents": 10000,
      "description": "Compra de exemplo"
    }]
  }],
  "observations": [],
  "resolutions": []
}
```

O hash deve ser o retornado pela prévia, não o hash do original. `header` pode
ser omitido quando desconhecido. Quando informado, exige vencimento e total
declarados; período é opcional, mas deve ter início/fim juntos e ordem válida.
Cada evidência declara os controles que foram transcritos; nesta versão o
cabeçalho da evidência também exige vencimento/total. Para guardar apenas um
parecer de ausência, usar cabeçalho desconhecido e nenhuma evidência.

## Regras de conferência

- Origem deve ser cartão; `expected_source_id` e hash precisam coincidir com a
  prévia. Evidências de outra origem/moeda são recusadas.
- Página é obrigatória para PDF. Outros formatos exigem página ou linha inicial;
  linha final opcional não pode preceder a inicial. Isso localiza a declaração,
  mas não prova que o arquivo possui aquela página sem um leitor PDF.
- Ao menos uma evidência HEADER deve coincidir com o cabeçalho escolhido.
  Controles declarados conflitantes geram pendência; não se escolhe um vencedor.
- A cobertura exige DETAILS de documento diferente do CSV principal. Referências
  precisam cobrir todas as posições da prévia, sem duplicar posições ou deixar
  ocorrências não correspondentes. `preview_position=null` registra linha extra
  sem forçar um vínculo.
- Data, valor inteiro em centavos e descrição são comparados exatamente após a
  validação textual do schema. Não há tolerância monetária, tradução de descrição,
  pareamento por similaridade ou conclusão de identidade bancária.
- Não comparar automaticamente o líquido das linhas ao total da fatura: a
  composição pode incluir saldo anterior/pagamento e requer análise própria.
- Diferenças do resumo ou outro problema observado devem ser registrados em
  `observations`, com chave estável e motivo. Não existe campo "aprovar mesmo assim".
- Até 20 evidências, 2.000 referências no total e 100 observações. Declarações
  maiores também respeitam o limite estruturado de 2 MiB. Resoluções têm teto
  de 8.200 para comportar múltiplas diferenças por linha, dentro do mesmo limite.

Referenciar o mesmo documento em várias páginas/papéis é permitido. Esses
vínculos não deduplicam nem criam transações. Uma diferença meramente textual
continua pendente nesta versão estrita; futuras equivalências deverão ter regra
explícita e testes, nunca limpeza silenciosa das descrições.

## Revisões e resoluções

Enviar a revisão corrente em `expected_revision`. Reenvio com a mesma chave e
payload retorna a mesma resposta; chaves diferentes com revisão superada geram
`FINANCIAL_BILL_REVISION_CONFLICT`. Mudança de payload usando chave antiga é
recusada pelo contrato geral de idempotência.

Quando um finding anterior desaparecer na nova transcrição, informar sua
resolução: `finding_id`, motivo, `document_id` presente na nova evidência e
localizador. Um finding que continua calculado **não pode ser dispensado** por
resolução. A revisão anterior, seus documentos e suas conclusões são preservados.
O operador pode continuar a registrar uma situação ainda pendente sem eliminar
as observações anteriores. A revisão não deve ser tratada como confirmação de
veracidade da declaração do operador.

## Confirmação e compatibilidade

O `POST /previews/{id}/confirm` aceita `assessment_id` opcional. Quando usado,
exige a conferência **mais recente daquela prévia**, status VERIFIED e os mesmos
controles de cabeçalho. Confirmação e vínculo são atômicos. Reenvio não cria
outro vínculo. O ID aparece na resposta; a associação histórica fica na tabela
própria e na auditoria. Uma revisão posterior não apaga vínculos antigos.

O fluxo anterior **sem `assessment_id` continua recebendo evidências**, com as
mesmas validações de leitura/cabeçalho. Seu hash de idempotência foi preservado.
Portanto, não afirmar que toda confirmação antiga passou a exigir conferência
nem que o backend bloqueia globalmente o staging de documentos divergentes.
Nenhum dos dois fluxos executa pagamento ou cria obrigação. Integração futura
deverá exigir conferência e qualificação semântica em seu próprio comando.

Nova prévia começa sem conferência; não herda aprovação de outro hash/documento
ou versão do leitor. Pareceres antigos consultados no histórico são retratos
daquele conjunto de documentos, não aprovações atuais de qualquer fatura.

## Migração, validação e implantação

O startup continua excluindo as tabelas financeiras de `create_all`. Sem as três
tabelas novas, o módulo retorna `FINANCIAL_SCHEMA_NOT_READY`/503. Planejar a
atualização do servidor e a migração em conjunto; não usar startup como migrador.
O downgrade recusa excluir qualquer uma das três tabelas se houver evidência.
Antes de implantação: backup verificado, janela de atualização e recuperação.

A nova migração foi validada em base sintética preenchida e em cópia descartável
da base local. A conexão original era somente leitura e mostrou revisão
`fc2f3a4b6512` com 41 tabelas. A cópia chegou a `fd3a4b5c7613`, preservando dados,
índices/gatilhos anteriores, integridade e FKs. **A nova migração não foi aplicada
à base original.** Isso atualiza a observação histórica anterior de revisão f9;
não atribuímos a alteração intermediária a este incremento.

Nas duas amostras reais, o novo fluxo registrou controles transcritos do PDF e
observações manuais. Os detalhes não foram transcritos individualmente para o
novo endpoint: a cobertura permaneceu pendente e a confirmação com o parecer
foi bloqueada. Essa homologação comprova guarda de procedência/pendência, não
validação automática dos detalhes do PDF nem resolução das diferenças anteriores.

Relatórios sanitizados: [migração da cópia](validacoes_financeiras/2026-10-16-migracao-conferencia-faturas.json)
e [procedência dos originais](validacoes_financeiras/2026-10-16-procedencia-faturas.json).
Os originais, controles e manifestos permanecem fora do Git.

### Decisões adicionais e fontes

**FAT-011:** conferência pertence à prévia; vínculo com statement é tabela
aditiva própria. Evitou alterar/reconstruir evidências existentes e permite
parecer antes do staging. A escolha de não reconstruir veio das restrições do
projeto e da consulta de 16/10 à documentação de
[ALTER TABLE do SQLite](https://www.sqlite.org/lang_altertable.html), que descreve
implicações de renomear/reconstruir tabelas referenciadas. Não se afirmou que o
SQLite proíbe toda alteração de tabela; não foi necessário fazê-la aqui.

**FAT-012:** comparação exata e revisão explícita, sem autorização comercial.
Dados transcritos têm origem atribuída, mas continuam declarações humanas. A
aplicação de [procedência W3C](https://www.w3.org/TR/prov-overview/) segue a
fundamentação do documento de arquitetura, sem adicionar RDF/OWL.

Também foram conferidas em 16/10 as referências oficiais de
[FKs SQLite](https://www.sqlite.org/foreignkeys.html) e
[transações SQLite](https://www.sqlite.org/lang_transaction.html). Aplicação:
preservar referências, serializar a gravação na transação existente e testar
integridade. A compatibilidade de migração foi verificada por testes; não foi
presumida apenas pela leitura da documentação.

Código: modelos/schemas/serviço `financial_bill_assessments.py`, rotas em
`api/v1/financial_imports.py`, integração em `financial_previews.py` e migração
`fd3a4b5c7613_audited_bill_evidence_assessments.py`. Testes:
`test_financial_bill_assessments.py`, `test_financial_bill_assessment_migration.py`
e verificações gerais de migração/backup.

Validação final: **386 testes backend e 238 Flutter aprovados**, incluindo 23
casos novos deste incremento. A comparação de metadata/gatilhos entre Alembic
e as bases isoladas também passou. Os avisos preexistentes permaneceram.
