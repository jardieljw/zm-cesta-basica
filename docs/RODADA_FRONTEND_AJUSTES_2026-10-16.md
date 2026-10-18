# Espaçamento confirmado e correção dos ajustes

Revisão: **16/10/2026**, FE-028/FE-029. Continuação da
[base visual](BASE_VISUAL_FRONTEND.md), somente em planejamento/prévia.

## Decisões do usuário

- **20 entre grupos de campos**, conforme captura enviada. Na prévia são CSS px;
  preservar a intenção em unidades lógicas e validar texto/plataforma no Flutter.
- **Destaque escolhível nas configurações do app**, com azul original **#2866ae**
  por padrão. A configuração real continua para implementação futura. Persistência
  por dispositivo/perfil e organização da tela ainda serão definidas.
- Fundo, modo e raios movidos para testar **não são escolhas finais**. O usuário
  relatou que outros controles não mudavam a tela. Não promover estado do painel
  a aprovação desses valores.

Os [valores estruturados](TOKENS_VISUAIS_PROPOSTOS.json) passam a ter confirmação
parcial. Alerta, erro e sucesso conservam significado próprio e mensagens. Derivar
tonalidades do destaque para legibilidade continua como proposta técnica.

## Defeito e correção

A primeira verificação simulava a classe de ajustes e chamava sua resposta
diretamente. Isso não cobria o mecanismo original de entrega de eventos; o
relato do usuário mostrou essa lacuna.

Na reprodução local com o `tweak.js` original do pacote visualize **1.0.50**, um
evento entregou a edição e um `widgetState` anterior. O helper aplicou/publicou
a escolha, mas a restauração reaplicou o estado antigo logo depois. O painel
pediu cantos 24/20 e espaço 28; a tela voltou a 32/28/24. Publicação da escolha
não comprova aplicação visual. O teste não automatiza o painel da janela do usuário.

A revisão:

1. Compara snapshots estruturalmente, independentemente da ordem das chaves,
   e reconhece ecos já escritos/restaurados. O histórico é limitado a 128
   assinaturas, preservando a inicial.
2. Ignora esses ecos para não desfazer uma interação recente; conserva estado
   externo genuinamente novo e a identidade dos objetos ligados aos controles.
3. Registra os controles após a restauração inicial, com os valores efetivos.
4. Aplica parâmetros nas raízes dos componentes depois de reconstruir o conteúdo.
   No WebKit local, a restauração expôs variáveis novas no contêiner com medidas
   antigas em descendentes. A revisão verifica a medida efetiva; isso não é uma
   atribuição de causa geral a todos os WebKits/iPhones.
5. Usa nova fonte/versão de estado, com espaço 20 e azul original. Não altera
   os artefatos históricos nem o cliente Flutter.

Essa proteção é da demonstração, não uma solução de concorrência financeira
ou um novo gerenciador de estado do aplicativo.

## Evidência e próximo passo

A [pasta da rodada](referencias_frontend/rodada-ajustes-2026-10-16/README.md)
conserva captura do usuário, fontes, scripts, relatórios e imagens. O teste
reproduz o defeito na fonte anterior e confere os sete ajustes na revisão em
Edge/WebKit, com helper original e provedor de anotações simulado. Inclui eco
antigo, chaves reordenadas, estado externo novo, arraste após restauração e
calendário/foco mantidos.

Também passaram cinco grupos por motor, 96 combinações de layout e 768 pares de
contraste, sem erros JavaScript observados na regressão revisada. São testes
locais, sem homologação do painel nativo, Flutter ou aparelhos iOS/Android.

Próximo recorte: avaliar fundo/cantos depois da correção e então tipografia.
Espaço e requisito de personalização de cor não precisam ser perguntados outra
vez. O piloto e a configuração real mantêm seu alinhamento próprio.
