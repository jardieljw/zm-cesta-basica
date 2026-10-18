# Memória da implementação financeira

Consolidação: **16/10/2026**. Decisões, evidências e pendências para retomar após
compactação ou em outra sessão. Não substitui ler o código e verificar a instalação.

## Como retomar

`AGENTS.md` é o ponto de entrada curto; aponta para as instruções existentes e
para estes registros, sem duplicar as regras de integridade.

1. Cumprir a ordem de consulta de [AGENT_INSTRUCTIONS.md](../AGENT_INSTRUCTIONS.md).
2. Ler esta memória, a [base financeira](BASE_FINANCEIRA_E_CONCILIACAO.md),
   [CSV multibanco](IMPORTACAO_CSV_MULTIBANCO.md),
   [PDF financeiro](IMPORTACAO_PDF_FINANCEIRO.md),
   [correção de revisão](CORRECAO_REVISAO_FINANCEIRA.md) e
   [homologação](HOMOLOGACAO_IMPORTACAO_FINANCEIRA.md).
3. Conferir Git, testes, revisão Alembic e implementação. Há alterações de outros
   trabalhos no mesmo projeto; não limpar, reverter ou sobrescrever em bloco.
4. Distinguir capacidade do código, app instalado e proposta futura. Atualizar
   decisões, fontes, resultados, limites e próxima ação ao encerrar cada rodada.

## Objetivo e alcance autorizado

O usuário quer reunir dívidas, faturas e movimentações de diferentes bancos,
PF/PJ, sem contar a mesma operação duas vezes e sem fundir operações legítimas.
Pediu priorizar backend/persistência porque o front-end está sendo reformulado
em outro trabalho, usar campos com finalidade real, pesquisar antes de decidir
e registrar aprendizados para outros agentes.

Foi autorizada a consulta de documentos bancários antigos no Gmail para estudo
e testes isolados. Isso não instala Gmail no app, não autoriza envio de e-mails
nem execução de pagamentos. Não enviar documentos a conversores públicos.

## Estado confirmado em 16/10/2026

| Assunto | Situação |
| --- | --- |
| Originais PDF/CSV/OFX/QFX | Recepção em BLOB com hash/limites/auditoria. Receber não significa interpretar. |
| Leitores CSV | Adaptador de conta Nubank e leitor configurável de conta/cartão, com formato explícito. |
| Prévia e confirmação | API com erros bloqueantes, original preservado e versão do leitor. |
| Revisão/duplicidade | Decisão explícita, IDs no escopo origem/namespace; semelhança não comprova identidade. |
| Correção de revisão concluída | Decisão posterior imutável, com motivo/autor/revisão; preserva a primeira decisão e os fatos. |
| Conciliação | Vincula movimento existente; não paga. Correção bloqueada com conciliação ativa nas operações envolvidas. |
| Procedência/conferência de fatura | Implementada na API: documentos/páginas, comparação exata de transcrições e revisões imutáveis. READY separado de conferência; sem autorização comercial. |
| Homologação com originais | Três CSVs Nubank, PF/PJ e períodos sobrepostos, aprovados em banco descartável. |
| Homologação multibanco com originais | PDF Nubank/PicPay validado no alcance do guia; CSV de outro emissor ainda pendente. |
| PDF | `pdf_auto` v1 detecta faturas Nubank/PicPay e extratos Nubank PF/PJ. Cinco originais, 151 lançamentos; uma fatura bloqueada por diferença resumo/detalhes. |
| Outros layouts PDF, OFX, OCR, senha, IA | Pendentes; não anunciar suporte universal a PDF. Texto de layout desconhecido preservado com erro bloqueante. |
| Dívidas a partir da fatura, relatórios e nova interface | Integração futura; eventos externos não são novas despesas. |
| Gmail automático/Open Finance | Não implementados; exigem etapas próprias de autorização, credenciais e coleta. |
| Banco da empresa | Observação mais recente somente de leitura: `fc2f3a4b6512`, 41 tabelas. A nova `fd3a4b5c7613` foi aplicada apenas à cópia descartável. A observação anterior de f9 é histórica. |

As rotas financeiras retornam `FINANCIAL_SCHEMA_NOT_READY`/503 sem a estrutura
migrada. Não migrar o original como efeito colateral de testes ou demonstrações.

