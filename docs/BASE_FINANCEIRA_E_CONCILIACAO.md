# Base de documentos e conciliação financeira

Revisão: **15/10/2026**. Situação: **base e prévias CSV multibanco implementadas no backend, com migrações preparadas; sem telas novas**. [Índice](README.md). [Plano de evolução](PLANO_IMPORTACAO_E_CONCILIACAO_FINANCEIRA.md). [Leitores CSV](IMPORTACAO_CSV_MULTIBANCO.md).

## Resultado e limites deste incremento

O servidor pode receber documentos originais e dados estruturados de extratos, faturas e comprovantes. Mantém os dados recebidos separados dos pagamentos e saldos efetivos. Oferece revisão de duplicidades e vínculo de evidência com movimentações já existentes.

Enviar um PDF armazena o original. A API oferece [prévia e confirmação CSV multibanco](IMPORTACAO_CSV_MULTIBANCO.md) e, desde 16/10, [extração automática de PDF por adaptadores](IMPORTACAO_PDF_FINANCEIRO.md), para faturas Nubank/PicPay e extratos Nubank PF/PJ caracterizados. A leitura exige gerar a prévia `pdf_auto`; upload isolado não interpreta. Outros layouts, senha, OCR, OFX, IA, sincronização Gmail e telas novas continuam pendentes. Os dados estruturados podem continuar sendo fornecidos explicitamente pela API.

Também não se criam automaticamente contas a pagar, compras, recebimentos ou pagamentos a partir desses registros. O vínculo entre fatura e obrigações existentes, o tratamento contábil de seus itens e sua participação nos relatórios serão outro incremento. Os relatórios atuais continuam baseados nos livros existentes.

## O que os exemplos consultados mostraram

Foram examinadas faturas antigas do Nubank e PicPay, um extrato Nubank PJ em PDF e seu CSV, além de uma notificação de Pix do Mercado Pago. Os originais foram consultados em pasta temporária, fora dos arquivos do projeto. Não foram usados dados pessoais nem cópias dos documentos reais como fixtures de teste.

| Informação observada | Tratamento na base |
| --- | --- |
| Mesmo dia, valor e descrição em operações distintas | Preservar cada ocorrência; sem fusão automática por semelhança. |
| CSV com Data, Valor, Identificador e Descrição | Guardar identificador no escopo da origem e namespace; aproveitar na conferência futura. |
| PDF e CSV com informações diferentes da mesma conta | Um documento mantém sua própria evidência; várias evidências podem apontar para uma transação conferida. |
| Fatura com compras e pagamentos da fatura anterior | Não transformar a soma de todas as linhas na dívida atual; preservar o total declarado pelo banco. |
| Parcelas com data original antiga e finais diferentes de cartões na mesma fatura | Manter data conforme apresentada, número/total da parcela e final do cartão por item. A origem de cartão representa a relação de crédito, não obrigatoriamente um único plástico. |
| Datas de transação sem horário; comprovante com hora | Campos de horário e fuso opcionais. Preservar precisão de minuto/segundo quando informada. |
| Horário de geração do documento no rodapé | Não atribuir esse horário às transações. |
| Nome/CPF ou CNPJ, instituição, agência e conta da contraparte | Campos opcionais próprios, inclusive quando o banco apresenta documento mascarado. |
| Saldo inicial/final, entradas e saídas totais | Guardar os valores declarados e apontar divergência da equação, sem inventar ajustes. |
| Juros, IOF, pagamentos, créditos e estornos | Manter tipo e sinal do lançamento, sem presumir que toda linha representa uma compra nova. |

Não foram criados cadastros para endereço de correspondência, publicidade, programa de pontos, simulações de financiamento ou taxas apenas anunciadas para períodos futuros. O original permanece disponível para auditoria. A base não armazena número completo de cartão, CVV, senha de PDF, senha bancária ou credenciais Gmail em campos estruturados.

## Entidades e efeito no banco

