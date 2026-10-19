# Padronização do frontend ZM para trabalho confiável com IA

## Diagnóstico: o problema não é falta de documentação; é falta de um contrato executável

Depois de cruzar a documentação do ZIP com as práticas atuais de design systems, Flutter, testes visuais, especificações de design tokens e configuração de agentes de IA, a conclusão é direta:

**vocês documentaram o design, mas ainda não transformaram esse design em uma linguagem obrigatória que o agente seja incapaz de contornar.**

Esse é o ponto central.

No material enviado, existe muito mais definição de frontend do que parecia à primeira vista. Há decisões explícitas sobre navegação, hierarquia, tipografia, raios, espaçamento, formulários, Pagar/Receber, filtros, estados, responsividade, acabamento, comportamento e responsabilidades dos componentes. O próprio `CATALOGO_COMPONENTES_FRONTEND.md` já chega à percepção correta de que “uma coleção de imagens” não basta e especifica dez famílias de componentes com entradas, comportamentos e responsabilidades. O problema não é ausência de pensamento de design. Fontes internas: `ARQUITETURA_FRONTEND.md`, `CATALOGO_COMPONENTES_FRONTEND.md`, `BASE_VISUAL_FRONTEND.md`, `COMPOSICAO_DAS_PAGINAS_FRONTEND.md`, `HIERARQUIA_E_TIPOGRAFIA_FRONTEND.md`.

O problema é que **a autoridade de design está distribuída entre documentos históricos, decisões, protótipos HTML/CSS, JSON de planejamento, instruções de agentes e posteriores notas de implementação**. Em vários pontos, o próprio material distingue “confirmado”, “proposto”, “demonstrado”, “implementado”, “a validar no Flutter” e “não certificado”. Por exemplo, `TOKENS_VISUAIS_PROPOSTOS.json` declara literalmente seu status como `partially_confirmed` e diz que o arquivo é dado de planejamento, “not a runtime theme”; `CATALOGO_COMPONENTES_FRONTEND.md` diz que a forma final de expor os tokens no Flutter ainda estava por escolher; e `ARQUITETURA_FRONTEND.md` diz explicitamente que o catálogo não era ainda uma biblioteca Flutter. Fontes internas: `TOKENS_VISUAIS_PROPOSTOS.json`, `CATALOGO_COMPONENTES_FRONTEND.md`, `ARQUITETURA_FRONTEND.md`.

Isso é fatal para o caso de uso que você quer: “IA, faça uma nova página e siga o padrão”. **A IA ainda precisa interpretar o padrão e reconstruí-lo.** Ela não está apenas escolhendo peças de um sistema.

O contraste entre as duas imagens do seu próprio ZIP mostra exatamente isso. A tela que havia sido combinada e a tela implementada contêm aproximadamente a mesma jornada e conteúdo, mas a implementação altera a **composição**: proporções do resumo, agrupamento dos campos, tratamento dos controles, densidade vertical, acabamento, relações espaciais e hierarquia. Isso não é simplesmente “a cor azul saiu errada”. É uma reconstrução da página segundo outra gramática visual. Fontes internas: `A PORRA DO REGISTRAR PAGAMENTO/COMO EU TINHA COMBINADO.png` e `A PORRA DO REGISTRAR PAGAMENTO/COMO ESSA PORRA FOI IMPLEMENTADA.png`.

E a própria documentação posterior percebeu o problema. Em FE-055, o agente foi explicitamente instruído a não fazer “outro layout”, a tratar FE-052 como **alvo**, não inspiração, a conferir diferenças de até um pixel e a não usar testes funcionais como prova de fidelidade. Mesmo depois disso, o documento de fechamento afirma que a aceitação visual integral não estava certificada. Fonte interna: `INTEGRACAO_INTERFACE_APROVADA.md`, especialmente as seções “Direção e autorização”, “Conferência e aprendizados” e “Continuidade”.

Há outro mecanismo importante. Hoje, a documentação oficial do Codex estabelece que ele carrega `AGENTS.md` em uma cadeia de instruções, com precedência por diretório, e que o limite combinado padrão dessa cadeia é **32 KiB**; arquivos mais próximos do diretório de trabalho podem sobrescrever instruções anteriores. A própria OpenAI recomenda manter as regras concisas e deixar verificações mecânicas como lint para a automação/CI. No ZIP, o pequeno `AGENTS.md` delega para `AGENT_INSTRUCTIONS.md`; esse arquivo sozinho tem cerca de 32,5 KB, `ARCHITECTURE.md` cerca de 49 KB e os documentos principais de design na pasta raiz somam centenas de KB. **Isso não prova que o limite de contexto causou aquela implementação específica**, porque o agente pode abrir documentos posteriormente. Mas prova que o sistema dependia de o agente realizar corretamente uma longa cadeia de recuperação, interpretação, priorização e reconciliação de documentos. Essa é precisamente a classe de trabalho que você não deve deixar como pré-condição para uma implementação visual consistente. Fonte interna: `INSTRUÇÕES.../AGENTS.md`, `AGENT_INSTRUCTIONS.md`, `ARCHITECTURE.md`; comportamento atual do Codex documentado oficialmente pela OpenAI. Portanto, a causa estrutural é:

