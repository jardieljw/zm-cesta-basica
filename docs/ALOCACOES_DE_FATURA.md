# Alocações de fatura: diagnóstico e próximo contrato

**Plano vigente após a auditoria — 19/10/2026:** retomar pelo
[plano de importação até Contas a Pagar](PLANO_IMPLEMENTACAO_IMPORTACAO_FATURAS.md)
e [roteiro curto](RETOMADA_IMPORTACAO_FATURAS.md). A solução recomendada trata
créditos no agrupamento da fatura; o motor manual descrito abaixo não é etapa
obrigatória. E1–E5 ainda não implementadas.

**Escopo corrigido pelo usuário, 19/10/2026:** consultar primeiro
[o resultado solicitado](ESCOPO_IMPORTACAO_DE_FATURAS.md). O diagnóstico abaixo
existe, mas não é a entrega principal. O plano detalhado de alocações manuais é
uma alternativa técnica anterior, sem obrigação de implementá-la por completo.
Prioridade é importar as faturas efetivamente usadas para Contas a Pagar com
identificação e parcelas. Reavaliar o modelo mínimo, inclusive crédito no total
da fatura, antes de acrescentar tabelas/telas ou exigir vínculos manuais por linha.
Preservar exatidão e prevenção de duplicidade; não confundir simplificação com
liberar os bloqueios atuais sem uma representação correta do valor devido.

Revisão: **19/10/2026**. Complementa a [arquitetura semântica](ARQUITETURA_SEMANTICA_DE_FATURAS.md)
e a [correção da importação](CORRECAO_IMPORTACAO_FINANCEIRA_2026-10-19.md).
Os PDFs e lançamentos bancários disponíveis são massa de testes autorizada,
conforme esclarecimento do usuário; não há recuperação contábil a executar.

## Implementado nesta continuação

A API oferece `GET /api/v1/financial-imports/statements/{id}/allocation-requirements`,
com autenticação financeira estrita. `expected_review_id` opcional recusa a
consulta se outra revisão tiver sido salva. O resultado distingue pendências por
linha da revisão vigente; saldo anterior só declarado no resumo conserva
`item_id=null` e `origin=REPORTED_SUMMARY`. Não inventa uma linha no documento.

| Código | Informação e vínculo ainda necessário |
| --- | --- |
| `SEMANTIC_REVIEW_REQUIRED` | Classificar explicitamente os itens antes de discutir os vínculos. |
| `EXACT_COMPONENT_REVIEW_REQUIRED` | Diferença exata entre composição e total; sem ajuste compensatório. |
| `CREDIT_TARGET_REQUIRED` | Crédito/estorno precisa da compra ou obrigação original, valor alocado e atribuição empresarial/pessoal. Não cria entrada de caixa. |
| `HISTORICAL_PAYMENT_LINK_REQUIRED` | Pagamento precisa do ciclo pago e do pagamento existente. Sua presença na fatura não quita a cobrança atual. |
| `PRIOR_DEBT_LINK_REQUIRED` | Saldo anterior precisa das obrigações anteriores, principal/encargos e saldo ainda devido. Não cria nova despesa. |
| `PURCHASE_PAYABLE_LINK_REVIEW` | Compra de estoque vinculada apresenta seus títulos, situação, saldo, número de parcela e vencimento. Nenhum candidato é escolhido automaticamente. |

`installment_observations` conserva parcela atual/total, data da compra conhecida
e vencimento da fatura. `CURRENT_INSTALLMENT_ONLY` não gera as parcelas futuras,
não calcula vencimentos inexistentes e não interpreta números no texto livre.
O valor informado é o da ocorrência atual, sem multiplicação pelo total de parcelas.

O diagnóstico está **somente no backend**, sem tela ou botão novo no Flutter.
Não constitui prévia de pagamento ou autorização para gerar títulos.
`scope=REQUIREMENTS_ONLY`, `authorizes_generation=false` e `affects_ledger=false`
fazem essa distinção no contrato. Uma lista vazia de pendências desta consulta
não certifica o documento: versão do leitor, controles, ciclo já representado,
revisão vigente e as demais precondições continuam validados na geração.
Situação/saldo de títulos são uma observação no momento da consulta, sem reserva.

Implementação em `backend/app/services/financial_bill_allocations.py` e na rota
financeira existente. A consulta usa os serviços e entidades do domínio, sem
gravar parecer, auditoria, classificação, caixa, título, compra ou estoque.
Não houve tabela ou migração nova. Os bloqueios da geração não foram alterados.

## Modelo para o próximo incremento — ainda proposto

A recomendação é começar por **crédito da mesma fatura dirigido a componente
novo ainda não gerado**, antes de alterar títulos pagos/parciais ou tratar ciclos
anteriores. É um recorte técnico do agente dentro da continuação autorizada;
não é uma preferência financeira universal atribuída ao usuário.

