# Diagnóstico da importação financeira — 19/10/2026

Escopo autorizado: inspeção e planejamento, retomando a pergunta do usuário
«agora o que falta implementar?». Nenhuma correção funcional, migração da
empresa, pagamento, geração de obrigação real ou distribuição nesta rodada.
Fontes: código local e documentos indicados abaixo, consultados em 19/10/2026.

## Conclusão e ordem recomendada

A base de importação, interface e integração com contas a pagar já existe.
A prioridade é corrigir os caminhos que podem atribuir significado financeiro
indevido, demonstrar ausência de dupla contagem e homologar a execução entregue.

| Prioridade | Pendência concreta | Evidência e alcance |
| --- | --- | --- |
| P0 | Restaurar fechamento exato e preservar controles declarados. | `financial_bill_semantics.py:create_semantic_review` aceita diferença absoluta até 10 centavos, soma a diferença aos encargos e aprova a revisão. Também pode substituir o saldo anterior para fechar a equação. `financial_bill_review_view.dart` aceita a mesma tolerância. Isso contradiz FAT-004 e a memória de fechamento exato; não é apenas pendência de teste. |
| P0 | Tratar dados ausentes como pendentes. | `financial_pdf_readers.py:parse_tabular_statement` fabrica total da fatura pela soma das linhas e vencimento pela última data quando faltam. Datas observadas também são usadas como período declarado. Separar observação/inferência de controle comprovado antes de permitir efeitos comerciais. |
| P0 | Fechar prevenção de dupla contagem entre extrato, compra, fatura e pagamento. | `financial_imports.py:post_statement_to_treasury` já grava caixa: atribui `RECEITA`/`DESPESA` e `BUSINESS` conforme o sinal, sem exigir revisão individual; apenas pula transações com conciliação ativa. Isso não demonstra correspondência com pagamentos já registrados. `business_dashboard.py` inclui `BANK_IMPORT` nos recebimentos/despesas. Transferências, empréstimos, retiradas e pagamento de cartão precisam de tratamento explícito. |
| P0 | Consolidar revisão humana, vínculos e versão vigente antes de gerar obrigações. | `financial_imports_view.dart:_launchCardBillDirect` classifica pela descrição/sinal e gera títulos se a equação fechar; o padrão é compra empresarial e “saldo em atraso” é sugerido como encargo. Em `financial_bill_review_view.dart:_generateObligations`, havendo revisão salva, alterações locais podem não ser salvas antes da geração. A API aceita `review_id` antigo aprovado sem exigir a última revisão. Validar compras canceladas/pagas, parcelas e valores vinculados; hoje a revisão verifica principalmente a existência da compra. |
| P0 | Representar créditos e dívida anterior nos vínculos da obrigação. | `financial_bill_semantics.py:generate_bill_obligations` gera pelas compras/encargos e pula créditos, pagamentos e saldo anterior. Exemplo sintético: compra de 100 e crédito de 20 podem fechar revisão em 80, mas gerar título de 100; saldo anterior sem obrigação vinculada pode ficar sem representação. Exigir alocação e cobertura da dívida, preservando uma única obrigação econômica. |
| P1 | Homologar por banco/layout e tornar a cobertura reproduzível. | Adaptadores CSV e detecção PDF Itaú/Santander/Inter existem. A memória de 17–18/10 relata ampliação com originais, mas não foi localizado relatório sanitizado equivalente por esses layouts em `docs/validacoes_financeiras/`. A suíte PDF permanente exercita principalmente Nubank/PicPay sintéticos. Um teste semântico depende de CSV privado em caminho absoluto; não é uma fixture portátil. Não declarar suporte universal ou homologia integral. |
| P1 | Validar a entrega instalada e o leitor PDF empacotado. | `financial_pdf_runtime.py:extract_pdf` retorna `PDF_RUNTIME_UNAVAILABLE` quando `sys.frozen` é verdadeiro. Precisa de solução para o processo extrator e validação no servidor distribuído. Executar por Python é uma alternativa operacional a comparar, não prova de funcionamento do executável congelado. Build do cliente não atualiza nem valida o servidor. |
| P1 | Verificar segurança e recuperação do conjunto efetivamente entregue. | A autenticação das rotas de importação exige token ativo, mas `api/deps.py:get_current_device` ainda tem fallback de mestre local em outros fluxos. SQLite/backups seguem sem nova criptografia de aplicação. Revisar acesso a originais/exportações, permissões e restauração com todas as tabelas atuais, sem anunciar ausência de backup: já há mecanismo e testes. |
| P2 | Implementar OCR/OFX e avaliar coleta automática depois. | PDF digital tem leitores; PDF sem texto retorna `PDF_OCR_OR_TEXT_REQUIRED`. Receber OFX/QFX como documento não equivale a interpretá-los. Gmail/Open Finance continuam entregas próprias. Senha já existe e não pertence à lista de funções ausentes. |

Os riscos acima foram identificados por inspeção de código. A aprovação das
suítes não reproduz nem resolve automaticamente cada cenário apontado.

## O que já está implementado

- Fontes bancárias/cartões, armazenamento do original com hash, prévias
  versionadas e confirmação: `backend/app/services/financial_imports.py`,
  `financial_previews.py`, `financial_readers.py` e API correspondente.
