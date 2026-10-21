# Retomada curta: corrigir a importação de faturas

**Atualização:** 20/10/2026. A Etapa 1 do [plano de correção](PLANO_CORRECAO_E_USABILIDADE_IMPORTACAO_PDF.md) foi implementada, verificada e ativada para uso local. Migração Alembic `f39a012b2159`; Release Windows **1.0.5+10** no diretório padrão. O backend HTTPS local está ativo e respondeu com saúde da API e do banco.

Antes da migração foi criado e validado o backup `backend/backups/estoque_backup_before_e1_activation_20261021_021954_491572.db`. Comparação pós-migração confirmou as 57 tabelas anteriores sem mudança, integridade `ok`, nenhuma violação FK e backfill de 1 entrada ativa/6 retiradas. O pacote anterior permanece em `tmp/release-backup-before-e1-283de47721524f7b8947c4fdeacb6866/Release`.

O pacote novo contém 16 arquivos e informa `1.0.5+10`; a sobra `kernel_blob.bin` de 17/10 não foi incluída. As Etapas 2–4 do plano corretivo continuam pendentes. T15 ainda aponta um `CheckboxListTile` sem `Material` intermediário; revisão visual nativa integral permanece pendente.

[Guia E1](IMPORTACAO_FATURAS_E1.md) e [guia de Pagar/E2–E4](CONTAS_A_PAGAR.md).

## Entrada e próximo trabalho

Cumprir a ordem canônica de [AGENT_INSTRUCTIONS.md](../AGENT_INSTRUCTIONS.md).
Depois ler [escopo](ESCOPO_IMPORTACAO_DE_FATURAS.md) e o trecho da etapa vigente
no [plano único](PLANO_IMPLEMENTACAO_IMPORTACAO_FATURAS.md). A
[auditoria](AUDITORIA_FATURAS_FORNECIDAS_2026-10-19.md) é a referência dos achados;
não refazê-la inteira só para recuperar contexto.

