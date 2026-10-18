# Referências preservadas do planejamento de front-end

**Continuação vigente FE-052:** [acabamento integrado e filtros compactos](rodada-acabamento-2026-10-16/README.md).
Derivação de FE-049 com vidro/cores da referência inicial, contas como extrato e
filtros recolhidos. Leitura recuperada, organização e navegação conservadas.
O [registro canônico](../REFERENCIA_ATUAL_FRONTEND.json) aponta a nova fonte;
FE-049 permanece preservada como base acolhida e origem desta revisão.

**Base acolhida FE-049:** [organização com a leitura escolhida](rodada-organizacao-2026-10-16/README.md).
Usuário escolheu Leitura recuperada e o nome Negócio para vendas/clientes/resultado.
Home curta com períodos; atenção atual preservada. O
[registro canônico](../REFERENCIA_ATUAL_FRONTEND.json) aponta para a fonte atual.
FE-048 abaixo conserva a comparação histórica, não uma escolha ainda pendente.

Arquivo histórico consolidado em **15/10/2026**. As cópias são idênticas aos
originais da conversa; o [manifesto](manifesto.json) registra origem, tamanho
e SHA-256. Não são código integrado ao aplicativo, nem uma especificação de
todos os comportamentos futuros.

Decisões vigentes: [manual](../ARQUITETURA_FRONTEND.md).
Contexto, motivos e evidências: [memória e pesquisas](../MEMORIA_E_PESQUISAS_FRONTEND.md).

**Referência de continuação FE-048:** [tipografia e hierarquia integradas](rodada-tipografia-2026-10-16/README.md),
derivadas da recuperação FE-046. O [apontador canônico](../REFERENCIA_ATUAL_FRONTEND.json)
identifica a fonte candidata, origem e evidências. Não escolher um estudo parcial
por recência. A recuperação já foi apresentada; novas medidas de leitura ainda
estão em avaliação. Os relatos de auditoria abaixo descrevem o estado histórico.

**Auditoria FE-045, 16/10/2026:** [resultado e matriz de acordos](../AUDITORIA_CONTINUIDADE_FRONTEND_2026-10-16.md).
As 179 cópias de 11 manifestos conferem com os registros locais. Duas cópias
adicionais da primeira comparação, antes só na conversa, foram recuperadas em
[fontes recuperadas](auditoria-continuidade-2026-10-16/fontes-recuperadas/).
Preservação dos arquivos não garantiu continuidade visual da amostra recente;
barra e destinos ainda precisam ser recuperados. Pasta histórica não versionada
no Git nesta inspeção. Consultar limites e evidências na auditoria.

## Artefatos

| Arquivo | Uso e situação |
| --- | --- |
| [Briefing inicial](briefing-inicial.txt) | Transcrição original anexada pelo usuário. Preservar inclusive ambiguidades; interpretar junto às decisões posteriores. |
| [Direções visuais ajustáveis](direcoes-design-zm-ajustavel.html) | Fragmento da comparação Camadas suaves/Vidro, com correção dos ajustes, fundo e destaque independentes e transparência/desfoque. Referência aceita; tokens finais em discussão. |
| [Contêiner de teste das direções](direcoes-design-zm-ajustavel-preview.html) | HTML gerado para inspeção em navegador; artefato derivado, preservado sem edição. |
| [Mapa navegável](mapa-navegavel-zm.html) | Fragmento com cinco destinos, composições celular/computador e páginas conectadas. Organização e direção visual aceitas como base. |
| [Contêiner de teste do mapa](mapa-navegavel-zm-preview.html) | HTML gerado para inspeção em navegador; artefato derivado, preservado sem edição. |
| [Celular](navigation-mobile.png), [computador](navigation-desktop.png) e [composição compacta escura](navigation-dark-mobile.png) | Capturas da inspeção da demonstração. Dados fictícios, sem comprovação de integração nativa. |
| [Vidro no celular](controls-glass-mobile.png) | Captura da direção revisada; comparar com os controles da prévia, sem tratar a imagem como especificação dos tokens. |
| [Verificação do mapa](check-navigation-preview.cjs) | Script histórico de navegação, preservação de contexto e largura. |
| [Verificação dos controles](check-design-controls.cjs) | Script histórico de vínculo dos ajustes, restauração e CSS calculado; usa simulação controlada dos ajustes. |

