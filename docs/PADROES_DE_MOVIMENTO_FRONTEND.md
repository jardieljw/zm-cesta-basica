# Movimento e animações do front-end

Revisão: **16/10/2026**. Situação: **movimento demonstrado aceito como referência; especificação em consolidação**.
Complementa o [manual de arquitetura](ARQUITETURA_FRONTEND.md). A implementação
da nova experiência no Flutter continua para o piloto alinhado separadamente.

## 1. Quando projetar e quando implementar

Movimento faz parte do planejamento atual. As prévias devem permitir avaliar
como campos aparecem, telas mudam e ações recebem resposta. Depois, o incremento
real implementará os comportamentos acordados com os componentes Flutter.
Assim, aprovação de uma tela estática não fecha automaticamente a interação.

O usuário perguntou em 16/10 se as animações seriam implementadas posteriormente.
O esclarecimento registrado é: algumas já existem nas amostras; o sistema
completo de movimento está sendo projetado agora e será integrado ao aplicativo
com as jornadas, por etapas. Não existe autorização para animar ou migrar todas
as telas de uma vez.

## 2. O que já existe e o que a nova amostra demonstra

**O que significa “Movimento compartilhado” no painel da base visual:** a mesma
escolha vale para Formulário, Estados dos controles e Lista e detalhe. Em
**Padrão**, há transições suaves, como revelar o valor parcial, mudar de tela e
abrir o calendário. Em **Reduzido**, as mudanças aparecem diretamente, reduzindo
movimentos opcionais; mensagens de processamento e resultados permanecem.
A preferência de redução do sistema prevalece mesmo ao selecionar Padrão.

Esse controle permite comparar a experiência durante o planejamento. Não é
uma configuração do app já aprovada. Em FE-030, o usuário perguntou seu
significado, sem escolher modo ou confirmar durações/curvas.

O cliente atual tem [AnimatedReveal](../client/lib/widgets/shared/animated_reveal.dart)
e [AnimatedContentSize](../client/lib/widgets/shared/animated_content_size.dart),
com duração de 220 ms, curva easeInOut e leitura de disableAnimations. São
candidatos à evolução/reutilização, não componentes descartados por este estudo.

A [rodada de Receber](RODADA_FRONTEND_RECEBER_2026-10-16.md) acrescenta à prévia
transições entre páginas e abertura do calendário, conservando a revelação do
parcial. O exemplo permanece funcional quando esses movimentos estão reduzidos.

| Interação | Objetivo | Amostra atual | Movimento reduzido |
| --- | --- | --- | --- |
| Resposta de botão/seleção | Tornar o toque ou a escolha perceptível. | Transições curtas herdadas, em torno de 160–180 ms. | Estado final direto, sem escala. |
| Integral → Parcial | Mostrar por que surgiu o campo de valor, sem salto brusco de altura. | Altura em 260 ms e opacidade em 180 ms; foco permanece na escolha, campo passa a participar do Tab. | Campo aparece diretamente, com os mesmos valores e regras. |
| Lista → detalhe → revisão → conclusão | Dar continuidade à mudança de contexto. | Translação vertical curta de 6 px e opacidade em 220 ms. Retorno usa direção inversa. | Troca direta, conservando navegação, dados e mensagens. |
| Abrir calendário | Relacionar o seletor ao campo acionado. | Entrada curta de 8 px e opacidade em 180 ms; o diálogo recebe foco. | Abertura direta, com foco e fechamento disponíveis. |
| Fechar calendário | Devolver a interação ao campo de data. | Fechamento direto nesta amostra; transição de saída ainda a avaliar. | Mesmo resultado e retorno de foco. |
| Registro em andamento | Comunicar que a ação está sendo processada. | Texto “Registrando…” e indicador durante a simulação. | Texto permanece, indicador sem giro. |
| Valor financeiro confirmado | Permitir leitura imediata do resultado. | Valor final atualizado diretamente; sem contagem animada de dinheiro. | Mesmo valor e momento de atualização. |
| Troca de tema/destaque | Preservar leitura durante a mudança de aparência. | Proposta FE-027 na base visual: texto e fundo mudam juntos, sem interpolar só a cor de fundo dos controles. | Mesmo par final, direto. |

Esses números e curvas são **propostas do assistente**, não medidas prescritas
pela Apple nem tokens globais aprovados. A duração de 220 ms dos auxiliares
existentes e a revelação de 260 ms da prévia são referências a harmonizar antes
da implementação compartilhada.

A [base visual](BASE_VISUAL_FRONTEND.md) registra por que medir apenas os pares
finais não bastava durante a troca de tema. A revisão dessa prévia remove a
interpolação isolada de fundo, preservando os demais movimentos com redução.
As cópias históricas e o Flutter não foram alterados por essa correção.