Comparação: distribuir proporcionalmente todo crédito entre gastos seria uma
decisão econômica sem evidência; escolher automaticamente a primeira compra
com mesmo valor confundiria semelhança com identidade. A escolha explícita
preserva a natureza do componente e permite rastrear crédito dividido entre
mais de uma compra. Créditos sem alvo identificável permanecem pendentes.

Antes de liberar geração líquida, implementar os seguintes contratos em conjunto:

1. **Decisão persistida e versionada:** plano com fatura, revisão semântica,
   revisão esperada do plano, autor, motivo e alocações por item de origem/alvo.
   Usar tabelas aditivas e FKs via Alembic; não esconder o estado comercial em
   texto de notas ou no JSON genérico da auditoria. Planos/versões anteriores
   permanecem consultáveis. Uma revisão semântica nova invalida o plano para
   operações novas, sem apagar suas evidências.
2. **Conservação exata:** cada crédito deve ser coberto uma única vez no plano;
   cada alvo conserva valor bruto, parcela do crédito e valor líquido. Zero de
   tolerância. Alocação não pode superar o crédito nem o componente alvo. Crédito
   excedente, alvo de outro cartão/ciclo ou mistura de natureza exigem tratamento
   específico; nenhum saldo residual vira receita ou encargo automático.
3. **Geração única:** revalidar revisão/plano/ciclo dentro de `BEGIN IMMEDIATE`,
   com idempotência. Gerar somente obrigações líquidas novas; conservar o bruto e
   a origem do abatimento para explicar a composição. A fatura não é outra despesa
   além dos componentes. Alvo já vinculado a compra/título exige o modelo próprio
   de abatimento; não modificar silenciosamente `original_amount_cents` ou simular
   um pagamento em dinheiro para representar crédito de cartão.
4. **Pagamentos anteriores:** vincular o fato bancário a pagamentos e obrigações
   do ciclo realmente pago. Uma transação de conta e a linha do cartão podem ser
   evidências do mesmo desembolso; não criar uma segunda saída. Pagamento parcial
   exige distribuição explícita e revalidação dos saldos. Não supor ordem universal
   de amortização e não compensar numericamente saldo anterior/pagamento sem links.
5. **Saldo anterior/refinanciamento:** representar a continuidade de principal e
   encargos já existentes, com saldo remanescente por obrigação. Refinanciamento
   não cria uma segunda despesa principal. Encargos novos comprovados são
   componentes próprios. Dívida histórica não identificada exige conferência;
   não criar um título genérico adicional para fechar a equação.
6. **Parcelas e compras existentes:** permitir escolher título/parcela e valor
   coberto, incluindo divisão de uma ocorrência entre títulos quando comprovada.
   Revalidar compra confirmada, saldo e situação dos títulos, sem alterar estoque
   ou CMPM. Parcela paga/cancelada e coincidência de descrição/valor não autorizam
   novo vínculo. Datas de compra, cobrança e vencimento ficam separadas.
7. **Revisão no cliente:** apresentar origem, destino, bruto, crédito e líquido
   no fluxo visual já aprovado, com rascunho e confirmação explícitos. Persistir
   identidade de comando e tratar resposta incerta conforme Pagar/Receber.
   Comparar efeito em resumo gerencial, pagamentos, cancelamentos e estornos
   antes de habilitar a ação operacional.

Os testes de aceitação futuros devem exercitar concorrência, replay, rollback
integral, crédito total/parcial/dividido/excedente, alvo de natureza diferente,
revisão antiga, ciclo sobreposto, títulos pagos/parciais/cancelados, saldo anterior
que se compensa com pagamento, parcelas com compra antiga e ausência de dívida
ou caixa duplicados. Migração precisa de cópia preenchida e backup verificado.

## Validação e continuidade

Oito regressões sintéticas verificam o diagnóstico vigente, revisão concorrente,
conta incompatível, autenticação, ausência de gravações e candidatos de uma compra
com parcelas paga/aberta. A homologação HTTPS usa um caso de crédito inteiramente
sintético em banco descartável; o diagnóstico identifica o alvo faltante e a
geração continua bloqueada. Ver [evidências da continuação](validacoes_financeiras/correcao-2026-10-19/README.md).

Mapeamento assistido de D/C, duas colunas e moeda, homologação adicional por
layout, OCR, OFX e Open Finance continuam pendentes; o diagnóstico de alocação
não implementa esses leitores. As alternativas e fontes primárias preservadas
na [auditoria de 19/10](AUDITORIA_IMPORTACAO_FINANCEIRA_2026-10-19.md#4-pesquisa-como-ampliar-a-importação-corretamente)
continuam a fundamentação, sem nova pesquisa ou ampliação de cobertura nesta rodada.
