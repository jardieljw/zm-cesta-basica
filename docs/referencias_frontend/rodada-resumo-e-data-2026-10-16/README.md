# Resumo financeiro e novo seletor de data — 16/10/2026

A [nova foto](data-cortada-iphone.jpg) confirma que a tentativa anterior deixou
o texto da data cortado no iPhone. Esta revisão troca o controle de exibição
por botão com calendário e concretiza o próximo recorte autorizado.
Consultar o [registro completo](../../RODADA_FRONTEND_RESUMO_E_DATA_2026-10-16.md).

- [Fonte da prévia](financeiro-origem-e-data-zm.html) e
  [contêiner de inspeção](financeiro-origem-e-data-zm-preview.html).
- [Verificação](check-financeiro-origem-data.cjs),
  [relatório](financeiro-origem-data-verificacao.json) e [manifesto](manifesto.json).
- Edge: [formulário](origem-data-edge-formulario.png),
  [calendário](origem-data-edge-calendario.png), [resumo](origem-data-edge-resumo.png),
  [origem](origem-data-edge-origem.png), [tabela](origem-data-edge-tabela.png),
  [vazio](origem-data-edge-vazio.png) e [indisponível](origem-data-edge-indisponivel.png).
- WebKit Windows: [formulário](origem-data-webkit-formulario.png),
  [calendário](origem-data-webkit-calendario.png), [resumo](origem-data-webkit-resumo.png),
  [origem](origem-data-webkit-origem.png), [tabela](origem-data-webkit-tabela.png),
  [vazio](origem-data-webkit-vazio.png) e [indisponível](origem-data-webkit-indisponivel.png).

São 19 cópias verificáveis, preservadas sem modificar arquivos das rodadas
anteriores. O manifesto não cobre este README. Para reexecutar, copiar fonte,
contêiner e script para outra pasta e apontar `PREVIEW_DIR` para ela; não substituir
este relatório ou estas capturas.

Resultado local: 64 combinações de geometria da data e oito grupos de fluxo
por motor, sem erros JavaScript observados. Inclui valor integral por padrão,
calendário com data ISO preservada e filtros coerentes com o resumo.

**Limites:** não é execução no iPhone nem implementação Flutter. O painel de
design e a persistência real do hospedeiro não foram automatizados; seus vínculos
foram instrumentados. A nova data ainda precisa de observação no aparelho. A
rolagem externa da conversa e resposta desconhecida ao gravar não foram verificadas.
