# Funcionalidades arquivadas

Atualizado em 13/10/2026. Esta pasta guarda funcionalidades retiradas do
aplicativo por decisão do usuário. Não importar seus serviços ou telas em
`lib/` nem recolocá-los no menu sem uma solicitação de restauração.

**Atualização do dashboard:** o painel e os pagamentos foram simplificados para
controle da empresa, sem saldos de conta, caixa ou projeção de tesouraria.
Consulte [DASHBOARD.md](DASHBOARD.md) e `dashboard_manifest.json` para os novos
arquivamentos e os cálculos ativos. Esta atualização substitui as referências
abaixo à consulta de contas no aplicativo: o modelo e o serviço de contas
financeiras também foram arquivados. O vínculo interno dos pagamentos continua
no backend para compatibilidade, sem seleção pelo operador.

## Organização

**Integração nova autorizada — 14/10/2026:** o cliente ativo oferece montagem
padrão e histórico dentro de Tipos de Cesta. Seus arquivos novos não importam
este arquivo de serviços/modelos/telas. O conteúdo arquivado permanece preservado;
não considerar a integração como restauração completa do módulo antigo. Ver
[Montagens e histórico](../../docs/MONTAGENS_E_HISTORICO.md).

| Local | Conteúdo |
| --- | --- |
| `views/` | As oito telas arquivadas anteriormente: produção, desmontagem, expedição, conferência, responsáveis e tesouraria. |
| `services/` | Clientes de API exclusivos dessas telas: produção, expedição e tesouraria completa. |
| `models/` | Modelos exclusivos de lotes, expedição, lançamentos e contas financeiras, além do dashboard anterior. |
| `l10n/removed_app_pt.arb` | Textos e metadados de tradução retirados do catálogo ativo. |
| `snapshots/2026-10-13/` | Cópias anteriores dos arquivos modificados (`.snapshot`) e mudanças por arquivo (`.patch`). Incluem os trechos retirados de arquivos compartilhados. |
| `manifest.json` e `dashboard_manifest.json` | Registro de cada etapa: caminhos originais, arquivos movidos, hashes SHA-256 dos snapshots e patches. |

Os snapshots preservam arquivos inteiros para dar contexto aos trechos. Não são
uma segunda implementação executável nem devem substituir automaticamente os
arquivos ativos. Os patches mostram precisamente quais trechos foram retirados
e quais adaptações foram necessárias.

## O que foi retirado do aplicativo

- Seleção de venda em rota, consulta de saídas abertas e saldo sob custódia no
  formulário de venda. Novas vendas pelo aplicativo usam `DIRECT_STORE`.
- Opções de relatórios de montagem e de conferência de saídas/repasses.
- Formulário de saídas/custódia e colunas Trânsito/Total na tabela de cestas do
  dashboard. O saldo exibido é o disponível na loja; não soma mercadorias em trânsito.
- Serviço completo de tesouraria e consulta compartilhada de contas. Pagamentos
  usam o vínculo interno padrão no backend, sem pedir saldo ou conta ao operador.
- Textos ligados ao código arquivado sem referência no código ativo ou nos testes.

O relatório ativo de vendas usa a API existente com `include_dispatches=false`:
inclui vendas históricas, inclusive vendas antigas de rota, mas não mistura
transferências físicas com vendas. Tela, PDF e CSV/XLSX usam o mesmo filtro.

## Dependências preservadas deliberadamente

Não foram removidos tabelas, migrações, movimentações, dados ou endpoints. Os
serviços do backend de produção, custódia e financeiro continuam disponíveis
porque sustentam regras compartilhadas, históricos e futura restauração.

- A montagem durante a venda permanece ativa e usa o motor de produção.
- Compras, pagamentos, recebimentos e DRE usam contas e livro-caixa.
- Modelos de vendas, recebíveis e estoque conservam os campos históricos
  de lotes e custódia para ler os registros existentes sem perda de informação.
- Os testes de modelos arquivados continuam executando: importam os modelos
  de `../_archive/models/` como fixtures de compatibilidade, sem imports do aplicativo.
- Textos usados por testes existentes permanecem no catálogo para manter essa
  cobertura. Isso não disponibiliza botões ou rotas no aplicativo.

Arquivar a interface não bloqueia chamadas diretas à API. Uma futura desativação
de endpoints deve ser planejada separadamente, considerando compatibilidade,
dados em trânsito e dependências dos fluxos ativos.

## Como restaurar

1. Escolher a funcionalidade e revisar suas dependências na tabela abaixo.
2. Executar os testes do backend e Flutter antes de editar e conferir o Git.
3. Copiar apenas os modelos/serviços necessários de volta para seus caminhos
   originais em `lib/`. Ajustar imports relativos conforme a nova localização.
   O manifesto e os snapshots preservam os caminhos e imports originais.
4. Restaurar as telas escolhidas em `lib/views/`. Os imports atuais das telas
   antigas foram preservados como recebidos; revisar os caminhos ao movê-las.
5. Usar os patches e snapshots para reaplicar os trechos em arquivos
   compartilhados, adaptando-os ao código atual. Não sobrescrever um arquivo
   inteiro se houver mudanças posteriores. `git apply --reverse --check`
   pode verificar um patch, mas não garante compatibilidade entre módulos.
6. Mesclar as chaves necessárias de `l10n/removed_app_pt.arb` em
   `lib/l10n/app_pt.arb`, incluindo os metadados `@chave` e placeholders.
   Executar `flutter gen-l10n`; não editar as classes geradas manualmente.
7. Reintroduzir a navegação em `home_view.dart` e as opções de relatórios/formulários
   somente para a funcionalidade escolhida. Ajustar os imports dos testes que
   passarem a verificar modelos ativos novamente.
8. Validar testes completos, `flutter analyze` e os fluxos no dispositivo.
   Atualizar documentação e este índice com o novo escopo.

| Funcionalidade | Dependências de restauração |
| --- | --- |
| Produção/desmontagem | `production_batch`, `production_service`, três telas de produção; traduções e menus. O motor do backend já existe. |
| Expedição/responsáveis | `dispatch`, `dispatch_service`, quatro telas; cadastro de responsáveis, saídas, retorno/perdas e conferência; traduções e menus. |
| Venda em rota | Expedição funcional, saldo `TRANSIT`, trechos de `sale_form_view.dart`; manter a baixa exclusiva da custódia. |
| Tesouraria | `cash_flow_entry`, `financial_account`, serviço completo e `treasury_view`; revisar os patches de seleção de contas nos pagamentos. |
| Relatórios/formulário de rota | Opções nos snapshots de `reports_view`, `blank_forms_view` e dashboard. A API preserva os relatórios originais e aceita `include_dispatches=true`. |

## Validação

Os testes prévios passaram: 183 backend e 95 Flutter. Os resultados posteriores
à limpeza estão registrados em `VALIDATION.md`.
