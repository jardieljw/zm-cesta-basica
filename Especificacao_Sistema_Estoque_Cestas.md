# Especificação do projeto — Sistema de Estoque, Montagem e Vendas de Cestas

> **Atualização implementada em 14/10/2026:** registro de montagem padrão/personalizada e
> histórico por tipo estão acessíveis em Tipos de Cesta → Montagens. Essa
> integração nova não restaura todas as telas originais descritas abaixo. Ver
> [Montagens e histórico](docs/MONTAGENS_E_HISTORICO.md).

> **Documento de planejamento histórico — escopo esclarecido em 14/10/2026.**
> Esta especificação conserva o projeto original; não é a lista atual de menus.
> As telas de produção em lote, desmontagem separada, responsáveis, expedição,
> conferência/acerto de rota e tesouraria foram arquivadas em 13/10/2026, assim
> como seus relatórios exclusivos e o formulário C. Backend, tabelas e dados
> foram preservados. Montagem durante a venda segue ativa; dashboard e financeiro
> usam o escopo simplificado. Consultar [mecânicas atuais](docs/README.md),
> [funções arquivadas](docs/FUNCOES_ARQUIVADAS.md) e
> [arquivo do cliente](client/_archive/README.md). As instruções históricas
> deste documento não autorizam restaurar funções arquivadas.

**Versão:** 1.0 — planejamento inicial  
**Idioma da interface:** português brasileiro (pt-BR)  
**Plataformas:** Android e Windows  
**Operação pretendida:** sem servidor na nuvem; dados sob controle da empresa  
**Objetivo deste documento:** orientar uma IA de desenvolvimento para construir um sistema modular, confiável, testável e extensível.

---

## 1. Visão do produto

Construir um sistema de gestão para uma empresa que vende cestas de produtos. O sistema deve registrar compras, manter o estoque de cada item, controlar a montagem de cestas padronizadas, registrar vendas com preços negociados, controlar cestas personalizadas, exibir alertas de reposição e gerar relatórios/exportações.

Tipos comerciais iniciais:

1. **Cesta Básica Completa:** um produto comercial, formado por itens de alimentação e itens de limpeza. Os itens podem ser acondicionados em dois pacotes físicos separados, mas a composição comercial é considerada uma cesta completa.
2. **Cesta de Carne:** composição padronizada independente.
3. **Cesta Personalizada:** montagem excepcional cuja lista de itens e quantidades é alterada conforme o pedido do cliente.

A aplicação deve funcionar em telas de celular e computador, priorizando a experiência mobile sem desperdiçar o espaço da tela desktop. Deve permitir adicionar funcionalidades sem misturar as regras de negócio à interface ou reescrever módulos que já funcionam.

### Objetivos operacionais

- Saber o saldo atual de cada produto armazenado.
- Saber quais produtos estão abaixo do estoque mínimo.
- Registrar compras e repor o estoque.
- Cadastrar a composição padrão de cada tipo de cesta.
- Registrar quantas cestas foram montadas por dia.
- Registrar quantas cestas saíram/venderam por dia.
- Descontar os ingredientes corretos ao montar as cestas.
- Descontar as cestas prontas ao vender, sem descontar novamente os ingredientes.
- Registrar modificações em cestas personalizadas sem alterar a receita padrão.
- Guardar o preço real de cada venda, mesmo que seja diferente do preço habitual.
- Consultar histórico por dia e por período e exportar relatórios para planilhas.
- Proteger o histórico de alterações acidentais e manter backups recuperáveis.

### Fora do objetivo inicial

Não incluir, na primeira versão, emissão fiscal, integração com sistemas contábeis, pagamento por cartão, integração com fornecedores, loja virtual, acesso pela internet pública ou previsão complexa com inteligência artificial. Preparar a arquitetura para futuras extensões, mas não implementar essas funcionalidades antes de o fluxo central estar confiável.

---

## 2. Decisões técnicas recomendadas

### Aplicação cliente

- **Flutter + Dart** para Android e Windows.
- Uma base de código compartilhada, com interface adaptativa por tamanho de tela.
- Navegação e componentes reutilizáveis, sem colocar fórmulas de estoque dentro dos widgets.

### API local

- **Python + FastAPI** como serviço HTTP local.
- **Pydantic** para validar os dados recebidos e as respostas da API.
- **SQLAlchemy** para acesso ao banco de dados.
- **Alembic** para versionamento e migração do esquema do banco.
- Testes automatizados com `pytest`.

A API deve ser o único componente autorizado a executar operações de negócio e gravar no banco. Tanto o aplicativo Windows quanto o Android usam a mesma API. Isso centraliza as regras e evita que cada interface calcule o estoque de forma diferente.

### Banco de dados

- **SQLite** é o banco principal na primeira versão multi-dispositivo.
- **SQLAlchemy** é a camada de acesso ao SQLite no backend; **Alembic** versiona o esquema. Somente o serviço local abre e grava diretamente no arquivo SQLite.
- A aplicação Flutter não deve abrir o banco do servidor diretamente nem acessar o mesmo arquivo SQLite por pasta de rede.
- **Drift não é necessário no cliente da primeira versão compartilhada**, porque as leituras e escritas passam pela API central. Ele seria uma opção adequada se futuramente for adotado um modo autônomo 100% local ou um cache local/offline no Flutter.
- Preferir migrações versionadas, transações atômicas, chaves estrangeiras e restrições do banco.
- **JSON não será o banco de dados principal.** Será formato auxiliar de exportação/importação. O histórico transacional e as relações entre compras, produtos, montagens e vendas devem permanecer em um banco relacional.

