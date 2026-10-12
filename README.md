# ZM Cesta Básica — Sistema Profissional de Gestão de Estoque e Produção

Sistema de alta confiabilidade para controle de estoque, compras com conversão de embalagens, montagem de cestas (padrão e personalizadas), vendas e relatórios gerenciais, operando em rede local privada (Windows Desktop e Android Mobile) sem dependência de serviços em nuvem.

---

## 📌 Documentos Canônicos de Referência

Para entender a arquitetura, regras de engenharia, especificações de negócio e diretrizes para agentes de desenvolvimento:

1. **[ARCHITECTURE.md](file:///c:/Users/jardi/Desktop/ZM%20CESTA%20B%C3%81SICA/ARCHITECTURE.md):** Documento canônico de arquitetura, princípios permanentes de engenharia, governança técnica, backlog futuro (financeiro, fiado, expedição) e mapa de fases.
2. **[Especificacao_Sistema_Estoque_Cestas.md](file:///c:/Users/jardi/Desktop/ZM%20CESTA%20B%C3%81SICA/Especificacao_Sistema_Estoque_Cestas.md):** Especificação original completa do negócio aprovada pela empresa.
3. **[backend/README.md](file:///c:/Users/jardi/Desktop/ZM%20CESTA%20B%C3%81SICA/backend/README.md):** Guia detalhado do backend FastAPI, banco de dados SQLite WAL, migrações e endpoints.
4. **[client/README.md](file:///c:/Users/jardi/Desktop/ZM%20CESTA%20B%C3%81SICA/client/README.md):** Guia da aplicação cliente Flutter (Windows e Android), pinning TLS e componentes de interface.

---

## 🚀 Status do Projeto

| Fase | Escopo | Situação | Testes / Evidências |
| :--- | :--- | :---: | :---: |
| **Fase 1** | Fundação Arquitetural, TLS local autoassinado com pinning SHA-256, pareamento por PIN de 6 dígitos, SQLite WAL + `synchronous=FULL`, `BEGIN IMMEDIATE`, idempotência e backups | **CONCLUÍDA** | 26/26 ✅ |
| **Fase 2** | Cadastro de produtos/insumos, embalagens comerciais com fator de conversão, tipos de cestas e versionamento imutável de receitas padrão | **CONCLUÍDA** | 44/44 ✅ |
| **Fase 3** | Livro-razão contábil *append-only* com triggers SQLite, entradas de compras com conversão automática, estorno contábil condicionado a saldo e ajustes manuais | **CONCLUÍDA** | 31/31 ✅ |
| **Fase 4** | Motor de Montagem e Produção de Cestas (lotes padrão e personalizados), CMPM em escala de microcentavos e desmontagem com triagem | **CONCLUÍDA** | 21/21 ✅ |
| **Fase 5** | Vendas de Balcão e Rotas, Cadastro de Clientes, Contas a Receber (Fiado) e Montagem Simultânea sob Demanda | **CONCLUÍDA** | 17/17 ✅ |
| **Fase 6** | Saídas Físicas (`STORE` $\rightarrow$ `TRANSIT`), Responsáveis por Rota, Baixa Exclusiva de Trânsito, Equação Canônica de 4 Termos e Acerto Segregado | **CONCLUÍDA** | 18/18 ✅ |
| **Fase 7** | Gestão Financeira Completa, Contas a Pagar (`BUSINESS` vs `PERSONAL_WITHDRAWAL`), Tesouraria e Livro-Caixa Imutável | **CONCLUÍDA** | 14/14 ✅ |
| **Fase 8** | Dashboard Consolidado, DRE Gerencial, Exportação Digital (CSV/XLSX), Formulários A4 em Branco para Prancheta e Impressão Direta (Epson Wi-Fi) | **CONCLUÍDA** | 8/8 ✅ |
| **Fase 9** | Auditoria Final, Ciclo E2E Completo, CLI e Agendamento de Backup Quente, Tarefas Windows, Compilações Nativas e 4 Manuais Técnicos/Operacionais | **CONCLUÍDA** | 1/1 ✅ |

- **Backend (pytest):** **180 testes automatizados aprovados (100% verde)**.
- **Frontend (flutter test):** **93 testes automatizados aprovados (100% verde)**.
- **Análise Estática (dart analyze):** **0 erros / 0 avisos**.
- **Binário Windows Release:** `client/build/windows/x64/runner/Release/zm_cesta_basica_client.exe` (92.160 bytes).
- **Binário Android Release APK:** `client/build/app/outputs/flutter-apk/app-release.apk` (74.1 MB).
- **Manuais Técnicos e Operacionais:** Diretório `docs/` (`MANUAL_OPERACIONAL.md`, `MANUAL_INSTALACAO_WINDOWS.md`, `MANUAL_BACKUP_RESTAURACAO.md`, `MANUAL_IMPRESSAO_EPSON.md`).
- **Scripts de Automação:** Diretório `scripts/` (`start_backend_server.bat`, `run_scheduled_backup.bat`, `setup_firewall_rules.ps1`, `install_windows_service.ps1`, `backup_cli.py`).

---

## 💻 Como Executar

### 1. Backend (Servidor Local FastAPI)
O servidor opera no computador principal da loja (Windows):

```powershell
# Navegar até a pasta backend
cd backend

# Ativar ambiente virtual
.\.venv\Scripts\Activate.ps1

# Aplicar migrações do banco de dados (se houver pendências)
alembic upgrade head

# Executar a suíte completa de testes automatizados
pytest -v

# Iniciar o servidor local com HTTPS (TLS)
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --ssl-keyfile certs/server.key --ssl-certfile certs/server.crt --workers 1
```

### 2. Cliente Multiplataforma (Flutter para Windows e Android)
O aplicativo cliente conecta-se ao servidor local via Wi-Fi:

```powershell
# Navegar até a pasta client
cd client

# Instalar dependências
flutter pub get

# Executar no Windows Desktop
flutter run -d windows

# Executar no dispositivo Android conectado
flutter run -d android
```

---

## 🔒 Princípios de Segurança e Integridade de Dados
- **Zero Dependência de Nuvem:** Operação 100% local, dados centralizados no SQLite do servidor da empresa.
- **TLS Local com Pinning:** Validação de impressão digital SHA-256 do certificado autoassinado para proteção contra espionagem na rede Wi-Fi.
- **Pareamento Efêmero:** PIN de 6 dígitos descartável em 5 minutos; QR Code não expõe nenhum token permanente.
- **Rastreabilidade Contábil:** O livro-razão `inventory_movements` não permite `UPDATE` nem `DELETE`. Correções são feitas via estornos com contrapartida contábil.
- **Durabilidade Estrita:** `synchronous = FULL` e `BEGIN IMMEDIATE` impedem perda de dados em quedas de energia e bloqueiam saldo negativo.
