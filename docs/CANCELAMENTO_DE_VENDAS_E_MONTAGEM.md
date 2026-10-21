# Cancelamento de vendas e montagem

Revisão: **20/10/2026**. [Índice](README.md).

## Onde escolher na interface

Em **Vendas**, clicar em **Cancelar Venda**. O diálogo solicita uma justificativa
e, para cada item identificado como montagem durante a venda, exige preencher
**Situação da montagem**. Nenhuma opção é escolhida automaticamente na tela.
A regra abaixo está implementada no código e depende de atualização do servidor
e do cliente instalado para aparecer no aplicativo.

O diálogo usa **Cancelar a venda nº ...?**, mostra cliente/data e diferencia
cancelar venda de estornar recebimento. Valor recebido aparece em reais (por
exemplo, R$ 150,00). **Ver recebimentos desta venda** abre diretamente o título
daquela venda, com consulta e estorno explícito. Retornar atualiza a lista;
nenhum recebimento ou venda é desfeito automaticamente. Durante gravação, edição
e fechamento do diálogo ficam bloqueados. Impedimento financeiro aparece como
mensagem da operação, sem marcar o motivo como se fosse um texto inválido.

No cancelamento, cada item montado durante a venda exige informar sua situação física:

- **As cestas continuam montadas:** estorna a saída da venda e mantém as cestas prontas em estoque. Os produtos continuam consumidos.
- **A montagem não aconteceu:** estorna a saída e desfaz contabilmente a montagem daquele item, devolvendo todos os produtos da composição congelada do lote. O saldo de cestas prontas não aumenta.

A escolha vale para a quantidade inteira de cada linha. Não representa desmontagem com perdas ou devolução parcial. Itens vendidos de estoque pronto sempre retornam como cestas prontas.

A API aceita `unassembled_item_ids` no pedido de cancelamento. Apenas IDs de itens da própria venda de balcão, ligados a lotes confirmados de montagem na venda, podem devolver produtos. Omissão da lista preserva o comportamento anterior de retorno das cestas prontas. A resposta dos itens inclui `assembled_on_demand` para a tela identificar as montagens, inclusive no histórico existente.

Não há alteração estrutural no banco. Os movimentos originais são preservados; novos movimentos registram o estorno da venda e, quando selecionado, o retorno dos produtos e a baixa correspondente das cestas. O lote desfeito recebe o status existente `DISASSEMBLED`, com motivo indicando montagem não realizada. O cancelamento financeiro e de títulos mantém as regras anteriores. Todas as operações ocorrem na mesma transação, com rollback em caso de erro e idempotência para impedir repetição.

## Backend e efeitos detalhados no banco

`POST /api/v1/sales/{id}/cancel` recebe motivo e os IDs selecionados. O servidor
valida que pertencem à venda e que correspondem a lotes de montagem direta,
confirmados e compatíveis com o item. IDs inválidos e itens vendidos de estoque
pronto não podem ser usados para devolver ingredientes.

| Registro | Efeito |
| --- | --- |
| `sales` | `status` e `payment_status` passam a `CANCELED`; guarda data e motivo. |
| `inventory_movements` | `REVERSAL` vinculado a cada saída original da venda. |
| Produtos de montagem não realizada | `DISASSEMBLY_RETURN`, com quantidades da composição congelada. |
| Cestas de montagem não realizada | `DISASSEMBLY_DEPARTURE`, compensando a entrada que o estorno da venda devolveu. |
| `production_batches` | Lote selecionado passa a `DISASSEMBLED`, com data e motivo; itens originais permanecem. |
| `sales_receivables` | Título sem pagamentos passa a `CANCELED`, com saldo zero. Se há valor pago, cancelar a venda é bloqueado até estornar os recebimentos. |
| `cash_flow_entries` | Lançamento inverso do recebimento imediato, quando aplicável, preservando o original. |

## Exemplo e limites

Três cestas que consumiram 15.000 G de arroz: se continuam montadas, o cancelamento
deixa três cestas prontas e não devolve arroz. Se a montagem não aconteceu, devolve
os 15.000 G e o saldo de cestas prontas não aumenta. A receita atual não substitui
a composição gravada no lote original.

A seleção é por linha inteira. Uma situação com parte da quantidade montada ou
com produtos perdidos não é representada por essa opção. Uma venda já cancelada
não pode ser cancelada novamente; a idempotência devolve a resposta do mesmo pedido
quando ele é reenviado com a mesma chave. A lista omitida na API preserva a regra
anterior; a exigência de escolha explícita está na interface atualizada.

## Onde conferir

- [Diálogo](../client/lib/views/sales_view.dart), [serviço](../client/lib/services/sale_service.dart) e [modelo de item](../client/lib/models/sale.dart).
- [API](../backend/app/api/v1/sales.py), [contrato](../backend/app/schemas/sales.py), [cancelamento](../backend/app/services/sales.py) e [retorno de produtos](../backend/app/services/production.py).
- [Testes backend](../backend/tests/test_sales.py) e [testes de escolha obrigatória](../client/test/sale_cancellation_test.dart).
