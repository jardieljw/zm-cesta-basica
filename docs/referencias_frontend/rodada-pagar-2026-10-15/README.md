# Prévia da jornada Pagar — 15/10/2026

Situação: **demonstração verificada, aguardando retorno do usuário**.
Consultar o [registro da rodada](../../RODADA_FRONTEND_PAGAR_2026-10-15.md)
para contexto, contratos, pesquisa, evidências e decisões ainda abertas.

- [Fonte editável da prévia](jornada-pagar-zm.html).
- [Contêiner de inspeção](jornada-pagar-zm-preview.html), derivado da fonte.
- [Script de verificação](check-jornada-pagar.cjs) e [relatório](jornada-pagar-verificacao.json).
- Capturas mobile: [lista](pagar-lista-mobile.png), [detalhe](pagar-detalhe-mobile.png),
  [formulário](pagar-formulario-mobile.png), [conferência](pagar-conferencia-mobile.png),
  [histórico parcial](pagar-historico-mobile.png) e [falha antes de gravar](pagar-falha-mobile.png).
- Capturas desktop: [formulário](pagar-formulario-desktop.png),
  [histórico](pagar-historico-desktop.png) e [tema escuro](pagar-historico-desktop-escuro.png).
- [Manifesto](manifesto.json): origem, tamanho e SHA-256 das 13 cópias da rodada.

Dados fictícios, sem API ou banco. O HTML sem sufixo `-preview` é um fragmento
para o ambiente de visualização. O contêiner permite inspeção separada; ajustes
do hospedeiro dependem do ambiente. As capturas permitem consulta direta.

O script usa Node, Playwright e Edge. `PREVIEW_DIR` pode apontar para esta pasta
e `PLAYWRIGHT_MODULE` para a instalação disponível de Playwright. Sem essas
variáveis, usa a própria pasta e o caminho do runtime da máquina original.
O script escreve o relatório e as imagens no diretório escolhido: para preservar
esta cópia histórica, reexecutar em outra pasta de trabalho com cópias dos HTML.

O ajuste “Próxima confirmação” da demonstração permite explorar uma falha na
primeira tentativa. A confirmação seguinte conclui o registro; é um cenário
local de apresentação. O painel nativo do chat não foi automatizado: o teste
verifica o vínculo por um substituto controlado. O ícone Recomeçar reinicia
somente os dados fictícios daquela composição.