### Por que separar cliente, API e banco

Essa arquitetura permite modificar a interface sem alterar as regras de estoque, trocar o armazenamento futuramente com impacto limitado e oferecer a mesma lógica para diferentes dispositivos. Também torna possível testar as operações sem abrir a interface visual.

---

## 3. Como os dispositivos compartilharão os dados

### Arquitetura recomendada para a primeira versão multi-dispositivo

O computador Windows será o **servidor local principal**. Nele ficará o serviço FastAPI e o banco SQLite. Os aplicativos Windows e Android enviarão operações à API local.

- No Windows, o aplicativo acessa a API por `http://127.0.0.1:<porta>`.
- No Android, o aplicativo acessa o endereço IP local do computador, por exemplo `http://192.168.1.20:<porta>`; o endereço real deve ser configurável, nunca fixado no código.
- Os dois dispositivos precisam estar na mesma rede Wi-Fi/rede local e o computador precisa estar ligado com o serviço ativo.
- Não é preciso que a rede tenha conexão com a internet; é preciso que os dispositivos consigam comunicar-se pela rede local.
- O aplicativo deve ter uma tela de configuração da conexão, teste de conexão, indicação clara de conectado/desconectado e instruções de diagnóstico.
- O instalador/assistente futuro deve permitir iniciar o serviço automaticamente com o Windows. Na primeira implementação, documentar claramente como iniciar e parar o serviço.
- O firewall deve permitir acesso somente pela rede privada local. Não configurar encaminhamento de portas no roteador e não expor a API à internet.
- A API deve exigir autenticação local, mesmo numa rede privada. Implementar um token de dispositivo ou mecanismo de pareamento, guardar credenciais com segurança e evitar registrar segredos em logs.

### Limitação que deve ser explícita na interface

Se o computador-servidor estiver desligado ou o telefone estiver em outra rede, o Android não consegue consultar o estoque central atualizado. Na primeira versão, as operações que alteram estoque devem falhar com mensagem clara quando a API estiver indisponível; não podem ser registradas silenciosamente em uma base isolada do telefone.

O modo de edição offline com sincronização posterior pode ser adicionado numa fase futura, mas exige fila de operações, identificação de conflitos, prevenção de duplicação e regras de reconciliação. Não simular sincronização apenas copiando arquivos ou mantendo duas bases independentes.

### Alternativa mais simples, caso a empresa decida usar apenas um dispositivo

Se o uso ficar restrito ao computador, uma versão local com Flutter + SQLite/Drift pode ser suficiente e menos complexa. Porém, isso não fornece automaticamente um estoque compartilhado com o Android. A decisão de usar uma API local deve ser tomada antes de começar a implementação.

---

## 4. Fluxo correto de estoque: regra mais importante

O sistema deve distinguir **insumos/produtos individuais** de **cestas prontas**.

### Exemplo do fluxo

1. A empresa compra 100 pacotes de arroz e registra a compra. O estoque do arroz aumenta.
2. A empresa monta 10 Cestas Básicas Completas. O sistema desconta a quantidade de cada ingrediente definida pela receita e aumenta o estoque de cestas prontas em 10.
3. A empresa vende 6 Cestas Básicas Completas. O estoque de cestas prontas diminui em 6. O arroz e os demais ingredientes **não** são descontados de novo.
4. O estoque final de cestas prontas passa a ser 4, e o saldo de ingredientes reflete a montagem das 10 cestas.

A interface deve registrar montagem e venda como eventos separados, ainda que ocorram no mesmo dia.

### Validação antes de confirmar

Ao confirmar uma montagem, calcular o consumo total e conferir se cada ingrediente possui saldo suficiente. Se faltar algo, bloquear a confirmação por padrão e mostrar uma lista como: produto, saldo atual, quantidade necessária e diferença faltante. Não deixar o estoque ficar negativo silenciosamente.

Se no futuro for necessário permitir saldo negativo, isso será uma opção administrativa explícita, com justificativa e registro no histórico; deverá vir desativada por padrão.

### Integridade transacional

A confirmação de montagem deve acontecer em uma transação indivisível:

- validar a receita e o estoque;
- criar o registro de montagem;
- gravar os itens efetivamente consumidos;
- criar movimentos de saída dos ingredientes;
- adicionar o saldo de cestas prontas, quando aplicável;
- confirmar tudo em conjunto.

Se qualquer etapa falhar, nenhuma parte da operação poderá permanecer gravada.

A mesma exigência vale para compras, vendas, cancelamentos e ajustes de inventário. Usar proteção contra envio repetido para impedir que um toque duplo, repetição de requisição ou falha de rede registre a mesma operação duas vezes.

---

## 5. Módulos funcionais

### 5.1 Painel inicial

Exibir de forma clara:

- saldo de cestas prontas por tipo;
- montagens de hoje por tipo;
- vendas/saídas de hoje por tipo;
- valor total vendido hoje;
- produtos abaixo do estoque mínimo;
- produtos que impedem a montagem de mais cestas;
- movimentações recentes;
- estado da conexão com o servidor local.

As métricas devem vir de dados persistidos e consultas verificáveis, nunca de números fixos ou demonstrações fictícias na versão de produção.

### 5.2 Cadastro de produtos

Cada produto deve permitir:

- nome e identificador interno/SKU opcional;
- categoria: alimentação, limpeza, carne ou outra;
- unidade-base de estoque;
- formas de compra e fatores de conversão;
- estoque mínimo;
- ativo/inativo;
- observações opcionais;
- custo de compra registrado por compra.

Produtos já usados em receitas ou movimentos históricos não devem ser apagados definitivamente. Usar desativação lógica para preservar o histórico.

### 5.3 Unidades e conversões

O estoque deve ser mantido numa **unidade-base canônica** por produto. Exemplos:

- produto contado individualmente: `unidade`;
- arroz comprado em saco de 5 kg: unidade-base `grama`, pacote de compra `5 kg = 5000 g`;
- líquido: unidade-base `ml`, quando adequado.

O usuário deve conseguir cadastrar a embalagem comprada, a quantidade por embalagem e a unidade. Ao registrar uma compra, o sistema converte a quantidade para a unidade-base.

Não misturar, por exemplo, saldo em quilos com consumo em gramas sem conversão explícita. Não arredondar quantidades silenciosamente. Para itens contáveis, impedir frações inválidas; para itens medidos por peso/volume, permitir a precisão definida pelo produto.

### 5.4 Receitas/composição das cestas

Cada tipo de cesta deve ter uma receita com itens e quantidade por cesta.

A receita da Cesta Básica Completa deve permitir separar visualmente os itens em seções:

- alimentação;
- limpeza.

Essas seções indicam os pacotes físicos, mas continuam compondo um único produto comercial para montagem e venda.

A receita da Cesta de Carne é independente.

Cada item de uma receita deve conter produto, quantidade por cesta, unidade-base e seção. Validar duplicidades ou consolidar automaticamente o mesmo produto repetido na mesma receita.

#### Versionamento de receitas

Nunca sobrescrever retroativamente a composição utilizada em montagens antigas. Ao editar uma receita já usada, criar uma nova versão. Cada montagem deve guardar a versão da receita e uma cópia dos itens/quantidades efetivamente consumidos.

Isso garante que o histórico continue correto se a composição mudar no futuro.

### 5.5 Compras e reposição

Registrar:

- data da compra/recebimento;
- fornecedor opcional;
- produtos;
- quantidade de embalagens compradas;
- tipo de embalagem e conversão;
- preço unitário e total;
- observação opcional.

Ao confirmar uma compra recebida, aumentar o estoque dos produtos por movimentos rastreáveis. Uma compra em rascunho ainda não altera o estoque. Se uma compra confirmada precisar ser corrigida, realizar estorno/cancelamento com movimentos inversos e histórico, não apagar silenciosamente os movimentos.

Permitir consultar histórico de compras por período e por produto. O custo histórico deve ficar vinculado à compra original.

### 5.6 Montagem/produção de cestas

> **Tela separada arquivada:** o fluxo descrito abaixo é referência original.
> O motor de montagem continua atendendo a montagem durante a venda.

Registrar:

- data e hora;
- tipo de cesta;
- quantidade montada;
- versão da receita;
- itens consumidos e quantidades calculadas;
- observação opcional;
- estado: rascunho, confirmada ou cancelada/estornada.

A montagem confirmada diminui os ingredientes e aumenta o estoque de cestas prontas. O painel deve permitir ver total montado hoje, por tipo de cesta, sem confundir com as vendas.

Se for útil na operação, oferecer modo de montagem rápida: escolher tipo e quantidade, revisar os itens a consumir e confirmar. Não esconder uma falta de estoque atrás de uma confirmação genérica.

### 5.7 Cestas personalizadas

> **Escopo atual:** Registrar montagem oferece personalização, preservando a receita.
> A Nova Venda ainda não possui editor de composição nem seletor de lote personalizado.
> Não interpretar a descrição original abaixo como função já disponível na venda.

A personalização é uma exceção ao padrão, não uma edição da receita principal.

Para uma montagem personalizada, o usuário deve:

1. escolher uma cesta de referência ou começar uma composição vazia;
2. adicionar, remover ou alterar a quantidade de produtos;
3. visualizar a lista final de consumo;
4. informar a quantidade de cestas personalizadas;
5. revisar o impacto no estoque;
6. confirmar.

Guardar um **snapshot** da composição personalizada e das quantidades efetivamente utilizadas. Nunca alterar a receita padrão em consequência de uma personalização.

Como a personalização é rara, a primeira versão pode tratar essas cestas como montagens sob encomenda, registrando no mesmo fluxo sua montagem e a venda, quando ocorrerem juntas. Caso uma cesta personalizada fique pronta sem ser vendida, seu tratamento no estoque de produtos acabados deverá ser explícito; não deve ser misturada ao saldo da cesta padrão se sua composição for diferente. Deixar esse caso documentado e testado na implementação.