> **O frontend foi especificado como conhecimento para a IA compreender, quando deveria ter sido transformado em um sistema que o código e a CI obrigam a IA a utilizar.**

A solução não é escrever um prompt melhor dizendo “por favor siga o design”. É substituir a arquitetura atual:

**documentação → IA interpreta → IA desenha → humano descobre divergências**

por:

**contrato canônico → componentes/tokens executáveis → IA apenas compõe → testes rejeitam qualquer divergência**.

Esse princípio também está alinhado com a direção atual dos padrões de design tokens: o Design Tokens Community Group define tokens tipados, grupos, herança e referências/aliases precisamente para que valores semânticos sejam expressos de forma estruturada e reutilizável, em vez de duplicados manualmente. ## As dez coisas solicitadas, sem eliminar nenhuma

As duas listas que você exigiu se sobrepõem em alguns pontos, mas **não devem ser reduzidas a cinco tarefas**. Elas respondem a perguntas diferentes: uma investiga metodologia e automação; a outra transforma o ZM em um sistema concreto.

| | Exigência | Resultado da investigação |
|---|---|---|
| **1** | **Mapear e extrair padrões da documentação ZIP enviada** | Feito como reconstrução da autoridade visual do ZM. FE-049/FE-052, arquitetura, tokens, catálogo, composição, tipografia e decisões posteriores permitem recuperar o padrão pretendido sem usar o Dart atual como fonte de verdade. |
| **2** | **Pesquisar práticas e frameworks de design systems e automação para IA** | O padrão robusto é combinar tokens estruturados, biblioteca de componentes, receitas de composição, instruções de repositório e gates automatizados. Instrução textual sozinha não basta. Design Tokens Community Group, Flutter Theme/ThemeExtension e mecanismos de instrução de agentes oferecem as peças técnicas para isso. |
| **3** | **Identificar técnicas de instrução e contratos formais para gerar UI consistentes** | O agente deve receber uma API visual fechada: componentes permitidos, contratos de propriedades/estados, famílias de página, tokens válidos, comportamentos adaptativos e condições de aceite. A IA deve escolher e combinar essas primitivas, não redesenhar controles. |
| **4** | **Propor um fluxo de validação automatizada e testes visuais para garantir fidelidade** | Flutter possui testes de widget e comparação com golden files; `matchesGoldenFile` compara a renderização contra uma imagem mestre considerada a representação correta. O pacote de integração também possui comparador de goldens. Isso deve virar gate de merge. |
| **5** | **Gerar um checklist de implementação e integração para agentes IA e CI/CD** | O checklist deve começar antes da edição, exigir identificação do contrato utilizado e terminar somente após análise estática, testes de componentes, goldens, adaptação e navegação passarem. A OpenAI inclusive recomenda separar instruções conceituais de checks mecânicos executados por CI. |
| **6** | **Catalogar e extrair padrões da documentação ZIP enviada** | A documentação foi classificada em decisões confirmadas, referência visual canônica, históricos rejeitados e pontos ainda sem definição nativa. Isso é diferente do item 1: aqui o objetivo é transformar a história em um catálogo que possa alimentar o novo sistema. |
| **7** | **Mapear componentes e tokens visuais necessários para o design system** | O próprio ZIP já contém os CMP-01 a CMP-10 e quase todos os tokens fundamentais. Falta consolidá-los e acrescentar componentes estruturais como shell, cabeçalho, superfície, filtro compacto, extrato/lista, seção de formulário e receitas de página. |
| **8** | **Definir contratos de componentes e regras de composição programáticas** | Esta é a peça que mais faltou. Não basta `panelRadius=32`: precisa existir `ZmFinancialPanel`, por exemplo, e a página de formulário deve obrigatoriamente ser composta por uma receita conhecida. A IA não decide novamente padding, borda, tipografia ou estrutura. |
| **9** | **Especificar testes automatizados de fidelidade visual e navegação** | Além dos goldens de componentes, devem existir goldens das famílias de páginas, testes de rotas, restauração de filtro/estado, variação claro/escuro, largura e escala textual. Flutter distingue responsividade de adaptação; o app precisa testar ambos. |
| **10** | **Produzir instruções formais para agentes IA e processo de validação** | O agente deverá ser formalmente proibido de inventar variante visual. Quando o sistema não contiver o que a tarefa exige, o resultado correto será “há uma lacuna no design system”, não criar silenciosamente um novo desenho. As instruções ficam pequenas; os detalhes vivem nos contratos executáveis. |

