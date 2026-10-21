# Evidência E1 — 19/10/2026

[Guia funcional e contrato](../../IMPORTACAO_FATURAS_E1.md).
[Registro completo de retomada/testes](../../RETOMADA_IMPORTACAO_FATURAS.md).

- Baseline: 488 backend / 367 Flutter.
- Final: 512 backend / 373 Flutter; análise estática sem pendências.
- [Amostras afetadas](amostras-sanitizadas.json): hashes/linhas/parcelas/diferenças,
  com referências privadas, sem dados pessoais ou descrições financeiras.
- [HTTPS isolado](https-sanitizado.json): worker PDF real, contrato versionado,
  reenvio reutilizado, integridade e livros inalterados, zero títulos.
- [Conflito de vencimentos](vencimentos-sinteticos.png): renderização Flutter com
  dados inteiramente fictícios; duas datas/páginas e confirmação bloqueada.

E1 implementada; E2–E5 pendentes. Sem build, ativação, nova migração ou teste no
banco da empresa. Os scripts privados ficam ignorados em `tmp/`; não publicar
originais, manifestos e transcrições. A captura não certifica o seletor nativo
Windows ou dispositivos físicos.