| Tabela | Responsabilidade |
| --- | --- |
| `financial_sources` | Identidade de conta PF/PJ ou relação de cartão, instituição, titular e moeda. Conta bancária referencia uma `financial_accounts` existente; cartão não vira conta de caixa. |
| `financial_documents` | Original binário, tamanho, tipo, nome e hash SHA-256. Conteúdo não aparece nas respostas JSON. |
| `financial_statements` | Cabeçalho de extrato, fatura ou comprovante, período/datas e totais declarados. |
| `financial_statement_items` | Ocorrência no documento, posição/página, texto de apoio, dados estruturados e decisão de revisão. |
| `financial_transactions` | Evento externo conferido, distinto de lançamento no livro-caixa. |
| `financial_transaction_identities` | Identificadores externos conhecidos de um evento, com unicidade por origem/namespace/identificador. Permite que evidência posterior acrescente identificação sem reescrever a original. |
| `financial_reconciliations` | Alocações entre evento externo e movimentos existentes de `cash_flow_entries`; uma transação pode cobrir vários movimentos e vice-versa. |
| `financial_import_audit` | Autor, data, ação e motivo das decisões e acesso ao conteúdo dos documentos. |
| `financial_import_previews` | Resultado imutável de leitor CSV/PDF, versão, configuração, hashes, erros, páginas/linhas originais extraídas. |
| `financial_review_corrections` | Decisões posteriores da revisão, com autor, motivo e número sequencial. |
| `financial_identity_changes` | Alterações auditáveis da associação de identificadores, preservando os aliases originais. |

As onze tabelas pertencem à base nova. A primeira migração acrescenta oito tabelas; a segunda acrescenta prévias e colunas opcionais de datas/procedência; a terceira acrescenta correções e mudanças de identidade. As tabelas comerciais anteriores permanecem preservadas. A autenticação usa dispositivos existentes. Nenhuma dessas operações modifica estoque, dívidas, pagamentos, saldo da conta ou resultado gerencial.

## Datas, valores e revisão

- Valores são inteiros em centavos, sem aceitação de booleanos, floats ou valores fora dos limites. Zero não representa transação; saldo/subtotal não deve ser enviado como compra.
- Conta bancária: entrada positiva, saída negativa. Cartão: cobrança positiva, crédito/pagamento negativo. Não misturar essas convenções para fazer uma conciliação de caixa.
- `transaction_date` guarda a data mostrada. `date_kind` distingue data como apresentada, de compra ou de lançamento quando essa informação for conhecida. `purchase_date` e `booking_date` preservam ambas quando disponíveis, sem preenchimento retroativo presumido.
- `transaction_time` aceita `HH:MM` ou `HH:MM:SS`; `utc_offset_minutes` permanece ausente se o documento não informar o fuso. Não deduzir horário de IDs, do e-mail ou da emissão do PDF.
- Datas do período, emissão, fechamento e vencimento têm campos separados. Parcela pode ter data original fora do período atual da fatura.
- Uma ocorrência entra como `PENDING`. A revisão explícita escolhe `NEW`, `LINK` ou `IGNORE`, sempre com motivo e dispositivo autor.
- `NEW` reutiliza evento com identidade externa confiável já conhecida, se os fatos forem compatíveis. Identidade com valor, data ou outros fatos conhecidos conflitantes retorna erro e mantém a ocorrência pendente.
- Sem identidade confiável, a API só sugere candidatos por origem/data/valor. O operador pode confirmar que são operações distintas. Uma escolha `LINK` revalida origem, valor, data e demais informações conhecidas.
- Não se pode vincular dois identificadores distintos do mesmo namespace à mesma transação. Namespaces distintos permitem identificações específicas de formatos diferentes, desde que a correspondência seja conferida.
- Os fatos e decisões originais ficam preservados. [Correção de revisão concluída](CORRECAO_REVISAO_FINANCEIRA.md) acrescenta uma decisão auditável, sem atualizar o original. Corrigir valores ou datas extraídos exige nova interpretação documentada; não simular isso alterando os registros diretamente.
- Quando evidência posterior acrescenta horário ou identificação, sua precisão permanece na ocorrência e no endpoint de evidências. A representação canônica inicial não é reescrita silenciosamente.

