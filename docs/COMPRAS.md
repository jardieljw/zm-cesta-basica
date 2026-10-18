# Compras, entrada de estoque e cancelamento

Revisão: **14/10/2026**. [Índice](README.md).

## Para que serve e interface

Em **Compras → Nova Compra**, informar fornecedor, itens, forma de compra, quantidade, preço e condição de pagamento. Conferir a quantidade convertida e o total antes de salvar. Na listagem, consultar detalhes e as ações disponíveis para o status da compra.

Quantidade e preço são da embalagem selecionada. Sem embalagem, são da unidade-base. Ver [Produtos e formas de compra](PRODUTOS_E_FORMAS_DE_COMPRA.md).

## Regras do backend

A API cria a compra em `POST /purchases`. Uma compra `DRAFT` registra os itens, mas ainda não repõe o estoque. A criação já confirmada ou `POST /purchases/{id}/confirm` registra a entrada. São validados produtos ativos, embalagens compatíveis e conversões.

Na confirmação, o backend adiciona movimentos `PURCHASE`, atualiza o custo de referência e o custo médio ponderado em microcentavos. O cálculo usa saldo e custo anteriores, quantidade e valor da nova entrada. A compra a prazo gera obrigação em aberto; a compra à vista registra a obrigação quitada, o pagamento e o débito financeiro quando há valor positivo e conta interna resolvida.

## O que mexe no banco

| Tabela | Efeito |
| --- | --- |
| `purchases`, `purchase_items` | Cabeçalho, status, pagamento e itens com conversão e valores registrados. |
| `inventory_movements` | Entrada de produtos na confirmação; movimentos `PURCHASE_CANCEL` no cancelamento confirmado. |
| `products` | Atualização dos campos de custo na entrada confirmada. |
| `accounts_payable`, `payable_payments` | Obrigação da compra e confirmação de pagamento conforme a condição. |
| `cash_flow_entries` | Débito da compra/pagamento e lançamentos inversos quando aplicáveis. |

## Cancelamento e exemplo

`POST /purchases/{id}/cancel` preserva a compra. Em rascunho, muda o status sem estornar estoque que nunca entrou. Em compra confirmada, soma as quantidades por produto e exige saldo para remover a entrada inteira, antes de criar os movimentos inversos. Trata também a obrigação vinculada e os pagamentos conforme o serviço.

Comprar três sacos de arroz de 5 kg, a R$ 25,00 cada, registra R$ 75,00 e entrada de 15.000 G. Se restarem apenas 10.000 G, cancelar essa entrada de 15.000 G será bloqueado. O cancelamento não refaz a sequência histórica do custo médio: não interpretar a baixa como recálculo retroativo de todos os custos.

## Onde conferir

- [Lista](../client/lib/views/purchases_view.dart), [formulário](../client/lib/views/purchase_form_view.dart) e [serviço](../client/lib/services/purchase_service.dart).
- [API](../backend/app/api/v1/purchases.py), [serviço de compras](../backend/app/services/purchases.py), [modelo](../backend/app/models/purchases.py).
- [Testes](../backend/tests/test_purchases.py).
