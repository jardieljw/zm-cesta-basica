# Tipos de cesta e controles do cadastro

Revisão: **14/10/2026**. [Índice](README.md).

## Para que serve e onde aparece

Em **Tipos de Cesta**, cadastrar e editar o produto comercial, como Cesta Básica ou Cesta de Carne. O cadastro identifica o que será vendido. A lista de produtos da cesta é definida na [receita](RECEITAS_E_COMPOSICAO.md), em outro fluxo.

## Interface, backend e banco

O formulário envia os dados pelo `BasketService`. A API usa `POST /basket-types` para cadastro e `PUT /basket-types/{id}` para edição. Os dados ficam em `basket_types`.

| Controle | Campo | Efeito atual |
| --- | --- | --- |
| Código | `code` | Identificação única. O código fica desabilitado na tela de edição. |
| Nome e descrição | `name`, `description` | Identificação e apresentação comercial. |
| Categoria | `category` | Classificação do tipo; não é a lista de produtos da receita. |
| Preço padrão | `default_price_cents` | Sugestão para preencher a venda; o preço efetivamente vendido é registrado em `sale_items`. |
| Permite personalização | `allows_customization` | Habilita Personalizar esta montagem em Registrar montagem. O motor revalida a permissão na prévia e na criação. Nova Venda ainda não oferece editor personalizado; desligar preserva os lotes já registrados. |
| Estoque de cestas prontas | `tracks_finished_stock` | Ligado: permite cesta pronta ou montagem na venda. Desligado: exige montagem na venda, sem produção antecipada ou ajuste manual de cestas. |
| Status ativo | `is_active` | Tipos inativos são rejeitados em novas vendas e montagens pelo backend. |

Salvar o cadastro não cria saldo, não monta cestas e não consome produtos. A ação de inativar usa `DELETE /basket-types/{id}`, mas apenas muda `is_active`. A lixeira usa `/basket-types/{id}/catalog`: apaga tipos/receitas nunca utilizados ou retira do catálogo preservando o histórico. Ver [Exclusão de tipos de cesta](EXCLUSAO_DE_TIPOS_DE_CESTA.md).

## Exemplo e limites

Cadastrar “Cesta Básica” com preço padrão de R$ 150,00 grava `15000` centavos como referência. A cesta ainda precisa de composição para ser montada na venda. Desligar “Estoque de cestas prontas” seleciona “Montar” automaticamente na venda; o backend rejeita venda de cesta pronta e produção antecipada para esse tipo. Se houver saldo pronto, a desativação é bloqueada até tratar esse saldo.

Os movimentos de montagem na venda continuam registrados para auditoria. Cancelar uma venda cujas cestas continuam montadas pode devolver cestas prontas, mesmo se a opção estiver desligada; nesse caso, ativar a opção para vendê-las como prontas. A configuração não apaga histórico nem estornos.

O controle “Pronta / Montar” da venda (anteriormente chamado “Estoque Acabado”) tem outro significado: seleciona a origem das cestas daquela linha. Ver [Vendas e montagem](VENDAS_E_MONTAGEM.md). Para fabricar cestas padrão ou personalizadas e consultar seus saldos/histórico, ver [Montagens](MONTAGENS_E_HISTORICO.md).

## Onde conferir

- [Lista](../client/lib/views/basket_types_view.dart), [formulário](../client/lib/views/basket_type_form_view.dart), [modelo](../client/lib/models/basket_type.dart) e [serviço](../client/lib/services/basket_service.dart).
- [API de cestas e receitas](../backend/app/api/v1/basket_types.py), [schemas](../backend/app/schemas/recipes.py) e [modelo BasketType](../backend/app/models/products.py).
- [Testes de receitas e tipos](../backend/tests/test_recipes.py).
