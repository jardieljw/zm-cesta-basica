# Memória, decisões e pesquisas do projeto de front-end

Consolidação inicial: **15/10/2026**. Atualização: **17/10/2026**. Escopo: planejamento
realizado nesta conversa, com pesquisas, prévias e incrementos de 14–17/10/2026. Este registro permite retomar o trabalho
depois de uma compactação ou em outra sessão. É uma síntese de trabalho, não uma
exportação literal de todas as conversas.

## 1. Como retomar

Cumprir primeiro a ordem de consulta de [AGENT_INSTRUCTIONS.md](../AGENT_INSTRUCTIONS.md).
Para o front-end, estes arquivos se complementam:

| Arquivo | Responsabilidade |
| --- | --- |
| [Manual de arquitetura](ARQUITETURA_FRONTEND.md) | Padrões e decisões vigentes, distinguindo propostas de implementação. |
| [Plano de design](PLANO_ARQUITETURA_DE_DESIGN.md) | Sequência de evolução e estudo inicial de filtros. |
| [Catálogo mínimo](CATALOGO_COMPONENTES_FRONTEND.md) | Contratos de componentes, estados e exemplos; distinguir proposta e código entregue. |
| [Base visual](BASE_VISUAL_FRONTEND.md) e [valores propostos](TOKENS_VISUAIS_PROPOSTOS.json) | Papéis de cor, aparência, formas e espaço em avaliação. |
| [Hierarquia e tipografia](HIERARQUIA_E_TIPOGRAFIA_FRONTEND.md) | Papéis de leitura, escala inicial proposta e critérios de adaptação. |
| [Composição e roteiro de revisão](COMPOSICAO_DAS_PAGINAS_FRONTEND.md) | Blocos de página, continuidade e perguntas concretas da próxima revisão agrupada. |
| [Jornadas financeiras e preparação do piloto](JORNADAS_FINANCEIRAS_E_PRONTIDAO_DO_PILOTO.md) | Contratos de estado e envio, confronto com código atual, lacunas e recorte proposto; não é implementação. |
| [Design inteligente e orientação ao usuário](DESIGN_INTELIGENTE_E_ORIENTACAO_AO_USUARIO.md) | Referência aprofundada da intenção, fundamentação e lógica de informações úteis/proativas. Ler o documento completo, não apenas este índice. |
| [Primeiras regras de informação útil](REGRAS_DE_INFORMACAO_UTIL_FRONTEND.md) | Especificação de vencimentos, estoque mínimo e custo incompleto, com dados, limites, destinos e casos. |
| Este registro | Contexto, motivos, pesquisas, aprendizados, evidências e pendências. |
| [Referências e prévias preservadas](referencias_frontend/README.md) | Briefing original, HTML, capturas e scripts históricos de verificação. |
| [Índice das mecânicas](README.md) | Comportamento efetivamente implementado nos módulos. |

Em caso de divergência, identificar o escopo e a data: uma proposta antiga não
substitui uma decisão posterior, e uma aprovação visual não comprova entrega de
código. Revalidar o código e os guias atuais para afirmar uma capacidade técnica.
O histórico abaixo explica as escolhas; o manual conserva sua situação vigente.

## 2. Estado para a próxima sessão

- **Conclusão Integral do Front-End FE-052 / FE-055 — 17/10/2026:**
  Execução completa das 5 fases do plano de implementação conforme [ARQUITETURA_FRONTEND.md](ARQUITETURA_FRONTEND.md) e [INTEGRACAO_INTERFACE_APROVADA.md](INTEGRACAO_INTERFACE_APROVADA.md):
  1. **Fase 1 (Componentes Base FE-052 & Preferências)**: Componentes canônicos implementados em `approved_app_style.dart` (`ApprovedChoice`, `ApprovedWarningBox`, `ApprovedTotalBox`, `ApprovedHeroCard`, `ApprovedPrimaryButton`, `ApprovedSecondaryButton`, `ApprovedCollapsibleFilter`, `ApprovedField`, `ApprovedCalendarDialog`, `ApprovedDateButton`); suporte a Material (Vidro / Sólido) e Movimento (Padrão / Reduzido) persistidos em SharedPreferences via `AppAppearanceController`.
  2. **Fase 2 (Financeiro Completo)**: `FinancialSourcesView` nativo para cadastro/gestão de contas bancárias e cartões de crédito; `PayableFormDialog` para registro de despesas operacionais; navegação integrada em `AppFinanceView`.
  3. **Fase 3 (Estoque Completo)**: Hub canônico de cestas com 3 opções (Composição da receita, Registrar montagem padrão/personalizada, Histórico de montagens); alerta de estoque em `_StockAttentionPage` com `ApprovedHeroCard` e navegação para produtos.
  4. **Fase 4 (Negócio Completo)**: `_business` com botão primário para "Registrar nova venda" conectado ao `SaleFormView`, `ApprovedWarningBox` para alerta de custo incompleto e navegação para detalhe em `_ResultPage`; `_financialAttention` com direcionamento correto para o escopo de vencidos/hoje.
  5. **Fase 5 (Qualidade e Build Release)**:
     - `flutter analyze`: **0 problemas / 0 avisos**.
     - Suíte de testes Flutter: **347/347 testes aprovados (100%)**.
     - Compilação Windows Release: executável gerado com sucesso em `client/build/windows/x64/runner/Release/zm_cesta_basica_client.exe` (código de saída 0).
  Preservação absoluta das regras de persistência (sem acesso direto ao SQLite, chamadas REST seguras via TLS), integridade monetária em centavos/microcentavos inteiros e imutabilidade dos livros-razão.

- **Retomada e entrega técnica FE-055 — 17/10/2026:** após “Termine po”, execução
  liberada e fechamento concluído: **334 testes Flutter**, **436 backend / 14
  avisos**, análise sem pendências e **Windows Release** compilado (27,9 s).
  [Evidências](validacoes_frontend/fe-055-integracao-2026-10-17/README.md) preservam
  fontes/capturas/hashes, incluindo `data/app.so`, e conferem 35/8/11 arquivos das
  rodadas FE-052/053/054. Release em `client/build/windows/x64/runner/Release/`;
  conservar a pasta completa. Sem abrir janela alternativa, publicar Sites,
  alterar dados da empresa ou substituir instalação externa. Compatibilidade
  de cores das telas operacionais foi ajustada para o tema escuro. A comparação
  equivalente de Receber ficou abaixo de um pixel nos dez blocos geométricos
  medidos; não constitui certificação de todos os pixels de todas as interfaces.
  Aceitação visual integral/dispositivos físicos permanecem separados. Os
  relatos de bloqueio abaixo são históricos e foram superados nesta retomada.

- **Fechamento FE-055 solicitado pelo usuário:** “Termine logo”. A revisão
  automática de execução falhou por limite de uso da conta antes de executar
  o último formatador. Não é rejeição por insegurança e não deve ser contornada.
  Código salvo, sem build FE-055 ou instalação atualizada. Última suíte completa
  intermediária: 436 backend / 333 Flutter; rodada financeira/tipográfica posterior:
  43 aprovados. Depois houve ajustes visuais adicionais ainda sem fechamento.
  Conferir o guia FE-055 e o registro atual, concluir medidas/telas operacionais,
  formatação/análise/suítes/build quando houver execução disponível. Não anunciar
  fidelidade completa nem usar o executável antigo como versão atualizada.

- **Exigência de fidelidade e retomada FE-055 — 17/10/2026:** usuário reforçou que
  comparará todas as interfaces, inclusive diferenças de um pixel. Usar a fonte
  FE-052 e a captura anexada como alvo; comparar tamanho/tema/escala/dados iguais.
  Não anunciar equivalência a partir de testes funcionais. O pedido de Sites
  foi revogado antes de qualquer criação/publicação; só houve consulta da lista
  de projetos. Continuar a integração local. O [guia FE-055](INTEGRACAO_INTERFACE_APROVADA.md)
  registra arquivos, contratos, aprendizados e pendências. Cinco áreas/resumos
  reais, contexto por área e preferências locais estão implementados; revisão
  de fidelidade e telas operacionais ainda em andamento. Suítes intermediárias:
  436 backend / 333 Flutter; ajustes posteriores exigem fechamento final.
  A comparação identificou Segoe UI Semibold, vetores Lucide/Feather, medidas,
  ordem/alfa dos gradientes e borda interna superior. Nenhuma dependência nova,
  migração, IA ou alteração dos dados da empresa nesta rodada.

- **Correção de direção FE-055 — 17/10/2026, integração em andamento:** o usuário
  comparou o aplicativo FE-054 com a referência e rejeitou a apresentação
  intermediária: “não preciso de ver front end diferente do que combinamos só
  para testar”; quer integrar o backend à interface já construída. A referência
  FE-052 é o alvo visual, não inspiração para outro layout. Essa instrução
  autoriza a integração da estrutura principal e das jornadas aos serviços reais;
  não repetir pilotos com outra composição nem propor nova descoberta visual.
  Preservar Leitura recuperada, navegação, títulos, tabs, recortes, resumo e linhas
  da referência. Trabalho atual em `app_shell_view.dart`, `app_finance_view.dart`,
  `app_overview_controller.dart` e componentes de mapeamento visual compartilhados.
  Os resumos usam a API existente; regras financeiras/estoque e dados preservados.
  Entrada validada: 436 backend / 319 Flutter. Validação final e fidelidade
  ainda pendentes; não tratar esse código parcial como entrega concluída.
  Retomar a integração atual, não abrir outra versão visual de teste ao usuário.

- **Ponto vigente FE-054 — 17/10/2026:** após esclarecer que o piloto não era a
  instalação nem o aplicativo completo, usuário respondeu **“Vambora uhuuu”**
  e pediu retomar o trabalho. O [Receber revisado](PILOTO_RECEBER_REVISADO.md)
  foi integrado: Integral/Parcial, dia/forma, revisão/edição, origem da venda,
  confirmação separada da consulta e tentativa persistida por origem/título.
  API aditiva conserva hash legado e replay; saldo conferido na transação e
  capacidade no detalhe. Receber preserva venda/estoque e usa CASH/PIX/CARD/OTHER.
  Lista com extrato, filtros recolhidos/recorte visível, Em aberto incluindo
  parciais e mais páginas; soma explicitamente das contas exibidas. Consultas
  congelam filtros, rejeitam respostas antigas e conservam recibos fora do filtro.
  Apresentação e recuperação comuns foram extraídas sem trocar JSON/chaves de
  Pagar. Material ganhou luzes radiais/sombra e tema financeiro local; não é
  equivalência nativa integral do HTML. [Evidência FE-054](validacoes_frontend/fe-054-receber-2026-10-17/README.md)
  registra resultados finais e capturas com fixtures. Instalação/banco da empresa
  preservados; fonte FE-052 imutável. Próximo: áreas principais/resumos reais,
  depois validação dos alvos e atualização correspondente de servidor/cliente.
  Não reapresentar uma captura isolada como se fosse o aplicativo navegável.
  Verificação final: **436 backend / 319 Flutter**, análise sem pendências e Windows debug compilado.


- **Ponto atual FE-053:** após a indicação de Pagar funcionando no aplicativo como
  próxima entrega concreta, usuário respondeu **“Show vamo embora”**. O
  [primeiro piloto real](PILOTO_PAGAR_REVISADO.md) foi implementado em Flutter/API:
  detalhe/histórico → Integral/Parcial → data/forma/observação → revisão/edição →
  confirmação/retorno. Persistência de tentativa e recibo, mesma chave/corpo na
  retomada, conexão vinculada, precondição atômica e dia civil são contratos reais.
  Capacidade `payment_review_version=1` evita servidor antigo ignorando campos.
  Hashes de requests legados preservados; sem tabelas/migrações novas. Pagar usa
  atraso por dia de negócio; Receber ainda precisa do alinhamento equivalente.
  Nova lista carrega mais de cem sem tratar a soma parcial como total global.
  Guia e [evidência](validacoes_frontend/fe-053-piloto-pagar-2026-10-16/README.md)
  distinguem código, testes, capturas de widgets e compilação de versão instalada.
  Fonte visual FE-052 intacta; navegação/tema global não foram migrados. Continuar
  por Receber com suas regras e efeitos na venda; não repetir autorização para
  ajustes rotineiros de Pagar nem voltar a nova descoberta visual.
  Verificação final: 420 backend/274 Flutter aprovados, análise sem pendências
  e Windows debug compilado. Instalação não substituída; usar servidor/cliente
  correspondentes. Capturas são de widgets com fixtures, não do banco da empresa.

