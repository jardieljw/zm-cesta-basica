# Rodada de projeto: registrar um pagamento

Data: **15/10/2026**. Situação: **prévia navegável verificada; avaliação do usuário pendente**.
Continua sendo planejamento. Esta rodada não alterou o cliente Flutter, os
serviços financeiros, o banco da empresa ou os contratos da API.

**Retorno posterior em 16/10:** a conferência foi aceita. O usuário pediu integral
por padrão, parcial opcional e maior arredondamento. Este documento conserva a
rodada original; o estado atualizado está na
[rodada de 16/10](RODADA_FRONTEND_INTEGRAL_2026-10-16.md).

## Pergunta desta rodada

É fácil encontrar uma conta, entender o saldo, registrar um pagamento já
realizado e conferir o resultado? A etapa separada de conferência é uma proposta
a avaliar, inclusive quanto ao esforço que acrescenta à rotina.

O usuário autorizou continuar o próximo passo e manter o registro do progresso
e dos aprendizados. Isso autoriza esta demonstração; não significa que o percurso
já tenha sido aprovado ou que o piloto de produção tenha começado.

## Exemplo que pode ser percorrido

1. Financeiro → Pagar → Fornecedor de alimentos.
2. Detalhe com R$ 680,00 originais, já pago, saldo, vencimento, origem e histórico.
3. Registrar pagamento: informar R$ 300,00, data, forma efetiva e observação opcional.
4. Conferir pagamento: revisar os dados, alterar campos ou confirmar o registro.
5. Conclusão → Ver conta e histórico: R$ 300,00 pagos e R$ 380,00 em aberto.
6. Retornar à lista: saldo do período passa de R$ 1.280,00 para R$ 980,00.

Também é possível registrar os R$ 380,00 restantes e verificar a quitação. O
exemplo tem duas contas no período; a de embalagens mantém R$ 600,00 em aberto.
O filtro da listagem é preservado. O resumo identifica que abrange todas as
contas do período, mesmo quando a lista mostra apenas uma situação.

A composição mobile mantém os cinco destinos inferiores. Em largura ampla,
o computador usa navegação lateral e contexto das contas ao lado do detalhe.
Ao estreitar, o conteúdo se reorganiza. O FAB de registrar tem espaço reservado
no final do conteúdo; a navegação entre áreas continua distinta dessa ação.

## Contratos existentes consultados

- [Guia de Contas a Pagar](CONTAS_A_PAGAR.md).
- [Schemas financeiros](../backend/app/schemas/financial.py), em especial
  `PayablePaymentCreate` e as respostas de conta/detalhe.
- [Serviço financeiro](../backend/app/services/financial.py), registro de
  pagamento parcial/total limitado ao saldo e estados OPEN/PARTIAL/PAID.
- [API de pagamentos](../backend/app/api/v1/payables.py), que já usa idempotência
  transacional para criar o registro.

O operador não precisa escolher conta bancária nesse fluxo atual. Forma prevista
da obrigação e forma efetiva do pagamento são diferentes: o exemplo pode prever
Boleto e ter um pagamento registrado por Pix. A prévia registra informações
locais fictícias; não envia dinheiro nem cria uma transferência bancária.

## Pesquisa nova e aplicação proposta

Consultas realizadas em 15/10/2026; estas fontes informam o desenho, sem impor
ao ZM todos os padrões do produto de origem.

