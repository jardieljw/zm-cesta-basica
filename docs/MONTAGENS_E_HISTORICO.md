# Montagens padrão, personalizadas e histórico de fabricação

Revisão: **20/10/2026**. [Índice](README.md).

## Onde aparece e como usar

Em **Tipos de Cesta**, cada cartão oferece **Montagens**. A página mostra o saldo
atual de cestas padrão prontas e o histórico daquele tipo, com paginação.
**Registrar montagem** aparece para tipos ativos, com estoque de cestas prontas
habilitado e receita ativa. Tipos sem essa configuração continuam podendo
consultar montagens feitas durante a venda.

1. Abrir Montagens do tipo desejado e tocar em Registrar montagem.
2. Informar quantidade positiva, data/horário da fabricação e observações.
   Data e horário começam no momento atual e podem ser selecionados pelo operador.
3. Usar **Revisar montagem**: a consulta apresenta produtos necessários, saldos,
   faltas e custo estimado; ainda não movimenta o estoque.
4. Conferir a composição e usar **Confirmar montagem**. Se faltar produto, a
   confirmação fica bloqueada; alterar quantidade ou atualizar a revisão.
5. Após confirmação, o histórico e o saldo são consultados novamente.

A interface tem rolagem, limite de largura no computador e FAB com espaço ao fim
do conteúdo. A expansão do conteúdo de revisão usa animação curta de tamanho,
respeitando redução de movimento. O formulário oferece personalização para tipos que permitem essa opção.

## Desmontar e devolver os ingredientes

Expandir uma montagem confirmada oferece **Desmontar cestas**. Informar a
quantidade, motivo e confirmar que os produtos estão intactos. **Revisar
desmontagem** mostra as quantidades exatas que voltarão ao estoque, usando a
composição original. Depois **Desmontar cestas** grava retornos/baixa na mesma
transação e atualiza o histórico/saldo. Produtos danificados não devem ser
confirmados como intactos; a triagem de perdas existente no servidor não ganhou
um editor nesta tela. Não foi restaurado o módulo antigo de produção.

A revisão usa `POST /production/batches/{id}/disassembly-preview`: as mesmas
validações da confirmação são executadas em savepoint sempre desfeito. Nenhum
movimento de revisão permanece. A confirmação usa `/disassemble`, com corpo e
chave persistidos para retomada após resposta incerta, inclusive ao reabrir a tela.
Uma montagem já ligada a venda não cancelada não pode usar o saldo de outra
montagem para devolver seus ingredientes. No estoque padrão agregado, o servidor
limita a quantidade à composição comprovadamente disponível, descontando vendas
e saídas sem atribuição. Cestas de receita diferente não suprem essa conferência.
Os impedimentos identificam a venda e permitem consultá-la diretamente.

Desmontagem parcial conserva o restante; desmontagem total recebe `DISASSEMBLED`.
O registro original permanece no histórico. Depois de resolver vendas, montagens
e demais saldos, o tipo de cesta/receita pode ser excluído do catálogo sem apagar
os fatos anteriores. Retornar arroz ao estoque não o apaga nem registra perda.

## Personalizar somente esta montagem

Em Registrar montagem, **Personalizar esta montagem** aparece quando o cadastro
permite personalização. Ao ativar, o cliente consulta o tipo e os produtos ativos,
copia a receita ativa para um editor local e solicita uma identificação para
as cestas (até 500 caracteres). O tipo de cesta e sua receita não são editados.

É possível trocar produtos, adicionar um produto pesquisando seu nome, remover
itens e ajustar quantidades. A quantidade de cada produto é **por cesta**: todas
as cestas registradas nessa montagem terão a mesma composição. Quantidades são
inteiros positivos na unidade base exibida (G, ML ou UN). Trocar/adicionar produto
exige preencher a quantidade; não transferir números entre unidades diferentes.
Não se pode confirmar composição vazia ou sem identificação. A lista oferece
produtos ativos e evita incluir o mesmo produto mais de uma vez pelo editor.

Revisar montagem continua consultando estoque e custos no servidor. Alterar um
campo elimina a revisão e exige outra antes da confirmação. Desativar a
personalização retorna ao fluxo padrão, sem mudar a receita. A prévia não
movimenta estoque. O servidor valida novamente a permissão de personalização
na criação; desligá-la depois da prévia rejeita a montagem com
`CUSTOMIZATION_DISABLED`. Montagens históricas continuam preservadas.

O pedido personalizado envia `is_custom=true`, `custom_description` e
`custom_items` com produtos, unidades base e seções. Não envia versão esperada
da receita: a composição é explícita e independente de edições posteriores da
receita. O motor existente congela produtos/custos em `production_batch_items`,
cria o lote em `production_batches` e registra consumo/entrada de cestas no
razão na mesma transação. Não há migração ou saldo paralelo.