- **Ponto atual FE-052:** usuário rejeitou o espaço ocupado pelos filtros da
  captura inicial e pediu adiantar o conjunto respeitando arquitetura/acordos.
  A [revisão integrada de acabamento](referencias_frontend/rodada-acabamento-2026-10-16/README.md)
  deriva diretamente de FE-049: vidro suave, fundo azul/quente, lista como extrato,
  filtros recolhidos com seis recortes existentes. Leitura recuperada, navegação,
  dimensões, período/atenção atual e jornadas conservados. Não foi feito novo
  estudo parcial como substituto da base. Ver relatórios/manifesto na pasta e
  [registro atual](REFERENCIA_ATUAL_FRONTEND.json). Continuidade: integração pelo
  recorte FE-050, sem reabrir decisões visuais ou inferir tema global. Fonte atual
  demonstrada, não comportamento Flutter/API entregue.
  Verificação: 324 composições Edge/WebKit, sem erro JavaScript observado;
  manifesto FE-049 intacto e fonte reproduzível. Saúde final do workspace:
  410 backend/238 Flutter aprovados (408 backend na entrada; outras evoluções
  coexistem no workspace). Esta rodada não alterou código/testes do produto.

- **Retorno visual FE-051:** usuário anexou a captura inicial de Contas a Receber
  e destacou cores, vidro e contas com aparência bancária. A
  [análise na base visual, seção 8](BASE_VISUAL_FRONTEND.md#8-aproveitar-o-acabamento-da-referência-inicial--fe-051)
  propõe trazer fundo azul/quente discreto, painéis de vidro suave e lista como
  extrato para a estrutura FE-049, mantendo Leitura recuperada e medidas confirmadas.
  Preferência expressa não equivale à aprovação de todos os parâmetros do estudo
  antigo. Sem novo recurso bancário, fonte visual, implementação ou comparação
  nova nesta rodada. Antes do piloto, considerar esse retorno no fechamento do
  acabamento; não reiniciar arquitetura/navegação nem copiar filtros grandes para a home.

- **Ponto atual FE-050:** usuário respondeu **“SHOW, VAMOS PROSSEGUIR”** após
  FE-049. Organização acolhida como referência; fonte e arquivos visuais intactos.
  [Jornadas financeiras](JORNADAS_FINANCEIRAS_E_PRONTIDAO_DO_PILOTO.md) consolidadas
  com consulta, detalhe, preenchimento, revisão, envio e retorno. Inspeção local
  separou a prévia do Flutter atual e encontrou lacunas: identidade estável da
  tentativa, precondição de saldo revisado, data civil, divergência de atraso
  entre resumo/listas e cobertura/atualização após confirmar. Replay do POST pode
  concluir a intenção original; não o chamar de consulta somente de leitura.
  Pagar sobre título existente é recomendação do agente, não escolha do usuário.
  Próximo: alinhar esse recorte e fechar contratos antes do incremento real.
  Saúde reexecutada: 363 backend/238 Flutter aprovados; evidência e hashes no
  [registro FE-050](validacoes_frontend/fe-050-jornadas-2026-10-16/README.md).
  Sem código do app/API/banco, nova prévia ou commit nesta rodada.
- **Decisões FE-049:** usuário preferiu expressamente **Leitura recuperada**;
  considerou a orientada grande, pesada e sem contraste de hierarquia. Aprovou
  a organização integrada como direção. Pediu home curta, essencial, com escolha
  Dia/Semana/Mês; resultado do negócio sai do Financeiro e fica junto das vendas.
  Na pergunta específica respondeu **“Negócio — vendas, clientes e resultado”**.
  A [revisão integrada](referencias_frontend/rodada-organizacao-2026-10-16/README.md)
  mantém barra/destinos e leitura recuperada, renomeia o terceiro destino,
  demonstra períodos coerentes e separa atenção atual do recorte escolhido.
  Semana inicial é proposta da amostra, não escolha adicional do usuário.
  Home normal coube em até 835,96 na referência de altura 844 testada; ampliação,
  menor altura ou conteúdo maior podem exigir rolagem, sem cortar informação.
  Cinco grupos/90 composições por Edge/WebKit (180 no total) passaram; sem erro
  JavaScript observado. Saúde atual: 363 backend/238 Flutter aprovados.
  Próximo passo: terminar jornadas/estados e contratos reutilizáveis; não reabrir
  a disputa visual nem iniciar implantação global. Sem Flutter/API/banco ou Git.
- **Ponto atual FE-048:** continuação recebida no chat de FE-047. A
  [comparação integrada de hierarquia](referencias_frontend/rodada-tipografia-2026-10-16/README.md)
  deriva diretamente da recuperação FE-046, com duas leituras sincronizadas do
  mesmo registro/rascunho. Proposta orientada: página 24, seção 18, corpo/rótulo
  16, apoio 14, valor central 28 e resumo 24. Família existente conservada para
  isolar a decisão; fonte definitiva continua aberta. Barra normal, cinco áreas,
  destinos, home e medidas confirmadas preservados. Caso cotidiano e extremo,
  conteúdo 100/150/200%, claro/escuro e formato celular/computador disponíveis.
  **Limite importante:** só o conteúdo é ampliado; isso não valida escala global
  da navegação, zoom nem Dynamic Type. Quebra de quantia extrema entre milhares
  preserva dígitos, mas o conforto ainda precisa de avaliação. Ver relatório e
  capturas na pasta, além do [registro atual](REFERENCIA_ATUAL_FRONTEND.json).
  Próximo passo: retorno sobre leitura/equilíbrio. Não declarar tipografia aprovada
  nem avançar automaticamente a fundo/vidro, piloto real ou marco Git.
- **Continuação em outro chat, FE-047:** depois da apresentação recuperada, o
  usuário respondeu “Ok qual proximo passo?” e pediu enviar essa continuação e
  os próximos passos para outro chat porque este ficou longo. Retomar por
  **tipografia e hierarquia da informação**, usando a candidata de
  [REFERENCIA_ATUAL_FRONTEND.json](REFERENCIA_ATUAL_FRONTEND.json). Aproveitar
  a pesquisa e a proposta de hierarquia existentes; comparar poucas telas
  conhecidas, nomes longos, valores grandes e texto ampliado em claro/escuro.
  Conservar a barra, caminhos e medidas confirmadas. Não repetir a recuperação
  nem reiniciar o planejamento. O “Ok” permite seguir o alinhamento; não congela
  cada detalhe visual novo nem autoriza implementar Flutter/API. Após essa etapa:
  fechar demais detalhes visuais, consolidar jornadas/estados e arquitetura
  reutilizável, organizar um marco no Git, escolher e alinhar um piloto pequeno,
  implementar/validar o piloto e expandir módulos por incrementos. Cada passagem
  conserva seus contratos e o escopo; não executar a sequência inteira de uma vez.
  Chat local de continuação criado no mesmo projeto:
  `01a14659-364b-77f1-a979-38d363019836`, com contexto, arquivos, acordos e roteiro
  enviados no pedido inicial. Não é uma nova implementação ou outro checkout.
- **Ponto atual FE-046:** o usuário autorizou “OK VAMOS PROSSEGUIR” após o plano
  de recuperação; durante a conclusão pediu continuar de onde parou. A
  [rodada integrada](referencias_frontend/rodada-recuperacao-integrada-2026-10-16/README.md)
  usa a fonte original como estrutura, preserva barra/destinos/contexto por área
  e incorpora espaço 20, campos 24, painéis 32, destaque e jornadas Pagar/Receber.
  Cinco grupos por motor Edge/WebKit e 64 layouts no total passaram, sem erro
  JavaScript observado. Barra original/recuperada têm capturas de bytes idênticos
  em cada motor na comparação 1024/claro/escala normal; não é homologação de aparelho.
  Dezessete arquivos preservados com manifesto e origem. O
  [registro da referência atual](REFERENCIA_ATUAL_FRONTEND.json) aponta a candidata
  integrada; os estudos parciais não substituem mais o mapa por recência do arquivo.
  **Próximo passo:** colher retorno sobre a recuperação. Não declarar aprovação
  automática, implementação Flutter/API ou commit Git. Índices FE-045 abaixo
  explicam a falha anterior; a recuperação visual posterior está nesta rodada.
- **Prioridade mais recente, FE-045:** usuário contestou a regressão da barra e
  cobrou sinceridade sobre preservação de tudo. A [auditoria detalhada](AUDITORIA_CONTINUIDADE_FRONTEND_2026-10-16.md)
  verificou 11 manifestos/179 cópias íntegras, 26 HTMLs disponíveis e os 44 registros
  anteriores FE-001–044. Primeira comparação e contêiner estavam só na conversa:
  duas cópias foram recuperadas no projeto. Onze documentos centrais e a pasta
  histórica estão não rastreados no Git. Falha principal: referências/acordos
  não aplicados consistentemente às amostras novas; barra 140→174, arredondamento,
  marca extra, espaçamento e seleção alterados. Testes não comparavam fidelidade
  da barra nem cobertura completa de destinos. Não declarar que foi tudo perdido
  ou que está tudo consolidado. A matriz da auditoria aponta os demais acordos.
  **Próximo trabalho:** consolidar os avanços na estrutura do mapa original,
  recuperando barra e destinos. Nenhuma prévia/app foi modificada nesta auditoria;
  a recuperação visual e o versionamento continuam pendentes. Os relatos
  cronológicos abaixo conservam etapas anteriores, não redefinem essa prioridade.
- **Trabalho autorizado aqui:** pesquisa, planejamento, documentação e prévias.
  A nova arquitetura visual ainda não foi aplicada ao cliente Flutter por este chat.
- **Base aceita:** aparência e organização da última demonstração navegável;
  Início, Financeiro, Vendas, Estoque e Mais. O usuário destacou a utilidade das
  informações da visão geral, além da apresentação e do visual.
- **Plataformas:** priorizar Android e iPhone; adaptar ao Windows. Na inspeção
  de 15/10/2026 havia projetos nativos Android/Windows, sem `client/ios`.
  Desenhar para iPhone não entrega automaticamente integração nativa iOS.
- **Rodada anterior, 16/10/2026:** o usuário aceitou a conferência e pediu integral
  por padrão, parcial opcional com campo revelado suavemente e mais arredondamento.
  A [nova prévia](RODADA_FRONTEND_INTEGRAL_2026-10-16.md) foi criada e verificada;
  o acabamento demonstrado ainda aguarda avaliação. A implementação não começou.
- **Data no iPhone:** a primeira revisão alinhou a moldura, mas uma nova foto
  confirmou texto cortado/desalinhado. A [rodada de resumo/data](RODADA_FRONTEND_RESUMO_E_DATA_2026-10-16.md)
  usa botão com calendário próprio; verificações locais passaram e o usuário
  considerou a amostra ótima/perfeita, permitindo avançar. Não declarar por isso
  homologação do app iOS ou execução de teste físico pelo agente.
- **Exemplo:** integral usa o saldo atual sem digitar. Para explorar R$ 300,00
  pagos de uma conta de R$ 680,00, selecionar Parcial; depois o integral será
  R$ 380,00. Todos os valores da prévia são fictícios, sem operação bancária.
- **Pesquisa empresarial, 16/10/2026:** o usuário pediu rigor de uma grande
  aplicação financeira/fiscal/empresarial e continuidade das pesquisas. Fontes,
  aplicações e limites estão na [nova pesquisa](PESQUISA_FRONTEND_EMPRESARIAL_2026-10-16.md).
  Isso não muda a prioridade mobile nem a simplicidade da empresa familiar.
- **Recorte autorizado e demonstrado:** Financeiro → Pagar hoje → lista filtrada
  → origem da conta, reaproveitando o pagamento. A nova amostra tem entradas
  “Conferir a data”, “Financeiro no celular” e “Financeiro no Windows”. A escolha
  Consulta financeira no painel de design compara dados/sem contas/indisponível.
- **Última jornada aceita:** [Receber e movimento](RODADA_FRONTEND_RECEBER_2026-10-16.md).
  O usuário confirmou que no fiado geralmente quitam o saldo inteiro: integral
  do saldo atual por padrão, parcial opcional. Prévia criada, verificada e aceita
  como referência em FE-024,
  com venda de R$ 150,00/recebido R$ 50,00/saldo R$ 100,00 e origem preservada.
- **Animações:** algumas já existiam nas amostras. O
  [padrão de movimento](PADROES_DE_MOVIMENTO_FRONTEND.md) documenta transições,
  pesquisa e redução; implementação real no piloto, valores ainda propostos.
- **Última base aceita, FE-025/FE-026:** usuário autorizou continuar. O
  [catálogo mínimo](CATALOGO_COMPONENTES_FRONTEND.md) registra dez padrões candidatos,
  responsabilidades e estados, com três entradas interativas: Campos e escolhas,
  Ações e respostas, Resumo e lista. O retorno posterior “Tá ótimo” elogiou
  elegância, aparência agradável e arquitetura inteligente: direção e apresentação
  aceitas como referência. Não registrar cada novo detalhe técnico ou medida
  como aprovado automaticamente.
- **Aprendizado:** situação financeira, disponibilidade da consulta e andamento
  do comando são dimensões separadas. Os controles compartilhados recebem
  opções do módulo; códigos de formas de Pagar/Receber não são equivalentes.
- **Novidades apenas simuladas:** consulta anterior com horário e verificação
  após perda de resposta. Não comprovam cache nem recuperação de operação da API.
- **Rodada da base, FE-027:** pedido “Show, vamos em frente amiga ;)”, com retomada
  após interrupção. A [base visual](BASE_VISUAL_FRONTEND.md) propõe papéis de cor,
  contorno legível, pares claro/escuro, curvas e espaço, com sete ajustes
  compartilhados nos exemplos conhecidos. Os [valores](TOKENS_VISUAIS_PROPOSTOS.json)
  estão estruturados, ainda sem aplicação ao Flutter. Retorno registrado abaixo.
