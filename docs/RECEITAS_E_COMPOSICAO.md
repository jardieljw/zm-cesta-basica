# Receitas e composição das cestas

Revisão: **14/10/2026**. [Índice](README.md).

## Para que serve e interface

Na gestão de um tipo de cesta, abrir sua composição/receita. Informar quais produtos entram em uma cesta, a quantidade na unidade-base, a seção e a indicação de item obrigatório. Consultar versões anteriores permite entender a composição utilizada em outras épocas.

O cadastro de receita não monta cestas nem altera o saldo de produtos. Ele prepara a composição que a montagem padrão consumirá.

## Regras do backend

`POST /basket-types/{id}/recipes` valida o tipo ativo, os produtos, quantidades e duplicidades. Cada alteração cria uma versão nova. A versão anterior deixa de ser `ACTIVE` e passa a `ARCHIVED`. Atualizar ou excluir diretamente uma versão por suas rotas é rejeitado; não se reescreve a receita histórica.

A montagem padrão consulta a receita ativa e multiplica as quantidades pelo número de cestas. O motor atual percorre todos os itens da receita, inclusive os marcados como não obrigatórios: esse campo não significa que o item será automaticamente omitido na montagem padrão.

## O que mexe no banco

| Tabela | Alteração |
| --- | --- |
| `recipe_versions` | Nova versão com número sequencial por tipo de cesta; atualização do status da versão anterior. |
| `recipe_items` | Produtos, quantidades por cesta, seção e `is_required` da nova versão. |
| `production_batches` e `production_batch_items` | Somente na montagem: vínculo à versão usada e cópia dos consumos e custos, preservando a composição efetiva. |

## Exemplo e limites

Uma receita com 5.000 G de arroz e 2.000 G de feijão consome 15.000 G e 6.000 G ao montar três cestas. Se a receita mudar depois, o lote antigo mantém seus consumos e custos. Cancelar uma venda cuja montagem não aconteceu devolve os produtos registrados naquele lote, conforme [o guia de cancelamento](CANCELAMENTO_DE_VENDAS_E_MONTAGEM.md).

Criar uma nova receita não recalcula custos de vendas antigas e não altera cestas já montadas. Composição personalizada recebida pela API é registrada como lote personalizado, sem substituir a receita padrão; seu editor não está na tela atual de Nova Venda.

## Onde conferir

- [Tela de receita](../client/lib/views/recipe_view.dart) e [BasketService](../client/lib/services/basket_service.dart).
- [API](../backend/app/api/v1/basket_types.py), [modelos de receitas](../backend/app/models/products.py) e [motor de montagem](../backend/app/services/production.py).
- [Testes](../backend/tests/test_recipes.py) e [testes de produção](../backend/tests/test_production.py).
