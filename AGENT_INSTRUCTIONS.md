# Instruções Mandatórias para Agentes de Desenvolvimento (AI / Pair Programming)

**Catálogo, receitas e desmontagem — 20/10/2026:** retomar pelo
[registro único deste trabalho](docs/PLANO_CANCELAMENTO_MONTAGENS_E_EXCLUSAO.md)
e pelos guias funcionais de receitas, produtos e montagens. Venda não cancelada
e operação/saldo ainda válido bloqueiam; histórico já desfeito não é bloqueio
permanente. Esse trabalho é separado do aceite nativo da importação/E5.

**Importação de faturas — estado vigente:** Etapa 1 do plano corretivo foi implementada, verificada e ativada localmente. Retomar pelo [registro curto](docs/RETOMADA_IMPORTACAO_FATURAS.md); migração `f39a012b2159`, backend HTTPS local e Release Windows **1.0.5+10**. Etapas corretivas 2–4 continuam pendentes; não inferir que os fluxos E2–E4 da aplicação sejam essas etapas.
T15 ainda tem pendência visual; não declarar aceite nativo integral. A reforma visual global permanece separada.

## Registro enxuto e economia de contexto

**Direção do usuário — 19/10/2026:** manter continuidade sem produzir históricos
extensos a cada etapa. Esta regra prevalece sobre orientações anteriores de
registro contínuo quando elas levarem a duplicar a mesma informação.

- Usar um único arquivo de andamento por trabalho; atualizar seu estado atual,
  sem acrescentar um diário a cada ação. Na importação de faturas, o arquivo é
  [RETOMADA_IMPORTACAO_FATURAS.md](docs/RETOMADA_IMPORTACAO_FATURAS.md).
- Registrar ao concluir um incremento relevante, transferir o trabalho ou parar
  com pendência. Não registrar separadamente cada edição, comando ou teste.
- Normalmente bastam 5–10 linhas: resultado/decisão, arquivos ou contratos
  relevantes, testes e limites, pendência e próximo passo. Não narrar pensamentos,
  tentativas rotineiras, logs completos ou informações já presentes no plano.
- Atualizar o guia funcional somente se o comportamento documentado mudou;
  arquitetura somente se houve decisão estrutural. Fazer alteração localizada,
  sem copiar o registro para memória, índice e vários outros documentos.
- Índices e memórias existentes conservam apontadores; só editá-los quando o
  destino ou uma informação vigente ficar incorreto. Não criar outro arquivo de
  memória, relatório ou pesquisa para repetir um resultado já registrado.
- Ao retomar, consultar o estado curto e as seções pertinentes. Cumprir a ordem
  canônica abaixo sem reler integralmente todo o histórico a cada subetapa;
  ampliar a leitura quando houver dúvida, conflito ou mudança de contexto.
- Preservar fundamentações, decisões e evidências necessárias já existentes.
  Economia de contexto não autoriza apagar histórico, omitir falhas/limites ou
  pular validação. Detalhe adicional deve resolver uma necessidade concreta.

## Escolha de esforço e referências locais

**Pedido explícito do usuário — 20/10/2026:** ao apresentar um plano ou nova etapa
relevante, recomendar o esforço do modelo escolhido em uma frase, com motivo
ligado ao escopo. Para recomendações habituais, consultar primeiro apenas a seção
**Consulta rápida** do [guia local](docs/ESFORCO_DOS_AGENTES.md); abrir somente o trecho necessário
das páginas oficiais salvas que ele referencia. Evitar pesquisas repetidas quando
o resumo e o contexto já forem suficientes. Verificar online fatos atuais ou
provavelmente alterados, modelos novos, divergências e exigências superiores.
Não reler o acervo inteiro, repetir o aviso em toda resposta, pedir mudança de
esforço a cada correção nem alterar configurações automaticamente. Não converter
segundos em tokens ou prometer economia sem medição. Esta orientação vale para
os agentes deste projeto; não muda a configuração global do Codex.

## Direção financeira e continuidade

### Clareza didática, erros e consistência de interface — direção de 20/10/2026

O usuário exige uma experiência que uma criança ou uma pessoa sem familiaridade
com o sistema consiga entender e usar. **Didática não significa apenas encurtar
o texto.** Explicar o necessário, com palavras familiares, sequência concreta e
tom respeitoso: o que aconteceu, qual informação falta ou diverge, onde está,
como corrigir e o que já foi ou ainda não foi gravado. Não exigir que a pessoa
conheça termos do banco, da API ou do código para concluir sua tarefa.

- Em erros de preenchimento, destacar o campo, a escolha, a linha ou a confirmação
  exata com a aparência de erro do tema **e texto explicativo junto ao controle**.
  Abrir a seção recolhida quando necessário, levar rolagem/foco à primeira
  pendência e preservar o que já foi preenchido corretamente. Um aviso geral,
  uma cor isolada ou um aviso temporário não substituem essa orientação.
- A ação ensinada precisa existir e ser executável naquele estado. Não mandar
  selecionar uma conta quando não há contas disponíveis, preencher um campo
  oculto ou corrigir uma falha interna do servidor. Distinguir informação faltante,
  decisão necessária, conflito real e falha técnica; indicar a recuperação
  comprovadamente disponível e explicar quando o resultado da gravação é incerto.
- Antes de criar/alterar página, botão, título, mensagem, campo, seletor ou diálogo,
  consultar a arquitetura do front-end, o apontador da referência atual e os
  componentes/tema existentes. Reutilizar o dono canônico; não inventar aparência
  por página nem copiar um desvio só porque existe numa tela antiga.
- Planos de implementação devem ensinar o agente explicitamente: arquivos e
  símbolos, condições e ramificações, comportamento de cada tela, exemplos de
  mensagem, ações válidas, critérios e casos de verificação. Não trocar precisão
  por brevidade nem omitir decisões para aparentar economia de tokens. Preferir
  **duas etapas; usar no máximo quatro** quando a dimensão justificar, com tarefas
  internas pequenas e verificáveis, sem transformar cada tarefa em nova fase.
- Não tratar hipótese como causa confirmada. Reproduzir o defeito de estado em
  ambiente isolado antes da correção; não agrupar/ocultar registros para encobrir
  um problema de identidade, exclusão ou gravação. Testes não podem semear a base
  usada pelo aplicativo. A revisão específica atual está no
  [plano de correção e usabilidade do PDF](docs/PLANO_CORRECAO_E_USABILIDADE_IMPORTACAO_PDF.md).

