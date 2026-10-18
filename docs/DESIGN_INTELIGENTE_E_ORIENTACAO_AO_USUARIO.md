# Design inteligente: informação útil, antecipação e cuidado com o usuário

**Complemento vigente FE-049:** o usuário detalhou a intenção da home como
resumo curto do essencial, com Dia/Semana/Mês e acesso fácil à investigação.
A seção 14 registra esse complemento. Leitura recuperada escolhida; resultado
fica em **Negócio**, junto de vendas/clientes. A fundamentação abaixo permanece.

Versão **0.1**, revisão **16/10/2026**, FE-036/FE-037.
**Documento de referência específico para o produto e seus agentes.**
Conserva a intenção do usuário, a fundamentação pesquisada, sua aplicação ao ZM,
limites e critérios de evolução. A memória do projeto serve como índice e
histórico; não substitui este conteúdo por resumos.

## 1. Intenção confirmada pelo usuário

O aplicativo deve usar as informações que possui para ajudar a pessoa a
perceber o que importa, antecipar necessidades e encontrar caminhos úteis.
Informações importantes devem aparecer nas telas e momentos em que fazem
diferença, mesmo quando a pessoa ainda não souber que precisa procurá-las.

O objetivo é transmitir cuidado: o usuário percebe que o sistema acompanha o
contexto do negócio, organiza o que merece atenção e facilita sua vida. Esse
efeito pode vir de regras, cálculos, relações entre registros, padrões de
apresentação e preferências declaradas, sem um modelo de IA raciocinando em
tempo real. A interface não precisa assumir voz de assistente ou falar como
uma pessoa para oferecer essa experiência.

O usuário também pediu documentação específica e aprofundada, preservando o
entendimento das pesquisas, em vez de manter apenas sínteses na memória.

**Alcance confirmado:** direção do produto e método de projeto. Os exemplos,
regras candidatas e propostas de arquitetura abaixo ainda serão avaliados por
etapas. Este documento não afirma que todos esses comportamentos já existem.

## 2. O significado de inteligência neste projeto

Há três trabalhos complementares:

| Trabalho | O que entrega à pessoa | Exemplo aplicado |
| --- | --- | --- |
| Organizar | Torna dados reconhecíveis e comparáveis. | Identificar conta, saldo em aberto e vencimento sem confundir valores. |
| Interpretar e contextualizar | Explica a relevância e os limites de uma informação. | Mostrar que o resultado gerencial tem uma limitação porque há vendas sinalizadas sem custo registrado. |
| Antecipar e orientar | Traz uma necessidade ou próximo passo útil ao contexto atual. | Dar acesso às contas com vencimento relevante sem exigir que a pessoa monte a consulta do zero. |

A definição anterior do manual enfatizava clareza, adaptação e continuidade.
Ela foi ampliada por FE-036 para incluir explicitamente interpretação,
antecipação e orientação proativa com base nos dados do negócio.

Isso também inclui conforto e confiança: reduzir escolhas desnecessárias,
mostrar o resultado de uma ação, indicar o que ainda falta e oferecer uma
mensagem tranquila quando os dados realmente sustentarem essa conclusão.
O padrão Integral, escolhido porque pagamentos parciais são raros na rotina,
já exemplifica uma decisão contextual que economiza esforço sem depender de IA.

## 3. Conceitos pesquisados e como se relacionam

### 3.1 Design antecipatório

