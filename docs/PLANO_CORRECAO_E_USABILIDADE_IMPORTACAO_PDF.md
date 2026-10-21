# Plano de correção e usabilidade da importação de PDF

**Data:** 20/10/2026. **Situação:** Etapa 1 implementada e ativada; Etapas 2–4 pendentes.
**Pedido:** revisar o percurso inteiro de PDF, corrigir os registros que reaparecem e o salvamento bloqueado, e tornar cada pendência compreensível e corrigível por qualquer pessoa.
**Execução:** a autorização do usuário cobriu a Etapa 1, incluindo migração e Release Windows. Nenhuma outra etapa foi executada.
**Esforço recomendado:** Alto nas etapas 1–2, pela identidade dos registros e pelas regras financeiras; Médio nas etapas 3–4 depois de estabilizar esses contratos. Não alterar o modelo/esforço da sessão automaticamente.

A Etapa 1 foi ativada após backup verificado. As 57 tabelas de dados anteriores permaneceram idênticas; a migração `f39a012b2159` criou o lifecycle com integridade `ok`. Release Windows `1.0.5+10` gerado no destino habitual. Testes direcionados passaram; a suíte completa e a revisão visual nativa não foram repetidas. T15 permanece pendente para a etapa visual. As etapas 2–4 continuam no plano, sem implementação nesta ativação.

## Como começar sem repetir a descoberta
## Como começar sem repetir a descoberta

Ler este plano inteiro uma vez e depois reler somente a etapa em execução. Consultar a retomada curta para o estado vigente. Usar os símbolos abaixo para localizar o código; números de linha são fotografias da auditoria e podem mudar.

1. [Instruções dos agentes](../AGENT_INSTRUCTIONS.md), seção de clareza didática e ordem canônica.
2. [Retomada financeira](RETOMADA_IMPORTACAO_FATURAS.md).
3. [Arquitetura do front-end, método 8.1](ARQUITETURA_FRONTEND.md), [referência vigente](REFERENCIA_ATUAL_FRONTEND.json) e [design inteligente](DESIGN_INTELIGENTE_E_ORIENTACAO_AO_USUARIO.md).
4. Somente o trecho do [plano original](PLANO_IMPLEMENTACAO_IMPORTACAO_FATURAS.md) ou dos guias funcionais necessário à dúvida concreta. E1–E4 já existem; este plano corrige seu uso e sua integração.

O agente implementador deve receber a etapa completa, os contratos comuns, sua lista de arquivos e seus critérios. Não receber apenas “melhore o PDF”. Preservar as modificações locais de outros trabalhos; o diretório contém alterações anteriores sem commit.

## Escopo e resultado esperado

Percurso comum: escolher o PDF e a conta/cartão, ler o arquivo, conferir apenas as informações necessárias e salvar com resultado inequívoco. Quando voltar à lista, a pessoa deve reconhecer o arquivo e saber se ainda está em conferência, se foi guardado sem cobrança ou se foi adicionado a Contas a Pagar.

Inclui lista/envio, senha, prévia/original, conferência da fatura, cabeçalho, documentos com várias faturas, revisão bancária/ocorrência, revisão de faturas anteriores e exclusão. Inclui consultas e estado do servidor que determinam o conteúdo dessas telas.

Preservar leitores, formatos aceitos, valores em centavos, papéis de linhas, controles/procedência, parcelas, títulos, pagamentos, estoque e auditoria existentes. Não expandir para bancos novos, IA, OFX, Gmail ou reforma visual geral. CSV compartilha infraestrutura: manter compatibilidade e testar os pontos compartilhados, sem abrir outra revisão de formatos.

A regra de didática e consistência passa a orientar todo o aplicativo por meio de AGENT_INSTRUCTIONS.md. A aplicação nesta entrega fica no percurso de importação; uma reforma de todas as páginas continua fora do escopo.

## Diagnóstico com evidência e limites

| Ref. | O que foi verificado | Implicação |
| --- | --- | --- |
| A | A cópia da base consultada contém sete arquivos binários distintos; todos os hashes armazenados correspondem ao conteúdo. Um arquivo tem cinco prévias, com fontes/versões e datas diferentes. | Arquivo armazenado, prévia de leitura e importação exibida não são a mesma entidade. Não contar prévias como PDFs novos. |
| B | Executando os serviços reais numa cópia em memória: cinco prévias visíveis → excluir → zero → enviar novamente os mesmos bytes → as mesmas cinco prévias visíveis. Foram criados zero arquivos e zero prévias nesse reenvio. | Há um defeito reproduzido no ciclo de visibilidade. store_document chama restore_document; removed=False volta a expor todas as prévias históricas pelo filtro de list_previews. |
| C | Enviar bytes de outro arquivo, na mesma reprodução isolada, não reativou o documento excluído usado no teste. | O defeito B não prova que quaisquer quatro PDFs distintos sejam restaurados juntos. Comparar IDs, SHA, geração e respostas no percurso real; não impor essa interpretação ao relato do usuário. |
| D | draft retornou zero replacement_candidates. A integração da prévia de cartão, com total extraído, vencimento explicitamente escolhido para o ensaio e confirmações necessárias, falhou em financial_bill_cycles.integrate, linha 268: carry>0 e zero decisões PREVIOUS_BALANCE. | A regra exige vínculo de saldo anterior mesmo quando não oferece título anterior elegível. O preenchimento da pessoa não consegue satisfazer esse estado. |
| E | Vinte títulos legados no recorte consultado estavam cancelados, zerados e retirados. A correção atual de hidden_payables já os elimina da exigência de legados. A falha D continua ocorrendo por outro ramo. | Não atribuir todo erro de vínculo à mesma causa. Ignorar retirados é necessário, mas não resolve a exigência impossível de saldo anterior. |
| F | _failureMessage e _targetForFailure da conferência agrupam códigos distintos sob a mesma mensagem sobre escolher uma conta. Com candidatos vazios, o quadro vermelho contém orientação, mas nenhum seletor. | O realce existe parcialmente; seu destino e sua explicação podem ser inexequíveis. |
| G | _preview na lista pode executar createPreview ao abrir uma leitura antiga. _load lista prévias e busca obrigações por fatura; algumas falhas são convertidas em listas vazias. | Abrir documento pode criar registro técnico. Falha de consulta pode parecer ausência de registros ou situação financeira diferente. |
| H | No cabeçalho, a confirmação impede _submit antes de validar os campos; período invertido usa aviso temporário. Segmentos, revisão bancária e revisão antiga também têm escolhas bloqueadas ou avisos sem alvo preciso. | Revisar o conjunto: uma correção somente na conferência principal deixaria a experiência inconsistente. |
| I | Existem duas prévias de arquivos distintos às 08:31:19 e 08:31:20. | A conclusão anterior de incompatibilidade entre cartão e banco baseada apenas no minuto estava errada. Não usar minuto, rótulo de origem, quantidade de linhas ou nome do arquivo como identidade. |

Os ensaios B–E não fizeram gravações na base do aplicativo. Eles comprovam os ramos descritos, não uma homologação da janela Windows nem o sucesso final da fatura. Os quatro cartões da primeira captura ainda precisam de correspondência exata no percurso integrado; não apagar ou “limpar” registros com base na aparência ou no nome de uma origem de homologação.

## Decisões para a implementação

### Identidade e exclusão

Adotar identidade persistida da importação visível, separada do binário e do cache de leitura. O arquivo continua armazenado uma vez por SHA. Uma importação tem uma geração, uma prévia raiz e, quando o conteúdo realmente contém várias faturas, seus segmentos.

Não corrigir com agrupamento Flutter, escolha indiscriminada da prévia mais recente, filtro por nome ou exclusão de históricos. Não exibir “cinco leituras” como solução do incidente. O estado ativo deve vir do servidor; a tela apenas apresenta esse estado.

### Primeira fatura com saldo anterior

