# Plano de importação e conciliação financeira

Data inicial: **15/10/2026**. Atualização **16/10**: base, CSV, correções,
procedência e primeiro leitor PDF multibanco implementados no backend;
integração de obrigações/interface e ampliação de formatos continuam futuras.

O [guia da base financeira](BASE_FINANCEIRA_E_CONCILIACAO.md) descreve documentos, dados estruturados de extrato/fatura, revisão de duplicidades e vínculo de evidência ao livro-caixa. O [guia CSV multibanco](IMPORTACAO_CSV_MULTIBANCO.md) e o [guia PDF](IMPORTACAO_PDF_FINANCEIRO.md) descrevem os leitores, prévias e confirmação. A [correção auditável de revisão](CORRECAO_REVISAO_FINANCEIRA.md) acrescenta decisões sem apagar o passado. OFX, OCR/senha, criação de dívidas a partir de faturas, Gmail e novo front-end continuam futuros. O incremento PDF não criou migração e não alterou o banco da empresa.

## Objetivo e escopo

Continuidade em **16/10/2026**: [memória financeira](MEMORIA_IMPLEMENTACAO_FINANCEIRA.md)
e [homologação com originais](HOMOLOGACAO_IMPORTACAO_FINANCEIRA.md). Nubank PF/PJ
passou no procedimento descartável; PDFs Nubank/PicPay foram validados depois.
CSV de outros emissores e novos layouts PDF continuam pendentes. Esses registros
orientam a próxima rodada.

Unificar dívidas, parcelas, faturas e movimentações bancárias, preservando a origem das informações e evitando duplicar obrigações, pagamentos e despesas. Priorizar backend, persistência e contratos de API para que a reformulação do front-end possa consumir os mesmos serviços.

O plano parte da análise dos modelos, serviços, APIs, migrações e do esquema de `backend/data/estoque.db`. As quatro tabelas financeiras já existem nesse banco local, cuja revisão consultada foi `f9c0d1e2f309`. Isso não comprova o estado de outra instalação do aplicativo. Não foram executadas importações nem testes de comportamento durante essa análise.

## Base reaproveitada

- `financial_accounts`: contas financeiras e saldos.
- `accounts_payable`: obrigações, parcelas, recorrência e saldos devedores.
- `payable_payments`: pagamentos parciais/totais e estornos.
- `cash_flow_entries`: movimentos imutáveis, com origem e estornos.
- Serviços de compras, transferências, pagamentos, transações e idempotência.

A proteção existente por chave de requisição ou referência interna não substitui a detecção da mesma transação em documentos diferentes. O pagamento atual pode resolver uma conta padrão interna, que não comprova qual banco foi utilizado. O dashboard ativo considera origens específicas e precisará de integração explícita com o novo domínio.

## Etapa 1 — Regras de domínio e contratos

Definir separadamente obrigação, compra no cartão, fatura, pagamento, movimento bancário e evidência importada. Documentar quando cada evento afeta dívida, saldo e resultado gerencial.

- Uma compra, sua parcela na fatura e o pagamento bancário devem manter vínculos, sem gerar três despesas.
- Itens de uma fatura não podem ser somados novamente ao total dessa fatura como dívidas independentes.
- Transferências próprias precisam de duas pontas vinculadas; não representam receita/despesa operacional.
- Preservar vínculos com compras de estoque para evitar descontar novamente custos já considerados nos relatórios.
- Diferenciar data da compra, lançamento, competência, fechamento, vencimento e pagamento. Trabalhar com centavos, moeda explícita e datas sem inventar horários ausentes.
- Registrar como serão tratados juros, tarifas, estornos, créditos, pagamentos parciais e parcelamento da própria fatura.
- Definir a transição de dívidas de fornecedores para obrigações de cartão quando uma compra já cadastrada aparecer na fatura. Não cancelar títulos históricos automaticamente.

Entrega: regras com exemplos e contratos de API, erros estáveis, paginação e exemplos de respostas, independentes do layout Flutter. Registrar decisões pendentes sem bloquear a modelagem das partes já definidas.

## Etapa 2 — Persistência e migrações

Acrescentar entidades próprias, com nomes finais definidos na modelagem:

| Entidade | Responsabilidade |
| --- | --- |
| Documento financeiro | PDF original, nome, tipo, tamanho, hash, origem e data de recebimento. |
| Importação e tentativas | Conta/cartão, período, estado do processamento, erros e versão do extrator. |
| Item extraído | Texto/dados originais, página/posição, campos normalizados, dúvidas e decisões de revisão. |
| Transação bancária | Identidade externa quando disponível, conta, valor, direção, datas, contraparte e referências disponíveis. |
| Evidência de transação | Relacionar a mesma transação a ocorrências em diferentes documentos sem perder a procedência. |
| Cartão | Emissor, identificação parcial, titular e regras de ciclo; sem armazenar número completo ou código de segurança. |
| Fatura e itens | Ciclo, fechamento, vencimento, totais, compras, parcelas, créditos e encargos. |
| Conciliação e alocações | Relacionar evidências, transações, obrigações, pagamentos e movimentos internos, com valores e histórico da decisão. |

