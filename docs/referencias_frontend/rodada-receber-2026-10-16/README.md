# Receber e movimento — 16/10/2026

[Registro completo](../../RODADA_FRONTEND_RECEBER_2026-10-16.md) e
[padrão de movimento em elaboração](../../PADROES_DE_MOVIMENTO_FRONTEND.md).
O usuário confirmou que os clientes geralmente quitam o saldo inteiro.

- [Fonte](receber-e-movimento-zm.html) e [contêiner](receber-e-movimento-zm-preview.html).
- [Script](check-receber-movimento.cjs), [relatório](receber-movimento-verificacao.json)
  e [manifesto SHA-256](manifesto.json).
- Edge: [lista](receber-edge-lista.png), [detalhe](receber-edge-detalhe.png),
  [integral](receber-edge-integral.png), [parcial](receber-edge-parcial.png),
  [conclusão](receber-edge-conclusao.png), [falha](receber-edge-falha.png),
  [Windows](receber-edge-windows.png).
- WebKit Windows: [lista](receber-webkit-lista.png), [detalhe](receber-webkit-detalhe.png),
  [integral](receber-webkit-integral.png), [parcial](receber-webkit-parcial.png),
  [conclusão](receber-webkit-conclusao.png), [falha](receber-webkit-falha.png),
  [Windows](receber-webkit-windows.png).

Dezoito cópias preservadas, sem sobrescrever as rodadas anteriores. O manifesto
não inclui este README. Para reexecutar, copiar fonte, contêiner e script para
outra pasta e apontar PREVIEW_DIR para ela; preservar relatório e capturas históricos.

Verificação final: sete grupos por motor, 32 combinações de layout e nenhum erro
JavaScript observado. Cobre saldo atual integral, parcial, venda de origem,
movimento padrão/reduzido, falha conhecida e restauração instrumentada.

São navegadores locais no Windows, sem homologação do app Flutter ou do aparelho.
O teste não mede taxa de quadros; usa simulação de painel/persistência e não
exerce gravação real, estorno ou retorno desconhecido de uma operação.
