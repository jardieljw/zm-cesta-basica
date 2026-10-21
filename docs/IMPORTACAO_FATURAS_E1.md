# Importação de faturas — entrada e controles E1

**19/10/2026 — implementado no código, sem ativação.** E1.1, E1.2 e E1.3 do
[plano existente](PLANO_IMPLEMENTACAO_IMPORTACAO_FATURAS.md). Próximo incremento:
E2 naquele fechamento. E2/E3 estão no [guia atual de Pagar](CONTAS_A_PAGAR.md);
o estado único de continuidade está na [retomada](RETOMADA_IMPORTACAO_FATURAS.md).
A leitura isolada não conclui a integração com Contas a Pagar.

## Comportamento da interface

Financeiro → Documentos financeiros → escolher conta/cartão → selecionar PDF/CSV
→ Ler documento. Selecionar ou trocar arquivo conserva a origem escolhida;
nome do arquivo não seleciona outro cartão. Sem origem, a pessoa faz uma escolha
explícita, inclusive quando existem dois cartões do mesmo banco.

CSV usa reconhecimento do conteúdo no servidor; a tela não exige escolher um
leitor técnico. Mercado Pago/PicPay em formato de índice recebem explicação de
que faltam os detalhes, em vez de leitor de conta incompatível ou fallback pelo
nome do banco. O mapeamento CSV explícito continua na API para os consumidores
existentes. Layout compartilhado não comprova instituição emissora.

Na conferência, vencimentos conflitantes aparecem com data e página; nenhum
deles vira automaticamente o vencimento operacional. Cabeçalho extraído confiável
preenche a revisão CSV. Campo ausente permanece vazio: soma dos itens não
preenche total declarado, nem hoje preenche vencimento.

O complemento de documentos está disponível pelo contrato da API/serviço; a
escolha guiada desse complemento e a resolução operacional dos vencimentos
ficam para a conferência das próximas etapas. O layout/tema vigente foi mantido.

## Leitores, fatos e procedência

- `csv_auto` v1 examina cabeçalhos, identifica índice, compilação, detalhe ou
  ambiguidade. Só despacha para um adaptador compatível com o tipo da origem.
  Um namespace compatível pode ser desambiguado pela origem explicitamente
  selecionada e seu PF/PJ; sem essa declaração, a ambiguidade permanece.
- `pdf_auto` v3; `generic_csv` v4; adaptadores CSV conhecidos v3. Versões novas
  geram prévias imutáveis novas, conservando as anteriores. O adaptador detectado
  e sua versão ficam no relatório CSV automático.
- Normalizador compartilhado de parcelas no CSV/PDF: `Parcela 3/10`, `PARC01/02`
  e sufixo ` - 3/10`; valida `1 ≤ atual ≤ total ≤ 1000`. Um `3/10` solto pode ser
  uma data e fica sem inferência. Coluna e texto contraditórios bloqueiam a linha.
- Descrição, ocorrência repetida, sinal e centavos são preservados. Notas do PDF
  e linhas CSV originais permanecem em `raw_text`. Não há linha compensatória.
- Papéis automáticos: compra, encargo, pagamento, crédito, saldo anterior ou
  desconhecido. `transaction_kind` conserva o fato normalizado; `role` explicita
  o papel na prévia e `purpose=UNSPECIFIED` conserva finalidade desconhecida.
  Nenhuma regra preenche BUSINESS/PERSONAL pelo estabelecimento ou por PF/PJ.
- `controls` distingue HEADER/TOTAL/MINIMUM/SUMMARY_COMPONENT/SUBTOTAL/OFFER,
  com documento, página/linha, texto, leitor/versão e origem da declaração.
  Controles/ofertas/subtotais não geram compras.
- `header_candidates` conserva os candidatos, inclusive os dois vencimentos;
  campo conflitante é removido de `extracted_header`. Nome do arquivo não é fonte.

## Contrato e efeitos no banco

`financial_import_previews.result` recebe `contract_version=1`, `content_type`,
`controls`, `header_candidates` e `readiness` tipados. A leitura continua usando
documentos/prévias e auditoria existentes. **Não há migração ou tabela nova.**

`readiness.version=1` separa:

| Campo | Significado |
| --- | --- |
| `header_status` | MISSING, CONFLICTING, DOCUMENT_VALIDATED ou OPERATOR_DECLARED |
| `details_status` | SUMMARY_ONLY, AVAILABLE_UNRECONCILED ou RECONCILED |
| `total_basis` | DOCUMENT, CALCULATED_ONLY ou MISSING |
| `difference_cents` | Soma dos detalhes menos controle comparável; inteiro exato ou ausente |
| `pending` | Códigos/campos e bloqueios de cabeçalho/detalhes separados |
| `can_prepare_bill` | Controles permitem preparar o percurso de cobrança; não grava título |
| `can_prepare_complete_details` | Cabeçalho e detalhe passam também pela conferência exata disponível |
| `financial_status` / `can_generate_obligations` | PENDING / false, sempre nesta camada |

READY mantém seu significado antigo de leitura sem erro; não é dívida gravada.
Uma diferença exata entre detalhe e resumo conserva a prévia INVALID no fluxo
atual, mas o contrato identifica separadamente o cabeçalho válido para o percurso
D4 a implementar em E2. Erros de leitura e cabeçalho continuam explícitos.
O relatório pode estar reconciliado internamente sem provar cobertura entre dois
formatos. Não altera pareceres de conferência anteriores.

`FinancialPreviewCreate` aceita `control_preview_id` e `cycle_due_on`. Complemento
exige prévia imutável de uma fatura única, mesma origem, cabeçalho apto e ciclo
igual. Se o CSV não comprova ciclo, a declaração explícita do operador fica
marcada como tal. Compilação, conflito, outra origem, data de linha posterior ao
vencimento ou ciclo incompatível são recusados. Total/vencimento passam com a
procedência do documento complementar; isso não certifica cobertura dos itens.
Confirmar não permite sobrescrever controles extraídos. Campos declarados e
campos documentais são separados na auditoria da confirmação CSV.

As revisões semânticas/obrigações antigas continuam com suas proteções. A nova
representação de propósito neutro, cobrança líquida, relatório gerencial,
pagamento e agenda ainda depende de E2–E4. Não foi importado teste na base da
empresa nem atualizado o aplicativo/servidor instalado.

## Verificação e limites

Testes permanentes em `backend/tests/test_financial_e1.py`, leitores existentes e
testes Flutter de importação/cabeçalho. T01–T07 cobertos no alcance de E1; os
efeitos em títulos/lucro de T05/T06 dependem de E2, e a decisão operacional de
vencimento/conferência guiada depende das etapas seguintes.

[Evidência sanitizada das amostras](validacoes_financeiras/e1-2026-10-19/amostras-sanitizadas.json):
hashes iguais aos da auditoria, linhas/valores/descrições comparados privadamente.
PDFs 06/07/08 mantêm 28/39/22 linhas; PDFs 07/08 estruturam 3/2 parcelas;
CSVs 05/06 mantêm 21/13 linhas e estruturam 9/3 parcelas. Diferenças −6/+2 centavos
permanecem; outubro conserva 24/26 com procedência. Mercado Pago/PicPay fornecidos
são índices sem compras e ficam assim identificados. Originais/referências não
foram copiados para fixtures públicas.

A revisão visual usa renderização Flutter com dados sintéticos e tamanhos
equivalentes de teste. Não certifica o seletor nativo Windows, dispositivos
físicos ou fidelidade integral de todas as telas. Não houve build/ativação,
pesquisa repetida, API de IA ou migração no banco da empresa.

**512 testes backend e 373 Flutter aprovados; análise sem pendências.** HTTPS
com certificado/banco descartáveis e worker PDF separado também passou, com
reenvios reutilizados e livros inalterados.
[Relatório HTTPS](validacoes_financeiras/e1-2026-10-19/https-sanitizado.json).

Comandos, resultados finais e próximo passo ficam no
[registro de retomada](RETOMADA_IMPORTACAO_FATURAS.md), atualizado nesta entrega.

## Referências de implementação

Backend: `app/services/financial_normalization.py`, `financial_readers.py`,
`financial_pdf_readers.py`, `financial_preview_contract.py`,
`financial_previews.py` e `app/schemas/financial_readers.py`.
Cliente: `lib/views/financial_imports_view.dart`,
`financial_header_review_view.dart`, `lib/services/financial_import_service.dart`,
`lib/utils/api_error_mapper.dart` e catálogo l10n.
