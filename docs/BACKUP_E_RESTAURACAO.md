# Backup e restauração do banco central

Revisão: **14/10/2026**. [Índice](README.md).

## Para que serve e interface

Em **Configurações → Backup e Segurança do Banco de Dados**, gerar uma cópia do banco, consultar backups e solicitar restauração com confirmação. Restaurar recupera o estado de um backup para toda a empresa. Para começar um banco vazio, usar o fluxo distinto de [Novo banco](NOVO_BANCO_DE_DADOS.md).

## Regras do backend

`POST /backup/create` utiliza o backup online do SQLite e verifica a integridade da cópia. `GET /backup/list` lista os arquivos do servidor. Os arquivos ficam no diretório de backups configurado, normalmente `backend/backups`, e não em um banco individual de cada celular.

`POST /backup/restore` valida o nome e a existência do arquivo, gera uma cópia de segurança do estado atual com identificação `pre_restore` e restaura o backup escolhido. O fluxo conserva os comprovantes de criação de novo banco para evitar reexecução após restauração. A barreira de manutenção e o tratamento de conexões coordenam a substituição do banco central.

## O que mexe no banco e nos arquivos

| Ação | Efeito |
| --- | --- |
| Criar backup | Cria arquivo `.db` consistente; não cancela vendas nem zera dados. |
| Listar | Consulta arquivos; não muda os dados comerciais. |
| Restaurar | Substitui o estado do banco ativo pelo conteúdo recuperado, com backup prévio e preservações técnicas previstas pelo fluxo. |

Restauração pode recuperar pareamentos do backup; não presumir a mesma preservação de todos os dispositivos que ocorre na criação de um banco novo. Recarregar as telas e verificar autenticação após a operação.

## Exemplo e limites

Restaurar um backup de ontem recupera o histórico até aquela cópia. Vendas feitas depois dela não estarão no banco restaurado; o backup `pre_restore` permite recuperar o estado anterior à restauração. Para corrigir uma venda isolada, usar seu cancelamento, não restaurar o banco inteiro.

Os scripts de backup diário estão no projeto. A presença do script não comprova que a tarefa agendada está instalada ou executando neste computador. Conferir a instalação e os logs antes de confiar no agendamento. Retenção de backups comuns e proteção de backups anteriores à criação de novo banco são regras distintas; ver [Novo banco](NOVO_BANCO_DE_DADOS.md).

## Onde conferir

- [Tela](../client/lib/views/settings_view.dart), [serviço](../client/lib/services/backup_service.dart), [API](../backend/app/api/v1/backup.py).
- [Backup do servidor](../backend/app/core/backup.py), [barreira de manutenção](../backend/app/core/database_maintenance.py) e [CLI](../scripts/backup_cli.py).
- [Procedimentos de recuperação](MANUAL_BACKUP_RESTAURACAO.md) e [testes](../backend/tests/test_backup_restore.py).
