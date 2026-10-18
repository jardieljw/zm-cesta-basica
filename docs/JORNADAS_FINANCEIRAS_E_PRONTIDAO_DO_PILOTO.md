# Jornadas financeiras e preparação do primeiro piloto

**Continuação vigente FE-054 — 17/10/2026:** o [piloto Receber](PILOTO_RECEBER_REVISADO.md)
completa o segundo percurso real, com precondição/dia civil/capacidade,
retomada, vínculo com a venda, filtros recolhidos e paginação. Pagar e Receber
compartilham apresentação e recuperação, mantendo regras/métodos separados.
As matrizes FE-050 e os relatos FE-053 abaixo conservam seus escopos históricos;
o próximo recorte é a organização das áreas principais e seus dados reais.

**Continuação FE-053 — primeiro recorte implementado:** usuário autorizou seguir
com Pagar real após a indicação dessa próxima entrega. O
[piloto de pagamento revisado](PILOTO_PAGAR_REVISADO.md) implementa o percurso,
identidade/retomada, precondição atômica, data civil, consulta após confirmação
e carregamento adicional na lista. Atraso foi harmonizado em Pagar. A matriz
FE-050 abaixo conserva a inspeção anterior; não descreve a nova tela entregue.
Receber, integração global de Home/Negócio e validação nativa continuam próprios.

Revisão **16/10/2026**, FE-050. **Planejamento baseado em inspeção do código e
nas evidências das prévias.** O usuário respondeu “SHOW, VAMOS PROSSEGUIR” após
FE-049: organização acolhida como referência e continuidade da consolidação.
Não é autorização para implantar todo o front-end ou escolher um piloto em seu nome.

Base visual vigente: **Leitura recuperada**, Início/Financeiro/Negócio/Estoque/Mais,
home curta com períodos, resultado em Negócio. A
[fonte integrada FE-049](referencias_frontend/rodada-organizacao-2026-10-16/README.md)
permanece intacta. Esta rodada não gera outra prévia: a decisão agora é sobre
comportamento e integração, sem reabrir aparência ou redistribuir os módulos.

## 1. O que já está demonstrado e o que existe no aplicativo

| Assunto | Evidência da prévia integrada | Código atual do aplicativo/servidor | Consequência para o piloto |
| --- | --- | --- | --- |
| Lista → detalhe → formulário → revisão → confirmação → retorno | Demonstrado em Pagar/Receber, com dados fictícios. | Diálogos Flutter atuais enviam diretamente do preenchimento; não têm a nova revisão dedicada. | Integrar a jornada acolhida por incremento, sem confundir a simulação com tela instalada. |
| Integral e Parcial | Integral padrão, campo parcial revelado, valor oculto excluído. | Diálogos atuais mostram campo monetário preenchido com o saldo. | Usar os componentes acordados; não tratar um campo previamente preenchido como a interação Integral/Parcial já entregue. |
| Forma efetiva e data | Forma começa sem seleção; calendário e edição preservados. | Pagar inicia com a forma do título; Receber com CASH. Modelos aceitam data, mas os diálogos inspecionados não a fornecem. | Novo formulário valida a escolha e envia a data efetiva; conservar defaults legados para outros consumidores até mapear impacto. |
| Parcial/quitação e histórico | Saldos simulados coerentes após registrar. | Serviços já validam título OPEN/PARTIAL e valor até o saldo; registram pagamento, razão e novo status. | Reutilizar domínio, sem cálculos financeiros autoritativos no widget. |
| Mesmo pedido recebido duas vezes | Não é comprovado pelo temporizador da prévia. | Servidor possui replay por chave + operação + payload; testes de Pagar/Receber verificam um pagamento para duas requisições idênticas. | Conservar a identidade do comando no cliente para aproveitar a proteção existente. |
| Saldo alterado por outra operação | A prévia compara uma referência local de saldo. | Backend limita o valor ao saldo atual; o request não contém o saldo revisado. | Essa limitação não garante por si só que “Integral” continue quitando o saldo revisado. Alinhar precondição atômica. |
| Confirmação e atualização posterior | Prévia atualiza seu estado local fictício. | Resposta POST é do pagamento; saldo/histórico vêm de GET do título. | Mostrar confirmação recebida e consulta do saldo como estados distintos. |
| Período, atrasos e cobertura | Home e recorte simulados têm o mesmo conjunto completo de quatro títulos. | Listas padrão retornam até 100 itens; critérios de atraso diferem do resumo de negócio. | Não ligar total global à soma da primeira página nem usar filtros aparentemente equivalentes sem conferir datas. |

“Código atual” significa leitura dos arquivos nesta data e testes isolados;
não é comprovação do binário instalado, aparelho real ou cobertura de todos os consumidores.

## 2. Contrato de comportamento da jornada

