# Integral por padrão — 16/10/2026

Referência histórica da revisão pedida pelo usuário. Consultar o
[registro da rodada](../../RODADA_FRONTEND_INTEGRAL_2026-10-16.md).
O comportamento solicitado está demonstrado; a nova amostra visual aguarda avaliação.

- [Fonte da prévia](jornada-pagar-integral-zm.html) e [contêiner de inspeção](jornada-pagar-integral-zm-preview.html).
- [Script](check-pagamento-integral.cjs) e [relatório de verificação](pagamento-integral-verificacao.json).
- [Referência enviada pelo usuário](referencia-usuario.jpg), sem edição.
- Mobile: [integral inicial](integral-padrao-mobile.png), [parcial aberto](integral-formulario-mobile.png),
  [lista](integral-lista-mobile.png), [detalhe](integral-detalhe-mobile.png),
  [conferência](integral-conferencia-mobile.png), [histórico](integral-historico-mobile.png)
  e [falha](integral-falha-mobile.png).
- Desktop: [formulário](integral-formulario-desktop.png), [histórico](integral-historico-desktop.png)
  e [tema escuro](integral-historico-desktop-escuro.png).
- [Manifesto](manifesto.json): tamanho, origem e SHA-256 das 15 cópias.

Dados fictícios, sem API ou banco. A fonte é um fragmento para o ambiente de
visualização. O contêiner é um derivado para inspeção; recursos do hospedeiro
dependem do ambiente. O ícone Recomeçar reinicia apenas esta demonstração.

O script usa Node, Playwright e Edge. Aceita `PREVIEW_DIR` para a pasta de trabalho
e `PLAYWRIGHT_MODULE` para a instalação de Playwright. Sem essas variáveis, usa
a própria pasta e o runtime da máquina original. Como escreve capturas e relatório,
reexecutar em outra pasta com cópias dos HTML para preservar este histórico.

O cenário de falha anterior à gravação é local. O teste instala um substituto
controlado de `Tweak`; não valida o painel nativo do chat. Interações e capturas
da prévia não comprovam entrega ou validação nativa iOS.
