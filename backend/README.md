# ZM Cesta Básica — Backend FastAPI e Banco de Dados SQLite

Estado vigente da importação: [retomada única](../docs/RETOMADA_IMPORTACAO_FATURAS.md).
**Ativação da Etapa 1 — 20/10/2026:** migração aditiva `f39a012b2159` aplicada após backup quente verificado; 57 tabelas anteriores preservadas, integridade `ok`, sem violações FK. Backend HTTPS local iniciado e health/API/banco verificados. Não avançar etapas corretivas 2–4 nesta versão.
As notas de ativação/correção de 19/10 abaixo são históricas e anteriores à E5.

**Ativação de 19/10/2026:** servidor Python/venv atualizado e HTTPS/PDF verificados
em banco isolado com sete PDFs autorizados; schema fe4 já existente, sem migração.
[Alocações](../docs/ALOCACOES_DE_FATURA.md): consulta protegida de requisitos por
linha/ciclo/parcela, somente backend e sem efeitos financeiros. Persistência das
alocações e geração líquida continuam futuras. Evidências no guia da correção.

**Importação financeira — 19/10/2026:** a
[correção de integridade e revisão](../docs/CORRECAO_IMPORTACAO_FINANCEIRA_2026-10-19.md)
registra a implementação atual, contratos versionados e evidência. O cliente
permite revisão explícita e conciliação; importação em lote no caixa foi suspensa.
Alocação de créditos/saldo anterior/parcelas e homologação adicional continuam
pendentes. Código/Release não substituem o servidor e o aplicativo abertos.

**Receber revisado — 17/10/2026:** o [guia do incremento](../docs/PILOTO_RECEBER_REVISADO.md)
descreve saldo/dia civil/capacidade, preservação da venda e recuperação comum
com Pagar. Cliente e servidor correspondentes são necessários; sem migração
nova ou substituição automática da instalação.

**Pagamento revisado — 16/10/2026:** o [piloto de Pagar](../docs/PILOTO_PAGAR_REVISADO.md)
acrescenta saldo revisado e data civil como campos opcionais, capacidade no detalhe
e erros estruturados, preservando hashes legados. Cliente e servidor precisam das
versões correspondentes; esse incremento não requer migração de banco.

Para regras e efeitos de cada operação no banco, consulte o
[índice das mecânicas do app](../docs/README.md).

**Base financeira — 15/10/2026:** o backend oferece documentos bancários/cartões,
dados estruturados, revisão de duplicidades e conciliação de evidências em
`/api/v1/financial-imports`, incluindo prévias CSV multibanco configuráveis e um
adaptador de conta Nubank. PDF/OFX e sincronização Gmail continuam futuros.
As migrações `fa0d1e2f4310`, `fb1e2f3a5411` e `fc2f3a4b6512` exigem backup verificado antes do uso;
a inicialização não cria essas tabelas automaticamente. Consulte o
[guia da base financeira](../docs/BASE_FINANCEIRA_E_CONCILIACAO.md).
O contrato de leitura está no [guia CSV multibanco](../docs/IMPORTACAO_CSV_MULTIBANCO.md).
A [correção de revisão](../docs/CORRECAO_REVISAO_FINANCEIRA.md) conserva decisões
anteriores e exige tratar explicitamente conciliações ativas.
Para continuar em outra sessão, ler a [memória financeira](../docs/MEMORIA_IMPLEMENTACAO_FINANCEIRA.md).
A [homologação](../docs/HOMOLOGACAO_IMPORTACAO_FINANCEIRA.md) usa ferramenta
offline com banco descartável, sem usar o banco da empresa.

**16/10 — procedência de faturas:** o [guia](../docs/CONFERENCIA_E_PROCEDENCIA_DE_FATURAS.md)
descreve documentos de controles, transcrição manual, pareceres imutáveis e
vínculo opcional de confirmação, sem criar obrigações. Migração `fd3a4b5c7613`,
após fc2, exclusivamente por Alembic. A base original foi observada em fc2 por
leitura; fd3 foi validada somente em cópia. Sem as três tabelas novas o módulo
retorna 503, portanto atualizar servidor/migração juntos após backup verificado.

Servidor de aplicação local de alta durabilidade, projetado sob os princípios de **Monólito Modular** para gerenciamento de estoque, compras, receitas, montagem de cestas e vendas.

Consulte o documento canônico de diretrizes de engenharia em **[ARCHITECTURE.md](../ARCHITECTURE.md)** e o guia de referência e pendências em **[docs/ARQUITETURA_BACKEND.md](../docs/ARQUITETURA_BACKEND.md)**.

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
├── tests/                      # Suíte de Testes Automatizados
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
   - Produtos e tipos de cestas utilizam inativação lógica (`is_active = False`). Produtos com vínculos ou histórico não podem ser excluídos fisicamente. Cadastros nunca utilizados podem ser excluídos pela ação explícita `/products/{id}/permanent`, após verificação transacional de receitas, compras, montagens e movimentos.
   - Produtos ativos em receitas ativas não podem ser inativados sem antes gerar uma nova versão da receita sem o produto.

---

## 🛠️ Comandos de Manutenção e Testes

**Importação financeira — 16/10/2026:** o [guia PDF](../docs/IMPORTACAO_PDF_FINANCEIRO.md)
documenta `pdf_auto`, adaptadores Nubank/PicPay, erros bloqueantes e homologação
sem efeitos financeiros. Instalar dependências no ambiente Python do servidor,
incluindo `pdfplumber==0.11.10`; versões transitivas constam no lock. A extração
usa esse Python em processo separado. Não está homologada em executável
congelado nem integrada ao Flutter. Reutiliza as tabelas de prévias; não aplica
migrações no banco da empresa. Novos layouts, OCR/senha e Gmail são futuros.

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


**Importação — E5.7, 20/10/2026:** retirada/reimportação auditada exige a migração
`f17e8f901037`. Executar migrações em cópia verificada antes da ativação; não há
criação implícita de tabelas no startup. A exclusão retira documentos/contas e
previsões próprias e restaura contas previamente reunidas, preservando pagamentos
e estoque. Contratos, bloqueios e instruções em [Contas a Pagar](../docs/CONTAS_A_PAGAR.md#excluir-e-reimportar-uma-importação--e57).
