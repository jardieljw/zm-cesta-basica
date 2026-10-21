# Produtos e formas de compra

Revisão: **20/10/2026**. [Índice das mecânicas](README.md).

## Cadastro na interface e no servidor

Em **Produtos**, cadastrar ou editar nome, identificação, categoria, unidade-base,
estoque mínimo, custos, preço de referência e status. No gerenciador de formas de
compra, definir o conteúdo de cada pacote, saco, fardo ou caixa. Salvar esses
cadastros não registra uma entrada de estoque; a entrada ocorre na compra ou no
ajuste correspondente.

`ProductService` usa a API de produtos: `POST /api/v1/products`,
`PUT /api/v1/products/{id}` e as rotas de embalagens. `products` conserva os dados
do produto, inclusive unidade e custos; `product_packagings` conserva nome,
conteúdo na unidade-base, indicação de padrão e status de cada forma de compra.
A regra de conversão fica centralizada no servidor quando a compra é registrada.

SKU e código de barras são validados quanto a duplicidade. A alteração de
unidade-base é bloqueada quando há embalagens ou receitas vinculadas. Isso não
é uma conversão dos movimentos anteriores; não mudar a unidade para tentar
corrigir histórico.

Editar preços de referência não recalcula o custo congelado das vendas anteriores.
Os campos de custo são dados comerciais, diferentes do saldo de estoque,
calculado em `inventory_movements`. Compras confirmadas atualizam os custos
conforme o [guia de compras](COMPRAS.md).

## Excluir ou inativar

O catálogo oferece duas ações diferentes:

- **Inativar:** mantém o cadastro e seu histórico, retirando o produto de novas
  compras e composições. Se ele estiver em uma receita ativa, retirar dessa
  composição antes de inativar.
- **Excluir produto:** verifica os vínculos atuais e pede confirmação. Cadastro
  nunca utilizado e suas embalagens são apagados. Com operações anteriores já
  resolvidas, o produto sai do catálogo, inclusive da lista de inativos, e fica
  disponível somente por seus registros históricos. Isso é diferente de inativar.

Receitas ainda disponíveis, compras não canceladas (inclusive rascunhos), vendas
não canceladas, montagens não desfeitas e saldo de estoque restante impedem a
exclusão. O diálogo identifica as receitas/versões, compras, vendas/clientes,
montagens e saldos efetivos, com acesso aos registros correspondentes.
Montagem desfeita, venda cancelada, compra cancelada e movimentos com saldo
resolvido não tornam o bloqueio permanente. Para liberar o arroz de uma receita,
editar/excluir a receita elegível ou excluir o tipo de cesta elegível; uma receita
protegida por venda não cancelada exige resolver essa venda antes.

Excluir não descarta estoque silenciosamente. Produtos devolvidos pela
desmontagem continuam no saldo: se ainda houver quantidade ou compra válida,
o aplicativo informa esse impedimento separado. Não registrar perdas ou ajustes
fictícios apenas para liberar uma exclusão.

A API verifica esses vínculos novamente no momento da exclusão, na mesma
transação. A consulta prévia na interface não permite apagar um produto que
passou a ser usado depois da consulta. A rota de inativação existente continua
compatível; a exclusão explícita usa `DELETE /api/v1/products/{id}/permanent`.
O nome histórico dessa rota permanece compatível; a resposta informa
`deletion_mode=PERMANENT` ou `CATALOG_ONLY`. Neste último caso, `removed_at` e a
inativação retiram o cadastro do uso, sem romper referências de receitas,
compras e montagens preservadas. Edição/reativação do cadastro excluído é bloqueada.

## O que é embalagem comercial

É a forma de compra do produto: pacote, saco, caixa, fardo ou unidade. O conteúdo
de uma embalagem é convertido para a unidade-base do estoque. Não é uma sacola
vazia para montar a cesta.

Há duas maneiras comuns de cadastrar arroz:

| Controle do produto | Forma de compra | Quantidade comprada | Preço informado | Resultado |
| --- | --- | --- | --- | --- |
| Produto “Pacote de arroz de 5 kg”, estoque em UNIT | Sem embalagem: comprar em UNIT | 3 | R$ 25 por unidade | 3 pacotes, compra de R$ 75 |
| Produto “Arroz”, estoque em G | Saco de 5 kg, conteúdo 5000 G | 3 | R$ 25 por saco | 15000 G (15 kg), compra de R$ 75 |
| Produto contado em UNIT | Caixa com 12 unidades, conteúdo 12 UNIT | 2 | Preço de uma caixa | Entrada de 24 unidades |

Escolher o controle que corresponde às quantidades utilizadas nas receitas.
Produtos existentes com histórico não devem ter sua unidade alterada para tentar
converter registros anteriores.

## Preencher a compra

1. Selecionar o produto.
2. Selecionar a **forma de compra**.
3. Informar quantas embalagens foram compradas, quando houver uma selecionada.
4. Informar o preço de **uma embalagem**, não o valor total da linha.
5. Conferir a quantidade que entrará no estoque e o valor total apresentados.

Sem embalagem cadastrada, quantidade e preço se referem à unidade-base exibida.
Se o estoque usa gramas, mas a nota informa preço por kg, cadastrar uma forma de
compra “1 kg”, com conteúdo 1000 G, para poder informar o preço por kg. Para litro,
usar uma forma de compra com conteúdo 1000 ML.

A interface usa somente embalagens ativas em novas compras. Embalagens inativas
continuam aparecendo no gerenciador para preservar os registros anteriores.

## Verificação desta alteração

201 testes do backend e 105 testes Flutter aprovados; análise estática sem problemas.
Os novos testes cobrem confirmação de exclusão, bloqueios por histórico,
reenvio idempotente, preservação da inativação e o exemplo de 3 sacos de 5 kg
a R$ 25. A compilação Windows Release foi atualizada.

## Onde conferir a implementação

- [Lista](../client/lib/views/products_view.dart), [formulário](../client/lib/views/product_form_view.dart), [formas de compra](../client/lib/views/packagings_dialog.dart) e [serviço](../client/lib/services/product_service.dart).
- [API](../backend/app/api/v1/products.py), [proteção da exclusão](../backend/app/services/product_catalog.py) e [modelos](../backend/app/models/products.py).
- [Testes de produtos](../backend/tests/test_products.py), [embalagens](../backend/tests/test_packagings.py) e [exclusão permanente](../backend/tests/test_product_permanent_deletion.py).

Os números de testes da seção anterior registram a validação daquela alteração;
não são a contagem atual de testes do projeto.
