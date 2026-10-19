# ZM — Design System canônico (branch backup)

**Comece por [CONTRATO_VISUAL_ZM.md](CONTRATO_VISUAL_ZM.md).** Esta pasta NÃO é uma nova interface, não muda o visual atual e não substitui a referência FE-052. É a documentação **executável e versionada** que qualquer IA ou desenvolvedor deve obedecer ao manter e criar páginas.

- `tokens.json`: 33 tokens com valor, unidade, origem e nível de aprovação.
- `components.json`: 20 famílias de componentes, comportamento, estados, implementação real ou lacuna.
- `page_patterns.json`: 8 modelos de páginas.
- `views.json`: mapa operacional de **38 views** da `backup`, com prioridade e ação.
- `exceptions.json`: exceções explicitamente registradas (atualmente nenhuma).
- `tools/check_zm_design_system.py`: verifica SHA imutável da FE-052, integridade dos catálogos e detecta **novo estilo local** em alterações de views.
- `client/lib/AGENTS.md`: obriga Codex/IA a ler as regras ao trabalhar no frontend.
- Workflow GitHub Actions `ZM Design System contracts`: fiscaliza PRs para a backup.

## Como usar

Solicitar a qualquer agente: "Leia `client/lib/AGENTS.md` e `docs/design_system/CONTRATO_VISUAL_ZM.md`; identifique e reutilize o componente canônico. Se faltar, crie o widget compartilhado e o contrato antes de mudar qualquer view. Não mude serviços ou APIs."

## Diferença fundamental
**Spec + catálogo + lint de diff** evitam parte da deriva futura; **não migram automaticamente telas antigas** nem certificam um calendário nativo. As 38 views possuem débito conhecido em `views.json` e precisam ser migradas progressivamente por componente. A próxima migração recomendada é criar pesquisa/filtros compartilhados e fazer as primeiras telas adotá-los. Testes visuais e de interação seguem obrigatórios para o aceite.
