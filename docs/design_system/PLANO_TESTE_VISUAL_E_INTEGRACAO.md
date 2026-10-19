# Gates de qualidade — plano de validação VISUAL e de integração

## Ordem fixa, não negociável
`pesquisa + FE-052 -> decisão classificada -> token/componente implementado -> testes estruturais -> captura Flutter -> comparação FE-052 -> homologação -> migração controlada -> build`.

## O que cada artefato prova
- `PORRA.zip` / FE-052: referência visual/interativa aceita; **não garante que o Dart a reproduz**.
- `tokens.json`: inventário de valores/autoridade; **não são estilos Flutter compiláveis**.
- `components.json`: catálogo de APIs candidatas; **não é biblioteca executável**.
- `views.json`: inventário de arquivos; **não é inspeção de estados visuais de cada rota**.
- Testes Python/CI verde: integridade e restrições textuais incrementais; **não é visual**.
- Flutter `flutter analyze`: código Dart estático; **não é fidelidade FE-052**.
- Golden: comparação com **baseline explicitamente aprovada** em ambiente controlado; **nunca criá-la automaticamente como prova de aprovação**.
- Build Windows/Android: aplicativo executa/compila; **não prova que o design está correto**.

## Escopo de validação necessário antes de dizer “padronização concluída”
1. **Controles:** Header/PageTitle, Search, CompactFilter (fechado, aberto, 0/1/n filtros, limpar/aplicar), DateField/Calendar (mês, seleção, cancelar, foco), Choice Integral/Parcial, MoneyField, status chips, Primary/Secondary actions, record rows, cards, dialogs, loading/empty/error/offline/stale.
2. **Configurações:** 320/390/430 px mobile e ~1100 px desktop, temas claro/escuro, escala textual 1.0/1.5/2.0, navegação inferior/lateral, preferir redução de movimento.
3. **Fluxos:** iniciar, pagar e receber com dados simulados/contas reais mockadas; seleção de datas válidas, revisão, cancelar, estados de falha; cadastro/lista/detalhe operacionais sem alterar dados.
4. **Comparação:** toda tela com equivalente FE-052 deve ter comparação lado a lado em viewport, dados, tema, DPI, fonte e estado equiparados, com notas de diferença, evidência e aprovação registrada. Telas sem correspondente FE-052 usam gramática canônica e são revisadas, nunca declaradas “pixel-perfect FE-052”.
5. **Code review:** proibir novo estilo local fora do design system; componente novo = ID, contrato, estados, exemplo, testes, semântica e exceção justificada.
6. **Regression gate:** novo teste failing adicionado deliberadamente deve bloquear PR; depois corrigir código e confirmar que regra volta a passar. Não encobrir bugs ampliando exceções.

## Estado atual documentado
- Branch `visual-audit/backup-20261019` foi criada da `backup` e executou testes de UI existentes no Windows: 43 testes passaram (GitHub Actions run `39203246250`). Capturas são da baseline, **não desta futura biblioteca**. Em Linux a rodagem apontou divergências sob texto 2x; podem variar por fontes/plataforma, exigindo testes em ambiente controlado.
- Branch `design-system/canonical-backup-20261019` contém regras/contrato e CI de integridade. **Sem widgets Flutter novos, sem preview novo e sem golden homologada**.
- O usuário quer visualizar **o resultado real após a integração**, não um screenshot parcial anunciado como padrão concluído.

## Procedimento seguro
Fase A = Codex audita em modo leitura. Fase B = aprovação explícita para migrar. Fase C = publicar screenshots e pacote compilado da branch de migração para revisão, sem substituir a versão principal. Somente depois decidir merge. Manter lista de regressões e plano de rollback para cada lote.
