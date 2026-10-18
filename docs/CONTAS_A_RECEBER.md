# Fiado, recebimentos e estornos

**Entrada FE-055:** Financeiro → Receber apresenta os recortes atuais. Abrir uma
conta segue para detalhe/histórico, venda de origem e recebimento revisado.
**Filtrar → Histórico e cadastros** conserva pesquisa ampliada, títulos quitados
e as operações de histórico/estorno existentes. A integração não altera a venda
ou o estoque ao registrar recebimento.

**Continuação FE-054 — 17/10/2026:** o [recebimento revisado](PILOTO_RECEBER_REVISADO.md)
substitui o diálogo antigo por detalhe/formulário/revisão/confirmação e retomada
persistida. Lista com filtros recolhidos, Em aberto incluindo parciais, mais
páginas e consulta da venda de origem. O guia abaixo conserva as regras de
domínio, inclusive histórico e estorno. Servidor/cliente correspondentes são
necessários; instalação e banco da empresa não foram substituídos.

Revisão: **14/10/2026**. [Índice](README.md).

## Para que serve e interface

Em **Contas a Receber**, consultar títulos por cliente, status, vencimento e demais filtros disponíveis. Abrir o detalhe para confirmar recebimento parcial ou total e consultar/estornar pagamentos. O título nasce na venda fiada, não na simples criação do cliente.

## Regras do backend

Uma venda `CREDIT_TERM` exige cliente ativo e cria um título em `sales_receivables`, inicialmente `OPEN`, com valor original, saldo e vencimento. Se não vier vencimento, o backend utiliza a data da venda mais 30 dias. O fluxo atual cria um título por venda; vários recebimentos parciais não significam vários títulos parcelados.

`POST /receivables/{id}/payments` valida título e valor. Um recebimento não pode ultrapassar o saldo pendente. O backend resolve a conta financeira interna, sem seleção de conta pelo operador no fluxo atual de balcão. Receber não movimenta estoque novamente.

## O que mexe no banco

| Tabela | Efeito |
| --- | --- |
| `receivable_payments` | Registra valor, meio, data e status `CONFIRMED` do recebimento. |
| `sales_receivables` | Aumenta `paid_amount_cents`, reduz `balance_cents`; fica `PARTIAL` ou `PAID`. |
| `sales` | Sincroniza `payment_status` com o pagamento do título. |
| `cash_flow_entries` | Crédito de recebimento e débito reverso no estorno, conforme a origem do pagamento. |

`POST /receivables/payments/{id}/cancel` preserva o pagamento, marca `REVERSED`, registra motivo e devolve o valor ao saldo devedor. A venda continua existindo. Para cancelar uma venda fiada que já recebeu pagamentos, é necessário estornar esses pagamentos antes; ver [Cancelamento de vendas](CANCELAMENTO_DE_VENDAS_E_MONTAGEM.md).

## Exemplo e limites

Venda fiada de R$ 150,00: título em aberto de R$ 150,00. Receber R$ 50,00 deixa R$ 100,00 e status parcial. Receber os R$ 100,00 restantes quita. Estornar o primeiro recebimento reabre R$ 50,00.

O backend conserva vínculos de recebimentos de rota para histórico, mas a tela ativa não exige saída ou responsável. O valor vendido já aparece como venda na confirmação; o recebimento posterior entra como confirmação financeira, sem criar outra venda.

## Onde conferir

- [Tela](../client/lib/views/receivables_view.dart) e [serviço](../client/lib/services/receivable_service.dart).
- [API](../backend/app/api/v1/receivables.py), [serviço](../backend/app/services/receivables.py), [venda fiada](../backend/app/services/sales.py), [modelos](../backend/app/models/sales.py).
- [Testes](../backend/tests/test_receivables.py).
