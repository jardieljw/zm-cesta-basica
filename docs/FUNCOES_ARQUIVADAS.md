# Funções arquivadas e histórico preservado

Revisão: **14/10/2026**. [Índice](README.md).

## O que significa arquivado

As telas e serviços exclusivos dos fluxos abaixo foram retirados da navegação ativa em 13/10/2026. Seus arquivos estão no [arquivo do cliente](../client/_archive/README.md). As APIs, tabelas e dados históricos continuam preservados. A retirada da tela não cancela operações antigas.

| Fluxo | Finalidade original | Backend e banco preservados |
| --- | --- | --- |
| Produção em lote | Consumir produtos e formar estoque de cestas antes da venda. | API `production`, serviço de produção, `production_batches`, `production_batch_items`, movimentos de montagem. |
| Desmontagem separada | Retornar produtos intactos e registrar perdas ao desmontar cestas. | Serviço de produção, movimentos `DISASSEMBLY_RETURN`, `DISASSEMBLY_DEPARTURE`, `ASSEMBLY_LOSS` e estado do lote. |
| Responsáveis e expedição | Transferir cestas de `STORE` para custódia `TRANSIT` e registrar retorno, perdas e conferência. | API/serviço `dispatches`, `responsible_persons`, `stock_dispatches`, `dispatch_items`, retornos, perdas, despesas, cobranças e acertos. |
| Tesouraria | Gerir contas, lançamentos manuais e transferências. | API `treasury`, serviço financeiro, `financial_accounts`, `cash_flow_entries`. |
| Relatórios exclusivos desses fluxos | Consultar montagem, expedição e tesouraria. | Rotas e consultas históricas preservadas; não são opções dos relatórios ativos. |

## O que continua funcionando

**Integração autorizada em 14/10/2026:** Tipos de Cesta agora oferece Montagens,
com registro padrão antecipado e histórico por tipo. São páginas novas que usam
o motor preservado; não restauram as telas antigas nem desmontagem, expedição ou
tesouraria. Ver [Montagens e histórico](MONTAGENS_E_HISTORICO.md).

Montar durante a venda continua ativo e usa o motor de produção. O novo cancelamento também usa o serviço de desmontagem internamente quando o operador informa que a montagem não aconteceu. Isso não restaura a tela de desmontagem separada.

Vendas, compras e pagamentos continuam utilizando registros financeiros internos. A ausência da tela de tesouraria não significa ausência de auditoria financeira. A venda atual do cliente usa balcão; o backend conserva regras de custódia para transações históricas e consumidores das APIs existentes.

## Exemplo e limites

Um lote montado antes do arquivamento pode conservar estoque e histórico. Não cadastrar outro lote fictício para representar novamente as mesmas cestas. Cestas prontas e produtos soltos exigem reconciliação com a situação física.

Os manuais antigos e a especificação original incluem essas funções. Não os usar como prova de que existe um menu correspondente na versão atual. Restaurar navegação ou mudar regras arquivadas exige uma alteração própria, com avaliação dos vínculos existentes.

## Onde conferir

- [Navegação atual](../client/lib/views/home_view.dart), [manifesto do arquivo](../client/_archive/manifest.json), [validação histórica](../client/_archive/VALIDATION.md).
- [Produção](../backend/app/services/production.py), [expedição](../backend/app/services/dispatches.py), [financeiro](../backend/app/services/financial.py).
- [Modelos de produção](../backend/app/models/production.py), [custódia](../backend/app/models/dispatches.py), [financeiro](../backend/app/models/financial.py).
