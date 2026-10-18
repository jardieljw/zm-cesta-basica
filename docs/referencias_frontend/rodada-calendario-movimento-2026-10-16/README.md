# Estudo local do calendário — 16/10/2026

**Não apresentado nem aprovado.** O usuário dispensou a prévia quando a geração
e os testes já haviam terminado; pediu agrupar ajustes simples (FE-032).
Ver [contexto, resultados e limites](../../RODADA_FRONTEND_CALENDARIO_2026-10-16.md).

- [Fonte do estudo](calendario-movimento-zm.html) e [contêiner de teste](calendario-movimento-zm-preview.html).
- [Script](check-calendar-motion-zm.cjs), [observação da fonte anterior](calendar-motion-before.json)
  e [verificação do estudo](calendar-motion-verification.json).
- Edge: [intermediário](calendar-edge-intermediate.png) e [final](calendar-edge-complete.png).
- WebKit: [intermediário](calendar-webkit-intermediate.png) e [final](calendar-webkit-complete.png).
- [Manifesto de origem, tamanho e SHA-256](manifesto.json).

Nove cópias preservadas. O manifesto exclui este README e documentos vivos.
As capturas intermediárias pausam o movimento em 80 ms para inspeção;
o relatório também registra amostragem por quadros durante a execução normal.
Testes locais não homologam aparelhos ou controles nativos do aplicativo.

Para reexecutar futuramente, usar outra pasta e PREVIEW_DIR. O modo `--probe`
precisa da fonte e do contêiner `fundamentos-visuais-revisados-zm` da
[rodada anterior](../rodada-ajustes-2026-10-16/README.md). O teste principal usa
o helper original `tweak.js` 1.0.50, no caminho indicado pelo script ou por
TWEAK_HELPER_PATH. Rever runtimes, navegadores e caminhos; não sobrescrever
evidências históricas. Não reexecutar agora só para apresentar o estudo.