- **Retorno atual, FE-028/FE-029:** usuário confirmou **20 entre campos** e cor
  de destaque escolhível nas configurações, com azul original **#2866ae** por
  padrão. Relatou que outros ajustes não respondiam. A
  [revisão dos ajustes](RODADA_FRONTEND_AJUSTES_2026-10-16.md) reproduz conflito
  entre edição e restauração antiga e entrega nova fonte, com teste do helper
  original. Naquele retorno, fundo e raios movimentados para experimentar não
  foram aprovados. **FE-030:** depois confirmou campos 24 px e painéis 32 px;
  perguntou o significado de movimento compartilhado, sem escolher um modo.
- **Aprendizado novo:** contraste de texto e indicador de campo são separados.
  Medir só tokens finais não detecta uma transição de cor pouco legível; texto
  e fundo agora mudam juntos na nova amostra, com verificação das cores efetivas.
- **Retorno FE-031/FE-032:** usuário não percebe animação na abertura do calendário.
  O teste local observou a entrada anterior de 180 ms, não reproduziu ausência
  total. Estudo posterior usa entrada de 240 ms desde opacidade 0, deslocamento
  12 e escala .98, com redução respeitada; passou em Edge/WebKit locais.
  **Não apresentado ao usuário:** durante a conclusão, pediu evitar gerar prévia
  a cada ajuste simples para reduzir consumo. Registrar e agrupar mudanças;
  apresentar outra prévia quando ele solicitar ou houver um conjunto para revisar.
  Ver [registro e evidências](RODADA_FRONTEND_CALENDARIO_2026-10-16.md).
- **Rodada atual FE-033:** usuário autorizou prosseguir com planejamento e
  aprendizado. A [hierarquia e tipografia](HIERARQUIA_E_TIPOGRAFIA_FRONTEND.md)
  agora registra pesquisa primária, informação por família de página, nove papéis
  tipográficos propostos, exemplo de saldo original/pagamentos/saldo atual e
  critérios de adaptação. Novos tamanhos, família e composição não são aprovação.
  Rodada documental; sem prévia, testes de navegador ou alterações Flutter.
- **Continuação atual FE-034:** usuário gostou do critério de uma revisão visual
  por conjunto e autorizou prosseguir com prudência e pesquisa. A
  [composição das páginas](COMPOSICAO_DAS_PAGINAS_FRONTEND.md) detalha lista,
  detalhe, registro/revisão e retorno, com alternativas e limites. Recomenda
  detalhe em página própria nesta primeira rodada. Isso é proposta, não escolha
  final nem garantia de recuperação já integrada. Sem nova prévia ou navegador.
- **Direção ampliada FE-036/FE-037:** usuário esclareceu que design inteligente
  inclui interpretar dados, antecipar necessidades e trazer informação útil
  nas telas e momentos relevantes, transmitindo cuidado sem depender de IA.
  Pediu documentação específica, em profundidade. Ela está no
  [documento de design inteligente](DESIGN_INTELIGENTE_E_ORIENTACAO_AO_USUARIO.md),
  com fundamentação, critérios, catálogo e contrato de orientações; manual e
  instruções de entrada apontam para ela. Esta memória não a substitui por resumo.
- **Rodada atual FE-039/FE-040:** após autorização, foram especificadas as
  [três primeiras regras](REGRAS_DE_INFORMACAO_UTIL_FRONTEND.md) com dados,
  condições, mensagens, destinos, validade e casos. Usuário confirmou **próximos
  três dias**, com hoje/atrasadas separados. Demais arranjos/textos são propostas.
  Código conferido: estoque já tem filtro, falta passagem inicial pela navegação;
  custo incompleto tem contagem e classificação própria, mas o resumo não fornece
  IDs por essa classificação. Primeiro caminho proposto é explicar o resultado,
  sem prometer correção de custos históricos. Data/atualidade exigem contrato
  explícito na integração. Não houve prévia, navegador ou alteração no app.
- **Revisão visual atual FE-041:** usuário pediu ver o planejado, observando que
  o trabalho parecia apenas documental. A [prévia Negócio em foco](referencias_frontend/rodada-negocio-em-foco-2026-10-16/README.md)
  reúne visão geral, vencimentos separados, estoque mínimo, explicação do
  resultado e lista → detalhe → registro → revisão/resultado, em celular/Windows.
  Usa dados fictícios e conserva as medidas confirmadas. Apresenta também o
  calendário de 240 ms antes adiado. Conferida em Edge/WebKit locais; colher
  retorno sobre utilidade, prioridade e percurso antes de outro incremento.
  Tipografia, fundo, composição nova e escolha do piloto real continuam abertos.
- **Correções durante a revisão FE-042/FE-043:** usuário perguntou pela home
  anterior e alertou sobre perder acordos. Conservar seus blocos financeiro,
  negócio hoje e atenção; presença conferida na prévia e método atualizado no
  manual. Também observou que vendas e resultado pareciam iguais: exemplo
  repetia 1.240 em períodos diferentes. A revisão usa vendas de hoje 860 e
  resultado de 1–16/10 de 1.240, com fórmula explicada. São exemplos fictícios;
  nome Resultado do negócio proposto, sem mudar cálculo real ou declarar aprovação.
- **Método explícito FE-035:** usuário perguntou se a estratégia estava acessível
  aos agentes e pediu continuar. Ela já aparecia distribuída; agora está
  consolidada na seção **8.1 — Método de planejamento** do manual, com referências
  em AGENTS.md e AGENT_INSTRUCTIONS.md. Inclui pesquisa direcionada, comparação,
  confirmação de dúvidas relevantes, continuidade e cadência sem aprovações
  repetidas. O roteiro de seis tarefas da próxima revisão está na composição.
  Pagar é recomendado como exemplo dessa apresentação, não escolhido como piloto.
  Rodada documental; sem nova pesquisa externa, prévia, navegador ou código.