A principal conclusão desses dez pontos é que **“documentação do frontend” precisa deixar de significar um conjunto de textos que descrevem o design**. Para o seu objetivo, ela precisa significar um pacote versionado que seja simultaneamente legível por humanos, legível por máquina e verificável automaticamente.

## O design ZM que já pode ser extraído do ZIP

Há uma base suficientemente consistente para construir essa nova especificação sem utilizar o frontend Dart atual para decidir como o aplicativo deveria parecer.

### O que já é decisão firme

A arquitetura de navegação tem cinco áreas: **Início, Financeiro, Negócio, Estoque e Mais**. No telefone, a navegação é inferior; no computador, lateral. FE-049 fixa “Negócio” e coloca vendas, clientes e resultado nessa área, enquanto Pagar/Receber permanecem em Financeiro. A home deve ser curta, com Dia/Semana/Mês. Fontes internas: `ARQUITETURA_FRONTEND.md` e `referencias_frontend/rodada-organizacao-2026-10-16/organizacao-integrada-zm.html`.

Isso coincide com a distinção feita pela documentação atual do Flutter entre **responsive** — reorganizar o conteúdo para caber — e **adaptive** — escolher a forma de interação apropriada ao espaço, como navegação inferior versus lateral. Nos fluxos financeiros, **Integral é o padrão**, Parcial é uma opção explícita, e há uma etapa de revisão antes da confirmação. Pagar e Receber são parentes visualmente, mas conservam suas regras de domínio. Fonte interna: `ARQUITETURA_FRONTEND.md`, `CATALOGO_COMPONENTES_FRONTEND.md`, rodadas de Pagar e Receber.

Os valores confirmados mais importantes são:

| Papel | Valor recuperado |
|---|---:|
| Destaque padrão | `#2866ae` |
| Espaço entre grupos de campos | `20` |
| Raio dos campos | `24` |
| Raio dos painéis | `32` |
| Ações/escolhas de uma linha | cápsula |
| Target mínimo de interação da referência | `44` |
| Altura mínima de campo da referência | `56` |
| Padding de página de referência | `20`, estreito `14` |
| Label → controle | `9` |
| Coluna da navegação desktop FE-052 | `140` |
| Raio dos controles da navegação | `12` |

Fontes internas: `TOKENS_VISUAIS_PROPOSTOS.json`, `BASE_VISUAL_FRONTEND.md`, FE-049 e README da FE-052.

A paleta-base recuperada é também bastante definida:

| Token semântico | Claro | Escuro |
|---|---|---|
| `page.soft` | `#f6f7f9` | `#141518` |
| `surface` | `#ffffff` | `#24262b` / variação contextual |
| `text.primary` | `#222730` | `#eef0f5` |
| `text.secondary` | `#5c6472` | `#b6becb` |
| `separator` | `#d9dee7` | `#505867` |
| `control.edge` | `#7d8796` | `#7a8495` |
| `success.text` | `#246a4e` | `#a6ddc3` |
| `warning.text` | `#80501a` | `#f2c78d` |
| `error.text` | `#a43136` | `#ffb5b7` |

Fonte interna: `TOKENS_VISUAIS_PROPOSTOS.json`.

A tipografia “**Leitura recuperada**” substituiu a alternativa maior e mais pesada. A referência documenta, entre outros papéis, `pageTitle` 23/33,35/500, `sectionTitle` 16/23,2/500, corpo 15/21,75/400, input 16/24/400, `amountMain` 32/46,4/500 e `amountSummary` 23/33,35/500. **Mas há uma lacuna importante:** a família tipográfica nativa definitiva nunca foi formalmente fixada; Segoe UI foi usada na referência para controlar a comparação, e o próprio documento alerta que as métricas nativas ainda precisavam ser validadas. Fonte interna: `TOKENS_VISUAIS_PROPOSTOS.json`, `HIERARQUIA_E_TIPOGRAFIA_FRONTEND.md`.

Isso significa que a nova documentação não deve fingir que esse ponto está resolvido. Ela deve ter algo como:

```yaml
typography:
  family:
    status: unresolved-native-decision
  roles:
    pageTitle:
      source: FE-049
      size: 23
      lineHeight: 33.35
      weight: 500
```

O acabamento FE-052 é igualmente recuperável. A referência estabelece fundo azul-acinzentado com luz quente discreta, vidro suave, borda iluminada e sombra; o CSS registra glows frios/quentes, painel translúcido, campo translúcido e blur de 18 CSS px. Nas listas de Pagar/Receber, a apresentação é de extrato; o filtro fica recolhido por padrão e mostra o recorte ativo. Campos continuam 24, painéis 32, espaço 20; a navegação conserva coluna 140, raio 12 e alinhamentos. Fonte interna: `referencias_frontend/rodada-acabamento-2026-10-16/README.md` e `acabamento.css`.