**Direção financeira vigente — esclarecimento do usuário em 19/10/2026:** ler
[o escopo de importação de faturas](docs/ESCOPO_IMPORTACAO_DE_FATURAS.md) antes de
seguir roteiros técnicos antigos. A prioridade é concluir os PDFs/CSVs dos bancos
usados até Contas a Pagar, com banco/cartão, estabelecimento, valores, vencimentos
e parcelas atuais/futuras. Não ampliar por completude nem tratar o diagnóstico
de alocações como entrega dessa função. Reavaliar o modelo mínimo antes de
implementar todo o plano de alocações manuais; OFX/Open Finance/Gmail ficam fora
do recorte atual. O usuário aceita avaliar uma API de IA se necessária para seus
documentos; isso não implica integração escolhida ou envio já executado.

**Continuidade financeira — plano de 19/10/2026:** após a auditoria dos arquivos,
o usuário solicitou planejamento antes de implementar. Consultar o
[plano por etapas](docs/PLANO_IMPLEMENTACAO_IMPORTACAO_FATURAS.md) e a
[retomada curta](docs/RETOMADA_IMPORTACAO_FATURAS.md). E1–E4 implementadas conforme os guias vigentes;
a retomada conserva o estado de homologação/ativação da E5.
Retomar pela etapa e critérios indicados, sem repetir a auditoria inteira
ou construir o antigo plano de alocações manuais por completude.

## ZM Cesta Básica — Sistema de Gestão de Estoque, Produção, Vendas e Financeiro

Este documento estabelece as **diretrizes e o protocolo operacional obrigatório** para qualquer agente de inteligência artificial ou desenvolvedor automatizado que venha a atuar neste projeto em sessões futuras.


> **Escopo atual do cliente — 13/10/2026:** as telas de produção em lote,
> desmontagem, expedição/conferência, responsáveis e tesouraria estão arquivadas.
> As descrições dessas fases abaixo são referência histórica e de domínio.
> O backend e os dados históricos são preservados para os fluxos compartilhados.
> Consulte [client/_archive/README.md](client/_archive/README.md) antes de restaurar
> funções. Não reintroduzir menus, relatórios ou serviços exclusivos arquivados
> sem solicitação do usuário. Montagem na venda segue ativa; pagamentos não exigem seleção de contas.

> **Dashboard e financeiro simplificados:** o aplicativo usa `dashboard/business-summary`
> e `reports/business-financial-summary`, com vendas, compras, estoque, confirmações,
> pendências, custo vendido e resultado gerencial. Não exibir saldos de caixa/contas,
> depósitos manuais ou projeção de tesouraria. As confirmações preservam a auditoria
> interna; contas financeiras não são selecionadas pelo operador. Consultar
> [client/_archive/DASHBOARD.md](client/_archive/DASHBOARD.md) antes de evoluir esses fluxos.

---

## 1. Regra de Entrada e Ordem de Consulta de Documentos

### 1.1. Núcleo obrigatório

- Ler e cumprir sempre a seção 2 inteira, incluindo a política vigente de testes
  proporcionais ao risco e o [contrato de integridade](docs/REGRAS_DE_INTEGRIDADE_E_EVOLUCAO.md).
  Aplicar também **Registro enxuto e economia de contexto**. A leitura seletiva
  não dispensa segurança, integridade, isolamento, backups ou preservação do histórico.
- Respeitar o escopo e as autorizações vigentes do usuário; preservar alterações
  preexistentes. Não modificar, atualizar, fazer merge, rebase ou push em
  `master`/`main`, locais ou remotas. Não executar `push --force`, `reset --hard`
  nem operações que descartem trabalho. Commit, push e aplicação de migrações em
  banco real exigem autorização correspondente; um plano ou registro
  histórico não concede autorização para executar suas etapas.
- Nunca usar o banco da empresa em testes, nem presumir dados locais descartáveis.
  Migrações exigem cópia preenchida isolada, backup verificado e recuperação
  planejada antes de aplicação real. Preservar livros append-only, vínculos,
  valores congelados, `BEGIN IMMEDIATE`, idempotência, chaves estrangeiras,
  centavos/microcentavos inteiros, carimbos de data/hora em UTC e a comunicação
  autenticada com TLS.
  A interface e os testes não podem contornar essas garantias.
- Ler as diretrizes das seções 3–7 sempre que a tarefa afetar os respectivos
  contratos, inclusive por uma alteração de interface ou de testes. Distinguir
  código implementado, testes executados, ativação local, homologação e produção;
  registrar falhas e limites sem declarar validação completa indevidamente.

### 1.2. Hierarquia e roteamento por tarefa

A leitura externa e os blocos específicos deste arquivo são selecionados pelo
impacto da tarefa. Começar por títulos, índice, estado curto e seções pertinentes;
não carregar integralmente documentos extensos de módulos alheios. Os registros
iniciais de catálogo e finanças, **Direção financeira e continuidade** e os blocos
1.3/1.4 são consultados quando o trabalho envolver seus assuntos. **Escolha de
esforço e referências locais** aplica-se a planos e novas etapas relevantes.

**Exceção de escopo autorizada em 14/10/2026:** registro de montagem padrão/personalizada e
histórico estão integrados em Tipos de Cesta → Montagens. As páginas novas
reutilizam o backend existente; não restaurar por esse motivo as telas antigas
de produção, desmontagem ou outros módulos arquivados. Consultar
[docs/MONTAGENS_E_HISTORICO.md](docs/MONTAGENS_E_HISTORICO.md).

**Documentação das mecânicas:** para localizar ou alterar uma mecânica, consultar [docs/README.md](docs/README.md),
o índice dos fluxos atuais. Ao alterar uma mecânica, atualizar seu guia na mesma
entrega com localização na interface, regras de backend, efeitos nas tabelas,
exemplos, limites e referências de implementação. Incluir fluxos novos no índice
e distinguir telas ativas, capacidades apenas do backend e funções arquivadas.
Não documentar comportamento planejado como se já estivesse implementado.

**Papéis das fontes canônicas — consulta conforme a tarefa:**

