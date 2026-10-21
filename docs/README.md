# Índice das mecânicas do app

**Prioridade FE-055 — 17/10/2026:** [integração da interface aprovada](INTEGRACAO_INTERFACE_APROVADA.md)
descreve as cinco áreas ligadas aos serviços, aparência comum, responsabilidade
de cada camada e a entrega Windows Release concluída: 334 testes Flutter,
436 de backend e análise sem pendências. Referência FE-052 intacta;
[evidências finais](validacoes_frontend/fe-055-integracao-2026-10-17/README.md).
A entrega não certifica equivalência de cada pixel em todas as telas/dispositivos.
As prioridades FE-054 e anteriores abaixo registram etapas históricas.

**FE-054 — 17/10/2026:** [Receber revisado](PILOTO_RECEBER_REVISADO.md)
e [validação](validacoes_frontend/fe-054-receber-2026-10-17/README.md) descrevem
a segunda jornada real, lista compacta, venda de origem e componentes comuns
com Pagar. O tema/navegação de todo o app ainda não foi aplicado.

Revisão do índice: **16/10/2026**. Cada guia informa sua própria revisão. Estes guias descrevem o código atual do projeto. Uma alteração de código só aparece no aplicativo instalado depois de atualizar o servidor e/ou compilar e distribuir o cliente correspondente.

## Por onde começar

Para compreender o que pode ser editado e como evoluir o aplicativo sem perder
o histórico, comece pelas [regras de integridade dos dados e evolução](REGRAS_DE_INTEGRIDADE_E_EVOLUCAO.md).

Para a nova interface, consultar o
[manual de arquitetura do front-end](ARQUITETURA_FRONTEND.md): fundação,
prioridades mobile, contratos de módulos e mapa aceito como base. O
[plano de design](PLANO_ARQUITETURA_DE_DESIGN.md) organiza a evolução por etapas.
Ambos distinguem decisões acordadas, propostas e comportamento implementado.
A [memória de decisões, pesquisas e aprendizados](MEMORIA_E_PESQUISAS_FRONTEND.md)
registra os motivos das escolhas, fontes, pendências e o ponto de retomada;
as [prévias e referências](referencias_frontend/README.md) estão preservadas no
projeto. Consultar esse conjunto ao continuar o planejamento em outra sessão.
**Prioridade atual, FE-053:** primeiro fluxo real de
[pagamento revisado](PILOTO_PAGAR_REVISADO.md) integrado em Contas a Pagar.
O guia distingue código/testes/compilação de atualização instalada e conserva
contratos de envio, saldo, data e recuperação. Continuar por Receber e áreas
principais a partir da base visual já consolidada.

**Base visual, FE-052:** o
[acabamento integrado e filtros compactos](referencias_frontend/rodada-acabamento-2026-10-16/README.md)
reúne vidro suave/cores da referência inicial à organização acolhida. Filtros
recolhidos por padrão, Leitura recuperada e navegação preservadas. Esta é a
fonte visual vigente; avançar para integração pelo recorte documentado, sem
reiniciar descoberta ou redesenhar áreas já acertadas.

