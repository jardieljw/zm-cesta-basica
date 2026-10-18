# Base visual — 16/10/2026

FE-027: alinhamento de cores, formas e espaço, retomado após interrupção.
[Especificação/pesquisa](../../BASE_VISUAL_FRONTEND.md) e
[valores propostos](../../TOKENS_VISUAIS_PROPOSTOS.json). A amostra desta rodada
aguarda retorno; o catálogo anterior continua aceito como referência.

- [Fonte](fundamentos-visuais-zm.html), [contêiner de inspeção](fundamentos-visuais-zm-preview.html)
  e [manifesto SHA-256](manifesto.json).
- [Script](check-fundamentos-visuais.cjs) e
  [relatório final](fundamentos-visuais-verificacao.json).
- Edge: [formulário claro](fundamentos-edge-formulario-claro.png),
  [escuro](fundamentos-edge-formulario-escuro.png),
  [destaque petróleo](fundamentos-edge-destaque-petroleo.png),
  [ametista](fundamentos-edge-destaque-ametista.png),
  [validação](fundamentos-edge-validacao.png),
  [confirmação pendente](fundamentos-edge-confirmacao-pendente.png),
  [lista ampla](fundamentos-edge-lista-ampla.png),
  [lista no celular escuro](fundamentos-edge-lista-celular-escura.png).
- WebKit Windows: [formulário claro](fundamentos-webkit-formulario-claro.png),
  [escuro](fundamentos-webkit-formulario-escuro.png),
  [destaque petróleo](fundamentos-webkit-destaque-petroleo.png),
  [ametista](fundamentos-webkit-destaque-ametista.png),
  [validação](fundamentos-webkit-validacao.png),
  [confirmação pendente](fundamentos-webkit-confirmacao-pendente.png),
  [lista ampla](fundamentos-webkit-lista-ampla.png),
  [lista no celular escuro](fundamentos-webkit-lista-celular-escura.png).

**20 cópias preservadas**, sem alterar as 109 cópias das sete rodadas/manifestos
anteriores. O manifesto não inclui este README nem os documentos vivos do projeto.
Preservar esta versão para comparação; criar outra rodada para alterações futuras.

## Verificação e limites

Resultado final: **cinco grupos por motor, 96 combinações de layout, 768 pares
de contraste e nenhum erro JavaScript observado**, em Edge/WebKit locais no
Windows. A revisão final é posterior à correção da interpolação de cor.

Os pares cobrem seis cores de origem, dois fundos e dois temas, com 16 verificações
por combinação/motor. Incluem texto/placeholder/avisos, contorno de campo e cores
efetivas do botão, data e escolha selecionada após mudar a aparência. Não é uma
auditoria de todos os estados, focus rings, interfaces nativas ou WCAG integral.

O layout cobre três famílias, larguras externas 320/360/390/780, dois temas e
duas configurações de espaço/curvas/texto. A configuração ampliada usa texto 21
nos controles, espaço 32, painéis 40 e campos 32; a base usa texto 16/espaço 24/
painéis 32/campos 28. É estresse simulado, sem equivalência a Dynamic Type.

Também confere medidas CSS reais após ajuste, objeto estável após restauração,
ausência de gravação no carregamento/restauração, redução pelo sistema/painel,
rascunho conservado e calendário aberto/foco preservados ao trocar tema/cor/espaço.
Capturas do formulário, temas e lista foram inspecionadas após a revisão final.

São exemplos independentes, fictícios e locais. Não exercem API, cache,
recuperação financeira, leitor de tela, fluidez do Flutter ou aparelho Android/iOS.
Tweak e persistência foram instrumentados; painel nativo e restauração real do
hospedeiro não foram automatizados. Não houve alteração do cliente/servidor ou
execução de suas suítes nesta rodada de apresentação e documentação.

Para reexecutar, copiar os quatro arquivos de fonte/contêiner/script/relatório
para outra pasta e apontar PREVIEW_DIR para ela. Rever caminhos locais do runtime
e navegadores. Regenerar o contêiner após editar a fonte; preservar os resultados
históricos em vez de sobrescrevê-los.