Saldo anterior faz parte do total da fatura; não é uma segunda compra nem uma segunda cobrança.

- Se há título anterior ativo e elegível no app, exigir o vínculo correspondente antes de substituir/reunir esse saldo. Revalidar saldo e pagamento na transação.
- Se não há título anterior cadastrado nem sobreposição financeira pendente, permitir a primeira fatura pelo total confirmado, mantendo o saldo anterior como saldo inicial externo não classificado.
- Essa permissão exige confirmação explícita da pessoa de que o saldo ainda é devido e não está representado por outra conta cadastrada. Incorporar essa informação à confirmação final condicional, evitando outra página ou uma confirmação redundante.
- Se há histórico pago, vínculo incerto ou uma consulta necessária falhou, “zero candidatos” não autoriza presumir ausência de dívida. Explicar a situação real e oferecer o registro existente quando identificável.
- Pagamento impresso não registra pagamento no app. Não criar caixa, estorno, ajuste de centavos, estoque ou título anterior fictício.

Essa precisão corrige a aplicação excessivamente ampla de D6 do plano original; conserva a proteção contra duas cobranças do mesmo saldo.

### Didática, sem empobrecimento

Toda mensagem necessária ensina: o que aconteceu; qual dado/decisão está em questão; onde agir; como resolver; e o efeito sobre arquivo e cobrança. Usar exemplos e explicação adicional quando necessários. Não encurtar a ponto de retirar a informação que permite agir.

Usar tom adulto e respeitoso, compreensível mesmo por uma criança, sem infantilizar. Termos “prévia”, “ciclo”, “título legado”, “alocação”, “hash” e códigos de API ficam em detalhes técnicos quando indispensáveis. No percurso comum, usar arquivo, fatura, conta, valor, vencimento e saldo anterior.

### Consistência visual e de comportamento

Nenhuma página nova está prevista. Reorganizar as existentes e extrair apenas a apresentação repetida de feedback. A página continua responsável por associar o erro aos controles que realmente possui.

| Papel | Dono/referência |
| --- | --- |
| Página, navegação e cabeçalho | ApprovedPage/ApprovedHeader e referência vigente, preservando a barra e o contexto financeiro |
| Superfícies, seções, linhas | ApprovedSurface, ApprovedSectionHeader, ApprovedRow |
| Campos e seleções | Form, TextFormField, FormField/InputDecorator e InputDecorationTheme existentes; ApprovedField somente onde já é o contêiner correto |
| Calendário/data | Componentes de data aprovados de approved_app_style.dart, mantendo validação de formulário e locale |
| Ações | ApprovedPrimaryButton/ApprovedSecondaryButton ou o componente canônico aplicável, após conferir a referência; uma ação principal por decisão |
| Cor de erro | ColorScheme.error, errorContainer e onErrorContainer; texto/ícone além de cor |
| Texto de interface | app_pt.arb e geração de localizações, sem mensagens novas hard-coded |
| Erro de API | ApiException.details preservado; ApiErrorMapper para falhas comuns; tradução financeira por código/metadata sem perder o alvo |
| Grupo sem campo nativo | Apresentação compartilhada extraída dos mecanismos atuais de realce/aviso; página fornece alvo, chave e ação |

Não copiar os raios, paddings ou cores locais da conferência como se fossem uma escala global. Ler a referência vigente e os componentes reais. O cabeçalho financeiro é referência de mecanismo de Form/validator, não de toda sua aparência. O plano não aprova uma nova paleta ou “3D” diferente para cada controle.

## Contratos que as quatro etapas devem preservar

### Registro de importação e leitura

Implementação proposta: dois modelos de metadados, junto ao módulo financeiro existente:

- **FinancialImportEntry / financial_import_entries:** id, document_id, generation, state ACTIVE/REMOVED, root_preview_id, referências ao statement/revisão confirmados pela raiz, created_by/created_at, updated_at e informações auditadas de retirada/efeitos. Unicidade de (document_id, generation), geração positiva e índice parcial de uma entrada ACTIVE por documento. root_preview_id nesta tabela é a única autoridade da raiz.
- **FinancialImportEntrySegment / financial_import_entry_segments:** import_id, segment_key, preview_id, parent_preview_id e referências ao statement/revisão confirmados pelo segmento. Chave (import_id, segment_key), unicidade de (import_id, preview_id). Conter somente filhos; não repetir a raiz nesta tabela. O pai precisa ser a raiz ou outro segmento da mesma entrada; validar isso na transação e testar a integridade.
- FinancialDocument e FinancialImportPreview conservam identidade, bytes, resultados, hashes e imutabilidade. A geração não entra no hash do cache de leitura; outra geração pode reutilizar o resultado por root_preview_id, ou pela associação de segmento quando se tratar de filho.
- A retirada e os efeitos ficam associados à geração. Preservar integralmente financial_import_removals na migração como auditoria legada somente leitura após a ativação. Transportar seus efeitos comprovados para o baseline. FinancialImportEntry.state é a única autoridade operacional de visibilidade; state/hidden_payables/withdrawn_cycles/reinstate_cycle consultam os novos metadados. Não unir estados antigos e novos como autoridades concorrentes nem continuar gravando a tabela antiga.
- O backfill cria um baseline do estado comprovável atual; não inventa limites ou datas de gerações passadas que não possam ser reconstruídos.

Sequência obrigatória:

| Operação | Efeito permitido |
| --- | --- |
| POST documents | Guardar/reutilizar bytes e responder a identidade do arquivo; não reativar importação, prévia, conta ou previsão |
| Consultar estado de importação do documento | Informar geração atual, entrada ativa e raiz; leitura sem efeitos |
| Ler arquivo sem importação ativa | Preparar leitura fora da transação longa; na gravação atômica revalidar geração, persistir/reutilizar raiz e criar/ativar a nova entrada |
| Ler arquivo com entrada ativa | Retomar a entrada; mudar origem/interpretação exige ação explícita e precondições, sem outro cartão nem perda de efeitos já confirmados |
| Selecionar segmento | Associar a prévia filha à mesma entrada/geração; não criar cartão de outra importação |
| Abrir documento | Consultar; nunca reprocessar ou reativar silenciosamente |
| Salvar fatura/extrato | Confirmar efeitos e seus vínculos com a entrada/geração na mesma transação |
| Excluir importação | Validar snapshot/geração, dependências e pagamentos; retirar somente os efeitos próprios e marcar a geração removida |
| Reimportar após exclusão | Criar nova geração somente após raiz persistida; não reativar as prévias históricas ou a cobrança só pelo upload |

Uma falha transitória antes da leitura persistida não deve produzir cartão com aparência de fatura salva. Uma leitura persistida com pendência deve produzir exatamente uma entrada identificada como conferência pendente, sem cobrança, inclusive se a pessoa voltar da tela.

Nas operações de segmento, cabeçalho persistido, integração, confirmação e remoção,
exigir import_id e expected_generation e validar sua participação ativa na transação.
O document_id ou o preview_id isolado não comprova que aquela geração possa ser
alterada. Leituras históricas permanecem consultáveis somente pelo percurso de
auditoria autorizado; não podem integrar efeitos apenas por conhecer seu ID.
O formulário e seu comando congelado carregam essa identidade. A chave dos cartões
e o estado local usam import_id, pois o cache pode reutilizar o mesmo preview_id
em gerações diferentes. O draft também recebe a identidade da importação.

Aplicar a mesma guarda às mutações dependentes de uma importação: revisão/correção
de item, revisão semântica, geração de obrigações, conciliação e envio ao caixa.
Resolver a entrada pela procedência comprovada de statement/item/transaction;
não aceitar ID histórico retirado como atalho. Operações financeiras manuais
independentes conservam seu contrato e suas permissões; não exigir import_id de
um registro que nunca veio da importação.

