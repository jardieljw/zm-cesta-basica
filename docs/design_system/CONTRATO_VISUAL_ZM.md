# ZM — CONTRATO CANÔNICO DE DESIGN (v3.0)
**Fonte:** branch `backup`, commit `79c95cd`, confrontada com a FE-052. **Objetivo:** nenhuma página nova deve decidir novamente como são título, fonte, campos, filtros, calendários, ícones, cartões ou navegação.

## 0. Escopo e autoridade
A ordem de autoridade é **decisão explícita do usuário > HTML FE-052 preservado > contratos históricos específicos > código Flutter da backup > preferência do agente**. A referência imutável está em `docs/referencias_frontend/rodada-acabamento-2026-10-16/acabamento-integrado-zm.html`, SHA-256 `774f5bbce0ccbc8048818a2daa24531804619551432113795a00a6dbe4eaf53f`. O HTML não descreve integralmente todas as 38 views. Não aplicar uma medida de formulário a um componente de navegação não equivalente. Se dois documentos divergem, citar o conflito e usar a decisão mais recente comprovada; jamais inventar aprovação.
   
O código **já tem** `approvedAppTheme`, `AppPalette`, `ApprovedPage`, `ApprovedHeader`, `ApprovedSurface`, `ApprovedChoice`, `ApprovedCollapsibleFilter`, `ApprovedDateButton`, `ApprovedCalendarDialog`, `ApprovedIcon`, `ReviewedPaymentView`. **Reaproveitar antes de criar qualquer outro componente**; o nome "Approved" não comprova que toda ocorrência esteja homologada.

## 1. Valores do produto
| Papel | Valor na FE-052 / decisão | Regra |
| --- | --- | --- |
| Destaque padrão | `#2866AE` | Confirmado FE-028; usuário pode alterar. Derivar destaque/contraste conjuntamente para cada tema. |
| Espaço entre grupos de campos | `20` | Confirmado FE-028. Adaptar com escala de texto, sem colidir. |
| Raio de campo | `24` | Confirmado FE-030. |
| Raio de painel | `32` | Confirmado FE-030. |
| Fundo claro / escuro | `#F6F7F9` / `#141518` | Observado FE-052; globalizar via `AppPalette`, não escrever literal na view. |
| Superfície clara / escura | `#FFFFFF` / `#24262B` | Observado FE-052. |
| Texto claro / escuro | `#222730` / `#EEF0F5` | Observado FE-052. |
| Borda clara / escura | `#E0E4EB` / `#454B57` | Observado FE-052. |
| Destaque efetivo escuro | `#A7CAFF` | Referência quando seed padrão; outras sementes exigem contraste. |
| Campos normais | altura mínima `56` | Referência CSS px, não altura máxima; manter texto íntegro com acessibilidade. |
| Filtro recolhido | altura mínima `48`, raio `24` | Resumo do filtro aplicado deve continuar visível. |
| Controle segmentado | opção mínima `48`, indicador de rádio `18` | `Integral/Parcial` não vira dois ChoiceChips independentes. |
| Calendário | largura máxima `360`, raio `32` | Diálogo; fonte e tamanho adaptativos, retornar valor e foco. |
| Navegação lateral desktop | `140` | Largura de referência FE-052, não breakpoint universal. |
| Navegação inferior | cinco destinos | Início, Financeiro, Negócio, Estoque, Mais; manter estado/rolagem. |

**Tipografia da referência HTML:** página `23/500/-0.6 letterSpacing`, seção `16/500`, conteúdo `15` com altura de linha aproximada `1.45`, campo `16`, apoio `12`, contexto de filtro `13`, valor em painel `23/500`, valor em detalhe `32/500`. Segoe UI/Semibold foi efetivamente usada na referência Windows; **os arquivos de fonte não são distribuídos** e a equivalência em outras plataformas requer teste. O estudo tipográfico alternativo `24/30` e demais papéis em `docs/HIERARQUIA_E_TIPOGRAFIA_FRONTEND.md` é proposta, não sobrepõe sozinho a FE-052. Nunca espalhar números literais de texto pelas views. Obter via `Theme.of(context).textTheme` e papéis centralizados em `approvedAppTheme`.

## 2. Componentes — API existente, lacunas e comportamento
Consultar `components.json` para IDs, estados, caminhos reais e nível de implementação.

