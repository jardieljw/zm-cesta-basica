# Editar, inativar e excluir tipos de cesta

Revisão: **14/10/2026**. [Índice](README.md).

## Onde aparece

Cada cartão em Tipos de Cesta usa os mesmos ícones do catálogo de produtos:
lápis para editar, olho cortado para inativar e lixeira vermelha para excluir.
O olho aparece quando o tipo está ativo. Excluir está disponível também para
tipos inativos. Inativar não é excluir: mantém o tipo na lista e permite alterar
seu status pelo cadastro. Excluir tem confirmação própria.

## Regra aprovada pelo usuário

O usuário confirmou **retirar do catálogo e preservar o histórico** para cestas
utilizadas em vendas canceladas. Essa ação limpa o catálogo; não apaga registros
de teste das vendas, montagens, finanças ou movimentos do banco.

| Situação | Resultado de Excluir |
| --- | --- |
| Nunca usada em operação | Apaga o tipo e todas as suas receitas nunca utilizadas. Preserva os produtos e embalagens. O código fica disponível para um novo cadastro. |
| Possui histórico, sem vendas não canceladas, sem saldo e sem saída aberta | Retira do catálogo: marca `removed_at` em UTC e `is_active=false`, preservando tipo, código, receitas e vínculos. |
| Venda não cancelada | Bloqueia até tratar a operação. |
| Saldo padrão ou personalizado, em qualquer localização ou responsabilidade | Bloqueia até tratar o estoque físico. Saldos diferentes não são somados para esconder saldo de um lote/local. |
| Saída/conferência aberta | Bloqueia até concluir/cancelar o fluxo existente. |

Quando há histórico, o código continua reservado pela unicidade do cadastro
preservado. A ação não oferece recuperação/reativação pelo editor comum. Não
renomear IDs/códigos históricos como atalho para liberar unicidade.

Cancelar a venda não significa saldo zero: se as cestas continuam montadas, elas
retornam ao estoque e a exclusão fica bloqueada. Quando a montagem não aconteceu
fisicamente, a escolha correta no cancelamento retorna os produtos e permite
excluir do catálogo após a revalidação. Não escolher esse destino apenas para
contornar o bloqueio quando as cestas realmente existem.

## Interface e API

Antes da confirmação, `GET /api/v1/basket-types/{id}/deletion-check` informa se
pode excluir, o modo `PERMANENT` ou `CATALOG_ONLY` e motivos de bloqueio. O diálogo
distingue apagar definitivamente de excluir do catálogo preservando histórico.

`DELETE /api/v1/basket-types/{id}/catalog` revalida vínculos, vendas e saldo sob
a transação central `BEGIN IMMEDIATE`. A consulta anterior é informativa; não
autoriza contornar uma operação nova feita por outro terminal. A operação usa
idempotência, preservando o resultado em reenvio com a mesma chave.

`DELETE /api/v1/basket-types/{id}` continua apenas inativando, sem substituir
silenciosamente o contrato anterior. Produtos também conservam seus contratos:
este fluxo não libera exclusão de produtos que tenham histórico.

Tipos excluídos do catálogo não aparecem em `GET /basket-types`, mesmo sem filtro
ou ao pedir inativos. Consultas diretas e histórico continuam acessíveis para
interpretar registros anteriores. O servidor rejeita edição/reativação e novas
receitas em tipos removidos. Novas vendas/montagens rejeitam tipos inativos;
ajustes de estoque também rejeitam tipos removidos.

## Banco, migração e recuperação

A migração Alembic `f9c0d1e2f309`, após `f8b9c0d1e208`, acrescenta somente
`basket_types.removed_at`, inicialmente nulo. Nenhuma cesta existente é removida
pela migração. A marca só é escrita após a confirmação explícita de Excluir.

No modo definitivo, receitas e seus `recipe_items` nunca usados são apagados
antes de `basket_types`. No modo de catálogo, apenas o status e a marca do tipo
mudam. Vendas, itens de vendas, montagens, movimentos e registros financeiros
não são apagados, desconectados ou recalculados.

Antes da aplicação no banco real, foi criado backup quente verificado, testado
upgrade/downgrade em uma cópia preenchida e comparado o conteúdo das tabelas,
além de `integrity_check` e `foreign_key_check`. O script
`scripts/verify_basket_catalog_migration.py` reproduz essa verificação sem
alterar o original. Recuperação usa o fluxo existente de backup/restauração;
considerar operações posteriores antes de restaurar uma cópia anterior.
Downgrade técnico remove a marca de exclusão e não é um fluxo de recuperação do
catálogo: não executar com entradas removidas para tentar reativá-las.

## Referências e validação

- `backend/app/services/basket_catalog.py`: regras e exclusão transacional.
- `backend/app/api/v1/basket_types.py`: endpoints e filtro do catálogo.
- `client/lib/views/basket_types_view.dart`: ícones, prévia e confirmação.
- `backend/tests/test_basket_catalog_deletion.py`: cancelamento, saldo, vínculos,
  exclusão definitiva, reenvio e preservação dos registros.
- `backend/tests/test_basket_catalog_migration.py`: banco preenchido e migração.
- `client/test/basket_catalog_actions_test.dart`: ícones e fluxos de confirmação,
  cancelamento, bloqueio e distinção entre inativar/excluir.

## Falha de isolamento de testes identificada nesta validação

O teste antigo `test_duplicate_cash_flow_entry_prevention` importava SessionLocal
real. Além disso, o startup do TestClient usava a engine real, apesar de get_db
ter sido redirecionado. Isso foi corrigido: startup, engine e fábrica de sessões
internas usam o banco temporário; settings voltam ao estado anterior ao terminar.
Um teste de regressão verifica esses vínculos.

Foram identificados dois créditos de TEST_SOURCE criados pela suíte nesta etapa
(14/10/2026, UTC 19:51:33.474417 e 20:04:56.444870). Após backup, foram estornados
pelo serviço financeiro, com reversal_of_id, sem apagar os originais. O script
`reverse_isolation_test_entries.py` limita-se exatamente a esses registros,
verifica características e evita repetir um estorno. Não é ferramenta genérica
para limpar dados e não altera lançamentos anteriores de outras execuções.
