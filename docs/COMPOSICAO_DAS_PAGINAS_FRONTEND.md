# Composição das páginas e continuidade da jornada

Revisão: **16/10/2026**. Versão **0.1 — proposta para revisão conjunta**, FE-034.
O usuário autorizou continuar o planejamento com pesquisa e prudência e gostou
do critério de revisar um conjunto coerente de mudanças. Isso não aprova
antecipadamente os arranjos novos deste documento nem a implementação.
Rodada documental: nenhuma nova prévia, navegador ou mudança Flutter/API.

Referências: [manual](ARQUITETURA_FRONTEND.md),
[hierarquia e tipografia](HIERARQUIA_E_TIPOGRAFIA_FRONTEND.md),
[catálogo de componentes](CATALOGO_COMPONENTES_FRONTEND.md),
[plano](PLANO_ARQUITETURA_DE_DESIGN.md) e
[memória](MEMORIA_E_PESQUISAS_FRONTEND.md).
As rotinas atuais continuam nos guias de [Pagar](CONTAS_A_PAGAR.md) e
[Receber](CONTAS_A_RECEBER.md).

## 1. Caminho recomendado para a próxima revisão

**Lista → detalhe → registro → revisão → resultado → retorno ao contexto.**
O usuário precisa reconhecer onde está, conferir os valores e continuar sua
tarefa sem refazer filtros ou preencher tudo novamente. Usar as mesmas bases
confirmadas: espaço 20, campos 24, painéis 32, destaque configurável com azul
original por padrão. Fundo e tipografia permanecem propostas.

Detalhe em página própria é a recomendação inicial para celular e Windows.
A lista pode virar tabela quando largura, conteúdo e escala de texto permitirem.
Isso conserva a jornada sem obrigar a mesma disposição em todas as larguras.

| Alternativa considerada | Avaliação para esta rodada |
| --- | --- |
| Detalhe em página própria | Recomendado: oferece espaço para identidade, origem, histórico e ação; mantém retorno reconhecível. |
| Histórico e formulário dentro da linha expandida | Não recomendado como composição principal: o conteúdo financeiro compete com a comparação da lista. Expansão curta pode ser avaliada para informação complementar. |
| Lista e detalhe simultâneos em duas áreas no Windows | Possível evolução; avaliar benefício na rotina, largura, foco e estado antes de introduzir outra composição. Não é requisito do primeiro piloto. |

São escolhas propostas do ZM, não conclusões de testes com usuários.

## 2. Lista: localizar sem perder o significado

Ordem de blocos proposta, dentro da navegação já alinhada:

| Bloco | Conteúdo | Regra de composição |
| --- | --- | --- |
| Identificação | Nome da área e finalidade da lista. | Pagar/Receber mantêm contexto reconhecível; não misturar os registros silenciosamente. |
| Resumo | Valor e contagem pertinentes ao recorte, quando fornecidos. | Nomear período/cobertura. Abrir um resumo leva à lista com os mesmos critérios. |
| Filtros | Critérios aplicados e painel alinhado à página para edição. | Ao recolher o painel, conservar um resumo compreensível do filtro aplicado. Rascunho de edição não pode parecer consulta já aplicada. |
| Resultados | Identificação, saldo em aberto, vencimento e situação. | Uma unidade de leitura por registro; nomes e valores legíveis, sem empilhar painéis decorativos para cada atributo. |
| Continuidade | Paginação ou carregamento adicional, conforme contrato disponível. | Informar a cobertura real. Contagem retornada e soma parcial não são total global. |

No celular, propor duas linhas principais por registro: identificação e valor;
depois vencimento/situação. Isso é uma intenção de agrupamento, não altura fixa
ou limite de linhas. Com texto ampliado ou nome longo, os blocos podem empilhar.
Em tabela, manter colunas nomeadas e quantias comparáveis, com a mesma informação
essencial. A identificação completa precisa ser acessível sem depender de hover.

Abrir um detalhe e executar uma ação sobre um registro têm alvos distintos e
rótulos claros, sem controles interativos aninhados. A primeira revisão pode
concentrar as ações financeiras no detalhe para evitar acionamento durante a
busca. Não acrescentar seleção em lote, gesto de quitar ou transferência bancária.
A ação de página conserva FAB e espaço final de rolagem conforme a
[preferência já registrada](LAYOUT_E_ACOES_DE_PAGINA.md).

