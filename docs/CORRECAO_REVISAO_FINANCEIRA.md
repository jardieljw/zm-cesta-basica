# Correção auditável da revisão financeira

Revisão: **15/10/2026**. Implementado no backend pela API, sem telas novas e sem
aplicação da migração no banco da empresa. [Índice](README.md).

## Finalidade

Uma conferência pode associar duas ocorrências ao mesmo evento externo por
engano. Exemplo: dois débitos legítimos de R$ 100 no mesmo dia foram tratados
como o mesmo pagamento. A correção permite separar as ocorrências, mudar o
evento escolhido ou retirar uma confirmação, preservando as decisões anteriores.
Funciona para entradas, saídas e itens de cartão, independentemente do banco.

Esse fluxo corrige a **interpretação da evidência**, sem modificar pagamentos,
recebimentos, contas a pagar/receber, valores de caixa, estoque ou relatórios
comerciais. Alterar os fatos de uma ocorrência, como data ou valor extraído,
continua exigindo outra interpretação do documento; a correção de revisão não
edita o arquivo ou os dados normalizados.

## Decisões e proteções

- `NEW`: separar uma ocorrência vinculada por engano, ou confirmar uma ocorrência
  anteriormente ignorada. Data/valor semelhantes não são identidade suficiente.
- `LINK`: associar a uma operação confirmada ativa. O backend revalida origem,
  valor, datas, horário e demais fatos conhecidos; não permite usar operação sem
  evidência ativa como destino de uma associação.
- `IGNORE`: retirar a confirmação daquela ocorrência. O original permanece
  consultável; isso não apaga o evento nem estorna o pagamento real.
- Motivo e dispositivo autor são obrigatórios. A primeira revisão deve estar
  concluída; linhas pendentes seguem usando `/review`.
- A requisição deve informar a revisão atual. Se outra pessoa já corrigiu a
  ocorrência, retorna `FINANCIAL_REVIEW_CHANGED`, sem sobrescrever sua decisão.
- Uma decisão sem mudança de associação é recusada como
  `FINANCIAL_CORRECTION_NO_CHANGE`; `NEW` sobre ocorrência já separada também.
- **Conciliação ativa em qualquer operação envolvida bloqueia a correção.** O
  operador precisa desfazer explicitamente esses vínculos em
  `/reconciliations/{id}/void`, com motivo. Depois corrige a revisão e, quando
  apropriado, registra a conciliação correta. Nenhuma etapa estorna pagamentos.

O mesmo identificador confiável de banco, no mesmo escopo de conta/namespace,
não pode virar dois eventos ativos. Havendo outras ocorrências que confirmam
essa identidade, a transferência é bloqueada até revisar os vínculos envolvidos.
Retirar uma dessas ocorrências não libera o ID enquanto outra ainda o sustentar.
Não se transfere silenciosamente um conjunto inteiro de evidências.

Se um identificador foi acrescentado por um vínculo equivocado, sua associação
pode ser corrigida de forma auditada quando não houver outra evidência conflitante.
O alias original é preservado; uma entrada de histórico registra a nova associação.
A próxima importação consulta essa associação atual, evitando repetir o erro.

## Modelo e consultas

`financial_statement_items` conserva a **primeira decisão** e o conteúdo original.
`financial_review_corrections` acrescenta as decisões seguintes, numeradas por
ocorrência. A situação atual é uma projeção da última decisão, usada pelas listas,
consulta de evidências, candidatos, contagens e verificações de conciliação.
Nenhum registro original precisa ser atualizado ou apagado para corrigir a revisão.

`financial_identity_changes` conserva as mudanças de associação e liberação de
identificadores. A associação atual é a última mudança, ou o alias original
quando não houver mudança. Revisões, mudanças de identidade e auditoria são
imutáveis também no SQLite. Gatilhos protegem sequência de revisão, origem,
imutabilidade e impedem inserir correção sobre conciliação ativa.

Um evento sem ocorrências confirmadas ativas recebe `evidence_status=WITHDRAWN`;
não aparece na listagem padrão de eventos nem nas sugestões. Permanece disponível
com `include_inactive=true`, e não pode ser conciliado. Seu valor não é exposto
como saldo a conciliar (`unreconciled_amount_cents=null`). Não é exclusão contábil:
o evento é evidência externa e nunca foi um lançamento novo no livro-caixa.

