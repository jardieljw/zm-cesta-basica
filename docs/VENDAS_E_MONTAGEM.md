# Vendas, cesta pronta e montagem na venda

Revisão: **14/10/2026**. [Índice](README.md).

## Para que serve e interface

Em **Vendas → Nova Venda**, selecionar cliente, pagamento, tipo de cesta, quantidade, preço, desconto e observações. Adicionar linhas para vender outros tipos. O preço padrão preenche a referência; a venda conserva o preço efetivamente confirmado.

| Controle da linha | Significado |
| --- | --- |
| “Pronta”, à esquerda; toggle desligado | Padrão, em verde. Usa cestas já montadas e exige saldo suficiente. |
| “Montar”, à direita; toggle ligado | Em laranja. Monta durante a confirmação da venda, usando produtos da receita ativa e exigindo saldo desses produtos. |

O toggle fica entre os nomes, acompanha a cor selecionada e o nome escolhido
fica em negrito. A explicação aparece abaixo. Somente “Pronta” mostra
“Cestas prontas disponíveis: X”, consultando o tipo selecionado. “Montar” oculta
o indicador com animação de opacidade e altura de aproximadamente 220 ms, sem
deixar um espaço vazio. Retornar a “Pronta” expande o indicador e consulta o
saldo novamente. A plataforma pode desativar a animação por redução de movimento.

Sem tipo selecionado, a tela orienta selecionar uma cesta. Durante a consulta,
mostra “Consultando saldo…”. Falha aparece com mensagem e ação para tentar de
novo, nunca como zero. Venda de cesta pronta aguarda uma consulta bem-sucedida;
montagem pode ser confirmada sem essa consulta, com validação de produtos pelo
backend. Respostas antigas não substituem a consulta mais recente. A atualização
visual está no código e exige distribuir o cliente recompilado.

O botão altera o pedido da linha, não o cadastro do tipo de cesta. Trocar a seleção ou preencher campos não registra a venda. A tela atual envia `DIRECT_STORE` e não oferece responsável/expedição nem editor de composição personalizada.

## Regras do backend

`POST /sales` valida tipo ativo, quantidade, valores, cliente e pagamento. Revalida o saldo mesmo que a tela já o tenha consultado. O subtotal líquido de uma linha é `quantidade × preço unitário − desconto da linha`; o desconto não é multiplicado pela quantidade.

Sem `assemble_on_demand`, a venda baixa apenas cestas prontas com movimento `SALE`. Não desconta seus ingredientes novamente. Na cesta padrão, o custo prefere o último lote padrão confirmado com custo positivo e usa a prévia da receita como alternativa; não é uma seleção FIFO do lote físico vendido.

Com `assemble_on_demand=true`, cria um lote de produção com `is_direct_sale=true`, copia consumos/custos, lança `ASSEMBLY_CONSUME` dos produtos, `ASSEMBLY_PRODUCE` das cestas e `SALE` das cestas. A montagem e a venda fazem parte da mesma operação.

## O que mexe no banco

- `sales`: venda, número, cliente, condição de pagamento, status e total.
- `sale_items`: quantidade, preço, desconto, custo congelado e eventual lote.
- `production_batches`, `production_batch_items`: apenas quando há montagem na venda, preservando composição e custo.
- `inventory_movements`: saídas e, quando há montagem, consumo e entrada.
- `sales_receivables`: título para fiado; ver [Contas a receber](CONTAS_A_RECEBER.md).
- `cash_flow_entries`: recebimento imediato conforme a condição; conta interna é resolvida pelo backend.

## Exemplo e limites

Vender duas cestas prontas diminui seu saldo em duas. Montar duas na venda consome os ingredientes, registra +2 cestas e −2 cestas; não aumenta o saldo final de cestas prontas. Falta de produtos bloqueia a montagem, mesmo que não seja necessário saldo inicial de cestas.

O backend também mantém montagem personalizada e venda de lote personalizado; isso não implica um editor disponível na tela atual. Com `tracks_finished_stock=false`, a tela usa “Montar” automaticamente e oculta “Pronta” e o saldo; o backend rejeita a venda de cestas prontas. Ver [Tipos de cesta](TIPOS_DE_CESTA.md) e [Cancelamento](CANCELAMENTO_DE_VENDAS_E_MONTAGEM.md).

## Onde conferir

- [Formulário](../client/lib/views/sale_form_view.dart), [lista e cancelamento](../client/lib/views/sales_view.dart), [serviço](../client/lib/services/sale_service.dart).
- [API](../backend/app/api/v1/sales.py), [serviço de vendas](../backend/app/services/sales.py), [montagem](../backend/app/services/production.py), [modelos](../backend/app/models/sales.py).
- [Testes backend](../backend/tests/test_sales.py) e [testes do cliente](../client/test/active_sale_and_report_test.dart).
