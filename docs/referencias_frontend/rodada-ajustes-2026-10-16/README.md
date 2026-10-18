# Ajustes revisados — 16/10/2026

[Decisões, causa e limites](../../RODADA_FRONTEND_AJUSTES_2026-10-16.md).
FE-028 confirma espaço 20 e destaque configurável com azul original por padrão.
FE-029 corrige os controles da prévia; fundo e raios testados não foram aprovados.

- [Captura do usuário](espacamento-20-enviado.png).
- [Fonte revisada](fundamentos-visuais-revisados-zm.html),
  [contêiner](fundamentos-visuais-revisados-zm-preview.html) e
  [manifesto SHA-256](manifesto.json).
- [Teste do mecanismo original](check-ajustes-reais-zm.cjs) e
  [relatório de reprodução/correção](ajustes-reais-verificacao.json).
- [Regressão visual](check-fundamentos-revisados.cjs) e
  [relatório](fundamentos-revisados-verificacao.json).
- Mecanismo original: [Edge claro](ajustes-reais-edge-claro.png),
  [escuro](ajustes-reais-edge-escuro.png),
  [WebKit claro](ajustes-reais-webkit-claro.png),
  [escuro](ajustes-reais-webkit-escuro.png).
- Regressão Edge: [claro](fundamentos-revisados-edge-formulario-claro.png),
  [escuro](fundamentos-revisados-edge-formulario-escuro.png),
  [petróleo](fundamentos-revisados-edge-destaque-petroleo.png),
  [ametista](fundamentos-revisados-edge-destaque-ametista.png),
  [validação](fundamentos-revisados-edge-validacao.png),
  [pendente](fundamentos-revisados-edge-confirmacao-pendente.png),
  [ampla](fundamentos-revisados-edge-lista-ampla.png),
  [celular escuro](fundamentos-revisados-edge-lista-celular-escura.png).
- Regressão WebKit: [claro](fundamentos-revisados-webkit-formulario-claro.png),
  [escuro](fundamentos-revisados-webkit-formulario-escuro.png),
  [petróleo](fundamentos-revisados-webkit-destaque-petroleo.png),
  [ametista](fundamentos-revisados-webkit-destaque-ametista.png),
  [validação](fundamentos-revisados-webkit-validacao.png),
  [pendente](fundamentos-revisados-webkit-confirmacao-pendente.png),
  [ampla](fundamentos-revisados-webkit-lista-ampla.png),
  [celular escuro](fundamentos-revisados-webkit-lista-celular-escura.png).

**27 cópias preservadas**. O manifesto não inclui este README ou os documentos
vivos; registra também o hash da dependência `tweak.js` original, não copiada.
As oito rodadas/manifestos anteriores e suas 129 cópias permanecem preservados.

O mecanismo original reproduziu a falha na fonte anterior e passou para os sete
ajustes na revisão, em Edge/WebKit. O provedor de anotações é simulado; o painel
nativo da janela do usuário não foi automatizado. A regressão revisada passou
em cinco grupos por motor, 96 combinações de layout e 768 pares de contraste,
sem erros JavaScript observados. Configuração base: espaço 20, painéis 32,
campos 28 e texto 16; estresse usa espaço 32, raios 40/32 e texto 21 simulado.

Capturas do formulário e do mecanismo revisado foram inspecionadas. Cores de
experimento e raios mostrados nas capturas são cenários de teste, não decisões
finais. Não houve alteração Flutter/API, dados reais ou execução de suas suítes.
Testes web locais não homologam aparelho, UIKit, leitor de tela ou WCAG integral.

Para reexecutar, trabalhar em outra pasta e apontar PREVIEW_DIR para ela.
O teste do mecanismo também exige a fonte e o contêiner anteriores de
[base visual](../rodada-base-visual-2026-10-16/README.md), com os nomes originais,
e o helper original na versão/caminho descritos no script; TWEAK_HELPER_PATH pode
selecionar uma cópia compatível para revalidação. Rever runtimes e navegadores.
Não sobrescrever relatórios históricos; regenerar o contêiner após mudar fonte.
