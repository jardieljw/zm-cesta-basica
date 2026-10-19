# Auditoria independente do PR #2 — ZM Design System
Data: 2026-10-19. Status: **AUDITORIA DOCUMENTAL E DE CÓDIGO CONCLUÍDA; INTEGRAÇÃO BLOQUEADA**.

## 1. Prova da branch correta e do isolamento
- Repositório: `jardieljw/zm-cesta-basica`.
- `master` (front antigo/original): commit `2717066092a6d6e3dd493a8ab674f3b6e773ff0f`.
- `backup-2026-10-12` (histórica): commit `6efab8349aa6ac490e0aeac657eb99681e27e1b5`.
- **`backup` (front atual, objeto da auditoria): commit `79c95cd35cfdf79c762513df866b072a3f700f03`.**
- **`design-system/canonical-backup-20261019`** foi criada a partir da `backup` correta; PR **#2** tem `base=backup`, `head=design-system/canonical-backup-20261019` e está **draft, não mesclado**.
- Antes desta revisão de auditoria, os 12 arquivos do PR eram apenas `docs/design_system/*`, `AGENTS.md`, `client/lib/AGENTS.md`, `tools/check_zm_design_system.py`, `tools/test_zm_design_system.py` e `.github/workflows/zm-design-contract.yml`. **Nenhum arquivo de frontend Dart, backend, banco, modelos ou serviços foi alterado.**
- A autoridade visual é FE-052, arquivo no `backup`: `docs/referencias_frontend/rodada-acabamento-2026-10-16/acabamento-integrado-zm.html`; SHA-256 `774f5bbce0ccbc8048818a2daa24531804619551432113795a00a6dbe4eaf53f`, conferido com `PORRA.zip`.
- A `backup` e a `master` não foram alteradas nesta auditoria.

## 2. Pesquisa profunda recuperada integralmente no nível documental
A pesquisa original, **Padronização do frontend ZM para trabalho confiável com IA**, está em `research/DEEP_RESEARCH_ORIGINAL_2026-10-18.md`. A cópia original bruta do relatório da Library foi preservada fora do GitHub; o arquivo do repositório é a transcrição de texto fornecida pelo leitor do relatório. Para prova de bytes, usar o arquivo original extraído da Library, não presumir que formatação/citações sejam bit a bit idênticas.

**Lição central da pesquisa:** documentação e arquivos `AGENTS.md` não substituem tokens tipados, widgets efetivos, composições obrigatórias, exemplos reais, golden tests e CI bloqueante. Sem essa cadeia, o agente pode improvisar uma página mesmo após ler o contrato.

## 3. Auditoria por dimensão
| Dimensão | Existe no PR | Resultado | O que falta / critério de conclusão |
|---|---|---|---|
| Branch base e rastreabilidade | Sim | **PASSOU** | Confirmar SHA antes de cada migração se a `backup` avançar. |
| FE-052 autoridade | HTML no baseline e SHA fixado | **PASSOU (integridade)** | Não significa equivalência de todas as views Flutter. |
| Pesquisa original recuperada | Texto em `research/` | **PASSOU (acesso textual)** | Evitar tratar achados de pesquisa como UI implementada. |
| Tokens | `tokens.json` com 33 registros e origem/status | **PARCIAL** | Não são tokens tipados DTCG, não geram tema Dart, vários valores extraídos de CSS são **referências**, não aprovação global. |
| Fontes/tipografia | Papéis e medidas FE-052 no contrato | **PARCIAL** | Fonte nativa Flutter definitiva não homologada; validar font fallback, renderização e escala. |
| Cores, superfícies, raios | FE-028/030 e valores CSS | **PARCIAL** | Contrato existe, mas não obriga implementação Flutter a usar todos os papéis semânticos. |
| Componentes | `components.json` 20 famílias | **PARCIAL** | Catálogo descreve API pretendida, não fornece uma nova biblioteca pronta; `ZmSearchField`, filtro composto, status e diálogos permanecem lacunas. |
| Flutter existente | `approved_app_style.dart`, `approved_icon.dart`, `responsive_filter_bar.dart`, `reviewed_payment_view.dart` na `backup` | **REAPROVEITÁVEL SOB AUDITORIA** | Não reescrever sem necessidade; componentes com nome `Approved` não são automaticamente fiéis. |
| Padrões de página | `page_patterns.json` com 8 modelos | **PARCIAL** | Modelos são descrições, não templates Flutter obrigatórios nem um validador de composição. |
| Cobertura de páginas | `views.json` inventaria 38 arquivos de `views/` | **PASSOU (inventário de arquivos)** | Inventário não prova que cada rota/estado esteja acessível, compilado ou visualmente validado. |
| Pesquisa/filtros | Diagnóstico de implementações paralelas | **NÃO RESOLVIDO NO CÓDIGO** | Construir API visual comum e migrar usos sem alterar semântica dos filtros. |
| Data/calendário | `ApprovedCalendarDialog`, `ApprovedDateButton` no baseline | **NÃO PADRONIZADO NO CÓDIGO** | `ReviewedPaymentView` usa `showDatePicker`; botão canônico candidata coloca ícone à esquerda, FE-052 à direita; testar abertura/cancelamento/foco. |
| Estado/ícones/diálogos | IDs e regras gerais | **PARCIAL** | Falta única API visual de estados, catálogo de ícones e diálogo responsivo efetivamente consumido por todas as views. |
| Regras de agente | `AGENTS.md` raiz e `client/lib/AGENTS.md` | **PASSOU (instrução presente)** | Não garante obediência sem testes e análise do código alterado. |
| Fiscalização automatizada | Python + GitHub Actions | **PASSOU COMO DETECTOR INCREMENTAL LIMITADO** | Detecta padrões textuais adicionados em `client/lib/views/*.dart` contra `origin/backup`; **não verifica toda a árvore Dart, APIs de componentes, tokens em widgets compartilhados, AST nem visual**. |
| Testes Flutter do Design System novo | Nenhum código novo de widgets no PR | **NÃO APLICÁVEL / NÃO EXECUTADO** | Não existe UI nova no PR que possa ser certificada. |
| Goldens e contraste FE-052 | Capturas de testes existentes na branch visual-audit/backup-20261019 | **INCOMPLETO** | 43 testes funcionais Windows passaram em rodada anterior, mas capturas de algumas telas NÃO são equivalência certificada do design novo para as 38 views. |
| Build/preview do "frontend novo" | O PR não alterou telas Dart | **NÃO EXISTE** | Build desta branch mostraria apenas o frontend da `backup`, não um novo frontend produzido pelo PR; não anunciar como preview de UI nova. |
| Backend/modelos/API | Inalterados | **PASSOU (isolamento)** | Manter inalterados em qualquer integração visual. |
| PR pronto para mesclar | Draft | **BLOQUEADO** | Não aprovar nem mesclar até Codex comprovar integração segura e, para alterações visuais, goldens e revisão de interface. |