## Conciliação com o livro-caixa existente

Conciliação vincula evidência; não executa pagamento. É aceita para conta bancária vinculada à mesma conta do movimento e, neste incremento, em BRL, moeda do livro atual. Direção deve corresponder a `CREDIT` ou `DEBIT` e a alocação não pode ultrapassar o valor ainda não conciliado de nenhum dos lados.

Exemplo fictício: um débito bancário de R$ 100 pode comprovar dois movimentos existentes de R$ 60 e R$ 40. Isso cria duas alocações e nenhuma nova saída. Desfazer uma alocação exige motivo e fica auditado; não estorna o pagamento real. O estorno financeiro continua no serviço próprio.

Pagamentos antigos resolvidos em uma conta padrão interna não provam qual banco foi usado. Esta base rejeita vínculos com conta diferente; não reescreve o histórico para forçar correspondência. A reclassificação auditável desse histórico permanece no plano.

## Contrato HTTP para o futuro front-end

Prefixo: `/api/v1/financial-imports`. Todas as operações exigem token Bearer válido de dispositivo ativo. As mutações também exigem `X-Idempotency-Key`, de até 120 caracteres. Reutilizar a mesma chave/payload retorna a resposta já gravada; mudança de payload com a mesma chave é recusada.

| Operação | Endpoint |
| --- | --- |
| Cadastrar/listar origens | `POST /sources`, `GET /sources` |
| Guardar original, sem interpretar | `POST /documents?filename=exemplo.pdf`, com bytes no corpo e `Content-Type` apropriado |
| Consultar metadados/baixar original | `GET /documents/{id}`, `GET /documents/{id}/content` |
| Receber dados estruturados/listar cabeçalhos | `POST /statements`, `GET /statements` |
| Consultar cabeçalho e ocorrências | `GET /statements/{id}`, `GET /statements/{id}/items` |
| Sugerir candidatos e registrar revisão | `GET /items/{id}/candidates`, `POST /items/{id}/review` |
| Consultar decisão atual/histórico e corrigir revisão | `GET /items/{id}`, `GET /items/{id}/review-history`, `POST /items/{id}/corrections` |
| Listar eventos externos e sua procedência | `GET /transactions`, `GET /transactions/{id}/evidence` |
| Vincular/listar conciliações | `POST /reconciliations`, `GET /reconciliations` |
| Desfazer vínculo | `POST /reconciliations/{id}/void` |
| Consultar auditoria por entidade | `GET /audit?entity_id={id}` |

Listas possuem `limit` e `offset`, com limite máximo de 500. Extratos, transações e conciliações oferecem os filtros descritos no OpenAPI gerado pelo servidor. A criação de interpretação tem até 2.000 itens e um limite total de corpo estruturado de 2 MiB; documentos originais têm limite de 10 MiB. Os tipos aceitos para guarda são PDF, CSV e OFX/QFX; aceitar o tipo não significa interpretar ou validar internamente todo seu conteúdo.

A listagem de transações calcula no backend o valor conciliado, o valor ainda não conciliado e sua situação. Itens de cartão não oferecem conciliação direta de caixa. Valores de moedas diferentes são mantidos na origem, sem conversão ou soma em um saldo misto.

Respostas de validação informam código/campo, sem repetir os valores sensíveis recebidos. Os endpoints usam códigos estáveis como `FINANCIAL_EXTERNAL_ID_CONFLICT`, `FINANCIAL_RECONCILIATION_EXCEEDS_BALANCE` e `FINANCIAL_SCHEMA_NOT_READY`. Consultar também os schemas e a especificação OpenAPI; as telas não devem reproduzir as regras de saldo e alocação.

## Proteção e implantação

Os novos endpoints verificam diretamente o token e não aceitam a compatibilidade legada de dispositivo mestre quando o token estiver ausente ou inválido. Respostas com dados usam `Cache-Control: no-store`; downloads são anexos com `nosniff`. Documentos, cabeçalhos, fatos conferidos, identificadores e auditoria têm proteção de imutabilidade no SQLite. Ocorrências só admitem conclusão de revisão; conciliações só admitem desfazimento auditado. A identidade conta/moeda de uma origem não pode ser trocada.