- **[ARCHITECTURE.md](./ARCHITECTURE.md):** Fonte canônica da verdade sobre decisões arquiteturais, governança modular, princípios de engenharia permanentes, preparação de IA futura, simplificação da Fase 6, consistência de vendas/custódia e especificações de relatórios/impressão da Fase 8.
- **[Especificacao_Sistema_Estoque_Cestas.md](./Especificacao_Sistema_Estoque_Cestas.md):** Especificação original aprovada do produto e regras de domínio da empresa.
- **[backend/README.md](./backend/README.md) e [client/README.md](./client/README.md):** Estrutura física de diretórios, convenções de código e comandos de execução.

**Hierarquia para resolver divergências:** autorizações atuais do usuário e
proteções obrigatórias governam o trabalho. A especificação original define o
domínio, complementada pelas evoluções explicitamente aprovadas e pelas decisões
arquiteturais vigentes. Código e testes pertinentes mostram a implementação e
oferecem evidência verificável; código existente pode conter defeitos e testes
podem estar desatualizados. Guias atuais descrevem o funcionamento e devem ser
conferidos nessas evidências. Memórias, auditorias e planos datados preservam
motivos e estados anteriores; não comprovam capacidade ou autorização atual.
Diante de conflito, investigar o contrato e a decisão vigente; não usar código,
teste, documento ou data isolados para autorizar mudança incompatível. Escalar ao
usuário dúvidas que dependam de decisão de negócio ou ampliação de autorização.

| Tipo de tarefa | Leitura específica obrigatória, além do núcleo |
| --- | --- |
| Texto, documentação ou ajuste simples | Trecho e referências afetados; guia da funcionalidade se seu significado estiver envolvido. Conferir consistência e diff conforme a seção 2, sem exigir suítes completas automaticamente. |
| Backend, API, serviço ou testes backend | Seção 3; [backend/README.md](backend/README.md); invariantes e módulo pertinente de [ARQUITETURA_BACKEND.md](docs/ARQUITETURA_BACKEND.md); código, schemas e testes relacionados. Consultar ARCHITECTURE e a especificação nas decisões e regras de domínio afetadas. |
| Flutter, interface ou testes frontend | Seção 4, bloco 1.3 e as direções didáticas de **Direção financeira e continuidade** quando envolverem apresentação/erros; [client/README.md](client/README.md), [manual frontend](docs/ARQUITETURA_FRONTEND.md), [referência atual](docs/REFERENCIA_ATUAL_FRONTEND.json), componentes e tema. Para planejamento, seção 8.1 do manual e memória pertinente; para conteúdo/indicadores, [design inteligente](docs/DESIGN_INTELIGENTE_E_ORIENTACAO_AO_USUARIO.md). |
| Importação, conciliação ou faturas | Seção 3, bloco 1.4 e **Direção financeira e continuidade**; primeiro [escopo](docs/ESCOPO_IMPORTACAO_DE_FATURAS.md) e [retomada curta](docs/RETOMADA_IMPORTACAO_FATURAS.md), depois trechos pertinentes da [memória financeira](docs/MEMORIA_IMPLEMENTACAO_FINANCEIRA.md) e [homologação](docs/HOMOLOGACAO_IMPORTACAO_FINANCEIRA.md). Para faturas, consultar as decisões semânticas/procedência indicadas em 1.4; combinar com a rota Flutter se houver interface. |
| Leitores PDF ou CSV | Rota financeira mais o guia do formato afetado: [PDF](docs/IMPORTACAO_PDF_FINANCEIRO.md) ou [CSV multibanco](docs/IMPORTACAO_CSV_MULTIBANCO.md), leitor, schemas e testes correspondentes. Alterações compartilhadas combinam ambos. |
| Persistência, migrações, backup ou segurança | Seções 2 e 3; contrato de integridade completo, invariantes pertinentes de ARCHITECTURE e ARQUITETURA_BACKEND, cadeia Alembic, implementação e testes de isolamento/backup envolvidos. A documentação orienta; não autoriza acessar ou migrar o banco real. |
| Estoque, produtos, receitas, compras, montagens, vendas, contas a pagar ou a receber | Guia funcional localizado pelo [índice](docs/README.md), regras pertinentes da especificação e de ARCHITECTURE; seção 3 e/ou 4 conforme a camada. Para catálogo/receitas/desmontagem, consultar também o registro inicial deste arquivo; preservar a exceção de produto nunca utilizado ao final. |
| Custódia, expedição, conferência ou acerto | Seção 5 e guias pertinentes, além das rotas técnicas. Preservar os contratos históricos sem restaurar funções arquivadas; consultar [funções arquivadas](docs/FUNCOES_ARQUIVADAS.md) e [arquivo do cliente](client/_archive/README.md) antes de qualquer restauração autorizada. |
| Relatórios, planilhas ou impressão | Seção 6 e regras pertinentes da Fase 8 em ARCHITECTURE, guia funcional e rotas backend/Flutter envolvidos. |
| Preparação ou integração futura com IA | Seção 7 e decisões pertinentes de ARCHITECTURE; a leitura não autoriza implementar IA ou adicionar dependências. |

**Tarefas com vários módulos:** combinar todas as rotas afetadas, incluindo as
camadas e os contratos compartilhados (API, payloads, persistência, dinheiro,
identidade/geração e tentativas repetidas). Reavaliar as leituras se o escopo ou
os riscos crescerem. Uma tarefa pequena que afeta dinheiro, autenticação ou dados
não se torna de baixo risco pelo tamanho do diff.

**Histórico e carregamento progressivo:** preservar todos os registros e suas
referências. Consultar primeiro o estado vigente e ampliar para decisões,
auditorias e planos anteriores quando necessário para entender motivos,
compatibilidade, evidências, falhas ou conflitos. As decisões e restrições ainda
vigentes continuam obrigatórias; não reler toda a cronologia por rotina nem
converter uma instrução histórica superada em bloqueio atual. A seção 8 é o
registro da entrega original, não comprovação atual de testes ou produção.

### 1.3. Front-end — diretrizes e continuidade