- Leitura PDF local, páginas/procedência e senha efêmera no processo extrator:
  `financial_pdf_readers.py`, `financial_pdf_runtime.py` e `financial_pdf_worker.py`.
  Verificar também nova tentativa após senha incorreta: o cache distingue apenas
  presença/ausência de senha em `interpretation`, não a correção da tentativa.
- API de revisão de duplicidades, correções históricas e conciliação. Sua
  existência não comprova que o atalho de lançamento direto preserve as regras.
- Procedência/conferência e revisão semântica com geração ou vínculo de
  `accounts_payable`: `financial_bill_assessments.py` e `financial_bill_semantics.py`.
  Créditos, pagamentos e saldo anterior não criam títulos nesse gerador, mas
  ainda precisam de alocação/vínculos para refletir corretamente o valor devido.
- Telas `financial_sources_view.dart`, `financial_imports_view.dart` e
  `financial_bill_review_view.dart`, com serviço REST e acessos em
  `app_finance_view.dart`. Não planejar sua criação novamente.

## Testes, originais e instalação são evidências distintas

**Código atual:** nesta rodada passaram **449 testes backend**, com 14 avisos,
e **356 testes Flutter**, em execução sequencial. As primeiras tentativas no
executor restrito falharam na criação de temporários ou não progrediram;
foram interrompidas pelas respectivas sessões. Repetição concluída com execução
autorizada e bancos temporários isolados. Não foram adicionados testes nesta
rodada. Logs locais ficam em `tmp/diagnostico-financeiro-20261019/`, fora do Git.

**Originais:** os relatórios sanitizados de 16/10 comprovam CSV Nubank PF/PJ e
cinco PDFs Nubank/PicPay, 151 ocorrências, quatro confirmações em banco
descartável e um bloqueio esperado por quatro centavos. Não se reexecutou essa
homologação nem se recuperaram originais/Gmail nesta rodada. A memória posterior
relata novos bancos e amostra Nu Empresas com 28 itens; o relato deve ser
complementado por evidência reproduzível de cada layout antes de ampliar a
declaração de suporte.

**Banco local:** consulta direta com SQLite `mode=ro` em
`backend/data/estoque.db` encontrou **`fe4b5c6d8714` e 48 tabelas**, incluindo
procedência e semântica/obrigações. A cadeia no código é fc2 → fd3 → fe4;
não foi identificada revisão posterior. Logo, “aplicar fd3/fe4 ao banco local”
não é pendência confirmada. Não se atribui a esta rodada a migração anterior,
nem se afirma que toda instalação externa use esse mesmo arquivo. Não houve
upgrade/downgrade nesta análise.

**Aplicativo instalado:** existe executável Flutter Release local datado de
17/10. Sua existência não comprova atualização de uma instalação externa,
homologação física Android/iOS, equivalência visual integral ou funcionamento
do extrator em servidor congelado. Não foi executado fluxo comercial no app.

## Reconciliação documental e próxima entrega proposta

Os trechos históricos de `AGENT_INSTRUCTIONS.md`, `ARCHITECTURE.md`, READMEs,
[guia PDF](IMPORTACAO_PDF_FINANCEIRO.md),
[homologação](HOMOLOGACAO_IMPORTACAO_FINANCEIRA.md) e
[arquitetura semântica](ARQUITETURA_SEMANTICA_DE_FATURAS.md) que dizem “sem
interface”, “senha futura”, “Santander sem leitor”, “sem integração de títulos”
ou “banco em fc2” descrevem rodadas anteriores. A
[memória financeira](MEMORIA_IMPLEMENTACAO_FINANCEIRA.md) de 17–18/10 e o código
superam essas afirmações quanto à existência das funções. As regras de
integridade e a fundamentação detalhada continuam válidas; existir código não
comprova atendimento integral a elas.

Próximo incremento recomendado: corrigir os pontos P0, conservando a
interface aprovada e o histórico. Validar em bancos descartáveis: diferença de
1/4/10 centavos bloqueada sem ajuste; controles ausentes sem invenção;
compra + cobrança + pagamento com uma obrigação econômica e uma saída;
créditos/saldo anterior; extratos sobrepostos; conciliação parcial/desfeita;
revisão antiga ou editada; compra já paga/cancelada e parcelas. Conferir efeitos
no resumo e relatórios, não apenas o número de títulos/linhas de caixa.

Alternativas avaliadas: ampliar bancos/OCR/Gmail agora aumentaria cobertura de
entrada sobre regras comerciais ainda inseguras; recriar as telas repetiria
trabalho já entregue. Recomenda-se primeiro esse recorte de integridade, depois
homologação e empacotamento, sem expansão indiscriminada. Trata-se de proposta
de sequência, sem autorização implícita para implantação ou operações reais.

Registro complementar localizado no workspace durante esta rodada:
[auditoria da importação](AUDITORIA_IMPORTACAO_FINANCEIRA_2026-10-19.md), com
casos de caracterização próprios. Seus 14 casos adicionais e observações dos
documentos/efeitos já armazenados não foram reexecutados por esta análise;
consultá-los antes de corrigir ou investigar registros existentes. Preservado
sem alteração, assim como os arquivos de outros trabalhos.