- **Página/título/navegação:** `ApprovedPage` + `ApprovedHeader`; títulos respeitam hierarquia e quebra longa; shell tem barra inferior no celular, lateral no desktop. Não construir novo `Scaffold` em tela comum quando o template resolve.
- **Pesquisa:** **não existe um único componente compartilhado completo**. Crie `ZmSearchField` na biblioteca compartilhada antes de migrar views; parâmetros `hint`, `value/controller`, `onChanged` ou `onSubmitted`, `onClear`, `enabled`, `autofocus`. Lupa, limpeza, raio, cor, foco e geometria definidos UMA vez. Clientes, produtos, compras, pagar, estoque devem usá-lo.
- **Filtros:** `ApprovedCollapsibleFilter` já existe (cabeçalho fechado `48`, raio `24`); `ResponsiveFilterBar` só resolve disposição, NÃO padroniza componentes. Construir `ZmFilterPanel` composto de cabeçalho, resumo aplicado, opções/chips padronizados e ações limpar/aplicar/atualizar conforme a busca. Diferenciar **rascunho de filtro** de **filtro aplicado**. Nunca impor a Pagar/Receber um enum global de status que altere semântica dos dados.
- **Seletor:** reutilizar `ApprovedChoice<T>` quando correspondente ao desenho FE-052. Integral selecionado por padrão, Parcial revela valor, campo oculto sai da validação. Não substituir sem teste por `ChoiceChip` ou `SegmentedButton` padrão. Filtros rápidos podem ser outra variante declarada, não devem imitar rádio financeiro sem necessidade.
- **Calendário:** **usar** `ApprovedDateButton` + `ApprovedCalendarDialog` como implementação candidata a consolidar. O HTML FE-052 coloca o ícone no extremo DIREITO do campo, com data legível. **Bug de aderência identificado:** `ApprovedDateButton` atual desenha `Icons.calendar_today_outlined` à ESQUERDA; corrigir no próprio componente antes de migrar. `ReviewedPaymentView` ainda usa `OutlinedButton.icon + showDatePicker`, outro caminho paralelo. Unificar após testar abertura, cancelamento, escolha, restrições, texto 2x e retorno de foco. Os tempos alternativos da rodada FE-031/032 não foram aprovados; não promover `240ms/12px` a padrão.
- **Campos e dinheiro:** `ApprovedField` fornece recipiente; definir widget composto de rótulo, texto/ajuda/erro, área de toque e formatação. Valor financeiro tem centavos, identidade/estado explícitos. Tela não inventa regras de negócio nem trata falha de API como `R$ 0,00`.
- **Registros/listagens:** reutilizar `ApprovedRow`, `ApprovedSurface` e `ApprovedHeroCard`; extrato financeiro apresenta pessoa, origem, vencimento e saldo. Em desktop pode usar tabela, **sem perder dados**. Badges textuais independentes da cor de destaque. Nunca uma moldura por informação quando uma linha organizada basta.
- **Botões/ícones:** `ApprovedPrimaryButton`, `ApprovedSecondaryButton`, `ApprovedIcon`. Nada de nova biblioteca de ícones sem contrato, novo `ButtonStyle` artesanal para página isolada nem FAB invadindo rolagem. Uma ação primária por etapa.
- **Diálogos/status:** criar padrão de diálogos para extratos, embalagem, confirmação/erro e edição; estados obrigatório `loading`, `empty`, `offline`, `error`, `stale`, `success`, `disabled`, `focused`. Distinção entre revisão (previsão) e confirmação (operação efetiva).
- **Efeitos:** luz azul/quente e acabamento translúcido apenas nos painéis indicados FE-052; campos de dados/valores permanecem legíveis. Respeitar reduzir movimento e alto contraste; animação não pode tornar texto ilegível.

## 3. Oito contratos de página (sem reinvenção)
`page_patterns.json` documenta **overview**, **finance**, **list**, **detail**, **form**, **review**, **document** e **settings**. Implementar como estruturas com slots de conteúdo e dados, não blocos de design duplicados. O tipo de negócio muda conteúdo/opções, não a identidade visual.