O SQLite e seus backups mantêm o modelo de proteção local existente: **não há criptografia de aplicação nem novos papéis de acesso por usuário neste incremento**. Dispositivos ativos autorizados acessam os dados da empresa. A política das rotas legadas permanece existente e precisa entrar numa revisão global de segurança antes de qualquer exposição fora da rede local.

O original fica em BLOB no próprio SQLite, portanto acompanha o backup quente e a restauração existentes. Isso aumenta o tamanho do banco/backups; limites maiores e política de retenção exigirão avaliação própria. Não acrescentar uma pasta paralela de anexos sem integrar sua recuperação.

Migrações: `fa0d1e2f4310`, `fb1e2f3a5411` e `fc2f3a4b6512`, a partir de `f9c0d1e2f309`. A inicialização preserva os fluxos existentes e não cria essas tabelas por `create_all`. Até aplicar as migrações, os novos endpoints retornam `FINANCIAL_SCHEMA_NOT_READY`/503. A aplicação em produção requer backup verificado, janela de atualização e conferência do banco após migrar. A inversa da correção recusa apagar decisões; as inversas anteriores recusam remover a base financeira preenchida.

Nesta entrega a migração foi validada em bancos de teste e numa cópia somente para validação do banco local da empresa, preservando os dados e índices anteriores. **Não foi aplicada ao banco da empresa**. Os documentos reais consultados no Gmail também não foram gravados nele.

## Verificação e referências

Testes cobrem operações legítimas idênticas, documentos sobrepostos, identidades externas conflitantes, precisão de datas/horários, faturas com pagamentos históricos, confirmação concorrente, excesso de alocação, desfazimento, autenticação, limites de entrada, proteção SQL, backup/restauração e migração preenchida. Fixtures são sintéticas.

Resultado desta entrega em 15/10/2026: **285 testes backend aprovados**, incluindo
37 novos casos da base financeira/migração, e **238 testes Flutter aprovados**.
A verificação na cópia do banco da empresa preservou os registros das 30 tabelas
anteriores, com `integrity_check` e `foreign_key_check` aprovados. O original
permaneceu na revisão `f9c0d1e2f309`, sem as tabelas novas. Existem avisos prévios
de depreciação nas dependências de teste e de fontes dos PDFs Flutter; não houve
falha nas suítes.

- Modelos: `backend/app/models/financial_imports.py`.
- Schemas: `backend/app/schemas/financial_imports.py`.
- Serviços: `backend/app/services/financial_imports.py`.
- API: `backend/app/api/v1/financial_imports.py`.
- Migração: `backend/alembic/versions/fa0d1e2f4310_financial_evidence_and_reconciliation_.py`.
- Testes: `backend/tests/test_financial_imports.py` e `backend/tests/test_financial_imports_migration.py`.

O incremento seguinte acrescentou [leitores CSV multibanco e prévias versionadas](IMPORTACAO_CSV_MULTIBANCO.md). As contagens acima registram a entrega inicial; consultar o guia CSV para o escopo posterior. Leitores por formato não exigem IA; eventual assistência por IA e integração OAuth do Gmail serão decisões posteriores, usando o mesmo fluxo de evidências e validações.

Para retomar o trabalho após compactação ou em outra sessão, consultar a
[memória financeira](MEMORIA_IMPLEMENTACAO_FINANCEIRA.md) e a
[homologação com originais](HOMOLOGACAO_IMPORTACAO_FINANCEIRA.md), atualizadas em
16/10/2026. Os números históricos acima não substituem os resultados da rodada atual.

Continuação: a [conferência/procedência de faturas](CONFERENCIA_E_PROCEDENCIA_DE_FATURAS.md)
acrescenta três tabelas por fd3, sem alterar os livros comerciais. O parecer
pertence à prévia e a confirmação pode vincular sua revisão atual. A última
leitura do original mostrou fc2; a nova migração foi validada apenas em cópia.
Classificação semântica e integração de títulos continuam futuras.