## Como usar sem depender da conversa

As imagens permitem consultar a aparência diretamente. Os arquivos sem sufixo
`-preview` são fragmentos para o ambiente de visualização; os arquivos com esse
sufixo são seus contêineres de inspeção. Recursos do hospedeiro, como ajustes e
persistência, dependem desse ambiente. A ausência desse painel em um navegador
comum não significa que ele faça parte da interface planejada do aplicativo.

Os scripts foram copiados sem adaptação: contêm caminhos da máquina original
para Node/Playwright, Edge e a pasta de visualizações. Antes de reexecutar,
revisar esses caminhos e apontar a leitura para as cópias desejadas. Consultar
os limites da evidência na memória; resultado passado não certifica uma revisão nova.

Não editar estas cópias históricas para uma nova rodada. Criar uma versão
identificada, atualizar os registros de decisão e guardar a nova evidência.
O manifesto cobre as 11 cópias originais, não este README nem futuras revisões.

## Rodadas seguintes

- [Recuperação integrada — 16/10/2026](rodada-recuperacao-integrada-2026-10-16/README.md):
  FE-046 reutiliza o mapa original, conserva barra/destinos e incorpora os avanços
  de formulários e jornadas. Verificada localmente; revisão do usuário pendente.
  Consultar o [registro da referência atual](../REFERENCIA_ATUAL_FRONTEND.json)
  antes da continuação; Negócio em foco permanece um estudo parcial histórico.
- [Negócio em foco — 16/10/2026](rodada-negocio-em-foco-2026-10-16/README.md):
  FE-041 apresenta as três informações úteis e seus destinos, ligadas à jornada
  financeira em celular/Windows. Dados fictícios; nova composição em avaliação.
- [Estudo local do calendário — 16/10/2026](rodada-calendario-movimento-2026-10-16/README.md):
  entrada mais perceptível testada localmente; não apresentada nem aprovada.
  Usuário pediu agrupar ajustes simples e dispensou a prévia desta rodada.
- [Ajustes revisados — 16/10/2026](rodada-ajustes-2026-10-16/README.md):
  espaço 20 e personalização do destaque confirmados; colisão de edição/estado
  antigo reproduzida e corrigida. Nova fonte verificada com o helper original.
- [Base visual — 16/10/2026](rodada-base-visual-2026-10-16/README.md):
  papéis de cor, aparência clara/escura, formas e espaço compartilhados nos três
  exemplos. Proposta para avaliação; não é tema implementado no Flutter.
- [Catálogo mínimo — 16/10/2026](rodada-catalogo-2026-10-16/README.md):
  campos/escolhas, ações/respostas e resumo/lista, com contratos e estados.
  Direção/apresentação aceitas como referência em FE-026; consultas e recuperação
  de confirmação simuladas, com contratos técnicos ainda por formalizar.
- [Receber e movimento — 16/10/2026](rodada-receber-2026-10-16/README.md):
  integral do saldo atual confirmado para fiado, origem na venda, parcial opcional
  e transições com redução. Demonstração aceita como referência; 18 cópias preservadas.
- [Resumo e nova data — 16/10/2026](rodada-resumo-e-data-2026-10-16/README.md):
  foto confirmou texto da data ainda defeituoso na tentativa anterior. Nova
  amostra com calendário e resumo/lista/origem; 19 cópias preservadas. Verificada
  localmente e aceita como referência pelo usuário. Integração e homologação do
  app no aparelho permanecem etapas próprias.
- [Correção da data — 16/10/2026](correcao-data-2026-10-16/README.md): campo alinhado
  ao painel e aos vizinhos; tentativa superada pela rodada acima após retorno do
  iPhone. Preservar como evidência histórica, não usar como correção definitiva.
- [Integral por padrão — 16/10/2026](rodada-integral-2026-10-16/README.md): seleção
  integral/parcial, expansão suave e controles mais arredondados. Retorno do usuário
  registrado; acabamento da nova amostra em avaliação.
- [Jornada Pagar — 15/10/2026](rodada-pagar-2026-10-15/README.md): registro parcial,
  conferência, conclusão e histórico, com novas evidências e manifesto próprio.
  Prévia pronta; avaliação do usuário pendente.