O painel detalhado mantém a proposta Aplicar/Limpar/Atualizar do plano: o piloto
deverá alinhar a diferença em relação ao comportamento atual de cada módulo.
Não mudar filtros rápidos ou ordenação apenas por causa do novo desenho.

## 3. Detalhe: identidade, saldo e explicação

1. **Retorno e identidade:** pessoa/descrição e referência de conta ou venda.
2. **Situação atual:** saldo em aberto, vencimento e situação legível.
3. **Composição do saldo:** valor original e pagamentos/recebimentos anteriores,
   distinguindo valores efetivos e registros estornados conforme o domínio.
4. **Origem e histórico:** acesso ao documento ou registro que originou o título,
   quando houver vínculo; movimentações com valor, data e situação disponíveis.
5. **Ação contextual:** registrar pagamento/recebimento quando o domínio permitir.
   Cancelar ou estornar conserva finalidade, motivo e validação próprios.

Evitar repetir o saldo principal em vários painéis. Conteúdo complementar pode
ser recolhível, mas a compreensão do saldo, um aviso necessário ou a identificação
do registro não depende de abrir um acordeão. Histórico deve continuar consultável
sem transformar uma lista em outra lista de formulários embutidos.

No Windows, usar largura de leitura adequada e alinhar grupos relacionados;
não espalhar os campos até as bordas apenas porque há espaço. Com largura menor
ou texto maior, retornar à composição em coluna, sem uma versão com menos dados.

## 4. Registro e revisão: continuidade do preenchimento

| Etapa | Conteúdo proposto | Comportamento a preservar |
| --- | --- | --- |
| Contexto | Pessoa/conta e saldo atual relevante. | Registro de algo já pago/recebido; sem linguagem que sugira envio de dinheiro. |
| Tipo | Integral selecionado; Parcial como alternativa. | Integral usa o saldo atual. Campo parcial aparece só nessa opção; oculto não participa da validação ou comando. |
| Dados | Data, forma efetiva e observação opcional. | Sem forma preselecionada; opções vêm do módulo. Calendário conserva escolha ao cancelar e devolve foco. |
| Conferência | Valor deste registro, data, forma, pessoa e saldo esperado. | Previsão ainda não é resultado. Valor original e saldo atual não substituem o valor da operação. |
| Correção | Voltar para editar os dados. | Preservar preenchimento; validar campos dependentes e voltar à revisão, sem repetir toda a navegação. |
| Envio e resultado | Andamento e resposta conhecida ou ainda desconhecida. | Impedir acionamento repetido enquanto ocupado. Identidade da tentativa e confirmação dependem dos serviços. |

Campo com erro mantém valor e mensagem associada; a navegação de correção deve
chegar ao campo correspondente. Observação pode ficar sem resposta e a revisão
deve representá-la de modo claro, sem parecer um dado carregando.

Manter rascunho entre formulário e revisão durante a jornada é a proposta.
Não copiar o rascunho para outro registro. Persistência após fechar/reiniciar o
app e política para sair com mudanças não salvas continuam por definir antes
do piloto; esta composição não adiciona salvamento automático ou modal global.

## 5. Voltar deve preservar o trabalho, sem fingir que os dados não mudaram

| Transição | Continuidade proposta |
| --- | --- |
| Lista → detalhe → lista | Preservar filtros aplicados, ordenação, referência da posição e acesso ao registro de origem. Em teclado, devolver foco a um alvo coerente. |
| Formulário → revisão → editar | Conservar rascunho, seleção e contexto do mesmo registro. |
| Resultado confirmado → detalhe/lista | Atualizar os dados correspondentes e manter o recorte. Se a conta quitada sair de um filtro de abertas, explicar essa consequência e retornar perto da posição anterior quando possível. |
| Registro confirmado, atualização da lista falhou | Distinguir o registro confirmado da consulta não atualizada. Oferecer atualizar a consulta; não sugerir registrar o pagamento outra vez. |
| Outro usuário/processo alterou o saldo | Antes do piloto, alinhar verificação com o domínio. Proposta: apresentar o novo saldo e exigir nova conferência quando afetar a operação; não converter silenciosamente um valor já revisado. |
| Mudou largura, tema ou preferência visual | Preservar identidade, rascunho e etapa. Reorganizar apresentação não cria nem confirma uma operação. |