Aqui há uma sutileza que precisa ser preservada na migração: o JSON dizia que alguns parâmetros do estudo de material não tinham sido **individualmente** confirmados. Entretanto, FE-055 posteriormente declara a **FE-052 inteira como alvo de apresentação, e não mera inspiração**. Portanto, a solução correta não é reabrir tudo; é registrar esses valores como **“derivados da referência canônica FE-052”**, distinguindo-os dos tokens que foram verbalmente aprovados um a um. Fonte interna: `INTEGRACAO_INTERFACE_APROVADA.md`.

### Os componentes já concebidos

O catálogo contém:

`CMP-01` campo monetário, `CMP-02` campo de data, `CMP-03` escolha exclusiva com revelação, `CMP-04` seletor, `CMP-05` texto complementar, `CMP-06` ação principal/secundária, `CMP-07` mensagem de estado, `CMP-08` resumo financeiro, `CMP-09` registro lista/tabela e `CMP-10` revisão/conclusão.

O ponto forte é que o documento já registra **o que cada componente recebe e o que ele não deve decidir**. Isso é exatamente a abordagem certa para IA.

O que faltava era dar o passo seguinte:

**CMP-03 escrito num Markdown → classe concreta `ZmExclusiveChoice` → API fechada → golden obrigatório → agente proibido de redesenhá-la.**

Também faltam primitivas estruturais, porque seu problema foi justamente de composição. O novo catálogo precisa incluir pelo menos:

```text
ZmAppShell
ZmNavigation
ZmPageHeader
ZmPageBody
ZmPanel
ZmFinancialSummary
ZmFormPanel
ZmFieldGroup
ZmMoneyField
ZmDateField
ZmExclusiveChoice
ZmOptionField
ZmTextArea
ZmPrimaryAction
ZmSecondaryAction
ZmStateMessage
ZmCompactFilter
ZmStatementList
ZmStatementRow
ZmReviewPanel
```

Isso resolve uma diferença fundamental: **tokens dizem como desenhar uma peça; componentes impedem que cada tela redesenhe a peça; receitas de composição impedem que cada tela reorganize as peças de qualquer jeito.**

Só um design system de três níveis consegue resolver seu problema:

**tokens → componentes → composições de página.**

## O contrato executável que deve substituir a documentação atual

A melhor arquitetura para o ZM não é um Markdown gigantesco. É ter **uma hierarquia inequívoca de autoridade**.

### Fonte de verdade

Eu recomendo esta estrutura:

```text
frontend_contract/
├── manifest.yaml
├── tokens.json
├── components.yaml
├── compositions.yaml
├── navigation.yaml
├── motion.yaml
├── pages/
│   ├── inicio.yaml
│   ├── financeiro_resumo.yaml
│   ├── financeiro_lista.yaml
│   ├── financeiro_registro.yaml
│   ├── financeiro_revisao.yaml
│   ├── negocio.yaml
│   └── ...
├── acceptance/
│   ├── visual_matrix.yaml
│   ├── navigation_matrix.yaml
│   └── accessibility_matrix.yaml
└── references/
    └── FE-052/
```

E, separadamente:

```text
docs/frontend/
├── README.md
├── DESIGN_SYSTEM.md
├── COMPONENT_CATALOG.md
├── PAGE_RECIPES.md
├── AGENT_WORKFLOW.md
├── DECISIONS.md
└── archive/
    └── ... documentação histórica ...
```

A distinção é crucial:

> `frontend_contract/` manda.  
> `docs/frontend/` explica.  
> `archive/` conta a história, mas **não compete com o presente**.

Hoje a história e o contrato estão misturados.

### Manifesto de autoridade

`manifest.yaml` deveria declarar algo nessa linha:

```yaml
designSystem:
  id: zm-frontend
  version: 1.0.0
  status: canonical

authority:
  tokens: tokens.json
  components: components.yaml
  compositions: compositions.yaml
  navigation: navigation.yaml
  visualReference: references/FE-052/

rules:
  historicalDocumentsAreAuthoritative: false
  featureCodeMayDefineVisualTokens: false
  featureCodeMayCreateComponentVariants: false
  missingPatternPolicy: block-and-propose-design-system-change
```

Isso elimina uma pergunta que hoje o agente precisa responder por interpretação:

> “Qual desses cinquenta documentos eu devo seguir?”

Ele deixa de responder. O manifesto responde.

### Tokens realmente utilizáveis

O atual `TOKENS_VISUAIS_PROPOSTOS.json` é uma excelente matéria-prima, mas o próprio arquivo declara que **não é runtime**.

A nova versão deve adotar tokens semanticamente nomeados, tipados e referenciáveis. O Design Tokens Format Module formaliza justamente grupos, `$type`, `$value`, referências e aliases; referências semânticas ajudam a eliminar repetição e manter relações entre valores. Exemplo conceitual:

```json
{
  "color": {
    "accent": {
      "$type": "color",
      "$value": {
        "colorSpace": "srgb",
        "components": [0.157, 0.4, 0.682],
        "hex": "#2866ae"
      }
    }
  },
  "shape": {
    "panel": {
      "$type": "dimension",
      "$value": {
        "value": 32,
        "unit": "px"
      }
    },
    "field": {
      "$type": "dimension",
      "$value": {
        "value": 24,
        "unit": "px"
      }
    }
  }
}
```

O Design Tokens Community Group oferece o formato como especificação de interoperabilidade e permite, entre outras coisas, aliases semânticos e grupos hierárquicos; a página do W3C registra os relatórios publicados pelo grupo. Esses tokens então geram ou alimentam um único tema Flutter. O Flutter oferece `ThemeExtension` exatamente para acrescentar propriedades específicas do aplicativo ao `ThemeData`, com campos próprios e interpolação entre temas. Então em vez de uma IA escrever:

```dart
Container(
  padding: const EdgeInsets.all(21),
  decoration: BoxDecoration(
    color: const Color(0xFF252A32),
    borderRadius: BorderRadius.circular(28),
  ),
)
```

o código da feature deveria ser algo próximo de:

```dart
ZmFinancialPanel(
  child: ...
)
```

O raio, padding, superfície, sombra, contraste e comportamento claro/escuro pertencem ao design system.

**É isso que impede a IA de “ser criativa”.**

### Contratos dos componentes

Cada componente precisa ter um contrato **programático**, e não só uma descrição visual.

Um exemplo simplificado para seu componente Integral/Parcial:

```yaml
component: ZmPaymentModeChoice
version: 1

inputs:
  value:
    type: enum
    values: [full, partial]
    required: true
  balance:
    type: money
    required: true

behavior:
  default: full
  partialReveals:
    - ZmMoneyField
  fullHides:
    - ZmMoneyField

visual:
  family: exclusiveChoice
  shape: shape.capsule
  typography: typography.action
  spacing: spacing.component.choice

forbidden:
  - independent custom radius
  - independent custom colors
  - alternate segmented-control geometry

accessibility:
  semantics: single-selection-group

requiredStates:
  - full
  - partial
  - disabled
  - validation-error
```

Agora a IA não recebe “faça um seletor parecido”. Ela recebe uma interface.

O catálogo que já existe no ZIP tem a base semântica disso; a nova documentação precisa convertê-la para contratos que tooling consegue ler.

### Gramática de composição

Essa é provavelmente **a peça mais importante que faltava no projeto**.

A tela de Registrar pagamento não ficou diferente apenas porque um raio estava errado. Ela foi **recomposta**.

Portanto é necessário definir famílias de página.

Por exemplo:

```yaml
composition: financialEntryForm

structure:
  - ZmPageHeader
  - ZmFinancialSummary
  - ZmFormPanel:
      children:
        - ZmChoiceField
        - ZmFieldGroup*
        - ZmRemainingBalance
        - ZmPrimaryAction
  - ZmSupportingText

constraints:
  contentGap: spacing.fieldGroup
  formPanelRadius: shape.panel
  onePrimaryActionPerStep: true
  fieldOrderIsSemantic: true

forbidden:
  - splitting summary into arbitrary oversized hero
  - putting navigation inside page content
  - adding an independent card around each field
```

E uma listagem:

```yaml
composition: financialStatementList

structure:
  - ZmPageHeader
  - ZmFinancialSummary
  - ZmCompactFilter
  - ZmStatementList
```

É assim que sua pergunta original fica solucionada.

Você poderia pedir:

> “Crie uma página de faturas, com pesquisa, filtro por período, status, valor e acesso aos detalhes.”

O agente não decidiria mais “como uma página do ZM deve parecer”.

Ele faria:

```text
família = financialStatementList
header = Faturas
search = permitido
filter = ZmCompactFilter
records = ZmStatementList
row content = emissor + vencimento + valor + status
```

Todo o resto já existe no sistema.

**Essa é a diferença entre dar à IA referências de design e dar à IA uma linguagem de interface.**

## Instruções formais para qualquer agente de IA

A parte textual deve ficar muito menor do que hoje, porque ela deixará de carregar todos os detalhes visuais.

O mecanismo de `AGENTS.md` do Codex é apropriado para regras de projeto: o Codex atualmente lê os arquivos antes do trabalho, aplica uma hierarquia de escopos e permite instruções mais específicas nos diretórios inferiores. GitHub Copilot possui ideia equivalente de instruções específicas de repositório para dar ao agente contexto sobre como compreender, construir, testar e validar mudanças no projeto. Isso mostra que **instrução versionada dentro do repositório é uma prática suportada por mais de uma plataforma**, embora cada agente tenha seu próprio formato de entrada. Mas o conteúdo do arquivo-raiz do ZM deveria ser aproximadamente assim, não centenas de linhas de história:

```md
# Frontend ZM — regras obrigatórias

## Fonte de verdade
Antes de editar UI, leia frontend_contract/manifest.yaml.
Somente arquivos referenciados pelo manifesto são canônicos.

## Regra fundamental
Não redesenhe componentes existentes.
Não derive estilos de telas antigas.
Não use documentação histórica como fonte visual.

## Construção de páginas
1. Identifique a família em compositions.yaml.
2. Use exclusivamente componentes registrados em components.yaml.
3. Use exclusivamente tokens registrados em tokens.json.
4. Use o page spec correspondente quando existir.

## Lacuna no sistema
Se a tarefa exigir um padrão que não existe:
PARE.
Não invente um novo padrão.
Registre a lacuna e proponha alteração do design system.

## Proibições
Feature code não pode criar:
- paleta própria;
- TextStyle estrutural próprio;
- BorderRadius estrutural próprio;
- espaçamento estrutural arbitrário;
- variante visual local de componente compartilhado.

## Validação
Uma alteração de UI só está concluída se:
- contratos passarem;
- análise passar;
- widget tests passarem;
- goldens passarem;
- navegação afetada passar;
- nenhum token visual bruto proibido for introduzido.

Teste funcional não é prova de fidelidade visual.
```

Esse documento é pequeno o suficiente para ser realmente carregado como regra permanente. Os detalhes ficam em arquivos especializados e verificáveis. Isso também evita pressionar a cadeia de instruções do Codex, cujo limite combinado é documentado como 32 KiB por padrão. ### A regra que mudaria completamente o comportamento do agente

Esta frase deve ser tratada quase como a “constituição” do frontend:

> **Ausência de um padrão não concede liberdade para inventar um padrão.**

Hoje, implicitamente, quando a documentação não resolve uma tradução para Flutter, o agente pode preencher a lacuna.

No sistema novo:

**lacuna → falha explícita → extensão do design system → só depois implementação.**

Isso impede crescimento descontrolado do frontend.

Outra regra:

> **A IA não implementa visual; ela instancia o design system.**

Naturalmente haverá Dart sendo escrito, mas a responsabilidade visual da feature fica radicalmente menor.

### Contrato de tarefa para uma nova tela

Um pedido para IA deveria poder ser formalizado assim:

```yaml
task:
  id: UI-INVOICES
  intent: create-page

page:
  family: financialStatementList
  area: financeiro
  title: Faturas

content:
  search: true
  filters:
    - duePeriod
    - status
  record:
    fields:
      - issuer
      - dueDate
      - originalAmount
      - currentBalance
      - status

navigation:
  destination: financeiro/faturas

requiredStates:
  - loading
  - loaded
  - empty
  - noFilterResults
  - error
  - staleData

allowedVisualChange:
  designSystem: false
```

Um agente suficientemente capaz deixa de ter que “descobrir qual design fica bonito”.

Ele recebe o conteúdo e o contrato.

## Validação automatizada: o que torna o padrão realmente obrigatório

Mesmo toda essa arquitetura não basta se a IA ainda puder quebrá-la e declarar o trabalho pronto.

É por isso que a **CI é parte do design system**.

O Flutter oferece testes de widgets nos quais `WidgetTester` constrói e interage com widgets, `Finder` localiza elementos e matchers verificam estados; entre esses matchers está `matchesGoldenFile`, especificamente destinado a verificar se a renderização corresponde a uma imagem bitmap de referência. A API oficial descreve um golden como uma imagem mestre considerada a renderização verdadeira daquele widget, estado ou aplicação e permite atualizar explicitamente esses masters com `flutter test --update-goldens`. Isso é exatamente o mecanismo que faltou como autoridade nativa.

### Pipeline obrigatório

A sequência deveria ser:

**Contrato → análise → componentes → golden → navegação → integração → build.**

Mais concretamente:

| Gate | O que rejeita |
|---|---|
| Validação de `manifest/tokens/components/compositions` | contratos inválidos, referências inexistentes, token sem tipo, componente desconhecido |
| Codegen/drift | Dart do design system diferente da especificação canônica |
| Policy check | cor, raio, padding, `TextStyle` ou variante estrutural introduzidos indevidamente em feature code |
| `flutter analyze` | problemas estáticos e regras do projeto |
| Component tests | componente descumprindo sua API/estado |
| Component goldens | mudança visual em uma peça do sistema |
| Page goldens | alteração da composição aprovada |
| Navigation tests | rota, retorno, filtro ou estado quebrados |
| Adaptive tests | layout errado em mobile/desktop/texto ampliado |
| Integration tests | fluxo real não funcionando |
| Build | plataforma alvo não compilando |