Os efeitos anteriormente retirados continuam retirados até reinstate explícito,
mesmo quando uma nova leitura torna o arquivo visível. Ao transportar um baseline
legado com removed=False e efeitos ainda retirados, não inferir que a visibilidade
reativou contas. Preservar também os bancos/extratos já confirmados e seus vínculos;
o backfill não se limita aos ciclos de cartão.

**Propriedade dos efeitos:** registrar, na mesma transação de confirmação, os IDs
de statement, revisão, conta, série e vínculo criados/assumidos por aquela geração.
Não atribuir efeitos pelo document_id ou pelo preview_id reutilizado isoladamente.
Excluir uma geração nova ainda pendente não pode cancelar nem restaurar contas de
uma geração anterior. O plano de exclusão seleciona somente efeitos cuja propriedade
está comprovada e mostra dependências externas como bloqueios.

O snapshot de retirada conserva os efeitos enquanto houver retenção pendente,
independentemente de state ACTIVE/REMOVED. Uma restituição exige registro explícito
e auditado dos IDs liberados, nenhuma outra retirada que ainda retenha o efeito,
e revalidação da revisão/saldo/pagamentos/dependências. Se o registro foi alterado
ou pago independentemente, não restaurar automaticamente: devolver conflito com
o objeto identificável e manter o estado. No backfill, efeitos de propriedade
incerta ficam protegidos como legado, com referência ao snapshot original; não
os transferir à geração nova por aproximação. Se essa incerteza impedir uma
migração consistente, bloquear a ativação e relatar os IDs por alias para análise.

Manter rotas de binário/prévia usadas pelos leitores. A lista comum deve consultar entradas ativas e suas raízes, não a tabela bruta de prévias. O endpoint existente de listagem pode preservar o formato compatível de resumo, acrescentando import_id/generation/filename e os fatos financeiros da geração; seu histórico não deve ser o default da lista. Consultas de statements, controles e enriquecimento também devem respeitar o estado ativo.

A consulta de estado após upload deve ser atual, sem depender de uma resposta idempotente antiga de upload. A criação de leitura recebe expected_generation. Retentativa do mesmo corpo/chave retorna a mesma geração; uma reimportação deliberada após nova retirada usa a geração atual como precondição e produz outra chave. Preservar o processamento transacional de idempotência. Senha não entra no banco, log, registro local nem identidade persistida de conteúdo.

**Rotas e capability:** adicionar GET /documents/{document_id}/import-state,
autorizado pelo mesmo ator financeiro, com lifecycle_version=1,
current_generation (zero antes da primeira entrada), active_import ou null, e
root_preview_id quando há entrada ativa. active_import contém id, generation e
state. Acrescentar import_lifecycle_version=1 e bill_requirements_version=1 ao
GET /capabilities. Adaptar POST /documents/{document_id}/previews para receber
expected_generation e devolver import_id/generation junto de preview. Adaptar
GET /previews, mantendo sua forma de coleção atual, para listar as raízes ativas
e metadata da entrada. Plano de exclusão GET /documents/{document_id}/removal
recebe import_id/expected_generation; POST /documents/{document_id}/remove recebe
também o snapshot. Guardas recusam geração antiga com conflito de estado, sem
executar a mutação. Testar versão/estado atuais após qualquer replay de upload.

Gerar a próxima geração sob a mesma transação que valida o estado e insere a raiz;
tratar a corrida pelo índice único como replay/conflito recuperável, não como
segunda importação. Alterar a raiz de uma entrada ativa exige intenção explícita,
precondição da raiz atual e conferência dos efeitos já confirmados. Não permitir
trocar de cartão silenciosamente para contornar um conflito.

### Validações coerentes entre consulta e gravação

Centralizar o cálculo das exigências em um helper do domínio, chamado pelo draft e novamente por integrate na transação. Não manter um teste de elegibilidade diferente para o candidato exibido e para o título exigido.

O draft deve informar requisitos estruturados, reutilizando os conceitos de readiness.pending já existentes; adicionar um contrato versionado para os requisitos de integração. Cada requisito contém código estável, alvo semântico, categoria, parâmetros seguros, ação disponível e referências existentes quando necessárias. A gravação devolve a mesma identificação quando a precondição deixa de ser satisfeita.

Alvos previstos: file, source, password, header.total_amount_cents, header.due_on, header.period_start, header.period_end, due_choice, details_ack, previous_balance, replacement.<id>, final_ack, segment.<key>. Linhas bancárias acrescentam item.<id>.amount, reason e transaction.

Categorias: dado ausente/inválido; decisão necessária; conflito de dados; falha do sistema; resultado da gravação incerto. Falha técnica não vira erro de preenchimento.

- Se um requisito pede seleção, os candidatos elegíveis precisam existir no mesmo payload e na tela.
- Se não existem candidatos porque não há conta anterior, usar o modo de saldo inicial da primeira fatura.
- Se deveriam existir mas estão indisponíveis por conflito, retornar esse conflito e seus dados seguros; não pedir escolha vazia.
- CANCELED, superseded e retirados não são candidatos ativos. PAID/legado com pagamentos não é candidato substituível de saldo zero. Aplicar a regra de sobreposição paga abaixo; não criar nova dívida ignorando pagamentos.
- Revalidar origem exata, mês civil, saldo e vínculo de compra. Não inferir identidade por nome de banco, valor igual isolado ou proximidade de horário.

A confirmação condicional de saldo inicial deve ter campo explícito no comando, com default seguro para clientes antigos. Só aceitar quando o servidor também comprovar ausência de título anterior ativo elegível e de conflito financeiro pendente. Uma falha da consulta não significa ausência.

**Histórico pago e sobreposição:** não bloquear uma primeira fatura porque há
qualquer pagamento antigo no mesmo banco. Exigir procedência que relacione a
conta/revisão ao mesmo cartão, fatura ou componente do saldo em análise. Separar
estes casos para não exigir que o implementador escolha uma regra:

- Ciclo anterior OPEN/PARTIAL comprovado, do mesmo cartão e período anterior:
  pode fornecer PREVIOUS_BALANCE quando o saldo residual integral corresponde ao
  carry representado e o vínculo é revalidado. Transferir somente a dívida ainda
  aberta. Pagamentos e sua procedência continuam na conta original; não copiar
  valores pagos para a dívida nova nem gerar outro pagamento. Esta substituição
  válida permite OPEN e exige vínculo, inclusive para PARTIAL. O aceite de saldo
  externo não substitui esse vínculo.
- Conta PAID, componente já pago incluído novamente no total, composição paga
  incompatível ou legado pago/parcial sem substituição comprovadamente suportada:
  bloquear OPEN enquanto a sobreposição não estiver resolvida. Oferecer Ver conta
  e pagamentos com ID real e explicar qual valor já está representado. Não oferecer
  saldo externo nem substituição de saldo zero para ultrapassar o bloqueio.
- Saldo residual divergente ou pagamento concorrente durante a conferência:
  REFRESH_DRAFT recalcula saldo/candidatos e pede nova decisão. Não reaproveitar
  expected_balance_cents antigo nem descartar pagamento para fazer o total caber.

Guardar sem nova cobrança continua possível somente se PENDING/HISTORY for
permitido pelas demais validações; conta ativa não pode ser ocultada mudando o
destino. A pessoa consulta/corrige registro de fato incorreto pelo fluxo financeiro
existente; depois Atualizar conferência recalcula os requisitos. Não recomendar
desfazer pagamento correto nem adicionar aceite que ignore sobreposição. Se for
a mesma fatura já confirmada/paga, retomar o resultado existente. Sem procedência
suficiente, retornar conflito de dados para revisão, sem presumir dívida nova ou
acusar uma conta por nome/valor semelhante.

### Contrato executável de erros e recuperação