## 3. Regras propostas para a futura arquitetura

- Centralizar durações, curvas e política de redução, sem números espalhados
  em cada página. A composição do movimento depende da tarefa e da plataforma.
- A resposta à ação deve começar imediatamente. A animação não atrasa o envio,
  não cria uma confirmação extra e não deve bloquear a próxima interação útil.
- Uma interação nova interrompe/substitui o movimento anterior de forma coerente.
  Uma animação concluída não pode restaurar um estado antigo sobre o atual.
- O conteúdo oculto deixa a navegação por teclado e a leitura assistiva; ao
  revelar, não mover o foco para o campo sem uma razão de uso.
- Carregamento e resultado dependem da operação. A duração de uma animação não
  determina se o pagamento/recebimento foi registrado.
- Mensagens, valores e situações continuam compreensíveis sem movimento.
  Animação não é a única indicação de erro, sucesso ou seleção.
- Avaliar fluidez em aparelho real quando houver implementação. A duração de
  um efeito em uma prévia não comprova desempenho no Android, iPhone ou Windows.

## 4. Pesquisa e cuidado específico com Android/iPhone

Fontes primárias consultadas em **16/10/2026**:

1. [Apple HIG — Motion](https://developer.apple.com/design/human-interface-guidelines/motion?changes=l_9_3):
   orienta movimento com propósito, sem excesso, e informação compreensível
   também sem animações. A aplicação ao ZM é usar efeitos para revelar relações
   e respostas, com alternativa reduzida. O endereço base retornou somente a
   página que exige JavaScript; esta variante indexada forneceu o conteúdo.
2. [Flutter — Animations API overview](https://docs.flutter.dev/ui/animations/overview):
   descreve animações implícitas e controladas. A escolha proposta é aproveitar
   a base existente para mudanças locais e avaliar controles de rota por jornada.
3. [Flutter — MediaQueryData.disableAnimations](https://api.flutter.dev/flutter/widgets/MediaQueryData/disableAnimations.html):
   distingue a solicitação de remover animações no Android do sinal reduceMotion
   do iOS. Uma única leitura de disableAnimations não deve ser apresentada como
   cobertura comprovada das duas plataformas.

**Conferência local, sem alterar código:** o SDK instalado informa Flutter
**3.47.7**, revisão `abaf9c523780a608bd46686fd5e53740a07077f8`. Seu
`packages/flutter/lib/src/widgets/media_query.dart` conserva essa distinção e o
`bin/cache/pkg/sky_engine/lib/ui/window.dart` expõe reduceMotion. Os auxiliares
atuais do ZM consultam somente MediaQuery.disableAnimationsOf.

**Consequência de projeto:** antes da integração iOS, definir uma política
compartilhada que considere os sinais adequados, reaja a mudanças do sistema
e seja verificável por plataforma. Revalidar o SDK e as APIs no momento de
implementar. Esta leitura identifica uma lacuna de cobertura a tratar; não é
uma falha reproduzida no app iOS, cuja integração nativa ainda não existe.

Na amostra HTML, a redução combina prefers-reduced-motion com a opção de
comparação “Movimento → Reduzido”. Selecionar Padrão não sobrepõe a preferência
de redução do sistema. Essa opção do painel serve à avaliação, não é uma nova
tela de configurações já aprovada para o produto.

O retorno posterior à amostra foi “Perfeito.👍 :)” (FE-024). O movimento
demonstrado fica aceito como referência; tempos e curvas compartilhados serão
formalizados no catálogo, mantendo os limites de plataforma registrados acima.

## 5. O que falta fechar

**Retorno FE-031/FE-032, 16/10:** o usuário não percebeu animação na abertura.
Na inspeção local, a entrada anterior de 180 ms existia; não foi comprovada a
causa do comportamento no aparelho do usuário. Um estudo posterior testa entrada
de 240 ms, opacidade 0→1, deslocamento 12→0 e escala .98→1, com fundo escurecendo
em 180 ms. Redução local/sistema mantém abertura direta. Foi verificado em
Edge/WebKit no Windows; não comprova iPhone. O estudo está
[registrado e preservado](RODADA_FRONTEND_CALENDARIO_2026-10-16.md), **sem apresentação
ou aprovação**, pois o usuário pediu agrupar ajustes e evitar novas prévias a
cada mudança simples. As amostras anteriores e o Flutter permanecem preservados.

Generalizar os padrões a partir da referência aceita; saída de calendário,
transições de navegação mais amplas e comportamento de detalhes expansíveis.
No piloto, verificar toque rápido, interrupções, teclado, leitura assistiva,
redimensionamento e os sinais reais de acessibilidade. Manter mensagens de
operação independentes dos efeitos visuais.