## 4. Diferenças REAIS na backup que devem ser resolvidas
- `client/lib/views/payables_view.dart`: campo de pesquisa com raio `16`, diferente do padrão de referência `24`; filtros e badges locais.
- `client/lib/views/receivables_view.dart`: `ExpansionTile`/chips/dropdown nativos em vez do filtro FE-052; existem controles adicionais que precisam ser preservados, não eliminados.
- `client/lib/views/products_view.dart`: `ApprovedChoice` e `ChoiceChip` coexistem; busca redesenhada dentro da tela.
- `client/lib/views/purchases_view.dart`, `customers_view.dart`, `sales_view.dart`: pesquisa, status e filtros reconstruídos independentemente.
- `client/lib/widgets/shared/reviewed_payment_view.dart`: calendário nativo `showDatePicker` e botão `OutlinedButton.icon`; diverge da referência e do próprio `ApprovedDateButton`.
- `client/lib/views/reports_view.dart`, `sale_form_view.dart`, `purchase_form_view.dart`, `dashboard_view.dart`: seletores de data e muitas geometrias locais.
- Formulários `product_form_view.dart`, `customer_form_view.dart`, `basket_type_form_view.dart` montam `Scaffold` e campos locais.
- `home_view.dart` é um alias, `payable_payment_view.dart`/`receivable_payment_view.dart` são adaptadores: **não recriar**.
- `pairing_view.dart` e `pdf_viewer_screen.dart` podem justificar casca especial; mantê-las como exceções justificadas.

A matriz **de todas as 38 views** está em `views.json`, com indicação por arquivo e ação. Essa matriz é de código/arquitetura e NÃO declara 38 páginas visualmente homologadas.

## 5. Regra operacional para Codex e qualquer desenvolvedor
1. Antes de editar `client/lib/views`: consultar este arquivo, `tokens.json`, `components.json`, `page_patterns.json` e `views.json`; localizar os widgets `Approved*` que já existem.
2. Criar ou atualizar **primeiro** o componente compartilhado se faltar um padrão recorrente; migrar os usos sem mudar API/backend, localização e dados.
3. Nenhuma página nova cria `TextStyle(`, `Colors.`, `Color(0x...`, `InputDecoration(`, `BorderRadius.circular(` ou usa `showDatePicker(` **em lugar de componente já existente**. A partir desta revisão o CI também identifica acréscimo de `Icons.*`, filtros nativos (`FilterChip`, `ChoiceChip`, `ExpansionTile`, `SegmentedButton`), inputs crus, `Scaffold`, `AppBar`, `EdgeInsets.*` e fonte literal nas views. São alertas bloqueantes sobre **linhas novas**, não uma condenação automática do legado. Exceções justificadas devem ser registradas em `exceptions.json`.
4. Se precisar de variante nova, adicionar ID, API, estados, fonte e testes em `components.json` **antes** de usar.
5. Conferir estados (vazio/carga/erro/offline), filtros fechados/abertos, calendário e seleção Integral/Parcial, celular `320/390/430`, desktop `1100+`, claro/escuro, escala `1x/2x`.
6. Executar `python tools/check_zm_design_system.py --check-changed --base origin/backup` e testes Flutter relevantes. Nenhum sucesso no analisador comprova fidelidade visual; goldens precisam de referência e revisão, nunca `--update-goldens` para esconder erro.
7. **Não reescrever backend, IDs, formas de pagamento ou regras financeiras** para adaptar aparência.

## 6. Estratégia de migração automática e segura
1. **Central:** consolidar os componentes existentes e adicionar pesquisa/filtros/chips/status/diálogos ausentes.
2. **Reuso imediato:** migrar grupos de buscas/chips nas páginas Clientes, Produtos, Compras e Vendas via componentes únicos, sem mudar suas consultas.
3. **Financeiro:** padronizar Pagar/Receber e `ReviewedPaymentView` com filtro recolhível e calendário FE-052; preservar históricos, contas e categorias.
4. **Formulários:** Produto, Cliente, Compra, Venda, Cestas; usar modelo de formulário com campos compostos.
5. **Documentos/relatórios/exceções:** extratos, PDFs, importações, Configurações; auditar controles especiais.
6. Para cada migração, medir código removido (duplicação), evidência visual, estados, backend preservado e zero violações novas.

**Estado desta entrega:** contrato versionado, taxonomia, inventário, instrução de agente e fiscalização incremental de código; **não é migração das 38 views nem homologação raster completa**. A `backup` permanece intacta.