### 5.8 Vendas/saídas

Registrar cada venda com:

- data e hora;
- um ou mais itens vendidos;
- tipo de cesta;
- quantidade;
- preço unitário **realmente praticado**;
- desconto opcional;
- total calculado automaticamente;
- cliente opcional;
- método/condição de pagamento opcional;
- observações opcionais.

O preço de cada venda não deve ficar preso ao preço padrão do produto. O usuário pode vender por preço diferente, com ou sem desconto, e o sistema guarda exatamente o valor informado e o total final.

Ao confirmar a venda, diminuir o estoque de cestas prontas. Se não houver saldo suficiente, bloquear a venda por padrão e explicar a falta. Não diminuir os ingredientes de novo.

Permitir cancelar uma venda com estorno rastreável. O cancelamento deve reverter corretamente o saldo de cestas acabadas e manter o registro original no histórico. Se houver devolução ou a cesta não puder voltar ao estoque vendável, tratar como uma operação específica, não como simples cancelamento sem contexto.

### 5.9 Inventário e ajustes

Oferecer uma tela para conferir a quantidade física de um produto e compará-la com o saldo do sistema. Se houver divergência, registrar um ajuste com:

- saldo do sistema;
- quantidade física contada;
- diferença;
- motivo obrigatório;
- data/hora.

Ajustes não devem apagar nem reescrever o histórico de movimentos. O saldo deve mudar por um novo movimento de entrada/saída.

Prever tipos de movimentação para compra, consumo de montagem, venda de cesta pronta, estorno, devolução, perda/descarte e ajuste manual. Perdas de ingredientes precisam ser distinguíveis de consumo normal em cestas.

### 5.10 Alertas de estoque

- Alerta visual para produto abaixo do mínimo cadastrado.
- Saldo atual, mínimo e quantidade que falta para voltar ao mínimo.
- Estimativa de quantas cestas padrão ainda podem ser montadas com o estoque atual.
- Explicação de qual ingrediente limita a montagem de cada tipo de cesta.

Para cada ingrediente de uma receita, calcular `cestas possíveis = piso(saldo disponível / quantidade desse ingrediente por cesta)`. O máximo de cestas possíveis é o **menor** desses resultados entre todos os ingredientes necessários. Se um ingrediente não for necessário, não participa do cálculo. Respeitar unidade-base e quantidades inteiras quando o produto exigir.

A primeira versão não precisa prever demanda futura. Essa estimativa pode ser adicionada depois usando histórico de vendas e prazo de reposição de fornecedores.

### 5.11 Relatórios e planilhas

> **Escopo simplificado:** consultar [os seis relatórios e formulários ativos](docs/RELATORIOS_E_IMPRESSAO.md).
> Relatórios exclusivos dos fluxos arquivados não aparecem na interface atual.

Relatórios mínimos:

- vendas por dia e por período, incluindo quantidade, receita e preço médio praticado;
- montagens por dia e por tipo de cesta;
- comparação entre montadas, vendidas e saldo de cestas prontas;
- estoque atual de todos os produtos;
- produtos abaixo do estoque mínimo;
- consumo de cada ingrediente no período;
- compras e custos registrados por período;
- histórico de movimentações de um produto;
- vendas de cestas personalizadas.

Permitir filtrar por datas inicial/final e tipo de cesta.

Exportar para **CSV e/ou XLSX** com cabeçalhos claros, datas no padrão brasileiro, valores em reais e quantidades nas unidades apropriadas. A exportação deve conter os dados filtrados e os totais correspondentes ao relatório visual. Exportar não deve alterar o banco de dados.

A aplicação pode gerar um resumo diário de vendas e montagens. Não chamar receita de “lucro”: lucro/margem só pode ser apresentado se existir um cálculo de custo suficientemente definido e testado.

### 5.12 Clientes e recebimentos — preparar, não ampliar o MVP sem necessidade

Deixar uma extensão prevista para cadastrar clientes e condições de recebimento, inclusive venda pendente ou parcial, se isso fizer parte do processo real da empresa. No MVP, cliente, condição e método de pagamento podem ser campos opcionais de registro; não implementar um módulo financeiro complexo sem validar os requisitos reais.

### 5.13 Configurações e manutenção

- Nome da empresa e preferências de exibição.
- Configuração e teste da conexão com a API local.
- Exportação e restauração de backup.
- Configuração de estoque mínimo padrão, se desejado.
- Consulta à versão do aplicativo e versão do esquema do banco.
- Diagnóstico básico sem exibir segredos.

---

## 6. Modelo de dados inicial

O esquema exato será decidido pelo desenvolvedor, mas deve contemplar no mínimo as seguintes entidades relacionais. Utilizar IDs estáveis (UUID ou inteiros imutáveis) e chaves estrangeiras.

### `products`

- `id`
- `name`
- `sku` opcional
- `category`
- `base_unit` (`unit`, `g`, `ml` ou unidade suportada)
- `minimum_stock`
- `is_active`
- `notes`
- `created_at`, `updated_at`

### `product_packagings`