- **Retorno mais recente FE-044:** usuário destacou a mensagem original do
  mapa navegável (“Abrir Financeiro → Pagar → Fornecedor” e “Estoque → Cestas e
  montagens → Cesta Básica Completa”) e disse “olha isso”. A comparação das fontes
  confirma que Negócio em foco manteve os cinco nomes de áreas, mas omitiu vários
  caminhos do mapa anterior. Repor a home não resolve toda a continuidade.
  O mapa original segue como base organizacional; a amostra recente é parcial.
  Ver [comparação e lacunas](COMPOSICAO_DAS_PAGINAS_FRONTEND.md#82--continuidade-do-mapa-navegável-fe-044).
  Próximo trabalho de consolidação: incorporar os avanços ao mapa preservando
  destinos e contexto por área. Essa integração ainda não foi feita; não afirmar
  que os menus já foram restaurados. Sem nova prévia ou mudança no aplicativo
  nesta resposta. O destaque não aprova novos detalhes de composição.
- **Depois:** contas, cartões e importações em rodadas próprias. A escolha do
  primeiro piloto real continua aberta.
- **Não fechado:** tokens finais, mistura de materiais, paleta, medidas,
  comportamento de todos os controles e detalhes internos dos módulos.

O usuário quer um processo incremental de engenharia: exemplos concretos,
análise cuidadosa, aprendizado por pesquisa e registro de decisões. Não apresentar
uma arquitetura inteira como resolvida em uma rodada nem exigir novamente uma
autorização já concedida para um ajuste rotineiro dentro do escopo vigente.

## 3. Contexto do negócio e do produto

A empresa inicial é familiar e pequena, vende cestas básicas por entrega, sem
estabelecimento aberto ao público. A entrega é feita pela própria família, com
um entregador. A interface deve atender essa rotina, sem acrescentar gestão
complexa de equipes por antecipação.

A visão de produto é modular: adaptar o aplicativo a outras empresas, compondo
ou substituindo módulos. A metáfora usada pelo usuário foi Lego. A implicação
técnica proposta é definir contratos, dependências, navegação e padrões comuns;
separar arquivos, por si só, não garante substituição segura nem elimina vínculos
históricos entre módulos.

O aplicativo deverá comportar uma central financeira com bancos, contas, cartões,
extratos e faturas. Pagar e Receber pertencem à mesma área Financeiro. Produtos,
cestas, compras, vendas, PDF, formulários em branco, impressão, configuração,
pareamento e backup fazem parte do contexto que deve ser preservado. Importação
de DANFE é uma evolução futura, ainda sem fluxo entregue neste projeto visual.

“Aplicativo inteligente” foi recebido aqui como informação útil e contextual:
mostrar o que pede atenção e permitir agir a partir disso. Não houve autorização
para implementar IA ou adicionar dependências de IA.

## 4. Registro das decisões e do retorno do usuário

IDs estáveis para referência. Datas de consolidação não são horários exatos de
cada fala; registros de 14–15/10 foram reunidos em 15/10/2026.

| ID | Decisão ou retorno | Motivo e alcance | Situação |
| --- | --- | --- | --- |
| FE-001 | Alinhar o projeto por etapas antes de implementar. | O usuário pediu expressamente evitar uma mudança completa de uma vez. | Confirmado; vale para o trabalho deste chat. |
| FE-002 | Mobile first Android/iPhone, com Windows bem adaptado. | A maior prioridade é o uso no celular; o computador continua importante para gestão e documentos. | Confirmado; integração iOS pendente. |
| FE-003 | Abrir na visão geral do negócio com acesso direto ao Financeiro. | Escolha explícita em resposta à pergunta sobre a primeira área. | Confirmado. |
| FE-004 | Unificar Pagar e Receber na área Financeiro. | Permitir visão financeira coesa e evolução para documentos bancários. | Confirmado; organização interna em planejamento. |
| FE-005 | Comparar Camadas suaves e Vidro nos controles em uma prévia. | O usuário quis experimentar ambas antes de escolher. | Comparação realizada; nenhuma variante exata foi congelada. |
| FE-006 | Demonstrar vidro de verdade, fundo claro/escuro/personalizado e destaque independente. | A primeira prévia era azul, pouco distinta e não deixava perceber transparência. | Correção aceita na prévia; entrega de temas no Flutter por definir. |
| FE-007 | Mostrar propostas por telas navegáveis e tarefas reais. | O usuário explicou que, sem exemplo, era difícil entender a arquitetura imaginada. | Método adotado após pesquisa; manter nas próximas decisões. |
| FE-008 | Usar os cinco destinos e a direção visual da demonstração como base. | O usuário gostou da organização, do design e das informações úteis da visão geral. | Aceito como base, sujeito a refinamentos nos percursos. |
| FE-009 | Padronizar controles sem apagar diferenças dos módulos. | Filtros e formulários se repetem, mas têm campos e necessidades próprias. | Diretriz confirmada; composição e implementação por incremento. |
| FE-010 | Preservar FAB e espaço de rolagem; separar ação principal de navegação entre áreas. | Preferência anterior contra barra fixa de ações; a prévia posterior mostrou navegação inferior. | Confirmado para ações; avaliar convivência com teclado e áreas seguras. |
| FE-011 | Salvar também aprendizados, pesquisas e motivos das decisões. | O usuário chamou atenção para a perda de contexto por compactação. | Solicitado e consolidado em 15/10/2026; manutenção contínua. |
| FE-012 | Avançar ao próximo recorte de planejamento, mantendo os registros. | Pedido explícito do usuário após a consolidação documental. | Rodada de Pagar autorizada em 15/10/2026; prévia criada, sem implementação no app. |
| FE-013 | Explorar revisão separada, erros vinculados aos campos e conclusão com saldo/histórico. | Propostas do assistente para avaliar clareza e segurança do registro cotidiano. | Demonstradas; conferência aceita em 16/10/2026. Ver FE-014 a FE-016 para o retorno posterior. |
| FE-014 | Manter a revisão antes de confirmar o pagamento. | O usuário respondeu que a revisão estava adequada. | Confirmado em 16/10/2026 para este percurso. |
| FE-015 | Integral do saldo atual por padrão; parcial opcional, com campo revelado por animação suave. | Pagamentos parciais são raros na rotina de pagamentos relatada pelo usuário. | Solicitado em 16/10/2026; demonstrado e verificado na prévia. |
| FE-016 | Arredondar mais campos e painéis; esclarecer a fidelidade da prévia. | O usuário considerou as caixas retangulares demais e perguntou o que seria implementado. | Preferência confirmada; amostra com painéis 32/campos 28/cápsulas em avaliação. Esses números são proposta do assistente. |
| FE-017 | Corrigir o campo de data que ultrapassa a coluna na prévia do iPhone. | Defeito mostrado em foto pelo usuário em 16/10/2026. | Primeira correção externa verificada localmente, mas outra foto confirmou texto ainda incorreto; ver FE-020. |
| FE-018 | Projetar com o rigor esperado de uma grande aplicação bancária, financeira, fiscal e empresarial; continuar pesquisando e registrando. | Pedido explícito do usuário em 16/10/2026. Eleva os critérios de clareza, consistência e confiabilidade, conservando o processo gradual e a rotina atual. | Direção confirmada; critérios concretos em elaboração. Não autoriza ampliar funções automaticamente. |
| FE-019 | Avaliar o percurso Financeiro → Pagar hoje → lista filtrada → origem da conta. | Proposta após a pesquisa de 16/10, autorizada pelo usuário na mensagem seguinte; corrigir a data primeiro. | Prévia autorizada, criada e verificada localmente. Aparência e organização desse recorte em avaliação; sem implementação no app. |
| FE-020 | Corrigir a data cujo texto continua cortado no iPhone, antes de prosseguir com o resumo. | Nova foto e pedido explícito em 16/10/2026; mostram o limite da correção anterior. | Nova amostra usa botão com calendário e mede caracteres. Verificada localmente e aceita como referência em FE-021; seletor Flutter e homologação por aparelho continuam próprios do piloto. |
| FE-021 | Prosseguir após a amostra de resumo e data. | O usuário respondeu “Ótimo perfeito” e perguntou pelo próximo passo em 16/10. | Amostra aceita como referência para continuar; não é homologação da integração iOS nem aprovação de cada token. |
| FE-022 | Integral do saldo atual também por padrão em Receber. | Resposta específica sobre vendas fiadas: “Geralmente quitam o saldo inteiro”. | Confirmado; parcial opcional. A demonstração de Receber foi aceita como referência em FE-024. |
| FE-023 | Esclarecer o momento de planejar e implementar animações. | Pergunta do usuário em 16/10. Esclarecimento: planejar/demonstrar agora, integrar ao Flutter no piloto. | Especificação inicial salva e movimentos adicionais demonstrados. Durações/curvas são propostas, não escolhas finais do usuário. |
| FE-024 | Aceitar a prévia de Receber e o movimento demonstrado como referência. | Resposta posterior do usuário: “Perfeito.👍 :)”, em 16/10/2026. | Referência aprovada para a próxima etapa. Consolidar componentes/estados é o próximo recorte proposto; tokens globais e implementação no Flutter ainda exigem seu alinhamento próprio. |
| FE-025 | Continuar ao catálogo mínimo a partir das jornadas aceitas. | Mensagem em 16/10/2026: “Otimo. Vamos prosseguir amiga ;)”. Autoriza a próxima rodada de pesquisa, documentação e exemplos. | Catálogo e amostra criados para avaliação. Não é aprovação antecipada dos novos estados, tokens nem autorização de implementação. |
| FE-026 | Retorno positivo ao catálogo inicial e à direção do projeto. | Em 16/10/2026, o usuário respondeu “Tá ótimo” e destacou elegância, aparência agradável e arquitetura inteligente. | Direção e apresentação aceitas como referência para continuar o planejamento. Medidas finais, contratos técnicos e implementação mantêm seu alinhamento próprio. |
| FE-027 | Avançar ao alinhamento de cores, formas e espaçamento do catálogo. | Em 16/10/2026, “Show, vamos em frente amiga ;)”; depois pediu continuar de onde houve interrupção. | Pesquisa, proposta documentada e amostra ajustável criadas para avaliação. Não congela valores nem autoriza implementação no Flutter. |
| FE-028 | Usar espaço 20 e deixar o usuário escolher destaque nas configurações, com a cor original por padrão. | Pedido explícito e captura do controle em 20, em 16/10/2026. Azul original da base: #2866ae. | Confirmado para o projeto. Configuração Flutter ainda futura; demais ajustes testados não são aprovação. |
| FE-029 | Corrigir ajustes que não produzem mudança perceptível na prévia. | Usuário relatou que tentou modificar os outros controles e nada mudou. | Conflito edição/estado antigo reproduzido com helper original; fonte revisada e verificações locais concluídas. Não é homologação do painel nativo ou do app. |
| FE-030 | Usar cantos de campos 24 px e painéis 32 px; esclarecer movimento compartilhado. | Pedido explícito de 16/10/2026: “cantos dos campos vai ser 24px, cantos dos paineis vai ser 32. Movimento compartilhado é oq?” | Raios confirmados para o planejamento. Movimento explicado como política comum às três amostras, com Padrão/Reduzido e preferência de redução do sistema. Pergunta não aprova modo, durações ou nova opção nas configurações. Registro documental e valores estruturados atualizados; fontes históricas preservadas, sem alteração no Flutter. |
| FE-031 | Conferir calendário que aparece sem animação perceptível. | Relato do usuário em 16/10/2026. | Entrada de 180 ms observada nos testes locais anteriores; ausência total no ambiente do usuário não reproduzida. Nova proposta de entrada 240 ms verificada localmente e salva, sem apresentação ou aprovação. Não alterou Flutter. |
| FE-032 | Evitar gerar uma nova prévia a cada ajuste simples; agrupar alterações para revisão. | Usuário pediu poupar créditos e dispensou a prévia desta rodada. | Preferência vigente. A geração e os testes locais desta rodada já haviam terminado; somente registros e preservação foram concluídos depois do pedido. Não emitir a nova prévia nem retestar agora; próximos ajustes simples devem ser documentados e agrupados. |
| FE-033 | Prosseguir no planejamento da hierarquia e tipografia, continuando a pesquisa e seu registro. | Usuário respondeu “show, vamos prosseguir com o planejamento, sempre buscando melhorar e aprender coisas novas”, em 16/10/2026, após a proposta desse recorte. | Pesquisa Apple/SAP/W3C, documento de hierarquia e escala inicial propostos; dados estruturados, manual e plano atualizados. Autoriza a rodada de planejamento, não confirma família, tamanhos ou implementação. Sem nova prévia, navegador ou testes do app. |
| FE-034 | Continuar a composição das famílias de página com pesquisa e prudência, reunindo mudanças para revisão visual. | Após perguntar quando gerar outra prévia, o usuário respondeu “show, gostei da ideia, vamos prosseguir com o plano sempre sendo prudente, fazendo pesquisas, confirmando detalhes, buscando as melhores opções, criando um caminho, buscando design inteligente”, em 16/10/2026. | Critério de revisão agrupada acolhido; nova composição documentada como proposta. Carbon/GOV.UK/SAP consultados. Detalhe dedicado, retorno ao contexto e edição com rascunho preparados para avaliação, sem prévia ou implementação nesta rodada. |
| FE-035 | Tornar o método de planejamento explícito e acessível aos agentes e preparar os próximos passos. | Em 16/10/2026, o usuário reafirmou prudência, pesquisa, confirmação de detalhes, melhores opções, caminho e design inteligente e perguntou se a estratégia estava registrada aos agentes. | Método consolidado na seção 8.1 do manual e ligado às duas instruções de entrada. Roteiro documental de seis tarefas preparado para a próxima revisão agrupada; nenhuma prévia ou pesquisa externa nova nesta rodada. A diretriz de trabalho é confirmada; detalhes novos de composição e a sugestão de exemplo Pagar continuam propostas, sem escolher o piloto real. |
| FE-036 | Ampliar design inteligente para interpretação e orientação proativa com os dados do app, sem exigir IA. | Usuário esclareceu em 16/10/2026 que o aplicativo deve trazer informações úteis e importantes onde fazem diferença e transmitir cuidado, antecipando o que a pessoa precisa saber. | Intenção do produto confirmada e definição anterior ampliada. Pesquisa e documentação específicas; exemplos e regras candidatas ainda propostas. Sem implementação ou nova prévia. |
| FE-037 | Manter documentação específica e aprofundada para os conceitos importantes, além de resumos. | Durante a pesquisa, em 16/10/2026, o usuário pediu “montar uma documentação especifica pra essas coisas importantes pra evitar ficar colocando apenas resumos”. | Documento de design inteligente criado com intenção, pesquisa, aplicações, limites, catálogo, contrato, arquitetura e avaliação. Entrada dos agentes, manual, plano e índice apontam para ele. Preservar o corpo detalhado; esta memória é índice/histórico. |
| FE-038 | Incluir sempre links das fontes nos documentos de aprendizado para permitir aprofundamento. | Usuário reforçou em 16/10/2026 que só o resumo não deixa os assuntos claros e pediu lembrar dos links. | Regra explícita nas instruções dos agentes, manual e documento específico. Acrescentados links originais também às pesquisas P-09 a P-11 e P-13 a P-16, que antes remetiam aos documentos internos detalhados. P-08 conserva suas fontes locais de integração. Sem nova pesquisa, prévia ou implementação. |
| FE-039 | Especificar as três primeiras oportunidades de informação útil. | Usuário respondeu “Showw, vamos prosseguir” à proposta de vencimentos, estoque mínimo e custo incompleto. | Documento específico criado com condições, fontes, ciclo, linguagem, destinos e casos. Autorização de planejamento; textos e novas integrações seguem propostas. Inspeção de código e pesquisa documental, sem implementação ou nova prévia. |
| FE-040 | Destacar próximos vencimentos em três dias, separando hoje e atrasadas. | Em pergunta específica desta rodada, o usuário respondeu “Próximos 3 dias”. | Horizonte confirmado. A proposta considera os três dias seguintes, com D separado e terceiro dia incluído. Exemplo D=16/10 usa 17–19/10; não cria configuração nova nem autoriza alterar datas do domínio. |
| FE-041 | Mostrar o conjunto planejado agora, evitando prolongar somente a documentação. | Usuário perguntou “e quando vc vai me mostrar essas coisas? me parece que só está adicionando nas documentações por enquanto.” | Prévia conectada Negócio em foco criada, conferida e preparada para revisão no mesmo atendimento. Inclui INT-01/02/03 e jornada financeira; dados e confirmações fictícios. Retorno ainda pendente; nenhuma autorização de implementação no app. |
| FE-042 | Conservar a estrutura da homepage já aceita ao evoluir o conjunto. | Usuário enviou a home antiga, perguntou o que havia acontecido com ela e alertou que perder acordos bagunçaria o projeto. | Agente reconheceu a omissão indevida e reincorporou financeiro A pagar/A receber, negócio hoje e atenção à nova amostra. Fonte antiga intacta; conferência verifica os blocos e manual exige preservar a base aceita. Não é aprovação automática da nova disposição. |
| FE-043 | Diferenciar vendas e resultado por significado, período e exemplo. | Usuário observou que “Valor das Vendas” e “Resultado gerencial” pareciam iguais. | Exemplo anterior repetia 1.240 em períodos diferentes. Revisão mostra vendas hoje 860 e resultado 1–16/10 de 1.240, com cálculo acessível. Nome Resultado do negócio é proposta do agente; fórmula atual do backend conferida, sem alteração no app. |
| FE-044 | Reexaminar a continuidade com a proposta navegável anterior, além da home. | Usuário destacou a mensagem do primeiro mapa clicável, com os percursos de Financeiro e Cestas e montagens, e pediu “olha isso”. | Comparação local encontrou omissões de destinos e diferença no contexto por área na amostra recente. Mapa original preservado como base; Negócio em foco identificado como estudo parcial. Lacunas registradas na composição, sem restaurar menus, criar prévia ou alterar Flutter nesta resposta. |
| FE-045 | Auditar a preservação dos designs, acordos e aprendizados e reconhecer a regressão visual da barra. | Usuário enviou duas imagens, afirmou que o combinado de continuidade foi desrespeitado, pediu 100% de sinceridade e reforçou que a barra lateral ficou desorganizada. | Auditoria reproduzível confirma 179 cópias/11 manifestos e 44 registros anteriores. Duas cópias HTML só existentes na conversa recuperadas. Regressão visual e ausência de versão integrada explicitadas; documentos centrais/arquivo histórico não rastreados no Git. Matriz de acordos e recuperação delimitada registradas; sem corrigir prévia, implementar Flutter ou criar commit nesta rodada. |
| FE-046 | Recuperar a prévia integrada a partir do mapa original, preservando a base e incorporando os ajustes confirmados. | Usuário autorizou “OK VAMOS PROSSEGUIR” após a sequência de recuperação e depois pediu continuar de onde parou. | Fonte original reutilizada; barra, cinco áreas, destinos e contexto preservados; formulários e jornadas integrados. Conferência local de cinco grupos por motor e 64 layouts passou. Dezessete arquivos arquivados e registro canônico da candidata criado. Demonstração para revisão; não aprova os detalhes abertos nem autoriza código Flutter/API. |
| FE-047 | Transferir a continuidade de tipografia/hierarquia e o roteiro posterior para outro chat do mesmo projeto. | Usuário pediu “Ok manda isso e os proximos passos pra outro chat, esse aqui ja ta muito longo”, após o alinhamento do próximo passo. | Contexto e continuação registrados; criar chat local no mesmo projeto com fontes, acordos, limites, falhas já corrigidas e próximas etapas. Não é autorização para refazer a estrutura ou implementar o app inteiro. |
| FE-048 | Comparar tipografia e hierarquia na fonte integrada, sem repetir a recuperação. | Continuação expressa encaminhada por FE-047 com prioridade para home e formulário/detalhe financeiro, nomes longos, quantias altas e texto ampliado. | Comparação orientada/recuperada criada, com jornada/rascunho sincronizados, papéis propostos e casos de leitura. Barra normal e caminhos conservados; evidência local e limites na pasta da rodada. Novas medidas/família dependem de retorno; sem alterações Flutter/API/banco ou commit. |
| FE-049 | Manter Leitura recuperada e organizar as áreas por tarefa, com home curta e períodos. | Usuário rejeitou a orientada por texto grande/peso excessivo, acolheu a integração, pediu resultado junto das vendas e escolheu “Negócio — vendas, clientes e resultado”. | Leitura recuperada escolhida; terceiro destino renomeado, resultado movido, home com Dia/Semana/Mês e atenção atual. Demais caminhos/geometria preservados. Nova composição demonstrada e conferida localmente; não equivale a implantação do front-end ou aprovação automática de cada dado ilustrativo. |
| FE-050 | Consolidar jornadas e contratos antes do piloto. | “SHOW, VAMOS PROSSEGUIR” após FE-049. | Referência visual acolhida e preservada. Estados/envio/retorno confrontados com código e testes; lacunas e primeiro recorte proposto documentados. Pagar é recomendação do agente; sem escolha atribuída ao usuário ou implementação Flutter/API. |
| FE-051 | Identificar o que aproveitar da referência inicial com vidro. | Usuário anexou Contas a Receber, elogiou cores/glasslike e contas com aparência de banco, e perguntou o que incluir na versão atual. | Preferência visual registrada. Proposta: acabamento de vidro/fundo suave e lista como extrato sobre a organização FE-049, mantendo Leitura recuperada, medidas e navegação. Análise documentada; combinação ainda não demonstrada/implementada. |
| FE-052 | Adiantar e reunir o acabamento com filtros compactos. | Usuário não gostou do espaço tomado pelos filtros da captura e pediu avançar respeitando arquitetura e acordos para chegar à parte final. | Nova fonte derivada de FE-049, com vidro/cores/extrato e filtros recolhidos. Mantém destinos, leitura, dimensões e jornadas. Revisão visual agrupada e registros atualizados; não implica implantação global Flutter/API. |
| FE-053 | Integrar o primeiro fluxo real de pagamento de conta existente. | “Show vamo embora” após a indicação de Pagar real como próxima entrega concreta. | Piloto Flutter/API implementado com detalhe, histórico, formulário, revisão, persistência/replay, saldo/data e confirmação separada do GET. Capacidade de servidor e hashes legados preservados; evidência própria. Tema/navegação globais e Receber continuam incrementos seguintes; sem atualização automática da instalação. |
| FE-054 | Integrar Receber e compartilhar o padrão financeiro. | “Vambora uhuuu” e pedidos de continuar após a distinção entre prévia, piloto e versão instalada. | Fluxo real Receber com contratos aditivos, venda de origem, filtros recolhidos, extrato/páginas, recuperação comum e adaptadores tipados. Pagar mantém JSON/chaves e ganha o mesmo material local. Instalação/tema global/áreas principais ainda separados; evidência específica. |

