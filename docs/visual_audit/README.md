# ZM — Etapa 1B: auditoria visual (branch backup)

**Finalidade:** executar o Flutter em um runner Linux e exportar screenshots dos testes já presentes em `client/test`, sem alterar a aparência nem o fluxo de produção.

Referência visual: FE-052 original e decisões aprovadas de `docs/REFERENCIA_ATUAL_FRONTEND.json` e `docs/INTEGRACAO_INTERFACE_APROVADA.md`. O código atual em `client/` serve somente de objeto de auditoria; ele não define a referência aprovada.

**Escopo deste primeiro lote:** capturas de navegação e estados previstos em `approved_app_integration_test.dart` e capturas financeiras criadas pelos testes existentes, quando houver. Isso NÃO cobre todas as 38 views. Os testes funcionais não constituem prova de fidelidade.

**Como recuperar as evidências:** GitHub > Actions > `ZM visual audit from backup` > execução > Artifacts > `zm-backup-visual-evidence` (se houver imagens).

**A homologação exige:** catálogo de cenários de TODAS as telas reais e estados importantes, dados previsíveis, temas/clocks/fonts/viewport controlados, screenshots atuais + FE-052 quando houver equivalente, relatório de diferenças e uma revisão humana dos casos não comparáveis. Não atualizar imagens golden automaticamente para apagar discrepâncias.

**Isolamento:** commit e execução somente na branch `visual-audit/backup-20261019`. Nunca mesclar automaticamente com `backup` ou `master`.

Estado: **PILOTO DE CAPTURA**; não classificar como homologação visual completa.