Permitir que um pagamento liquide várias obrigações e que uma obrigação receba vários pagamentos. Preservar campos específicos dos bancos em dados estruturados adicionais, acompanhados da versão do formato; não limitar tudo a observações livres.

Definir a guarda do PDF junto com backup/restauração: se estiver no SQLite, avaliar crescimento e limites; se estiver fora, incluir os arquivos em um backup consistente e verificável. O backup atual copia o SQLite e não é suficiente para anexos externos por si só.

Criar migrações Alembic aditivas, índices e restrições adequadas. Validar em banco vazio e cópia preenchida, com integridade, referências, totais e recuperação. Não modificar o banco real nesta etapa de planejamento.

## Etapa 3 — Importação e revisão pela API

Disponibilizar operações para enviar documento, acompanhar processamento, consultar itens, corrigir interpretações, resolver duplicidades, confirmar e consultar o histórico. Os caminhos dos endpoints serão definidos na etapa 1.

- Separar processamento do documento de transações de gravação financeira; a leitura demorada não deve manter uma transação de escrita SQLite aberta.
- Persistir estado e tentativas para retomar após falhas e reinício do servidor.
- Exigir identidade de requisição nas confirmações, revalidar a revisão apresentada e tratar concorrência entre dispositivos.
- Confirmar cada conjunto de efeitos financeiros de forma atômica. Repetir a confirmação deve retornar o resultado anterior.
- Documento recebido ou item extraído não altera saldo nem baixa dívida.
- Proteger o acesso a originais e dados financeiros. Revisar a autenticação atual, inclusive a resolução do dispositivo mestre, antes de expor os novos endpoints.

Entrega: fluxo completo exercitável pela API com dados estruturados de teste, antes de depender de um leitor de PDF ou do novo design.

## Etapa 4 — Duplicidades e conciliação

Implementar camadas de decisão:

1. Arquivo repetido: hash do original e política de reprocessamento vinculada à importação anterior.
2. Identidade externa confiável: banco/conta e identificador da transação, quando presentes, com restrições de unicidade no escopo correto.
3. Sem identificador: comparação de datas, direção, valor, descrição e contraparte para sugerir correspondências. Mesmo valor e dia não autorizam fusão automática.
4. Operação já cadastrada: procurar compra, parcela, pagamento, recebimento ou transferência e vincular a evidência existente.

Preservar ocorrências legítimas idênticas, extratos sobrepostos e evidências repetidas. Registrar motivo, autor, horário e valores vinculados. Suportar confirmação de correspondência, rejeição da sugestão e correção auditável. Desfazer uma conciliação não deve estornar automaticamente um pagamento real; efeitos financeiros exigem o fluxo próprio de estorno.

Conciliar saldos e totais do documento com o período conhecido. Divergências ou informação incompleta devem ficar explícitas. Não gerar ajustes artificiais apenas para os números coincidirem.

## Etapa 5 — Leitores de PDF por banco

Selecionar amostras representativas de extrato e fatura dos bancos usados pelo negócio, com períodos sobrepostos e variações de layout. Usar cópias sem dados pessoais na suíte de testes quando possível.

Começar por um banco e PDFs com texto. Acrescentar outros formatos e OCR para documentos digitalizados depois. PDF protegido deve ter fluxo próprio; eventual senha não deve ficar em logs ou nos dados financeiros.

Guardar original, conteúdo extraído, versão do leitor e localização da informação. Não inventar campos ausentes. Permitir revisão quando houver ambiguidade e reprocessar com nova versão sem recriar os efeitos já confirmados. Escolher bibliotecas e eventual uso de IA nessa etapa, após avaliar precisão, custo, privacidade e funcionamento local.

## Etapa 6 — Regras específicas de cartão

Integrar fatura, itens e parcelas à base de obrigações, respeitando a política definida na etapa 1. Conservar as datas reais de cada fatura; intervalos genéricos de 30 dias não substituem o ciclo informado pelo banco.

Tratar pagamentos parciais, encargos, créditos e parcelamento da fatura separadamente das compras parceladas. Parcelas futuras inferidas devem ficar identificadas como previsão até haver confirmação; não presumir que toda fatura informa o cronograma completo.

Entrega: exemplo completo de compra já cadastrada → item de fatura → obrigação consolidada → pagamento → evidência no extrato, sem duplicar dívida, saída ou despesa.

## Etapa 7 — Histórico existente e relatórios

Preparar sugestões de conciliação para pagamentos antigos sem conta bancária confirmada. Preservar a conta e os movimentos originais; eventual reclassificação financeira deve seguir uma operação auditável, com efeito explicado e validado.