## 4. Evidências concretas de inconsistência, sem inferir culpa visual a partir de uma classe
1. `client/lib/views/payables_view.dart`: pesquisa local `OutlineInputBorder(radius=16)` diferente do campo de referência com raio 24; filtros e chips locais.
2. `client/lib/views/receivables_view.dart`: `ExpansionTile` com `ResponsiveFilterBar`, dropdown e chips diretos, apesar de filtro recolhível `ApprovedCollapsibleFilter` existir.
3. `client/lib/views/products_view.dart`: `ApprovedChoice` combinado com `ChoiceChip` direto; pesquisa montada localmente.
4. `client/lib/views/customers_view.dart`, `purchases_view.dart`, `sales_view.dart`: campos e filtros reimplementados localmente, sem API semântica única.
5. `client/lib/widgets/shared/reviewed_payment_view.dart`: `showDatePicker` + `OutlinedButton.icon`; ao lado, `ApprovedDateButton` usa `ApprovedCalendarDialog`. São dois caminhos para a mesma experiência.
6. `client/lib/views/reports_view.dart`, `purchase_form_view.dart`, `sale_form_view.dart`: campos de data e muitos estilos locais; formulários de cadastro possuem vários `Scaffold` próprios.

**A classificação é de duplicação/risco de consistência**; apenas testes renderizados equivalentes FE-052 confirmam divergência visual específica. Exceções necessárias (pareamento, visualizador PDF etc.) são possíveis e devem estar documentadas.

## 5. Falhas técnicas na fiscalização atual
- O guard verifica alterações **linhas adicionadas em `client/lib/views/`**, não alterações no Dart compartilhado: `client/lib/widgets` está incluído no comando diff, mas é ignorado no filtro Python.
- O verificador é textual, portanto admite falsos negativos: estilos passados por `Theme.of(...).copyWith(...)`, funções auxiliares, aliases, estilos desdobrados e novos componentes equivalentes com nomes diferentes.
- Alguns filtros e inputs legítimos poderão ser barrados em uma view sem que haja ainda um `ZmSearchField` real disponível. **O próximo passo é criar/compor um widget compartilhado e testar seu contrato**, não liberar exceção genérica.
- Não há validação de widgets contra FE-052, golden baseline aprovada, catálogo interativo ou cobertura sistemática de todas as 38 views.
- Um CI verde confirma apenas o escopo dos seus passos, não que o design de toda a aplicação foi padronizado.

## 6. Decisão para integração
**NÃO mesclar PR #2 na `backup` agora.** Preservar a branch de contrato como referência para revisão pelo Codex. O Codex deve executar primeiro a tarefa `INSTRUCOES_CODEX_AUDITORIA_SEGURA.md`, etapa AUDIT-ONLY. Se confirmar a viabilidade, propor migração incremental por famílias de widgets em nova branch derivada do estado atualizado da `backup`, preservando semântica e serviços. **Primeiro migrar controles compartilhados, depois as views, nunca o contrário.**

## 7. Critério final — o que será realmente "pronto"
Um design padronizado só estará completo quando os contratos mapearem componentes Dart e composições reais, o CI barrar desvios, os estados obrigatórios estiverem cobertos, as views relevantes usarem widgets compartilhados e as capturas mobile/desktop/claro/escuro forem confrontadas com a FE-052 e homologadas. **Nenhuma dessas exigências é substituída por um relatório bem escrito.**