Adicionar requirements_version=1 ao draft e ao details da resposta de erro. Cada
issue contém code, target, category, params e actions. Categorias fechadas:
INPUT, DECISION, DATA_CONFLICT, SYSTEM, UNCERTAIN. Cada action contém kind e
somente as referências necessárias: import_id, generation, preview_id,
payable_id, segment_key ou campo. IDs devem ser verificados quanto à permissão;
não devolver dados de outra origem/usuário. Params contém fatos seguros, nunca
texto livre do PDF, senha ou stack trace. Flutter traduz code+params via l10n.

O helper retorna os mesmos códigos/alvos no draft e na gravação; erro por mudança
concorrente recalcula os fatos. Validação sintática local usa as mesmas chaves de
alvo. Erro HTTP 422 com loc conhecido vira o campo correspondente; loc desconhecido
vira SYSTEM, sem inventar um controle. O servidor não depende de o cliente ter
mostrado a mensagem para aplicar as invariantes.

Matriz normativa abaixo: códigos novos estão marcados. Códigos já existentes com
vários ramos precisam fornecer reason/target/IDs específicos. Uma mesma mensagem
genérica não atende a dois ramos com ações diferentes.

| Código/condição | Categoria e alvo exatos | Dados obrigatórios e ação permitida |
| --- | --- | --- |
| Sem arquivo / sem origem, validação local | INPUT file / source | Focar seletor correspondente; não enviar comando incompleto |
| FINANCIAL_DOCUMENT_SIZE / TYPE / FORMAT | INPUT file | Limite/tipo ou formato detectado; SELECT_FILE preserva origem |
| PDF_PASSWORD_REQUIRED | INPUT password | reason REQUIRED ou INVALID, sem senha; EDIT_FIELD no diálogo existente |
| PDF_SOURCE_TYPE_MISMATCH / FINANCIAL_INSTITUTION_MISMATCH | INPUT source ou segment.<key>.source | Tipo/instituição detectados e origem escolhida; SELECT_SOURCE só com opções compatíveis; CREATE_SOURCE pelo cadastro existente |
| PDF_OCR_OR_TEXT_REQUIRED / PDF_LAYOUT_UNSUPPORTED | DATA_CONFLICT file | Limite de leitura real; VIEW_ORIGINAL e SELECT_FILE. Não oferecer editar valor como solução de falha de leitura |
| HEADER_MISSING / HEADER_CONFLICT, readiness existente | INPUT header.<field> ou DECISION due_choice | Campo da whitelist, valores/páginas quando existem; EDIT_HEADER ou SELECT_DUE. Sem datas alternativas, apontar header.due_on |
| PDF_BILL_HEADER_REQUIRED / PDF_BANK_PERIOD_REQUIRED / PDF_BANK_CONTROLS_REQUIRED / PDF_BANK_CONTEXT_REQUIRED | INPUT header.<field> ou item.<id>.<field> | Expandir em issues pelos campos realmente ausentes; não manter um único erro inespecífico. EDIT_HEADER/EDIT_FIELD no local |
| FINANCIAL_BILL_CONTROLS_REQUIRED | DECISION final_ack e issues INPUT dos controles ausentes | Validar total/vencimento/destino separadamente e destacar cada pendência. Focar o primeiro na ordem visual, nunca só o último checkbox |
| FINANCIAL_PDF_HEADER_CONFLICT / FINANCIAL_DUE_DATE_CONFLICT / PDF_CONFLICTING_HEADER | DECISION due_choice ou DATA_CONFLICT header.<field> | Valores confirmados/extraídos e páginas. SELECT_DUE quando escolha permitida; EDIT_HEADER somente campo editável; conflito imutável mostra VIEW_ORIGINAL e impede salvar até revisão válida |
| FINANCIAL_BILL_DETAILS_PENDING / PDF_SUMMARY_DETAIL_MISMATCH | DECISION details_ack | Total, soma, diferença e can_accept_details_pending. EDIT_FIELD no aceite se permitido; caso contrário mostrar os bloqueios reais, sem checkbox de dispensa |
| FINANCIAL_BILL_EXTERNAL_BALANCE_CONFIRMATION_REQUIRED — novo | DECISION final_ack.external_balance | Carry e prova de ausência de sobreposição; CONFIRM_EXTERNAL_BALANCE incorporado à confirmação final condicional. Servidor revalida na gravação |
| FINANCIAL_BILL_PREVIOUS_BALANCE_LINK, saldo ainda aberto representado | DECISION previous_balance ou DATA_CONFLICT replacement.<id> | Candidatos elegíveis completos, saldo esperado e motivo da incompatibilidade. SELECT_REPLACEMENT, ou REFRESH_DRAFT se saldo mudou. Sem candidatos, reclassificar como saldo externo ou inconsistência; nunca retornar esta seleção vazia |
| Mesmo código, carry=0 com conta anterior aberta e pagamento apenas impresso | DATA_CONFLICT previous_balance | IDs das contas ainda abertas e valores; VIEW_PAYABLE_PAYMENTS. Explicar que o pagamento no PDF não baixou a conta no app. Atualizar após conferir situação real; não liquidar automaticamente |
| FINANCIAL_BILL_LEGACY_REVIEW | DECISION replacement.<id> ou DATA_CONFLICT previous_balance | Contas legadas pertencentes àquela fatura e saldos. SELECT_REPLACEMENT somente se substituíveis; sem correspondência exata, VIEW_PAYABLE_PAYMENTS/REFRESH_DRAFT, sem aceite que ignore dívida |
| FINANCIAL_BILL_LEGACY_PAYMENT_REVIEW / FINANCIAL_BILL_PAID_COMPOSITION_CONFLICT | DATA_CONFLICT previous_balance ou revision | Contas/pagamentos e parcelas de composição que conflitam; VIEW_PAYABLE_PAYMENTS. Aplicar regra de sobreposição paga; não oferecer substituir conta paga |
| FINANCIAL_BILL_REPLACEMENT_CONFLICT | DATA_CONFLICT replacement.<id> | ID, saldo/status atual e esperado; REFRESH_DRAFT, preservar demais decisões; seleção antiga não é reenviada como se ainda fosse válida |
| FINANCIAL_PURCHASE_ALLOCATION_REQUIRED | DECISION item.<id>.purchase ou DATA_CONFLICT no mesmo alvo | Compra/conta elegíveis, posição estável, valor e unicidade exigidos. SELECT_PURCHASE somente com candidatos reais; sem eles, VIEW_PURCHASE quando há ID ou corrigir classificação opcional de estoque. Nunca criar compra fictícia |
| FINANCIAL_BILL_ROLE_CONFLICT / FINANCIAL_ITEM_NOT_FOUND | INPUT item.<id>.role ou DATA_CONFLICT items | Papel/sinal esperado e linha identificável; EDIT_FIELD apenas se decisão editável. Linha inexistente dispara REFRESH_DRAFT, sem marcar linha errada pela posição antiga |
| FINANCIAL_BILL_CONTENT_CONFLICT | DECISION revision | comparison com diferenças e revisão esperada; REVIEW_REVISION abre comparação existente e seu aceite. Não limpar ou aceitar automaticamente |
| FINANCIAL_BILL_REVISION_CONFLICT / FINANCIAL_PREVIEW_CHANGED | DATA_CONFLICT revision | Revisão/resultado atual; REFRESH_DRAFT e revalidação. Preservar entradas, invalidar apenas decisões dependentes e confirmação final |
| FINANCIAL_BILL_CYCLE_CONFLICT | DATA_CONFLICT source ou segment.<key>.source | Ciclo/origem já vinculados; OPEN_EXISTING_IMPORT somente com referência autorizada. Não trocar origem para burlar vínculo |
| FINANCIAL_BILL_SINGLE_CYCLE_REQUIRED / PDF_COMPILED_DOCUMENT_REVIEW_REQUIRED | DECISION segments ou DATA_CONFLICT file | SELECT_SEGMENT apenas se há segmentos utilizáveis no payload. Documento sem segmentos válidos: VIEW_ORIGINAL/SELECT_FILE e explicação do limite |
| FINANCIAL_BILL_ACTIVE_DESTINATION | DATA_CONFLICT destination | Conta ativa e destino pedido; VIEW_PAYABLE_PAYMENTS ou voltar ao destino compatível. Não esconder conta pelo destino HISTORY/PENDING |
| FINANCIAL_IMPORT_CURRENCY_MISMATCH | DATA_CONFLICT file | Moeda detectada e moeda suportada; VIEW_ORIGINAL/SELECT_FILE. Não converter nem acusar campo de total válido |
| FINANCIAL_REIMPORT_REQUIRED | SYSTEM document | reason READER_CONTRACT ou CLIENT_CAPABILITY. Primeiro: REPROCESS_EXPLICIT com precondição de raiz/geração, depois de explicar o motivo. Segundo: atualização do cliente/serviço, sem reprocessar o mesmo PDF inutilmente |
| FINANCIAL_CLIENT_UPDATE_REQUIRED — novo | SYSTEM service | Capabilities ausentes/esperadas; RETURN_TO_LIST, orientação de atualização; mutação antiga recusada |
| FINANCIAL_IMPORT_REQUIREMENTS_INCONSISTENT — novo | SYSTEM form | Requisito sem campo/opção/referência válida; REFRESH_DRAFT conforme protocolo abaixo; nenhuma pendência vermelha atribuída à pessoa |
| FINANCIAL_IMPORT_REMOVAL_CHANGED | DATA_CONFLICT removal | Snapshot atual; REFRESH_REMOVAL_PLAN executa a consulta de plano existente. Mostrar consequências novamente; não repetir exclusão automaticamente |
| PDF_RUNTIME_UNAVAILABLE / PDF_PROCESSING_BUSY / PDF_PROCESSING_FAILED / PDF_PROCESSING_TIMEOUT | SYSTEM service ou UNCERTAIN operation, conforme houve escrita possível | Explicar leitura indisponível/ocupada; retry apenas pelo comando idempotente preservado. Se resultado incerto, resolver operação primeiro |
| Timeout/transporte após envio de mutação | UNCERTAIN operation | Identidade e chave do comando em memória, sem senha persistida; RESOLVE_OPERATION consulta resultado ou repete a mesma chave. Nenhuma nova chave enquanto resultado não resolvido |
| Código desconhecido / metadata incompleta | SYSTEM form | Mensagem segura de serviço e contexto preservado; RETURN_TO_LIST ou consulta sem mutação. Sem mensagem de escolha obrigatória, sucesso ou falha definitiva inventados |

