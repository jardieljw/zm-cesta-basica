# Catálogo mínimo de componentes do front-end

**Implementação vigente FE-054 — 17/10/2026:** [Pagar e Receber](PILOTO_RECEBER_REVISADO.md)
usam `ReviewedPaymentView` com adaptadores tipados e um motor comum de recuperação.
Métodos, metadados e contratos de domínio permanecem separados; JSON/chaves de
Pagar conservados. `FinancialJourneyTheme` e `FinancialSurface` são locais a
essas jornadas e à lista/origem de Receber. A extração reutiliza os dois casos
concretos; não transforma todos os formulários ou módulos em uma jornada universal.

**Implementação incremental FE-053:** o [piloto real de Pagar](PILOTO_PAGAR_REVISADO.md)
usa `AnimatedReveal` e adiciona `FinancialSurface`, `BusinessDates` e `MoneyInput`;
o coordenador financeiro concentra identidade/persistência/retomada. Não implica
que todo o catálogo ou o tema global esteja implementado. Não criar um formulário
universal com exceções de módulos apenas para generalizar este primeiro recorte.

Revisão: **16/10/2026**. Versão: **0.2 — direção e apresentação aceitas como referência**.
Autorização: FE-025, continuidade do planejamento após a aceitação das jornadas
Pagar e Receber. Este catálogo especifica apresentação e interação; os novos
componentes ainda não foram implementados no Flutter por este trabalho.

**Retorno do usuário (FE-026):** “Tá ótimo”, destacando elegância, aparência
agradável e arquitetura inteligente. O catálogo inicial fica aceito como
referência para continuar o planejamento. Esse retorno geral não formaliza cada
medida, estado adicional ou contrato técnico proposto abaixo.

Referências: [manual](ARQUITETURA_FRONTEND.md),
[memória e decisões](MEMORIA_E_PESQUISAS_FRONTEND.md),
[movimento](PADROES_DE_MOVIMENTO_FRONTEND.md) e
[amostra preservada](referencias_frontend/rodada-catalogo-2026-10-16/README.md).

## 1. O que esta rodada decide

Transformar as jornadas apreciadas pelo usuário em padrões que outras páginas
possam reutilizar: aparência, dados recebidos, estados, resposta à interação e
limites de responsabilidade. Uma coleção de imagens, sozinha, não explica como
o mesmo campo deve funcionar durante validação, envio e falha.

A amostra separa três famílias, cada uma com exemplos independentes:

| Entrada | O que experimentar | Alcance |
| --- | --- | --- |
| Campos e escolhas | Integral/Parcial, valor, data, forma, observação e revisão. No painel de design, alternar Recebimento/Pagamento. | Reaproveita decisões já confirmadas; a apresentação do catálogo foi aceita como referência em FE-026. |
| Ações e respostas | Confirmar e observar o processamento. No painel, comparar sucesso, recusa antes da gravação e perda de resposta. | Resultado desconhecido e sua verificação são propostas de apresentação, com recuperação inteiramente simulada. |
| Resumo e lista | Abrir o total, consultar os registros e a origem. Comparar consulta normal, vazia, indisponível, em andamento e anterior. | Estados adicionais e composição ainda em avaliação; não pressupõem cache ou API novos. |

O painel de design e a navegação entre exemplos pertencem à apresentação do
projeto. Não são telas de configuração ou menus novos do aplicativo. Os três
exemplos não compartilham registros: concluir a simulação de recebimento não
altera os dados das outras amostras.

## 2. Responsabilidades: quem escolhe e quem apresenta

As [composições de página e regras de continuidade](COMPOSICAO_DAS_PAGINAS_FRONTEND.md),
FE-034, propõem como reunir esses componentes numa jornada conectada.
Não alteram os exemplos históricos nem tornam as novas disposições aprovadas.

