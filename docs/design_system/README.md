# ZM — Design System canônico (branch backup)

**Comece por [CONTRATO_VISUAL_ZM.md](CONTRATO_VISUAL_ZM.md).** Esta pasta NÃO é uma nova interface, não muda o visual atual e não substitui a referência FE-052. É a documentação **executável e versionada** que qualquer IA ou desenvolvedor deve obedecer ao manter e criar páginas.

- `tokens.json`: 33 tokens com valor, unidade, origem e nível de aprovação.
- `components.json`: 20 famílias de componentes, comportamento, estados, implementação real ou lacuna.
- `page_patterns.json`: 8 modelos de páginas.
- `views.json`: mapa operacional de **38 views** da `backup`, com prioridade e ação.
- `exceptions.json`: exceções explicitamente registradas (atualmente nenhuma).
- `tools/check_zm_design_system.py`: verifica SHA imutável da FE-052, integridade dos catálogos e detecta **novo estilo local**, calendários nativos, novos filtros, inputs, ícones e cascas independentes em alterações de views. É um detector textual incremental, não substitui revisão nem análise semântica.
- `client/lib/AGENTS.md`: obriga Codex/IA a ler as regras ao trabalhar no frontend.
- Workflow GitHub Actions `ZM Design System contracts`: fiscaliza PRs para a backup.

## Como usar

Solicitar a qualquer agente: "Leia `client/lib/AGENTS.md` e `docs/design_system/CONTRATO_VISUAL_ZM.md`; identifique e reutilize o componente canônico. Se faltar, crie o widget compartilhado e o contrato antes de mudar qualquer view. Não mude serviços ou APIs."

## Diferença fundamental
**Spec + catálogo + lint de diff** evitam parte da deriva futura; **não migram automaticamente telas antigas** nem certificam um calendário nativo. As 38 views possuem débito conhecido em `views.json` e precisam ser migradas progressivamente por componente. A próxima migração recomendada é criar pesquisa/filtros compartilhados e fazer as primeiras telas adotá-los. Testes visuais e de interação seguem obrigatórios para o aceite.

## Auditoria independente obrigatória e integração segura
- **[`manifest.json`](manifest.json)**: registra autoridade, status de implementação e gate de merge bloqueado.
- **[`AUDITORIA_INDEPENDENTE_2026-10-19.md`](AUDITORIA_INDEPENDENTE_2026-10-19.md)**: confronta Deep Research original com a entrega efetiva, explicitando o que é apenas contrato.
- **[`INSTRUCOES_CODEX_AUDITORIA_SEGURA.md`](INSTRUCOES_CODEX_AUDITORIA_SEGURA.md)**: tarefa pronta para Codex auditar a viabilidade do PR **SEM ALTERAR** a backup.
- **[`PLANO_TESTE_VISUAL_E_INTEGRACAO.md`](PLANO_TESTE_VISUAL_E_INTEGRACAO.md)**: gate para testes de Flutter, capturas e futura migração.
- **[`research/DEEP_RESEARCH_ORIGINAL_2026-10-18.md`](research/DEEP_RESEARCH_ORIGINAL_2026-10-18.md)**: transcrição textual do relatório Deep Research recuperado da Library. Texto original integral em formato bruto também foi preservado como artefato independente.

**Não marcar como pronto para mesclar**: atualmente não há widgets Flutter novos, catálogos Widgetbook, novos goldens homologados ou migração das 38 views. O CI existente é só a primeira camada de fiscalização de estilos adicionados em `views/`.