Fluxo conservado: **localizar → entender o saldo → preencher → revisar → registrar
→ reconhecer o resultado → continuar a consulta**.

1. **Consulta:** identificar módulo, período de vencimento, situações e cobertura.
   Ação de um resumo abre esses mesmos critérios. Posição atual não vira saldo
   histórico por causa do período escolhido.
2. **Detalhe:** pessoa/conta identificável, saldo atual, original, anteriores,
   vencimento e situação. Pagamento/recebimento depende das regras do domínio.
3. **Preenchimento:** Integral do saldo consultado como padrão. Parcial explícito;
   campo oculto não participa do comando. Data e forma efetiva obrigatórias na
   jornada nova; observação opcional. Não selecionar conta financeira ou saída/rota.
4. **Revisão:** valor desta operação, título, data, forma e saldo esperado.
   Editar conserva os dados; revisão não é confirmação. Verificar saldo atualizado
   não autoriza alterar silenciosamente o valor que já foi conferido.
5. **Envio:** congelar o comando e sua identidade antes da primeira chamada.
   Um toque adicional não cria outro comando. Animação não controla gravação.
6. **Confirmação:** validar a resposta como pagamento do mesmo título e guardar
   sua referência. Consultar o saldo autoritativo e invalidar consultas afetadas.
7. **Retorno:** manter recorte e referência de posição. Se a conta quitada sair
   do filtro de abertas, explicar a consequência. Uma lista desatualizada não
   desfaz o pagamento já confirmado nem autoriza registrar novamente.

### Rascunho editável e comando enviado são objetos diferentes

**Proposta de contrato para o piloto:** durante a jornada, preservar o rascunho
ao editar a revisão e alternar áreas do mesmo contexto. Não copiar dados para
outro título. Limpar apenas por descarte explícito ou conclusão correspondente.
Tema, largura e escala de texto não apagam preenchimento.

Salvar automaticamente todo rascunho não enviado após encerrar o app continua
fora da promessa inicial. Já uma **tentativa enviada com resultado incerto**
precisa de persistência local antes do envio: origem/servidor, tipo da operação,
título, chave, corpo congelado e estado. Falha em conservar essa identidade
impede iniciar o envio seguro; não seguir como se tivesse sido salva.
Troca de servidor exige resolver o contexto da tentativa, sem enviá-la a outra origem.

## 3. Estados, mensagem e próxima ação

Os textos abaixo são propostas de conteúdo; a implementação deve usar l10n.

| Estado | Comunicação proposta | Ação e preservação |
| --- | --- | --- |
| Consultando, sem dados | “Consultando as contas…” | Aguardar; sem total zero fictício. |
| Consulta concluída e vazia | “Nenhuma conta neste recorte.” | Alterar período/filtros; mostrar quais foram usados. |
| Consulta indisponível | “Não foi possível consultar agora.” | Consultar novamente; sem afirmar ausência de dívidas. |
| Informação anterior disponível | Identificar data/contexto da consulta anterior. | Atualizar; não promover valor anterior a saldo atual. Isso exige dados anteriores realmente disponíveis. |
| Campo inválido | Explicar junto ao campo o que corrigir. | Conservar restante e levar ao campo correspondente. |
| Revisão pronta | Valor, título, data, forma e consequência esperada. | Editar ou confirmar; nenhuma gravação ainda. |
| Enviando | “Registrando…” | Bloquear novo envio da mesma intenção; preservar comando. |
| Recusa comprovada | Explicar o motivo e que esta tentativa foi recusada. | Corrigir quando permitido e revisar novamente. Não classificar qualquer erro de rede como recusa. |
| Saldo alterado | “O saldo mudou. Confira o valor atualizado.” | Reconsultar título e exigir nova revisão antes de novo comando. |
| Resposta desconhecida | “Ainda não recebemos a confirmação deste registro.” | Conservar identidade; retomar a mesma tentativa segundo o contrato abaixo. |
| Registro confirmado; saldo ainda consultando | “Pagamento registrado. Atualizando a conta…” | Guardar referência da confirmação e buscar saldo/histórico. |
| Registro confirmado; atualização falhou | “Pagamento registrado. Falta atualizar a consulta.” | Atualizar a consulta, sem oferecer outro registro do mesmo pagamento. |
| Concluído | Confirmação, valor e referência; saldo atual quando confirmado pela consulta. | Voltar ao detalhe/lista, conservando contexto. |

## 4. Resposta desconhecida: resolver a semântica antes do botão

Fontes: [idempotência transacional](../backend/app/core/idempotency.py),
[API Pagar](../backend/app/api/v1/payables.py),
[API Receber](../backend/app/api/v1/receivables.py) e
[cliente HTTP](../client/lib/core/api_client.dart), inspecionados em 16/10/2026.