Posição e foco são referências, não promessa de um índice imutável: registros
podem mudar ou sair do recorte. Identificar itens por sua identidade de domínio,
e não pela posição. Retorno coerente não significa manter um valor antigo como atual.
Reabertura após encerrar o aplicativo exige contrato próprio de persistência.

## 6. Estados: o mesmo espaço, mensagens com consequências diferentes

O [contrato consolidado FE-050](JORNADAS_FINANCEIRAS_E_PRONTIDAO_DO_PILOTO.md)
aplica esta composição às jornadas financeiras e distingue demonstração,
capacidades atuais e contratos pendentes. Preservar confirmação já recebida
mesmo se falhar a consulta seguinte; retomar tentativa incerta conserva seu comando.

As dimensões de consulta, situação financeira e comando continuam separadas,
conforme o catálogo. Esta proposta especifica sua composição:

- **Consultando sem dados:** indicar consulta em andamento na área de resultados;
  resumo não exibe zero fictício.
- **Consulta vazia:** explicar se o recorte não tem resultados; oferecer ajuste
  de filtros. Ausência de cadastro inicial é outra situação.
- **Falha na consulta:** mensagem e ação de consultar novamente na própria área.
  Dados anteriores só podem aparecer como anteriores se realmente disponíveis.
- **Falha de validação ou recusa conhecida:** conservar os campos para correção.
- **Resposta do registro desconhecida:** manter contexto e apresentar verificação
  antes de oferecer repetição; não usar o mesmo botão de repetir uma consulta.
- **Registro confirmado:** comunicar confirmação e efeito efetivo. A atualização
  de outras áreas pode ter situação própria, sem revogar visualmente o sucesso.

Esses estados não comprovam cache, recuperação ou suporte de API. Antes do
piloto, mapear contratos reais e limites do comando, da consulta e da concorrência.

## 7. Pesquisa primária e decisões derivadas

Consultas em **16/10/2026**:

| Fonte | Aprendizado | Aplicação proposta e limite |
| --- | --- | --- |
| [Carbon — Data table](https://www.carbondesignsystem.com/building-blocks/core/components/data-table/guidelines) | Expansão serve a conteúdo complementar; conteúdo apertado pode precisar de um destino dedicado. | Detalhe financeiro em página própria na primeira revisão. Não adotar tabelas expansíveis, alturas Carbon ou sua barra de ações como padrão automático. |
| [GOV.UK — Check answers](https://design-system.service.gov.uk/patterns/check-answers/) | Revisão oferece correção com dados preenchidos e retorno à conferência, incluindo novas perguntas dependentes quando necessário. | Conservar rascunho ao editar, revalidar e voltar à revisão. Não acrescentar revisões a todas as ações nem copiar o formulário governamental. |
| [SAP Fiori iOS — List Report](https://www.sap.com/design-system/fiori-design-ios/v26-1/page-types/list-report) | Distingue ações da lista e do item, contexto de filtros e composição adaptativa. | Preservar critérios e separar localizar um registro de agir sobre ele. Não copiar gestos, contadores ou controles que dependam de dados/rotinas ausentes no ZM. |

Páginas lidas como documentação, sem executar seus exemplos. A ordem dos blocos,
a recomendação de detalhe dedicado e as regras de retorno acima são inferências
de projeto a avaliar. Não são padrões prescritos pelas fontes nem novos contratos
de backend aprovados. Continuidade após confirmar e concorrência exigem validação
nos serviços atuais; documentação não implementa essas garantias.

## 8. Conjunto preparado para a próxima revisão visual

**Continuação FE-052:** o [acabamento integrado](referencias_frontend/rodada-acabamento-2026-10-16/README.md)
aplica a direção apreciada na captura inicial sobre FE-049. Filtros compactos,
fechados por padrão; lista com linguagem de extrato e recorte sempre identificável.
Nenhuma mudança na Leitura recuperada, destinos ou composição essencial da home.
Usuário pediu agrupar e adiantar o trabalho; não voltar a uma prévia por detalhe.

**Decisão FE-049:** Leitura recuperada escolhida; terceiro destino **Negócio**,
com vendas/clientes/resultado. A [revisão atual](referencias_frontend/rodada-organizacao-2026-10-16/README.md)
conserva a base integrada e demonstra home curta com períodos e atenção atual.
Próximo trabalho é concluir jornadas/estados e contratos concretos, preservando
esta organização. FE-048 abaixo é histórico; a disputa de leitura foi resolvida.

**Continuação FE-048:** a [comparação de hierarquia integrada](referencias_frontend/rodada-tipografia-2026-10-16/README.md)
apresenta agora home, lista, detalhe, formulário e revisão com as duas leituras,
nomes longos, quantias altas e conteúdo ampliado. Parte da recuperação FE-046;
os relatos anteriores abaixo não autorizam retornar ao estudo parcial como
estrutura do app. Novas medidas/fonte seguem propostas; avaliação de leitura
precede os próximos detalhes visuais e a escolha do piloto real.

**Atualização FE-041:** o [conjunto Negócio em foco](referencias_frontend/rodada-negocio-em-foco-2026-10-16/README.md)
foi criado para apresentação a pedido do usuário. Os parágrafos e o roteiro
abaixo conservam a preparação anterior; já não significam que a apresentação
esteja adiada. O exemplo 680/200/480, integral/parcial, calendário, edição e
retorno estão navegáveis; a validação local não confirma integração no app.
Nomes extremos, quantias extremas e recuperação real continuam cuidados do
piloto, sem alegação de cobertura integral nesta prévia.

**Ampliação de intenção em FE-036:** aplicar a
[documentação específica de design inteligente](DESIGN_INTELIGENTE_E_ORIENTACAO_AO_USUARIO.md).
Antes de gerar o conjunto, especificar poucas oportunidades de informação útil,
com condição, origem, benefício, lugar e próximo passo. Conectá-las à visão geral,
módulo ou registro pertinente, sem transformar cada oportunidade em nova prévia.
O roteiro abaixo conserva sua validade e deve incluir a compreensão/utilidade
dessas informações quando forem selecionadas para avaliação.

FE-039/FE-040 preparam as [regras de vencimento, estoque e custo](REGRAS_DE_INFORMACAO_UTIL_FRONTEND.md).
A antecedência confirmada é de três dias, além de hoje/atrasadas separados.
Usar mensagens e destinos de acordo com as capacidades e lacunas documentadas;
explicação de custo não promete uma lista filtrada ou correção histórica pronta.

Proposta de apresentação agrupada: uma jornada conectada de lista, detalhe,
registro e revisão, com as medidas confirmadas e a tipografia proposta; reunir
fundo e entrada do calendário já estudada. Priorizar celular e conferir a adaptação
Windows, sem acrescentar funções bancárias ou importar documentos reais.

Casos para a futura revisão: nome longo, quantia grande, texto ampliado, integral/
parcial, edição da revisão, retorno ao filtro e erro sem perda do rascunho.
Separar casos demonstrados de integrações reais não executadas. O cenário de
saldo alterado/resultado desconhecido deve ser identificado como simulado se
ainda não houver contrato integrado.

O plano desta composição está preparado para revisão. Não houve geração de
prévia nesta rodada: a próxima apresentação deve ocorrer como um conjunto,
conforme FE-032 e o critério acolhido em FE-034. Ela deve responder: é fácil
reconhecer o registro, entender a situação e encontrar a próxima ação?

Checagem desta entrega: links locais e continuidade documental; sem suítes do
aplicativo ou testes visuais, pois houve somente edição de documentos.

### 8.1 — Roteiro da próxima revisão agrupada, FE-035

Preparação documental, ainda sem gerar ou executar a prévia. Recomenda-se usar
uma jornada de **Pagar** com o mesmo exemplo fictício da hierarquia (original
R$ 680,00, pagos R$ 200,00, saldo R$ 480,00). Reutilizar um exemplo reduz dúvidas
entre telas. Isso não escolhe Pagar como primeiro piloto de implementação;
Receber conserva suas regras e sua avaliação própria.

| Tarefa de revisão | O que precisamos observar | Situação atual |
| --- | --- | --- |
| Localizar a conta na lista e abrir seu detalhe | Identificação, saldo, vencimento e filtro reconhecíveis. | Composição proposta, ainda não demonstrada nessa jornada conjunta. |
| Entender a composição do saldo | Distinguir original 680, pagos 200 e restante 480. | Exemplo documental; verificar leitura no conjunto. |
| Registrar o saldo integral; depois experimentar Parcial | Integral começa em 480; parcial revela campo, e voltar a Integral exclui esse valor da operação. | Regra confirmada; conferir aplicação na composição nova. |
| Abrir calendário e corrigir dados pela revisão | Perceber entrada no modo padrão, abertura direta com redução e preenchimento preservado ao editar. | Novo movimento testado localmente em estudo anterior, ainda sem apresentação ao usuário. |
| Voltar à lista depois do resultado | Preservar recorte e retorno coerente; explicar saída de uma conta quitada do filtro de abertas. | Regra de apresentação proposta; sem integração real comprovada. |
| Ler nome longo, quantia grande e texto ampliado | Conteúdo e ações acessíveis no celular e no Windows, com temas legíveis. | Critérios planejados; nova composição ainda não validada visualmente. |

Registrar o retorno em três grupos: **entendido e aceito**, **ajuste necessário**
e **dúvida a investigar**. Aceitar a aparência não confirma automaticamente cada
tamanho nem o contrato de recuperação do serviço. Registrar o alcance do retorno.
Esse roteiro prepara a próxima apresentação; não exige novo formulário de
aprovação para cada linha. Campos, painéis e espaçamento já confirmados seguem
como base, sem repetir as mesmas perguntas.

### 8.2 — Continuidade do mapa navegável, FE-044

**Atualização FE-046:** a [recuperação integrada](referencias_frontend/rodada-recuperacao-integrada-2026-10-16/README.md)
incorpora esses caminhos e preserva a estrutura original, com comparação visual
da barra e testes das jornadas. Retorno do usuário ainda pendente. O diagnóstico
abaixo conserva o estado anterior; consultar o [registro atual](REFERENCIA_ATUAL_FRONTEND.json)
para identificar a candidata de continuação, sem tratar o estudo parcial como app completo.

Em 16/10/2026, o usuário destacou a mensagem que apresentava o primeiro mapa
clicável e pediu “olha isso”, após questionar a perda da homepage anterior.
Comparação das fontes locais, sem nova pesquisa externa ou geração de prévia:

- [Mapa original](referencias_frontend/mapa-navegavel-zm.html): referência de
  organização já acolhida, com cinco áreas e pontos de entrada de seus módulos.
- [Negócio em foco](referencias_frontend/rodada-negocio-em-foco-2026-10-16/negocio-em-foco-zm.html):
  estudo de informações úteis e registro financeiro, com apenas parte dos caminhos.

| Área | Referência anterior | Limite encontrado na amostra recente |
| --- | --- | --- |
| Início | Resumo financeiro, negócio hoje e atenção. | Blocos reincorporados em FE-042; novos indicadores e composição ainda em avaliação. |
| Financeiro | Pagar/receber; contas/cartões e extratos/faturas sinalizados como propostas futuras. | Jornada de registro aprofundada; pontos de entrada futuros ausentes. Isso não os retira do plano. |
| Vendas | Resumo, detalhe de venda e Clientes. | Sínteses do dia/período, sem os pontos de entrada de Clientes e detalhe completo. |
| Estoque | Produtos, Compras, Cestas e montagens e Movimentações; caminho até Cesta Básica Completa. | Lista de produtos e recorte abaixo do mínimo; os outros caminhos não estão representados. |
| Mais | Relatórios, Impressão e formulários, Configurações e conexão e Backup. | Somente preferências de aparência demonstradas. |
| Continuidade | Posição por área preservada ao alternar os destinos. | A amostra usa histórico global e abre a raiz ao trocar a área; não equivale ao comportamento anterior. |

**Conclusão de comparação do agente:** manter os nomes das cinco áreas ou
guardar a fonte antiga não basta para preservar a experiência projetada.
Os pontos de entrada e a continuidade da referência precisam permanecer na
evolução integrada. Um recorte de estudo deve ser identificado como parcial,
sem parecer substituição do aplicativo inteiro.

**Próximo trabalho de consolidação:** tomar o mapa original como estrutura e
incorporar os avanços de campos, integral/parcial, calendário, revisão e
informações úteis. Conferir os dois percursos destacados e os demais destinos
da tabela antes da próxima apresentação integrada. Isso ainda não foi realizado;
esta rodada identifica e documenta a lacuna. Números fictícios e propostas
futuras não se tornam contratos de negócio aprovados por constarem na referência.
