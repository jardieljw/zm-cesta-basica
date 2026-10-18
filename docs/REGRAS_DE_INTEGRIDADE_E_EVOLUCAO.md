# Regras de integridade dos dados e evolução do app

Revisão: **14/10/2026**. [Índice](README.md).

Este contrato reúne as regras permanentes de proteção do histórico comercial e
financeiro. Aplica-se às ações do operador e às mudanças realizadas por pessoas
ou agentes no código. Complementa [ARCHITECTURE.md](../ARCHITECTURE.md).

## O que está sendo protegido

**Integridade física:** o arquivo SQLite pode ser aberto e suas estruturas estão
consistentes. **Integridade de vínculos:** uma venda continua ligada aos cadastros
e operações necessários. **Integridade comercial:** valores, consumos, datas e
estornos representam corretamente os fatos. Um banco pode passar na verificação
estrutural e ainda ter cálculos comerciais errados; são verificações diferentes.

Uma edição válida pela interface não deve corromper o arquivo inteiro. Mudanças
mal planejadas no código, migrações, remoção de vínculos ou interpretação errada
de unidades podem causar falhas ou perda de sentido dos dados. Não prometer risco
zero apenas porque existem testes ou backups.

## Contratos permanentes

1. **Preservar o passado.** Não apagar nem reescrever movimentos de estoque ou
   caixa para corrigir operações. Acrescentar estornos/ajustes rastreáveis pelos
   serviços próprios. Mudanças de status autorizadas, como cancelar uma venda,
   não são exclusão física de seu registro.
2. **Não recalcular o passado usando cadastros atuais.** Receitas usadas,
   composição efetiva, quantidades e custos congelados devem continuar
   interpretáveis. Editar uma composição cria uma nova edição. Preços atuais
   não substituem valores efetivos de compras e vendas anteriores.
3. **Não romper referências.** Excluir definitivamente apenas cadastros que
   atendam às verificações do domínio. Status cancelado, saldo zero e inatividade
   não removem vínculos históricos. Nunca liberar exclusão somente removendo
   uma checagem ou adicionando exclusão em cascata sobre transações.
4. **Preservar o significado de unidades e campos.** Centavos não viram reais,
   gramas não viram quilos e datas não mudam de fuso por uma simples alteração
   do nome ou tipo de uma coluna. Conversões exigem plano explícito e validação.
5. **Operações comerciais são indivisíveis.** Validar e gravar na transação
   central. Se uma parte falhar, desfazer a operação inteira. Reenvio com a mesma
   identidade não pode duplicar consumo, produção, venda ou pagamento.
6. **Interface não contorna domínio.** Mudar botão, rótulo, visibilidade ou fluxo
   não permite remover validações do backend ou acessar SQLite diretamente.
   O servidor permanece responsável pelas regras e pela persistência.
7. **Dados antigos continuam suportados.** Mudanças de estrutura são migrações
   Alembic versionadas. Atualizar o modelo Python não basta para atualizar um
   banco preenchido; `create_all` não substitui migração de tabelas existentes.
8. **Evolução não é limpeza da empresa.** Não apagar arquivo/tabelas, criar novo
   banco, restaurar backup ou remover dados de produção como efeito colateral
   de uma alteração visual ou funcional.

## Exemplos: o que pode mudar

| Pedido | Tratamento |
| --- | --- |
| Mudar cor, texto ou animação | Alteração da apresentação; conservar payloads e regras de domínio. |
| Não mostrar data/hora na tela | Pode ocultar a apresentação preservando os campos e registros no banco. |
| Remover/substituir data/hora do banco | Avaliar filtros, relatórios, ordenação, auditoria e dados antigos; preparar alternativa compatível antes de executar. Não perder datas antigas silenciosamente. |
| Acrescentar um campo | Definir migração, valores existentes, compatibilidade entre cliente/servidor e validações. |
| Corrigir nome ou preço de referência | Usar edição permitida do cadastro; verificar impacto da apresentação histórica. Não substituir valores comerciais congelados. |
| Corrigir receita | Nova edição e preservação da anterior; montagens antigas usam sua composição registrada. |
| Corrigir compra/venda/pagamento confirmado | Usar cancelamento/estorno correspondente e novo registro quando necessário. Não atualizar livremente movimentos. |
| Retirar cadastro usado do catálogo | Inativar/arquivar conforme o fluxo; preservar relações. Exclusão física exige uma solução específica que conserve o histórico. |
| Limpar testes | Planejar ambiente de teste ou retirada de cadastros sem romper dados reais. Cancelamento não transforma uma transação usada em cadastro nunca utilizado. |

Nenhum arquivo de código é intocável por si só. O que precisa permanecer é o
contrato dos dados e das operações. Implementações podem ser reorganizadas ou
substituídas se mantiverem essas garantias e forem verificadas.

## Procedimento para quem altera código

Antes de alterar uma regra, coluna ou possibilidade de edição/exclusão:

1. Mapear telas, endpoints, serviços, tabelas, referências, relatórios e testes
   afetados; distinguir mudança visual de mudança no significado dos dados.
2. Explicar ao usuário efeitos sobre registros existentes, limitações e uma
   alternativa que preserve os contratos. Pedido funcional genérico não equivale
   a autorização para apagar histórico ou retirar proteções.
3. Implementar e validar em bancos de teste. Mudança de esquema deve ser testada
   também sobre uma cópia representativa já preenchida, não só em banco vazio.
   Incluir operações canceladas e registros antigos quando relevantes.
4. Antes de migrar um banco real, criar backup verificado, definir ordem de
   atualização de servidor/clientes e um caminho de recuperação. Não executar
   teste destrutivo no banco da empresa.
5. Verificar estrutura e referências (`integrity_check`, `foreign_key_check`),
   além de saldos, valores, vínculos e comportamento dos fluxos afetados. Suíte
   aprovada não substitui teste de migração nem avaliação de impacto.
6. Documentar a alteração e os resultados. Para uma mudança incompatível ou
   destrutiva, exigir decisão explícita após apresentar impacto e recuperação;
   não tratar um pedido de aparência/uso como essa decisão.

Uma migração inversa não garante recuperação de valores apagados. O plano deve
conservar a informação necessária ou usar o backup anterior, considerando os
registros novos criados após a atualização.

## Proteções existentes versus trabalho futuro

Já existem: chaves estrangeiras ativadas, transações `BEGIN IMMEDIATE`, rollback
das operações comerciais, idempotência, proteção de estoque e caixa contra edição
e exclusão, validação de vínculos de produtos e fluxos de backup verificado.

Referências: [database.py](../backend/app/core/database.py),
[idempotency.py](../backend/app/core/idempotency.py),
[movimentos](../backend/app/models/movements.py),
[financeiro](../backend/app/models/financial.py),
[exclusão de produtos](../backend/app/services/product_catalog.py) e
[backup](../backend/app/core/backup.py).

Este documento não comprova que todas as migrações antigas foram auditadas,
que um agendamento está instalado ou que toda situação futura já possui teste.
A revisão completa do banco e das formas de correção será um trabalho próprio,
conforme a preferência do usuário de aprofundar o assunto em outro chat.

Texto de documentação orienta agentes e desenvolvedores, mas não bloqueia por
si só uma edição de código. As proteções precisam continuar aplicadas no banco,
serviços, testes e processo de atualização. Não desativar essas camadas para fazer
uma operação passar.
