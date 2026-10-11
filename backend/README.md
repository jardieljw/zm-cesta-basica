# ZM Cesta Básica — Backend FastAPI e Banco SQLite

Servidor local de alta durabilidade e integridade para controle de estoque, receitas, compras, montagens e vendas.

## Características Arquiteturais (Fase 1 Concluída)
- **Topologia:** Servidor local único em rede privada, sem dependência de nuvem.
- **Segurança:** HTTPS local com certificados autoassinados gerados dinamicamente com Subject Alternative Names (SAN), validação por impressão digital (SHA-256 fingerprint), pareamento efêmero por PIN (5 minutos), tokens individuais aleatórios por dispositivo com armazenamento de apenas hashes no banco (`paired_devices.token_hash`), e revogação ativa de dispositivos.
- **Idempotência Transacional:** Tratamento unificado de `X-Idempotency-Key` com hash canônico SHA-256 do corpo (`request_payload_hash`). Reutilização da chave com mesmo conteúdo retorna a resposta original salva sem reprocessar estoque; reutilização com conteúdo ou tipo de operação diferente resulta em HTTP 409 (`IDEMPOTENCY_PAYLOAD_MISMATCH`).
- **Concorrência e Durabilidade:**
  - SQLite WAL mode (`PRAGMA journal_mode = WAL`)
  - Durabilidade estrita para proteção contra quedas de energia (`PRAGMA synchronous = FULL`)
  - Prevenção de deadlocks e TOCTOU com transações atômicas exclusivas (`BEGIN IMMEDIATE`)
  - Tolerância a contenção com timeout configurado (`PRAGMA busy_timeout = 5000`) e retry exponencial automático.
- **Durabilidade e Backup Externo:** Backup online e a quente via `sqlite3.Connection.backup()` em arquivo separado fora do banco principal, com verificação de integridade via `PRAGMA integrity_check` tanto no backup quanto na restauração testada.

## Como Executar

### Ativar Ambiente Virtual e Dependências
```powershell
# Ativar venv
.\.venv\Scripts\Activate.ps1

# Executar migrações do banco
.\.venv\Scripts\alembic.exe upgrade head
```

### Iniciar o Servidor FastAPI
```powershell
# Iniciar servidor HTTPS local
.\.venv\Scripts\python.exe -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --ssl-keyfile certs/server.key --ssl-certfile certs/server.crt --workers 1
```

### Executar a Suíte de Testes Automatizados
```powershell
.\.venv\Scripts\pytest.exe -v
```