**REFRESH_DRAFT, operação exata:** executar o GET já existente
/previews/{preview_id}/bill-integration, acrescentando import_id e
expected_generation e mantendo reference confirmada. Atualizar o método
FinancialImportService.billIntegrationDraft para esses parâmetros. Não executar
POST createPreview, upload ou integrate como “atualização”. Preservar os valores
locais; reconciliar os requisitos retornados e validar novamente o formulário.
Permitir uma atualização por acionamento, sem loop automático. Se a entrada foi
removida/substituída, voltar à lista e recarregar seu estado atual com explicação.

Se o GET continuar exigindo escolha sem candidato, manter o bloqueio OPEN como
falha do serviço, retirar a instrução impossível e oferecer Voltar aos documentos
pela navegação existente, seguida da consulta da lista. A entrada permanece
pendente, sem cobrança nova. Não prometer que reenviar, marcar mais uma caixa ou
excluir o arquivo corrigirá o serviço. HISTORY/PENDING só pode ser oferecido se
o servidor declarar esse destino válido; voltar não exige nova gravação.

Para cada linha da matriz, criar teste do requisito no helper/draft e do mesmo
código/alvo em integrate quando aplicável, incluindo mudança concorrente. No
cliente, testar o roteamento, texto, ação existente e preservação dos campos.
Enums/params novos devem constar dos schemas e da capability, não de convenção
informal entre uma mensagem do backend e um if de texto no Flutter.

### Feedback compartilhado

Extrair apresentação reutilizável para client/lib/widgets/shared/app_form_feedback.dart, a partir de _feedbackNotice/_targetFrame, respeitando os componentes/tema. Não mover a decisão financeira ou o roteamento de telas para o widget compartilhado.

O estado de formulário mantém issues por alvo e registro das chaves/focos. Ao tentar continuar/salvar, validar todas as pendências conhecidas, mostrar resumo persistente com atalhos e levar ao primeiro alvo na ordem visual. Abrir a seção antes de mover o foco/rolagem.

- Campo nativo: errorText/validator no próprio controle.
- Data/seletor: FormField/InputDecorator ou equivalente canônico com erro no controle.
- Checkbox/radio/grupo: borda de erro na área do grupo e mensagem adjacente; leitura acessível e foco no controle.
- Lista de linhas: marcar a linha e o campo exatos, não pintar a tabela inteira como se tudo estivesse errado.
- Corrigir um campo limpa/revalida apenas as issues relacionadas; preservar erros independentes e valores corretos.
- Não depender de SnackBar, tooltip, cor isolada ou botão permanentemente desabilitado para explicar uma pendência.
- Salvar pode acionar validação quando faltam dados; durante envio fica bloqueado com progresso. Se uma ação estiver indisponível por capacidade/permissão, explicar o motivo junto dela.
- Em erro com resultado incerto, bloquear decisões incompatíveis, preservar o comando e consultar/repetir a mesma chave; não exibir “não foi salvo” sem confirmação.
- Sem foco/controle aplicável, mostrar a falha técnica e recuperação comprovada. Não fabricar um campo vermelho.

## Mensagens e decisões a especificar

Os textos abaixo são exemplos de conteúdo e comportamento a adaptar às chaves l10n; valores são fictícios. Podem ocupar mais de uma frase quando isso ensinar a ação.

| Situação | Explicação didática esperada | Alvo/ação |
| --- | --- | --- |
| Sem arquivo | “Escolha o PDF que você quer importar. Use Selecionar PDF abaixo.” | Seletor de arquivo |
| Sem origem | “Escolha a conta ou o cartão ao qual este PDF pertence. Essa escolha diz onde a fatura será registrada.” | source |
| Fatura escolhida como conta bancária | “Este PDF contém uma fatura de cartão. Você escolheu uma conta bancária. Escolha o cartão desta fatura para continuar.” | source, opções compatíveis; cadastrar somente se necessário |
| Banco/origem diferentes | Identificar os dois nomes disponíveis e pedir a origem correta; não trocar automaticamente | source |
| Senha ausente/incorreta | “O banco protegeu este PDF com senha. Digite a senha usada para abrir esse arquivo.” / “Essa senha não abriu o PDF. Confira e tente novamente.” | password, preservar seleção; nunca registrar senha |
| Arquivo ilegível/sem texto | Explicar o limite efetivamente detectado e orientar o arquivo aceito; não mandar preencher vencimento se a leitura nem ocorreu | file, escolher outro PDF |
| Vencimentos conflitantes | “Encontramos dois vencimentos no PDF. Escolha o vencimento desta fatura. A página indicada ajuda você a conferir no documento.” | due_choice aberto, datas/páginas |
| Total ausente/inválido | “Informe o total que aparece na fatura, em reais. Por exemplo: 100,00.” | header.total_amount_cents |
| Período invertido | “A data final está antes da data inicial. Confira a data final do extrato.” | header.period_end, revalidar também period_start |
| Diferença de detalhes | “O total da fatura é R$ 100,00, mas os itens lidos somam R$ 99,98. A diferença é R$ 0,02. Você pode usar o total conferido e deixar os itens pendentes para revisar.” | details_ack, somente se essa continuação é permitida; sem ajuste fictício |
| Saldo anterior sem conta cadastrada | “Esta fatura inclui saldo de uma fatura anterior. Como ainda não há uma conta anterior deste cartão no app, esse valor fará parte desta fatura. Confira se ele ainda precisa ser pago e se não está em outra conta cadastrada.” | Confirmação final condicional, sem seletor vazio |
| Conta anterior existente | Identificar conta, valor aberto e vencimento, explicar que ela será reunida à fatura para evitar cobrar duas vezes | previous_balance/replacement.<id> |
| Pagamento anterior que impede substituição | Identificar o pagamento/conta existente e explicar a consulta necessária; não sugerir estorno de pagamento correto | Ver conta e pagamentos, somente com ID fornecido |
| Nenhum candidato e estado incoerente | “O aplicativo pediu uma conta anterior, mas não encontrou nenhuma opção para você escolher. Isso é um problema da conferência do aplicativo. Suas escolhas foram mantidas e nenhuma nova cobrança foi criada.” Somente afirmar a última frase após confirmar ausência de commit | Atualizar conferência executa REFRESH_DRAFT; se persistir, Voltar aos documentos. Sem seletor vazio, reenvio ou nova caixa de aceite |
| Confirmação final ausente | “Marque a confirmação depois de conferir o cartão, o total e o vencimento. Isso confirma os dados usados para salvar a fatura.” | final_ack; incluir saldo anterior quando aplicável |
| Arquivo já ativo | “Este arquivo já está cadastrado. Abra o cadastro existente para continuar a conferência.” | Abrir a mesma entrada; nenhuma nova importação |
| Salvamento concluído | “Fatura adicionada a Contas a Pagar”, com total/vencimento e Ver conta; ou “Arquivo guardado para conferir depois. Nenhuma conta foi criada.” | Ação correspondente ao destino efetivamente gravado |
| Resposta perdida | “A conexão caiu antes de recebermos a confirmação. Vamos conferir se a fatura foi salva antes de tentar novamente.” | Consulta/retentativa idempotente, preservando escolhas |
| Exclusão bloqueada | Explicar o pagamento ou documento dependente e oferecer o item real identificado | Ação apenas se existe ID; manter o arquivo visível até conclusão |
| Versões incompatíveis/API indisponível | Dizer que o serviço do aplicativo precisa ser atualizado ou restabelecido, conforme o erro detectado | Recuperação de serviço; nenhum campo do PDF acusado |