Cestas personalizadas têm saldo separado por `production_batch_id`, não entram
no saldo padrão do tipo. O histórico exibe identificação e **Prontas desta
montagem**, obtidas de `current_batch_stock`; não calcula saldo a partir da
quantidade fabricada. A identificação diferencia as composições registradas.
A retomada de resposta incerta conserva composição, identificação, data, payload
e chave original; os campos ficam bloqueados até a resolução.

**Limite desta etapa:** a página de nova venda ainda não oferece seleção de lote
personalizado. Esse acesso é a próxima etapa para vender essas cestas pela
interface; não tratá-las como padrão nem somar os saldos indiscriminadamente.
Personalização diretamente na venda também não foi incluída nesta etapa.

## Backend e banco

Não existe saldo paralelo. A tela reutiliza os endpoints existentes:

| Endpoint (`/api/v1`) | Efeito |
| --- | --- |
| `POST /production/preview` | Consulta receita ativa, necessidade de produtos e custos; não grava montagem. |
| `POST /production/batches` | Cria lote, copia consumo/custo e registra movimentos de produtos e cestas na mesma transação. |
| `GET /production/batches?basket_type_id=...` | Lê histórico filtrado pelo tipo e paginado. |
| `GET /inventory/baskets/{id}/stock` | Calcula saldo padrão atual pelo livro de movimentos. |

Na confirmação, `production_batches` recebe quantidade, receita usada, data UTC,
status e custos. `production_batch_items` guarda produtos, quantidades consumidas
e custos da composição efetiva. `inventory_movements` recebe `ASSEMBLY_CONSUME`
negativo para os produtos e `ASSEMBLY_PRODUCE` positivo para as cestas.

Montagem antecipada não é venda e não cria recebimento financeiro. O estoque
de produtos é revalidado na confirmação, mesmo depois de uma revisão suficiente.

## Receita, datas e proteção contra duplicidade

O formulário envia `expected_recipe_version_number`, um campo opcional novo do
pedido, sem coluna nova no banco. Se a receita ativa mudar após a revisão, a API
rejeita com `RECIPE_CHANGED` para exigir outra conferência. Chamadas antigas que
omitem esse campo mantêm o contrato e a identidade de reenvio anteriores.

A data local selecionada é enviada em UTC. O serviço normaliza datas de pedidos
novos para UTC e a resposta de histórico identifica UTC explicitamente para a
conversão local do cliente. Isso não reescreve datas históricas armazenadas.

Registrar fabricação passada usa receita, custo e estoque vigentes no momento
do registro; não reconstrói automaticamente receita, custo médio ou saldo daquela
data passada. A composição revisada é a que precisa representar a fabricação.

Antes de enviar a confirmação, o cliente conserva payload e chave de idempotência
localmente, separados por servidor e tipo de cesta. Em resposta incerta, mantém
o pedido e oferece **Retomar confirmação**, inclusive ao fechar/reabrir a página.
Os campos ficam bloqueados nessa retomada. Não criar outro pedido para repetir a
mesma fabricação. Rejeições definitivas de validação/estoque/receita liberam nova
revisão. O servidor continua responsável por impedir dupla gravação.

## Histórico e exemplo

Cada registro mostra quantidade fabricada, data/hora, origem, status e detalhes
de produtos/custo. **Montagem antecipada** identifica um lote normal; **Montada na
venda** identifica `is_direct_sale=true`. A fabricação durante a venda já existe
no backend e aparece nesta consulta; a interface não a grava uma segunda vez.

Montagem desfeita permanece identificada no histórico. Quantidade fabricada não
significa saldo atual daquele lote. Para cestas padrão, o saldo é agregado por
tipo; a página não atribui arbitrariamente esse saldo a cada lote. Lotes
personalizados são identificados, mostram o saldo por montagem e podem ser
consultados; sua composição já registrada não é editada.

Exemplo: fabricar cinco cestas com 5.000 G de arroz em cada uma consome 25.000 G e
adiciona cinco cestas prontas. Depois vender duas pelo modo Pronta deixa três e
não consome arroz novamente. Montar duas durante outra venda gera um lote de duas
e saída de duas, sem alterar o saldo de três cestas previamente prontas.

## Onde conferir

- [Acesso no catálogo](../client/lib/views/basket_types_view.dart),
  [histórico](../client/lib/views/basket_assemblies_view.dart),
  [formulário](../client/lib/views/basket_assembly_form_view.dart) e
  [serviço](../client/lib/services/basket_assembly_service.dart).
- [API](../backend/app/api/v1/production.py),
  [contrato](../backend/app/schemas/production.py),
  [motor](../backend/app/services/production.py),
  [modelos](../backend/app/models/production.py).
- [Testes da interface e retomada](../client/test/basket_assemblies_test.dart),
  [testes de histórico/compatibilidade](../backend/tests/test_sales.py) e
  [testes do motor](../backend/tests/test_production.py).

Testes de personalização: `client/test/assembly_customization_test.dart` e
`backend/tests/test_assembly_customization_policy.py` cobrem troca, inclusão,
remoção, revisão obrigatória, retomada, permissão e preservação dos dados.
