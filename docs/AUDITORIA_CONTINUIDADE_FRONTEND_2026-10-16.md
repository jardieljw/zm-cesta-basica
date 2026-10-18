# Auditoria da continuidade do front-end — 16/10/2026

**Atualização posterior FE-046:** foi criada e verificada a
[prévia integrada recuperada](referencias_frontend/rodada-recuperacao-integrada-2026-10-16/README.md),
com origem no mapa original. O [registro atual](REFERENCIA_ATUAL_FRONTEND.json)
aponta a candidata para revisão. A auditoria e seu relatório abaixo conservam
o estado observado antes dessa recuperação; não foram reescritos como se a
continuidade anterior já estivesse correta. Retorno do usuário ainda pendente.

**FE-045. Motivo:** o usuário apontou regressão da barra lateral e questionou,
com razão, se os códigos, designs, decisões e aprendizados estavam sendo
preservados. Esta rodada confere os arquivos e registra os limites. Não altera
prévias ou aplicativo e não substitui o retorno do usuário por uma aprovação.

## 1. Resultado verificável

A [verificação reproduzível](referencias_frontend/auditoria-continuidade-2026-10-16/verificar_preservacao.py)
e o [resultado detalhado](referencias_frontend/auditoria-continuidade-2026-10-16/resultado-auditoria.json)
conferiram:

| Pergunta | Evidência encontrada | O que isso não prova |
| --- | --- | --- |
| Os arquivos de referência registrados existem? | 11 manifestos, 179 cópias; todas com tamanho e SHA-256 iguais aos registros locais. Incluem código das prévias, contêineres de inspeção, capturas, scripts, relatórios e referências do usuário. | Não prova que toda edição intermediária tenha sido arquivada; manifestos locais não são um histórico independente de alterações. |
| A referência original da navegação foi apagada? | Não. [Fonte original](referencias_frontend/mapa-navegavel-zm.html) presente e correspondente ao manifesto histórico. | Sua preservação não significa que foi respeitada na amostra recente. |
| Há código disponível para recuperar as versões encontradas? | 26 HTMLs na pasta da conversa: 13 fragmentos de prévias e seus 13 contêineres de inspeção. Comparados por conteúdo com os arquivos históricos. | Não afirma que exista uma única versão integrada de todos os avanços. |
| Todos esses HTMLs já estavam arquivados no projeto? | Não. A primeira comparação visual e seu contêiner só estavam na pasta da conversa. Duas cópias adicionais foram preservadas nesta auditoria, sem editar os originais. | Esta recuperação não deve ser apresentada como se o arquivamento anterior já fosse completo. |
| Os registros anteriores de decisões e retornos estão presentes? | FE-001 a FE-044 encontrados uma vez cada na memória. | A memória é uma reconstrução documentada, não a transcrição integral de todas as conversas nem garantia de cada detalhe verbal. |
| Há documentação de arquitetura e aprendizado? | 11 documentos centrais conferidos, incluindo manual, plano, tokens, componentes, movimento, tipografia, composição, design inteligente e regras de informação. Fontes externas estão ligadas nos documentos. | Nesta auditoria não foi reaberta cada fonte externa nem validada cada conclusão de pesquisa. |
| Isso está versionado no Git? | Os 11 documentos centrais consultados estão não rastreados; nenhum arquivo da pasta de referências está rastreado no Git nesta inspeção. | Cópias locais não são um commit nem comprovação de backup remoto. A auditoria não criou commit. |

As duas cópias recuperadas estão em
[fontes recuperadas](referencias_frontend/auditoria-continuidade-2026-10-16/fontes-recuperadas/),
com origem identificável no inventário e hashes no relatório. As duas imagens
que motivaram a cobrança também foram preservadas, com
[registro de integridade](referencias_frontend/auditoria-continuidade-2026-10-16/evidencias-das-barras.json).

## 2. Falhas efetivas de continuidade

**Houve salvamento de código e conhecimento; houve também falha em aplicar a
referência e os acordos na evolução.** A amostra Negócio em foco foi escrita
como outro protótipo, com estrutura/estilos próprios. Os avanços ficaram
distribuídos entre versões e documentos. Isso não constitui uma base única de
front-end implementada, nem garante uma evolução visual cumulativa.

### Barra lateral

