# FE-055 — integração principal e Windows Release

Data: **17/10/2026**. [Guia e alcance](../../INTEGRACAO_INTERFACE_APROVADA.md).

Resultado técnico: **334 testes Flutter**, **436 testes backend / 14 avisos**,
análise sem pendências e build **Windows Release** concluído em 27,9 s.
O backend não foi alterado pela integração; o log preservado corresponde às
fontes atuais. Ver `verificacao.json` para comandos/logs, fontes e hashes do
executável e do código Dart AOT em `data/app.so`.

O aplicativo principal reúne Início, Financeiro, Negócio, Estoque e Mais com
serviços reais, contexto por área, jornadas financeiras revisadas e aparência
local configurável. As capturas daqui usam exclusivamente API simulada. Elas
não mostram dados da empresa, uma instalação externa atualizada ou teste em
Android/iPhone físicos. Não foram criados Site ou publicação.

`reference-receive.png` é a referência fornecida renderizada localmente, com
uma conta de Bruno, saldo de R$ 700,00, tema escuro e área interna de
418 × 815,578125. `reference-receive-matched-fixture.png` é o widget nativo nas
mesmas condições. JSONs de medidas permitem conferir os dez blocos medidos:
cabeçalho, contexto, aba, filtro, resumo, legenda, valor, período, contagem e
título da seção. Suas diferenças geométricas registradas ficaram abaixo de
um pixel; isso **não é certificação de identidade raster de todas as interfaces**.

As outras capturas verificam apresentação principal em claro/escuro, computador
e texto ampliado. As telas operacionais herdadas e a aceitação visual integral
continuam sujeitas à conferência correspondente. Não usar testes funcionais
como prova de equivalência visual global.

As referências/evidências anteriores continuam intactas: **35 arquivos FE-052,
8 FE-053 e 11 FE-054** conferidos pelos manifestos. O manifesto desta pasta não
inclui o README nem a si próprio. Esta preservação local não é um commit Git.

Executável atualizado:
`client/build/windows/x64/runner/Release/zm_cesta_basica_client.exe`.
Manter a pasta completa para executar. A compilação não altera o banco nem
substitui uma instalação externa automaticamente.
