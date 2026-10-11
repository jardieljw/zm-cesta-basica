# ZM Cesta Básica — Backend FastAPI e Banco de Dados SQLite

Servidor de aplicação local de alta durabilidade, projetado sob os princípios de **Monólito Modular** para gerenciamento de estoque, compras, receitas, montagem de cestas e vendas.

Consulte o documento canônico de diretrizes de engenharia em **[ARCHITECTURE.md](../ARCHITECTURE.md)**.

---

## 🏛️ Estrutura Modular do Backend

O backend é organizado em módulos de responsabilidades estritas, evitando acoplamento indevido e dependências circulares:

```
backend/
├── alembic/                    # Migrações versionadas do banco SQLite
│   └── versions/               # Scripts incrementais (06d734cf2223, c1f5d6a8e901, d2e6f7a8b902)
├── app/
│   ├── api/                    # Camada de Apresentação HTTP (FastAPI)
│   │   ├── deps.py             # Injeção de dependências (sessão db, dispositivo autenticado)
│   │   └── v1/                 # Endpoints REST versionados
│   │       ├── auth.py         # Pareamento de dispositivos e emissão de tokens
│   │       ├── backup.py       # Backups quentes e restauração de dados
│   │       ├── basket_types.py # Tipos de cestas e receitas imutáveis
│   │       ├── health.py       # Health checks e status de conectividade
│   │       ├── inventory.py    # Resumo de estoque, livro-razão e extrato
│   │       ├── products.py     # Produtos, insumos e embalagens com conversão
│   │       ├── purchases.py    # Notas de compra e estornos contábeis
│   │       └── router.py       # Agregação central de rotas v1
│   ├── core/                   # Núcleo de Infraestrutura e Segurança
│   │   ├── config.py           # Configurações do ambiente e diretórios
│   │   ├── database.py         # Engine SQLAlchemy, sessões e listener BEGIN IMMEDIATE
│   │   ├── idempotency.py      # Gerenciador transacional de chaves de idempotência
│   │   ├── security.py         # Criptografia, certificados X.509 e hashing SHA-256
│   │   └── backup.py           # Operações de cópia quente sqlite3.Connection.backup()
│   ├── models/                 # Modelos Relacionais SQLAlchemy (Entidades de Banco)
│   │   ├── base.py             # Classe Base declarativa e utilitários de timestamp UTC
│   │   ├── auth.py             # PairedDevice e PairingSession
│   │   ├── idempotency.py      # IdempotencyRecord
│   │   ├── products.py         # Product, ProductPackaging, BasketType, RecipeVersion, RecipeItem
│   │   ├── purchases.py        # Purchase e PurchaseItem
│   │   ├── production.py       # ProductionBatch e ProductionBatchItem
│   │   ├── sales.py            # Sale e SaleItem
│   │   └── movements.py        # InventoryMovement (livro-razão append-only com triggers)
│   ├── schemas/                # Contratos de Validação e Serialização Pydantic
│   │   ├── auth.py, backup.py, common.py, health.py
│   │   ├── products.py, packagings.py, recipes.py
│   │   ├── purchases.py, movements.py
│   └── services/               # Lógica e Regras de Negócio de Domínio
│       ├── inventory.py        # Cálculos de saldo em tempo real e ajustes de balanço
│       └── purchases.py        # Lançamento de compras com conversão e cancelamentos
├── certs/                      # Certificados TLS dinâmicos autoassinados (ignorados no git)
├── data/                       # Arquivo do banco SQLite estoque.db (ignorado no git)
├── backups/                    # Arquivos de backup quente gerados (ignorados no git)
├── tests/                      # Suíte de Testes Automatizados (101 testes)
├── pyproject.toml              # Configurações de ferramentas (pytest, etc.)
└── requirements-lock.txt       # Versões exatas travadas de dependências Python
```

---

## 🔒 Princípios de Concorrência, Integridade e Durabilidade

1. **SQLite WAL + Synchronous=FULL:**
   - Leituras não bloqueiam escritas (`PRAGMA journal_mode = WAL`).
   - Cada confirmação é garantida fisicamente em disco (`PRAGMA synchronous = FULL`), evitando perda de transações comerciais em quedas de energia.
2. **Serialização de Escrita com `BEGIN IMMEDIATE`:**
   - Transações de escrita iniciam travando o acesso exclusivo no início da operação via listener SQLAlchemy, eliminando problemas de concorrência (*TOCTOU*) e prevenindo estoque negativo.
3. **Livro-Razão *Append-Only*:**
   - Movimentações de estoque não sofrem alteração ou deleção física. Triggers nativos no SQLite bloqueiam qualquer comando `UPDATE` ou `DELETE` acidental.
4. **Idempotência Transacional Genérica:**
   - Mutações exigem cabeçalho `X-Idempotency-Key`. Reenvios de rede com o mesmo payload recebem a resposta gravada em cache sem reprocessar regras ou duplicar estoques. Modificações no payload com a mesma chave resultam em `HTTP 409 Conflict`.
5. **Soft Delete de Itens de Catálogo:**
   - Produtos e tipos de cestas utilizam inativação lógica (`is_active = False`). Exclusão física é proibida para manter a integridade histórica de transações passadas.
   - Produtos ativos em receitas ativas não podem ser inativados sem antes gerar uma nova versão da receita sem o produto.

---

## 🛠️ Comandos de Manutenção e Testes

```powershell
# Ativar venv
.\.venv\Scripts\Activate.ps1

# Executar todas as migrações até o estado mais recente
alembic upgrade head

# Executar a suíte completa de testes com detalhes
pytest -v

# Executar um módulo específico de testes
pytest tests/test_movements.py -v
pytest tests/test_purchases.py -v
pytest tests/test_concurrency_sqlite.py -v

# Iniciar o servidor com TLS e single-worker
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --ssl-keyfile certs/server.key --ssl-certfile certs/server.crt --workers 1
```