Atualizar os serviços de consulta para apresentar obrigações, movimentos, itens pendentes de revisão e situação da conciliação. Distinguir saldo informado pelo banco, saldo calculado e diferença identificada. Revisar dashboard e relatórios para evitar omissões e dupla contagem de compras de estoque, itens de cartão e quitação de faturas.

Os contratos devem permitir uma experiência unificada no futuro front-end. Não restaurar automaticamente telas de tesouraria arquivadas nem aplicar o novo design como efeito dessa implementação de backend.

## Etapa 8 — Gmail como origem adicional

Adicionar depois que o fluxo manual estiver validado. A conexão Gmail disponível nesta conversa não fornece credenciais ao aplicativo ZM.

Implementar autorização própria do aplicativo e seleção de remetentes/períodos/documentos, com permissões mínimas, credenciais protegidas, revogação e tratamento de falhas. Validar as APIs e permissões vigentes durante a implementação. Reutilizar o mesmo fluxo de documentos, revisão e conciliação, registrando mensagem e anexo de origem.

Receber novamente o mesmo anexo não deve gerar novo efeito financeiro. A primeira versão deve manter confirmação humana. Sincronização automática, sua periodicidade e execução com o computador desligado exigem definição explícita de operação e hospedagem.

## Etapa 9 — Validação e implantação gradual

Validar por incremento, usando bancos isolados. Antes de alterações de código, cumprir a checagem de saúde prevista nas instruções do projeto. Testar migrações em cópia preenchida, backup/restauração com documentos e compatibilidade com o cliente atual.

Critérios centrais de aceite:

- Repetir arquivo ou confirmação não duplica efeitos; requisições concorrentes também não.
- Extratos sobrepostos conservam cada transação única e suas evidências.
- Operações legítimas de mesmo valor/data continuam distintas.
- Pagamento já registrado é vinculado ao extrato sem nova saída.
- Compra, parcela e fatura representam corretamente a obrigação sem somas duplicadas.
- Transferências próprias não alteram resultado operacional.
- Pagamentos parciais, estornos, encargos e créditos preservam totais e referências.
- Erro de leitura, falha na confirmação ou reinício não produz gravação financeira parcial.
- Os fluxos atuais de compras, vendas, estoque, contas e relatórios seguem compatíveis.

Implantar primeiro com um banco, conferência obrigatória e documentos conhecidos; expandir formatos após comparar resultados com os documentos originais. Preservar possibilidade de suspender novas importações sem afetar o restante do app.

## Ordem recomendada de entregas

**Atualização de 16/10:** a sequência original abaixo é referência histórica.
CSV estruturado foi priorizado e já tem leitores/prévias. No momento dessa
primeira atualização PDF automático ainda não existia; a entrega posterior
priorizada pelo usuário está indicada abaixo. A conferência de PDFs reais revelou diferenças frente aos CSVs.
Antes da integração de títulos, implementar procedência e conferência auditável
conforme a [arquitetura semântica de faturas](ARQUITETURA_SEMANTICA_DE_FATURAS.md),
que reúne decisões, fontes diretas, alternativas e critérios de aceite. Não
tratar READY do leitor como aprovação comercial ou cobertura completa.

Continuação de 16/10: procedência/conferência foi implementada com pareceres na
prévia, três tabelas aditivas e vínculo opcional na confirmação. Ver
[contrato atual](CONFERENCIA_E_PROCEDENCIA_DE_FATURAS.md). Revisão semântica
auditável continua necessária antes de propor obrigações/alocações. Migração fd3
testada em cópia e ainda não aplicada ao original nesta rodada.

**Prioridade posterior do usuário: PDF primeiro.** Foi implementado `pdf_auto`
v1 com adaptadores Nubank/PicPay, texto por página, controles bloqueantes e
confirmação como evidência pendente. Cinco originais foram exercitados pela API
em SQLite descartável, com backup/restauração e um bloqueio esperado. Ver o
[guia, fontes e limites](IMPORTACAO_PDF_FINANCEIRO.md). A sequência abaixo
continua como roteiro geral; não voltar a anunciar PDF conhecido como etapa
ainda inexistente. Próximo incremento recomendado é ampliar cobertura por
amostra real; OCR/senha conforme necessidade efetiva, sem IA/Gmail implícitos.

1. Regras, contratos e modelo do banco.
2. Migrações, documentos, revisão e confirmação pela API.
3. Duplicidades e conciliação com operações existentes.
4. Extrato em PDF de um banco, de ponta a ponta.
5. Fatura desse banco com compras, parcelas e pagamento vinculados.
6. Consultas consolidadas e relatórios compatíveis.
7. Outros bancos e OCR conforme necessidade.
8. Gmail como nova origem do mesmo fluxo.

O primeiro incremento entregue estabelece persistência, documentos, dados estruturados, revisão e vínculo de evidência ao livro-caixa, com contratos documentados e validação isolada. Não executa pagamentos nem cria dívidas a partir de faturas. O novo front-end pode consumir esses serviços; leitores de arquivos e integração contábil das faturas seguem nas próximas etapas.
