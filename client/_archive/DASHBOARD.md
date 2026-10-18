# Dashboard e pagamentos simplificados — 13/10/2026

O aplicativo ativo acompanha vendas, compras, estoque, fiados, contas a pagar e
suas confirmações. Ele não representa uma conta bancária ou um caixa físico.

## Indicadores ativos

- **Valor das vendas:** vendas confirmadas no período, inclusive as ainda a receber.
- **Custo das cestas vendidas:** custo histórico congelado nos itens vendidos.
- **Lucro bruto:** valor das vendas menos o custo das cestas vendidas.
- **Outras despesas pagas:** pagamentos do negócio que não são compras de estoque
  vinculadas nem retiradas pessoais.
- **Resultado gerencial:** lucro bruto menos essas outras despesas pagas no período.
  É uma medida gerencial; mistura vendas do período com despesas quando pagas.
- **Recebimentos confirmados:** eventos de venda à vista e quitação de fiados,
  descontando os estornos na data em que foram registrados.
- **Pagamentos confirmados:** eventos de pagamento de compras e obrigações,
  descontando os estornos na data em que foram registrados.
- **Diferença recebido menos pago:** comparação dos movimentos do período.
  Não é lucro, saldo bancário ou dinheiro disponível.
- **Pendências:** valores restantes de todas as contas atuais, com destaque para
  as vencidas e as que vencem no período selecionado.
- **Compras registradas:** quantidade e valor das compras confirmadas no período,
  pagas ou a prazo; não confundir com desembolso.

Uma cesta vendida por R$ 300 com custo de R$ 200 gera R$ 100 de lucro bruto.
Se houver R$ 30 de outras despesas pagas, o resultado gerencial é R$ 70.
A compra dos mesmos insumos não deve ser descontada mais uma vez do lucro bruto.
Para evitar essa duplicidade, registrar as compras no módulo de compras e pagar
os títulos vinculados que ele gera, sem criar outra obrigação para a mesma compra.

## O que foi arquivado nesta etapa

As classes antigas de dashboard estão em `models/dashboard_legacy.dart`.
O modelo de contas financeiras e o serviço de consulta de contas estão em
`models/financial_account.dart` e `services/financial_accounts_service.dart`.
Os testes anteriores continuam consultando os modelos arquivados como fixtures.

Os cartões de saldo atual/projetado, o detalhamento de livro-caixa e os seletores
de conta com saldo foram retirados dos arquivos ativos. Os trechos completos,
contexto e patches estão em `snapshots/2026-10-13-dashboard/` e em
`dashboard_manifest.json`. Para restaurar, usar os passos do README e revisar
os patches dos arquivos compartilhados. Não sobrescrever mudanças posteriores.
Os textos exclusivos retirados estão em `l10n/removed_dashboard_pt.arb`;
mesclar as chaves e seus metadados antes de regenerar as traduções ao restaurar.

## Banco de dados e compatibilidade

O dashboard é uma consulta: não grava indicadores ou cria depósitos. A nova
rota `/api/v1/dashboard/business-summary` não consulta saldos de contas,
produção em lote, pessoas responsáveis ou acertos de rota.

O histórico imutável de confirmações continua existindo internamente. Os vínculos
de conta existentes permanecem para compatibilidade e auditoria; o operador não
precisa selecionar uma conta. Novos pagamentos podem omitir `account_id`, usando
o vínculo interno padrão. Não foram excluídos dados, tabelas ou movimentos.

Depósitos manuais, transferências entre contas e repasses de rotas arquivadas não
entram nos novos indicadores. As APIs antigas permanecem compatíveis para leitura
histórica e futura restauração. O relatório financeiro ativo, PDF, CSV e XLSX
usam os mesmos cálculos do dashboard pela rota `business-financial-summary`.

## Datas e interpretação

O período do painel usa o calendário da empresa, UTC-03 (São Paulo).
Os eventos efetivos são armazenados em UTC e apresentados no horário local.
Vencimentos são datas de calendário: uma conta que vence hoje só fica vencida
no dia seguinte. As pendências totais são atuais, mesmo ao filtrar um mês antigo.

Vendas sem custo registrado recebem um aviso de resultado incompleto.
O aplicativo não pode inferir custos que nunca foram registrados.
