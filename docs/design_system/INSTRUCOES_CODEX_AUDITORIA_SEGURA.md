# Tarefa para o Codex — Auditoria de viabilidade e integração segura do Design System ZM

## Identidade e objetivo
Você está no repositório `jardieljw/zm-cesta-basica`.
- **Projeto operacional atual:** branch **`backup`**. Não é `master`, `backup-2026-10-12` nem outra branch. Verifique HEAD e remote: no início a `backup` era `79c95cd35cfdf79c762513df866b072a3f700f03`, mas pode ter avançado.
- **Contrato em avaliação:** branch `design-system/canonical-backup-20261019`, PR #2 **draft** comparado à `backup`.
- **Visual aprovado:** FE-052 em `docs/referencias_frontend/rodada-acabamento-2026-10-16/acabamento-integrado-zm.html`, SHA256 `774f5bbce0ccbc8048818a2daa24531804619551432113795a00a6dbe4eaf53f`.
- **Pesquisa metodológica ORIGINAL:** `docs/design_system/research/DEEP_RESEARCH_ORIGINAL_2026-10-18.md` (na branch do contrato).
- **Auditoria do trabalho anterior:** `docs/design_system/AUDITORIA_INDEPENDENTE_2026-10-19.md`.
- **Arquivos canônicos propostos:** `docs/design_system/CONTRATO_VISUAL_ZM.md`, `tokens.json`, `components.json`, `page_patterns.json`, `views.json`, `exceptions.json`.
- **Código Flutter a preservar:** `client/lib/` da `backup`, especialmente `widgets/shared/approved_app_style.dart`, `approved_icon.dart`, `responsive_filter_bar.dart`, `reviewed_payment_view.dart`. Backend, banco e APIs **fora do escopo visual**.

## Fase A — SOMENTE AUDITORIA, sem alterar um arquivo do usuário
**Não mescle PR #2, não execute `git reset --hard`, não rebaseie a `backup`, não rode `--update-goldens`, não altere `master`, backend, contratos HTTP nem esquema SQLite.** Trabalhe em checkout/cópia descartável se precisar executar testes. Não implemente widgets nesta fase.

1. Confirme o `git rev-parse` real das branches e a base do PR #2. Demonstre que a origem é a `backup` correta e liste os arquivos alterados entre as branches. Registre se houve algum arquivo Flutter/backend afetado.
2. Leia integralmente a Deep Research e a hierarquia de autoridade do contrato. A pesquisa ensina o **método**, não determina sozinha a aparência. A FE-052 e decisões FE-028/030/049/052 determinam o visual.
3. Revise todos os registros em `tokens.json`, `components.json`, `page_patterns.json` e `views.json`. Verifique consistência com o código atual e distinga decisão aprovada de propriedade derivada de CSS. Confirme ou refute as 38 views mapeadas; procure widgets fora de `views/` e rotas ativas ausentes.
4. Para cada família de controle (título, cabeçalho, fonte, fundo, ícones, espaçamento, borda, pesquisa, filtro, chips, seletor, calendário, formulário, cartões, extrato, documento, loading, vazio, erro, diálogo, responsividade), informe **qual widget Dart existe**, qual regra canônica, onde há implementações paralelas, se pode ser reutilizado/adaptado/substituído e o risco de migração. Cite arquivos e linhas.
5. Investigue sem deduzir que `Approved*` é automaticamente fiel. Verifique FE-052 para filtros recolhíveis, estados de chips e seletores, posicionamento do calendário, comportamento de data civil, raios, tipografia e áreas de navegação. Separe comprovado de não especificado.
6. Audite a qualidade do guard `tools/check_zm_design_system.py` e dos testes: falsos positivos/negativos; teste mínimo de violação; compare com lint/AST e tokens tipados. Verifique se o `AGENTS.md` e o CI realmente obrigam consulta dos contratos.
7. Avalie **integração viável ou não** sem código de UI novo: compatibilidade com widgets existentes, ThemeData/ThemeExtension, localização, plataformas Windows/Android, dados/serviços, dependências, testes, riscos e rollback.
8. Se possível, em checkout descartável e sem alterar o histórico, execute `flutter pub get`, `flutter analyze`, testes existentes relevantes e `flutter build windows --release` em Windows. **O executável é da baseline atual backup**, porque o PR não tem nova UI. Não invente preview do Design System.
9. Entregue relatório com tabela **PASSOU / PARCIAL / NÃO FEITO / BLOQUEADO**, evidências por caminho e linha, diferenças concretas e proposta de integração **incremental por componentes**, sem substituir o aplicativo todo.
10. Identifique questões que realmente exigem decisão do proprietário, mas faça recomendações técnicas por conta própria quando a documentação/FE-052 resolver.

### Relatório obrigatório do Codex
Entregar `RELATORIO_CODEX_AUDITORIA_DESIGN_SYSTEM.md` com:
- SHA exata das branches;
- lista de arquivos alterados no PR;
- tabela de contratos e componentes reutilizáveis/não implementados;
- mapa de inconsistências nas 38 views e outras rotas;
- verificação de fonte/ícones/filtros/calendários/menus;
- cobertura por breakpoint `320,390,430,1100`, temas claro/escuro, escala `1.0/1.5/2.0`;
- testes realmente executados com logs, ou motivo concreto da impossibilidade;
- riscos/retrocompatibilidade/rollback;
- decisão `integrável sem regressões`, `integrável com correções` ou `não integrável`, sempre fundamentada.

### Fase B — SOMENTE APÓS o usuário autorizar
Criar nova branch isolada a partir da `backup` atualizada. Implementar biblioteca central de tokens Flutter / ThemeData / ThemeExtension, widgets compartilhados ausentes, contratos de composição e testes de widget/golden. Migrar telas **por grupo de componentes**, sem modificar serviços. Exigir CI e comparação de visual em 320/390/430/1100, claro/escuro, texto aumentado e estados de filtro/calendário/revisão. **Não publicar ou mesclar mudanças sem aprovação explícita.**

## Critérios de falha que devem impedir o aceite
- O PR foi comparado com `master` ou backup histórico;
- uma regra derivada foi apresentada como aprovação explícita;
- testes de Python foram confundidos com certificação visual;
- Flutter atual foi refeito inteiro desnecessariamente;
- uma view teve layout ad hoc inventado;
- mexeu em backend/contratos HTTP para corrigir aparência;
- faltam estados ou responsividade e a tarefa é considerada pronta;
- goldens foram atualizadas só para “ficarem verdes”.

**Resultado esperado AGORA: auditoria independente de viabilidade e relatório. Não integrar nem programar visual sem segunda autorização.**
