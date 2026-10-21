# Importação de faturas: resultado solicitado pelo usuário

**Direção vigente — 19/10/2026, esclarecimento explícito do usuário.**
Este registro corrige a prioridade do roteiro técnico anterior. O produto é
um aplicativo simples para uso no próprio estabelecimento. O resultado exigido
é centralizar as dívidas dos cartões, não completar uma plataforma bancária.

## Esclarecimento vigente — 20/10/2026

O usuário quer centralizar faturas dos seus bancos para enxergar gastos da
empresa e pessoais, contas a pagar e parcelas junto das informações de entrada
e resultado do negócio. A empresa é pequena e sustenta suas despesas pessoais;
o produto deve ajudar a distinguir esses gastos sem exigir conhecimento bancário.
Essa distinção não autoriza presumir finalidade pela loja nem alterar o cálculo
do resultado empresarial sem explicação.

- Importar o PDF/CSV, reconhecer os dados e organizar o que for comprovado, com
  poucas perguntas em linguagem comum quando faltar uma decisão real.
- Tornar claro se o documento foi apenas guardado ou se já entrou no financeiro,
  onde encontrá-lo e qual ação está disponível. Um resultado de teste salvo não
  deve ser apresentado ao operador como se ainda faltasse decidir a mesma coisa.
- **Excluir/desfazer uma importação errada é requisito explícito.** Ausência identificada no retorno anterior; o recorte E5.7 implementa
  a ação revisada de retirada (POST idempotente). O pedido é retirar a importação da lista e desfazer os efeitos que ela criou no
  financeiro/parcelas, sem apagar compras ou pagamentos independentes. Casos com
  vínculos/pagamentos exigem definir o desfazimento coerente; apagar só o arquivo
  PDF não satisfaz o pedido. Em seguida o usuário autorizou executar as correções
  necessárias. O funcionamento atual e os limites estão no guia de Pagar.
- Não expor OCR, conciliação, ocorrência, cobrança positiva ou outros termos
  técnicos como conhecimento exigido para importar uma fatura. Orientação deve
  dizer o que aconteceu, o que falta fazer e o efeito da ação.
- Explicar diferenças necessárias entre fatura e extrato sem misturar caminhos
  legados/atuais e múltiplas revisões na tarefa comum. A E5.6 só unificou a entrada
  das faturas compatíveis com o contrato atual; não simplificou toda a lista.

O usuário confirmou acesso a filtros e visualização/rolagem dos itens da cobrança
90 pelo botão **Pagar e amortizar**; não relatou registrar pagamento nem validar
a agenda. Rejeitou a compreensão da conferência e voltou a apontar excesso de
funções. A menção a um manual PDF completo expressou essa dificuldade; não deve
ser tratada como solução escolhida ou autorização para produzir um manual extenso.
IA continua uma possibilidade a avaliar, sem integração/instalação autorizada.
Críticas de aparência e pedido de padrão global ficam exclusivamente na
[memória do front-end](MEMORIA_E_PESQUISAS_FRONTEND.md), para outra conversa.

## O que precisa funcionar

Importar PDF ou CSV de uma fatura, reconhecer automaticamente os dados disponíveis
e levá-los a Contas a Pagar, com:

- banco e cartão/origem vinculados de forma identificável;
- estabelecimento/descrição original e observações quando disponíveis;
- valor exato, data da compra e vencimento da cobrança, sem confundi-los;
- compra à vista ou parcela atual/total, quando informadas;
- visão das dívidas por dia, semana e mês e das parcelas restantes nos meses
  seguintes, sem duplicar a dívida ao importar a próxima fatura;
- créditos/estornos, encargos e pagamentos interpretados de modo que o total
  devido seja o correto, sem transformar pagamento já feito em dívida nova.

O objetivo é **automatizar o preenchimento**, não pedir que o operador recadastre
ou classifique manualmente todas as linhas. Conferência final curta e dúvidas
pontuais continuam compatíveis com essa intenção. Categorização solicitada
significa principalmente banco/cartão, estabelecimento, cobrança e parcelas;
não significa exigir uma classificação contábil detalhada como pré-requisito.
Uso empresarial/pessoal não pode ser deduzido apenas pelo nome da loja.

Parcelas futuras são requisito do usuário. Quando o documento só comprovar a
parcela atual, o aplicativo deve distinguir o que foi informado do que é previsão
calculada. Não garantir valor/vencimento futuros exatos se faltarem informações.
O comportamento de previsão e substituição pela cobrança efetivamente importada
precisa ser implementado; não está entregue hoje.

## Critério de entrega

Usar os arquivos privados do usuário como amostras de teste autorizadas. Conferir
linha a linha banco, descrição, datas, sinal, valor e parcelas contra referência
independente; verificar controles do documento e o resultado visível em Contas
a Pagar. Reimportar o mesmo arquivo e depois a fatura seguinte para demonstrar
ausência de duplicidade. Um centavo divergente é um problema a resolver, sem
ajuste artificial. Aceitação depende desse percurso, não do número de testes,
de um endpoint diagnóstico ou de o servidor estar ativo.

Não é necessário homologar todos os bancos ou construir funções extras para
entregar os formatos que o usuário realmente utiliza. Novas capacidades precisam
resolver um impedimento concreto encontrado nessas amostras.

## O que a evidência atual demonstra — e o que ainda falta

Há importação PDF/CSV, origens, itens, revisão e geração limitada de títulos.
Servidor/cliente foram ativados; 488 testes backend e a validação Flutter anterior
estão registrados. Isso não conclui o resultado solicitado.