O Dart permite configurar análise estática e regras de lint em `analysis_options.yaml`; a documentação atual recomenda `flutter_lints` para projetos Flutter. Para as restrições específicas do ZM — por exemplo “não usar `BorderRadius.circular` dentro de `views/`” — eu acrescentaria um verificador próprio do repositório, além do analyzer. ### Testes visuais do ZM

A FE-052 já tinha uma matriz de testes web bastante séria: 320/390/1024 de largura, claro/escuro, escala 100/150/200%, material vidro/sólido e múltiplos estados. A documentação registra centenas de composições verificadas no protótipo. Isso é útil como matriz de origem. **O erro foi essa proteção não ser equivalente a um contrato de renderização Flutter para todas as páginas implementadas.** Fonte interna: `referencias_frontend/rodada-acabamento-2026-10-16/README.md`.

A nova matriz pode reaproveitar esses eixos:

```yaml
canonicalViewports:
  narrow: 320
  phone: 390
  phoneWide: 422
  desktop: 1024

themes:
  - light
  - dark

textScale:
  critical:
    - 1.0
    - 1.5
    - 2.0

material:
  - normal
  - reducedTransparency

financialStates:
  - full
  - partial
  - validationError
  - review
  - success

listStates:
  - loaded
  - empty
  - noFilterResults
  - stale
  - error
```

Não é necessário testar o produto cartesiano inteiro em todo componente; cada contrato define quais combinações são visualmente relevantes.

### Sobre “diferença de um pixel”

É possível criar um gate extremamente rigoroso, mas existe uma condição: **o ambiente do golden precisa ser determinístico**.

Você precisa congelar, entre outras coisas:

```text
Flutter SDK
fonte e versão da fonte
viewport lógico
devicePixelRatio do teste
tema
escala textual
locale
dados
estado
animações
```

Caso contrário, diferenças de rasterização de fonte ou plataforma podem mudar pixels sem que o design tenha mudado.

A solução é ter:

**um ambiente canônico → comparação visual estrita**,  
mais  
**Android/iOS/Windows → testes adaptativos e de comportamento por plataforma**.

Isso combina a capacidade de controle pixel a pixel com a realidade de uma aplicação Flutter multiplataforma. A própria documentação do Flutter enfatiza que um aplicativo adaptativo precisa lidar não apenas com tamanhos diferentes, mas também com diferentes dispositivos de entrada e contextos de plataforma. E atenção: **atualizar um golden nunca pode ser um conserto automático**. Se a IA rodar `--update-goldens` sempre que um teste falhar, ela apaga a fiscalização. Alteração de golden deve ser tratada como mudança do design system e exigir autorização específica. A API oficial permite atualizar goldens, portanto a política do repositório precisa controlar quando isso é aceitável. ## A nova documentação que o ZM realmente precisa

O que você precisa criar não é outra versão mais extensa de `ARQUITETURA_FRONTEND.md`.

Você precisa **converter o trabalho já feito em uma especificação operacional**.

A nova documentação deveria ter estas autoridades:

| Artefato | Função |
|---|---|
| `manifest.yaml` | diz qual versão do design está valendo e aponta para todas as fontes canônicas |
| `tokens.json` | valores e papéis semânticos |
| `components.yaml` | API visual e comportamental dos componentes |
| `compositions.yaml` | gramática das famílias de página |
| `pages/*.yaml` | exceções e conteúdo específico das páginas |
| `navigation.yaml` | shell, áreas, rotas e adaptação |
| `visual_matrix.yaml` | quais renderizações obrigatoriamente têm golden |
| Flutter Design System | implementação única dos contratos |
| Goldens | evidência visual executável |
| `AGENTS.md` | regras pequenas que mandam qualquer IA utilizar o sistema |
| CI | autoridade que impede violação |

A documentação histórica deve continuar existindo, porque explica por que as decisões foram tomadas, mas deve sair da cadeia primária que o agente consulta para construir uma página.

### Status das decisões na migração

Eu criaria somente quatro estados:

**`canonical`** — pode e deve ser usado.

**`derived-from-canonical-reference`** — não foi aprovado isoladamente, mas é necessário para reproduzir FE-052, que é a referência aprovada.

**`experimental`** — não pode aparecer em produção.

**`deprecated`** — preservado só por história.

Isso elimina coisas perigosas como `partially_confirmed` dentro da fonte que um agente usa para implementação.

Exemplo:

```yaml
shape.panel.radius:
  value: 32
  status: canonical
  source: FE-030

shape.field.radius:
  value: 24
  status: canonical
  source: FE-030

spacing.fieldGroup:
  value: 20
  status: canonical
  source: FE-028

color.accent.default:
  value: "#2866ae"
  status: canonical
  source: FE-028

material.panel.blur:
  value: 18
  status: derived-from-canonical-reference
  source: FE-052/acabamento.css

typography.family:
  status: unresolved
```

