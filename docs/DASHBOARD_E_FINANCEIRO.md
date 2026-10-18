# Dashboard e resultado financeiro gerencial

**Interface FE-055 — 17/10/2026:** Início reúne Dia/Semana/Mês, contas com
vencimento no período, vendas/cestas e atenção atual de vencimentos/estoque.
Financeiro reúne Resumo/Pagar/Receber e recortes recolhidos. O resultado
gerencial fica em **Negócio → Entender o resultado**, com indicação de custo
incompleto. As consultas continuam nos serviços/endpoints descritos abaixo;
estoque e pendências permanecem posições atuais. Ver
[integração e limites](INTEGRACAO_INTERFACE_APROVADA.md).

Revisão: **14/10/2026**. [Índice](README.md).

## Para que serve e interface

O **Dashboard** reúne vendas, compras, estoque, confirmações financeiras e pendências. Os filtros mudam o período das operações apresentado. O cliente atual consulta `GET /dashboard/business-summary`; o relatório financeiro usa `/reports/business-financial-summary`.

## Como o backend calcula

| Indicador | Regra |
| --- | --- |
| Valor das vendas | Soma vendas `CONFIRMED` no período, incluindo fiado ainda não recebido. |
| Custo vendido | Soma custos congelados em `sale_items` das vendas consideradas. |
| Lucro bruto | Valor vendido menos custo vendido. |
| Outras despesas pagas | Pagamentos empresariais do período, excluindo compras de estoque vinculadas e retiradas pessoais. |
| Resultado gerencial | Lucro bruto menos outras despesas pagas. |
| Recebido/pago | Lançamentos das origens `SALE`, `RECEIVABLE_PAYMENT`, `PAYABLE_PAYMENT` e `PURCHASE`, considerando os sinais dos estornos. |
| Diferença recebido − pago | Comparação dos movimentos do período; não é saldo bancário. |
| Pendências | Saldos atuais de títulos abertos/parciais; não ficam todos restritos ao período das vendas. Vencimentos no período são apresentados separadamente. |
| Estoque | Saldo atual dos produtos ativos na loja, incluindo comparação com mínimo. |

O estoque e as pendências são posições atuais, mesmo quando se seleciona um período antigo de operações. Vendas sem custo registrado são contadas para indicar a limitação do resultado. O serviço considera vendas confirmadas existentes, inclusive histórico de modos antigos; ausência da tela de rota não apaga esse histórico.

## Banco e exemplo

A consulta lê `sales`, `sale_items`, `purchases`, `products`, `inventory_movements`, `sales_receivables`, `accounts_payable`, pagamentos e `cash_flow_entries`. Não cria pagamentos, vendas ou movimentações ao abrir o dashboard.

Exemplo: vendas de R$ 1.000,00, custo vendido de R$ 600,00 e outras despesas pagas de R$ 100,00 resultam em lucro bruto de R$ 400,00 e resultado gerencial de R$ 300,00. Se parte das vendas for fiado, o recebido pode ser menor que R$ 1.000,00. Comprar estoque não é descontado novamente desse lucro bruto, pois o custo vendido já representa o estoque consumido nas vendas.

## Limites e referências

É resultado gerencial do app, não demonstração fiscal completa nem conciliação bancária. A interface não mostra saldo de contas ou depósitos manuais de tesouraria. O [registro da simplificação](../client/_archive/DASHBOARD.md) explica o histórico da mudança.

- [Tela](../client/lib/views/dashboard_view.dart) e [serviço cliente](../client/lib/services/dashboard_service.dart).
- [API](../backend/app/api/v1/dashboard.py), [serviço de cálculos](../backend/app/services/business_dashboard.py), [schemas](../backend/app/schemas/business_dashboard.py).
- [Testes backend](../backend/tests/test_business_dashboard.py) e [testes cliente](../client/test/business_dashboard_test.dart).