Representa como um produto é comprado/embalado.

- `id`
- `product_id`
- `name` (ex.: saco de 5 kg, pacote com 12 unidades)
- `quantity_in_base_units`
- `is_default`
- `is_active`

### `basket_types`

- `id`
- `name`
- `description`
- `is_active`
- `tracks_finished_stock`

### `recipe_versions`

- `id`
- `basket_type_id`
- `version_number`
- `status`
- `created_at`
- `notes`

### `recipe_items`

- `id`
- `recipe_version_id`
- `product_id`
- `quantity_in_base_units`
- `section` (alimentação, limpeza, carne ou outra)
- `is_required`
- `notes`

### `purchases` e `purchase_items`

A compra contém data, fornecedor opcional, estado e totais. Cada item guarda produto, embalagem selecionada, número de embalagens, quantidade convertida para unidade-base, preço unitário/total e movimentos associados.

### `production_batches` e `production_batch_items`

A montagem contém data, tipo de cesta, quantidade produzida, origem (receita padrão ou personalizada), estado, versão da receita e observações. Os itens guardam o consumo efetivo em unidade-base e uma cópia dos detalhes relevantes para auditoria.

### `sales` e `sale_items`

A venda contém data, estado, cliente opcional, totais e condição de pagamento opcional. Cada linha guarda tipo de cesta, quantidade, preço unitário efetivo, desconto e total da linha. O preço histórico não deve mudar quando o cadastro da cesta mudar.

### `inventory_movements`

Este é o **livro-razão do estoque**. Cada mudança no saldo gera um movimento rastreável.

Campos recomendados:

- `id`
- `product_id` ou referência ao item acabado, conforme o modelo escolhido
- `quantity_delta` em unidade-base, positivo para entrada e negativo para saída
- `movement_type`
- `source_type` e `source_id`
- `occurred_at`
- `reason`/`notes`
- `created_by` quando houver usuários
- referência ao movimento estornado, se aplicável

Movimentos confirmados não devem ser apagados ou editados diretamente. Corrigir criando movimentos inversos/ajustes com referência ao original.

### Estoque de cestas prontas

Pode ser modelado com a mesma estrutura de inventário, distinguindo insumos e produtos acabados por tipo, ou por tabelas específicas. A escolha deve manter uma regra nítida: montar aumenta o saldo de cesta acabada; vender diminui esse saldo. Cestas personalizadas com composição diferente devem ter identidade/rastreamento separado ou ser registradas como montagem e venda sob encomenda sem contaminar o saldo padrão.

### `app_settings`, `devices` e auditoria

- configurações não sensíveis;
- dispositivos pareados, se houver autenticação por dispositivo;
- log de eventos administrativos e operações críticas;
- versão do esquema/migrações.

Não armazenar senhas em texto puro nem inserir tokens em logs.

---

## 7. Regras monetárias e quantitativas

### Dinheiro

- Usar reais e centavos.
- Evitar operações monetárias baseadas em ponto flutuante binário para totais comerciais.
- Guardar valores em centavos inteiros ou usar um tipo decimal apropriado no domínio e persistência.
- Calcular `total da linha = quantidade × preço unitário − desconto`, conforme as regras de desconto estabelecidas.
- Calcular o total da venda a partir das linhas; não confiar em um total enviado pela interface sem recalcular/validar na API.
- Preservar preço unitário e desconto históricos mesmo que o preço sugerido da cesta mude.

### Quantidades

- Estoque e receitas usam sempre unidades-base.
- Conversões ocorrem explicitamente no limite de entrada/saída.
- Não permitir quantidade negativa no cadastro de receita ou compra.
- Produtos vendidos por unidade devem usar quantidades inteiras, salvo uma regra específica documentada.
- Arredondamentos devem ser explícitos e cobertos por testes.

### Idempotência

Cada operação que altera estoque deve ter um identificador de requisição/operação para impedir duplicação após um reenvio. Repetir a mesma requisição idempotente deve retornar o resultado já registrado, e não gravar outra venda ou montagem.

---

## 8. Interface e experiência de uso

### Princípios visuais

- Interface moderna, limpa, legível e rápida.
- Idioma pt-BR e moeda `R$`.
- Contraste adequado, hierarquia visual clara e campos com rótulos explícitos.
- Não depender apenas de cor para comunicar estoque baixo ou erro; usar texto/ícone também.
- Estados visuais distintos para carregando, vazio, erro de conexão, falta de estoque e sucesso.
- Confirmação antes de operações irreversíveis, com resumo do impacto.
- Mensagens que expliquem como resolver o problema, não somente “erro”.

### Mobile

- Navegação simplificada e controles confortáveis ao toque.
- Formulários em coluna, botões principais acessíveis sem rolagem excessiva.
- Montagem e venda rápidas com o mínimo de campos obrigatórios.
- Tabelas convertidas em cartões ou listas quando necessário.

### Windows

- Aproveitar a largura da tela com tabelas, filtros laterais e ações contextuais.
- Navegação lateral persistente.
- Suporte a teclado, busca, seleção e foco previsível.
- Colunas com ordenação/filtros para produtos, movimentos e relatórios.

### Telas mínimas

