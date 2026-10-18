# Rodada de front-end — Receber e movimento

Data: **16/10/2026**. Situação: **prévia aceita como referência (FE-024)**. Pesquisa, documentação
e demonstração local; o cliente Flutter, a API e os dados reais não foram alterados.

## 1. Retorno e decisões desta rodada

O usuário considerou a amostra anterior ótima/perfeita, perguntou quando as
animações seriam implementadas e indicou continuar ao próximo passo. Na pergunta
específica sobre fiado, respondeu: **“Geralmente quitam o saldo inteiro”**.

**Retorno posterior:** após a apresentação desta prévia, respondeu
“Perfeito.👍 :)”. Registrar a jornada e o movimento demonstrado como referência
aprovada; prosseguir ao catálogo de componentes/estados como próximo recorte
proposto, sem tratar isso como autorização de implementação no aplicativo.

- A [amostra de resumo e data](RODADA_FRONTEND_RESUMO_E_DATA_2026-10-16.md) fica
  aceita como referência para avançar, sem transformar cada medida em token final.
- **Receber começa em integral do saldo atual**, com parcial opcional e abertura
  suave do campo. A decisão agora tem evidência própria da rotina de recebimentos;
  não foi deduzida apenas da preferência de Pagar.
- Movimento passa a ter [especificação própria](PADROES_DE_MOVIMENTO_FRONTEND.md),
  com exemplos durante o planejamento e implementação futura no piloto. Os
  números de duração e as transições da amostra são propostas, em avaliação.

## 2. Percurso demonstrado

As apresentações **Receber no celular** e **Receber no Windows** começam na
lista. Compartilham os dados do exemplo e a lógica de interação, com composição
própria para lista móvel e tabela comparável no computador. Cada apresentação
mantém seu estado independente.

| Passo | Exemplo e comportamento |
| --- | --- |
| Encontrar a venda | Ana Souza, venda #1042; Bruno Lima, venda #1043. A lista destaca cliente, venda, vencimento, situação e saldo. |
| Entender o saldo | Venda #1042 de R$ 150,00, já recebeu R$ 50,00: saldo atual de R$ 100,00. |
| Conferir origem | “Ver venda de origem” abre a venda confirmada de R$ 150,00, com cliente, data e condição fiada. |
| Registrar | Integral selecionado calcula R$ 100,00. Parcial revela o campo e conserva data, forma e observação. |
| Revisar | Mostra valor, data e forma antes de confirmar o registro de algo já recebido. |
| Concluir | Integral quita o saldo; histórico conserva o recebimento anterior de R$ 50,00 e acrescenta um de R$ 100,00. |
| Voltar à origem | A venda continua de R$ 150,00. O recebimento não cria uma segunda venda nem aumenta seu valor. |

Bruno tem R$ 200,00 em aberto. O total inicial do recorte é R$ 300,00. Após
quitar o saldo da Ana, fica R$ 200,00. Na alternativa de receber R$ 40,00 da Ana,
restam R$ 60,00 para ela e R$ 260,00 no recorte. Um próximo integral usa R$ 60,00.

O filtro **Em aberto inclui os parciais**. “Quitadas” identifica títulos sem
saldo. Período e situação são preservados no retorno do detalhe. Nenhuma soma
de página incompleta é apresentada como total global; os exemplos carregam os
dois registros do recorte por inteiro.

## 3. Padrão comum e particularidades de Receber

Reutilizar apresentação de moeda/data, seleção Integral/Parcial, revelação,
validação, revisão, mensagens, histórico e política de movimento. Conservar
as diferenças de rótulo, origem e serviço do módulo.

A [mecânica atual](CONTAS_A_RECEBER.md) e o
[contrato da API](../backend/app/schemas/receivables.py) foram consultados:
o título nasce de uma venda fiada, o recebimento pertence a esse título e não
volta a movimentar estoque. Uma venda pode receber várias amortizações; isso
não cria automaticamente várias parcelas ou vendas. A futura integração deve
usar o serviço existente e seus limites, sem duplicar a regra nos widgets.

A amostra usa Pix, dinheiro, cartão e outro, com os códigos do contrato de
Receber. Não impõe conta bancária ao operador nem apresenta a conta interna
resolvida pelo backend como prova do banco utilizado.

**Ainda por detalhar antes do piloto:** recebimento envolvendo várias vendas
do mesmo cliente, estorno com motivo e preservação do histórico, data/hora/fuso
da API e resultado desconhecido ao registrar. Nesta amostra, cada ação é sobre
uma venda específica; não existe distribuição automática pelo saldo do cliente.
A API aceita datetime e a amostra escolhe data civil: não converter isso em
horário inventado sem fechar o contrato de integração.

## 4. Movimento que pode ser avaliado agora

As páginas transitam com deslocamento curto e opacidade; o retorno usa sentido
inverso. O calendário tem entrada curta, e Parcial expande o campo de valor.
Os estados financeiros atualizam diretamente, sem contagem animada do dinheiro.
Esses efeitos não atrasam o processamento nem determinam sucesso.

Nos controles de design, **Movimento → Reduzido** permite comparar o mesmo
percurso sem esses efeitos. A preferência de redução do sistema também é
respeitada, inclusive quando o controle da amostra diz Padrão. Uma mudança de
preferência cancela movimentos opcionais em andamento.

O [padrão de movimento](PADROES_DE_MOVIMENTO_FRONTEND.md) distingue o que já foi
demonstrado, propostas de duração, fontes da pesquisa e itens ainda abertos.
Também registra um cuidado de redução por plataforma, conferido no SDK local,
que precisa entrar no contrato do piloto.

## 5. Evidência e limites

A [pasta desta rodada](referencias_frontend/rodada-receber-2026-10-16/README.md)
preserva fonte, contêiner, script, relatório e capturas. As versões de Pagar,
resumo e data continuam intactas.

A verificação cobre sete grupos por motor: origem/saldo; integral e animações;
parcial e próximo saldo; redução por controle/sistema; falha conhecida; vínculo
de ajustes após restauração simulada; layout móvel/Windows. São **32 combinações
de layout**, com dois motores, dois formatos, quatro larguras externas
(320/360/390/780) e dois temas. Nenhum erro JavaScript foi observado na execução
final. O teste aguarda a aplicação assíncrona da preferência de acessibilidade.

As durações de página e calendário foram observadas em chamadas reais de
animação da prévia; não são benchmark de fluidez ou taxa de quadros. O painel
de design e a persistência do hospedeiro foram instrumentados. WebKit Windows
não é Safari no aparelho; o comportamento Flutter, o leitor de tela e a
performance física continuam por validar na implementação correspondente.

A falha simulada ocorre antes de gravar, com preservação dos campos. O teste de
clique repetido evita uma segunda confirmação nessa simulação; não substitui
idempotência e recuperação no contrato real. Nenhuma suíte funcional do app
foi reexecutada por esta alteração exclusiva de prévia/documentação.

## 6. Próximo alinhamento

Após a aceitação da amostra, o próximo recorte proposto é consolidar o catálogo
mínimo dos componentes e seus estados, usando Pagar e
Receber como casos concretos, antes de escolher o piloto real. Contas, cartões,
importações e documentos terão percursos próprios. Não expandir todos os
módulos nesta rodada nem tomar a aprovação de uma amostra como autorização
para aplicar o novo tema ao aplicativo inteiro.