**Preparação técnica, FE-050:** seguir pelas
[jornadas financeiras e preparação do piloto](JORNADAS_FINANCEIRAS_E_PRONTIDAO_DO_PILOTO.md),
com estados, contratos, diferenças para o código atual e recorte proposto.
Leitura recuperada e organização FE-049 acolhidas: Início, Financeiro, Negócio,
Estoque e Mais. O [registro atual](REFERENCIA_ATUAL_FRONTEND.json) aponta a
[fonte integrada preservada](referencias_frontend/rodada-organizacao-2026-10-16/README.md);
a [auditoria](AUDITORIA_CONTINUIDADE_FRONTEND_2026-10-16.md) conserva as falhas
e a matriz de acordos. Sem implantação no app nesta rodada. As referências
cronológicas seguintes explicam o percurso e não substituem essa prioridade.
Para projetar o conteúdo e a orientação do produto, ler também o documento
aprofundado de [design inteligente, informação útil e antecipação](DESIGN_INTELIGENTE_E_ORIENTACAO_AO_USUARIO.md),
FE-036. Ele conserva fundamentação, exemplos e critérios; a memória é seu índice,
não substituto por uma síntese.
As [primeiras regras de informação útil](REGRAS_DE_INFORMACAO_UTIL_FRONTEND.md)
detalham vencimentos, estoque mínimo e custo incompleto, com fontes, condições e
lacunas. Horizonte de três dias confirmado pelo usuário em FE-040; nova orientação
e integração permanecem em planejamento.
Rodada visual anterior: [espaço confirmado e ajustes corrigidos](RODADA_FRONTEND_AJUSTES_2026-10-16.md),
com espaço 20 e preferência de destaque nas configurações definidos. Atualiza a
[base de cores, formas e espaço](BASE_VISUAL_FRONTEND.md),
com [valores estruturados propostos](TOKENS_VISUAIS_PROPOSTOS.json) e ajustes
compartilhados. O retorno seguinte confirma campos 24 e painéis 32 (FE-030);
fundo continua por avaliar. Mantém o
[catálogo mínimo de componentes](CATALOGO_COMPONENTES_FRONTEND.md),
com contratos e três famílias de exemplos; direção e apresentação aceitas como
referência em FE-026, com tokens e detalhes técnicos ainda por formalizar. A última
jornada aceita é [Receber e movimento](RODADA_FRONTEND_RECEBER_2026-10-16.md),
com integral do saldo atual confirmado pelo usuário.
A etapa de [hierarquia e tipografia](HIERARQUIA_E_TIPOGRAFIA_FRONTEND.md)
registra FE-033 e a escolha posterior da Leitura recuperada em FE-049;
ajustes simples permanecem agrupados.
Composição: [páginas e continuidade](COMPOSICAO_DAS_PAGINAS_FRONTEND.md),
FE-034, com blocos de lista/detalhe/registro/revisão e retorno ao contexto.
Conjunto preparado para uma futura revisão visual agrupada; propostas ainda por avaliar.
O [padrão de movimento](PADROES_DE_MOVIMENTO_FRONTEND.md) registra o que já foi
demonstrado, fontes e o que implementar no piloto. A rodada anterior de
[resumo e data](RODADA_FRONTEND_RESUMO_E_DATA_2026-10-16.md) foi aceita como referência.
Preservar também as decisões de
[integral por padrão e mais arredondamento](RODADA_FRONTEND_INTEGRAL_2026-10-16.md).
Pesquisa de referência: [front-end financeiro e empresarial](PESQUISA_FRONTEND_EMPRESARIAL_2026-10-16.md),
com fontes, aprendizados, limites e o roteiro de resumo/lista/origem agora demonstrado.

Para entender uma função, abra o guia da tabela abaixo. Cada fluxo explica sua finalidade, onde aparece na interface, a regra aplicada pelo servidor, as tabelas envolvidas, um exemplo e os arquivos de implementação. Os endpoints mencionados recebem o prefixo `/api/v1`.