Não afirmar sucesso por receber apenas o arquivo. Distinguir explicitamente: arquivo recebido; leitura pronta; conferência pendente; documento guardado; cobrança registrada. Voltar da conferência preserva uma única entrada pendente e explica que a cobrança ainda não foi criada.

## Etapa 1 — Corrigir o ciclo de exclusão, reimportação e listagem

**Entrega:** o mesmo PDF não ressuscita cartões históricos; arquivos diferentes continuam distintos; abrir um arquivo não altera o cadastro.

**Arquivos principais:** backend/app/models/financial_imports.py; schemas/financial_readers.py e financial_imports.py; services/financial_imports.py, financial_previews.py e financial_import_removals.py; api/v1/financial_imports.py; nova revisão Alembic; client/lib/services/financial_import_service.dart e o carregamento/abertura da lista em financial_imports_view.dart. Consultar também financial_bill_enrichment.py/financial_compilations.py e consultas de parcelas nos pontos que leem prévias/retiradas.

- [x] Congelar reproduções B/C como testes de regressão isolados. Cobrir múltiplas fontes/versões, mesmos bytes com nomes diferentes e mesmo nome com bytes diferentes. Não semear a base do app.
- [x] Criar os metadados/índices do contrato de importação e a migração aditiva. Inspecionar o head Alembic atual, sem presumir que o head histórico desta conversa ainda seja o único.
- [x] Backfill em cópia preenchida: preservar IDs, hashes, originais, statement/revisões, pagamentos, auditoria e efeitos de retirada. Raiz de segmento se obtém de sua procedência, não do horário. Quando houver confirmação financeira vigente, ela governa a associação; uma leitura inválida mais nova não sobrescreve essa confirmação.
- [x] Quando não houver confirmação financeira vigente, representar a raiz mais recente comprovadamente vinculada ao próprio documento como conferência pendente; manter outras interpretações somente na auditoria. Se raízes com efeitos financeiros vigentes não puderem ser reconciliadas com a procedência, interromper a ativação e apresentar a ambiguidade exata. Não escolher silenciosamente.
- [x] Remover a reativação de store_document. Preparação interna da nova leitura pode acessar bytes retirados de forma autenticada; isso não deve abrir consultas/mutações históricas indiscriminadamente. Ativar a nova geração somente depois de persistir a raiz, na mesma transação.
- [x] Acrescentar consulta atual de estado de importação, precondição de geração e idempotência. Incluir a geração na identidade do comando de reimportação, sem alterar o hash do cache imutável.
- [x] Atualizar select_segment e confirmações para vincular seus resultados à entrada correta. Filtrar consultas correntes por entrada/geração; helpers de retirada agregam efeitos históricos sem perder títulos retirados quando outra geração é excluída.
- [x] Listar raízes de entradas ativas com import_id, generation, filename completo, origem, contagens e situação financeira comprovada. Paginação e total pertencem a essa coleção, não a leituras brutas. Não fazer agrupamento no Flutter.
- [x] Retirar POST automático de _preview ao abrir. Quando reprocessamento for realmente necessário, explicar a razão e oferecer ação explícita; ela atualiza a entrada com precondições e preserva efeitos existentes.
- [x] _load não deve transformar falha de statements/obrigações em “não há registros”. Mostrar estado parcial/erro de consulta, conservar o último estado confiável e permitir nova consulta sem duplicar cartões.

**Verificação concluída:** 28 testes backend; 31 Flutter e regressões dirigidas (T05: 2, E56: 3, E3 T07: 2); análise Dart sem issues. Migração em cópia e base ativada: 57 tabelas preexistentes sem mudança, `integrity_check=ok`, zero FK inválida. Health HTTPS da API/banco: `200/ok`. A suíte completa e avaliação visual nativa não foram refeitas. T15 visual fica pendente.

**Aceite da etapa:** excluir A → zero entradas ativas de A; upload isolado de A → continua zero; persistir leitura de A → exatamente uma nova geração e um cartão; seus antigos resultados não voltam à lista. Importar B não reativa A. Abrir A repetidamente cria zero prévias. PDF com várias faturas mantém filhos na mesma importação. Reenvio concorrente/timeout cria uma única geração. Nenhuma cobrança volta apenas por ler.

## Etapa 2 — Corrigir saldo anterior e alinhar requisitos/erros

**Entrega:** primeira fatura pode ser salva sem conta anterior inexistente; vínculos reais continuam protegidos; nenhum erro exige opção que o draft não fornece.

**Arquivos principais:** backend/app/services/financial_bill_cycles.py (draft/integrate/confirmed_parts); financial_bill_enrichment.py; schemas/financial_bill_cycles.py e financial_readers.py; services/financial_preview_contract.py; rota financeira; client/lib/core/api_client.dart somente se o parsing perder metadata; serviço financeiro e mapeamento financeiro de erros.

- [ ] Extrair a elegibilidade de conta anterior/compra/legado e o cálculo de requisitos para um helper compartilhado entre draft e integrate. Consultar origem exata, mês, saldo, retirada, substituição e pagamentos; deduplicar por ID.
- [ ] Corrigir o teste incondicional da linha histórica 268: saldo inicial externo não exige criar ou escolher conta anterior inexistente. Acrescentar o aceite explícito condicional do contrato, sem repetir confirmações na jornada comum.
- [ ] Quando houver conta anterior elegível, exigir o vínculo e conservar transferência/substituição atômica, valores e pagamentos. A aceitação de saldo externo não pode contornar uma conta ativa encontrada no servidor.
- [ ] Corrigir também a consulta de prior_open do ramo carry=0 para respeitar ciclos/títulos retirados. Não liquidar uma conta ativa só porque o PDF mostra pagamento.
- [ ] Preservar a exclusão de legados retirados. Separar cancelado/retirado, conta aberta, histórico pago e composição paga incompatível; cada situação deve produzir requisito e ação próprios.
- [ ] Versionar requisitos de integração no draft e detalhes de erro, preservando os contratos de leitura existentes. Acrescentar capability de lifecycle e de requisitos para que o cliente detecte servidor incompatível.
- [ ] Atualizar schemas e comandos de gravação com import_id/expected_generation.
  Cliente incompatível recebe erro específico de atualização, sem executar a
  mutação antiga ou produzir um erro falso de preenchimento. A ativação final
  entrega API e cliente correspondentes; não usar fallback para a listagem bruta.
