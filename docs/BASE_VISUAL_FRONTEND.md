# Base visual: cores, formas e espaçamento

**Continuação vigente FE-052:** usuário rejeitou o espaço tomado pelos filtros
da captura inicial e pediu adiantar os ajustes respeitando os acordos. A
[revisão integrada de acabamento](referencias_frontend/rodada-acabamento-2026-10-16/README.md)
reúne vidro suave, fundo azul/quente e listas financeiras como extrato. Filtros
fechados por padrão, com recorte visível e opções sob demanda. Leitura recuperada,
navegação, dimensões e jornadas preservadas. Demonstração agrupada, não tema
implantado no Flutter; FE-051 abaixo registra a origem da preferência.

**Retorno FE-051 — acabamento de vidro:** usuário trouxe uma captura do estudo
inicial de Contas a Receber e destacou cores, glasslike e apresentação das contas
semelhante a aplicativo bancário. Isso acrescenta uma preferência visual à
organização FE-049 e à Leitura recuperada. Ver seção 8 para a análise e a proposta
de aproveitamento; a nova combinação ainda não foi demonstrada ou implementada.

**Continuação FE-049:** usuário escolheu **Leitura recuperada**, com a leveza e
o equilíbrio existentes, e acolheu a organização integrada. A
[revisão atual](referencias_frontend/rodada-organizacao-2026-10-16/README.md) usa
essa leitura, Início curto com períodos e Negócio para vendas/clientes/resultado.
As medidas confirmadas abaixo permanecem. Não reabrir escolhas visuais como
questionário; investigar lacunas concretas no componente e na plataforma.

Revisão: **16/10/2026**. Versão: **0.4 — medidas confirmadas e acabamento integrado demonstrado**.
FE-027 autoriza a próxima rodada de planejamento, após o catálogo aceito como
referência em FE-026. A continuação após interrupção preserva esse mesmo escopo.

**FE-028/FE-029:** o usuário escolheu espaço **20**, confirmou destaque escolhível
nas configurações do app com azul original **#2866ae** por padrão e relatou outros
controles sem efeito. A [rodada de correção](RODADA_FRONTEND_AJUSTES_2026-10-16.md)
registra reprodução e revisão. Naquele retorno, fundo e raios testados não eram
valores finais. **FE-030:** o usuário confirmou depois **campos 24 px** e
**painéis 32 px**. Fundo continua em avaliação. A pergunta sobre movimento
compartilhado foi esclarecida; não define uma escolha de modo ou nova configuração.

Esta proposta aplica papéis visuais compartilhados às amostras já conhecidas.
Não muda regras, serviços ou telas do Flutter. Referências:
[manual](ARQUITETURA_FRONTEND.md), [catálogo](CATALOGO_COMPONENTES_FRONTEND.md),
[memória](MEMORIA_E_PESQUISAS_FRONTEND.md),
[valores estruturados propostos](TOKENS_VISUAIS_PROPOSTOS.json) e
[prévia revisada](referencias_frontend/rodada-ajustes-2026-10-16/README.md).

## 1. Pergunta desta rodada

Alinhar uma base elegante, consistente e legível para os componentes aceitos,
observando como cores, curvas e espaços trabalham juntos. O exemplo tem três
entradas: Formulário, Estados dos controles e Lista e detalhe. Mantém dados e
interações do catálogo; não abre um novo módulo nem altera suas regras.

O painel de design compartilha **sete ajustes** entre as três entradas:
aparência, fundo, cor de destaque de origem, espaço entre campos, cantos de
painéis, cantos de campos e movimento. Mudar esses ajustes conserva rascunho e
contexto; o mesmo objeto de escolhas é mantido ao restaurar a amostra. Não há um
segundo painel de design dentro do produto.

Os ajustes particulares do exemplo continuam disponíveis: Recebimento/Pagamento,
resposta simulada à confirmação e situação da consulta. Não são novas opções
de configuração do aplicativo. O usuário ainda escolherá a base final; valores
testados ou movidos no painel não viram aprovação automática.

## 2. Proposta recomendada como ponto de partida