Um valor `unresolved` **não pode ser inventado pelo agente**.

Ele bloqueia a certificação daquele aspecto até a decisão existir.

### O checklist definitivo para um agente

Para qualquer nova página ou remodelação, o agente precisa conseguir responder automaticamente:

1. Qual versão do design system estou usando?
2. Qual família de página representa esta tarefa?
3. Quais componentes existentes atendem ao conteúdo?
4. Quais tokens esses componentes usam?
5. Quais estados precisam existir?
6. Qual comportamento mobile/desktop está definido?
7. Estou introduzindo algum estilo bruto fora do design system?
8. Estou criando uma variante de componente sem autorização?
9. Quais goldens devem permanecer iguais e quais novos são obrigatórios?
10. Todos os gates passaram?

E o critério de conclusão passa a ser:

> **“Eu implementei usando componentes canônicos e todos os contratos visuais passaram.”**

Não:

> “Analisei a documentação e tentei deixar parecido.”

### O checklist definitivo para CI/CD

A CI não deve aceitar uma alteração de UI se qualquer uma destas condições ocorrer:

- token bruto proibido aparece em código de feature;
- componente visual novo não consta do catálogo;
- variante local não consta do contrato;
- página não corresponde a uma composição registrada;
- contrato de tokens falha;
- `flutter analyze` falha;
- teste de widget falha;
- golden muda sem uma alteração de design explicitamente autorizada;
- navegação ou estado associado falha;
- um novo componente não possui estados e goldens obrigatórios;
- a implementação passa funcionalmente, mas falha visualmente.

Flutter já oferece os blocos fundamentais para os testes de widget/golden e para testes de integração; a camada específica de política do ZM é o que precisa ser construída por cima. ### O que muda na prática para você

Depois disso, a sua interação deixa de ser:

> “Faça uma tela de faturas. Mas lembra que o canto é assim, o botão é assado, o espaço é 20, cuidado com o título, não faça aquele card gigante, o filtro tem que ser compacto...”

E passa a ser:

> “Crie Faturas em Financeiro usando `financialStatementList`, com pesquisa, filtros de vencimento/status e os campos X, Y, Z.”

O agente procura a composição, instancia os componentes permitidos, liga os dados e os testes verificam o resultado.

Para remodelar uma tela antiga:

> “Migre `Tela X` para `financialEntryForm` sem alterar regras de negócio.”

A tarefa passa a ser uma **migração de uma composição para outra**, não uma oportunidade para redesenhar o frontend.

Essa é, de fato, a solução para “qualquer IA conseguir reproduzir o padrão”.

Não existe uma forma de garantir isso apenas escrevendo uma descrição suficientemente boa. A garantia vem de **reduzir o espaço de liberdade do agente e aumentar o espaço de validação automática**.

No estado atual, o agente recebe uma biblioteca.

No estado que você precisa, o agente deve receber uma **linguagem**.

E a linguagem deve ter compilador, tipos e testes.

### O que ainda não pode ser honestamente chamado de resolvido

Há três lacunas que a nova especificação precisa tratar explicitamente, em vez de escondê-las.

A primeira é a **fonte nativa definitiva**. A Leitura recuperada está escolhida, os papéis tipográficos estão documentados e a referência utilizou Segoe UI, mas o próprio material registra que a família nativa final não havia sido escolhida. Fonte interna: `TOKENS_VISUAIS_PROPOSTOS.json`.

A segunda é a diferença entre valores **explicitamente aprovados** e parâmetros **derivados do acabamento FE-052**. Como FE-055 transforma FE-052 em alvo visual, esses parâmetros podem ser migrados como derivados da referência, mas não devem ser falsamente registrados como decisões individuais que você tomou. Fonte interna: `BASE_VISUAL_FRONTEND.md`, `INTEGRACAO_INTERFACE_APROVADA.md`.

A terceira é que **eu deliberadamente não utilizei o Dart atual como fonte de verdade nesta investigação**. Isso é importante. O frontend atualmente implementado é justamente o objeto cuja conformidade está em questão. Ele só deve entrar numa fase posterior, quando o novo contrato estiver fechado, para responder:

> “Que partes do código atual já obedecem ao contrato e quais precisam ser migradas?”

Não para responder:

> “Qual deveria ser o design?”

Essa ordem é a correta.

**A documentação que você já criou não foi inútil. Ela contém quase toda a matéria-prima do design system. O erro foi esperar que um agente tratasse essa matéria-prima documental como se já fosse um design system executável.**

A reconstrução correta é:

**decisões do ZIP → contrato canônico → tokens → componentes → composições → Flutter Design System → goldens → regras do agente → CI bloqueante.**

É isso que transforma o padrão do ZM de uma coisa que a IA precisa “lembrar e interpretar” em uma coisa que ela precisa **obedecer**.