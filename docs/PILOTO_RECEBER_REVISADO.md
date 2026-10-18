# Recebimento revisado e continuidade do financeiro

**FE-054 — 17/10/2026. Implementação incremental Flutter/API.** Continuação
autorizada por “Vambora uhuuu” e pelos pedidos posteriores de retomar, após a
distinção entre o piloto real e a prévia do aplicativo completo. Complementa o
[piloto de Pagar](PILOTO_PAGAR_REVISADO.md); conserva a
[referência visual FE-052](referencias_frontend/rodada-acabamento-2026-10-16/README.md).

## 1. Localização e percurso

Em **Contas a Receber**, tocar na conta ou em **Registrar recebimento** abre
detalhe, histórico, Integral/Parcial, data/forma/observação, revisão, confirmação
e retorno. O diálogo anterior de recebimento foi substituído. A consulta antiga
de histórico/estorno continua disponível; estorno tem suas regras próprias.

- **Integral** começa com o saldo pendente, não o valor original da venda.
  Parcial revela seu campo suavemente; ao voltar para Integral, o valor parcial
  oculto não entra no comando. Entrada monetária usa centavos inteiros.
- A forma começa sem escolha. Receber usa **CASH, PIX, CARD, OTHER**; não
  copiar os códigos de Pagar. O operador não escolhe conta interna ou rota.
- O calendário seleciona dia civil. Editar a revisão conserva forma, data,
  observação e escolha de valor. Não há POST antes da confirmação.
- Antes da revisão, consulta-se o título. Se saldo/situação mudar, conservar
  preenchimento, mostrar o saldo novo e exigir revisão novamente.
- A confirmação identifica cliente e venda de origem, valor, dia, forma e
  saldo esperado. O detalhe mostra original, recebido, pendente e histórico,
  incluindo estorno e motivo quando presentes.
- **Ver venda de origem** consulta a venda pelo serviço existente na mesma
  conexão vinculada. Exibe cliente, valor original, data, condição e itens.
  A consulta é somente leitura e tem erro/tentativa de atualização próprios.

Receber amortiza o título da venda; não cria venda nova nem altera seu total,
itens, custos ou estoque. O serviço existente sincroniza `sales.payment_status`.
O teste integrado também confere que o estorno conserva esses registros.

## 2. Lista, filtros e cobertura

A lista usa fundo suave azul/quente, painéis translúcidos, linhas de extrato
com cliente/venda/saldo e valores original/recebido separados. Filtros começam
**recolhidos**, com o recorte aplicado visível. As opções anteriores de período,
cliente, cesta e valores continuam acessíveis dentro do painel; identificadores
de cadastro ainda são os filtros legados, sem novo seletor de busca nesta rodada.

**Em aberto, incluindo parciais** usa `open_only=true`, sem `status=OPEN`.
O filtro legado de API `status=OPEN` continua exato para seus consumidores.
Todas as situações continua sendo o recorte inicial; não foi inferida outra
preferência do usuário. Vencimento de hoje não é atraso: lista e detalhe usam
o mesmo dia de negócio UTC−03 já usado no resumo.

**Resumo das contas exibidas** soma somente as páginas carregadas. Há ação
para carregar mais de cem títulos, com offset real e deduplicação por ID.
Cada consulta congela os filtros aplicados, inclusive para as páginas seguintes;
digitar outro valor sem Aplicar não mistura consultas. Respostas antigas não
substituem um recorte mais recente. Erro e carregamento não mostram zero como
se fosse uma consulta concluída. A soma não é saldo bancário nem total global.

Tentativas e recibos locais aparecem fora do filtro de títulos, inclusive se
uma quitação deixar de aparecer em Em aberto. Voltar da jornada preserva os
critérios da lista; Atualizar consulta os dados novamente.

## 3. Contrato aditivo do servidor

`POST /api/v1/receivables/{id}/payments` acrescenta campos opcionais:

| Campo | Contrato |
| --- | --- |
| `expected_balance_cents` | Saldo revisado; conferido dentro do callback sob `BEGIN IMMEDIATE`. Divergência retorna 409 `RECEIVABLE_BALANCE_CHANGED` antes de registrar. |
| `payment_business_date` | Dia ISO `YYYY-MM-DD` UTC−03, mutuamente exclusivo com `payment_date`. Representado em UTC pelo início desse dia, 03:00Z; não é horário efetivo informado pelo operador. |

O novo cliente sempre fornece ambos e exige `payment_review_version=1` no
detalhe. Um servidor anterior não pode ignorar silenciosamente a precondição.
Consumidores legados podem continuar usando datetime ou data omitida. Os dois
campos novos nulos ficam fora do hash; defaults antigos permanecem no hash
legado. Não reescrever datas ou pagamentos históricos.

Replay da mesma chave/operação/corpo é resolvido **antes** da precondição de
saldo. Uma quitação confirmada pode ser recuperada com saldo atual zero ou
alterado por estorno posterior. A precondição é do saldo, não uma versão de
todo o histórico. Nenhuma tabela ou migração foi acrescentada.