| Camada | Responsabilidade proposta | Limite |
| --- | --- | --- |
| Tema e política de movimento | Cores semânticas, formas, medidas, tipografia e preferência de redução. | Não decide situação de contas ou permissões. |
| Componente de apresentação | Receber valor/estado/rótulos e comunicar uma interação. | Não consulta servidor, grava pagamentos ou inventa saldo. |
| Composição da jornada | Organizar campos, revisão, mensagens e navegação. | Não se tornar um formulário universal com regras de todos os módulos. |
| Estado/controlador do módulo | Rascunho, validação, filtros, comando em andamento e atualização após resposta. | Usa os serviços e contratos existentes, sem acesso direto ao banco. |
| Serviço/domínio | Contrato de requisição, identidade da tentativa, permissões, cálculo e confirmação autoritativa. | Não depender de cor, texto ou duração de animação para garantir integridade. |

O módulo fornece opções válidas e significados. O componente compartilha o
desenho e a interação. Exemplo já conferido no código: Receber usa
`CASH/PIX/CARD/OTHER`; Pagar usa outros códigos, como `DINHEIRO`, `BOLETO`,
`TRANSFERENCIA`, `CHEQUE` e `CARTAO_CREDITO`. Um seletor compartilhado deve receber
as opções do módulo, sem converter esses contratos silenciosamente.

## 3. Contratos dos componentes candidatos

Os IDs abaixo são referências documentais. Não congelam nomes de classes,
assinaturas Dart, bibliotecas ou nova estrutura de diretórios.

| ID e padrão | Recebe da jornada | Comportamento e estados mínimos | Não assume |
| --- | --- | --- | --- |
| CMP-01 — Campo monetário | Rascunho textual, moeda, erro, descrição e limites fornecidos pelo módulo. | Digitação local em pt-BR, vazio distinto de zero, foco, preenchido, inválido e desabilitado. Comunica edição; conversão validada para centavos. | Precisão de custo de estoque, câmbio ou fórmula de saldo. |
| CMP-02 — Campo de data | Data civil selecionada, rótulo, erro e restrições aplicáveis. | Texto integral dentro do controle; abrir, selecionar, cancelar e devolver foco. Teclado e alternativa reduzida. | Horário de um pagamento, fuso ou precisão que não foram fornecidos. |
| CMP-03 — Escolha exclusiva com revelação | Opções, seleção, descrição e conteúdo dependente. | Integral/Parcial com seleção única; campo parcial surge suavemente. Oculto sai da interação e leitura assistiva. | Que todo formulário deve ter essas duas opções. |
| CMP-04 — Seletor de opções | Chaves e rótulos do módulo, seleção, vazio, erro, habilitação. | Sem escolha arbitrária quando a pessoa precisa informar a forma efetiva; seleções legíveis e acessíveis. | Enum único para Pagar, Receber e futuros bancos. Busca de listas grandes terá estudo próprio. |
| CMP-05 — Texto complementar | Rascunho, rótulo, indicação de opcional e limite do domínio. | Campo multilinha arredondado, texto preservado em erro; cresce sem cortar o conteúdo. | Que observação é obrigatória ou tem limite global de 300 caracteres. Esse limite é só da amostra. |
| CMP-06 — Ação principal/secundária | Rótulo contextual, ação, habilitação e estado de processamento. | Uma ação principal por etapa, resposta imediata, mensagem de andamento; bloqueio de acionamento repetido enquanto ocupado. | Garantia de idempotência, confirmação financeira ou prazo de rede. |
| CMP-07 — Mensagem de estado | Tipo, texto, ação de recuperação e contexto fornecidos pelo módulo. | Distingue erro de campo, recusa conhecida, confirmação pendente e conclusão; texto e ação além da cor. | Que toda falha autoriza reenviar ou que aviso deve desaparecer em poucos segundos. |
| CMP-08 — Resumo financeiro | Valor confirmado, moeda, período, cobertura, atualização e destino. | Total legível e acesso ao mesmo recorte; dados ausentes/antigos/incompletos distinguíveis de zero. | Que soma da página é o total global ou que “a receber” é saldo bancário. |
| CMP-09 — Registro em lista/tabela | Identidade, origem, valor, situação, vencimento e ação. | Lista no celular e tabela quando couber, com os mesmos registros e significados. Parcial e vencida podem coexistir. | Que vencida substitui a situação financeira ou que precisa diminuir texto para caber. |
| CMP-10 — Revisão e conclusão | Resumo do comando e, depois, resultado confirmado. | Revisão permite conferir; conclusão apresenta saldo/histórico efetivos e referência. Dados mantidos quando a tentativa não conclui. | Que previsão apresentada na revisão já foi gravada. |

