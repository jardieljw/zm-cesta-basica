# Evolução do módulo de cestas: escopo e proposta

Revisão: **14/10/2026**. [Índice](README.md).

## Situação desta entrega

**Implementado:** a configuração “Estoque de cestas prontas”, o registro de montagem
padrão/personalizada antecipada e o histórico por tipo integrado ao catálogo. Ver
[Montagens e histórico](MONTAGENS_E_HISTORICO.md). Personalização está disponível em Registrar montagem. Seleção do lote na venda,
gestão ampliada de receitas ainda estão pendentes. Ações e exclusão de tipos
estão implementadas; ver [Exclusão](EXCLUSAO_DE_TIPOS_DE_CESTA.md).

## Montagem antecipada e histórico no módulo existente

Cada cartão do tipo de cesta agora oferece acesso a **Montagens**. A página mostra
saldo pronto atual, receita ativa, ação **Registrar montagem** e histórico.
No computador usa largura limitada; no celular, cartões em uma coluna e formulário
rolável. A ação principal acompanha o padrão de FAB, com
espaço no final da rolagem. Não criar um módulo paralelo no menu inicial.

Registrar montagem pede quantidade, data e horário da fabricação, com agora como
padrão, e observações. Antes de confirmar, apresentar composição, produtos
necessários e faltas. Confirmar consome os produtos, registra o lote e adiciona as
cestas prontas. Reutilizar `/production/preview` e `/production/batches`.

Não usar ajuste manual de saldo para representar fabricação: ajuste não cria lote
nem registra consumo/custo de receita. Contagem física é uma operação diferente.

O histórico usa `/production/batches?basket_type_id=...`, com paginação. Mostra
data/hora local, quantidade, composição usada, custo, status e origem (montagem
antecipada ou na venda). A venda com “Montar” já grava lote com `is_direct_sale`
e `occurred_at`; não criar outro registro de fabricação a partir do histórico da
venda, pois isso duplicaria a produção.

Tipos configurados para montar somente na venda podem consultar seu histórico;
não oferecem registro antecipado de produção. Uma montagem desfeita continua
no histórico com seu status, sem representar saldo vendável atual.

## Receita padrão versus personalização

Editar a receita padrão deve ser independente de permitir personalização.
O tipo de cesta representa o produto comercial. Personalização pertence à
fabricação de uma quantidade desse produto, sem mudar seu cadastro nem a receita
padrão. Partir da receita do tipo selecionado e permitir trocar produtos,
acrescentar/remover itens e alterar quantidades. Exemplos do usuário: trocar sabão
em pó barato por outro de maior qualidade; substituir um sabão por dois sabonetes.
A composição efetiva deve ser preservada no lote e participar do consumo e custo.

O usuário inicialmente pediu personalização tanto em **Registrar montagem**
quanto na venda com **Montar**. Depois considerou concentrá-la apenas em Registrar
montagem para reduzir complexidade. Isso ainda é uma alternativa em discussão,
não uma decisão definitiva de remover personalização da venda.

Proposta técnica a avaliar: reutilizar o mesmo editor de composição nos dois pontos,
em vez de criar dois editores independentes. O backend já recebe composições
personalizadas. Na montagem antecipada, lotes personalizados devem continuar
separados das cestas padrão, e sua venda exige selecionar o lote correto. Se o
editor existir somente na montagem antecipada, a venda precisa desse acesso ao
lote personalizado; sem ele, a personalização não atenderia a rotina completa.

## Receitas e histórico de edição

Proposta recomendada: uma composição ativa por tipo, com histórico de edições.
As versões técnicas existentes podem ser apresentadas como **Histórico da receita**,
com data/hora e indicação de qual está ativa.

- **Editar receita:** abre a composição selecionada para alteração e grava nova
  edição; mantém o conteúdo anterior. A composição nova passa a ativa.
- **Nova receita:** inicia composição vazia para o mesmo tipo, dentro do histórico.
- **Usar esta composição:** copia uma edição anterior para uma edição nova ativa;
  preserva a cronologia e o original.
- **Excluir receita nunca utilizada:** ação explícita com confirmação e validação
  no backend. Bloquear se houver produção vinculada, inclusive desfeita ou originada
  em venda cancelada. Não confundir ausência de venda com ausência de fabricação.

Se o usuário preferir várias receitas independentes, cada uma com suas próprias
edições, será necessário definir entidades e migração próprias. Essa alternativa
não é equivalente a apresentar as versões atuais como histórico.

## Ações e exclusão do tipo — implementadas

Editar, inativar e excluir usam os mesmos ícones do catálogo. Tipos nunca usados
podem ser apagados junto com suas receitas nunca usadas. Para tipos com histórico,
o usuário confirmou retirar do catálogo preservando os registros. Vendas não
canceladas, saldo em qualquer lote/local e saídas abertas bloqueiam a exclusão.
Cancelar uma venda pode devolver estoque: não equivale a liberar exclusão.
Ver [Exclusão de tipos de cesta](EXCLUSAO_DE_TIPOS_DE_CESTA.md) para interface,
backend, migração, limitações e efeitos no banco.

Essa exclusão não elimina transações de teste nem libera apagar produtos usados.
O tratamento de ambiente/dados de teste é um fluxo diferente a discutir no chat
próprio de banco, sem remover proteções do histórico.

## Correção de erros e uso real da empresa

O usuário quer compreender como corrigir cadastros e operações incorretas antes
de começar a registrar os dados reais da empresa. Esse assunto será aprofundado
em outro chat, por preferência expressa do usuário. Manter registrada a necessidade,
sem tratar todo erro como irreversível ou prometer ausência de falhas.

Separar edição de cadastro, edição da composição, cancelamento/estorno comercial,
ajuste físico, arquivamento do catálogo e recuperação de backup. A existência de
histórico não bloqueia todas as edições de um produto; os campos e vínculos têm
regras específicas. O diagnóstico deve indicar qual correção resolve cada caso.

## Referências

Não apagar tabelas históricas nem reativar todas as telas arquivadas como atalho
para essas alterações. A página de montagem deve reutilizar o motor preservado.
Ver [funções arquivadas](FUNCOES_ARQUIVADAS.md), [receitas](RECEITAS_E_COMPOSICAO.md),
[vendas](VENDAS_E_MONTAGEM.md) e [cancelamento](CANCELAMENTO_DE_VENDAS_E_MONTAGEM.md).
