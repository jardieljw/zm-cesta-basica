# Faturas: significado dos dados, procedência e integração segura

Revisão: **16/10/2026**. Registro de decisões e planejamento do backend.
Responsável pela continuidade: qualquer agente deve ler este documento junto da
[memória financeira](MEMORIA_IMPLEMENTACAO_FINANCEIRA.md), do
[guia de homologação](HOMOLOGACAO_IMPORTACAO_FINANCEIRA.md) e das regras de
[integridade](REGRAS_DE_INTEGRIDADE_E_EVOLUCAO.md).

**Situação:** procedência e conferência da seção 7 implementadas na API, com
[contrato próprio](CONFERENCIA_E_PROCEDENCIA_DE_FATURAS.md); classificação semântica
e integração de obrigações continuam futuras. O código não gera contas a pagar
a partir das faturas. A última consulta somente de leitura do banco local mostrou
`fc2f3a4b6512`; a nova migração `fd3a4b5c7613` foi validada apenas em cópia.
Não interpretar este planejamento como autorização
para reescrever histórico, importar dados reais em produção ou alterar relatórios.

**Prioridade posterior — PDF primeiro, 16/10:** por pedido do usuário, foi
implementado o [leitor automático PDF](IMPORTACAO_PDF_FINANCEIRO.md) para layouts
Nubank/PicPay, com texto/página, controles e confirmação pendente. Cinco originais
foram exercitados pela API em banco descartável; uma fatura continua bloqueada
pela divergência interna já registrada. Isso não implementa a revisão semântica
nem resolve as diferenças entre CSV/PDF. As seções seguintes conservam sua
fundamentação e seu alcance; a extração PDF deixou de ser apenas proposta no
escopo delimitado pelo guia.

## 1. Pedido e finalidade

O usuário quer reunir dívidas e movimentos de vários bancos, PF/PJ, com
duplicidades controladas, prioridade ao backend e dados úteis de fato. Pediu
explicitamente registrar decisões, aprendizado, fontes e arquitetura para
continuidade entre agentes e após compactação. Em 16/10 autorizou prosseguir
na conferência de total/vencimento e no tratamento dos tipos de lançamento.

O objetivo técnico é evitar que compra, parcela, fatura e pagamento virem quatro
despesas. Também evitar o problema inverso: ocultar dívida ou encargo legítimo ao
fundir operações parecidas. Não criar campos/tabelas específicos do Nubank para
resolver diferenças de seus arquivos; usar contrato comum e adaptadores de origem.

## 2. O que o código realmente faz hoje

| Responsabilidade | Implementação e limite |
| --- | --- |
| Original e origem | `financial_documents` conserva bytes/hash; `financial_sources` distingue conta/cartão e PF/PJ. |
| Leitura | `financial_readers.py`: genérico v2 e conta Nubank v1. Configuração explícita; sem OCR/IA/PDF/OFX. |
| Prévia | `financial_import_previews` guarda configuração, versão, hashes e resultado imutável. `READY` significa ausência de erros do leitor. |
| Cabeçalho | `FinancialStatementCreate` exige total declarado e vencimento para `CARD_BILL`; guarda campos declarados. |
| Fatos externos | `FinancialTransactionData.transaction_kind` já tem PURCHASE/BILL_PAYMENT/FEE/INTEREST/TAX/REFUND/OTHER, entre outros. CSV atual não classifica descrições; fica OTHER. |
| Decisões | Revisão/correções e associações de IDs são auditáveis. Correções usam decisões posteriores, não reescrita do fato. |
| Conciliação | Vincula fatos a `cash_flow_entries` existentes; não registra pagamento novo. |
| Contas a pagar | `financial.py:record_payable_payment` cria `PayablePayment`, lança débito e atualiza o título. Chamar novamente não é apenas vincular evidência. |
| Resultado gerencial | `business_dashboard.py:get_business_dashboard` separa estoque, retirada pessoal e outras despesas a partir dos pagamentos e vínculos existentes. Um título genérico de fatura não tem essa composição detalhada. |