As [fontes original](referencias_frontend/mapa-navegavel-zm.html) e
[recente](referencias_frontend/rodada-negocio-em-foco-2026-10-16/negocio-em-foco-zm.html)
declaram estas diferenças na composição ampla:

| Aspecto | Referência original | Amostra recente |
| --- | --- | --- |
| Largura da coluna | 140 px | 174 px |
| Raio do botão de navegação | 12 px | 20 px |
| Conteúdo antes dos destinos | Destinos começam diretamente na barra. | Nome da empresa acrescentado acima dos destinos. |
| Espaçamento interno da barra | 18 px na vertical e 10 na horizontal. | 24 px na vertical e 12 na horizontal. |
| Botões no desktop | Altura mínima 48, espaço interno 10, texto 13. | Outra composição de espaço, texto e alinhamento. |
| Seleção na imagem enviada | Realce amplo dentro da barra, alinhado aos demais itens. | Realce estreito em cápsula e outra posição dos itens. |

Valores declarados no CSS não são medição de pixels físicos no aparelho.
As imagens confirmam a diferença visível; não houve renderização nova nesta
auditoria. Elas estão preservadas como
[referência anterior](referencias_frontend/auditoria-continuidade-2026-10-16/barra-anterior-referencia.png)
e [barra recente relatada](referencias_frontend/auditoria-continuidade-2026-10-16/barra-recente-relatada.png).

Os raios **24 para campos** e **32 para painéis** não autorizam alterar todos
os elementos arredondados. Botões de navegação têm papel próprio. A largura,
marca extra e composição da barra recente não tinham sido alinhadas como
evolução da referência. A cobrança do usuário identifica regressão visual;
não deve ser reduzida apenas à ausência de menus.

### Home, destinos e contexto

