# Cancelamento, desmontagem e exclusão: pedido organizado

**Retomada — 20/10/2026:** escopo autorizado, implementado e validado; Release
1.0.5+6 ativado, com janela aberta e processo respondendo após a compilação final.
Backend: 590 testes; cliente: suíte final de 425 testes e regressões dirigidas
aprovadas, análise estática sem problemas. Revisão independente corrigiu três
achados de formulário e inspecionou capturas móvel/desktop. Backup e migração
f17→f28 em cópia preservaram as 56 tabelas anteriores; a ativação preservou todos
os registros encontrados na base atual, já em f28. Não foram canceladas vendas,
desmontadas cestas nem excluídos cadastros na base principal para testar.
Evidências: [validações](validacoes_catalogo/2026-10-20/ativacao.json).
Limites e mecânicas estão nos guias de receitas, produtos e montagens; reforma
visual global e avaliação nativa da E5 continuam em seus próprios registros.

## 1. Cancelar venda e localizar recebimentos

- Usar “Cancelar venda” no diálogo; reservar “estornar” para desfazer recebimentos.
- Mostrar valores em reais, por exemplo R$ 150,00, e identificar a venda pelo
  número e contexto disponível, como cliente/data. `#1` é o número da venda,
  não o nome do cliente nem o identificador de um pagamento.
- Quando houver recebimentos, explicar o bloqueio e oferecer acesso direto aos
  recebimentos daquela venda para consulta e estorno explícito. Após retornar,
  atualizar a situação; não estornar ou cancelar automaticamente.
- Base existente: `sales.py::cancel_sale`, `sales_view.dart`, `Sale.receivableId`
  e `ReceivablePaymentView`. Textos são pontuais; navegação exige integração e teste.

## 2. Desfazer montagem

- Oferecer a ação no histórico de Montagens, com composição, quantidade e efeito
  no estoque apresentados antes de confirmar. A necessidade é desfazer a operação,
  devolvendo os produtos, e não simplesmente apagar uma linha.
- Reutilizar e validar o motor `production.py::disassemble_production_batch`;
  ele já registra retornos/baixas, suporta quantidade parcial e diferencia perdas.
  A tela atual agora oferece revisão e confirmação dessa ação; o guia foi atualizado.
- Conferir saldo disponível, montagens padrão/personalizadas, composição original,
  operações ligadas a vendas e repetição de confirmação. Não restaurar o módulo
  antigo inteiro nem presumir que produtos danificados voltaram ao estoque.

## 3. Exclusão e vínculos compreensíveis

- Informar os registros reais: cesta e versão da receita, compra e situação,
  montagem, movimentação e venda/cliente quando relacionados. Oferecer acesso ao
  registro exato ou à lista já filtrada, sem pedir que a pessoa o procure sozinha.
- `catalog_dependencies.py` agora retorna os registros efetivos e seus destinos;
  `_usage_reasons` continua distinguindo histórico de cadastro nunca utilizado.
- Esclarecimento do usuário: não se trata apenas de receitas antigas. No caso
  relatado, o tipo “Cesta básica padrão” tem duas cestas prontas e nunca foi
  vendido. Deve ser possível desmontar as duas, devolver seus produtos e excluir
  o tipo de cesta, incluindo resolver a receita que ainda vincula o arroz.
- Regra vigente corrigida pelo usuário: existir venda NÃO CANCELADA usando a
  receita impede editar/excluir essa receita e excluir o tipo de cesta ou os
  ingredientes envolvidos. “Já foi utilizada alguma vez” não é o critério.
- Cancelar a venda permite excluir a receita que foi usada nela, desde que não
  reste outra venda não cancelada usando essa receita nem outro impedimento
  efetivo. Se ainda houver montagens prontas, desfazê-las e devolver os produtos
  antes de liberar as exclusões correspondentes.
- Se quiser manter o tipo de cesta, deve poder excluir uma receita elegível ou
  modificar a composição permitida. Depois de resolver montagens, receitas e
  demais vínculos efetivos, deve conseguir excluir o arroz. Não exigir excluir
  o tipo de cesta para poder mudar sua composição.