**Front-end — direção atualizada em 15/10/2026:** consultar também o
[manual de arquitetura do front-end](docs/ARQUITETURA_FRONTEND.md) e o
[plano de design](docs/PLANO_ARQUITETURA_DE_DESIGN.md). A experiência nova prioriza
Android e iPhone, com adaptação para Windows; a integração nativa iOS ainda é uma
entrega a realizar. O destino inicial escolhido é a visão geral do negócio com
acesso direto ao Financeiro. Evoluir o planejamento por etapas e distinguir
decisões confirmadas, propostas e comportamento implementado. As prévias não
autorizam aplicar o novo tema ou reorganizar todas as telas automaticamente.

**Continuidade do planejamento do front-end:** ler também a
[memória de decisões, pesquisas e aprendizados](docs/MEMORIA_E_PESQUISAS_FRONTEND.md)
e o [arquivo de prévias](docs/referencias_frontend/README.md), especialmente após
compactação do contexto ou ao iniciar outra sessão. Ao encerrar cada rodada
relevante, registrar data, fonte, motivo, alcance, situação e próximo passo;
atualizar manual e plano quando necessário. Preservar o motivo de hipóteses
descartadas. Não depender exclusivamente do histórico do chat nem tratar uma
sugestão do assistente como escolha do usuário.

**Método de planejamento do front-end — 16/10/2026, FE-035:** seguir a seção
**8.1 — Método de planejamento** do [manual](docs/ARQUITETURA_FRONTEND.md).
Entender a tarefa e os contratos atuais, pesquisar dúvidas relevantes em fontes
primárias, comparar alternativas quando houver uma escolha real e propor um
incremento pequeno. Confirmar detalhes que dependam do usuário sem repetir
perguntas já respondidas ou criar aprovações para cada ajuste rotineiro.
Registrar fontes, motivos, limites, propostas, decisões e próximo passo.
Agrupar ajustes simples e gerar prévias quando houver uma decisão visual
significativa para revisar, conforme FE-032/FE-034. Prudência não é paralisar
o trabalho autorizado; aprovação de uma referência não autoriza implementar
todo o front-end.

**Prioridade de retomada — auditoria FE-045, 16/10/2026:** ler a
[auditoria de continuidade do front-end](docs/AUDITORIA_CONTINUIDADE_FRONTEND_2026-10-16.md)
antes de outra evolução visual. O usuário apontou regressão da barra lateral;
arquivos salvos não garantiram preservação da referência nas novas amostras.
O mapa original continua como base. Próximo trabalho é consolidar os avanços
sem perder barra, hierarquia, destinos e contexto; a amostra recente não foi
recuperada por esta auditoria. Conferir a matriz de acordos e não aplicar raios
de campos/painéis automaticamente à navegação. Não apresentar cópias locais
como versionamento Git, nem testes funcionais como prova de fidelidade visual.

**Continuação FE-046 — referência atual da prévia:** a recuperação integrada foi
criada e verificada localmente após autorização do usuário. Consultar primeiro
o [registro da referência atual](docs/REFERENCIA_ATUAL_FRONTEND.json) e a
[rodada de recuperação](docs/referencias_frontend/rodada-recuperacao-integrada-2026-10-16/README.md).
O registro aponta a fonte integrada candidata, a referência original acolhida,
hashes e evidências. A barra coincide com a original nas condições locais
comparadas; destinos e jornadas estão reunidos. Retorno do usuário ainda pendente.
Prosseguir tecnicamente a partir da candidata integrada, usando o original na
comparação; não escolher uma prévia parcial pelo nome ou pela data. Arquivos
históricos permanecem imutáveis; outra alteração precisa de nova revisão e
atualização do apontador. Não implica implementação Flutter/API ou commit Git.

**Continuação FE-048 — tipografia/hierarquia:** o usuário encaminhou a
continuidade para outro chat em FE-047; a recuperação já foi apresentada e não
deve ser repetida. A [comparação integrada](docs/referencias_frontend/rodada-tipografia-2026-10-16/README.md)
compara leitura orientada/recuperada e conserva a navegação. Consultar o
[registro atual](docs/REFERENCIA_ATUAL_FRONTEND.json) para fonte/evidências.
Texto ampliado nesta amostra se refere ao conteúdo; não comprova escala global
da navegação nem Dynamic Type. Medidas/família seguem propostas; colher retorno
sobre leitura antes de avançar. Sem autorização de Flutter/API, piloto ou commit.

**Decisão vigente FE-049 — leitura e organização:** o usuário escolheu
**Leitura recuperada** e rejeitou a orientada por tamanho/peso excessivos.
Escolheu **Negócio** para a área de vendas, clientes e resultado; resultado
sai do Financeiro. Início deve ser curto, essencial e oferecer Dia/Semana/Mês;
atenção a hoje/atrasadas/estoque continua atual, independente do período.
Consultar a [revisão integrada](docs/referencias_frontend/rodada-organizacao-2026-10-16/README.md)
e o [apontador atual](docs/REFERENCIA_ATUAL_FRONTEND.json). Preservar os demais
caminhos, medidas e contexto; não reabrir a disputa tipográfica. Próximo trabalho:
terminar jornadas/estados e contratos antes do piloto alinhado. Home deve caber
nas condições usuais, sem cortar informação ou limitar texto para forçar encaixe.
Não é autorização de implementação Flutter/API, distribuição ou commit geral.

**Continuação FE-050 — jornadas antes do piloto:** usuário respondeu “SHOW,
VAMOS PROSSEGUIR” após FE-049. A fonte integrada fica acolhida como referência,
sem nova alteração visual. Consultar as
[jornadas financeiras e preparação do piloto](docs/JORNADAS_FINANCEIRAS_E_PRONTIDAO_DO_PILOTO.md)
para estados, contrato de tentativa incerta, saldo revisado, datas e divergência
de atraso resumo/listas. Pagar sobre título existente é recomendação do agente,
não escolha já feita pelo usuário. Retomar pelo registro atual e pela memória;
alinhar o incremento real sem repetir descoberta ou reabrir a leitura escolhida.

**Continuação FE-052 — acabamento e filtros:** após apreciar cores/vidro e contas
como extrato da referência inicial, o usuário rejeitou filtros grandes e pediu
adiantar o conjunto respeitando os acordos. Consultar o
[acabamento integrado](docs/referencias_frontend/rodada-acabamento-2026-10-16/README.md)
e o registro atual. A nova revisão deriva de FE-049; conserva Leitura recuperada,
barra/destinos, medidas e jornadas. Filtros recolhidos por padrão, recorte visível.
Não repetir descoberta ou reabrir tipografia; retomar integração pelo recorte
documentado em FE-050, distinguindo a simulação das capacidades reais.