O servidor retorna a resposta armazenada para mesma chave, operação e payload;
rejeita uso incompatível da chave. Os serviços Dart aceitam chave explícita,
mas os diálogos atuais não a passam. O cliente HTTP gera uma nova UUID quando
não recebe chave. Assim, um segundo acionamento após erro pode ser outro comando;
a proteção do servidor não substitui conservar a identidade no cliente.

**Recomendação técnica para avaliação do piloto:** retomar o POST com a mesma
chave e o mesmo corpo, após validar o contexto original. Isso pode obter a
confirmação anterior **ou concluir a intenção original se ela ainda não chegou**.
Por isso o botão deve comunicar **“Retomar registro”**. Não rotular essa ação
como consulta estritamente de leitura ou afirmar que só busca algo já gravado.

Uma ação chamada **“Verificar registro”**, com promessa apenas de consultar,
exige contrato real de consulta correspondente. Não foi encontrado esse contrato
nas rotas de Pagar/Receber inspecionadas. O botão fictício do catálogo não o cria.
Ausência de registro visível numa consulta não comprova que outra requisição
não esteja em andamento. Não liberar uma chave nova só por não encontrar resposta.

O comando congelado inclui valor, data e forma, sem recalcular pelo saldo novo
nem substituir data por agora no reenvio. A recuperação de um replay acontece
antes de reavaliar a precondição de saldo de um comando novo; caso contrário,
uma quitação já concluída poderia parecer falha porque o saldo passou a zero.
Contrato final, limites de retomada e compatibilidade precisam estar alinhados
no incremento real. Não há recuperação implementada nesta entrega documental.

## 5. Lacunas concretas a resolver para a integração

### L-01 — Saldo revisado e confirmação concorrente

[Pagar](../backend/app/services/financial.py), `record_payable_payment`, e
[Receber](../backend/app/services/receivables.py), `record_receivable_payment`,
rejeitam valor maior que o saldo atual. Os
[schemas de Pagar](../backend/app/schemas/financial.py) e
[Receber](../backend/app/schemas/receivables.py) não recebem o saldo revisado.

Exemplo: revisão integral de 480; um estorno faz o saldo subir a 680; enviar 480
pode ser aceito como parcial pelas regras atuais. Portanto “valor ≤ saldo” não
garante a consequência “quitou” que foi apresentada na revisão. É uma comparação
estática das regras, não uma corrida reproduzida em produção.

| Opção | Avaliação |
| --- | --- |
| Apenas GET antes do POST | Reduz desatualização, mas mantém intervalo entre leitura e gravação. Não comprova a precondição atômica. |
| Saldo revisado como precondição verificada na transação do POST | Recomendação de contrato mínimo a alinhar: rejeitar mudança antes de gravar e pedir nova conferência. Avaliar campo opcional/aditivo e compatibilidade dos consumidores. |

Não aplicar alteração de schema/regras nesta rodada. A precondição de saldo
também não equivale a uma versão completa de todo o histórico do título.

### L-02 — Data civil e instante persistido

Os modelos Dart aceitam `paymentDate` e serializam `toIso8601String`; os schemas
aceitam `datetime` opcional. Os diálogos atuais omitem a data; o servidor usa
`utc_now`. A prévia oferece um dia de calendário. Antes de ligar os dois, definir
a representação e o fuso de negócio, preservando UTC e o significado dos
instantes históricos. Não inventar uma hora efetiva nem deslocar o dia escolhido
pela localização do aparelho. A data congelada no envio deve ser a mesma no replay.

### L-03 — “Hoje” e “atrasadas” precisam concordar

O [resumo do negócio](../backend/app/services/business_dashboard.py) compara
`due_date.date()` com a data de negócio (UTC−03 nesta implementação).
As listas de [Pagar](../backend/app/services/financial.py) e
[Receber](../backend/app/services/receivables.py), `list_accounts_payable` /
`list_receivables`, usam `due_date < utc_now()` em `overdue_only`. Seus
[serializadores Pagar](../backend/app/api/v1/payables.py) e
[Receber](../backend/app/api/v1/receivables.py) também calculam `is_overdue` por instante.

Exemplo estático: às 15:00Z de 16/10, um vencimento representado por 16/10 00:00Z
é anterior ao instante atual, mas sua data civil ainda é hoje. Os critérios podem
divergir. Essa observação corrige o alcance da expressão “serviço atual” na
pesquisa anterior: ela se referia ao resumo, não a todas as listas financeiras.
Antes de integrar atalhos, harmonizar data civil e grupos conforme FE-040,
preservando os registros existentes; conferir limites e virada do dia.

### L-04 — Cobertura e retorno de consultas