Recusas estruturadas do callback: `RECEIVABLE_BALANCE_CHANGED`,
`RECEIVABLE_NOT_OPEN`, `RECEIVABLE_NOT_FOUND`,
`RECEIVABLE_AMOUNT_EXCEEDS_BALANCE`, `RECEIVABLE_PAYMENT_METHOD_INVALID`.
Os códigos viram mensagens em português no mapper, sem decidir pelo texto do erro.

## 4. Tentativa, conexão e confirmação

O comando é salvo antes do POST com origem (URL/fingerprint públicos), título,
cliente/venda de referência, chave UUID e corpo imutável. Token não faz parte
desse objeto. Falha de persistência impede começar o envio. O namespace de
Receber é `receivable_payment_v1`; Pagar conserva `payable_payment_v1`, formato
JSON e chaves anteriores. Não descartar silenciosamente dados corrompidos.

**Retomar registro** repete o mesmo POST e pode concluir a intenção original ou
obter seu recibo. Não é uma consulta somente leitura. Trocar servidor/fingerprint
impede enviar à nova origem. O cliente vinculado conserva TLS/pinning/token e
limite de resposta; timeout não significa cancelamento no servidor.

Falhas de transporte, autenticação, GET, 422, 5xx, chave incompatível e operação
em andamento conservam a tentativa. Somente a recusa estruturada do POST após
a busca por replay permite liberar essa identidade. Dois coordenadores locais
não criam outro comando simultâneo para o mesmo módulo/origem/título.

Confirmação válida verifica título, valor, meio, dia, observação e identificação
do recibo; no fluxo novo não se aceita resposta de cobrança em rota. Confirmação
conhecida permanece conhecida mesmo se salvar o recibo local ou atualizar o
saldo falhar. Atualizar a consulta repete apenas GET. Sair pelo botão de conclusão
reconhece o recibo local; voltar pela navegação conserva seu acompanhamento.

## 5. Responsabilidades e reutilização

| Arquivo/camada | Responsabilidade |
| --- | --- |
| [ReceivablePaymentView](../client/lib/views/receivable_payment_view.dart) e [PayablePaymentView](../client/lib/views/payable_payment_view.dart) | Adaptadores tipados: nomes, identificação, métodos e efeitos próprios de cada módulo. |
| [ReviewedPaymentView](../client/lib/widgets/shared/reviewed_payment_view.dart) e [contrato](../client/lib/widgets/shared/reviewed_payment_contract.dart) | Máquina de apresentação única: detalhe, formulário, revisão, foco, calendário, estados e consulta posterior. |
| [ReceivablePaymentCoordinator](../client/lib/services/receivable_payment_coordinator.dart) e [motor compartilhado](../client/lib/services/reviewed_payment_coordinator.dart) | Validar comando/recibo do domínio e compartilhar persistência, identidade, lock, conexão e retomada. |
| [ReceivableService](../client/lib/services/receivable_service.dart), [SaleService](../client/lib/services/sale_service.dart), [ApiClient](../client/lib/core/api_client.dart) | REST e conexão segura; interface não acessa SQLite. |
| [ReceivablesView](../client/lib/views/receivables_view.dart) e [SaleOriginView](../client/lib/views/sale_origin_view.dart) | Lista/páginas/recorte, acesso ao histórico legado e consulta da venda original. |
| [API](../backend/app/api/v1/receivables.py), [schema](../backend/app/schemas/receivables.py), [serviço](../backend/app/services/receivables.py) | Autoridade financeira, idempotência, precondição, saldo, venda e livro-caixa. |

Textos usam l10n; moeda e datas usam os utilitários centrais. O material nativo
compartilhado ganhou luzes radiais e sombra suave, mantendo painel 32, campo 24,
grupos 20, azul padrão #2866ae e ênfase moderada. Pagar recebe o mesmo material
e máquina de apresentação, com testes de regressão. A equivalência exata de
métricas de fonte/material com HTML não é uma homologação nativa concluída.

## 6. Evidências, limites e próximo recorte

Consultar o [registro FE-054](validacoes_frontend/fe-054-receber-2026-10-17/README.md)
para resultados finais, hashes, build e capturas de widgets com dados de teste.
Essa evidência distingue testes de código, compilação Windows e instalação.
Não houve uso do banco da empresa, substituição da instalação ou migração nova.

A nova navegação das cinco áreas, Início com períodos, resultado em Negócio,
tema global/configuração da cor e integração/validação iOS continuam por integrar.
A lista de Pagar conserva sua composição/filtros; não atribuir a ela a nova
lista de Receber. Estorno e recebimento distribuído entre várias vendas não
foram convertidos para a nova jornada por consequência deste incremento.

Próximo recorte: integrar a organização das áreas principais e seus resumos
reais à referência acolhida, preservando navegação e leitura; depois validar os
alvos nativos e preparar atualização de servidor/cliente correspondentes.
Não reabrir as escolhas visuais já confirmadas ou apresentar a prévia completa
como se já fosse o aplicativo instalado.