FE-042 reincorporou os blocos da home; não recuperou toda a organização.
A [comparação FE-044](COMPOSICAO_DAS_PAGINAS_FRONTEND.md#82--continuidade-do-mapa-navegável-fe-044)
identifica Clientes, Compras, Cestas e montagens, Movimentações, Relatórios,
Impressão, Conexão e Backup ausentes da amostra recente. Também há diferença
entre histórico global e preservação da posição em cada área. Funções futuras
de bancos/documentos continuam no plano com sua identificação de proposta.

### Verificações anteriores e índices

Os testes da última amostra verificavam percursos financeiros, cálculos,
controles, calendário, redução de movimento e limites de largura. Não
comparavam a barra e todos os destinos com a referência aceita. Portanto,
testes aprovados não comprovavam fidelidade do conjunto ao projeto anterior.

Também havia trechos dos índices chamando rodadas antigas de “atual” e
descrevendo a apresentação como futura depois de ela já ter ocorrido. Isso
prejudicava a retomada. As entradas de continuidade passam a apontar para
esta auditoria; descrições cronológicas antigas devem ser lidas como histórico.

## 3. Onde estão os demais acordos

Esta tabela aponta evidências existentes. Não congela propostas como aprovadas.

| Acordo ou referência | Situação a preservar | Fonte |
| --- | --- | --- |
| Planejar por incrementos antes de aplicar ao app | Confirmado; nenhuma migração visual global autorizada. | Memória FE-001 e plano. |
| Mobile first Android/iPhone e adaptação Windows | Confirmado; integração nativa iOS continua pendente. | FE-002 e manual. |
| Abertura na visão geral com acesso ao Financeiro | Confirmado. | FE-003. |
| Início, Financeiro, Vendas, Estoque e Mais | Base organizacional acolhida; conservar destinos e contexto ao integrar. | FE-008, mapa original, FE-044. |
| Home com resumo financeiro, negócio hoje e atenção | Referência acolhida; medidas/novos indicadores não são automaticamente aprovados. | Mapa original e FE-042. |
| Barra lateral do mapa original | Referência a recuperar; alteração recente contestada pelo usuário. | Fontes e imagens da seção 2. |
| Pagar e Receber na mesma área | Confirmado; integrações futuras continuam por etapas. | FE-004. |
| Integral do saldo restante por padrão | Confirmado para Pagar e Receber. | FE-015 e FE-022. |
| Parcial explícito e campo revelado suavemente | Confirmado; valor oculto não participa do integral. | FE-015 e jornadas preservadas. |
| Revisar antes de confirmar e editar sem perder preenchimento | Conferência aceita; contratos reais de concorrência/recuperação ainda por fechar. | FE-014 e catálogo. |
| Campo de data sem escapar/cortar; calendário | Referência com calendário aceita; movimento posterior e homologação nativa têm limites próprios. | FE-017/020/021/031 e arquivos das rodadas. |
| Espaço entre grupos de campos 20 | Confirmado; não extrapolar como espaçamento universal. | FE-028 e tokens. |
| Campos 24 e painéis 32 | Confirmado por papel; não extrapolar automaticamente para a barra de navegação. | FE-030 e base visual. |
| Destaque escolhível nas configurações, azul original por padrão | Confirmado; configuração real ainda não implementada neste trabalho. | FE-028, azul #2866ae documentado na base. |
| Ação principal com FAB e espaço na rolagem | Preferência vigente contra barra fixa de ações; distinta da navegação inferior. | FE-010 e guia de layout. |
| Próximos vencimentos em três dias; hoje e vencidas separados | Horizonte confirmado; demais detalhes particulares da regra identificados como proposta. | FE-040 e regras INT-01. |
| Design inteligente orienta com dados e transmite cuidado, sem exigir IA | Intenção confirmada; condições, fontes e limites precisam continuar explícitos. | FE-036/037 e documento específico. |
| Pesquisa com links diretos e aprendizado aprofundado | Confirmado; preservar fontes junto das conclusões. | FE-011/018/038 e pesquisas. |
| Não gerar prévia a cada ajuste simples | Confirmado; agrupar revisões significativas. | FE-032. |
| Fonte, escala tipográfica, fundo e uso definitivo de vidro | Detalhes ainda propostos/em avaliação; não declarar como fechados. | FE-005/006/033 e base visual. |

Fontes principais: [memória](MEMORIA_E_PESQUISAS_FRONTEND.md),
[manual](ARQUITETURA_FRONTEND.md), [plano](PLANO_ARQUITETURA_DE_DESIGN.md),
[tokens](TOKENS_VISUAIS_PROPOSTOS.json), [catálogo](CATALOGO_COMPONENTES_FRONTEND.md),
[movimento](PADROES_DE_MOVIMENTO_FRONTEND.md),
[design inteligente](DESIGN_INTELIGENTE_E_ORIENTACAO_AO_USUARIO.md) e
[regras de informação](REGRAS_DE_INFORMACAO_UTIL_FRONTEND.md).

## 4. Recuperação delimitada antes de novas expansões

1. Usar o código do mapa original como estrutura de recuperação, incluindo a
   barra, hierarquia, pontos de entrada e posição por área. Conservar originais.
2. Incorporar os avanços já alinhados de campos, pagamentos/recebimentos,
   revisão e calendário nos seus papéis, sem redesenhar a estrutura geral.
   Uma revisão integrada recebe fonte própria, ligada à origem e aos IDs aplicados.
3. Identificar separadamente os indicadores/arranjos ainda propostos. Nenhum
   detalhe experimental da última amostra revoga automaticamente uma referência.
4. Antes de apresentar, comparar a nova composição com a referência: largura
   e alinhamento da barra, área da seleção, espaçamento dos destinos, hierarquia,
   cobertura dos menus e retorno por área. Conferir também as jornadas financeiras
   já aceitas. Distinguir conformidade visual, teste funcional e teste em aparelho.
5. Apresentar o conjunto recuperado com uma lista curta das mudanças intencionais
   e pendências. Não exigir que o usuário reconstrua toda a conversa nem aprovar
   novamente escolhas confirmadas. Não confundir esse passo com implementar Flutter.

**Situação ao fim desta auditoria:** cópias e registros conferidos, duas cópias
HTML adicionais recuperadas e falhas explicitadas. A barra e os destinos da
amostra recente ainda não foram corrigidos. A consolidação integrada e o
versionamento no Git continuam trabalhos pendentes; não declarar concluídos.

## 5. Como reexecutar a conferência

Executar `verificar_preservacao.py --visualizations <pasta-da-conversa>` com Python.
A opção `--recover-missing` copia HTMLs ausentes do arquivo histórico para uma
subpasta desta auditoria; nunca substitui uma cópia com conteúdo diferente.
O relatório registra os valores observados naquele momento. Alterar documentos
depois muda seus hashes; isso não é, por si só, perda de um design histórico.
O script confere os arquivos e registros locais, sem abrir navegador ou acessar
backend, banco da empresa, APIs ou fontes externas.