Os serviços de lista usam `limit=100/offset=0` por padrão. O piloto deve informar
o recorte e permitir a cobertura necessária, sem apresentar a soma de uma página
como total global. Reutilizar totais autoritativos com critérios equivalentes ou
alinhar agregação/paginação antes de ligar os indicadores da home.

A resposta POST identifica o pagamento, mas não traz o saldo atualizado do título.
Confirmar o pagamento e falhar no GET posterior são dois resultados diferentes.
Ainda há respostas de domínio em `detail` textual; mapear os códigos/formatos
realmente disponíveis antes de distinguir recusa, concorrência e falha incerta.
Não extrair decisões comerciais comparando frases traduzidas de erro.

## 6. Primeiro piloto proposto, ainda não escolhido pelo usuário

**Recomendação: Pagar, sobre um título existente**, integrado ao ponto de entrada
atual. A tela já permite injeção do serviço e tem controle de versão de consulta;
o recebimento também sincroniza a venda, ampliando os efeitos a conferir.
Fontes: [PayablesView](../client/lib/views/payables_view.dart),
[ReceivablesView](../client/lib/views/receivables_view.dart) e seus serviços.
Essa é uma avaliação de escopo do agente, não preferência atribuída ao usuário.

Inclui lista/detalhe do recorte, Integral/Parcial, data, forma, observação, revisão,
edição, envio com identidade estável, resposta conhecida/incerta, saldo/histórico
e retorno coerente. Componentes recebem dados e opções do módulo; Pagar e Receber
mantêm seus próprios códigos. Valores/textos usam AppFormatters/l10n e API segura.
Não construir um formulário universal com todas as exceções financeiras.

Não inclui criar/editar obrigações, parcelamento, recorrência, estornos,
cancelamentos, seleção em lote, bancos/importação ou migração da navegação/tema
de todas as telas. Essas funções existentes continuam preservadas. Home global
e Negócio não são reescritos como efeito colateral do piloto.

**Prontidão:** fluxo de apresentação especificado; contrato de envio/data/datas
de vencimento e cobertura precisam do fechamento técnico acima. A escolha da
rotina e o escopo de implementação real têm alinhamento próprio. O próximo passo
é preparar esse incremento com critérios verificáveis, sem começar a escrever
Flutter/API a partir de uma aprovação genérica da aparência.

## 7. Critérios de saída para o incremento real

- Integral ignora valor parcial oculto; parcial válido deixa o saldo correto.
- Editar preserva campos; data escolhida mantém o mesmo dia nas plataformas.
- Duplo toque/reenvio conserva um registro, inclusive após resposta perdida.
- Mesma chave com conteúdo diferente é rejeitada; não mascarar incompatibilidade.
- Alteração de saldo exige nova conferência antes de uma nova gravação.
- Pagamento confirmado com GET falho continua confirmado; repetir a consulta não paga.
- Home/atalho/lista usam o mesmo significado de hoje, atraso, período e cobertura.
- Retorno preserva filtro/contexto; conta quitada sai de abertas de modo explicável.
- Teclado, foco, texto maior, movimento reduzido e áreas seguras são verificados
  no incremento Android/Windows. A integração iOS mantém entrega e ambiente próprios.
- Testes nunca usam o banco da empresa; nenhuma operação financeira vira exclusão
  ou reescrita de histórico. Ver [integridade](REGRAS_DE_INTEGRIDADE_E_EVOLUCAO.md).

## 8. Evidência, fontes e limites

Inspeção primária local em **16/10/2026**, funções e arquivos ligados junto aos
achados. Pesquisa anterior do [catálogo](CATALOGO_COMPONENTES_FRONTEND.md) e da
[composição](COMPOSICAO_DAS_PAGINAS_FRONTEND.md) foi aproveitada; sem nova pesquisa
externa. Propostas de estado, precondição e piloto são inferências do agente.

Suítes existentes executadas nesta rodada: **363 backend e 238 Flutter aprovados**,
com bancos temporários isolados. Os testes de replay existentes são
[Pagar — test_payable_idempotency](../backend/tests/test_payables.py) e
[Receber — test_receivable_payment_idempotency](../backend/tests/test_receivables.py).
Isso não testa persistência de tentativa de pagamento após reiniciar o app,
novos contratos propostos, corrida real ou binários instalados. Os padrões de
persistência existentes em [montagens](../client/lib/services/basket_assembly_service.dart)
e [novo banco](../client/lib/services/backup_service.dart) são referências locais
a avaliar, sem copiar suas regras de descarte/classificação para pagamentos.

O [registro de inspeção](validacoes_frontend/fe-050-jornadas-2026-10-16/README.md)
conserva hashes das fontes lidas e o alcance da verificação. Prévia FE-049 e seus
arquivos históricos permanecem intactos. Sem mudança Flutter/API/banco, nova
dependência, distribuição, nova prévia ou commit Git nesta rodada.