### Integral e parcial: regra de composição confirmada

Pagar e Receber iniciam no **saldo atual integral**, por escolhas próprias do
usuário para as duas rotinas. O campo de valor aparece somente ao escolher
Parcial. Um valor parcial mantido no rascunho não pode influenciar validação,
revisão, cálculo ou comando quando Integral estiver selecionado.

Na amostra de campos, Ana tem venda original de R$ 150,00, recebimento anterior
de R$ 50,00 e saldo atual de R$ 100,00. Parcial de R$ 40,00 deixa R$ 60,00;
integral continua sendo R$ 100,00 enquanto o exemplo estiver apenas na revisão.
Pagar usa uma conta independente de R$ 680,00. Esses valores são fictícios.

### Data: preservar o aprendizado do iPhone

A moldura alinhada não basta: os caracteres também precisam caber, inclusive
com texto ampliado. A amostra usa texto comum num botão e calendário em diálogo,
mantendo a abordagem aceita após as fotos do usuário. Não reutilizar a tentativa
anterior de apenas limitar a largura de um `input type=date` como correção final.

No Flutter, escolher/reutilizar o seletor considerando a plataforma. A geometria
HTML e o calendário demonstrado não entregam um widget nativo iOS nem encerram
o contrato de data/hora do registro financeiro. A amostra conserva uma data
civil ISO; não inventar meia-noite como horário real antes de definir esse contrato.

## 4. Estados que precisam ser separados

**Consolidação FE-050:** o [contrato das jornadas financeiras](JORNADAS_FINANCEIRAS_E_PRONTIDAO_DO_PILOTO.md)
detalha a aplicação destes estados ao código atual, inclusive tentativa incerta,
confirmação recebida com atualização falha e saldo alterado. O botão demonstrativo
“Verificar registro” não prova um endpoint de consulta: retomar o POST existente
pode concluir a intenção original. Ver o contrato antes de ligar o componente à API.

**Situação do registro:** em aberto, parcial, quitada; vencida é uma condição
relacionada ao vencimento e pode coexistir com parcial/em aberto. A lista da
amostra usa Ana parcial/vencida para mostrar essa combinação. Seu vencimento
fictício nesta entrada é 15/10; não altera a amostra aceita de Receber, que tinha 17/10.

**Disponibilidade da consulta:** não consultado, carregando sem dados, consultado
com dados, consultado sem resultados, atualizando com dados anteriores, falhou
sem dados, falhou conservando consulta anterior. Cobertura incompleta é outra
informação: uma soma parcial não passa a completa porque o carregamento terminou.

**Estado do comando:** rascunho, validação, revisão, envio, conclusão confirmada,
recusa conhecida antes de gravar ou resultado desconhecido, seguido de verificação.
Essas dimensões não cabem num único `isLoading`/`hasError` global.

| Ocorrência | Apresentação proposta | Ação coerente |
| --- | --- | --- |
| Campo inválido | Mensagem junto ao campo e resumo vinculado quando houver vários erros. | Levar ao campo, corrigir sem perder o restante. |
| Consulta sem contas no período | Informar o período e que a consulta terminou. | Ampliar o recorte ou alterar filtros. |
| Servidor indisponível sem dados | Informar que o total não pôde ser confirmado; não exibir R$ 0,00. | Consultar novamente. |
| Falha ao atualizar, com informação anterior disponível | Mostrar quando foi consultado e qual valor é anterior. | Atualizar; não promover o valor antigo a saldo atual confirmado. |
| Envio em andamento | Rótulo “Registrando…” com estado acessível; ação ocupada. | Aguardar resposta; prevenir novo toque. |
| Recusa comprovada antes de gravar | Explicar que não foi registrado e preservar a revisão. | Corrigir ou repetir quando o contrato permitir. |
| Conexão cai após envio | “Aguardando confirmação”; valor pretendido separado de saldo efetivo. | Verificar a mesma tentativa; sem segundo botão de confirmar às cegas. |
| Confirmação recebida | Resultado e referência, com saldo/histórico atualizados a partir da resposta. | Continuar a consulta ou voltar ao contexto anterior. |