- O usuário quer criar receitas com composições diferentes e alternar a receita
  utilizada nas próximas operações. Cada venda deve continuar consultável com
  a composição efetivamente usada, sem alterações retroativas.
- Uma montagem ainda válida pode impedir excluir seus componentes. Uma venda
  válida pode impedir excluir o tipo de cesta e seus produtos; o usuário aceita
  esses bloqueios. Porém uma venda cancelada, com seus efeitos resolvidos, não
  deve por si só tornar esses cadastros impossíveis de excluir para sempre.
- Oferecer caminho explícito para resolver cada dependência. Não presumir
  autorização para cancelar vendas, desmontar ou excluir registros reais em lote.
- A implementação deve permitir remover os cadastros conforme esse fluxo sem
  perder os fatos das operações e de seus cancelamentos. A estrutura atual usa
  referências obrigatórias aos cadastros: a exclusão do catálogo preserva as
  referências antigas fora da seleção de uso. Cadastros nunca utilizados podem
  ser apagados. Isso foi resolvido na implementação, sem tarefa técnica ao usuário.
- Não substituir o pedido por mera inativação nem exigir apagar todo o histórico.
  Compras, saldos restantes e outras dependências reais precisam ser verificadas
  e explicadas individualmente; não foram esclarecidas todas as regras desses
  outros casos neste pedido.

## 4. Alterar composição e valor mantendo o tipo de cesta

Hoje a receita define produtos e quantidades; o preço de venda padrão pertence
ao tipo de cesta (`BasketType.default_price_cents`), e cada item vendido guarda
seu preço negociado (`SaleItem.unit_price_cents`). Os custos da composição são
registrados na montagem. Criar nova receita não altera os preços de vendas antigas.
Requisito esclarecido: atender ao cliente alterando a composição da cesta e seu
valor quando necessário, sem criar outro tipo de cesta para cada modificação.
Se a receita estiver protegida por venda não cancelada, permitir outra composição
no mesmo tipo, conservando a composição e o preço das vendas já registradas.
A implementação mantém versões no mesmo tipo de cesta, com preço sugerido
opcional e ativação explícita de uma receita existente. Criar uma versão usa o
contrato existente de criar e ativar; o botão informa essa consequência.
Editar uma versão elegível já ligada a montagens históricas cria uma substituta,
preservando a original para consulta. Personalização diretamente na venda não
foi acrescentada; essa capacidade anterior da API não é exigida para alternar
receitas no mesmo tipo pela interface entregue.
Não confundir preço de venda com custo dos ingredientes.

## Critérios exercitados

Executar os blocos nessa ordem, mantendo os dados existentes. Validar navegação
para o recebimento correto, atualização após estorno, retorno correto dos produtos
e baixa das cestas, falta de saldo, reenvio sem duplicar efeitos, exclusão após
desfazer integralmente as duas montagens sem venda, exclusão da receita nunca
utilizada mantendo o tipo de cesta, bloqueio de edição/exclusão por venda não
cancelada, liberação da receita após cancelar todas as vendas que a bloqueiam
e resolver os demais efeitos, alteração de composição e preço sem criar outro
tipo de cesta nem mudar vendas anteriores. Preservar o histórico de operações;
verificar separadamente compras, saldos e demais vínculos efetivos.
Mensagens/navegação foram exercitadas em larguras móveis e de computador,
com capturas sintéticas e tema/fontes reais. Reenvio, conflito e recuperação
conservam a identidade do pedido e os dados de formulário. Na edição, ingrediente
inativo permanece visível e exige decisão explícita. Vendas antigas de estoque
padrão sem atribuição de receita continuam com proteção conservadora identificada;
as novas conservam as candidatas existentes, sem atribuir receitas criadas depois.
Saldo restante e compra válida continuam como impedimentos reais individualizados.
Dispositivos físicos, leitor de tela e percurso manual nativo não foram certificados;
não são apresentados como validados por testes de widget. Não há correção conhecida
aguardando uma ação técnica do usuário. Esforço recomendado para manutenção
desse conjunto: Sol 6.1 no Alto, por envolver estoque, vínculos e persistência.