## Caminho e decisões

**Prioridade PDF — 16/10, solicitação “PRECISAMOS DISSO PRIMEIRO”:** substitui
a recomendação anterior de fazer revisão semântica como próxima entrega. Foi
implementada a [importação automática de PDFs financeiros](IMPORTACAO_PDF_FINANCEIRO.md),
decisões PDF-001 a PDF-007, com fontes diretas, limites, contrato e reprodução.
`pdfplumber` 0.11.10 foi escolhido após verificar que cor e geometria mudavam o
significado financeiro dos documentos. Extração é local, em processo separado,
antes da transação de gravação; não usa IA, Gmail ou conversor externo.

Reutiliza BLOB e JSON imutável existentes; não acrescenta migração. Prévia
guarda texto/página/coordenadas, cabeçalho e controles. Confirmação preenche o
cabeçalho extraído, rejeita contradições e cria somente ocorrências pendentes.
`READY` não é autorização comercial nem VERIFIED de procedência. Mudança no
adaptador exige incrementar a versão externa do leitor para nova prévia.

O [relatório PDF](validacoes_financeiras/2026-10-16-pdf.json) registra cinco
originais, 35 páginas e 151 ocorrências: faturas Nubank A/B (19/16), PicPay (14),
extratos Nubank PF/PJ (5/97). A fatura B segue INVALID pela diferença de quatro
centavos entre resumo e detalhes; não foi corrigida artificialmente. Quatro
documentos foram confirmados só no banco descartável, com todos os itens
pendentes, nenhum evento/dívida/pagamento novo e livros preservados. Referências
monetárias visuais dos cartões e pares data/valor dos CSVs de extratos foram
conferidos, com repetição/backup/integridade. Isso não homologa todos os layouts
dos emissores nem todas as descrições/contrapartes. As divergências entre
formatos dos cartões continuam pendentes.

Aprendizados: ordem de lançamentos PDF/CSV pode diferir; comparar multiplicidade
na homologação, nunca usar isso como identidade. Créditos antigos Nubank são
verdes sem sinal; PicPay usa meia página; total de compras PicPay exclui
pagamentos anteriores. Página seguinte de extrato pode continuar uma saída sem
repetir a data. Campos/horários ausentes continuam ausentes; ano inferido da
fatura tem aviso. Não transformar ofertas de parcelamento em eventos.

Na preparação do manifesto, referências anteriores usavam decimal ponto; a
primeira comparação as interpretou como milhar e também exigiu ordem CSV no
PDF. Corrigiu-se o verificador, conservando originais. O teste restrito travou
na infraestrutura do cliente local; foi encerrado pelo identificador exato e
repetido com o executor autorizado, sempre com bancos descartáveis.
**Semântica e Integração de Obrigações — 17/10 (FAT-005 a FAT-009):**
Implementada a classificação semântica auditável e a consolidação de obrigações
em `accounts_payable` com a migração `fe4b5c6d8714` (tabelas `financial_bill_semantic_reviews`,
`financial_bill_semantic_items` e `financial_bill_obligations`).
- Equação de fechamento obrigatória:
  Total Declarado = Saldo Anterior + Compras PJ + Compras PF + Encargos - Pagamentos - Créditos.
  Diferença diferente de zero mantém o parecer como DRAFT e bloqueia geração de títulos (HTTP 409).
- Prevenção de duplicidade: compras de insumos já existentes em `purchases` reaproveitam
  o vínculo sem gerar novos títulos nem alterar o CMPM de estoque.
- Segregação de natureza: despesas operacionais viram `BUSINESS` (`CARTAO_CREDITO`),
  enquanto compras pessoais de sócios viram `PERSONAL_WITHDRAWAL` (`RETIRADA_SOCIO`).
- Zero geração de títulos para `BILL_PAYMENT`, `PREVIOUS_BALANCE`, `REFUND_CREDIT` e `CONTEXT_ONLY`.
- Front-end Flutter: `FinancialBillReviewView` com cálculo dinâmico da equação,
  seleção de categorias e exibição dos títulos gerados.
- Testes automatizados: 442 testes no backend e 352 no Flutter 100% aprovados,
  exercitando as faturas reais do Nubank (março/2026 e abril/2024).