1. Painel.
2. Estoque de insumos.
3. Cadastro/edição de produto.
4. Receitas e versões de cesta.
5. Compras.
6. Montagem padrão.
7. Montagem personalizada.
8. Vendas.
9. Histórico de montagens e vendas.
10. Movimentações e ajustes de inventário.
11. Relatórios/exportação.
12. Conexão com servidor e backups.

A interface deve chamar serviços/repositórios da aplicação; widgets não devem executar SQL nem calcular consumo de cesta diretamente.

---

## 9. Estrutura de projeto sugerida

A estrutura final pode mudar, mas deve manter fronteiras claras.

### Cliente Flutter

```text
client/
  lib/
    app/
      app.dart
      router.dart
      theme/
    core/
      network/
      errors/
      formatting/
      widgets/
      config/
    features/
      dashboard/
        data/
        domain/
        presentation/
      products/
        data/
        domain/
        presentation/
      recipes/
        data/
        domain/
        presentation/
      inventory/
        data/
        domain/
        presentation/
      purchases/
        data/
        domain/
        presentation/
      production/
        data/
        domain/
        presentation/
      sales/
        data/
        domain/
        presentation/
      reports/
        data/
        domain/
        presentation/
      settings/
        data/
        domain/
        presentation/
  test/
```

### Backend local

```text
backend/
  app/
    main.py
    api/
      v1/
        endpoints/
    core/
      config.py
      security.py
      errors.py
    db/
      session.py
      migrations/
    models/
    schemas/
    repositories/
    services/
      inventory_service.py
      recipe_service.py
      purchase_service.py
      production_service.py
      sales_service.py
      report_service.py
    tests/
  pyproject.toml ou requirements.txt
```

Os nomes são sugestões, não uma imposição. Evitar arquivos gigantes com centenas de funções e evitar abstrações vazias. Cada módulo deve possuir responsabilidade clara.

### Separação de responsabilidades

- **Interface:** exibe dados e recebe ações do usuário.
- **Estado/view model:** gerencia o estado da tela, carregamento e validações de apresentação.
- **Cliente de API/repositório:** busca e envia dados à API.
- **Serviços de domínio no backend:** concentram as regras de compras, receitas, produção, estoque e vendas.
- **Repositórios de persistência:** executam consultas no banco.
- **Banco de dados:** guarda o estado persistente, relações e histórico.

Toda regra crítica de estoque deve ser validada no backend. Uma validação no frontend serve para melhorar a experiência, mas não substitui a validação no servidor.

---

## 10. Rotas de API sugeridas

O prefixo pode ser `/api/v1`. Os caminhos abaixo são uma base para planejamento; ajustá-los ao design REST escolhido.

- `GET/POST /products`
- `GET/PATCH /products/{id}`
- `GET/POST /basket-types`
- `GET/POST /basket-types/{id}/recipes`
- `POST /purchases` e `POST /purchases/{id}/confirm`
- `POST /production-batches` e `POST /production-batches/{id}/confirm`
- `POST /sales` e `POST /sales/{id}/confirm`
- `POST /sales/{id}/cancel`
- `POST /inventory/adjustments`
- `GET /inventory/balances`
- `GET /inventory/movements`
- `GET /reports/daily-summary`
- `GET /reports/sales`
- `GET /reports/production`
- `GET /reports/low-stock`
- `GET /health` para saúde/versão e diagnóstico sem expor dados sensíveis

As operações de criação podem gerar rascunhos; apenas os endpoints de confirmação devem movimentar o estoque. Alternativamente, usar comandos explícitos de confirmação com a mesma garantia transacional. Documentar cada rota e o formato de erros.

### Erros de API

Usar estrutura consistente, por exemplo:

- código estável (`INSUFFICIENT_STOCK`, `SERVER_UNAVAILABLE`, `VALIDATION_ERROR`);
- mensagem legível para o usuário;
- detalhes estruturados, quando úteis;
- identificador de requisição para diagnóstico.

Nunca retornar stack trace, caminho interno, token ou segredo na mensagem apresentada ao usuário.

---

## 11. Backups, restauração e proteção dos dados

Os registros representam operações comerciais; backup é requisito essencial, não melhoria opcional.

- Implementar backup agendado do banco pelo mecanismo seguro do SQLite ou ferramenta compatível. Não depender de copiar de maneira ingênua um arquivo SQLite enquanto está sendo escrito.
- Guardar backups em diretório local escolhido, com nome/data claros e rotação configurável.
- Oferecer backup manual antes de mudanças importantes.
- Exportar também os dados essenciais para um formato documentado quando apropriado.
- Restaurar somente após validar a integridade e compatibilidade da versão do backup.
- Antes da restauração, criar automaticamente um backup do estado atual.
- Solicitar confirmação explícita e deixar claro que a restauração substitui dados atuais.
- Testar restauração na prática, não apenas a criação do arquivo.
- Criar um procedimento de recuperação caso o Windows seja reinstalado ou o computador seja trocado.

JSON não deve ser tratado como substituto automático do backup consistente do banco. Se houver exportação JSON, incluir versão do formato, IDs, referências, unidade-base e datas; validar e apresentar um resumo antes de importar.

---

