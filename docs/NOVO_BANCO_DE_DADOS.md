# Backup e criação de um novo banco

Revisão: **14/10/2026**. [Índice](README.md).

No Windows, abra Configurações → Backup e Segurança do Banco de Dados.
**Gerar Backup Agora** continua criando uma cópia verificada do banco atual.
**Criar e usar um novo banco** gera primeiro um backup obrigatório, cria um banco
vazio e ativa esse banco para toda a empresa. Digite `NOVO BANCO` na confirmação.

Produtos, embalagens, receitas, clientes, compras, produção, estoque, vendas,
contas, pagamentos e movimentações começam vazios. Os dados antigos permanecem
no backup `estoque_backup_pre_new_...db`, listado nos backups do servidor. Os
backups de bancos anteriores são protegidos contra a limpeza automática de
backups antigos; não entram no limite de retenção dos backups comuns. Os
pareamentos, seus hashes de autenticação e revogações são preservados, assim como
os comprovantes técnicos de operações de criação de banco. O banco novo contém a
conta interna padrão exigida pelos serviços financeiros, inicialmente zerada.

O arquivo ativo continua no caminho configurado do servidor, normalmente
`backend/data/estoque.db`; seu conteúdo passa a ser o banco novo. Não há mudança
de URL, certificado ou conexão dos dispositivos. Isso também mantém compatíveis
os scripts de inicialização, migração e backup diário. Para voltar aos dados
anteriores, restaure o backup de segurança. A restauração gera seu próprio backup
do estado atual, permitindo recuperar também o banco novo antes dessa restauração.

Recarregue as páginas abertas nos outros dispositivos depois da troca. O banco é
central, compartilhado por todos eles. A opção de criar banco aparece somente no
Windows, mantendo o Android como cliente operacional.

## Garantias de implementação

- A API exige autenticação real, confirmação explícita e chave de idempotência.
- O servidor usa a API de backup online do SQLite, preservando páginas do WAL.
- O banco temporário recebe todas as migrações Alembic até `head`, além de
  verificações de integridade e de chaves estrangeiras antes da ativação.
  A estrutura também é comparada com os modelos atuais. A migração
  `f8b9c0d1e208` completa a coluna `purchases.payment_method` que faltava na
  cadeia antiga; ela aceita bancos que já possuam a coluna sem duplicá-la.
- A barreira de manutenção espera as requisições anteriores terminarem e retém
  novas requisições enquanto cria ou restaura um banco. A instalação usa o worker
  único previsto em `iniciar_servidor.bat` e `scripts/start_backend_server.bat`;
  não iniciar essa instalação com múltiplos workers.
- Sessões e conexões SQLAlchemy são liberadas antes da ativação. Falhas após o
  início da ativação tentam restaurar imediatamente o backup de segurança.
- O cliente conserva a chave da operação pendente mesmo após perder a resposta
  ou recriar o serviço. O servidor conserva os comprovantes de criação entre
  bancos novos e restaurações, impedindo que a mesma requisição zere dados novos.
- Esta é uma substituição explícita do banco, não uma correção de transações
  individuais. O histórico anterior é conservado no backup; correções normais
  continuam usando os lançamentos reversos previstos pela arquitetura.

Os testes usam bancos temporários. Nenhuma criação ou troca é executada no banco
real apenas por compilar ou instalar o aplicativo. Reinicie o servidor após
atualizar o código para carregar o novo endpoint e a barreira de manutenção.

## Frontend, endpoint e persistência

O diálogo da tela Windows exige a frase de confirmação antes de enviar
`POST /api/v1/backup/new-database`. O pedido também exige uma chave de
idempotência. O servidor revalida autorização, confirmação e estado da operação;
a existência do botão não permite contornar essas regras.

As tabelas comerciais do novo arquivo começam vazias. Os dispositivos e
pareamentos preservados e os comprovantes técnicos necessários são tratados
pelo fluxo de manutenção; a conta financeira interna padrão é criada novamente.
O comprovante em `idempotency_records`, identificado como `NEW_DATABASE`, permite
reconhecer a mesma solicitação após uma troca de banco ou restauração.

Exemplo: criar um banco novo para começar a operação conserva o banco anterior
no backup obrigatório. Cadastrar produtos depois dessa troca e reenviar a mesma
requisição não deve apagar esses produtos por executar a troca uma segunda vez.
Não é um comando para excluir apenas uma venda ou um cliente.

## Onde conferir

- [Tela](../client/lib/views/settings_view.dart) e [serviço](../client/lib/services/backup_service.dart).
- [API](../backend/app/api/v1/backup.py), [contrato](../backend/app/schemas/backup.py), [criação do banco](../backend/app/core/new_database.py), [barreira](../backend/app/core/database_maintenance.py).
- [Testes backend](../backend/tests/test_new_database.py) e [cliente](../client/test/settings_authentication_test.dart).