**Procedência implementada — 16/10, após novo pedido para prosseguir:** a seção 7
da arquitetura saiu do planejamento para a API. O
[guia operacional do backend](CONFERENCIA_E_PROCEDENCIA_DE_FATURAS.md) detalha
contratos, limites, rotas e as decisões FAT-011/FAT-012, com fontes SQLite/W3C.
Três tabelas novas: `financial_bill_assessments`, `financial_bill_evidence` e
`financial_bill_assessment_links`; migração `fd3a4b5c7613` após `fc2f3a4b6512`.
Não foram reconstruídas tabelas antigas. Pai/filhos/auditoria/idempotência são
atômicos; gatilhos preservam histórico, sequência e conjunto fechado de evidências.

O parecer pertence à prévia, pode guardar cabeçalho desconhecido e problemas
pendentes, e compara data/valor/descrição de referências transcritas manualmente.
`VERIFIED` é concordância daquele conjunto, não classificação comercial ou prova
de autenticidade: `semantic_status=NOT_REVIEWED`, `can_generate_obligations=false`.
Origem/moeda/revisão/hash são revalidados. Findings removidos exigem resolução
explícita com motivo/documento/localizador; justificativa não dispensa diferenças
que continuam calculadas. Nova prévia não herda parecer.

Na confirmação, `assessment_id` opcional exige parecer atual VERIFIED e cabeçalho
igual; vínculo imutável em tabela própria. O fluxo antigo sem esse campo continua
recebendo evidências, com hash de idempotência preservado. Não dizer que toda
confirmação legada exige parecer nem que esta camada gera/paga títulos.

Homologação dos originais em banco descartável guardou cabeçalhos transcritos e
observações; detalhes não foram transcritos linha a linha no endpoint novo.
Ambas ficaram REVIEW_REQUIRED, com confirmação vinculada bloqueada e livros
inalterados. [Relatório sanitizado](validacoes_financeiras/2026-10-16-procedencia-faturas.json).
A [migração na cópia preenchida](validacoes_financeiras/2026-10-16-migracao-conferencia-faturas.json)
preservou as 41 tabelas, índices/gatilhos e integridade/FKs. O original foi aberto
com `mode=ro` e mostrou revisão fc2; não atribuímos a mudança desde a observação
anterior f9 a esta rodada. A nova revisão fd3 **não foi aplicada ao original**.

Aprendizado operacional: ao substituir `engine_from_config` num verificador
privado, respeitar o pool ou fechar todas as engines antes de limpar a pasta.
A primeira checagem passou os dados mas falhou na limpeza por conexão retida;
foi corrigida com `dispose`, repetida com limpeza concluída e removida somente
a pasta temporária exata criada pela tentativa. Não foi erro da migração ou
gravação no original. Não guardar cópia do banco da empresa em fixtures/Git.

**Base — 15/10:** documentos, interpretações, eventos externos e conciliações
ficam separados dos livros comerciais. Guardar extrato não duplica uma saída,
cria dívida ou altera saldo. A migração `fa0d1e2f4310` acrescentou oito tabelas,
após `f9c0d1e2f309`. Não existem tabelas de dívida específicas de um banco.

**Pesquisa/piloto — 15/10:** a [pesquisa](PESQUISA_PROXIMO_INCREMENTO_FINANCEIRO.md)
mudou a ordem para CSV estruturado antes de PDF. Permite conferir o fluxo sem
OCR/IA; não significa que CSV seja universal. O usuário reforçou multibanco.
Foi adotado contrato normalizado único, leitores versionados e configuração
explícita de colunas, codificação, datas, decimal/milhar, moeda e sinal.

`fb1e2f3a5411` acrescentou prévias, procedência e datas de compra/lançamento.
IDs de 255 caracteres são aceitos integralmente. As duas colunas antigas mantêm
`VARCHAR(200)` porque SQLite não limita esse comprimento; evitou-se reconstruir
tabelas imutáveis referenciadas. Outra tecnologia de banco exigirá rever isso.

