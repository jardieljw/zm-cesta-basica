# Estoque, movimentações e ajustes físicos

Revisão: **14/10/2026**. [Índice](README.md).

## Para que serve e interface

**Resumo de Estoque** apresenta os produtos, saldos e mínimos. **Movimentações** explica entradas e saídas com data, origem e justificativa. O diálogo de ajuste permite registrar entrada, saída, perda ou uma contagem física, sem editar o histórico anterior.

O saldo dos produtos soltos é diferente do saldo das cestas prontas. Na montagem, os produtos saem de seu estoque e as cestas entram no estoque acabado.

## Backend e banco

Consultas usam `/inventory/summary`, `/inventory/movements`, `/inventory/products/{id}/stock` e `/inventory/baskets/{id}/stock`. O ajuste usa `POST /inventory/adjustments`. As leituras não alteram o estoque.

O saldo é a soma dos valores positivos e negativos de `inventory_movements.quantity_delta`. O saldo padrão de cesta considera o tipo, a localização e movimentos sem lote personalizado. Lotes personalizados possuem saldo próprio no backend. `STORE` representa a loja; `TRANSIT` preserva registros de custódia das funções arquivadas.

| Tipo de ajuste | Efeito |
| --- | --- |
| `IN` | Adiciona a quantidade informada: `ADJUSTMENT_IN`. |
| `OUT` | Retira a quantidade: `ADJUSTMENT_OUT`. |
| `LOSS` | Retira a quantidade com movimento `LOSS`. |
| `COUNT` | Calcula a diferença entre contagem física e saldo atual e lança essa diferença. |

O serviço exige item válido e ativo, justificativa e quantidade adequada. Não permite saldo negativo em um ajuste de saída. A API também aceita ajustes de cestas, embora seja necessário distinguir as ações expostas pela tela atual das capacidades do backend.

O ajuste grava um movimento novo; não altera compras, vendas, receitas ou custo médio. Um ajuste de quantidade não registra automaticamente pagamento ou recebimento financeiro.

## Exemplo e limites

Saldo de sabonete: 100 UNIT. Contagem física: 96 UNIT. A ação de contagem cria uma saída de 4 UNIT; os movimentos anteriores continuam registrados. Se o erro pertence a uma venda ou compra identificável, preferir seu cancelamento próprio para preservar os vínculos comerciais e financeiros.

Produto abaixo do mínimo usa comparação estrita `saldo < mínimo` nas consultas correspondentes; saldo exatamente igual ao mínimo não é inferior ao mínimo.

## Onde conferir

- [Resumo](../client/lib/views/inventory_summary_view.dart), [movimentações](../client/lib/views/inventory_movements_view.dart), [diálogo](../client/lib/views/stock_adjustment_dialog.dart) e [serviço](../client/lib/services/inventory_service.dart).
- [API](../backend/app/api/v1/inventory.py), [cálculo e ajustes](../backend/app/services/inventory.py), [modelo e proteção do histórico](../backend/app/models/movements.py).
- [Testes de ajustes](../backend/tests/test_adjustments.py).
