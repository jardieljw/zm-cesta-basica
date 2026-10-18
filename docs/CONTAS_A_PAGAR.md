# Contas a pagar, pagamentos e recorrência

**Entrada FE-055:** Financeiro → Pagar apresenta os recortes atuais. Abrir uma
conta segue para detalhe/histórico e pagamento revisado. **Filtrar → Histórico
e cadastros** conserva pesquisa ampliada, criação, recorrência, histórico e
demais ações existentes. A integração não altera as regras abaixo.

Revisão: **16/10/2026**. [Índice](README.md).

**FE-053 — pagamento revisado implementado no código:** o botão Pagar / Amortizar
abre detalhe → formulário → revisão → confirmação, com Integral padrão, Parcial,
data/forma efetiva, edição e recuperação de envio. Ver o
[guia do piloto real](PILOTO_PAGAR_REVISADO.md) para contratos, persistência,
compatibilidade, datas, testes e limites. Receber e tema global mantêm seus
incrementos próprios. É necessário atualizar servidor e cliente correspondentes;
não representa atualização automática do aplicativo instalado.

## Para que serve e interface

Em **Contas a Pagar**, cadastrar obrigações, pesquisar/filtrar, abrir detalhes e confirmar pagamentos. Informar beneficiário, descrição, categoria, natureza, valor e vencimento. Obrigações também podem nascer da confirmação de uma compra.

`BUSINESS` representa despesa da empresa. `PERSONAL_WITHDRAWAL` representa retirada pessoal. A classificação participa do resultado gerencial; não é apenas texto de apresentação.

## Regras do backend

`POST /payables` cria um ou mais títulos. Parcelamento divide o valor em centavos entre os títulos, distribui o resto e conserva o total. Quando não são fornecidas datas individuais, as parcelas usam intervalos de 30 dias.

`POST /payables/{id}/payments` registra pagamento parcial ou total, limitado ao saldo. O fluxo atual resolve a conta interna sem exigir uma conta com saldo selecionada pelo operador. Confirmar uma despesa comum não movimenta produtos ou cestas. A entrada de produtos pertence à [compra](COMPRAS.md).

## O que mexe no banco

| Ação | Persistência |
| --- | --- |
| Criar obrigação | Insere `accounts_payable`, com valor original, saldo, natureza, vencimento, parcelas e recorrência. |
| Pagar | Insere `payable_payments`, lança débito em `cash_flow_entries` e atualiza pago/saldo/status do título. |
| Estornar pagamento | Marca pagamento `REVERSED`, devolve saldo à obrigação e registra crédito inverso. |
| Cancelar título | Exige ausência de valores pagos; marca `CANCELED`, zera saldo e registra motivo nas notas. |
| Próxima recorrência | Cria novo título `OPEN`; não confirma pagamento. |

Os status usuais são `OPEN`, `PARTIAL`, `PAID` e `CANCELED`. O estorno de pagamento usa `/payables/payments/{id}/cancel`. O cancelamento de título usa `/payables/{id}/cancel`.

## Exemplo e limites

Obrigação de R$ 300,00: pagar R$ 100,00 deixa R$ 200,00 em aberto. Estornar esse pagamento volta a R$ 300,00. Uma retirada pessoal paga aparece separada das despesas operacionais no dashboard.

A recorrência usa ação explícita `/payables/{id}/next-recurrence`, não um agendamento automático pelo simples cadastro. Os intervalos atuais são semanal +7 dias, mensal +30 dias e anual +365 dias; não representam cálculo por mês do calendário.

Uma obrigação de compra pode ter vínculo `purchase_id`. Esse vínculo evita descontar novamente compras de estoque como outras despesas no cálculo gerencial. Não cancelar só o título esperando estornar a entrada de estoque: são operações diferentes.

## Onde conferir

- [Tela](../client/lib/views/payables_view.dart) e [serviço](../client/lib/services/payable_service.dart).
- [API](../backend/app/api/v1/payables.py), [serviço financeiro](../backend/app/services/financial.py), [modelos](../backend/app/models/financial.py).
- [Testes](../backend/tests/test_payables.py).