| Fonte | Aprendizado e aplicação nesta rodada | Limite |
| --- | --- | --- |
| [GOV.UK — Check answers](https://design-system.service.gov.uk/patterns/check-answers/) | Permitir conferir e corrigir dados antes do envio, com a ação final explícita. A revisão mostra valor, data, forma, observação e saldo resultante; Alterar retorna ao campo preenchido. | A etapa extra pode ter custo na rotina. Sua utilidade no ZM continua em avaliação. |
| [GOV.UK — Error summary](https://design-system.service.gov.uk/components/error-summary/) | Relacionar o resumo dos erros aos respectivos campos e usar mensagens coerentes. A prévia preserva os dados e leva ao primeiro campo inválido; os atalhos do resumo também chegam aos campos. | A adaptação usa controles nativos e foco no campo; não replica todo o componente GOV.UK nem sua aparência. |
| [W3C — Status messages, WCAG 4.1.3](https://www.w3.org/WAI/WCAG22/Understanding/status-messages.html) | Comunicar progresso, resultado e erros também por semântica acessível. A prévia inclui estados de ocupado, mensagens de status e alertas. | Leitor de tela, teclado virtual e integração nativa ainda precisam de validação; não se declara conformidade completa. |

## Aprendizados da construção e da revisão

- **Separar os valores:** original, já pago e saldo precisam estar juntos no
  detalhe. O saldo após este registro aparece antes da confirmação e na conclusão.
- **Mensagem de erro acompanha a correção:** a inspeção encontrou aviso antigo
  ainda visível para um valor já corrigido. A prévia passou a reavaliar o campo
  ao sair dele ou concluir a seleção, sem reconstruir o formulário nem perder foco.
  A verificação agora cobre a retirada desse aviso e do estado inválido.
- **Resumo e filtro têm escopos explícitos:** o total é de todas as contas do
  período; o seletor filtra a lista. Um resultado vazio da lista não deve sugerir
  que o total financeiro seja zero. A pendência mostrada no Início também é
  atualizada quando uma conta é quitada.
- **Evitar repetição enquanto registra:** a confirmação passa a ocupado e bloqueia
  novos cliques até terminar a simulação. No app real isso deverá coexistir com
  a idempotência existente no servidor; desabilitar botão sozinho não basta.
- **Falha conhecida mantém os dados:** o cenário opcional falha antes de gravar,
  conserva a revisão e permite nova tentativa. Uma resposta de rede desconhecida
  no app real exigirá tratamento próprio, sem afirmar que nada foi registrado.
- **Ajustes e restauração:** o teste precisou instalar o substituto controlado de
  `Tweak` após o carregamento do contêiner e reiniciar a demonstração em elementos
  novos. O primeiro erro foi da instrumentação, não um defeito comprovado do
  painel do chat. A verificação continua sem automatizar esse painel nativo.
- **Preservar a rodada:** fonte, contêiner, script, relatório e capturas foram
  copiados para o projeto; as referências anteriores foram conservadas.

## Verificação e evidências

O [relatório preservado](referencias_frontend/rodada-pagar-2026-10-15/jornada-pagar-verificacao.json)
registra **5 grupos de verificação e 32 combinações de estado/largura aprovadas**,
sem erros JavaScript observados, no Edge sem janela. Larguras externas de
780, 412, 360 e 320, com 32 px a menos no iframe de inspeção.

Cobertura: entrada inválida, valor zero/negativo/acima do saldo, correção do erro,
rascunho entre áreas, revisão editável, clique repetido, pagamento parcial,
saldo/histórico, quitação, falha antes de gravar e nova tentativa, filtro, ausência
de resultados, restauração e aparência após restaurar. A composição ampla e a
refluência estreita foram verificadas; imagens claras/escuras foram inspecionadas.

O [arquivo da rodada](referencias_frontend/rodada-pagar-2026-10-15/README.md)
explica as 13 cópias e seu manifesto de integridade. Esta é evidência da prévia,
não teste de pagamento real, API, Flutter, iOS ou implementação concluída.
As suítes do aplicativo não foram repetidas para esta alteração de planejamento.

## Questões que permanecem abertas

1. Avaliar com o usuário se a sequência e a conferência são claras e confortáveis
   para o uso cotidiano; não transformar a proposta em regra global antes disso.
2. Definir a integração temporal antes do piloto: a prévia escolhe um dia; a API
   recebe `datetime`. Não converter silenciosamente o dia em horário/fuso inventados.
3. Especificar no incremento real a recuperação de resposta desconhecida,
   reutilização da identidade da tentativa e consulta do resultado no servidor.
4. Validar máscara monetária completa, colagem/cursor, texto ampliado, leitor de
   tela, teclado virtual e convenções Android/iOS/Windows no cliente real.
5. Depois do retorno, consolidar os padrões candidatos e adaptar a jornada a
   Receber. A escolha do primeiro piloto de implementação segue pendente.
