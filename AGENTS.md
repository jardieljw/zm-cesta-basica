# Orientação de entrada para agentes

Consultar e seguir [AGENT_INSTRUCTIONS.md](AGENT_INSTRUCTIONS.md), que contém
as regras do projeto e a ordem de leitura dos documentos canônicos.

Para planejamento e evolução do front-end, seguir também o **método de
planejamento da seção 8.1** do [manual](docs/ARQUITETURA_FRONTEND.md): prudência,
pesquisa direcionada, comparação de opções, confirmação de dúvidas relevantes e
registro contínuo. Retomar pela [memória do front-end](docs/MEMORIA_E_PESQUISAS_FRONTEND.md).
Agrupar ajustes simples para revisão visual; não gerar uma prévia a cada mudança.
Ao projetar conteúdo, indicadores ou orientação ao usuário, ler a documentação
específica de [design inteligente](docs/DESIGN_INTELIGENTE_E_ORIENTACAO_AO_USUARIO.md):
usar dados para interpretar, antecipar necessidades e apresentar informações
úteis no lugar e momento certos. Preservar sua fundamentação detalhada.

Para importação e conciliação financeira, retomar pela
[memória financeira](docs/MEMORIA_IMPLEMENTACAO_FINANCEIRA.md) e pelo
[procedimento de homologação](docs/HOMOLOGACAO_IMPORTACAO_FINANCEIRA.md).

## Design System (obrigatório em client/lib)
Antes de alterar qualquer interface, consulte `client/lib/AGENTS.md` e `docs/design_system/CONTRATO_VISUAL_ZM.md`. Reutilize os componentes canônicos; fonte FE-052, não a aparência inconsistente da backup.

## Contrato canônico e auditoria antes de integrar (PR #2)
Comece por `docs/design_system/manifest.json` e `docs/design_system/CONTRATO_VISUAL_ZM.md`. A pesquisa profunda integral está em `docs/design_system/research/DEEP_RESEARCH_ORIGINAL_2026-10-18.md`. O estado real e limites desta branch estão em `docs/design_system/AUDITORIA_INDEPENDENTE_2026-10-19.md`. Para revisar compatibilidade com a `backup`, execute primeiro a tarefa SOMENTE-LEITURA em `docs/design_system/INSTRUCOES_CODEX_AUDITORIA_SEGURA.md`. Não mescle PR #2 nem reescreva Flutter/backend sem autorização posterior.