**Próximo passo:** disponibilização da Etapa 1 concluída. As etapas corretivas 2–4 aguardam autorização e escopo próprios; nenhuma delas faz parte desta ativação. A avaliação visual nativa e a correção T15 permanecem pendentes. Uso/exclusão/reimportação: [guia de Pagar](CONTAS_A_PAGAR.md#excluir-e-reimportar-uma-importação--e57). A reforma visual global fica em outra conversa.
| Etapa | Estado | Saída esperada |
| --- | --- | --- |
| E1 | Concluída e ativada na base de testes | Origem, linhas, parcelas, controles/procedência; guia E1 |
| E2 | Concluída e ativada na base de testes | Fatura única, itens, crédito, composição, pagamento e estorno |
| E3 | Concluída e ativada na base de testes | Formatos fornecidos, conferência guiada, enriquecimento e filtros com total completo |
| E4 | Concluída e ativada na base de testes | Próximas parcelas e substituição sem duplicidade |
| E5 | E5.7 entregue e ativada; uso nativo final ainda não observado | Preservar os critérios e limites; não declarar aceite integral sem evidência |

## Decisões a conservar

Implementado na E2: uma cobrança líquida por ciclo em `accounts_payable`,
com todas as compras/créditos/parcelas atuais acessíveis em
campos próprios; não somar total e itens. Finalidade econômica desconhecida não
impede catalogar dívida comprovada nem vira despesa empresarial presumida.

Detalhe divergente não pode ser declarado balanceado: a cobrança pode usar total
comprovado/conferido, mantendo detalhe pendente e diferença explícita. Vencimento
conflitante impede ativar cobrança até decisão registrada. Resumos não produzem
compras ausentes; histórico não é automaticamente dívida em aberto. Projeções
restantes são separadas dos títulos confirmados e substituídas pela próxima fatura.

Sem ajuste de centavos, pagamento/estoque fictício, finalidade por nome de loja,
API de IA por pressuposto ou módulos extras. Proteger vínculos com compras e
pagamentos já existentes. Detalhes e limites: decisões D1–D8 do plano.

## Mapa de leitura por etapa

| Etapa | Ler/alterar principalmente |
| --- | --- |
| E1 | `backend/app/services/financial_readers.py`, `financial_pdf_readers.py`, `financial_previews.py`; schema `financial_readers.py`; `client/lib/views/financial_imports_view.dart` (`_pickDocument`, `_suggestReader`), serviço de importação |
| E2 | Modelos/schemas `financial_imports.py`, `financial_bill_semantics.py`, `financial.py`; serviços correspondentes e `business_dashboard.py`; APIs `financial_imports.py`/`payables.py`; migrações; revisão da fatura e Pagar no Flutter |
| E3 | Leitores/segmentos E1, serviço de ciclos E2; views de importação/cabeçalho/revisão/Pagar; `payable_filters_panel.dart`; modelo/serviço de títulos; l10n |
| E4 | Novo serviço de agenda e migração; integração de ciclos e consulta financeira existente; não reutilizar divisão de valor total/+30 dias para parcela importada |
| E5 | `HOMOLOGACAO_IMPORTACAO_FINANCEIRA.md`, matriz da seção 6 do plano, critérios T01–T16, evidências privadas e guias de ativação existentes |

As localizações completas e contratos estão nas seções 4–5 do plano. Usar `rg`
por símbolos, não abrir todo o repositório. Conferir diferenças locais antes de
editar; há trabalho anterior modificado/não commitado que deve ser preservado.

## Evidência reutilizável e ponto de partida

- Sanitizada: [resultado da auditoria](validacoes_financeiras/arquivos-fornecidos-2026-10-19/resultado.json).
- Privada/ignorada: `tmp/audit-user-files-20261019/LEIA_ME.md`,
  `manifest-private.json`, `independent-private.json`, `api-private.json`,
  `ui-observations.json`, `final-checks.json` e capturas. Se a pasta tiver sido
  limpa, recuperar originais autorizados; não fingir que fixtures sintéticas os substituem.
- São 19 arquivos/18 conteúdos; sete CSVs são metadados, não compras. Dois CSVs
  detalhados: 21/13 linhas corretas, 9/3 parcelas no texto ainda não estruturadas.
  PDFs bancários: 39/22 linhas corretas, diferenças -6/+2 centavos, data 24/26 em outubro.
- Auditoria inicial em base isolada: zero títulos/caixa/estoque. Naquela rodada não houve migração ou
  importação na base principal. Seletor nativo e janela Windows não foram pilotados.
- Baseline anterior à E5: schema `fe4b5c6d8714`, 48 tabelas;
  488 testes backend/367 Flutter e análise limpa. Verificar estado atual antes
  de uso; esses números não homologam novas fontes nem comprovam importação final.
- Fontes anteriores: 136 arquivos Flutter iguais aos hashes da auditoria.
  Não reutilizar build antigo depois de alteração. Servidor isolado da auditoria
  foi encerrado; não usar suas credenciais no aplicativo principal.

## Verificação proporcional

No diretório `backend`, usar o Python do ambiente do projeto (`.venv/Scripts/python.exe`)
com `-m pytest` e os testes da etapa listados no plano; confirmar caminho do ambiente.
No diretório `client`, `flutter test` nos arquivos afetados; usar o Flutter configurado
no projeto/ambiente. Antes da entrega: suítes gerais, `flutter analyze`, migração
em cópia preenchida, API HTTPS e percurso de telas. Comandos que requerem acesso
fora da sandbox seguem o mecanismo de aprovação do ambiente, sem contorná-lo.

Não executar build/suítes só porque um plano ou texto mudou. Não repetir todos
os testes após sucesso sem novas mudanças ou preocupação não resolvida.
Arquivos privados não entram em fixtures públicas ou no log do chat. Comparar
localmente e retornar apenas diferenças, aliases e resultado sanitizado.

## Estado curto a atualizar ao concluir um incremento

Este é o único arquivo de andamento desta implementação. Atualizar a tabela
acima e substituir o estado curto abaixo ao concluir um incremento relevante,
transferir o trabalho ou parar com pendência. Não acrescentar um diário de ações.
Normalmente usar 5–10 linhas, sem reproduzir o plano ou logs completos:

1. Item E executado e decisões D mantidas/alteradas, com motivo se mudou.
2. Arquivos/contratos/migração e versão do leitor alterados.
3. Testes T aprovados, comandos/ambiente e limites observados.
4. Amostras integrais, com detalhe pendente ou somente evidência.
5. Próximo item concreto e impedimento real, se existir.

Memória financeira e índice já apontam para este arquivo; não os atualizar por
rotina a cada incremento. Alterar guia funcional/arquitetura apenas quando mudar
o comportamento/contrato correspondente, de forma localizada. Não criar outro
relatório para repetir este andamento. Preservar evidências necessárias nos locais
próprios e referenciá-las quando útil.
Pesquisa adicional apenas por dúvida nova, com fonte primária e aplicação registrada.
Esta disciplina reduz redescoberta; não promete uma quantidade exata de tokens.

### Estado curto vigente

Etapa 1 do plano corretivo ativada: entrada e geração independentes do cache de bytes; upload não reativa retirada; lista consulta raízes ativas; abertura não cria prévia; comandos importados exigem identidade e geração. Cliente preserva estado confiável em falhas parciais.
Migração `f39a012b2159` aplicada somente após backup validado. As 57 tabelas anteriores mantiveram contagens e hashes; integridade `ok`, zero violações FK, 1 entrada ativa e 6 retiradas legadas mantidas. Backend HTTPS local respondeu `200/ok` com banco `ok`.
Release Windows **1.0.5+10** compilado no diretório padrão, 16 arquivos, `app.so` AOT presente e sobra JIT antiga removida. Backup do Release 1.0.5+9 preservado em `tmp/release-backup-before-e1-283de47721524f7b8947c4fdeacb6866/Release`.
Verificação anterior à ativação: 28 testes backend; 31 testes Flutter e regressões direcionadas T05 (2), E56 (3), E3 T07 (2); análise Dart de nove arquivos sem issues. Não foi repetida a suíte completa.
Pendências: T15 do ciclo reproduz falha visual antiga sem `Material`; avaliação visual nativa completa não feita. Etapas corretivas 2–4 não executadas; requisito de saldo anterior continua pendente. Base do app com migração ativa; Release anterior preservado para recuperação.
## E1 concluída — 19/10/2026

**Autorização:** usuário pediu E1 inteira (E1.1/E1.2/E1.3), com código/testes,
antes de E2. Após interrupção, confirmou retomar de onde parou. Alterações locais
anteriores, inclusive não rastreadas, foram preservadas. Nenhum novo plano geral.

**Entrega:** origem escolhida mantida ao selecionar/trocar arquivo; `csv_auto`
detecta conteúdo antes do adaptador. Mercado Pago/PicPay fornecidos ficam como
índices, sem leitor de conta forçado ou fallback pelo banco. Origem declarada
pode desempatar adaptadores somente depois de conferir cabeçalhos compatíveis,
inclusive namespace PF/PJ de conta Nubank; sem ela, a ambiguidade permanece.
Normalizador compartilhado CSV/PDF estrutura parcelas e papéis, mantendo
texto/sinal/centavos e `purpose=UNSPECIFIED`. Total/mínimo/oferta/subtotal têm
procedência distinta; soma calculada não é total declarado. Os dois vencimentos
de outubro são conservados e mostrados com página, sem escolher um deles.

**Contratos/arquivos:** schema `financial_readers.py`; serviços de leitores,
prévias, novos `financial_normalization.py`/`financial_preview_contract.py`;
importação e cabeçalho no Flutter, serviço e l10n. Resultado tipado com
`contract_version=1` e `readiness.version=1`. Versões: `csv_auto` 1, `pdf_auto` 3,
`generic_csv` 4, adaptadores CSV conhecidos 3. Complemento por
`control_preview_id`/`cycle_due_on` conserva documento/versão e declaração,
exige origem/ciclo compatíveis e não certifica detalhes. Campos extraídos não
podem ser sobrescritos na confirmação. Sem nova migração ou alteração de schema.
D1–D8 mantidas; não foi necessária pesquisa adicional.

**Verificação:** baseline 488 backend/367 Flutter. Final **512 backend/373
Flutter**, análise estática sem pendências; seis testes de cabeçalho passaram
novamente após o ajuste final de texto. T01–T07 verificados no alcance E1:
origem/ambiguidade, fatos exatos, parcelas válidas/inválidas, campos ausentes,
papéis sem finalidade, diferença de um centavo, controles e vencimentos.
Comandos usados no ambiente do projeto:

- Raiz: `backend/.venv/Scripts/python.exe -m pytest backend/tests -q --basetemp=tmp/pytest-e1-final2`.
- `client`: `flutter test --concurrency=1 --dart-define=PDF_IMPORT_CAPTURE=true`.
- `client`: `flutter analyze` e teste específico `financial_header_review_test.dart` após orientação final.
- Verificadores privados ignorados: `tmp/validate_e1_sources.py` e
  `tmp/verify_e1_https.py`; resultados públicos somente sanitizados.

A sandbox impediu o diretório temporário inicial; testes usaram diretório
próprio no projeto e execução aprovada pelo ambiente. As primeiras falhas após
mudança de versão eram expectativas antigas, corrigidas antes da suíte final.
Os 14 avisos de depreciação backend anteriores permanecem.

**Amostras:** hashes iguais à auditoria; PDF06 mantém 28 movimentos; PDF07/08
mantêm 39/22 linhas exatas e 3/2 parcelas. CSV05/06 mantêm 21/13 linhas exatas e
9/3 parcelas. Diferenças −6/+2 centavos continuam explícitas; outubro conserva
24/26. CSV04/09 são índices, sem compras individuais. Conferência de campos
reutilizou a referência independente privada; para CSV, o tokenizer compartilhado
não constitui prova independente da tokenização. Não foi refeita a auditoria dos
19 arquivos. [Resultados sanitizados](validacoes_financeiras/e1-2026-10-19/amostras-sanitizadas.json).

**HTTPS real isolado:** servidor temporário, certificado descartável confiado e
worker PDF em processo separado. As sete entradas afetadas passaram pelo
contrato novo, com reenvio reutilizado. Livros inalterados, zero títulos,
`integrity_check=ok` e `foreign_key_check` vazio. Schema fe4 instalado apenas
no banco descartável, sem nova migração da E1 ou migração no banco da empresa.
[Relatório HTTPS](validacoes_financeiras/e1-2026-10-19/https-sanitizado.json).
Servidor temporário encerrado; instalação principal não foi ativada/atualizada.

**Revisão visual agrupada:** Flutter com dados fictícios; duas datas e páginas
legíveis, confirmação bloqueada, larguras 320/390/1200 e texto ampliado nas
verificações existentes. [Captura sintética do conflito](validacoes_financeiras/e1-2026-10-19/vencimentos-sinteticos.png).
Sem piloto de seletor nativo Windows ou certificação em aparelhos físicos.

**Limites e próximo passo:** E1 não cria cobrança líquida, não resolve efeito
em lucro dos itens sem finalidade e não agenda parcelas futuras. T05/T06 no
percurso financeiro completo dependem de E2; conferência guiada/decisão operacional
de vencimento ficam nas próximas etapas. Complemento hoje é contrato de API/serviço,
sem seletor guiado novo na tela. E2 é o próximo trabalho concreto, sem repetir
esta etapa nem instalar a versão antes do recorte correspondente.
