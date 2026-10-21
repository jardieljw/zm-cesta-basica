# Receitas e composição das cestas

Revisão: **20/10/2026**. [Índice](README.md).

## Para que serve e interface

Na gestão de um tipo de cesta, abrir sua composição/receita. Informar quais produtos entram em uma cesta, a quantidade na unidade-base, a seção e a indicação de item obrigatório. Consultar versões anteriores permite entender a composição utilizada em outras épocas.

O cadastro de receita não monta cestas nem altera o saldo de produtos. Ele prepara a composição que a montagem padrão consumirá.

## Regras do backend

`POST /basket-types/{id}/recipes` cria outra receita no mesmo tipo de cesta,
valida produtos/quantidades e torna a nova versão `ACTIVE`; a anterior passa a
`ARCHIVED`. Não é necessário criar outro tipo de cesta para mudar composição.

Em **Gerenciar receita**, selecionar uma versão oferece **Editar receita**,
**Excluir receita**, **Inativar receita** ou **Usar esta receita nas próximas
montagens**. Venda não cancelada usando a composição e montagem ainda não
desfeita bloqueiam edição/exclusão, com os registros e seus atalhos. Cancelar
todas as vendas que a bloqueiam e desfazer as montagens libera a receita.
Ter sido usada alguma vez não é um bloqueio permanente.

`PUT /basket-types/{id}/recipes/{n}` edita receita elegível; se existe montagem
histórica, conserva a versão original e cria uma substituta no mesmo tipo.
`DELETE` retira a receita da seleção (`REMOVED`), conservando o histórico.
As ações `/activate` e `/deactivate` alternam `ACTIVE`/`ARCHIVED`; somente uma
receita por tipo fica ativa. A ativação exige ingredientes disponíveis.
As mutações revalidam os vínculos e têm idempotência transacional.

O campo opcional **Preço sugerido (R$)** pertence à receita. Sem preenchê-lo,
vale o preço padrão do tipo de cesta. Nova Venda usa a sugestão da receita ativa
e permite negociar outro valor. O preço efetivo e os custos das vendas antigas
permanecem como foram registrados. Isso não representa alteração do custo de
compra do ingrediente nem troca automática de fornecedor.

A montagem padrão consulta a receita ativa e multiplica as quantidades pelo número de cestas. O motor atual percorre todos os itens da receita, inclusive os marcados como não obrigatórios: esse campo não significa que o item será automaticamente omitido na montagem padrão.

## O que mexe no banco

| Tabela | Alteração |
| --- | --- |
| `recipe_versions` | Nova versão com número sequencial por tipo de cesta; atualização do status da versão anterior. |
| `recipe_items` | Produtos, quantidades por cesta, seção e `is_required` da nova versão. |
| `production_batches` e `production_batch_items` | Somente na montagem: vínculo à versão usada e cópia dos consumos e custos, preservando a composição efetiva. |
| `recipe_versions.suggested_price_cents` | Sugestão opcional para novas vendas; não recalcula valores históricos. |
| `sale_recipe_references` | Candidatas congeladas nas novas vendas de estoque padrão sem identificação de lote; versões criadas depois não passam a pertencer à venda. |

## Exemplo e limites

Uma receita com 5.000 G de arroz e 2.000 G de feijão consome 15.000 G e 6.000 G ao montar três cestas. Se a receita mudar depois, o lote antigo mantém seus consumos e custos. Cancelar uma venda cuja montagem não aconteceu devolve os produtos registrados naquele lote, conforme [o guia de cancelamento](CANCELAMENTO_DE_VENDAS_E_MONTAGEM.md).

Criar uma nova receita não recalcula custos de vendas antigas e não altera cestas já montadas. Composição personalizada recebida pela API é registrada como lote personalizado, sem substituir a receita padrão; seu editor não está na tela atual de Nova Venda.

Vendas ligadas a uma montagem identificam sua receita diretamente. Nas vendas
antigas de estoque padrão sem essa identificação, o sistema não inventa qual
versão foi vendida: protege as candidatas e identifica a venda como sem receita
identificada. Nas novas, conserva as candidatas existentes naquele momento.
Mistura de composições no saldo padrão pode exigir uma decisão anterior de
venda/estoque para confirmar uma desmontagem; o sistema não devolve ingredientes
de uma composição usando cestas de outra. O limite aparece com os registros.

Na falha de conexão, **Retomar confirmação pendente** repete o mesmo corpo/chave.
Se a retomada for rejeitada definitivamente, **Rever dados da receita** recupera
notas, preço e ingredientes para correção. Ingredientes inativos não são
removidos silenciosamente: permanecem visíveis para substituição/remoção explícita.

## Onde conferir

- [Tela de receita](../client/lib/views/recipe_view.dart) e [BasketService](../client/lib/services/basket_service.dart).
- [API](../backend/app/api/v1/basket_types.py), [modelos de receitas](../backend/app/models/products.py) e [motor de montagem](../backend/app/services/production.py).
- [Testes](../backend/tests/test_recipes.py) e [testes de produção](../backend/tests/test_production.py).
