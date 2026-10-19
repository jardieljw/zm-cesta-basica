# Design System obrigatório para alterações em client/lib

Antes de editar QUALQUER view Flutter, leia:
1. `../../docs/design_system/CONTRATO_VISUAL_ZM.md` (a partir da raiz do repositório: `docs/design_system/CONTRATO_VISUAL_ZM.md`);
2. `docs/design_system/tokens.json`, `components.json`, `page_patterns.json`, `views.json`;
3. referência FE-052 na pasta `docs/referencias_frontend/rodada-acabamento-2026-10-16/`.

**Usar componentes Approved* existentes primeiro.** Se não existir widget de pesquisa/filtro/status/diálogo canônico, implantar UM componente compartilhado com estados e contrato antes de copiar estilo em uma view. Jamais tratar a aparência do legado como fonte de verdade.

**Não introduzir** cores, tipografia, bordas, InputDecoration ou showDatePicker customizados em telas sem exceção documentada. O CI verifica as novas linhas. Reutilização de Backend, dados, localizações, controllers, permissões e jornadas é obrigatória. NÃO alterar dados do negócio para satisfazer desenho.

Registrar novas variantes no catálogo e testar claro/escuro, 320/390/430/1100px, escala textual e fluxos completos. Passar em testes funcionais não é aprovação visual. Nunca gerar goldens novos para encobrir diferenças.

Para código legado já diferente, siga `views.json` e corrija **por componente compartilhado**, não com 38 remendos independentes.

Antes de migrar qualquer tela, auditar com `docs/design_system/INSTRUCOES_CODEX_AUDITORIA_SEGURA.md` e `docs/design_system/PLANO_TESTE_VISUAL_E_INTEGRACAO.md`. A branch `backup` é a implementação atual; `master` é legado. O PR #2 atual é **contrato, não biblioteca Flutter nova**. Nem compilar o backup nem passar no lint prova que o frontend novo foi implementado.
