# Manual de Backup, Integridade e Recuperação de Desastres (DRP)
## ZM Cesta Básica — Procedimentos de Segurança e Continuidade de Negócio

**Versão do Documento:** 1.0 (Sistema Homologado - Fases 1 a 9)  
**Público-Alvo:** Administradores do Sistema, Suporte Técnico e Proprietários da Empresa  
**Objetivo:** Reduzir o risco de perda de dados históricos e orientar a recuperação com cópias verificadas. Nenhum procedimento garante risco zero de perda.

---

## 1. Princípios de Integridade do Banco de Dados

O banco de dados do sistema (**SQLite 3**) opera com configurações de nível industrial para assegurar que nenhuma transação seja perdida em casos de queda abrupta de energia ou falha de hardware:

1. **Modo WAL (Write-Ahead Logging):** Leituras e escritas ocorrem simultaneamente sem travamento de tabelas.
2. **Durabilidade Estrita (`PRAGMA synchronous = FULL`):** Toda gravação é descarregada no disco físico antes da confirmação da transação.
3. **Prevenção de Corridas de Concorrência (`BEGIN IMMEDIATE`):** Impede que duas vendas ou montagens simultâneas gerem saldo negativo de estoque.
4. **Livro-Razão e Livro-Caixa Append-Only:** Triggers nativos do banco impedem comandos `UPDATE` e `DELETE` em `inventory_movements` e `cash_flow_entries`.

---

## 2. Como Funciona o Backup Quente Online

Diferente de cópias manuais de arquivos que podem corromper se feitas enquanto o sistema está gravando, o sistema utiliza a **API Oficial de Backup Online do SQLite (`sqlite3.Connection.backup`)**:

- O backup lê os blocos do banco principal e do arquivo temporário WAL página por página de forma consistente.
- O sistema **não precisa ser desligado** nem interrompido para que o backup seja gerado.
- Imediatamente após a cópia, o utilitário executa o comando `PRAGMA integrity_check` no arquivo gerado. Se o arquivo apresentar qualquer inconformidade, ele é descartado e o operador é alertado.

---

## 3. Rotina de Backup Automático Diário

O projeto oferece um script de instalação da tarefa no **Agendador de Tarefas do Windows**. A existência dos arquivos não confirma a instalação neste computador; verificar a tarefa e seus logs. Ver [Backup e restauração](BACKUP_E_RESTAURACAO.md).

- **Frequência:** Diariamente às 23:00.
- **Local de Gravação:**  
  `backend\backups\estoque_backup_diario_YYYYMMDD_HHMMSS.db`
- **Política de Retenção:** O script aplica retenção por quantidade de arquivos comuns, normalmente **30 backups**, não por uma idade fixa de 30 dias. Backups protegidos anteriores à criação de novo banco seguem a regra própria de [Novo banco](NOVO_BANCO_DE_DADOS.md).
- **Arquivo de Log de Auditoria:** Gravado em `backend\backups\logs\`.

---

## 4. Como Executar um Backup Manual Imediato

### Opção A: Pelo Aplicativo Flutter (Interface Gráfica)
1. Acesse o menu lateral e clique em **Configurações / Backup**.
2. Clique no botão **Criar Backup Agora**.
3. O sistema cria o backup imediatamente, exibe o nome do arquivo gerado e confirma a integridade (`OK`).

### Opção B: Pela Linha de Comando (CLI)
Abra o PowerShell na pasta do projeto e execute:

```powershell
.\backend\.venv\Scripts\python.exe scripts\backup_cli.py create --tag manual
```

---

## 5. Como Listar e Verificar Backups Existentes

Para listar todos os arquivos de backup salvos no servidor:

```powershell
.\backend\.venv\Scripts\python.exe scripts\backup_cli.py list
```

Para verificar a integridade estrutural da base de dados ativa:

```powershell
.\backend\.venv\Scripts\python.exe scripts\backup_cli.py verify
```

Para verificar um arquivo de backup específico:

```powershell
.\backend\.venv\Scripts\python.exe scripts\backup_cli.py verify --file "backend\backups\estoque_backup_diario_20261012_230000.db"
```

---

## 6. Procedimento de Restauração em Caso de Desastre (DRP)

Se o computador sofrer uma pane, infecção por vírus ou se houver exclusão acidental, siga o roteiro de restauração passo a passo:

### Roteiro de Recuperação Passo a Passo:

#### 1. Fechar o Servidor e o Aplicativo
Certifique-se de que o aplicativo cliente e o servidor FastAPI estejam fechados:
```powershell
taskkill /F /IM python.exe
taskkill /F /IM zm_cesta_basica_client.exe
```

#### 2. Escolher o Backup Mais Recente
Consulte a lista de backups disponíveis:
```powershell
.\backend\.venv\Scripts\python.exe scripts\backup_cli.py list
```
Localize o nome do arquivo que deseja restaurar (ex.: `estoque_backup_diario_20261012_230000.db`).

#### 3. Executar o Comando de Restauração
Execute o comando passando o nome do arquivo:
```powershell
.\backend\.venv\Scripts\python.exe scripts\backup_cli.py restore --file "estoque_backup_diario_20261012_230000.db"
```

O comando executará:
1. Validação prévia de integridade do arquivo de backup (`PRAGMA integrity_check`).
2. Sobrescrita atômica segura da base de dados oficial (`backend\data\estoque.db`).
3. Validação pós-restauração garantindo que o banco de produção restaurado está 100% íntegro.

#### 4. Reiniciar o Servidor
Abra o arquivo `scripts\start_backend_server.bat` ou abra novamente o aplicativo desktop. Todos os dados, históricos contábeis, receitas e saldos estarão restaurados exatamente ao momento em que o backup foi gerado.

---

## 7. Recomendações Críticas de Segurança (Cópia Externa)

1. **Regra 3-2-1:** Mantenha pelo menos:
   - 3 cópias dos dados (Base ativa, pasta de backups local e pendrive externo).
   - 2 mídias diferentes (SSD do computador e Pendrive USB / HD Externo).
   - 1 cópia fora do local de trabalho (Pendrive guardado em local seguro).
2. **Cópia Semanal em Pendrive:**  
   Recomenda-se copiar semanalmente a pasta `backend\backups\` para um pendrive ou HD externo. O tamanho de cada arquivo de backup é compacto (em média 500 KB a 5 MB), permitindo armazenar anos de histórico em um pendrive comum de 8 GB.