Na última [rodada HTTPS](validacoes_financeiras/correcao-2026-10-19/runtime-https.json),
dos sete PDFs disponíveis, um extrato com 28 ocorrências ficou legível e os seis
demais documentos tiveram confirmação bloqueada. Os bloqueios incluem layout
sem leitor, controles/ciclos conflitantes e diferenças entre resumo e detalhes.
Essa rodada não resolveu se toda diferença resulta do documento ou da leitura;
é necessário conferir os originais para diagnosticar cada caso.

A geração atual conserva número/total da parcela informada, mas cria apenas
a cobrança atual, sem agenda das parcelas futuras. Banco/origem e estabelecimento
também precisam ser conferidos no vínculo e na apresentação dos títulos, sem
depender somente de texto concatenado. Créditos/saldo anterior/pagamentos ainda
bloqueiam casos reais da geração. Essas são lacunas do fluxo principal.

O diagnóstico de requisitos de alocação existe só no backend; é apoio técnico,
não função solicitada nem substituto pela importação funcionando. O roteiro
detalhado anterior de planos manuais de alocação não é mais a próxima entrega
obrigatória. Escolher o modelo mínimo que preserve itens, abatimentos, total e
ausência de duplicidade. Avaliar crédito no agrupamento da fatura antes de exigir
que o usuário vincule manualmente cada crédito a uma compra específica. A solução
ainda precisa proteger os totais gerenciais do app; isso não autoriza ignorar
centavos, criar pagamento fictício ou duplicar compras já cadastradas.

## IA: posição honesta e condição de uso

IA não é requisito técnico para todo importador de faturas. CSV estruturado e
PDF digital com layout conhecido podem ser interpretados por código. Isso não
prova que os leitores atuais já façam corretamente o trabalho nos arquivos do
usuário. PDF não fornece automaticamente uma estrutura semântica de linhas e
colunas; documentos escaneados podem exigir OCR.

Fontes primárias reconferidas em **19/10/2026**:

- [pypdf — Extract Text from a PDF](https://pypdf.readthedocs.io/en/stable/user/extract-text.html),
  seções *Missing Semantic Layer* e *OCR vs. Text Extraction*: descreve a ausência
  de estrutura semântica no formato, diferenças entre PDF digital/scan e limites
  de extração. Sustenta investigar o arquivo antes de escolher OCR ou inferência.
- [pdfplumber — documentação oficial do projeto](https://github.com/jsvine/pdfplumber):
  extração de texto, coordenadas e tabelas, com melhor adequação a PDFs gerados
  digitalmente. Demonstra um caminho sem modelo generativo, não certifica a
  interpretação de uma fatura específica.

**Aplicação ao projeto (conclusão de engenharia):** começar corrigindo os layouts
dos arquivos efetivamente usados. Se leitura convencional exigir esforço
desproporcional ou deixar ambiguidades relevantes, comparar auxílio de IA para
extração/interpretação das mesmas amostras. Não há evidência atual que permita
afirmar ser impossível concluir esses arquivos sem IA ou que uma API resolveria
sozinha as divergências. IA também precisa de validação de valores, cobertura e
duplicidade; cálculos e gravações continuam nas regras do aplicativo.

O usuário aceita o custo de uma API para cerca de dez PDFs iniciais se isso for
necessário/útil à solução. Não foi solicitada instalação/chamada imediata, nenhum
provedor foi escolhido e nenhum documento foi enviado a um serviço nesta rodada.
Essa abertura condicional supera proibições antigas de sequer avaliar IA, mas
não substitui a demonstração de necessidade nem a escolha da integração.

## Próximo trabalho delimitado

**Atualização após a auditoria de 19/10/2026:** o item de diagnóstico abaixo foi
executado na [auditoria dos arquivos fornecidos](AUDITORIA_FATURAS_FORNECIDAS_2026-10-19.md).
O usuário pediu em seguida o [plano de implementação por etapas](PLANO_IMPLEMENTACAO_IMPORTACAO_FATURAS.md)
e sua [retomada curta](RETOMADA_IMPORTACAO_FATURAS.md). Os itens de implementação
continuam pendentes; não reabrir o diagnóstico inteiro como primeira tarefa.

1. Conferir privadamente as faturas bloqueadas, identificar por amostra o que o
   leitor perdeu/interpretou incorretamente e o que de fato falta no arquivo.
2. Concluir a importação automática dessas faturas até Contas a Pagar, com
   banco/cartão, estabelecimento, valores e parcelas, usando o menor modelo
   necessário para abatimentos e continuidade das cobranças.
3. Implementar a visão das parcelas restantes e a atualização sem duplicidade
   pela próxima fatura, distinguindo previsão de cobrança comprovada.
4. Demonstrar o percurso com os arquivos do usuário; só então avaliar a entrega.

Mapeamento genérico para qualquer CSV, OFX, Open Finance, coleta Gmail, novos
módulos financeiros e empacotamento para distribuição não são metas deste recorte.
OCR e IA entram somente se as amostras mostrarem necessidade. Preservar interface
aprovada e os dados de outros módulos. As importações bancárias existentes são
testes descartáveis; recuperação contábil desses testes não faz parte do trabalho.

Nesta rodada houve conferência do código/evidências e correção documental de
escopo. Não foram implementados leitores, agenda de parcelas, planos de alocação,
alterações de interface, migrações ou operações no banco.