## 12. Testes obrigatórios antes de considerar o sistema confiável

### Testes de estoque

1. Comprar 100 unidades de um produto; saldo aumenta em 100.
2. Montar 10 cestas que usam 2 unidades desse produto cada; saldo diminui em 20.
3. Registrar venda de 6 cestas prontas; estoque de cestas prontas diminui em 6, e o ingrediente não sofre nova baixa.
4. Tentar montar sem ingredientes suficientes; a operação é bloqueada, nenhum movimento parcial fica salvo.
5. Cancelar/estornar uma montagem; a correção do saldo é rastreável e não duplica movimentos.
6. Registrar perda de 3 unidades; saldo diminui em 3 e o tipo do movimento é perda/descarte.
7. Corrigir contagem física; movimento de ajuste guarda saldo anterior, contagem e diferença.
8. Reenviar a mesma requisição de compra/venda/montagem; nenhuma movimentação duplicada é criada.

### Testes de receitas

9. Alterar a receita da cesta; as montagens antigas continuam indicando a receita original.
10. Montar uma cesta personalizada; somente os itens e quantidades personalizados são consumidos; a receita padrão não muda.
11. Validar unidades e conversões: uma compra de 3 sacos de 5 kg deve acrescentar 15.000 g ao produto cuja unidade-base é grama.
12. Calcular corretamente o ingrediente limitante para o número máximo de cestas montáveis.

### Testes de vendas/valores

13. Vender a mesma cesta em duas vendas com preços diferentes; cada venda preserva seu próprio preço e total.
14. Conferir a quantidade vendida no relatório e no saldo de cestas prontas.
15. Cancelar venda confirmada e verificar o estorno correto.
16. Validar arredondamento de valores, descontos e soma das linhas.

### Testes de sistema

17. Perda de conexão com a API: mostrar erro compreensível e não fingir que a operação foi registrada.
18. Fechar e reabrir o serviço: os dados persistem.
19. Executar migrações sobre uma versão anterior: preservar os dados existentes.
20. Gerar backup, restaurá-lo em ambiente de teste e comparar os saldos/históricos.
21. Validar os fluxos principais em Android e Windows com telas estreitas e largas.
22. Confirmar que a API não está acessível pela internet pública por configuração padrão.

Automatizar estes testes sempre que possível. Não considerar uma funcionalidade pronta apenas porque a tela renderiza ou porque um cenário feliz funciona manualmente.

---

## 13. Fases de desenvolvimento

A IA não deve tentar gerar todo o projeto em uma única resposta. Implementar por incrementos compiláveis/testáveis, com revisões e commits quando houver Git.

### Fase 0 — especificação e arquitetura

- Confirmar as premissas do negócio.
- Registrar ADRs (decisões arquiteturais) essenciais, especialmente a topologia servidor local e compartilhamento de dados.
- Definir modelo de dados, fluxos, erros e critérios de aceitação.
- Preparar estrutura de diretórios e ambientes de desenvolvimento.

### Fase 1 — base técnica

- Criar Flutter client e backend FastAPI.
- Configurar lint, testes, logs seguros, migrações e configuração por ambiente.
- Criar endpoint de saúde, configuração de conexão e teste de conectividade.
- Implementar autenticação local básica e verificar acesso pelo próprio Windows e pelo Android na rede privada.

**Critério de saída:** os dois clientes conectam-se à mesma API, sem qualquer funcionalidade de estoque falsa ou hardcoded.

### Fase 2 — produtos, unidades e receitas

- CRUD de produtos e unidades/embalagens.
- Receitas e versionamento.
- Testes de conversão e validação.

**Critério de saída:** é possível cadastrar a cesta padrão e revisar seus ingredientes e quantidades.

### Fase 3 — livro-razão e compras

- Movimentos de estoque.
- Compra em rascunho e confirmação.
- Saldos, histórico e ajustes.
- Testes de integridade transacional.

**Critério de saída:** compras e ajustes geram saldos rastreáveis e sobreviverem ao reinício.

### Fase 4 — produção/montagem

> **Marco histórico:** telas de produção em lote/desmontagem arquivadas;
> backend compartilhado e montagem durante a venda permanecem ativos.

- Montagem de cestas padrão.
- Baixa de ingredientes e entrada de cestas prontas.
- Validação de faltas e tratamento de cancelamento/estorno.
- Montagem personalizada com snapshot.

**Critério de saída:** a regra de consumo é correta e comprovada por testes automatizados.

### Fase 5 — vendas

- Registro de vendas com preço real variável.
- Baixa de cestas prontas, sem dupla baixa de ingredientes.
- Cancelamento/estorno.
- Resumo diário.

**Critério de saída:** os saldos, quantidades vendidas e valores batem entre banco e relatório.

### Fase 6 — painel, alertas e relatórios

- Painel operacional.
- Estoque mínimo e cesta possível.
- Relatórios com filtros.
- CSV/XLSX.

### Fase 7 — backup, restauração e robustez

- Backup automático e manual.
- Restauração validada.
- Testes de desconexão, repetição de requisições e migração.
- Testes de interface em aparelhos/dispositivos representativos.

### Fase 8 — distribuição