**Correções — 15/10:** após o usuário questionar vínculos incorretos entre
pagamentos/recebimentos distintos, foram implementadas decisões `NEW`/`LINK`/
`IGNORE`, com motivo, autor e revisão esperada. `fc2f3a4b6512` acrescenta
`financial_review_corrections` e `financial_identity_changes`, sem atualizar
item/alias original. As consultas operacionais usam a última decisão e o dono
atual do ID. Sem evidência ativa, o evento fica `WITHDRAWN` no histórico.
Não se força o mesmo ID confirmado em dois eventos. Conciliações precisam ser
desfeitas explicitamente antes de corrigir, sem estornar o pagamento real.

**Homologação — 16/10:** buscas de anexos antigos localizaram CSV/PDF Nubank e
faturas PDF PicPay/Santander. Busca por CSV/OFX fora de Nubank antes de julho/2026
retornou apenas anexos não bancários. Isso descreve as buscas, não prova
inexistência de arquivo. Não acessar conteúdo não financeiro só por ser CSV.

Os originais foram baixados fora do projeto, com tamanho conferido contra o
metadado. A ferramenta local exercitou a API em processo e SQLite descartável.

| Amostra | Ocorrências | Eventos novos | Eventos já conhecidos |
| --- | ---: | ---: | ---: |
| Nubank PF | 5 | 5 | 0 |
| Nubank PJ, período A | 97 | 97 | 0 |
| Nubank PJ, período B sobreposto | 187 | 90 | 97 |
| Total | 289 | 192 | 97 |

Foram comparados campos mapeados, bytes originais, reenvio/prévia/confirmação,
eventos, livros comerciais e recuperação de backup. Dois PDFs correspondentes
forneceram controles, conferidos visualmente na primeira página e registrados
no manifesto privado. Não se validou automaticamente cada página desses PDFs.
O período A PJ usou o leitor genérico com namespace `nubank:account`; B usou o
adaptador conhecido. O [relatório sanitizado](validacoes_financeiras/2026-10-16-csv.json)
conserva somente aliases, quantidades e checagens.

## Aprendizados a preservar

**Conferência semântica e procedência — 16/10:** após autorização para prosseguir
e registrar a fundamentação, foram localizados e conferidos os PDFs das duas
faturas CSV. Total/vencimento foram comprovados visualmente, mas houve
divergências de conteúdo: A tem 21 linhas no CSV e 19 no PDF, com diferenças de
valores e ocorrências adicionais; B tem 15 no CSV e 16 no PDF, crédito ausente,
descrições divergentes e diferença entre detalhes e resumo do próprio PDF.
Não foi investigada a causa nem eleito um formato como correto. Nenhuma fatura
foi confirmada. READY permanece um resultado de leitura, não de completude.

O [registro detalhado da arquitetura semântica](ARQUITETURA_SEMANTICA_DE_FATURAS.md)
é a referência canônica desta etapa: FAT-001 a FAT-010, fontes primárias diretas,
aplicação/limites, alternativas avaliadas, mapa do código, matriz dos lançamentos,
próximos incrementos e critérios de aceite. Preservar sua fundamentação; esta
memória é o índice, não substituto por resumo. O
[relatório do cruzamento](validacoes_financeiras/2026-10-16-faturas-cruzamento.json)
conserva apenas quantidades e resultados; valores, hashes e originais ficaram
em manifesto privado fora do Git. Comparar multiconjuntos de valores detecta
diferença, mas não comprova identidade de transações ou cobertura total.

Decisão de evolução: procedência de controles e qualificação de cobertura
separadas do READY do parser, antes de integração com títulos. O código atual
tem um documento principal por statement, sem associação tipada ao PDF que
forneceu seus controles. Criar uma fatura genérica e pagar de novo títulos já
registrados duplicaria efeitos; o resumo atual também precisa preservar a
separação de estoque, despesa e retirada. Essa camada está **planejada**, não
implementada. Nesta rodada houve pesquisa, conferência e documentação; nenhum
código ou banco operacional foi alterado. Baseline 363 backend/238 Flutter
aprovados. A verificação final repetiu **363 backend/238 Flutter aprovados**;
os avisos preexistentes permaneceram. Links locais e dez IDs de decisão foram
conferidos. Sem código novo, migração nova ou gravação na base da empresa.