**Continuação FE-053 — primeiro piloto real autorizado:** usuário respondeu
“Show vamo embora” após a indicação de Pagar real como próxima entrega concreta.
O [piloto de pagamento revisado](docs/PILOTO_PAGAR_REVISADO.md) foi implementado no
Flutter/API, com revisão, comando persistido, replay, precondição atômica de saldo,
dia civil e confirmação separada da atualização da consulta. Retomar pelo guia,
memória e registro atual; não tratar as restrições históricas de planejamento
como falta de autorização desse recorte nem perguntar de novo por ajustes rotineiros.
Nova API informa capacidade, preserva hashes legados e exige atualização do
servidor/cliente correspondentes para o fluxo instalado. Próximo recorte é Receber;
não inferir implantação global, distribuição ou uso do banco da empresa nos testes.

**Continuação FE-054 — Receber real:** após “Vambora uhuuu” e pedidos de
continuar, [Receber revisado](docs/PILOTO_RECEBER_REVISADO.md) foi integrado.
Usa métodos próprios, saldo/dia civil/capacidade/replay e preserva venda/estoque.
Apresentação e recuperação agora são compartilhadas com Pagar por adaptadores;
JSON/chaves antigas conservados. Lista Receber tem extrato, filtros recolhidos,
parciais incluídos em aberto, cobertura explícita e mais páginas. Retomar pela
memória/registro/evidência atuais. Próximo: áreas principais/resumos reais,
sem reabrir leitura/navegação ou tratar prévia/build como instalação atualizada.

**Correção vigente FE-055 — integração fiel autorizada:** após comparar FE-054
com FE-052, o usuário rejeitou explicitamente interfaces intermediárias para
teste e pediu integrar o backend ao front-end já construído. A referência
FE-052 passa a ser alvo de composição, leitura e navegação. Não criar outro
layout como piloto nem reabrir escolhas confirmadas. Integrar a estrutura
principal e as jornadas aos serviços reais, preservando regras/dados; registrar
e conferir fidelidade visual além dos testes funcionais. A memória registra os
arquivos em andamento; não inferir conclusão ou instalação antes da validação.

**Complemento FE-055:** usuário exigiu comparação de todas as interfaces com a
referência, incluindo diferenças de um pixel. Conferir condições equivalentes
e registrar divergências; não declarar fidelidade a partir de testes funcionais.
O pedido de Sites foi revogado antes de criação/publicação. Ler
[integração da interface aprovada](docs/INTEGRACAO_INTERFACE_APROVADA.md).
O bloqueio anterior por limite de uso foi superado após nova retomada: fechamento
FE-055 fechado em 17/10/2026 com **334 Flutter / 436 backend**, análise sem pendências e **Windows
Release compilado**. Ver a evidência no guia. A aceitação visual integral e os
dispositivos físicos não foram certificados. Não apresentar o executável
FE-054 como esta integração; usar o Release atual com sua pasta completa.

**Design inteligente — definição ampliada em FE-036:** ler a
[documentação específica e aprofundada](docs/DESIGN_INTELIGENTE_E_ORIENTACAO_AO_USUARIO.md)
ao projetar conteúdo, indicadores e orientação. O app deve usar seus dados para
interpretar situações, antecipar necessidades e trazer informações úteis nas
telas e momentos relevantes, transmitindo cuidado e reduzindo esforço.
Isso pode ser realizado com regras, cálculos e contexto, sem exigir IA.
Clareza visual e continuidade são parte dessa direção; não esgotam seu significado.
Conforme FE-037, preservar fundamentação, exemplos, critérios e limites nesse documento; a memória
e as instruções de entrada são índices, não substitutos por resumos. Novas regras
específicas continuam a ser alinhadas por etapas antes da implementação.

**Rastreabilidade das pesquisas — FE-038:** todo aprendizado pesquisado deve
trazer links diretos e clicáveis às fontes originais, junto da conclusão que
sustentam, com título/autor ou organização, data da consulta e seção/página
relevante quando útil. Explicar aplicação e limites; distinguir fonte de
inferência do agente e registrar acesso incompleto. Um resumo, nome de site ou
link apenas para outro documento interno não substitui os links das fontes.
Preservar essas referências ao reorganizar ou ampliar a documentação.

### 1.4. Importação financeira — diretrizes e continuidade

**Continuidade da implementação financeira — 16/10/2026:** para importação,
duplicidade e conciliação, ler a
[memória de decisões e aprendizados](docs/MEMORIA_IMPLEMENTACAO_FINANCEIRA.md)
e o [procedimento de homologação](docs/HOMOLOGACAO_IMPORTACAO_FINANCEIRA.md).
Atualizar decisões, evidências, limites, situação das migrações e próxima ação ao
encerrar uma rodada relevante. Distinguir testes sintéticos, homologação com
originais, capacidade da API e comportamento instalado. Guardar originais e
manifestos financeiros fora do Git; conservar somente relatórios sanitizados no
projeto. Banco da contraparte não comprova suporte ao banco emissor do extrato.

**Fundamentação das faturas — 16/10/2026:** ler também a
[arquitetura semântica de faturas](docs/ARQUITETURA_SEMANTICA_DE_FATURAS.md).
Conserva decisões FAT-001 a FAT-010, pesquisa com fontes diretas e limites,
divergências verificadas entre CSV/PDF, alternativas e critérios de aceite.
Não confundir READY do leitor com cobertura comprovada ou aptidão para gerar
obrigações. A [procedência e conferência auditável](docs/CONFERENCIA_E_PROCEDENCIA_DE_FATURAS.md)
já foi implementada no backend, com migração fd3 validada somente em cópia.
O usuário priorizou depois a importação automática de PDF, implementada para
layouts Nubank/PicPay conforme o [guia PDF](docs/IMPORTACAO_PDF_FINANCEIRO.md).
Retomar por esse guia e pela memória, ampliando a cobertura por amostras reais;
OCR continua pendente. Há parser de fatura Santander no código, mas os testes
existentes usam layouts sintéticos; a homologação com PDFs Santander reais
permanece pendente. O fluxo de solicitação de senha e nova tentativa já está
implementado no cliente e no backend; os testes existentes cobrem cenários
simulados e não comprovam homologação de PDFs bancários realmente criptografados
nem suporte universal. Consultar as evidências e os limites no guia PDF. Revisão
semântica continua futura;
não confundir VERIFIED das transcrições com
autorização para gerar obrigações. Preservar os documentos detalhados; memória
e instruções são índices.