### Preferências dos controles que precisam continuar visíveis no projeto

- Moderno, elegante, arredondado e com profundidade; evitar aspecto seco e
  excessivamente simplificado. Usar a prévia aceita como referência concreta.
- Painel de filtros alinhado ao resumo e à lista. Animações discretas ajudam a
  comunicar abertura e mudança; respeitar redução de movimento.
- Cliente e cesta por seleção de cadastros reais, com busca quando necessário.
  Não exigir digitação/memória de identificadores. Considerar histórico e paginação.
- Datas escolhidas com calendário e períodos claros. Moeda com formatação
  automática; distinguir vazio, zero e entrada inválida.
- Rótulos diretos como Contas, Em aberto, Parcial, Vencidas, Pagas e Canceladas.
  Explicações secundárias têm hierarquia visual própria, como “Aumenta o estoque”.
- Vencidas na mesma seleção de situação evita a combinação incoerente de filtro
  Pagas + Vencidas. Atraso atual é derivado para contas OPEN/PARTIAL pendentes;
  uma conta parcial pode estar vencida. Não criar um novo status persistido.
- Espaçamento de 24 e cantos de painel de 16 foram referências exploradas na
  primeira prévia. Interações posteriores nos ajustes não são uma escolha final
  de tokens nem autorizam um raio único para todos os componentes.
  O pedido de 16/10 por curvas mais amplas supera a ideia de conservar 16 como
  padrão: uma amostra posterior testou 32/28 e cápsulas. Os valores confirmados
  seguintes são espaço 20 (FE-028), painéis 32 e campos 24 (FE-030).

## 5. Pesquisas realizadas e o que aprendemos

Sínteses das fontes consultadas em 14–15/10/2026. As aplicações ao ZM são decisões
de projeto ou propostas do assistente, identificadas abaixo; as fontes não
determinam os cinco destinos, a paleta ou regras financeiras do aplicativo.

### P-01 — Apresentar um projeto por protótipos