**Correção monetária — 16/10:** os [novos originais](validacoes_financeiras/2026-10-16-csv-recebidos.md)
expuseram quatro valores negativos com espaço após o sinal. O leitor
`generic_csv` passou à versão 2 com opção explícita `amount_sign_spacing`:
`ADJACENT` por padrão ou `OPTIONAL_SINGLE_SPACE` (um espaço ASCII após sinal).
Sem limpeza geral de espaços, sem arredondamento e sem inferência pela descrição.
O adaptador `nubank_account_csv` continua versão 1 e estrito. O campo novo entra
no hash das opções, portanto pode criar nova prévia para o mesmo documento;
as prévias e decisões anteriores permanecem imutáveis. Não houve nova migração.

Revalidação via API em SQLite descartável: ambas as faturas ficaram `READY`,
com 21 e 15 linhas e campos comparados por oráculo separado. Originais preservados,
reenvio reutilizado, livros inalterados e zero eventos criados. A confirmação
sem vencimento/total declarado permaneceu bloqueada. Não foram inventados esses
campos nem interpretadas automaticamente parcelas ou categorias no texto.
[Relatório sanitizado](validacoes_financeiras/2026-10-16-cartoes-v2.json).
O verificador offline e seu oráculo foram atualizados para a opção; teste de
fatura inteiramente sintética exercita confirmação/revisão/backup sem gerar dívida.

Próxima entrega de cartões exige controles reais e tratamento semântico de
compra, crédito/estorno, pagamento, encargos e saldo anterior antes de integrar
obrigações. Não usar soma de linhas como total declarado nem descrição como ID.
Naquela rodada CSV, multibanco com originais continuava pendente; as amostras
também eram Nubank. A rodada PDF posterior validou um layout PicPay.

