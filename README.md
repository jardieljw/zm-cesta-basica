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

| Fase | Escopo | Situação | Testes |
| :--- | :--- | :---: | :---: |
| **Fase 1** | Fundação Arquitetural, TLS local autoassinado com pinning SHA-256, pareamento por PIN de 6 dígitos, SQLite WAL + `synchronous=FULL`, `BEGIN IMMEDIATE`, idempotência e backups | **CONCLUÍDA** | 26/26 ✅ |
| **Fase 2** | Cadastro de produtos/insumos, embalagens comerciais com fator de conversão, tipos de cestas e versionamento imutável de receitas padrão | **CONCLUÍDA** | 44/44 ✅ |
| **Fase 3** | Livro-razão contábil *append-only* com triggers SQLite, entradas de compras com conversão automática, estorno contábil condicionado a saldo e ajustes manuais | **CONCLUÍDA** | 31/31 ✅ |
| **Fase 4** | Motor de Montagem e Produção de Cestas (padrão e lotes personalizados com rastreabilidade) | *Aguardando autorização* | — |
| **Fase 5** | Vendas, Baixa de Cestas e Venda com Montagem Simultânea | *Planejada* | — |
| **Fase 6** | Relatórios Gerenciais, CMV Real, Margens de Lucro e Exportações | *Planejada* | — |
| **Fase 7** | Instalação no Windows, Inicialização em Segundo Plano e Entrega | *Planejada* | — |
| **Futuro** | Módulos Financeiros (Vendas Fiadas, Contas a Receber/Pagar, Caixa) e Conferência de Saídas | *Mapeado* | — |

**Total de testes automatizados ativos e aprovados:** **101 testes (100% verde)**.

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
