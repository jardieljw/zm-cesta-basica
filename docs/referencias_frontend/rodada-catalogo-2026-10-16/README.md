# Catálogo mínimo de componentes — 16/10/2026

[Especificação e pesquisa](../../CATALOGO_COMPONENTES_FRONTEND.md).
FE-025 autoriza continuar o planejamento. O retorno posterior “Tá ótimo” (FE-026)
destacou elegância, aparência agradável e arquitetura inteligente: direção e
apresentação do catálogo aceitas como referência. Medidas e contratos técnicos
mantêm seu alinhamento próprio; Pagar e Receber continuam sendo a base das jornadas.

- [Fonte](catalogo-componentes-zm.html), [contêiner de inspeção](catalogo-componentes-zm-preview.html)
  e [manifesto SHA-256](manifesto.json).
- [Script de verificação](check-catalogo-componentes.cjs) e
  [relatório final](catalogo-componentes-verificacao.json).
- Edge: [integral](catalogo-edge-integral.png), [parcial](catalogo-edge-parcial.png),
  [erros](catalogo-edge-erros.png), [escuro](catalogo-edge-escuro.png),
  [sucesso](catalogo-edge-sucesso.png), [recusa](catalogo-edge-recusa.png),
  [confirmação pendente](catalogo-edge-sem-confirmacao.png),
  [indisponível](catalogo-edge-indisponivel.png),
  [consulta anterior](catalogo-edge-ultima-consulta.png), [tabela](catalogo-edge-tabela.png).
- WebKit Windows: [integral](catalogo-webkit-integral.png),
  [parcial](catalogo-webkit-parcial.png), [erros](catalogo-webkit-erros.png),
  [sucesso](catalogo-webkit-sucesso.png), [recusa](catalogo-webkit-recusa.png),
  [confirmação pendente](catalogo-webkit-sem-confirmacao.png),
  [indisponível](catalogo-webkit-indisponivel.png),
  [consulta anterior](catalogo-webkit-ultima-consulta.png), [tabela](catalogo-webkit-tabela.png).

**23 cópias preservadas**. O manifesto não inclui este README nem os documentos
vivos do projeto. Não sobrescrever esta rodada para novos estudos. Os seis
manifestos anteriores e suas 86 cópias permanecem históricos.

## Verificação e limites

O relatório final passou em Edge e WebKit locais no Windows: **oito grupos por
motor, 96 combinações de família/largura/tema/texto e nenhum erro JavaScript
observado**. Os tamanhos de texto de 16/21 foram aplicados aos controles como
estresse; não equivalem à escala de texto nativa nem a Dynamic Type do iOS.
As larguras externas foram 320/360/390/780; o contêiner usa parte desse espaço.

Cobre integral/parcial e valor oculto, erros/foco, calendário/teclado, códigos de
formas por módulo, proteção de acionamento enquanto ocupado, resultados simulados,
coerência resumo/lista e os estados de consulta, redução e vínculo de ajustes
após restauração instrumentada. No cenário vazio, ampliar o recorte mostra Carla
R$ 80,00 em 21/10; não reapresenta contas da própria semana como se estivessem fora.

As capturas foram inspecionadas quanto ao formulário, mensagens, tabela e temas.
A captura escura adicional foi feita no mesmo contêiner Edge, com o navegador
em aparência escura; não acrescenta uma matriz de testes ao relatório.
Durante o ajuste, a reserva de altura dos exemplos gerou aviso de ResizeObserver.
A atualização passou para o próximo quadro e tornou-se condicional; a verificação
final posterior não registrou esse aviso. O relatório preservado é o final.

**Não comprova** Flutter, UIKit, aparelhos Android/iPhone, leitor de tela, taxa
de quadros, API, cache ou recuperação real após queda de rede. Tweak e persistência
foram instrumentados no teste; painel nativo e restauração real do hospedeiro não
foram automatizados. Os três exemplos usam dados fictícios independentes.

Para reexecutar, copiar os quatro arquivos de fonte/contêiner/script/relatório
para outra pasta e apontar PREVIEW_DIR para ela, preservando estas evidências.
Revisar caminhos locais de Node, Playwright e navegadores. Se editar a fonte,
regenerar seu contêiner antes de testar. Suítes do aplicativo não foram executadas
nesta rodada de documentação e prévia, sem alteração funcional do cliente/servidor.

Conferência documental final desta rodada: 176 referências locais válidas nos
oito documentos consultados; sete manifestos e 109 cópias com tamanho/SHA-256
conferidos, também iguais às origens disponíveis. Essas contagens descrevem a
revisão de 16/10/2026, não um certificado permanente para futuras alterações.