| Papel | Proposta | Motivo |
| --- | --- | --- |
| Fundo | Superfície neutra suave, com opção branco/preto na comparação. | Dar descanso visual sem tingir toda a tela de azul. |
| Superfície | Painéis próprios, opacos e elevados de forma discreta. | Separar conteúdo e campos com leitura previsível. |
| Texto principal | Escuro no tema claro, claro no escuro; valores financeiros neutros. | Priorizar a informação e não dar significado financeiro pela cor de destaque. |
| Texto secundário | Menor ênfase, com contraste de leitura preservado. | Ajudas, rótulos e referências não podem desaparecer sobre o fundo. |
| Destaque | Azul original #2866ae por padrão; usuário escolhe nas configurações do app. | Requisito confirmado em FE-028; configuração real ainda por implementar. |
| Avisos e resultado | Pares próprios de texto/fundo para atenção, erro e sucesso; sempre com mensagem. | O significado continua estável quando a identidade visual muda. |
| Contorno de campo | Linha fina mais perceptível, distinta da linha de separação. | Identificar a área editável sem depender de uma sombra. |
| Curvas | Painéis 32 e campos 24; escolha/ação de uma linha em cápsula. | Raios de painéis/campos confirmados em FE-030; preservar o arredondamento apreciado. |
| Espaço | 20 entre grupos de campos; rótulo/controle próximos. | Escolha confirmada em FE-028; validar unidades lógicas no piloto. |

As superfícies continuam propostas do assistente. A direção arredondada/elegante,
os raios 32/24, o espaço 20 e o requisito de preferência de destaque foram
confirmados; demais medidas continuam em avaliação.
Os três exemplos usam as mesmas definições, sem trocar a aparência do aplicativo
real. O estudo anterior de vidro continua preservado; sua aplicação a navegação
e superfícies próprias terá avaliação separada, sem tornar campos transparentes
automaticamente.

## 3. Cores por função e pares de aparência

Usar papéis como `surface.page`, `surface.panel`, `surface.field`,
`text.primary`, `text.secondary`, `control.edge`, `separator`, `action.accent`
e `feedback.warning`. A página escolhe o papel, em vez de repetir um hexadecimal.

Separador decorativo e contorno essencial são papéis diferentes. A linha suave
que organiza um detalhe pode ser discreta; o limite necessário para perceber
um campo deve continuar visível. A nova amostra propõe borda de campo clara
#7d8796/escura #7a8495, conservando separadores suaves. Não aplicar esse ajuste
retroativamente às cópias históricas do catálogo.

A cor escolhida no painel é uma **origem** para o destaque. A amostra deriva
tonalidades próprias para cada tema, conservando contraste com seus fundos e
com o texto da ação. Assim, uma origem muito clara não produz texto branco
ilegível sobre botão claro. O algoritmo demonstrado e os papéis estão no
[arquivo estruturado](TOKENS_VISUAIS_PROPOSTOS.json); a implementação Flutter
definitiva ainda será alinhada.

Sucesso, alerta e erro não são recalculados a partir do destaque. Situações
neutras da lista ficam neutras; vencimento continua acompanhado da palavra
Vencida. Valores em aberto não se tornam verdes só porque a pessoa escolheu
um destaque verde. Texto, situação e forma de interação conservam seu sentido.

Fundo branco/preto é uma comparação de aparência. Não entrega integração com
a opção nativa Aumentar Contraste. Cores dinâmicas, configurações assistivas e
contraste em todos os estados ainda precisam de conferência na plataforma.

## 4. Escala e geometria propostas

O arquivo estruturado registra uma escala inicial de espaço 4/8/12/16/20/24/32,
com exceções explícitas da amostra, como a distância rótulo/controle de 9.
Harmonizar essas exceções ao fechar o primeiro conjunto; não fingir que o estudo
já tem todos os tamanhos resolvidos.

| Elemento | Referência inicial | Comparação disponível |
| --- | --- | --- |
| Espaço entre grupos | 20, confirmado | 16 a 32 na comparação; não altera o tamanho da fonte. |
| Margem interna de painel | Até 24; até 20 quando estreito | Acompanha espaço com limite próprio. |
| Margem lateral de página | 20; 14 quando estreita | Adapta a área útil sem cortar controles. |
| Canto de painel | 32, confirmado | 24 a 40 na exploração da prévia. |
| Canto de campo | 24, confirmado | 20 a 32 na exploração; altura cresce com texto quando necessário. |
| Campo comum | Referência mínima 56 | Altura cresce para caber texto; não impor altura fechada. |
| Ação/toque | Referência mínima 44 na amostra, com campos normalmente maiores | Validar alvos e áreas seguras conforme a plataforma. |