Os campos `external_id_namespace`/`external_id` do evento são os fatos registrados
na criação, preservados historicamente. **Associações atuais** são devolvidas em
`external_identities` na lista de eventos; não usar os campos originais para
reconstruir associações depois de uma correção. Candidatos por ID incluem
`matched_identity`. Um ID liberado e posteriormente confirmado novamente pode
reutilizar o evento histórico compatível, sem reescrever seus fatos.

## API para o futuro front-end

Prefixo `/api/v1/financial-imports`, Bearer de dispositivo ativo. POST exige
`X-Idempotency-Key`. Não foi acrescentada uma ação visual no aplicativo atual.

| Operação | Endpoint |
| --- | --- |
| Consultar situação atual | `GET /items/{id}` ou `GET /statements/{id}/items` |
| Consultar decisões em ordem | `GET /items/{id}/review-history?limit=100&offset=0` |
| Registrar correção | `POST /items/{id}/corrections` |
| Listar eventos ativos | `GET /transactions` |
| Incluir eventos retirados | `GET /transactions?include_inactive=true` |
| Evidências atualmente associadas | `GET /transactions/{id}/evidence` |
| Incluir evidências de associações anteriores | `GET /transactions/{id}/evidence?include_history=true` |

Para separar uma ocorrência vinculada erroneamente, ler `review_revision` e enviar:

```json
{
  "expected_revision": 0,
  "action": "NEW",
  "reason": "O extrato confirma duas operacoes distintas."
}
```

Para mudar o destino, usar `action=LINK` e `transaction_id`. Para retirar a
confirmação, `action=IGNORE`. A resposta traz a situação atual, a nova correção,
o evento associado quando houver e `affects_ledger=false`. A próxima correção
usa a nova `review_revision`. Repetir a mesma chave/payload devolve a mesma
resposta, sem acrescentar outra revisão.

As listas de ocorrências devolvem os campos de revisão atuais e também
`original_review_status`/`original_transaction_id`. O histórico começa na revisão
zero e inclui autor, instante e motivo. Para evidência antiga inserida sem uma
entrada de auditoria, o motivo original fica nulo, sem inventar uma justificativa.

`include_history=true` devolve ocorrências que participaram de alguma decisão
para aquele evento, **com sua situação atual**; o histórico completo da decisão
continua em `/review-history`. Não somar essa lista como vínculos ativos.

## Migração e recuperação

Migração `fc2f3a4b6512`, depois de `fb1e2f3a5411`: acrescenta duas tabelas,
índices e gatilhos, sem modificar as tabelas anteriores. Não requer reescrever
revisões existentes ou copiar dados do histórico. Startup não substitui Alembic;
sem a estrutura completa, as rotas financeiras retornam 503.

Decisão, mudança de identidade, auditoria e idempotência são uma única transação
`BEGIN IMMEDIATE`. Falha intermediária desfaz tudo; concorrência com revisão
esperada igual permite apenas uma correção. Backup/restauração existentes
incluem originais, decisões anteriores e associações atuais. Downgrade é recusado
quando houver correções ou mudanças de identidade gravadas.

Aplicar no servidor somente com backup verificado e conferência de integridade.
A entrega preserva o banco original da empresa sem migração. A proteção local
de armazenamento e permissões segue os limites descritos na
[base financeira](BASE_FINANCEIRA_E_CONCILIACAO.md); esta função não cria papéis
de usuário ou criptografia de aplicação.

Testes usam dados sintéticos e bancos isolados: separação de débitos/créditos,
transferência de alias, outras evidências do mesmo ID, conciliação ativa,
inatividade, concorrência, falha parcial, backup e migração preenchida sob
`foreign_keys=ON`.

Resultado desta entrega: **333 testes backend e 238 testes Flutter aprovados**.
A atualização de uma cópia do banco da empresa até `fc2f3a4b6512` preservou os
dados das 30 tabelas anteriores, seus índices e gatilhos, com `integrity_check`
e `foreign_key_check` aprovados. O original permaneceu em `f9c0d1e2f309`.
Não foram inseridos documentos pessoais reais no banco da empresa.

Referências de implementação: `backend/app/services/financial_review_corrections.py`,
modelos/schemas/API `financial_imports.py`, migração `fc2f3a4b6512`, testes
`test_financial_review_corrections.py` e `test_financial_review_migration.py`.