- Empacotar app Windows e definir como o serviço local é instalado/iniciado.
- Gerar APK/AAB Android conforme o método de distribuição desejado.
- Documentar instalação, atualização, backup, restauração e diagnóstico.
- Fazer uma implantação piloto com cadastros reais revisados antes de usar em operação diária.

---

## 14. Critérios gerais de qualidade

A aplicação somente pode ser considerada pronta para uso real se:

- não houver estoque, vendas ou relatórios de demonstração misturados com dados reais;
- toda operação confirmada estiver persistida e for rastreável;
- montagem e venda forem eventos separados;
- receita padrão e receitas históricas não forem alteradas retroativamente;
- quantidades usarem unidades-base consistentes;
- preços de venda permitirem variação por venda;
- falhas não deixarem metade de uma transação gravada;
- não houver botões sem comportamento ou telas que mostrem números estáticos;
- os principais fluxos tiverem testes automatizados;
- os clientes Windows e Android utilizarem a mesma fonte de dados quando conectados;
- backup e restauração forem testados;
- logs e mensagens não expuserem tokens, segredos ou detalhes internos;
- documentação permitir a outra pessoa entender e manter o projeto.

---

## 15. Instruções para a IA desenvolvedora

Copie o texto desta seção como instrução inicial para o agente de programação, juntamente com este documento completo.

> Você é a pessoa responsável pela arquitetura e implementação de um sistema de gestão de estoque, montagem e vendas de cestas, especificado neste documento. Leia a especificação integralmente antes de escrever código.
>
> **Não comece criando todas as telas.** Primeiro identifique as decisões críticas, descreva a arquitetura que pretende usar, proponha o esquema inicial do banco de dados, liste os principais riscos e apresente uma sequência de implementação com critérios de aceitação. Preserve as decisões e os requisitos da especificação; se encontrar uma contradição real, explique-a e proponha a menor mudança necessária.
>
> Stack pretendida: Flutter/Dart para os aplicativos Android e Windows; FastAPI/Python como API local; SQLite com SQLAlchemy e migrações Alembic; Pydantic para validação; testes automatizados. A API local é a única responsável por gravar o banco e executar regras de negócio. Ambos os aplicativos conectam-se à mesma API quando estão na rede local.
>
> Trabalhe incrementalmente. Em cada etapa: (1) inspecione os arquivos existentes; (2) apresente um plano curto e os arquivos que pretende criar/alterar; (3) implemente apenas a etapa acordada; (4) execute os testes e as verificações disponíveis; (5) corrija as falhas antes de avançar; (6) informe arquivos alterados, comandos executados, resultado real dos testes e pendências. Nunca afirme que algo foi testado se não tiver executado o teste.
>
> Regras inegociáveis:
>
> - Não misturar interface, regras de negócio e persistência.
> - Não criar um monólito de arquivos gigantes.
> - Não usar JSON como banco principal.
> - Não abrir o mesmo arquivo SQLite por uma pasta de rede a partir dos dois dispositivos.
> - Não permitir que a interface altere o saldo diretamente; todas as mudanças vêm de movimentos transacionais na API.
> - Montar uma cesta consome ingredientes e aumenta o estoque de cestas prontas. Vender uma cesta reduz o estoque de cestas prontas e não consome seus ingredientes novamente.
> - Validar todos os movimentos no backend e gravar cada operação indivisível numa transação.
> - Impedir duplicação por repetição de requisição.
> - Preservar o histórico e corrigir operações confirmadas por estorno/ajuste rastreável, não por exclusão silenciosa.
> - Preservar preços históricos por venda e versões históricas das receitas.
> - Nunca alterar a receita padrão ao registrar uma cesta personalizada.
> - Não deixar estoque negativo silenciosamente.
> - Não introduzir funções, telas ou indicadores com dados fictícios na produção.
> - Não adicionar bibliotecas sem justificar sua necessidade e compatibilidade com Android/Windows.
> - Não alterar dependências, configurações de build ou arquivos fora do escopo da tarefa sem explicar o motivo.
>
> Antes da primeira implementação, entregue: (a) resumo da arquitetura; (b) diagrama textual do fluxo de dados; (c) ERD ou descrição das tabelas e relações; (d) lista de endpoints; (e) riscos de sincronização, backup, precisão de unidades e valores; (f) plano de testes. Aguarde a revisão desse plano dentro do mesmo fluxo de desenvolvimento antes de criar a implementação completa.
>
> O objetivo é um sistema confiável para uso comercial real, não apenas uma demonstração visual.

---

## 16. Referências técnicas oficiais

- Flutter — plataformas suportadas: https://docs.flutter.dev/reference/supported-platforms
- Flutter — arquitetura recomendada: https://docs.flutter.dev/app-architecture/guide
- Flutter — recomendações de arquitetura: https://docs.flutter.dev/app-architecture/recommendations
- Flutter — arquitetura offline-first: https://docs.flutter.dev/app-architecture/design-patterns/offline-first
- Drift — plataformas e implementação SQLite nativa: https://drift.simonbinder.eu/platforms/
- SQLite — usos apropriados: https://www.sqlite.org/whentouse.html
- SQLite — transações e características: https://www.sqlite.org/docs.html