As medidas são CSS px da apresentação. Na integração, usar unidades lógicas,
escala de texto, largura útil e recomendações da plataforma; não converter por
densidade física de tela de forma automática. A lista pode virar tabela quando
houver espaço para comparar os registros, mantendo os mesmos dados.

## 5. Movimento e troca de aparência

Movimento continua regido pelo [padrão específico](PADROES_DE_MOVIMENTO_FRONTEND.md).
Uma troca de tema/destaque atualiza texto e fundo juntos. A primeira inspeção
mostrou que animar só o fundo de botões deixava cores intermediárias pouco
legíveis, mesmo quando os pares finais passavam no cálculo.

A revisão remove a interpolação isolada de cor nessas trocas. Conserva resposta
de toque, revelação e navegação conforme a política de redução. O teste passa
a conferir também cores efetivamente calculadas no botão, na data e na opção
selecionada imediatamente após a mudança, além dos tokens finais.

Essa correção é da nova prévia. Não demonstra que a mesma falha existia no
Flutter ou autoriza trocar todas as animações do aplicativo.

## 6. Pesquisa e aplicação ao ZM

Fontes primárias consultadas em **16/10/2026**:

- [Apple HIG — Color](https://developer.apple.com/design/human-interface-guidelines/color?changes=_2_2)
  e [Dark Mode](https://developer.apple.com/design/human-interface-guidelines/dark-mode):
  descrevem uso coerente de papéis e variantes por aparência. **Aplicação:**
  separar fundo/texto/ação/feedback e oferecer pares claro/escuro. **Limite:**
  foram lidos os trechos indexados; abertura direta exigiu JavaScript e o link
  Markdown não forneceu conteúdo. Não copiar valores de sistema ou afirmar
  integração com APIs nativas a partir desses trechos.
- [W3C — Contraste de texto, 1.4.3](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html):
  orienta ao menos 4,5:1 no texto comum, com exceções como texto grande.
  **Aplicação:** usar 4,5:1 nos pares de texto previstos, incluindo ajuda,
  placeholder, seleção e texto de ação. **Limite:** é um critério entre vários;
  não transforma esta amostra em certificação WCAG do produto.
- [W3C — Contraste não textual, 1.4.11](https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html):
  trata indicadores necessários à identificação de componentes/estados, com
  referência de 3:1 contra cores adjacentes e exceções previstas no critério.
  **Aplicação:** verificar o contorno essencial dos campos separadamente do
  contraste do texto. **Limite:** não exigir 3:1 de todo separador decorativo nem
  tratar pares isolados como auditoria de todos os estados da interface.

**Inferência de projeto:** suavidade deve vir de espaço, hierarquia e
profundidade, mantendo o texto e o controle perceptíveis. Uma borda mais legível
não exige transformar todos os painéis em contornos fortes. Essas escolhas são
aplicações ao ZM, não raios ou espaçamentos prescritos pela Apple/W3C.

## 7. Evidência e próximo recorte

**Revisão FE-028/FE-029:** [27 cópias preservadas](referencias_frontend/rodada-ajustes-2026-10-16/README.md),
com reprodução/correção usando o helper original e nova regressão. A configuração
base agora usa espaço 20. Verificar os limites no relatório da rodada; a validação
anterior abaixo não cobria a entrega real dos eventos de ajuste.

Fonte, contêiner, script, relatório e imagens da primeira rodada FE-027 ficam em
[pasta própria](referencias_frontend/rodada-base-visual-2026-10-16/README.md).
Relatório final: cinco grupos por motor Edge/WebKit, 96 combinações de layout,
768 pares de contraste e nenhum erro JavaScript observado. Vinte cópias foram
preservadas após a revisão, incluindo 16 capturas.
Verificações locais não comprovam Flutter, UIKit, aparelhos Android/iPhone,
leitor de tela, contraste em todos os estados, cache ou operação financeira.
As escolhas gerais aprovadas continuam preservadas nas rodadas anteriores.

**FE-030:** atualização documental, sem nova prévia ou alteração das fontes
preservadas. A fonte da rodada anterior conserva seu valor inicial de campo 28;
a referência confirmada para a próxima rodada é 24, com painéis 32 e espaço 20.

**Continuação FE-033:** [hierarquia e tipografia](HIERARQUIA_E_TIPOGRAFIA_FRONTEND.md)
pesquisadas e propostas em documento; novos tamanhos/família ainda não confirmados.
FE-034 detalha a [composição das famílias](COMPOSICAO_DAS_PAGINAS_FRONTEND.md)
e prepara o roteiro para revisão visual conjunta, agrupando fundo e movimento
pendentes. Espaço, cantos e preferência
de destaque já foram confirmados. Sem nova prévia nesta rodada, conforme FE-032.
O piloto real continua por escolher e autorizar; não iniciar a
migração global ou novas funções bancárias nesta etapa.

## 8. Aproveitar o acabamento da referência inicial — FE-051

Fonte: captura anexada pelo usuário em 16/10/2026. Referências locais do mesmo
estudo: [direção de vidro](referencias_frontend/direcoes-design-zm-ajustavel.html)
e [captura preservada no celular](referencias_frontend/controls-glass-mobile.png).
A captura anexada tem composição mais larga; a imagem preservada não é seu
arquivo exato. O código do estudo contém fundo radial azul/quente, superfícies
com transparência/desfoque, borda iluminada e sombra. A imagem isolada mostra
a aparência, sem comprovar a técnica de renderização ou os estados nativos.

**Preferência expressa:** usuário achou essa direção bonita, especialmente cores,
vidro e contas com linguagem visual de banco. **Proposta do agente:** conservar
estrutura/navegação atuais e Leitura recuperada, incorporando esse acabamento.
Não há pedido de funções bancárias, nova tipografia ou retorno integral ao layout antigo.

| Qualidade observada | Aproveitamento proposto |
| --- | --- |
| Azul acinzentado com luz quente muito suave | Fundo discreto em áreas vazias, preservando o azul de ação configurável e as cores próprias de situação. O toque quente é decorativo, sem significado de dívida ou resultado. |
| Painéis claros, borda luminosa e sombra difusa | Vidro suave nos resumos e painéis principais. Regular intensidade em conjunto; evitar que cada camada dispute atenção. |
| Campos arredondados com presença tátil | Manter campos 24, painéis 32 e espaço 20 já escolhidos; ajustar superfície/contorno para conservar leitura e identificação do controle. Raios antigos da captura não substituem decisões posteriores. |
| Lista com aparência de extrato | Nome e contexto à esquerda, saldo atual à direita quando couber, situação em etiqueta e separadores finos. No celular estreito/texto maior, reorganizar sem apertar ou cortar os valores. |
| Poucos elementos fortes | Valor e ação ganham ênfase; informações secundárias permanecem leves e legíveis. Preservar Leitura recuperada, sem espalhar negrito. |

Aplicação proposta: Início recebe acabamento nos resumos existentes, preservando
a composição curta; Pagar/Receber recebem a linguagem de extrato; Negócio pode
compartilhar a superfície dos cartões. Campos e linhas financeiras ficam sobre
base suficientemente estável para leitura. Em claro/escuro e quando houver redução
de transparência, ajustar o material e sua alternativa sólida com os mesmos papéis.
Medir contraste e verificar desempenho na etapa correspondente; nada disso foi
homologado pela análise desta captura.

O grande bloco de filtros da referência não deve ser copiado para o Início. Nas
listas, propor acesso compacto com filtros adicionais sob demanda, conservando
os critérios e a identificação do recorte. Essa disposição é recomendação,
não escolha já confirmada pelo usuário.

Próxima revisão visual, caso solicitada: uma composição agrupada derivada da
fonte integrada FE-049, aplicando o acabamento em Início e Financeiro; preservar
barra, destinos, leitura, valores e jornadas para comparar somente o material.
Esta rodada registra análise/preferência, sem nova prévia, alteração dos arquivos
históricos ou código do aplicativo.