Lacunas que motivaram esta etapa: antes da seção 7 não existia associação tipada
entre CSV e PDF de controles. Agora a prévia possui pareceres e evidências por
documento e pode ter vínculo com o statement. Permanecem futuras a revisão
semântica versionada de todas as linhas e propostas de liquidação integradas aos
títulos comerciais. Não esconder essas lacunas em `description`, `notes` ou JSON
de auditoria sem contrato. VERIFIED desta camada não é autorização comercial.

## 3. Evidências reais e o que aprendemos

Os originais autorizados ficaram fora do Git. O registro público contém aliases,
quantidades e resultados, sem titulares, contas, valores, documentos pessoais,
Gmail IDs, tokens ou links de download. PDFs foram lidos por extração de texto e
conferência visual; nenhum leitor automático do app foi criado nesta rodada.

### Rodadas anteriores

CSV de conta PF/PJ e períodos sobrepostos passaram em banco descartável. O
genérico v2 passou a aceitar, por opção explícita, um espaço ASCII após o sinal
monetário, mantendo o padrão estrito. As faturas ficaram READY com 21 e 15 linhas.
Isso continua válido como teste de leitura dos bytes dos CSVs. Não é homologação
de cobertura dos PDFs nem autorização para gerar dívida.

### Cruzamento PDF/CSV — nova evidência de 16/10

| Amostra | Conferência visual | Resultado e consequência |
| --- | --- | --- |
| A | PDF: páginas 1, 3 e 4; cabeçalho, resumo e todos os lançamentos da página de transações. | CSV com 21 linhas e PDF com 19. Há diferenças pontuais de valor, redação de descrições e linhas compensatórias adicionais no CSV. Nomes de arquivo correspondentes não provam equivalência. |
| B | PDF: páginas 1, 4, 5 e 6; cabeçalho, resumo e todas as páginas de transações. | CSV com 15 linhas e PDF com 16. Falta uma ocorrência de crédito no CSV; descrições de alguns encargos diferem. Também foi observada diferença entre soma dos lançamentos do próprio PDF e seu resumo. |

Totais e vencimentos estão declarados nos PDFs e foram conferidos. A equação
dos campos de resumo fecha em ambas as amostras. Contudo, os lançamentos não
correspondem integralmente entre formatos. **As duas amostras ficaram com
`coverage_approved=false`; nenhuma fatura foi confirmada nesta rodada.**

O [relatório sanitizado](validacoes_financeiras/2026-10-16-faturas-cruzamento.json)
compara multiconjuntos de valores com sinal. Ele detecta diferença de quantidades
e valores, mas não prova identidade, ordem, datas ou classificação. Não usar esse
algoritmo para deduplicar operações. A inspeção visual forneceu a evidência de
descrições divergentes. Não investigamos nem afirmamos a causa dessas diferenças.
Não corrigir centavos, criar linha de ajuste ou apagar linhas para fechar o total.

No manifesto privado foram registrados hashes dos dois originais, controles,
páginas e contas de conferência; continuam sujeitos à limpeza da pasta temporária.
Para repetir após essa limpeza, recuperar novamente os originais autorizados.

## 4. Fontes pesquisadas e limites de aplicação

Consulta das fontes abaixo: **16/10/2026**. Links diretos preservados para nova
checagem; regras e versões externas precisam ser verificadas ao integrar.

### F1 — Banco Central: conteúdo de fatura