- [ ] Desfazer o agrupamento semântico de códigos na mensagem “Já existe alguma destas contas?”. Saldo inicial, falta de vínculo, compra de estoque, pagamento legado, saldo alterado e revisão incompatível têm explicações/ações diferentes.
- [ ] Provar que todas as referências acionáveis do erro existem e são acessíveis ao dispositivo. Erro sem candidato pode ser saldo inicial ou falha/conflito; não fabricar uma lista vazia com instrução de selecionar.
- [ ] Testar falha depois da validação e antes do commit, conflitos simultâneos de saldo/revisão e repetição da chave. Nenhuma resposta de erro pode deixar meia cobrança ou meia substituição.

**Verificação obrigatória:** ampliar test_financial_bill_cycles.py e test_financial_import_removals.py; fixtures sintéticas de primeira fatura com saldo inicial e de conta anterior cadastrada; testar os dois ramos de carry e os modos PENDING/HISTORY/OPEN. Não alterar leitores para acomodar esse erro de regra.

**Aceite da etapa:** saldo anterior positivo + ausência comprovada de conta anterior + aceite explícito + total conferido → uma cobrança pelo total; sem aceite → requisito na confirmação correspondente, nunca link impossível. Com conta anterior ativa → vínculo exigido e dívida não duplicada. Com apenas contas retiradas → elas não bloqueiam. Histórico pago real permanece protegido. Draft e integrate concordam sobre os candidatos, inclusive após mudança concorrente.

## Etapa 3 — Aplicar orientação didática e validação nas telas existentes

**Entrega:** a pessoa identifica, entende e corrige cada pendência no lugar em que ela acontece, com o mesmo padrão visual e sem páginas adicionais.

**Preparação comum:** extrair somente a apresentação repetida de feedback para app_form_feedback.dart e criar o mapeamento de issues financeiras versionadas junto ao domínio de importação. A página conhece seus campos e continua dona do roteamento/alvo. Usar a matriz de mensagens, o tema e os donos canônicos deste plano.

Checklist comum a entregar integralmente a cada tarefa de página:

- [ ] Usar página/superfície/campos/ações do projeto; não criar cores, sombras, raios ou hierarquia locais.
- [ ] Identificar arquivo e origem reais e manter o estado da operação reconhecível.
- [ ] Explicar o que aconteceu, onde agir, como corrigir e o efeito sobre a gravação, com detalhe suficiente.
- [ ] Validar o campo/grupo correto; erro textual persistente junto ao controle e resumo navegável.
- [ ] Abrir a seção necessária, rolar e focar o primeiro erro; permitir teclado e leitor de tela.
- [ ] Preservar valores e decisões válidas; revalidar apenas dependências alteradas e manter outros erros.
- [ ] Mostrar progresso/sucesso/falha/resultado incerto sem duplicar comandos ou deslocar a ação de forma inesperada.
- [ ] Localizar todas as mensagens; evitar jargão na jornada comum e instruções para opções inexistentes.
- [ ] Conferir texto ampliado, tela estreita, modo claro/escuro e redução de movimento, sem truncar a instrução essencial.
- [ ] Repassar a página pronta a um revisor que não a escreveu, com este checklist e suas condições específicas; corrigir os desvios encontrados.

Tarefas por página, dentro desta mesma etapa:

| Página/arquivo | Alteração exata e checklist específico | Critério de aceite |
| --- | --- | --- |
| FinancialImportsView / financial_imports_view.dart | Renderizar a coleção de importações da etapa 1; título pelo filename real e origem separada; mensagem junto a arquivo/origem; um caminho principal Selecionar PDF → Ler PDF → Conferir. Mesmo arquivo ativo retoma cadastro, sem novo cartão. Não mostrar histórico técnico de leituras. Cadastro de origem reaproveita o fluxo existente e valida os campos reais. | A pessoa distingue arquivos de nomes iguais por origem/datas e dados reais; falha de consulta não parece lista vazia; voltar da conferência mantém uma entrada pendente com a informação de que não há cobrança criada. |
| Senha / _promptPassword no mesmo arquivo | Usar Form e validar senha vazia no diálogo; senha incorreta permanece erro no campo e permite nova tentativa. Cancelar retorna ao mesmo arquivo/origem. Não congelar senha em comando persistido. | Tentativas incorretas não criam cartões; campo correto fica destacado; foco e descarte do controller respeitam o diálogo. |
| FinancialPdfPreviewView / mesmo arquivo | Separar original, dados lidos e problemas; erro aponta a origem/cabeçalho/segmento ou explica impossibilidade real de leitura. Preservar visualizador original seguro e consulta sem efeitos. | Abrir PDF é leitura; nenhum erro genérico manda confirmar uma fatura indisponível; ação existe no estado atual. |
| FinancialBillIntegrationView | Consumir requisitos da etapa 2; substituir mensagens genéricas; tratar saldo inicial condicional; ordenar dados principais → pendências → destino → confirmação final → resultado. Detalhes/classificação permanecem opcionais e recolhidos quando não bloqueiam. | Vencimento, total, diferença, saldo anterior, vínculo real e confirmação levam ao controle exato. Candidatos ausentes nunca levam a seletor vazio. Resultado informa guardar versus conta criada e oferece a conta real. |
| FinancialHeaderReviewView | Acionar Form.validate mesmo com confirmação ausente; validar datas pelo próprio FormField; período invertido destaca a data final e explica a correção. Valores não viram zero por campo vazio. | Tentar continuar revela todos os campos pendentes; confirmação fica destacada quando ausente; datas/valores corretos sobrevivem ao erro e ao retorno. |
| FinancialSegmentsView | Explicar “Este arquivo contém X faturas” somente a partir dos segmentos reais do leitor. Mostrar cartão/período/total identificáveis; se falta origem, erro no seletor daquele segmento; se não há origem compatível, oferecer o cadastro existente sem escolha impossível. | Confirmar um segmento não duplica arquivo ou fatura, não reabre segmentos já confirmados como novos e não cria cinco cartões de leitura. |
| FinancialBankReviewView e ocorrência interna | Mover erro de motivo/valor/movimento do SnackBar para o campo/linha correspondente; explicar conciliar como reconhecer um lançamento que já existe. Manter distinção entre evidência e dinheiro. | Seleção ausente fica localizada; nenhum pagamento/caixa é criado para encobrir conciliação; falha geral preserva a ocorrência. |
| FinancialBillReviewView | Identificar linhas/classificações pendentes e por que a gravação depende delas no fluxo legado. Para fatura atual, preservar a classificação opcional do contrato vigente; não tornar tudo obrigatório por copiar a tela antiga. | Nenhum botão esconde o único modo de descobrir o erro. Correção de uma linha mantém as demais. Retomada de registro antigo preserva vínculos/pagamentos. |
| FinancialImportRemovalView | Exibir arquivo e consequência sobre contas/previsões; bloqueio perto do item real, ação somente com ID; erro de snapshot pede nova conferência e preserva a lista até sucesso. | Após excluir, a entrada some uma vez; ao voltar ou importar outro arquivo não retorna. Dependências e pagamentos têm explicação específica; nenhum estorno de pagamento correto é ensinado como rotina. |

A tarefa de cada página começa relendo o checklist e termina com revisão independente. Para o processo do skill de consistência, provar uma vez que o checker detecta uma diferença plantada numa cópia temporária; não editar a aplicação para essa calibração nem gerar cópias de planejamento permanentes.