---

## 2. Protocolo de Pré-Implementação e Governança de Evolução Segura

Consultar e cumprir o [contrato de integridade e evolução](docs/REGRAS_DE_INTEGRIDADE_E_EVOLUCAO.md).
O usuário explicitou que pedidos de novas funções, edição ou exclusão precisam
ser avaliados quanto ao que é tecnicamente seguro, não atendidos por remoção de
proteções. Explicar impacto e alternativas compatíveis antes de mudanças que
alterem o significado de dados existentes. Pedidos funcionais genéricos não
autorizam apagar histórico, romper referências ou substituir o banco real.
Para migrações, verificar uma cópia preenchida e planejar backup/recuperação antes
da aplicação em produção. Documentação não substitui validações no código e banco.

Antes de produzir código ou aplicar qualquer alteração em arquivos existentes:

1. **Validação proporcional ao risco:**
   - **Documentação:** verificar consistência, referências e diff. Não exigir a
     execução automática das suítes completas para alterações exclusivamente
     documentais.
   - **Correção de testes:** registrar o estado anterior da suíte e as falhas já
     existentes; permitir corrigir os próprios testes apesar dessas falhas e
     executar os testes afetados. Não apresentar o resultado anterior como
     validação do código atual.
   - **Código:** executar primeiro os testes relacionados à alteração e ampliar
     a validação conforme o impacto, os módulos afetados e os riscos de regressão.
   - **Dados financeiros e migrações:** manter validações rigorosas em ambientes
     isolados, com cópias de bancos para testes e validação de migrações; planejar
     backup e recuperação antes de qualquer aplicação em produção. Nunca usar ou
     modificar o banco da empresa durante testes.
   - **Entrega final:** informar testes executados, resultados, falhas relevantes
     pendentes e limites da validação. Não declarar a validação completa enquanto
     houver falhas relevantes sem resolução.
   - Verificar o status do Git antes e depois do trabalho para preservar alterações
     preexistentes e identificar precisamente o diff produzido.
   - **Isolamento obrigatório:** testes não podem usar o banco da empresa. A fixture
     deve redirecionar dependências HTTP, engine do startup e SessionLocal para
     o banco temporário e restaurar settings ao terminar. Não importar a fábrica
     real para gravar em teste; usar `test_session`. Ver
     `backend/tests/test_database_test_isolation.py`.
2. **Mapeamento de Impacto e Limites Modulares:**
   - Respeite rigorosamente a divisão modular: `estoque`, `produtos`, `receitas`, `compras`, `produção`, `vendas`, `expedição`, `financeiro`, `relatorios_e_impressao` e `core`.
   - **Isolamento de Persistência:** É estritamente proibido o acesso direto ao banco de dados SQLite por telas ou módulos não responsáveis pela persistência. Toda leitura ou mutação deve transitar exclusivamente através dos serviços de domínio e endpoints da API REST.
   - Novos recursos devem utilizar os serviços e interfaces existentes, sem contornar as validações centrais.
3. **Preservação de Comportamento e Contratos:**
   - **Proibição de remoção ou substituição silenciosa:** Nenhuma regra de negócio, validação, tabela ou endpoint pode ser alterado de maneira incompatível sem explicação de impacto e autorização explícita do usuário.
   - O livro-razão contábil (`inventory_movements`) e o livro-caixa (`cash_flow_entries`) são estritamente **append-only**. Nunca altere ou apague movimentações existentes.
4. **Tratamento Padronizado de Erros:**
   - A API backend deve emitir códigos de erro estáveis e estruturados (`INSUFFICIENT_STOCK`, `IDEMPOTENCY_PAYLOAD_MISMATCH`, etc.).
   - O cliente Flutter deve mapear esses códigos de erro para mensagens amigáveis em português por meio do `ApiErrorMapper`, sem expor stack traces ou termos técnicos ao operador.
5. **Migrações de Banco de Dados:**
   - Toda alteração estrutural no SQLite deve ser implementada via migração versionada do Alembic (`alembic revision -m "..."`).
   - Respeitar a cadeia sequencial de dependências das tabelas, preservando `PRAGMA foreign_keys = ON` sem dependências circulares.
6. **Validação Contínua (Não-Regressão):**
   - Ao concluir uma alteração de código, execute os testes relacionados e amplie
     a validação conforme o impacto descrito acima. Registre falhas preexistentes
     e novas separadamente; testes novos devem cobrir a funcionalidade adicionada
     sem enfraquecer as garantias de segurança, integridade ou isolamento.

---

## 3. Diretrizes de Backend (Python / FastAPI / SQLite)

- **Transações de Escrita:** Sempre utilizar `BEGIN IMMEDIATE` para mutações no banco de dados SQLite. Isso previne deadlocks e corridas de concorrência (*TOCTOU*), garantindo que saldos nunca fiquem negativos.
- **Idempotência:** Toda operação comercial (compras, montagens, vendas, saídas, acertos, ajustes, baixas) deve ser envolvida no `IdempotencyManager` com `X-Idempotency-Key` e hash SHA-256 do payload.
- **Valores Monetários e de Custo:**
  - Valores monetários comerciais são sempre números inteiros de **centavos** (`cents`), sem ponto flutuante (*float*).
  - O Custo Médio Ponderado Móvel (CMPM) unitário na unidade-base é mantido em escala fixa de **microcentavos** (`cost_price_microcents INTEGER`, onde 1 centavo = 10.000 microcentavos) com arredondamento bancário *half-even*, congelando o custo unitário da cesta pronta em centavos inteiros (`unit_cost_cents`).
- **Valores Temporais:** Todos os carimbos de data/hora gravados no banco devem estar em **UTC**.

---

## 4. Diretrizes de Front-End (Flutter / Dart)