Na consulta normal, Ana R$ 100,00 + Bruno R$ 200,00 correspondem aos R$ 300,00
do resumo da semana de 12–18/10. No cenário vazio, não há saldos nessa semana:
“Ver todos os vencimentos” encontra outra conta, Carla R$ 80,00 em 21/10, com
período e critérios atualizados. Consulta anterior exibe R$ 300,00 identificados
como valor das 09:41; não comprova armazenamento de cache no aplicativo.

### Resultado desconhecido: apresentação proposta, contrato ainda pendente

A amostra permite simular perda da resposta, sem sucesso ou fracasso presumidos.
“Verificar registro” encontra uma confirmação fictícia; não realiza requisição.
No cliente real, uma desconexão não comprova recusa antes da gravação.

Antes de implementar esse percurso, revalidar os endpoints de Pagar/Receber e
definir: identidade estável da tentativa, persistência necessária ao retomar,
consulta/recuperação da confirmação, validade do comando se o saldo mudou,
condições para repetir e atualização coordenada de detalhe/lista/resumo. A
idempotência existente não deve ser tratada como prova automática de recuperação
completa após reiniciar. A [pesquisa empresarial](PESQUISA_FRONTEND_EMPRESARIAL_2026-10-16.md)
registra as fontes sobre essa distinção; não copiar contratos de terceiros.

## 5. Aparência e movimento: referências propostas

| Papel | Referência desta rodada | Situação |
| --- | --- | --- |
| Formas | A amostra preservada usa painéis 32, campos 28 e escolhas/ações de linha única em cápsula. | Escolha posterior FE-030: painéis 32 e campos 24 na base planejada; ver [base visual](BASE_VISUAL_FRONTEND.md). A cópia histórica não foi alterada. |
| Espaço | Campos em sequência com 22 de intervalo e painéis com 18–22 de margem interna, conforme espaço. | Medidas da amostra; harmonizar com a escala do produto antes do piloto. |
| Cor | Papéis de página, superfície, texto, descrição, linha, destaque, sucesso, alerta e erro; pares claro/escuro. | Paleta de referência; validar contraste e estados no componente real. |
| Materiais | Superfícies legíveis e opacas nas áreas de entrada/revisão. | O estudo de vidro continua preservado; não estender transparência a todo formulário automaticamente. |
| Movimento | Revelação 260 ms/180 ms; troca de contexto 220 ms/6 px; calendário 180 ms/8 px. | Propostas já demonstradas; ver documento canônico de movimento, interrupção e redução. |
| Toque e texto | Controles principais com altura mínima de referência 44, campos normalmente maiores; quebra de texto quando necessária. | Medidas da prévia web; respeitar recomendações e unidades da plataforma na integração. |

Os nomes conceituais de tokens devem expressar função, por exemplo
`surface.page`, `text.secondary`, `feedback.warning`, `shape.field` e
`motion.reveal`. A forma final de expô-los no Flutter continua por escolher.
Não copiar valores isolados da amostra para cada página.

O [padrão de movimento](PADROES_DE_MOVIMENTO_FRONTEND.md) conserva a pesquisa e
a diferença de sinais Android/iOS. Redução mantém dados, foco e mensagens,
sem giro ou deslocamento opcionais. Valores financeiros confirmados são lidos
diretamente, sem contagem animada. Não usar animação como relógio de confirmação.

## 6. Base existente a aproveitar antes de criar outra

Leitura em 16/10/2026, sem alterar estes arquivos:

| Base local | Relação com o catálogo | Avaliação antes do piloto |
| --- | --- | --- |
| [AppFormatters](../client/lib/utils/formatters.dart) | Moeda, data e unidades. | Reutilizar; separar formatação de rascunho da validação de domínio. |
| [ApiErrorMapper](../client/lib/utils/api_error_mapper.dart) | Mensagens amigáveis para códigos da API. | Reutilizar e verificar códigos dos endpoints da jornada. |
| [FinancialSummaryPanel](../client/lib/widgets/shared/financial_summary_panel.dart) | Já recebe métricas calculadas, sem decidir regras financeiras. | Evoluir apenas após mapear consumidores; não representa hoje todos os estados/ações propostos para CMP-08. |
| [AnimatedReveal](../client/lib/widgets/shared/animated_reveal.dart) e [AnimatedContentSize](../client/lib/widgets/shared/animated_content_size.dart) | Revelação e mudança de altura. | Aproveitar base, harmonizar política/tempos e cobertura de redução por plataforma. |
| [ResponsiveFilterBar](../client/lib/widgets/shared/responsive_filter_bar.dart) | Contexto de filtros adaptativo. | Avaliar quando o recorte de filtros for fechado; não reescrever agora. |
| [Pagar](../client/lib/views/payables_view.dart) e [traduções](../client/lib/l10n/app_pt.arb) | Exemplo de opções específicas e textos centralizados. | Conservar contratos e obter todos os textos por l10n na implementação. |

Essa inspeção não é auditoria completa dos consumidores. Não houve mudança em
`client/lib`, dependências, endpoints, banco, segurança ou distribuição do app.

## 7. Pesquisa desta rodada e aplicação

Fontes primárias consultadas em **16/10/2026**:

- [Storybook — Writing stories](https://storybook.js.org/docs/writing-stories):
  apresenta cada história como um estado renderizado de um componente, definido
  por suas entradas. **Aplicação proposta ao ZM:** registrar exemplos com
  contexto, dados e estado reproduzíveis, junto ao contrato de apresentação.
  **Limite:** referência de método; não escolhe React, instala Storybook ou muda
  a tecnologia Flutter do aplicativo.
- [W3C WAI — User notifications](https://www.w3.org/WAI/tutorials/forms/notifications/):
  orienta mensagens claras de sucesso/erro, instrução de correção, relação com
  campos e foco apropriado após validação. **Aplicação proposta:** erros locais
  associados, resumo acionável e confirmação persistente na conclusão.
  **Limite:** atributos HTML verificam a amostra web; semântica e leitura
  assistiva precisam ser implementadas e verificadas também no Flutter.
- A [pesquisa empresarial anterior](PESQUISA_FRONTEND_EMPRESARIAL_2026-10-16.md)
  fundamenta resumo/lista/origem e distinção de resultados financeiros. O
  [documento de movimento](PADROES_DE_MOVIMENTO_FRONTEND.md) centraliza as fontes
  Apple/Flutter. Não converter essas referências em promessa de funcionalidades
  de backend ou certificação bancária/fiscal.

**Aprendizado de engenharia desta rodada:** é mais útil especificar o que um
componente recebe, comunica e não decide, acompanhado de estados verificáveis,
do que montar apenas uma vitrine de formas. Isso é uma aplicação ao projeto,
não uma regra textual atribuída às fontes.

## 8. Evidência e próximo passo

A [pasta da rodada](referencias_frontend/rodada-catalogo-2026-10-16/README.md)
conserva fonte, contêiner, verificação e capturas com manifesto próprio.
Verificação final: oito grupos por motor Edge/WebKit, 96 combinações de layout
e nenhum erro JavaScript observado; 23 cópias preservadas. Inclui texto ampliado
simulado, calendário, validação, coerência financeira, redução e restauração
instrumentada dos ajustes.
Os testes são da apresentação local: não comprovam integração com API, cache,
recuperação de rede, acessibilidade nativa ou funcionamento do app no iPhone.
Datas, cores, opacidades e animações devem passar por conferência no componente
Flutter e em aparelho real antes de virarem padrão de entrega.

Após o retorno positivo FE-026, o próximo recorte proposto é alinhar um primeiro
conjunto de papéis visuais: superfícies/texto, formas/espaço e estados de controles.
Esse recorte foi autorizado em FE-027 e está demonstrado na
[base visual](BASE_VISUAL_FRONTEND.md), com valores ainda propostos e ajustes
compartilhados. A fonte preservada deste catálogo continua sendo a rodada aceita.
Após avaliar a base visual, alinhar hierarquia tipográfica; depois escolher a
jornada do piloto e revalidar seus contratos técnicos. A
implementação real exige seu alinhamento próprio. Não avançar automaticamente
para importação bancária, estorno, vários recebíveis ou migração global.
