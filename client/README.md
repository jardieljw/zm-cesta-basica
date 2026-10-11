# ZM Cesta Básica — Cliente Multiplataforma (Flutter para Windows e Android)

Aplicativo cliente unificado para tablets/smartphones Android e computadores Windows Desktop, conectando-se exclusivamente ao servidor FastAPI local na rede privada da loja.

Consulte o documento canônico de diretrizes de engenharia em **[ARCHITECTURE.md](../ARCHITECTURE.md)**.

---

## 📱 Estrutura e Princípios de Front-End

### 1. Mobile First com Adaptação Desktop
- O fluxo operacional primordial (galpão, montagem e contagem) é desenhado com foco em telas sensíveis ao toque (smartphones e tablets Android).
- Ao executar em computadores Windows Desktop (computador do caixa/administração), a interface se adapta utilizando *layouts* flexíveis, painéis laterais de consulta e densidade confortável de informações.

### 2. Componentização Centralizada e Reutilização
- **Proibição de Duplicação de Lógica:** Nenhuma fórmula matemática de estoque ou conversão é calculada na tela. O cliente consome serviços (`services/`) que comunicam-se com a API FastAPI.
- **Componentes Compartilhados:** A interface deve utilizar componentes padronizados para garantir consistência visual e facilitar mudanças globais:
  - Campos de entrada e valores monetários com máscara.
  - Botões de ação com feedback de carregamento integrado.
  - Cartões e listagens de dados padronizados.
  - Diálogos modais e *snackbars* de feedback com tratamento amigável de erros da API.

### 3. Internacionalização (i18n) e Formatação Centralizada
- **Textos e Rótulos:** Todo texto de interface deve residir em ponto central de strings (inicialmente em português brasileiro `pt-BR`), permitindo a introdução de novos idiomas no futuro sem necessidade de reescrever telas.
- **Valores Monetários:** Todo valor trafegado com o backend é um **inteiro em centavos**. A conversão para `"R$ X,XX"` é feita através de utilitário centralizado (`Intl`), evitando discrepâncias de formatação.
- **Datas:** Exibição com conversão de ISO-8601 UTC para data local formatada (`dd/MM/yyyy HH:mm`).

---

## 📂 Organização Modular do Projeto Flutter

```
client/
├── android/                    # Configurações nativas Android (Manifest, segurança de rede TLS)
├── windows/                    # Configurações nativas Windows Desktop (CMakeLists)
├── lib/
│   ├── core/                   # Utilitários globais de infraestrutura
│   │   ├── api_client.dart     # Cliente HTTP seguro com pinning de fingerprint TLS SHA-256
│   │   ├── constants.dart      # Constantes de configuração e rotas
│   │   └── secure_storage.dart # Armazenamento de credenciais (Android Keystore / WinCred)
│   ├── models/                 # Modelos de dados e serialização JSON
│   │   ├── product.dart        # Produtos e embalagens
│   │   ├── basket_type.dart    # Cestas e receitas de composição
│   │   ├── purchase.dart       # Notas de compras e itens
│   │   ├── inventory_movement.dart # Linhas do livro-razão e saldo progressivo
│   │   └── device_auth.dart    # Credenciais de pareamento
│   ├── services/               # Clientes de comunicação com a API REST
│   │   ├── auth_service.dart
│   │   ├── product_service.dart
│   │   ├── basket_service.dart
│   │   ├── purchase_service.dart
│   │   └── inventory_service.dart
│   └── views/                  # Telas modulares independentes
│       ├── home_view.dart      # Painel central de navegação e status de conexão
│       ├── pairing_view.dart   # Leitura de QR Code e entrada de PIN de 6 dígitos
│       ├── settings_view.dart  # Configurações do servidor e revogação
│       ├── products_view.dart  # Catálogo e busca de insumos
│       ├── product_form_view.dart
│       ├── packagings_dialog.dart # Gerenciamento de embalagens comerciais
│       ├── basket_types_view.dart # Tipos de cestas e receitas ativas
│       ├── recipe_view.dart    # Compositor de receitas com histórico
│       ├── purchases_view.dart # Listagem e cancelamento seguro de compras
│       ├── purchase_form_view.dart # Lançamento de notas de compras com conversão
│       ├── stock_ledger_view.dart # Extrato contábil detalhado e alerta de estoque mínimo
│       └── stock_adjustment_dialog.dart # Ajuste rápido de balanço/quebra com motivo
├── test/                       # Testes de modelos e componentes
├── pubspec.yaml                # Declaração de dependências
└── pubspec.lock                # Versões travadas e homologadas
```

---

## 🚀 Como Executar

```bash
# Obter pacotes
flutter pub get

# Rodar no Windows Desktop
flutter run -d windows

# Rodar no dispositivo Android conectado
flutter run -d android

# Gerar pacote release APK para Android
flutter build apk --release
```