- **Botões flutuantes:** preservar o FAB sobre o conteúdo e aplicar `fabScrollPadding` no final da lista/rolagem. Por preferência explícita do usuário, não colocar as ações dessas páginas em uma barra inferior fixa. Consultar [docs/LAYOUT_E_ACOES_DE_PAGINA.md](docs/LAYOUT_E_ACOES_DE_PAGINA.md).

- **Abordagem Mobile First com Responsividade Desktop:** As telas devem ser fluidas e usáveis em smartphones/tablets Android, bem como em telas amplas do Windows Desktop.
- **Componentes Compartilhados:** Reutilizar componentes padronizados em `client/lib/widgets/shared/` para formulários, botões, tabelas, cartões e diálogos. Evitar duplicar lógicas de exibição e máscaras entre telas.
- **Internacionalização e Formatação Centralizada:**
  - Todos os textos visíveis devem ser obtidos exclusivamente via `context.l10n`, utilizando o catálogo `client/lib/l10n/app_pt.arb` e código gerado por `flutter gen-l10n`. Proibido manter strings hardcoded nos widgets.
  - Formatações de moeda (`R$ X,XX`), datas e números com unidade de medida devem utilizar o utilitário centralizado `AppFormatters`.
- **Comunicação Segura com o Servidor:** Utilizar exclusivamente o `ApiClient`, que realiza validação de impressão digital SHA-256 do certificado TLS local e injeta tokens de autenticação de dispositivo.

---

## 5. Diretrizes da Simplificação da Fase 6 e Consistência Operacional

> **Rotina arquivada na interface desde 13/10/2026:** responsáveis, expedição,
> conferência e acerto não são menus ativos. Esta seção preserva regras de
> integridade do backend e de dados históricos. Não usar suas descrições como
> pedido de implementação ou de restauração dessas telas. Ver
> [funções arquivadas](docs/FUNCOES_ARQUIVADAS.md).

A Fase 6 atende à rotina real de uma pequena empresa de cestas básicas e rege a custódia temporária de mercadorias:

### 5.1. Vendas sob Custódia e Prevenção de Dupla Baixa de Estoque
- Toda venda de cesta colocada sob custódia de um responsável deve ser registrada **uma única vez** no serviço de vendas da Fase 5 (`sales`).
- **Baixa de Estoque Exclusiva de Trânsito:** A baixa de estoque dessa venda incide **exclusivamente sobre as unidades sob custódia (`TRANSIT`)**, e **NUNCA novamente sobre o estoque da loja (`STORE`)**.
- Vendas realizadas diretamente no balcão da loja (`DIRECT_STORE`) mantêm o comportamento homologado da Fase 5 (baixa de `STORE`).
- A venda mantém o vínculo com a saída (`dispatch_id`), o responsável (`responsible_person_id`), o cliente e o CMV congelado.
- **Proibição de Sistemas Paralelos:** Proibido criar outro subsistema de vendas, títulos ou clientes para a Fase 6.
- **Extensão Mínima de Arquitetura:** A Fase 6 adicionará `location_type` (`STORE` vs `TRANSIT`) e `responsible_person_id` em `inventory_movements`, ajustando `create_sale` para validar e baixar o saldo correto dependendo do `sale_mode`.

### 5.2. Conferência de Estoque e Equação de 4 Termos
- **Equação Canônica:**
  $$\text{Quantidade Retirada} = \text{Vendidas} + \text{Devolvidas Intactas} + \text{Avariadas ou Perdidas} + \text{Ainda sob Custódia / Não Localizadas}$$
- **Devolvidas Intactas:** Retornam formalmente ao estoque vendável do galpão (`STORE`) após conferência (`DISPATCH_RETURN`).
- **Avariadas ou Perdidas:** Baixadas de `TRANSIT` como perda operacional (`DISPATCH_LOSS`) com justificativa textual obrigatória, **sem retorno fictício ao estoque vendável**.
- **Itens Ainda sob Custódia / Não Conferidos:** Não são tratados como vendidos, devolvidos ou perdidos; permanecem sob a custódia pendente da pessoa responsável.
- **Divergências Não Resolvidas:** Registradas como pendências de investigação (`PENDING_INVESTIGATION`). É proibido forçar um fechamento artificialmente conciliado.
- **Auditoria do Fechamento:** O fechamento registra quem conferiu, quando ocorreu (timestamp UTC) e todos os valores apurados.

### 5.3. Acerto Financeiro e Segregação de Meios de Pagamento
- **Dinheiro Físico em Mãos:** Papel-moeda recebido na rota que deve ser entregue fisicamente ao caixa da empresa.
- **Pagamentos Recebidos Diretamente na Conta da Empresa:** Pix ou cartões creditados diretamente na conta da ZM já ingressaram no patrimônio da empresa e **NÃO devem ser cobrados em dinheiro físico do entregador**.
- **Cobranças de Fiados Antigos:** Amortizações de títulos da Fase 5 recolhidas pelo entregador com identificação do meio de pagamento.
- **Despesas Autorizadas Abatidas:** Gastos aceitos (combustível, pedágio) com valor, justificativa e autorização formal.
- **Divergências Financeiras:** Mantidas como `PENDING_INVESTIGATION`.
- **Prevenção de Duplicidades:** Faturamento bruto $\neq$ dinheiro físico a entregar. Não gerar lançamentos duplicados de caixa.

### 5.4. Preservação Estrita das Fases Concluídas (1 a 5)
- É expressamente proibido resolver divergências operacionais por exclusões (`DELETE`), alterações silenciosas (`UPDATE` sem rastreio) ou lançamentos fictícios. As correções ocorrem exclusivamente por lançamentos reversos rastreáveis.

---

## 6. Diretrizes do Módulo de Relatórios, Planilhas e Impressão (Fase 8)

1. **Modalidades de Saída:**
   - **Relatórios Preenchidos:** PDFs gerados automaticamente a partir dos dados do sistema com totais consolidados.
   - **Formulários em Branco:** Documentos A4 para escrita manual à caneta, com linhas altas e confortáveis (8 a 10 mm), colunas largas e checkboxes de conferência (sem tabelas comprimidas nem fontes minúsculas).
   - **Planilhas Digitais:** Arquivos CSV e XLSX para consulta e auditoria externa.
   - **Documentos PDF Paginados:** Papel comum A4, margens de 15 mm, paginação `Página X de Y` e cabeçalho padrão ZM.
