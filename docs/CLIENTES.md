# Clientes, crédito e extrato

Revisão: **14/10/2026**. [Índice](README.md).

## Para que serve e interface

Em **Clientes**, cadastrar ou editar identificação, contato e condições de crédito; consultar o extrato para acompanhar vendas e recebimentos. Na venda, selecionar o cliente cadastrado ou usar consumidor não identificado no balcão. Para fiado, é necessário selecionar um cliente.

## Backend e banco

`POST /customers` cria o cadastro; `PUT /customers/{id}` altera os campos. O cadastro fica em `customers`. A dívida é consultada a partir de `sales_receivables`, e não digitada como saldo livre no cadastro. O extrato de `/customers/{id}/statement` reúne vendas confirmadas e pagamentos confirmados associados ao cliente.

O limite de crédito participa da validação de vendas a prazo: o serviço considera a dívida existente e a nova venda. Exceder o limite gera `CREDIT_LIMIT_EXCEEDED`; a API admite liberação explícita via `allow_credit_override`. A validação da venda continua no servidor.

Essa comparação só é aplicada quando `credit_limit_cents > 0`. Limite zero não bloqueia todo fiado; representa ausência desse limite positivo no comportamento atual.

`DELETE /customers/{id}` significa inativar: muda `is_active` e conserva o histórico. Cadastrar, editar ou inativar cliente não movimenta produtos, cestas ou caixa. Uma venda à vista sem cadastro pode usar o nome avulso em `sales.customer_name`.

## Exemplo e limites

Cliente com R$ 200,00 pendentes e limite de R$ 300,00: uma nova venda fiada de R$ 150,00 totaliza R$ 350,00 e exige tratar o bloqueio/liberação de crédito. Receber R$ 100,00 pelo fluxo de [Contas a receber](CONTAS_A_RECEBER.md) reduz a dívida; editar o nome ou telefone não quita títulos.

O extrato é uma consulta. Imprimir ou abrir esse extrato não confirma recebimento. Inativar cliente não cancela suas vendas nem apaga suas dívidas.

## Onde conferir

- [Lista](../client/lib/views/customers_view.dart), [cadastro](../client/lib/views/customer_form_view.dart), [extrato](../client/lib/views/customer_statement_dialog.dart) e [serviço](../client/lib/services/customer_service.dart).
- [API](../backend/app/api/v1/customers.py), [serviço](../backend/app/services/customers.py), [modelo](../backend/app/models/customers.py) e [validação da venda](../backend/app/services/sales.py).
- [Testes](../backend/tests/test_customers.py).