**Verificação obrigatória:** testes de widgets existentes financial_header_review_test.dart, financial_bill_cycle_integration_test.dart, financial_import_removal_test.dart, financial_e56_flow_test.dart, financial_e3_review_test.dart, financial_pdf_import_test.dart e os de revisão bancária pertinentes. Acrescentar casos somente para comportamentos novos relevantes: alvo real, primeiro foco, estado incerto, ausência de candidatos e preservação de entrada. Fazer revisão visual agrupada das telas/estados alterados, não uma prévia a cada detalhe.

**Aceite da etapa:** em qualquer página do percurso, uma pessoa consegue responder sem consultar código: “o que aconteceu?”, “o que falta?”, “onde faço isso?” e “o que já ficou salvo?”. Nenhuma instrução essencial existe apenas em tooltip ou desaparece antes da correção.

## Etapa 4 — Conferir o percurso integrado e entregar cliente/API correspondentes

**Entrega:** fluxo exercitado em cópia isolada, janela Windows conferida, cliente e servidor compatíveis e pacote completo disponível no Release habitual.

- [ ] Rodar os testes direcionados após cada mudança relevante. Ao fim das alterações funcionais, executar uma vez as suítes gerais apropriadas de backend/Flutter, análise e migração em cópia preenchida. Repetir apenas por nova alteração/falha justificada.
- [ ] Exercitar os casos da matriz abaixo por API e por interação com as telas, com os arquivos autorizados/fixtures. Não substituir avaliação de compreensão por contagem de testes.
- [ ] Registrar evidência sanitizada: import_id/generation por alias, quantidade de binários/entradas/cobranças, transições, código/target dos erros e capturas sem dados pessoais. Nunca guardar tokens ou senhas.
- [ ] Conferir endpoint realmente configurado, schema e capability da API ativa. A versão genérica da raiz HTTP não identifica por si só o código implantado. Se houver processo antigo do projeto, identificar o executável/comando e os pedidos ativos antes de substituir; não encerrar outros serviços.
- [ ] Fazer backup coerente antes da ativação. Compilar o Windows com o próximo build number livre, verificar o pacote inteiro e substituir a pasta Release completa quando o app estiver fechado. O SDK em C:\dev\flutter pode precisar do mecanismo de permissão do ambiente para seu lockfile; não deixar o build girando sem saída.
- [ ] Verificar artefatos do build e manifesto; não entregar um kernel_blob.bin legado de build JIT como se fosse parte nova do pacote AOT. Não apagar arquivos por nome sem verificar origem/manifesto.
- [ ] Abrir o cliente correspondente, demonstrar o percurso e conferir um único serviço correto no endereço configurado. Build ou HTTP 200 isoladamente não certificam essa entrega.
- [ ] Atualizar CONTAS_A_PAGAR.md e os guias efetivamente afetados apenas com o comportamento entregue. Atualizar o estado curto de RETOMADA_IMPORTACAO_FATURAS.md uma vez, com resultado, limites e pendência. Não duplicar relatórios em várias memórias.

### Matriz mínima de aceitação integrada

| Caso | Preparação/ação | Resultado obrigatório |
| --- | --- | --- |
| V01 | Base sem importação ativa; importar PDF compatível de uma fatura | Uma entrada, dados reconhecíveis, uma cobrança somente depois da confirmação OPEN |
| V02 | Arquivo com cinco interpretações históricas; excluir e reimportar três vezes | Cada reimportação cria uma geração; uma entrada ativa; histórico não reaparece como cartões |
| V03 | Excluir A e importar B com bytes diferentes | A continua excluído; B identificável; nenhuma associação por nome/horário |
| V04 | Mesmo SHA com outro nome; mesmo nome com outro SHA | Primeiro retoma o arquivo/entrada existente; segundo permanece documento distinto |
| V05 | Abrir repetidamente, atualizar, voltar e paginar | Zero leituras criadas só por consulta; sem repetição/perda de entradas |
| V06 | PDF protegido: senha vazia, incorreta, correta e cancelamento | Erro no campo, arquivo/origem preservados; uma importação somente após resultado persistido |
| V07 | Primeira fatura, saldo anterior positivo, sem título anterior | Explicação/aceite condicional; uma cobrança pelo total; zero título fictício/caixa |
| V08 | Conta anterior real aberta/parcial; saldo muda durante conferência | Vínculo exigido e revalidado; nenhum saldo cobrado duas vezes |
| V09 | Apenas contas anteriores retiradas/canceladas; histórico pago separado | Retiradas não bloqueiam; pagamentos reais continuam protegidos com explicação própria |
| V10 | Dois vencimentos, total ausente, valor inválido e período invertido | Campos/grupos precisos com borda+texto; seção aberta, primeiro foco, dados válidos preservados |
| V11 | Diferença de R$ 0,02 nos detalhes | Diferença explícita, aceite apenas no controle próprio; sem arredondamento ou linha compensatória |
| V12 | Confirmação final desmarcada e outras duas pendências | Todas identificadas; ordem de foco previsível; nada enviado antes de validar |
| V13 | Servidor devolve requisito de seleção sem candidato ou ID acionável | Falha de contrato tratada como sistema; nenhuma seleção inexistente ensinada |
| V14 | PDF com várias faturas/segmentos e origem faltando em um deles | Arquivo único, faturas identificáveis; correção só do segmento afetado; sem perder os demais |
| V15 | Resposta perdida antes/depois do commit; fechar/reabrir cliente | Consulta/replay idempotente recupera o resultado; nenhum novo título, entrada ou pagamento |
| V16 | Exclusão bloqueada por pagamento/documento dependente e snapshot antigo | Efeito preservado até resolução explícita; ação leva ao objeto certo; sem exclusão parcial |
| V17 | API antiga/incompatível ou consulta parcial indisponível | Mensagem de serviço, escolhas preservadas; não mostrar “vazio”, “pago” ou “salvo” por fallback |
| V18 | Windows com teclado, tela estreita/texto ampliado e claro/escuro | Alvos, instruções e botões legíveis/operáveis, sem sobreposição ou dependência exclusiva de cor |

### Quando declarar concluído

As quatro etapas precisam de evidência própria e os casos aplicáveis devem passar. Informar qualquer limite ainda não observado. Não concluir enquanto V02, V07 ou os alvos de erro tiverem caminhos sem saída. A revisão visual geral do resto do app permanece um trabalho separado; o padrão compartilhado e a instrução didática ficam prontos para sua adoção posterior.

## Fontes e aplicação

Consultadas em 20/10/2026, somente para dúvidas concretas de validação:

- [W3C — Error Identification, SC 3.3.1](https://www.w3.org/WAI/WCAG22/Understanding/error-identification.html): identificar o item com erro e descrevê-lo em texto. Aplicação: campo/grupo correto e mensagem persistente; cor isolada é insuficiente.
- [W3C — Error Suggestion, SC 3.3.3](https://www.w3.org/WAI/WCAG22/Understanding/error-suggestion.html): oferecer orientação de correção quando conhecida. Aplicação: instrução executável e ligada a uma ação existente; não inventar solução para falha do servidor.
- [Flutter — Form validation](https://docs.flutter.dev/cookbook/forms/validation): Form/validator como mecanismo para verificar e apresentar erro no campo. Aplicação: reaproveitar a plataforma existente, sem mecanismo artesanal por tela.
- [Flutter — InputDecoration.errorText](https://api.flutter.dev/flutter/material/InputDecoration/errorText.html): erro associado ao campo. Aplicação: usar o estado nativo e o tema do projeto, extraindo apenas o feedback composto necessário.

Essas fontes fundamentam o mecanismo; não aprovam uma mudança visual global nem comprovam acessibilidade completa da aplicação. A didática explícita, a divisão em no máximo quatro etapas e a padronização vêm do pedido do usuário.