2. **Formulários do projeto original; escopo ativo atual A, B e D:**
   - **Formulário A:** Vendas fiadas, pagamentos e quitação.
   - **Formulário B:** Contas a pagar.
   - **Formulário C — arquivado na interface:** Saídas e conferência diária; preservar referências históricas sem reintroduzir a opção no cliente.
   - **Formulário D:** Conferência física do estoque (balanço/inventário).
3. **Impressão Direta Multiplataforma (Flutter):**
   - Uso dos pacotes `pdf` e `printing`.
   - Geração de PDF vetorial em memória e envio ao spooler nativo do sistema operacional (Windows Print Spooler no desktop e Android Print Framework no mobile).
   - Pré-visualização com `PdfPreview` e botão de imprimir pelo próprio app, sem exigir Excel ou visualizadores externos.
   - **Compatibilidade Epson Wi-Fi:** Integração direta com drivers ESC/P-R do Windows e Mopria Print Service / Epson Print Enabler no Android. Proibido o uso de protocolos proprietários crus ou sockets diretos.
   - **Rota de Contingência:** Botões diretos para Salvar PDF no disco local e Compartilhar PDF caso a impressora física esteja inacessível.
4. **Padrão de Templates Reutilizáveis:**
   - `DocumentBuilder` com `ReportHeader`, `ReportFooter` e `ReportTableTheme` compartilhados entre todos os formulários.

---

## 7. Diretrizes para Futura Integração com IA (Preparação Arquitetural)

> [!IMPORTANT]
> **NÃO IMPLEMENTE IA NEM ADICIONE DEPENDÊNCIAS DE IA NESTE MOMENTO.**
> Esta seção rege o design para quando a funcionalidade for formalmente autorizada.

1. **Arquitetura Desacoplada (Provider Pattern):**
   - Adaptadores intercambiáveis (`GeminiProviderAdapter`, `OpenAIProviderAdapter`, `MockProvider`) sob interface `BaseAIProvider`.
2. **Custódia Segura de Chaves:**
   - Chaves de API mantidas exclusivamente nas variáveis de ambiente do backend. Proibido no cliente Flutter.
3. **Acesso Declarativo e Proibição de SQL Arbitrário:**
   - A IA **NUNCA** terá acesso a conexões diretas do SQLite nem permissão para rodar comandos SQL livres.
   - Acesso estrito por ferramentas declarativas autorizadas do backend (`get_stock_ruptures()`, `simulate_basket_production()`, etc.).
4. **Human-in-the-Loop Obrigatório:**
   - Toda proposta de alteração comercial/financeira deve ser retornada como `AIProposal` e exigir confirmação manual do operador humano.
5. **Operação Offline por Padrão:**
   - O sistema opera 100% autônomo offline em rede local sem IA. O recurso de IA é o único dependente de Internet quando acionado e pode ser desativado via `AI_ENABLED=false`.
6. **Trilha de Auditoria:**
   - Registro permanente em `ai_interaction_logs`.

---

## 8. Status de Conclusão e Entrega Final do Projeto

**Esta seção registra a entrega original.** Não é uma declaração de que todas
as telas continuam ativas, nem uma contagem atual de testes/binários. Produção
separada e desmontagem (Fase 4), expedição e responsáveis (Fase 6), tesouraria
(parte da Fase 7) e relatórios exclusivos/formulário C (parte da Fase 8) estão
arquivados na interface. Montagem na venda, compras, vendas, fiado, contas a pagar
e consultas simplificadas continuam ativos. Consultar [o índice atual](docs/README.md).

O projeto concluiu e homologou **100% de todas as 9 Fases planejadas**:
- **Fase 1:** Fundação Arquitetural, TLS autoassinado com fingerprint SHA-256, Pareamento PIN, SQLite WAL, idempotência.
- **Fase 2:** Produtos, Embalagens com Conversão de Unidades e Versionamento Imutável de Receitas.
- **Fase 3:** Livro-Razão *append-only*, Compras com Conversão, CMPM em Microcentavos e Estornos Condicionados a Saldo.
- **Fase 4:** Motor de Produção, Lotes Padrão e Personalizados, Triagem de Desmontagem e Congelamento de Custo Unitário.
- **Fase 5:** Vendas de Balcão e Rotas, Cadastro de Clientes, Contas a Receber (Fiado) e Montagem Simultânea sob Demanda.
- **Fase 6:** Saídas Físicas (`STORE` -> `TRANSIT`), Responsáveis por Rotas, Baixa Exclusiva de Trânsito, Equação Canônica de 4 Termos e Acerto Segregado.
- **Fase 7:** Gestão Financeira Completa, Tesouraria, Contas a Pagar (`BUSINESS` vs `PERSONAL_WITHDRAWAL`) e Livro-Caixa Imutável.
- **Fase 8:** Dashboard Consolidado, DRE Gerencial, Exportação Digital (CSV e XLSX), Formulários A4 em Branco para Prancheta e Módulo de Impressão Direta (Windows e Android Spoolers, compatibilidade Epson Wi-Fi).
- **Fase 9:** Auditoria Final, Teste Ponta a Ponta (180 testes backend e 93 testes Flutter 100% aprovados), CLI e Agendamento de Backup Quente com Verificação de Integridade, Scripts de Inicialização Automática e Firewall, Compilações Nativas de Produção (Windows Release `.exe` e Android Release APK de 74.1 MB) e 4 Manuais Operacionais e Técnicos (`docs/`).

**ESTADO FINAL:** Sistema pronto para implantação em produção. Qualquer manutenção futura deve respeitar estritamente as regras de imutabilidade contábil, atomicidade sob `BEGIN IMMEDIATE`, tipagem monetária em centavos/microcentavos e testes automatizados contínuos.
## Exceção autorizada: produto nunca utilizado

O usuário autorizou a exclusão definitiva de produtos nunca usados. A ação é
explícita e separada da inativação. Revalidar no backend, dentro de BEGIN IMMEDIATE,
a ausência de vínculos em todas as receitas, compras, itens de produção e movimentos.
Remover apenas cadastros dependentes nunca usados; jamais excluir registros de
transações ou movimentos. Preservar a rota anterior de inativação e a confirmação
na interface. Consultar docs/PRODUTOS_E_FORMAS_DE_COMPRA.md.