| Fluxo | Documento | Situação |
| --- | --- | --- |
| Arquitetura do backend, regras de engenharia e roteiro | [Arquitetura do back-end](ARQUITETURA_BACKEND.md) | Guia canônico do backend |
| Caminho da tela até o banco, transações e histórico | [Como o sistema funciona](COMO_O_SISTEMA_FUNCIONA.md) | Base compartilhada |
| Cadastro, edição, inativação e exclusão de produtos; formas de compra | [Produtos e formas de compra](PRODUTOS_E_FORMAS_DE_COMPRA.md) | Ativo |
| Cadastro de tipos de cesta e seus controles | [Tipos de cesta](TIPOS_DE_CESTA.md) | Ativo; campos com limitações descritas |
| Composição, quantidades e versões de receitas | [Receitas e composição](RECEITAS_E_COMPOSICAO.md) | Ativo |
| Editar, inativar e excluir tipos de cesta | [Exclusão de tipos de cesta](EXCLUSAO_DE_TIPOS_DE_CESTA.md) | Ativo; histórico preservado |
| Fabricação padrão/personalizada antecipada e histórico por tipo de cesta | [Montagens e histórico](MONTAGENS_E_HISTORICO.md) | Integrado ao módulo de cestas |
| Compras, confirmação, conversão, custo e cancelamento | [Compras](COMPRAS.md) | Ativo |
| Saldo, movimentações, perdas e contagem física | [Estoque e ajustes](ESTOQUE_E_AJUSTES.md) | Ativo |
| Cadastro, limite de crédito e extrato de clientes | [Clientes](CLIENTES.md) | Ativo |
| Venda de cesta pronta e montagem durante a venda | [Vendas e montagem](VENDAS_E_MONTAGEM.md) | Ativo |
| Cancelamento e destino das cestas ou produtos | [Cancelamento de vendas](CANCELAMENTO_DE_VENDAS_E_MONTAGEM.md) | Implementado no código atual |
| Fiado, recebimentos e estornos | [Contas a receber](CONTAS_A_RECEBER.md) | Ativo |
| Obrigações, pagamentos, parcelas e recorrência | [Contas a pagar](CONTAS_A_PAGAR.md) | Ativo |
| Documentos de bancos/cartões, dados recebidos, duplicidades e conciliação | [Base financeira e conciliação](BASE_FINANCEIRA_E_CONCILIACAO.md) | Backend implementado; migrações preparadas, sem telas novas |
| Leitores CSV de conta/cartão, mapeamento multibanco, prévia e confirmação | [Importação CSV multibanco](IMPORTACAO_CSV_MULTIBANCO.md) | Backend implementado para validação pela API; OFX e integração Gmail futuros |
| Detectar e extrair faturas/extratos PDF, preservar páginas e bloquear divergências | [Importação PDF financeiro](IMPORTACAO_PDF_FINANCEIRO.md) | Cinco PDFs originais Nubank/PicPay validados no alcance documentado; solicitação/nova tentativa de senha implementadas, com testes simulados; parsers Nubank/PicPay/Itaú/Santander/Inter, com testes sintéticos para Itaú/Santander/Inter. Homologação com PDFs realmente protegidos e layouts fora do alcance validado, e OCR, continuam pendentes; sem tela nova |
| Corrigir duplicidade conferida, preservar decisões e revalidar identificadores | [Correção da revisão financeira](CORRECAO_REVISAO_FINANCEIRA.md) | Backend implementado; sem telas novas, migração preparada |
| Homologar originais e retomar a implementação | [Homologação financeira](HOMOLOGACAO_IMPORTACAO_FINANCEIRA.md) e [memória financeira](MEMORIA_IMPLEMENTACAO_FINANCEIRA.md) | CSV Nubank PF/PJ e PDFs Nubank/PicPay validados no alcance documentado |
| Significado das faturas, procedência, divergências e integração com obrigações | [Arquitetura semântica de faturas](ARQUITETURA_SEMANTICA_DE_FATURAS.md) | Planejamento fundamentado e conferência manual; não implementa integração de títulos |
| Associar documentos de controles e registrar conferência/revisões de faturas | [Conferência e procedência](CONFERENCIA_E_PROCEDENCIA_DE_FATURAS.md) | Backend implementado; migração fd3 validada em cópia e ainda não aplicada ao original |
| Vendas, compras, pendências e resultado gerencial | [Dashboard e financeiro](DASHBOARD_E_FINANCEIRO.md) | Ativo |
| Relatórios, exportação, PDF e formulários | [Relatórios e impressão](RELATORIOS_E_IMPRESSAO.md) | Ativo |
| Impressão Wi-Fi, serviços Android e compatibilidade | [Análise da impressão](IMPRESSAO_WIFI_E_ANDROID.md) e [guia de configuração](MANUAL_IMPRESSAO_EPSON.md) | Ativo; homologação física pendente |
| Conexão, pareamento e autenticação Windows/Android | [Configuração e autenticação](CONFIGURACAO_E_AUTENTICACAO.md) | Ativo |
| Backup, restauração e limites do agendamento | [Backup e restauração](BACKUP_E_RESTAURACAO.md) | Ativo |
| Criação e ativação de um banco vazio | [Novo banco](NOVO_BANCO_DE_DADOS.md) | Ação no Windows |
| Telas antigas de produção, desmontagem, expedição e tesouraria | [Funções arquivadas](FUNCOES_ARQUIVADAS.md) | Telas originais arquivadas; montagem padrão/personalizada integrada disponível |
| Posição dos botões e espaço de rolagem | [Layout e ações](LAYOUT_E_ACOES_DE_PAGINA.md) | Convenção de interface |

## Como consultar sem confundir versões

O [plano da nova arquitetura de design](PLANO_ARQUITETURA_DE_DESIGN.md)
registra pesquisa, preferências e etapas propostas, incluindo problemas de
compras adiados pelo usuário. Está em revisão; não descreve uma nova interface
já implementada nem autoriza a mudança global do tema.

O [escopo de evolução do módulo de cestas](EVOLUCAO_DO_MODULO_DE_CESTAS.md)
separa estoque, montagem padrão/personalizada e histórico já implementados das propostas de
seleção do lote personalizado na venda, receitas e exclusão ainda pendentes.

O [manual operacional](MANUAL_OPERACIONAL.md) oferece uma visão geral da rotina. Os guias acima detalham as mecânicas atuais. A [arquitetura](../ARCHITECTURE.md) define as regras técnicas permanentes; a [especificação original](../Especificacao_Sistema_Estoque_Cestas.md) registra o planejamento inicial, que também contém recursos posteriormente arquivados.

Uma tela arquivada não significa que suas tabelas ou seus dados foram apagados. Uma configuração salva não significa, por si só, que o backend já a utiliza: os guias registram essas diferenças explicitamente.

## Manutenção da documentação

Ao mudar uma mecânica, atualizar seu guia na mesma entrega: interface, regras, efeitos no banco, exemplos, limitações e referências de código. Adicionar ao índice qualquer fluxo novo e marcar funções retiradas da interface como arquivadas. Atualizar a data de revisão do guia afetado. Registrar resultados de testes como evidência da alteração correspondente, sem tratá-los como uma contagem permanente do projeto.