Fonte: [GOV.UK — Making prototypes](https://www.gov.uk/service-manual/design/making-prototypes).

**Aprendizado:** interações concretas permitem explorar, comunicar e avaliar
uma proposta antes de comprometer a implementação. A fidelidade acompanha a
pergunta em avaliação; código de protótipo tem uma finalidade distinta do produto.

**Aplicação:** uma tarefa curta por rodada, com dados fictícios e caminhos
navegáveis. A primeira demonstração conectou Início → Financeiro → Pagar →
detalhe e Estoque → Cestas e montagens → tipo de cesta. **Limite:** uma prévia
HTML não comprova implementação Flutter, integração, desempenho ou acessibilidade nativa.

### P-02 — Discutir o percurso entre telas

Fonte: [Nielsen Norman Group — Wireflows](https://www.nngroup.com/articles/wireflows/).

**Aprendizado:** relacionar telas com a sequência de ações ajuda a discutir o
comportamento de uma aplicação e a localização de cada etapa.

**Aplicação:** avaliar “o que faço agora e para onde volto”, além da aparência
de uma tela isolada. Alternar áreas deve preservar seu ponto de navegação.
**Limite:** um percurso aceito não define todos os caminhos ou regras do módulo.

### P-03 — Separar responsabilidades no Flutter

Fonte: [Flutter — Guide to app architecture](https://docs.flutter.dev/app-architecture/guide).

**Aprendizado:** separar apresentação, estado e acesso a dados facilita evolução
e teste, adaptando a estrutura à necessidade real da aplicação.

**Aplicação proposta:** estrutura do app, sistema de design, módulos funcionais,
dados/API e integração nativa com responsabilidades explícitas. O backend
continua responsável pelas regras comerciais e persistência. **Limite:** nomes
de diretórios, controladores e bibliotecas de estado ainda não foram escolhidos.

### P-04 — Adaptar à largura e à plataforma

Fontes: [Flutter — General approach](https://docs.flutter.dev/ui/adaptive-responsive/general)
e [Platform adaptations](https://docs.flutter.dev/ui/adaptive-responsive/platform-adaptations).

**Aprendizado:** compartilhar conteúdo e dados permite composições diferentes
conforme o espaço e as formas de interação disponíveis.

**Aplicação:** navegação inferior no celular, lateral em área ampla e refluência
no Windows estreito. Considerar toque, mouse, teclado, escala de texto e áreas
seguras. **Limite:** escolher apenas pelo sistema operacional deixa de atender
redimensionamento; simular largura de iPhone não valida plugins/permissões iOS.

### P-05 — Destinos reconhecíveis e navegação estável

Fonte: [Apple — Tab bars](https://developer.apple.com/design/human-interface-guidelines/tab-bars).

**Aprendizado:** destinos principais reconhecíveis e identificados ajudam a
alternar contextos sem perder a orientação.

**Aplicação:** os cinco destinos com ícone e nome; pilha de páginas preservada
por área na demonstração. **Limite:** o agrupamento específico é uma escolha
adaptada ao negócio, não uma exigência de usar exatamente cinco itens.

### P-06 — Profundidade, materiais e movimento com função

Fontes: [Apple — Materials](https://developer.apple.com/design/human-interface-guidelines/materials),
[Adopting Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass),
[Motion](https://developer.apple.com/design/human-interface-guidelines/motion),
[Microsoft — Materials](https://learn.microsoft.com/en-us/windows/apps/design/signature-experiences/materials)
e [Android — Material Design 3](https://developer.android.com/develop/ui/compose/designsystems/material3).

**Aprendizado:** materiais, hierarquia e movimento podem comunicar estrutura e
resposta às ações. Aplicá-los exige preservar legibilidade e contexto.

**Aplicação proposta:** camadas suaves para conteúdo; avaliar vidro em controles
e navegação, com transparência perceptível e alternativa sólida. Cor de fundo
e cor de destaque independentes. **Limite:** CSS com desfoque não reproduz o
material nativo Apple, e referência Compose não implica trocar a tecnologia Flutter.
Fluidez, contraste e custo do efeito no app real continuam por validar.

### P-07 — Seleção adequada ao conteúdo

Fonte: [Apple — Pickers](https://developer.apple.com/design/human-interface-guidelines/pickers).

**Aprendizado:** o controle de escolha deve ajudar a reconhecer valores válidos.

**Aplicação ao briefing:** seletores reais de cliente/cesta, calendário para
período e busca para listas extensas. Datas, moeda e paginação ainda exigem
contratos próprios; a fonte não decide o formato nem as regras do nosso backend.

### P-08 — Preparar apresentação financeira sem inventar efeitos

Fontes locais: [plano financeiro](PLANO_IMPORTACAO_E_CONCILIACAO_FINANCEIRA.md),
[base e conciliação](BASE_FINANCEIRA_E_CONCILIACAO.md),
[importação CSV](IMPORTACAO_CSV_MULTIBANCO.md) e
[pesquisa do incremento financeiro](PESQUISA_PROXIMO_INCREMENTO_FINANCEIRO.md).

**Aprendizado de integração:** documento recebido, interpretação, revisão e
operação financeira confirmada são coisas distintas. Não somar novamente um
pagamento de fatura ou tratar qualquer documento importado como dívida/saldo.
Datas sem horário não recebem horário inventado. Igualdade de data, descrição
e valor não prova, sozinha, que duas operações são a mesma.

**Situação ao consolidar:** os guias de 15/10 descrevem base de conciliação e
leitores CSV implementados no backend, sem telas novas. As migrações preparadas
não comprovam aplicação no banco da empresa. Revalidar os contratos no momento
de projetar as telas; não conservar como verdade atual a observação inicial de
que havia apenas arquivos em elaboração. As pesquisas do outro trabalho seguem
nos documentos citados, sem reproduzir dados de extratos reais aqui.

### P-09 — Qualidade empresarial aplicada à rotina do ZM

Pesquisa em **16/10/2026**, a pedido do usuário. O
[registro completo](PESQUISA_FRONTEND_EMPRESARIAL_2026-10-16.md) reúne quatro
referências verificadas: visão geral do SAP Fiori, estados sem dados e tabelas do
IBM Carbon, tratamento de erros e idempotência da Stripe. Cada entrada separa
recomendação da fonte, aplicação ao ZM e limites; tentativas de acesso sem
conteúdo verificável também estão registradas.

Fontes diretas: [SAP Fiori iOS — Overview](https://www.sap.com/design-system/fiori-design-ios/page-types/overview),
[Carbon — Empty states](https://www.carbondesignsystem.com/building-blocks/core/patterns/empty-states),
[Data table](https://www.carbondesignsystem.com/building-blocks/core/components/data-table/guidelines),
[Stripe — Advanced error handling](https://docs.stripe.com/error-low-level)
e [Idempotent requests](https://docs.stripe.com/api/idempotent_requests).

**Aplicação proposta:** resumo ligado aos registros que o compõem; distinção
entre situação financeira e disponibilidade da consulta; apresentação adaptada
à tarefa; tratamento próprio para uma gravação cujo resultado é desconhecido.
Os guias locais continuam definindo o significado dos números e os efeitos das
operações. Essas propostas não são integração Stripe/SAP/Carbon nem comprovação
de conformidade fiscal. O próximo exemplo sugerido está em FE-019.

### P-10 — Texto dentro do controle e limites da validação por plataforma

Pesquisa e retorno do aparelho em **16/10/2026**, registrados na
[rodada de resumo e data](RODADA_FRONTEND_RESUMO_E_DATA_2026-10-16.md). Fontes:
[MDN — input date](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/input/date),
[estilização de formulários](https://developer.mozilla.org/en-US/docs/Learn_web_development/Extensions/Forms/Advanced_form_styling)
e [dialog](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/dialog).
A caixa externa de um
controle pode estar alinhada mesmo com seu texto interno cortado; medir também
caracteres e espaço para ícones. Não confundir WebKit Windows com o seletor iOS.

**Aplicação:** nesta revisão, botão com texto comum e calendário em diálogo;
valor ISO, revisão, cancelamento e retorno de foco verificados. A escolha é da
amostra HTML, sem decidir antecipadamente o seletor no Flutter. O calendário
novo ainda depende de observação no iPhone; preservar a foto que refutou a
suficiência da abordagem anterior.

### P-11 — Movimento com propósito e sinais diferentes por plataforma

Pesquisa em **16/10/2026**, após a pergunta do usuário. O
[padrão de movimento](PADROES_DE_MOVIMENTO_FRONTEND.md) registra as fontes
primárias Apple/Flutter, sínteses, propostas e limites, incluindo conferência
do SDK local e um cuidado de redução por plataforma a tratar no piloto. Consultar
as evidências nesse arquivo; a inspeção não é homologação do aplicativo iOS.

Fontes diretas: [Apple HIG — Motion](https://developer.apple.com/design/human-interface-guidelines/motion?changes=l_9_3),
[Flutter — Animations](https://docs.flutter.dev/ui/animations/overview)
e [MediaQueryData.disableAnimations](https://api.flutter.dev/flutter/widgets/MediaQueryData/disableAnimations.html).

**Aplicação:** transições opcionais com ações e dados equivalentes em movimento
reduzido. Algumas são demonstradas nesta rodada; medições de duração não provam
fluidez ou taxa de quadros em aparelho real. A futura implementação deve avaliar
reutilização dos componentes atuais e manter a operação independente dos efeitos.

### P-12 — Catálogo como contrato e exemplos de estados

**Consulta em 16/10/2026:** [Storybook — Writing stories](https://storybook.js.org/docs/writing-stories)
e [W3C WAI — User notifications](https://www.w3.org/WAI/tutorials/forms/notifications/).
Síntese, aplicação e limites estão centralizados na seção 7 do
[catálogo](CATALOGO_COMPONENTES_FRONTEND.md). O primeiro fundamenta exemplos
reproduzíveis por estado; o segundo orienta feedback claro e associado aos campos.
São referências de método/acessibilidade, sem instalar bibliotecas ou comprovar
semântica nativa no Flutter.

**Inferência de projeto:** documentar entradas, interações, estados e limites de
responsabilidade de cada padrão; não montar só uma galeria visual. Distinguir
o componente compartilhado das regras e opções do módulo. A amostra vazia usa
uma conta de outra data quando o recorte é ampliado, conservando a coerência
entre o resumo, a lista e os critérios. As novas propostas aguardam retorno.

### P-13 — Contraste por papel e durante mudanças de aparência

**Consulta em 16/10/2026:** [Apple HIG — Color](https://developer.apple.com/design/human-interface-guidelines/color?changes=_2_2),
[Dark Mode](https://developer.apple.com/design/human-interface-guidelines/dark-mode),
[W3C — Contrast Minimum, 1.4.3](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html)
e [Non-text Contrast, 1.4.11](https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html).
Links, síntese, aplicação e limites estão na seção 6 da
[base visual](BASE_VISUAL_FRONTEND.md). A Apple foi consultada por trechos
indexados; as aberturas diretas exigiram JavaScript. Não atribuir à Apple raios
ou a escala numérica proposta para o ZM.

**Aplicação:** separar texto/ação/feedback, separador decorativo/contorno
essencial, aparência clara/escura e cor de origem/tonalidade usada para leitura.
Os testes medem pares resolvidos no navegador. Não são auditoria WCAG integral,
integração nativa de Aumentar Contraste ou homologação de acessibilidade.

**Hipótese superada:** bastaria conferir as cores finais dos tokens e animar
o fundo do botão. A inspeção revelou cores intermediárias de leitura ruim.
A amostra nova troca texto e fundo juntos e verifica botão/data/seleção após
alterar a aparência. Esse aprendizado não demonstra uma falha no Flutter.

### P-14 — Hierarquia por tarefa e texto que reorganiza a composição

**Consulta em 16/10/2026:** [Apple — Dynamic Type, transcrição WWDC24](https://developer.apple.com/videos/play/wwdc2024/10074/),
[SAP — Object Page Header](https://developers.sap.com/concepts/fiori-elements-object-page-header/),
[W3C — Resize Text](https://www.w3.org/WAI/WCAG22/Understanding/resize-text.html)
e [Reflow](https://www.w3.org/WAI/WCAG22/Understanding/reflow.html). Links, data, síntese,
aplicação e limites estão na seção 7 da
[proposta de hierarquia e tipografia](HIERARQUIA_E_TIPOGRAFIA_FRONTEND.md).
HIG Typography e Material 3 não forneceram texto direto completo; não atribuir
a essas aberturas uma validação da escala proposta.

**Aplicação inferida para o ZM:** separar identificação do registro, valor
relevante à tarefa e contexto. Na revisão, dar ênfase ao valor desta operação;
no detalhe, distinguir valor original, pagamentos anteriores e saldo atual.
Papéis semânticos compartilhados não exigem a mesma disposição em toda página.

**Hipótese evitada:** aumentar a letra mantendo sempre as mesmas colunas ou
reduzir automaticamente o texto para conservar uma composição rígida. Planejar
reorganização com conteúdo longo e escala de texto, preservando significado.
Referências de ampliação e largura web são critérios distintos e não equivalem
a teste nativo. Nesta rodada há proposta documental, sem nova evidência visual
ou execução do aplicativo; métricas e família continuam em avaliação.

### P-15 — Composição e continuidade além da aparência de cada tela

**Consulta em 16/10/2026:** [Carbon — Data table](https://www.carbondesignsystem.com/building-blocks/core/components/data-table/guidelines),
[GOV.UK — Check answers](https://design-system.service.gov.uk/patterns/check-answers/)
e [SAP Fiori iOS — List Report](https://www.sap.com/design-system/fiori-design-ios/v26-1/page-types/list-report).
Fontes, síntese, aplicação e limites estão na seção 7 da
[composição das páginas](COMPOSICAO_DAS_PAGINAS_FRONTEND.md). Páginas lidas,
sem execução de exemplos, adoção de bibliotecas ou nova evidência visual.

**Aplicação inferida ao ZM:** lista para localizar/comparar, detalhe com espaço
para origem e histórico, revisão que permite corrigir sem perder preenchimento.
Separar ações da consulta e do registro. Preferir detalhe dedicado nesta primeira
revisão, mantendo expansão e duas áreas como alternativas a avaliar, não requisitos.

**Cuidado de continuidade:** preservar filtros, posição de referência e foco
ao voltar, sem tratar dados antigos como atuais. Um registro confirmado e a
falha posterior de atualização da lista são situações diferentes. Oferecer
atualizar a consulta não pode induzir outro registro do pagamento.
Esse contrato de apresentação é proposto; mecanismos reais de recuperação,
concorrência, idempotência e persistência precisam de conferência antes do piloto.

### P-16 — Antecipação e orientação informativa por dados

Pesquisa em **16/10/2026**, com fontes primárias de autoria/documentação:
[Aaron Shapiro — Design antecipatório](https://www.fastcompany.com/3045039/the-next-big-thing-in-design-fewer-choices),
[SAP — Overview Pages](https://learning.sap.com/courses/discovering-sap-s-4hana-embedded-analytics/working-with-overview-pages_be723c43-51c9-46cd-bd7e-20973fb41aff),
[Situation Handling](https://help.sap.com/docs/SAP_S4HANA_CLOUD/a630d57fc5004c6383e7a81efee7a8bb/516c8ecb7462453ca430a42481cc33ec.html),
[Carbon — Notification](https://www.carbondesignsystem.com/building-blocks/core/components/notification/guidelines),
[GOV.UK — Notification banner](https://design-system.service.gov.uk/components/notification-banner/)
e [W3C — Status Messages](https://www.w3.org/WAI/WCAG22/Understanding/status-messages.html).
Fundamentação, fontes, forma de acesso, limites, exemplos e síntese aplicada ao
ZM estão nas seções 3–12 do
[documento específico](DESIGN_INTELIGENTE_E_ORIENTACAO_AO_USUARIO.md).
Ler essa referência para continuar o trabalho; não tratar este apontamento como
substituto do entendimento detalhado. Código do resumo foi apenas inspecionado
para distinguir dados existentes de propostas; não houve teste do aplicativo.

### P-17 — Regra verificável e destino compatível com os dados disponíveis

Consulta/inspeção em **16/10/2026**. Fontes primárias locais:
[serviço de resumo](../backend/app/services/business_dashboard.py),
[schemas](../backend/app/schemas/business_dashboard.py),
[registros do relatório](../backend/app/schemas/reports.py),
[serviço de estoque](../client/lib/services/inventory_service.dart),
[tela de estoque](../client/lib/views/inventory_summary_view.dart) e
[API de detalhe da venda](../backend/app/api/v1/sales.py).
Referência externa lida: [GOV.UK — Warning text](https://design-system.service.gov.uk/components/warning-text/).
Aplicação, demais fontes diretas e limites estão nas
[regras iniciais](REGRAS_DE_INFORMACAO_UTIL_FRONTEND.md).

**Achados:** atraso se refere à data de negócio atual; pendências atuais não
seguem o período histórico das vendas. Custo incompleto é classificação do
serviço (venda sem itens ou algum item com custo total não positivo), não simples
ausência de um campo. A contagem não fornece automaticamente IDs afetados.
O estoque tem filtro existente, mas isso não comprova navegação pré-filtrada.

**Aplicação proposta:** cada orientação tem condição e destino honestos. Explicar
limitação de custo antes de prometer investigação/correção inexistente. Registrar
lacunas de data/atualidade e navegação para a integração. Casos e exemplos foram
planejados; não foram testes de execução ou homologação do aplicativo.

### P-18 — Hierarquia aplicada e adaptação de texto — FE-048

Consulta dirigida em **16/10/2026**, aproveitando P-14/P-15:
[W3C WAI — Text Spacing, SC 1.4.12](https://www.w3.org/WAI/WCAG22/Understanding/text-spacing.html),
seções Success Criterion/Intent, e [WHATWG — HTML Standard, The wbr element, 4.5.28](https://html.spec.whatwg.org/multipage/text-level-semantics.html#the-wbr-element).
A primeira fundamenta testar espaçamento alterado sem perda de conteúdo/função;
esses valores não precisam ser o desenho padrão. A segunda define oportunidade
de quebra, sem prescrever quebra em dinheiro. Usá-la entre grupos de milhares
é inferência do agente, sujeita à avaliação de conforto e leitura assistiva.
O detalhe, fontes e limites permanecem na
[hierarquia](HIERARQUIA_E_TIPOGRAFIA_FRONTEND.md#9-comparação-aplicada-à-fonte-integrada--fe-048)
e na [rodada visual](referencias_frontend/rodada-tipografia-2026-10-16/README.md).

Aplicação: apoios 14, rótulos/corpo 16, seções 18 e valor central 28 propostos;
conteúdo pode empilhar, sem diminuir a fonte nem abreviar dinheiro. Uma cifra
extrema a 200% em largura estreita ocupa várias linhas: sem corte não significa
confortável. O controle da amostra amplia conteúdo; navegação global e escalas
de plataforma continuam pendentes. Não atribuir esses tamanhos às fontes.

## 6. Aprendizados técnicos das prévias

**FE-048:** comparação sincronizada permite avaliar as duas leituras na mesma
etapa sem apagar rascunho; o caso extremo tem troca explicitamente identificada
como reinício do exemplo. O WebKit nativo contribuía com largura extra ao pintar
uma opção longa de `select`, apesar da caixa caber. Coluna limitada não bastou;
aparência controlada com o mesmo seletor e indicação decorativa resolveu a
contribuição excedente, preservando cópia legível da opção ampliada. É evidência
da prévia local, sem reprodução Flutter/iPhone. A captura da referência também
precisou aguardar o comparador renderizar para evitar medida zero do teste.

**Complemento FE-029:** chamar diretamente o callback de uma classe simulada
não valida o caminho do painel. A revisão usa o `tweak.js` original 1.0.50 com
provedor de anotações simulado e reproduz a colisão edição/restauração na fonte
antiga. A nova fonte evita reaplicar ecos conhecidos, mantém restauração nova e
aplica valores nos componentes reconstruídos. Detalhes, limites e artefatos:
[rodada de ajustes](RODADA_FRONTEND_AJUSTES_2026-10-16.md). Não atribuir ao usuário
uma escolha só porque o painel publicou valores enquanto a tela estava defeituosa.

A [rodada de Pagar](RODADA_FRONTEND_PAGAR_2026-10-15.md) acrescenta pesquisas
GOV.UK sobre conferência e resumo de erros e W3C sobre mensagens de status.
Registra também a correção de aviso que permanecia depois de corrigir o campo,
a distinção entre total do período e filtro da lista, e os limites da simulação.
A [revisão de integral/parcial](RODADA_FRONTEND_INTEGRAL_2026-10-16.md) acrescenta
referências Apple de seleção e movimento, prioridade ao caso comum, tratamento
de valor oculto, saldo restante e esclarecimento da fidelidade visual.
A correção posterior da data acrescenta o relato WebKit 301648 e a distinção
entre testar limites da janela, limites do campo e o controle nativo da plataforma.
O WebKit Windows instalado apresentou fallback de texto: não chamar isso de
validação do calendário nativo iOS. Ver evidências e limites no registro da rodada.

Estes pontos são sobre as demonstrações HTML, não sobre defeitos comprovados no Flutter.

1. **Ajustes pareciam desconectados:** a restauração substituía o objeto de design
   ao qual os controles estavam ligados. A revisão manteve a identidade do objeto
   com `Object.assign`, atualizando suas propriedades. A verificação controlada
   alterou espaçamento e cantos, restaurou estado e voltou a alterar os controles.
2. **Vidro pouco distinguível:** sombras e degradês opacos não demonstravam o
   material pedido. A revisão passou a usar preenchimento com alfa e desfoque,
   independentes de fundo e destaque. Avaliar o efeito sobre conteúdo que permita
   perceber transparência; manter superfícies de leitura confortáveis.
3. **Estado da prévia e decisões de projeto:** restaurar preferências não deve
   recriar um vínculo inválido nem disparar uma sequência de gravações. Persistir
   em ações explícitas e evitar ciclos de restauração. Ajustes experimentais do
   painel não são aprovação automática de tokens do produto.
4. **Ambiente de demonstração:** o contêiner de teste usava iframe com restrições
   a formulários. Aplicar filtros precisou de botão e ação explícita, sem depender
   apenas de envio nativo do formulário. O fechamento externo do calendário usou
   o caminho do evento (`composedPath`) para não confundir elementos reconstruídos.
5. **Separar tema do exemplo e tema do chat:** o produto demonstrado mantém suas
   cores e variáveis próprias. Claro/escuro/personalizado devem ser escolhas
   compreensíveis, sem depender exclusivamente da aparência do hospedeiro.
6. **Ferramentas e plataforma:** verificar JavaScript e navegação em navegador
   ajuda a encontrar falhas da prévia. Isso não equivale a testar o painel nativo
   de ajustes do chat, o Flutter ou um dispositivo iOS. Evitar pedidos repetidos
   para verificações cujo escopo já esteja autorizado; quando houver bloqueio
   real de ferramenta, identificar a ação e o motivo concretos.

## 7. Evidências preservadas e seus limites

**Incremento FE-054:** [registro de validação](validacoes_frontend/fe-054-receber-2026-10-17/README.md), código e capturas de widgets com dados de teste. Não comprova instalação ou teste físico.

**Incremento real FE-053:** [registro de validação](validacoes_frontend/fe-053-piloto-pagar-2026-10-16/README.md).
Os relatórios distinguem suítes do backend e Flutter, análise estática, capturas
de widgets com fixtures e compilação Windows. Ler resultados e limites no registro;
não confundir compilação local com instalação ou operação no banco da empresa.

**Rodada vigente FE-052:** [acabamento integrado](referencias_frontend/rodada-acabamento-2026-10-16/README.md).
Relatórios separam regressão do conjunto, filtros/material/contraste e saúde do
projeto. Proveniência e manifesto identificam derivação direta de FE-049 e fontes
históricas intactas. Consultar números efetivos e limites na própria evidência;
simulação não comprova envio financeiro ou preferência de material nativos.

**Inspeção anterior FE-050:** [inspeção e saúde](validacoes_frontend/fe-050-jornadas-2026-10-16/README.md),
com hashes e marcadores de 19 fontes locais e resultados resumidos das suítes:
363 backend/238 Flutter aprovados. Os 18 arquivos do manifesto FE-049 coincidem
com os hashes preservados. Sem nova execução visual, aparelho real ou novos
testes dos contratos propostos. O [contrato das jornadas](JORNADAS_FINANCEIRAS_E_PRONTIDAO_DO_PILOTO.md)
liga cada achado ao código primário e distingue inferências/recomendações.

**Referência visual FE-049:** [organização integrada](referencias_frontend/rodada-organizacao-2026-10-16/README.md),
cinco grupos/90 composições por Edge/WebKit (180 no total), sem erro JavaScript.
Home, períodos e recortes, atenção atual, resultado em Negócio, contexto por área,
medidas da barra, parcial/revisão/edição e restauração do período foram conferidos.
Capturas claras/escuras da home e Negócio no celular/computador inspecionadas.
Fonte reproduzida com bytes idênticos; 18 arquivos preservados por manifesto,
mais README/manifesto. Testes existentes 363/238 aprovados; sem implementação
Flutter/API, aparelho nativo, dados da empresa ou commit Git.

**Rodada FE-048:** [comparação integrada de tipografia](referencias_frontend/rodada-tipografia-2026-10-16/README.md),
640 composições no total, cinco grupos principais e três de continuidade por
motor Edge/WebKit, sem erro JavaScript observado. Geometria/estilos da barra e
bytes das cinco capturas de botões coincidem com a recuperação em 1024/claro/100%,
nas duas leituras. Há ensaio separado de espaçamento na home e restauração sem
gravação extra, rascunho, ajustes após restauração e Receber integral. Capturas
de home clara/escura/Windows, composição financeira e casos extremos inspecionadas.
Não há teste de navegação ampliada global, leitor de tela, aparelho ou API.
Saúde do app existente conferida: 363 backend/238 Flutter aprovados, sem usar
o banco da empresa; não comprova implementação da proposta. Fonte histórica,
origem, extensões e evidências arquivadas localmente; sem commit Git.

As [cópias no projeto](referencias_frontend/README.md) incluem as duas prévias
mais recentes, seus contêineres de teste, capturas, scripts e o briefing original.
O [manifesto](referencias_frontend/manifesto.json) registra origem e SHA-256;
na consolidação, as 11 cópias foram comparadas com os originais.

Evidências registradas durante a rodada de 15/10/2026:

- Navegação: Início → Financeiro → Pagar → detalhe → voltar; Estoque → Cestas
  e montagens; preservação do contexto ao alternar áreas; acesso a Receber.
- Adaptação da prévia: larguras externas 780, 412, 360 e 320; no contêiner de
  teste, larguras internas 748, 380, 328 e 288. Sem transbordamento horizontal
  detectado nos casos verificados; navegação compacta/lateral e tema escuro inspecionados.
- Controles: espaçamento e raio efetivos antes/depois de restaurar estado;
  fundo escuro/personalizado, destaque independente e CSS com alfa/desfoque.
  O vínculo com os ajustes foi testado por uma simulação controlada; o painel
  nativo do hospedeiro não foi automatizado.
- Baseline histórico antes da documentação: 279 testes backend e 238 Flutter
  aprovados. Não são contagens permanentes nem validação da nova interface.

Essas verificações históricas não foram reexecutadas na consolidação documental.
A verificação desta consolidação é integridade das cópias, leitura dos arquivos,
ligações locais e coerência do registro. Não houve alteração de código funcional.

**Rodada posterior de Pagar, ainda em 15/10/2026:** 5 grupos de verificação e
32 combinações de estado/largura aprovadas, sem erros JavaScript observados.
O [relatório](referencias_frontend/rodada-pagar-2026-10-15/jornada-pagar-verificacao.json)
e 13 cópias da rodada foram preservados em subpasta própria; o manifesto inicial
e suas 11 referências continuam intactos. A evidência é da prévia, não do app real.

**Rodada de 16/10/2026:** 7 grupos de verificação e 40 combinações de estado/largura
aprovadas, sem erros JavaScript observados. O
[relatório](referencias_frontend/rodada-integral-2026-10-16/pagamento-integral-verificacao.json)
cobre integral sem digitar, parcial revelado, valor oculto ignorado, saldo restante,
redução de movimento e Tab, além do percurso anterior. Quinze cópias, incluindo
a referência enviada pelo usuário, foram preservadas com manifesto próprio.

**Correção posterior da data:** 64 casos de alinhamento aprovados em Edge e
WebKit Windows, mais preservação do valor ao revisar/editar e verificação com
valor vazio. A condição de excesso foi forçada como estresse; o defeito nativo
iOS não foi reproduzido localmente. Dez cópias foram preservadas em arquivo próprio.

**Pesquisa empresarial posterior em 16/10/2026:** novo registro de fontes e
roteiro proposto, com atualização dos documentos de continuidade. Sem nova
prévia, testes do navegador ou execução de suítes do app nesta rodada.

**Rodada visual posterior em 16/10/2026:** o usuário autorizou o roteiro e enviou
nova foto da data defeituosa. Foram preservadas 19 cópias em
[arquivo próprio](referencias_frontend/rodada-resumo-e-data-2026-10-16/README.md).
O relatório contém 64 casos de geometria do texto e oito grupos por motor, sem
erros JavaScript observados. Inclui calendário, resumo/lista/origem, integral,
parcial, consulta vazia/indisponível e vínculo de ajustes após restauração simulada.

**Rodada de Receber posterior em 16/10/2026:** usuário confirmou integral para
fiado; amostra com origem e movimento criada. Foram preservadas 18 cópias em
[arquivo próprio](referencias_frontend/rodada-receber-2026-10-16/README.md), com
sete grupos por motor e 32 combinações de layout, sem erros JavaScript observados.
O teste aguarda a mudança assíncrona da preferência de acessibilidade e verifica
que os recebimentos atualizam A receber, preservando a referência de A pagar.

**Rodada do catálogo em 16/10/2026:** FE-025 autoriza continuidade; proposta de
componentes/estados documentada e demonstrada em três famílias. O
[arquivo próprio](referencias_frontend/rodada-catalogo-2026-10-16/README.md)
preserva 23 cópias. Verificação final: oito grupos por motor Edge/WebKit,
96 combinações de família/largura/tema/texto, sem erros JavaScript observados.
Inclui confirmação pendente/verificação simuladas e consulta anterior, sem
comprovação de API ou cache. A reserva de altura recebeu ajuste para não gerar
aviso de ResizeObserver; o relatório final é posterior à correção. Formulário,
mensagens, tabela e temas foram inspecionados. Sem suítes Flutter/backend nesta
rodada, que não alterou código funcional do aplicativo.

**Evidência da base visual, 16/10/2026 (FE-027):**
[20 cópias preservadas](referencias_frontend/rodada-base-visual-2026-10-16/README.md),
com cinco grupos por motor Edge/WebKit, 96 combinações de layout, 768 pares de
contraste e nenhum erro JavaScript observado na revisão final. Inclui medidas
efetivas, troca de tema sem interpolação isolada de fundo, foco/rascunho mantidos,
redução e restauração instrumentada. Formulário, temas e lista foram inspecionados.
Sem integração Flutter/API ou suítes do aplicativo nesta rodada.

## 8. Pendências que não podem desaparecer

**Evidência histórica, FE-041:** [Negócio em foco](referencias_frontend/rodada-negocio-em-foco-2026-10-16/README.md),
14 cópias preservadas, quatro grupos por motor Edge/WebKit, 40 combinações de
layout no total e nenhum erro JavaScript observado. Dez capturas inspecionam
visão geral, temas, Windows, formulário e calendário. Helper original com
provedor simulado; sem homologação de aparelhos ou integração Flutter/API.
Próximo passo é revisar a prévia com o usuário, não ampliar automaticamente o
escopo documental ou iniciar o piloto. A evidência FE-028/FE-029 abaixo é histórica.

**Evidência histórica, FE-028/FE-029:**
[27 cópias](referencias_frontend/rodada-ajustes-2026-10-16/README.md), incluindo
captura do usuário. Sete controles conferidos com helper original em Edge/WebKit
e defeito reproduzido na fonte anterior. Regressão revisada: cinco grupos por
motor, 96 layouts e 768 pares de contraste, sem erros JavaScript observados.
O provedor de anotações é simulado; painel da janela do usuário não automatizado.
Os resultados anteriores de classe simulada não bastam como evidência desse
trajeto. Nenhuma alteração no Flutter/API ou em dados reais.

| Tema | Estado e próximo cuidado |
| --- | --- |
| Jornada de Pagar | Conferência e integral por padrão aceitos; amostra de resumo/data aceita como referência. Tokens finais, data/hora e resposta desconhecida seguem por especificar antes do piloto. |
| Data na prévia do iPhone | Amostra posterior com calendário aceita como referência; não confundir aceitação visual e teste local com homologação Flutter/iOS. |
| Receber | Integral confirmado e amostra aceita como referência. Receber por várias vendas, estorno e data/hora/fuso precisam de contrato antes da integração correspondente. |
| Movimento | Demonstração aceita como referência; consolidar tempos e curvas compartilhados e verificar sinais reais por plataforma antes do piloto. |
| Piloto real | Contas a Receber foi candidato no estudo inicial. Escolher novamente após avaliar as jornadas do Financeiro. |
| Tokens e temas | Fechar cores semânticas, tipografia, espaço, formas, profundidade e redução de movimento por amostras. A preferência pela aparência não fixa cada valor. |
| Filtros | Rascunho/Aplicar/Limpar/Atualizar propostos; revalidar a mudança em relação à tela atual. Filtros por valor em Receber hoje se referem ao valor original. |
| Totais | Não chamar de global uma soma da página carregada. Período, moeda, cobertura e origem precisam estar claros. Dado indisponível não vira zero. |
| Amostra de resumo | FE-021: aceita como referência após a demonstração. Prioridade global dos indicadores e tokens finais continuam por fechar. |
| Resultado desconhecido ao salvar | Especificar antes do piloto real. Pagar/Receber simulam falha conhecida antes de gravar; o catálogo acrescenta perda de resposta/verificação simuladas. Não comprova recuperação real nem persistência da identidade após reiniciar. Revalidar o contrato local. |
| Catálogo mínimo | Documentado e demonstrado em FE-025; direção/apresentação aceitas como referência em FE-026. Alinhar base visual e detalhes técnicos. Dez padrões candidatos não equivalem a classes novas já implementadas. |
| Base visual | FE-028 confirma espaço 20 e destaque configurável com azul original por padrão. FE-029 corrige a prévia; FE-030 confirma campos 24 e painéis 32. Fundo continua por fechar. Acessibilidade e políticas nativas seguem próprias do piloto. |
| Hierarquia e tipografia | FE-033 registra proposta por família e escala inicial, com pesquisa e limites. FE-041 apresenta a proposta no conjunto conectado; aguardar avaliação sem tratar tamanhos e composição como aprovados. |
| Composição e continuidade | FE-034 detalha blocos e retorno, com pesquisa e alternativas. Roteiro do conjunto conectado preparado; novos arranjos, persistência de rascunho e contratos de concorrência/recuperação ainda por avaliar. Sem prévia nesta rodada. |
| Compras em rascunho | Relatos sobre ausência de editar/excluir e aparência de pago/liquidado estão adiados. Não provar débito apenas pelo texto da interface. |
| Datas e pagamento de compras | Distinguir compra, vencimento e pagamento efetivo. A transcrição do briefing alterna sentidos da data do boleto; perguntar ao retomar esse fluxo. |
| Histórico e preservação | Uma adaptação de interface não pode apagar dados, romper vínculos ou restaurar funções arquivadas automaticamente. |
| iOS | Integração nativa, permissões, plugins, arquivos, câmera, impressão e validação no ambiente Apple ainda serão uma entrega própria. |
| Dependências com outros trabalhos | Cestas/montagens, importação financeira e impressão têm alterações de outros chats. Consultar guias atuais e preservar mudanças locais. |

## 9. Manutenção obrigatória deste conhecimento

**FE-037:** conceitos importantes têm referência específica e aprofundada. Esta
memória mantém índice, decisões e estado; não substituir o documento de design
inteligente ou futuras referências importantes por seus resumos. Conservar a
fundamentação, exemplos, limites e evolução que permitem aos agentes compreender
e aplicar o conhecimento depois da compactação.

Seguir também o **método de planejamento da seção 8.1** do
[manual](ARQUITETURA_FRONTEND.md), FE-035, referenciado nas instruções de entrada.
Pesquisa deve responder dúvidas relevantes; confirmação não significa pedir
aprovação a cada ajuste; prévias continuam agrupadas conforme FE-032/FE-034.

Ao encerrar cada rodada de alinhamento ou pesquisa relevante:

1. Registrar **data, pergunta/problema, fonte do retorno, decisão ou hipótese,
   motivo, alcance e situação**. Distinguir escolha do usuário de sugestão do
   assistente; não converter silêncio ou valores do painel em aprovação.
2. Para pesquisa, registrar **link direto e clicável da fonte original, título/
   autor ou organização, data da consulta, síntese, aplicação ao ZM e limite**.
   Indicar seção/página relevante quando útil. FE-038 exige os links junto do
   aprendizado, mesmo quando houver documento interno com a fundamentação.
   Separar afirmação da fonte de inferência de projeto. Se uma hipótese
   for descartada, preservar o motivo, sem mantê-la como orientação vigente.
3. Atualizar o manual quando mudar uma regra vigente e o plano quando mudar a
   sequência. Referenciar os mesmos IDs; não criar versões contraditórias.
4. Guardar a prévia correspondente e suas evidências com identificação da rodada.
   Conservar versões históricas; nova revisão recebe nome/data próprios ou
   histórico verificável. Nunca depender só da pasta temporária de um chat.
5. Atualizar o estado da próxima sessão: **última decisão, próxima pergunta,
   artefato esperado, pendências e escopo autorizado**. Isso vem antes de retomar
   implementação em uma conversa nova ou após compactação.
6. Revalidar fatos mutáveis no código e nas fontes necessárias. Não perpetuar
   contagens de testes, contratos em evolução ou estado de outro chat como atuais.
7. Usar exemplos fictícios nos artefatos. Não copiar tokens, credenciais ou
   documentos bancários reais para este registro.

Não é necessário pedir ao usuário para repetir o contexto já documentado.
Perguntas ficam para lacunas reais, conflitos ou decisões novas. Arquivos salvos
no diretório do projeto não constituem, por si só, commit ou backup externo.