[BCB — FAQ Cartão, seções 8, 9 e 10](https://www.bcb.gov.br/meubc/faqs/s/cartao)
separa total/vencimento, alternativas de pagamento e lançamentos complementares.
Aplicação no projeto: tratar total declarado e detalhes como informações
distintas. Não tomar oferta de financiamento ou pagamento mínimo como quitação.
O conteúdo foi recuperado na pesquisa indexada; a abertura direta da página
dinâmica retornou uma estrutura sem o texto. A regra de bloquear integração
enquanto houver divergência é decisão do projeto, não obrigação de software
descrita pelo FAQ. Não programar limites legais de juros nesta entrega.

### F2 — Open Finance: conta, fatura e transações são recursos diferentes

[Open Finance Brasil — Informações Gerais, v2.1.0-rc.2, seções 4, 6 e 7](https://openfinancebrasil.atlassian.net/wiki/spaces/OF/pages/163513705/Informa%2Bes%2BGerais%2B-%2BCart%2Bo%2Bde%2BCr%2Bdito%2B-%2Bv2.1.0-rc.2)
apresenta recursos separados para transações, faturas e transações por fatura.
Aplicação conceitual: a fatura agrega evidências; não substitui a identidade dos
eventos e da relação de cartão. Esta é uma referência **histórica RC**, não a
especificação vigente adotada pelo app.

O [índice técnico publicado em 24/04/2026](https://openfinancebrasil.atlassian.net/wiki/spaces/OF/pages/1739292674/Documenta%2Bo%2BT%2Bcnica%2B-%2BAPI%2BCart%2Bo)
apontou Swagger v2.4.0. Os links de
[orientações](https://openfinancebrasil.atlassian.net/wiki/spaces/OF/pages/1739292685/Orienta%2Bes%2B-%2BDC%2BCart%2Bo%2Bde%2BCr%2Bdito) e
[Swagger](https://openfinancebrasil.atlassian.net/wiki/spaces/OF/pages/1739292701/Swagger-%2BAPI%2BCart%2Bo%2Bde%2BCr%2Bdito%2Bv2.4.0)
retornaram somente metadados no acesso anônimo. Não se verificaram enums ou
campos dessa versão; não copiar enums históricos como se fossem atuais. A
integração Open Finance continua fora do incremento.

### F3 — W3C: origem e transformação de dados

[W3C — PROV Overview, introdução e modelo conceitual](https://www.w3.org/TR/prov-overview/),
editores Paul Groth e Luc Moreau, nota de 30/04/2013: procedência relaciona dados,
atividades e responsáveis. Aplicação escolhida: conservar de qual documento,
página e interpretação veio um controle ou decisão. Isso não exige adicionar
RDF/OWL nem uma infraestrutura PROV ao app; a nota é referência conceitual.

### F4 — OWASP: auditoria com redução de exposição

[OWASP — Logging Cheat Sheet, Data to exclude e Event attributes](https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html).
Aplicação: auditar ação, referência, responsável e resultado, evitando que
originais bancários, tokens e dados pessoais sejam copiados para logs ou docs.
Auditoria restrita do domínio e relatório público sanitizado são superfícies
distintas. Isso não comprova que toda a segurança global já foi revisada.

## 5. Registro das decisões de arquitetura

Os IDs abaixo são referências permanentes. Reavaliar por nova decisão com motivo,
fonte e impacto; não apagar a decisão anterior nem atribuir uma inferência ao usuário.

| ID | Decisão, motivo e alternativa descartada | Situação |
| --- | --- | --- |
| FAT-001 | Guardar original, interpretação, decisão semântica, obrigação e liquidação separadamente. Uma linha lida não deve executar uma operação comercial. Rejeitado criar um título para toda linha de CSV. Evidências: código atual, F1 e cruzamento real. | Base já implementada; camada semântica futura. |
| FAT-002 | Preservar total/vencimento declarados e sua procedência. Rejeitado inferir vencimento pelo filename e dívida pela soma de linhas. Evidências: F1 e resumos reais. | Associação e conferência manual implementadas; sem leitor PDF automático. |
| FAT-003 | Distinguir prontidão sintática de cobertura entre documentos e de aptidão comercial. Rejeitado ampliar silenciosamente o significado de READY. Evidências: cruzamento real. | API de parecer separada implementada; aptidão comercial continua futura. |
| FAT-004 | Divergências ficam visíveis e impedem geração automática de obrigações até resolução explícita. Rejeitado eleger CSV ou PDF como sempre correto, tolerar centavos silenciosamente ou fabricar ajustes. | Requisito futuro; nesta rodada não houve confirmação. |
| FAT-005 | Classificação é decisão revisável com procedência, não modificação do original. Texto/sinal podem sugerir, mas não provar tipo, finalidade empresarial ou identidade. Evidência: descrições divergentes e ausência de IDs. | Planejado. |
| FAT-006 | Total do cartão não é uma despesa adicional às compras já registradas. Liquidação deve reaproveitar títulos/vínculos e preservar uma única saída efetiva. Rejeitado criar título genérico da fatura e chamar pagamentos dos títulos originais adicionalmente. | Integração futura, depende de testes de relatório/caixa. |
| FAT-007 | Compra parcelada é diferente de parcelamento da dívida da fatura; saldo anterior não é compra nova. Rejeitado multiplicar o valor da parcela para fabricar o valor total ou futuras parcelas sem evidência. | Regra de desenho; sem gerador automático. |
| FAT-008 | Pagamento recebido/compensado em ciclo anterior não quita a fatura atual. Crédito não significa receita e estorno não prova devolução em caixa. Evidências: F1 e originais. | Base não paga automaticamente; política comercial futura. |
| FAT-009 | PF/PJ da origem não determina natureza de cada gasto. Separar origem, compra de estoque, despesa empresarial, retirada e financiamento antes de refletir em resultado. Evidência: serviço de resumo atual. | Planejado; sem nova classificação contábil. |
| FAT-010 | Modelo e regras de negócio são comuns a bancos; adaptadores traduzem formatos e preservam informações não compreendidas. Rejeitado corrigir divergências adicionando regras por nome de estabelecimento. | Contrato multibanco existente; novas instituições ainda por homologar. |

## 6. Tipos de lançamento: contrato conceitual mínimo

Esta matriz orienta revisão humana e futuros leitores. Não é enum implantado.
`transaction_kind` atual é um fato histórico e não deve ser sobrescrito para
acomodar decisões novas. Não importar automaticamente descrições como classificação.

| Significado observado | Tratamento previsto | Não concluir automaticamente |
| --- | --- | --- |
| Compra/parcela de compra | Vincular compra/título existente; propor obrigação somente se nova e comprovada. Guardar número/total de parcelas apenas quando conhecidos. | Que todo pagamento ao mesmo estabelecimento é a mesma compra; que futuras parcelas têm valor idêntico. |
| Pagamento de fatura | Associar à liquidação e ao movimento bancário comprovados, com ciclo e alocações. | Receita, compra, nova despesa ou quitação da fatura em que a descrição apareceu. |
| Estorno/crédito comercial | Relacionar à operação estornada quando comprovado; distinguir crédito no cartão de dinheiro recebido. | Que todo crédito é estorno ou receita. |
| Juros, multa, tarifa, IOF | Separar componentes e período; propor obrigação apenas se efetivamente cobrada e não registrada. | Que taxa projetada/oferta de pagamento é encargo já incorrido. |
| Saldo anterior/em atraso | Referenciar dívida anterior, investigar cobertura e eventual refinanciamento. | Compra ou despesa nova. |
| Crédito compensatório/reclassificação | Preservar ambas as ocorrências e exigir explicação quando o tipo não estiver claro. | Receita, perdão da dívida ou par compensatório só porque os valores se anulam. |
| Crédito contratado/parcelamento de fatura | Identificar contrato, principal e encargos quando fornecidos; ligar à dívida anterior por operação explícita. | Nova receita ou extinção da dívida anterior sem evidência. |
| Limite, subtotal, oferta, próximas faturas | Informação de contexto em seção própria; não é evento de pagamento. | Saldo bancário, dívida atual ou movimento financeiro. |
| Desconhecido | Manter pendente, conservar original e informar o que falta. | PURCHASE por exclusão, nem ignorar silenciosamente a linha. |

Exemplo **sintético**: compra de insumos de R$ 100 registrada no app e depois
cobrada no cartão. Vincular a compra à cobrança não dá baixa no banco. Ao pagar
o cartão, registrar/conciliar uma saída de R$ 100 que liquide a obrigação
correta; não acrescentar outra despesa de R$ 100 pelo título da fatura. Se já
houve saída registrada, conciliar essa saída em vez de chamar de novo o serviço
de pagamento. O vínculo não altera o custo de estoque congelado.

## 7. Próximo incremento do backend: procedência e qualificação

**Implementado em 16/10/2026**, sem geração de obrigações. O
[guia de procedência](CONFERENCIA_E_PROCEDENCIA_DE_FATURAS.md) é o contrato atual;
acrescenta FAT-011/FAT-012 e conserva aplicação/limites das fontes. O recorte
implementado foi:

1. Associar documentos adicionais a uma interpretação de fatura, com papel
   (controle/cabeçalho ou detalhe), campos comprovados e localizador de página
   ou registro. Verificar mesma origem, moeda e ciclo por evidências; filename
   é apenas pista. Nenhum documento herda automaticamente dados de outro.
2. Registrar conferência append-only: autor/dispositivo, instante UTC, revisão
   esperada, documentos/hashes e versão exata da prévia, resultados por controle,
   diferenças e justificativa. Não duplicar BLOB nem dados privados em logs.
3. Expor avaliação separada de READY: cabeçalho comprovado, cobertura conferida,
   divergências pendentes e qualificação semântica. Os nomes de estados e rotas
   devem ser definidos no incremento, sem mudar clientes existentes.
4. Guardar nova resolução como outra revisão, sem trocar original/cabeçalho/fato
   de uma interpretação antiga. Documento ou prévia novos invalidam a aptidão
   derivada daquela combinação para novas propostas; não apagam a anterior.
5. Começar manual. O operador informa o que conferiu e recebe diferenças
   calculadas; o backend revalida referências e totais. Não aceitar apenas um
   booleano genérico de "aprovado" para contornar divergência sem resolução.

Estado lógico suficiente para armazenar evidência não é aptidão para gerar
obrigação. Cabeçalho pode estar comprovado com detalhes ainda parciais. O usuário
poderá consultar a evidência incompleta sem que o resumo do negócio a contabilize.

### Persistência escolhida no incremento

Três tabelas aditivas: `financial_bill_assessments`, `financial_bill_evidence` e
`financial_bill_assessment_links`, referenciando documentos/prévias/statements e
dispositivos. A conferência começa na prévia e a confirmação aceita vínculo
opcional com o parecer atual. Transcrições estruturadas e observações ficam no
recurso protegido, sem BLOB duplicado ou auditoria genérica com dados bancários.
O fluxo legado sem parecer continua apenas recebendo evidências. A nova camada
tem transação, idempotência, revisão esperada, FKs e gatilhos imutáveis. Migração
fd3 preparada e testada; original não migrado nesta rodada.

Não adicionar agora um sistema de títulos, classificações por banco, motor de
IA, armazenamento genérico de todas as chaves bancárias ou livro-caixa paralelo.

## 8. Incremento posterior: integração de obrigações

Três opções foram avaliadas:

| Alternativa | Avaliação |
| --- | --- |
| Uma conta a pagar por linha importada | Rejeitada: saldo anterior, pagamento e crédito virariam obrigações; ainda duplicaria compras existentes. |
| Uma conta a pagar genérica por total da fatura | Adiada: pode servir como apresentação de cobrança, mas o pagamento atual do título inteiro perde natureza/composição e pode duplicar dívidas/resultado. Não ativar sem desenho das alocações. |
| Fatura como agrupamento de obrigações e evidências, com alocações de liquidação | Direção recomendada: reutilizar títulos existentes e criar somente componentes novos comprovados. Precisa de implementação própria, transacional e revisada. |

Antes de implementar a terceira alternativa, formalizar principal/encargos,
estoque/despesa/retirada, ciclos, saldo anterior, amortização e eventual
refinanciamento. Uma saída pode atender componentes distintos; os vínculos não
podem gerar segunda saída ou atualizar o passado. Pagamento parcial não permite
inferir uma ordem universal de alocação. Não converter antecipadamente título
de fornecedor em "pago" no banco só porque foi financiado no cartão.

Revisar `record_payable_payment`, geração de títulos de compras,
`business_dashboard.py`, relatórios, cancelamento e estornos antes da mudança.
O resumo atual é gerencial e usa despesas pagas; não reinterpretar histórico
como regime de competência em consequência desta integração.

## 9. Critérios de aceite e armadilhas para agentes

Para o próximo incremento, testes sintéticos devem cobrir:

- CSV válido e PDF divergente: leitura continua READY, qualificação fica pendente,
  zero efeitos nos livros. Mesmo nome de arquivo não cria vínculo automático.
- Cabeçalho ausente, moeda/origem/ciclo conflitantes e evidência insuficiente:
  bloqueio de aptidão com código estável e orientação específica.
- Nova prévia e nova resolução preservam a versão anterior; revisão concorrente
  e reenvio não criam duas decisões nem duas propostas.
- Diferença de centavos, linha ausente ou compensatória: preservação e revisão,
  sem tolerância/ajuste oculto. Total líquido de linhas diferente do total da
  fatura não é sozinho prova de erro: validar a composição/cobertura declarada.
- Pagamento anterior não quita cobrança atual; estorno não vira receita;
  principal refinanciado não é nova despesa; origem PJ não transforma gasto
  particular em despesa empresarial.
- Compra já cadastrada + cobrança + pagamento produzem uma obrigação econômica
  e uma saída efetiva, mantendo o tratamento de estoque e resultado.
- Créditos, fatura zero/negativa, múltiplos cartões/ciclos, parcelas com datas
  antigas, pagamentos parciais e divergência entre resumo e detalhes.
- Backup/restauração conserva os documentos, pareceres e relações; migração
  aditiva funciona em cópia preenchida. Testes nunca usam a base da empresa.

Na rodada documental anterior foram reexecutadas as suítes: **363 backend e 238 Flutter
aprovados**, antes e depois das alterações documentais. Não foi alterado código, schema ou
comportamento da API. O cálculo privado do cruzamento passou suas verificações
de resumo e produziu `REVIEW_REQUIRED` para cobertura; isso é um resultado
esperado da conferência, não falha de execução nem aprovação dos documentos.

Após implementar a seção 7: **386 backend e 238 Flutter aprovados**. Migração
fd3 validada em cópia preenchida e homologação da guarda de procedência nos
originais com cobertura pendente. Consultar o guia para o comportamento atual;
a seção 8 e os critérios comerciais acima continuam sem implementação.

## 10. Roteiro de retomada

1. Ler este documento e os relatórios. Não repetir a correção monetária concluída.
2. Procedência/conferência do item 7 concluída no backend; retomar pelo seu guia.
   Evoluir a revisão semântica auditável antes de propostas comerciais. Manter
   integração de títulos desligada e planejar implantação da migração fd3.
3. Preservar diferenças dos originais como casos sintéticos. Não tentar fechar
   as duas amostras alterando seus dados. Investigar com o emissor somente por
   iniciativa/autorização do usuário, sem mandar mensagens automaticamente.
4. Formalizar e validar alocações/efeitos em relatórios antes do item 8.
5. Homologar outra instituição com originais. Gmail automatizado, leitor PDF e
   novo front-end continuam entregas separadas.

Ao concluir cada rodada, acrescentar data, decisão afetada, motivo, fontes
clicáveis, evidência, situação (implementado/testado/proposto), limites e próximo
passo na memória. Mudanças de conclusão devem citar qual evidência as motivou.