[Aaron Shapiro, em artigo de autoria própria publicado em 2015](https://www.fastcompany.com/3045039/the-next-big-thing-in-design-fewer-choices),
descreve design antecipatório como uma forma de reduzir decisões e etapas por
meio de dados, preferências e lógica de negócio. Sua concepção inclui execução
automática de decisões em nome da pessoa, indo além de simples recomendações.

**Aplicação ao ZM:** antecipar a informação e preparar um caminho relevante.
**Limite da adoção:** a automação ampla descrita pelo autor não foi escolhida
para as operações financeiras deste projeto. A fonte é um ensaio de projeto,
não evidência experimental de que qualquer antecipação melhora a experiência.
Não transportar suas estatísticas ou previsões sobre produtos para o ZM.

### 3.2 Informação que leva a uma ação

Na [documentação didática de Overview Pages](https://learning.sap.com/courses/discovering-sap-s-4hana-embedded-analytics/working-with-overview-pages_be723c43-51c9-46cd-bd7e-20973fb41aff),
a SAP relaciona visão geral, investigação de detalhes e ação sobre uma situação.
O conteúdo deve permitir compreender o negócio sem sobrecarregar com detalhes.

**Aplicação ao ZM:** cada resumo importante explica o que representa e conduz
ao recorte correspondente. Um aviso de estoque conduz aos itens afetados;
um destaque financeiro conduz às contas que justificam aquela informação.
**Limite:** essa relação não exige reproduzir o layout SAP, criar dezenas de
cartões ou instalar uma plataforma de análise. A conexão deve ser útil à tarefa.

### 3.3 Detecção de situações do negócio

A documentação de [Situation Handling da SAP](https://help.sap.com/docs/SAP_S4HANA_CLOUD/a630d57fc5004c6383e7a81efee7a8bb/516c8ecb7462453ca430a42481cc33ec.html)
descreve detectar situações por condições de negócio, informar pessoas
relevantes e apresentar contexto e ações propostas. Seu
[resumo de funcionamento](https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/8308e6d301d54584a33cd04a9861bc52/4f5e8536fe82403ea6685439db5afc3c.html?locale=en-US)
também distingue detecção e transação: eventos ou execuções periódicas podem
introduzir atraso, e o ciclo de vida da situação precisa ser acompanhado.

**Aplicação ao ZM:** separar o fato persistido, a condição detectada e sua
apresentação. Após uma mudança, reavaliar se a orientação continua válida.
**Limite:** páginas Help foram obtidas pelo conteúdo indexado da pesquisa;
a abertura direta do resumo não expôs o texto. Uma
[lição encontrada sobre templates](https://learning.sap.com/courses/detailing-intelligent-procurement-and-procurement-analytics/using-situation-templates-in-procurement_acf8b693-8b91-44d9-8922-64275ba82b87)
retornou 404 e não fundamenta a especificação. Não afirmar conferência
completa do framework nem adotá-lo como implementação necessária ao app.

### 3.4 Informação contextual e atenção limitada

O [Carbon — Notification](https://www.carbondesignsystem.com/building-blocks/core/components/notification/guidelines)
distingue orientação contextual antes de uma ação de feedback posterior e
recomenda mensagens concisas e cuidado com excesso de destaques. O
[GOV.UK — Notification banner](https://design-system.service.gov.uk/components/notification-banner/)
orienta usar banners com parcimônia e colocar informação diretamente ligada à
tarefa no próprio conteúdo principal.

**Aplicação ao ZM:** usar o lugar relacionado ao assunto, com ênfase proporcional.
Uma explicação sobre saldo pertence ao contexto financeiro; erro de campo fica
associado ao campo. Informações úteis também podem ser conteúdo normal de página.
**Limite:** não copiar restrições de linhas, foco, botões ou cores dessas
bibliotecas sem avaliar acessibilidade e os padrões do ZM.

### 3.5 Percepção acessível das mudanças

O [W3C — Status Messages, 4.1.3](https://www.w3.org/WAI/WCAG22/Understanding/status-messages.html)
trata mensagens de estado que precisam ser identificáveis para tecnologia
assistiva sem receber foco. Também alerta para interfaces excessivamente
verbosas em leitores de tela.

**Aplicação ao ZM:** mudanças relevantes têm contexto compreensível e anúncio
adequado; atualizações de contagem não roubam foco nem repetem avisos a cada
reconstrução da tela. **Limite:** nem todo conteúdo proativo é uma mensagem de
estado segundo a WCAG. A pesquisa não certifica o aplicativo e não substitui
validação nas APIs de acessibilidade das plataformas.

Todas as consultas desta seção ocorreram em **16/10/2026**. Os conceitos se
complementam; não há uma única definição universal que transforme toda essa
direção em um componente pronto. As propostas seguintes são uma síntese de
projeto para o ZM, não prescrições literais das fontes.

## 4. Como transformar dados em orientação útil

Percurso de raciocínio do produto, a especificar por regra:

**Dados → condição verificável → significado para a tarefa → lugar/momento →
explicação → próximo passo → reavaliação.**

1. **Dados:** quais registros e campos sustentam a informação? De quando são?
   A consulta cobre todos os registros necessários? Qual é a origem?
2. **Condição:** o que exatamente precisa ser verdadeiro? Escrever uma regra
   verificável, evitando expressões vagas como “o sistema acha importante”.
3. **Significado:** que dúvida, esquecimento, esforço ou interpretação errada
   essa informação ajuda a resolver? Por que ela interessa à pessoa agora?
4. **Contexto:** em qual tela e etapa isso é útil? Deve aparecer na visão geral,
   no módulo ou apenas junto ao registro? Qual destaque é proporcional?
5. **Explicação:** apresentar conclusão curta e oferecer acesso à base quando
   necessário. A pessoa precisa conseguir entender a razão do destaque.
6. **Próximo passo:** consultar, conferir, corrigir ou entrar numa jornada.
   Informações de compreensão podem ser úteis mesmo sem um botão próprio.
7. **Reavaliação:** definir quando a condição deixa de valer, muda ou passa a
   desconhecida. Visualizar uma informação não resolve o fato que a originou.

Exemplo: um produto ativo está com quantidade atual abaixo do mínimo cadastrado.
Isso pode justificar informar uma necessidade de atenção no estoque, com acesso
ao item. A diferença para o mínimo é calculável; ela não prova uma data de
ruptura, a quantidade ótima de compra ou que o estoque físico foi contado hoje.
Essas conclusões exigem outros dados e regras.

## 5. Perguntas que toda proposta deve responder

Uma informação merece espaço quando puder responder de modo satisfatório:

- **Utilidade:** o que a pessoa passa a saber ou fazer melhor?
- **Evidência:** qual dado confiável sustenta a afirmação?
- **Relevância:** por que nesta tela e neste momento?
- **Clareza:** o significado é compreensível sem interpretar um indicador solto?
- **Proporção:** esse assunto merece destaque maior do que o conteúdo ao redor?
- **Continuidade:** é possível investigar ou seguir o caminho sem perder contexto?
- **Validade:** como isso reage a dados incompletos, antigos ou alterados?
- **Controle:** a pessoa consegue entender e escolher o que fazer a seguir?

Quando houver hipótese sobre gosto, frequência ou utilidade, registrar como
hipótese e avaliar com o usuário. Personalização deve aproveitar escolhas e
necessidades conhecidas; não inventar preferências individuais a partir de um
único clique. A aparência agradável deve favorecer compreensão e tranquilidade,
com espaço e linguagem acolhedora, sem mascarar pendências ou limitações.

## 6. Mapa de lugares e momentos

| Lugar | Papel informativo proposto | Exemplos de conteúdo útil |
| --- | --- | --- |
| Início / visão geral | Orientar o dia e oferecer entradas para o que merece atenção no negócio. | Vencimentos relevantes, estoque abaixo do mínimo e limitação de um resumo, quando sustentados pelos dados. |
| Visão geral do Financeiro | Contextualizar a situação financeira cadastrada e facilitar investigação. | Contas a pagar/receber, vencimentos e confirmações do período com significados distintos. |
| Lista filtrada | Explicar o recorte e ajudar a localizar os itens que compõem uma informação. | Critérios ativos, registros afetados e cobertura da consulta. |
| Detalhe | Relacionar os fatos de um registro e orientar a ação específica. | Saldo restante após pagamentos anteriores; origem e histórico. |
| Formulário / revisão | Antecipar consequências conhecidas e ajudar a evitar erro. | Integral usa o saldo atual; valor deste registro e saldo esperado são apresentados separadamente. |
| Resultado | Dar segurança sobre o que foi efetivamente confirmado e o que ainda depende de consulta. | Registro confirmado com atualização da lista pendente, quando essa for a situação real. |
| Estoque / produtos | Apoiar preparação e reposição com dados e unidades reconhecíveis. | Itens abaixo do mínimo, saldo e unidade-base associados. |
| Configurações | Explicar consequência das preferências e estado de recursos. | Preferência de destaque e informações de conexão/backup quando seus contratos fornecerem esses estados. |

A visão geral faz síntese; o módulo aprofunda; o detalhe explica o caso. A mesma
situação pode ter representações diferentes nesses lugares sem gerar várias
ocorrências ou avisos repetidos. O usuário não deve precisar decorar em qual
relatório está um dado importante para a tarefa atual.

## 7. Catálogo inicial de oportunidades — ainda propostas

Inspeção de código em **16/10/2026** e guias atuais, sem executar o aplicativo:

| ID | Informação candidata e benefício | Dados/condição necessários | Lugar e caminho propostos | Situação e limite |
| --- | --- | --- | --- | --- |
| INT-01 | Destacar contas abertas com vencimento relevante para reduzir esquecimento. | Saldo pendente, situação, vencimento, data de referência e recorte explicitados. | Início/Financeiro → consulta correspondente → detalhe. | Há dados de pendências/vencimentos no resumo atual. Mensagem, seleção e prioridade novas ainda por alinhar; alerta não significa débito bancário nem inadimplência fora do app. |
| INT-02 | Sinalizar produtos abaixo do mínimo para facilitar conferência e reposição. | Produto ativo, saldo, unidade e mínimo cadastrado; comparação na mesma unidade. | Início em síntese; Estoque com itens e seus dados. | API atual fornece contagem e itens abaixo do mínimo. Não é previsão de falta nem recomendação automática de quantidade de compra. |
| INT-03 | Explicar a limitação do resultado quando há vendas sinalizadas sem custo registrado. | Indicador de qualidade fornecido pelo cálculo do domínio. | Junto do resultado gerencial e acesso ao contexto disponível. | `sales_without_cost_count` existe no resumo. Não substituir a regra por “custo igual a zero” nem inventar lucro/custo ausente. |
| INT-04 | Mostrar o saldo que resta receber/pagar e preparar a opção usual. | Valor original, registros anteriores válidos e saldo atual. | Detalhe → Integral por padrão → revisão. | Integral e parcial já têm decisões confirmadas. Recomendações e dados do exemplo não substituem verificação do saldo pelo serviço. |
| INT-05 | Dar tranquilidade quando não há títulos vencidos na base consultada. | Consulta concluída, atualidade e cobertura suficientes para essa afirmação. | Resumo discreto da área, com escopo legível. | Candidato de comunicação positiva; “nenhuma conta vencida cadastrada nesta consulta” não significa “toda a vida financeira está em dia”. Falha de consulta não produz tranquilização. |
| INT-06 | Mostrar variação útil entre períodos comparáveis. | Duas bases comparáveis, períodos e cobertura conhecidos; regra de comparação alinhada. | Módulo/indicador pertinente, com acesso aos períodos. | Ideia futura; esta inspeção não comprova comparação pronta. Queda ou alta não têm significado bom/ruim universal. |
| INT-07 | Dar visibilidade ao que aguarda revisão numa importação financeira. | Origem, estado de revisão e vínculo dos itens, conforme contrato do módulo. | Futuro fluxo de importação/Financeiro → itens a conferir. | Integração futura de apresentação. Revalidar backend financeiro em evolução; semelhança entre linhas não comprova duplicidade nem pagamento. |

Base local consultada: [resumo gerencial](DASHBOARD_E_FINANCEIRO.md),
[schema do dashboard](../backend/app/schemas/business_dashboard.py),
[serviço de resumo](../backend/app/services/business_dashboard.py) e guias de
[Pagar](CONTAS_A_PAGAR.md)/[Receber](CONTAS_A_RECEBER.md).
Para INT-07, consultar a [memória financeira](MEMORIA_IMPLEMENTACAO_FINANCEIRA.md)
e a [homologação](HOMOLOGACAO_IMPORTACAO_FINANCEIRA.md) antes de definir o contrato.

**Não confundir disponibilidade de dados com apresentação entregue.** Alguns
indicadores já existem no código; a nova camada de seleção, orientação e layout
é planejamento. Código inspecionado não prova comportamento instalado nem teste.

**Detalhamento FE-039/FE-040:** [primeiras regras de informação útil](REGRAS_DE_INFORMACAO_UTIL_FRONTEND.md)
especifica INT-01, INT-02 e INT-03 com condições, dados, textos, destinos, validade,
casos e lacunas atuais. Próximos vencimentos em **três dias** foram confirmados
pelo usuário, com hoje e atrasadas separados. O indicador de custo é explicado
conforme a regra real, incluindo itens de custo não positivo. Textos, disposição
e integração das candidatas continuam propostas.

## 8. Confiança nos dados e significado financeiro

Proatividade exige precisão de contexto, inclusive quando a conclusão é simples:

- **Posição atual e período:** estoque e pendências atuais não se tornam posições
  históricas porque o usuário escolheu um período antigo para vendas. O resumo
  atual distingue esses conceitos; preservar os rótulos e o cálculo.
- **Registro e dinheiro disponível:** saldo a receber, vendas realizadas e
  recebimentos confirmados têm significados diferentes. Recebido menos pago no
  período não é saldo bancário nem prova capacidade de pagar novas despesas.
- **Cobertura:** soma de uma página, amostra, arquivo ou conta bancária não pode
  ser apresentada como universo completo. Exibir escopo pertinente.
- **Atualidade:** uma consulta anterior tem data e condição próprias; indisponível,
  desconhecido e zero são resultados distintos. Regras que exigem dados novos
  podem ficar indisponíveis quando esses dados não estiverem acessíveis.
- **Fato e projeção:** histórico e condição observada não garantem comportamento
  futuro. Uma previsão requer modelo/regra, dados e comunicação de limite próprios.
- **Calendário:** vencimento civil, data efetiva do pagamento e horário do evento
  não são intercambiáveis. Definir referência de data/fuso da regra com o domínio.
- **Relação entre registros:** a mesma operação importada, conciliada e registrada
  em fluxos diferentes não pode produzir conclusões ou contagens independentes
  sem resolver a origem. Preservar os contratos do trabalho financeiro.

O sistema pode orientar a investigação com o que sabe e explicar o que falta
saber. A confiança vem da correspondência entre mensagem e evidência, não de
usar linguagem categórica ou parecer mais inteligente do que os dados permitem.

## 9. Atenção, prioridade e sensação de cuidado

Priorizar por **impacto, urgência, relação com a tarefa e confiança dos dados**.
São critérios de avaliação, não uma pontuação universal já definida. Uma
confirmação financeira incerta pode precisar de mais atenção do que um indicador
comercial interessante; a interpretação depende do contexto.

Agrupar situações relacionadas e oferecer detalhes sob demanda. Evitar que a
mesma condição se reapresente como novidade a cada abertura da página. Informar
não é necessariamente interromper: muitas orientações pertencem ao conteúdo
normal ou a um resumo discreto. Quantidade máxima, ordem e ênfase serão avaliadas
na apresentação, sem fixar um número arbitrário como padrão do aplicativo.

Um estado importante pode continuar visível enquanto for verdadeiro; um destaque
promocional ou uma dica não deve ocupar o lugar de um problema real. Preferir
linguagem específica, respeitosa e sem culpabilização. A meta é reduzir esforço
e incerteza, não criar medo ou pressionar cliques.

Reconhecer que a pessoa viu um aviso é diferente de resolver sua causa. Se houver
dispensar/adiar no futuro, definir seu alcance: representação, duração, condição
de reaparecimento e quais fatos continuam consultáveis. Não adicionar uma
central de notificações, push ou agendamento por consequência deste documento.

## 10. Ciclo de vida e contrato de cada orientação

Uma regra deve identificar a condição e os registros afetados de forma estável.
Atualizar o valor ou estado não cria automaticamente uma nova ocorrência.
Proposta de ciclo: **avaliável → ativa → apresentada → reavaliada → resolvida ou
obsoleta**. “Dados insuficientes” é resultado de avaliação, não “resolvida”.
Fechar uma mensagem não altera títulos, estoque ou histórico.

Antes de implementar cada candidata, preencher a especificação:

| Campo | Conteúdo necessário |
| --- | --- |
| Identidade e versão | Nome estável da regra, finalidade e versão quando a lógica mudar. |
| Benefício | O que o usuário consegue compreender, evitar ou fazer melhor. |
| Dados e responsável | Fonte, campos, unidade, cobertura, atualidade e módulo responsável. |
| Condição e exceções | Predicado verificável; limites, ausência de dados e casos em que não se aplica. |
| Saída e explicação | Significado, valores e referências que sustentam a informação. |
| Local e momento | Tela, etapa, contexto e critérios de prioridade/ênfase. |
| Próximo passo | Destino com os mesmos critérios; ação permitida e limites. |
| Validade | Quando recalcular, resolver, tornar obsoleta ou indisponível. |
| Repetição e preferência | Como evitar duplicação e tratar dispensa/adiamento, se existirem. |
| Acessibilidade | Texto além de cor, ordem de leitura, anúncios necessários e foco preservado. |
| Evidência | Casos de conferência, retorno do usuário e distinção entre simulação e integração. |

Exemplo de especificação de INT-02: comparar quantidade atual e mínimo do produto
ativo na unidade-base; apresentar quais itens estão abaixo e abrir a consulta
coerente. Se o mínimo não representar a rotina ou os dados não cobrirem o produto,
isso precisa ser tratado pela regra. Atualizar estoque ou mínimo pode encerrar a
condição. Nenhuma dessas etapas registra uma compra automaticamente.

## 11. Responsabilidades da arquitetura — proposta

| Responsabilidade | Papel | Limite |
| --- | --- | --- |
| Domínio e persistência | Produzir fatos e cálculos comerciais confiáveis, validar operações e conservar histórico. | Cálculo de saldo e permissão não dependem da mensagem na tela. |
| Avaliação das regras do módulo | Transformar dados disponíveis em condições e explicações verificáveis. | Não acessar SQLite pela interface nem duplicar fórmulas financeiras nos widgets. Local técnico definitivo por alinhar. |
| Composição da página | Selecionar representações pertinentes à tarefa e à prioridade acordada. | Não transformar qualquer número em alerta nem promover dado incompleto a conclusão global. |
| Componentes compartilhados | Apresentar resumo, explicação, situação e caminho com os padrões visuais/acessíveis. | Não conhecer todas as regras de todos os módulos. |
| Navegação e estado | Abrir o recorte correto e preservar a continuidade da tarefa. | A navegação não confirma pagamentos nem resolve a condição por si só. |

Começar por poucas regras explícitas com benefício claro. Um motor genérico de
regras, nova infraestrutura, telemetria ou dependência de IA não é pré-requisito.
Dados já fornecidos pelo domínio podem sustentar uma primeira apresentação;
novas agregações e garantias terão contrato e verificação próprios.

## 12. Como avaliar se a inteligência ajudou

Na revisão com o usuário, perguntar por casos concretos:

1. Ele percebeu uma informação útil sem precisar adivinhar onde procurá-la?
2. Entendeu o significado, a origem e o motivo da relevância?
3. Conseguiu investigar ou seguir um caminho apropriado com contexto preservado?
4. A informação reduziu esquecimento, interpretação errada ou trabalho repetido?
5. O destaque foi proporcional e não atrapalhou a tarefa principal?
6. Quando não havia dados suficientes, o sistema comunicou isso honestamente?
7. A pessoa continuou com controle e sentiu orientação, não pressão?

Essas são perguntas de avaliação, não resultados já demonstrados. Não há coleta
de métricas ou rastreamento implementados por este documento. Futuramente,
comparar compreensão, esforço para localizar dados, erros evitados e utilidade
percebida; quantidade de mensagens ou cliques, isoladamente, não mede cuidado.

Casos de conferência da regra: condição verdadeira/falsa, saldo parcial, dados
ausentes/antigos, mudança após uma ação, registro que sai do filtro, mesma
condição em duas telas, tema/texto ampliado e leitor de tela. Em integrações
financeiras, incluir origem e sobreposição de dados conforme contrato real.

## 13. Continuação incremental e uso pelos agentes

INT-01, INT-02 e INT-03 foram detalhadas em FE-039 nas
[regras iniciais](REGRAS_DE_INFORMACAO_UTIL_FRONTEND.md), com o contrato da seção 10.
Continuam propostas, com horizonte de três dias confirmado em FE-040, não um pacote
aprovado para implementar. Antes da próxima apresentação agrupada, selecionar o
conjunto necessário à pergunta da revisão e preservar os limites de integração.
Conectar a informação ao percurso que já estamos preparando, em vez de gerar
uma prévia separada para cada insight ou acrescentar um painel cheio de avisos.

Agentes devem ler este documento ao decidir conteúdo, resumos, informações
contextuais e orientação ao usuário. Usar a intenção confirmada para avaliar
as alternativas, manter novos exemplos como propostas e registrar os motivos
de inclusão, alteração ou descarte de cada regra.

Manter este arquivo como referência detalhada; manual, instruções de entrada e
memória apontam para ele. Pesquisas futuras devem ampliar a fundamentação e os
exemplos quando necessário, preservando limites e revisões. Não trocar o corpo
do conhecimento por uma frase curta durante compactação ou reorganização.

**Rastreabilidade, FE-038:** cada aprendizado pesquisado mantém link direto e
clicável da fonte original junto da explicação, com título/autor ou organização,
data e seção/página relevante quando útil. O link deve permitir aprofundar o
assunto, não apenas chegar à página inicial do site. Ao mover conteúdo, conservar
essas referências. Síntese interna, conclusão do agente e acesso incompleto à
fonte continuam identificados como tais.

Nesta rodada foram feitas pesquisa, inspeção de código e documentação.
Não houve nova prévia, testes de navegador, execução das suítes, alteração de
dados ou implementação no aplicativo. Referências locais e coerência dos
registros foram conferidas; validação do produto continua por etapas.

## 14. Home essencial e organização por tarefa — FE-049

Retorno direto do usuário em **16/10/2026**: a home deve mostrar o que interessa
à rotina de cestas sem exigir procurar funções ou percorrer uma página longa.
Ele identificou como essenciais a pagar, a receber, vendas/cestas e estoque;
quer perceber vencimentos de hoje e atrasos. Considerou a organização integrada
simples, óbvia e agradável e escolheu a Leitura recuperada. Não ampliar a home
com novos indicadores apenas porque o dado existe.

**Aplicação acolhida como direção:** resumo curto com Dia/Semana/Mês, acesso aos
registros e explicação/investigação nas respectivas áreas. O período muda os
resumos de vencimentos e de operações. A atenção a hoje/atrasos e o estoque
continuam atuais; selecionar o mês não deve esconder uma necessidade de hoje.
Sem consulta válida, “sem atrasadas” não é conclusão disponível. A dívida em
aberto no intervalo de vencimento continua diferente de dinheiro movimentado.

O usuário escolheu **Negócio** para vendas/clientes/resultado e pediu mover o
resultado do Financeiro para essa área. A divisão é pela tarefa: localizar e
registrar vendas, acompanhar resultado e clientes; ou acompanhar títulos e
registrar pagamentos/recebimentos. Os dados e as regras continuam integrados.
Não duplicar o domínio financeiro porque a representação mudou de lugar.

**Home em uma tela é um objetivo de composição nas condições usuais**, com
ênfase e quantidade de conteúdo proporcionais. Menor altura, texto maior ou
nome/valor extenso continuam acessíveis por rolagem quando necessário. Não
ocultar um problema real, diminuir a fonte ou cortar conteúdo para simular
encaixe universal. A sensação de cuidado depende de informação legível e fiel.

A [prévia FE-049](referencias_frontend/rodada-organizacao-2026-10-16/README.md)
aplica esse recorte com dados fictícios, fontes/evidências e limites. Este
complemento deriva do retorno do usuário e da fundamentação preservada nas
seções anteriores; não é nova pesquisa externa ou entrega Flutter/API.