Referências técnicas conferidas nesta rodada:
[Python — fullmatch](https://docs.python.org/3/library/re.html#re.fullmatch) para
validar a cadeia inteira e [Decimal](https://docs.python.org/3/library/decimal.html)
para conversão decimal exata. A gramática financeira restritiva é decisão do
projeto apoiada nos originais, não uma regra bancária universal.

| Evidência ou problema | Decisão e consequência |
| --- | --- |
| A extração do conector pode acrescentar índice ao CSV. | Testar bytes originais; não reconstruir o arquivo pela prévia do conector. |
| Primeira transação difere do início do período. | Guardar período declarado e datas observadas separadamente; mínimo/máximo não prova cobertura completa. |
| Mesmo dia/valor/descrição em operações legítimas. | Não deduplicar por semelhança; IDs distintos continuam separados. |
| CSV/PDF não oferecem os mesmos campos. | Campo ausente permanece ausente; comparar controles quando houver, sem fabricar saldo/horário. |
| Nome de outro banco na transferência. | Contraparte não é emissor. Extrato Nubank mencionando Santander não homologa leitor Santander. |
| Arquivos sobrepostos na mesma conta. | Origem + namespace estável + ID definem identidade; não usar filename ou chave de requisição como namespace. |
| PicPay anuncia débito automático futuro e pagamento da fatura anterior. | Previsão não comprova liquidação; pagamento anterior não quita a fatura atual. Observação visual não entrega leitor PDF. |
| Não há horário da operação no CSV. | Não derivar hora de UUID, e-mail, emissão ou importação. Auditoria usa UTC; fatos bancários respeitam precisão/fuso conhecidos. |
| SQLite ficou aberto na primeira execução da ferramenta no Windows. | Contexto de `sqlite3.Connection` não fecha a conexão; usar `closing`, encerrar sessões/engine antes da limpeza. Teste verifica isso. |
| O oráculo compartilha o tokenizer CSV do Python. | Comparação de campos não é prova independente da tokenização. Controles do banco e conferência visual são evidências adicionais. |
| Teste sintético de outro layout passa. | Demonstra contrato configurável, não homologação com original daquela instituição. |

## Mapa do código

| Local | Responsabilidade |
| --- | --- |
| `backend/app/models/financial_imports.py` | Onze tabelas novas e proteções SQL. |
| `backend/app/schemas/financial_imports.py` | Fatos, cabeçalhos, revisões, correções e alocações. |
| `backend/app/schemas/financial_readers.py` | Configuração CSV, prévia e confirmação. |
| `backend/app/services/financial_imports.py` | Evidência, revisão inicial, compatibilidade e conciliação. |
| `backend/app/services/financial_readers.py` | Leitores determinísticos limitados, sem persistência/Gmail. |
| `backend/app/services/financial_pdf_readers.py` | Texto/geometria/cor, adaptadores PDF, cabeçalhos e controles; sem persistência. |
| `backend/app/services/financial_pdf_runtime.py` e `financial_pdf_worker.py` | Processo local limitado e falhas sanitizadas, fora da trava de escrita. |
| `backend/app/services/financial_previews.py` | Resultado versionado, hashes, relatório e staging. |
| `backend/app/services/financial_review_corrections.py` | Decisão/identidade atuais e histórico. |
| `backend/app/{models,schemas,services}/financial_bill_assessments.py` | Procedência por documento, comparação manual exata, revisões e vínculo de confirmação. |
| `backend/app/api/v1/financial_imports.py` | API protegida, idempotência e erros sem ecoar valores. |
| `backend/app/core/financial_payloads.py` | Limite de corpo estruturado; original possui limite próprio. |
| `backend/app/main.py` | Exclui a base nova de `create_all`; startup não migra. |
| `scripts/verify_financial_csv.py` | Homologação por manifesto privado, banco descartável e relatório sanitizado. |
| `scripts/verify_financial_pdf.py` | Homologação PDF com referências independentes, confirmação/bloqueio, backup e relatório sanitizado. |
| `backend/tests/test_financial*.py` | Contratos, leitores, correções, concorrência, isolamento e recuperação. |

Após correções, não consultar o item/alias original como decisão vigente: usar
`effective_items`, `identity_owner` e projeção de identidades atuais. Campos do
evento são históricos; `external_identities` informa as associações atuais.

## Pendências e próxima ação

Validação mais recente, após o PDF: **414 testes backend e 238 Flutter aprovados**.
Baseline desta entrega: 386/238; 28 casos PDF/ferramenta acrescentados, incluindo
cores, geometria, subtotais, páginas reais de procedência, cabeçalho inválido,
continuação, linhas monetárias desconhecidas, recuperação e acesso revogado.
`pip check` aprovado. A execução Flutter paralela ficou parada no executor;
foi encerrada apenas a árvore identificada desta rodada e a suíte sequencial
(`flutter test --concurrency=1`) concluiu 238 casos. Não houve alteração Flutter.
Os 14 avisos de depreciação anteriores do backend permaneceram.

Histórico anterior: procedência passou de 363/238 para 386/238 com 23 casos de
conferência, fonte/moeda/ciclo, linhas extras/faltantes, cabeçalho desconhecido,
concorrência, rollback, vínculo, idempotência antiga, backup e migração preenchida.

Retomada imediata: a procedência/conferência já está implementada conforme o
[guia](CONFERENCIA_E_PROCEDENCIA_DE_FATURAS.md); não refazê-la como pendência.
Depois da prioridade do usuário, o PDF automático já foi implementado no
alcance do guia. Próximo incremento recomendado: ampliar por original de outro
banco prioritário; se houver necessidade real, OCR/senha. Revisão semântica
auditável (FAT-005) continua necessária antes de propostas de obrigações/alocações.
As divergências
reais continuam sem resolução; não tentar fechar arquivos alterando os dados.
Antes de ativar a nova API no servidor, planejar backup/atualização e aplicar
fd3 explicitamente; a nova estrutura não é criada no startup.

1. Obter **CSV original de outra instituição** e inspecionar o layout antes de
   configurar/criar leitor. Santander informa CSV em solução PJ pelo Internet
   Banking; isso não garante igual opção em conta PF ou fatura de cartão.
2. Revisar acesso global, downloads/exportações e backup. A API nova valida
   token ativo estritamente. `backend/app/api/deps.py:get_current_device` ainda
   aceita mestre local ativo para token ausente/desconhecido, confirmado por
   leitura em 16/10. Preparar compatibilidade e testes antes de alterar globalmente.
3. Definir proteção de armazenamento, permissões e recuperação. Não há nova
   criptografia de aplicação para SQLite/backups nem papéis por usuário.
4. Ampliar a cobertura PDF por amostras; OFX continua sem leitor.
5. Integrar fatura às obrigações existentes sem triplicar despesa por compra,
   dívida e pagamento; depois interface e eventual coleta Gmail.

O leitor OFX não existe. Anexos OFX localizados estavam marcados como não
suportados pelo conector: não chamar `read_attachment` com marcador falso.
Santander PDF não retornou original utilizável nesta rodada; não inferir seu
conteúdo. PicPay passou depois à leitura automática de um layout com original,
no alcance e limites do guia PDF; a observação da primeira página é histórica.

## Fontes e conservação

- [Pesquisa inicial](PESQUISA_PROXIMO_INCREMENTO_FINANCEIRO.md), com referências primárias.
- [Python 3.14 — CSV](https://docs.python.org/3.14/library/csv.html): formatos
  variam, leitura retorna strings e `newline=''` preserva tratamento de quebras.
  Não habilitar conversão monetária implícita para float.
- [OWASP — File Upload](https://cheatsheetseries.owasp.org/cheatsheets/File_Upload_Cheat_Sheet.html):
  validação em camadas, limites e restrição de armazenamento/acesso.
- [Santander — Gestão Financeira PJ](https://www.santander.com.br/empresas/pagamentos/gestao-financeira):
  informa exportação CSV nessa solução pelo Internet Banking Empresarial; não
  fornece o layout do arquivo do usuário nesta rodada.

Originais, manifesto com valores e extrações ficam na pasta temporária privada,
fora do Git, e podem não sobreviver à limpeza do sistema. Para repetir, seguir o
guia com amostras autorizadas. Nunca guardar em fixtures dados reais, nem
registrar nesta memória nomes, documentos, contas, Gmail IDs, tokens ou URLs assinadas.

## Ampliação Multibanco e Descriptografia de Senhas (17/10/2026 - 18/10/2026)

Concluída a ampliação para novos bancos brasileiros com amostras reais do usuário:
1. **Leitores CSV Multibanco (12 adaptadores registrados):**
   - Nubank Cartão (`nubank_card_csv`), Nu Empresas PJ (`nu_empresas_account_csv`).
   - Itaú Conta e Cartão (`itau_account_csv`, `itau_card_csv`).
   - Santander Conta e Cartão (`santander_account_csv`, `santander_card_csv`).
   - Banco Inter Conta e Cartão (`inter_account_csv`, `inter_card_csv`).
   - Mercado Pago (`mercadopago_csv`), Banco do Brasil (`bb_account_csv`), Bradesco (`bradesco_account_csv`), Caixa Econômica (`caixa_account_csv`).
   - Resiliência para acentuação/caixa de cabeçalhos e suporte estrito a separadores de milhar (`thousands_separator="."`).
2. **Leitores PDF Multibanco e Descriptografia em Memória:**
   - Nu Empresas Extrato PJ (`nu_empresas_account_pdf_v1`): leitura de 5 páginas reais com 28 itens, conferência de entradas/saídas e equação de fechamento equilibrada.
   - Faturas de Cartão Itaú, Santander e Banco Inter (`itau_card_pdf_v1`, `santander_card_pdf_v1`, `inter_card_pdf_v1`).
   - Descriptografia efêmera de PDFs protegidos por senha: senha enviada em memória no processo de extração isolado, nunca armazenada em banco e nunca impressa em logs (em conformidade com OWASP).
   - Prevenção de colisão de cache de prévias via inclusão de `has_password` no hash da requisição.
3. **Integração Front-end (Flutter):**
   - `FinancialImportFile`: abstração unificada para arquivos PDF e CSV com validação de assinatura e tamanho.
   - Seletor de leitores bancários para CSVs e detecção automática sugerida pelo banco/tipo da origem.
   - Diálogo seguro e em memória para solicitação de senha ao encontrar `PDF_PASSWORD_REQUIRED`.
   - Visualização original de documentos PDF e CSV no visualizador aprovado.
4. **Verificação Integral de Testes e Integridade:**
   - **Backend:** 448 testes aprovados no pytest (100% green).
   - **Flutter:** 355 testes aprovados no flutter test (100% green).
   - **Banco de Dados Real (`backend/data/estoque.db`):** 995.328 bytes, data e integridade 100% inalteradas.

