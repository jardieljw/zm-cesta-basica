# ZM Cesta Básica — Cliente Multiplataforma (Windows e Android)

Aplicativo cliente para gestão de estoque e operações comerciais, projetado para operar em rede local privada sem dependência de internet.

## Plataformas Suportadas
- **Windows Desktop:** Executável nativo Win32/Flutter para operação no computador da loja/servidor.
- **Android Mobile:** APK para smartphones e tablets conectados via Wi-Fi à rede da loja.

## Arquitetura de Comunicação e Segurança
1. **Comunicação Segura Local (HTTPS):**
   - Todas as requisições utilizam TLS na rede local (`https://<ip_servidor>:8000`).
   - Pinning de certificado via validação de impressão digital SHA-256 (`tls_fingerprint_sha256`) durante o pareamento e requisições subsequentes.
2. **Autenticação por Tokens Individuais:**
   - Cada dispositivo pareado recebe um token criptográfico único (`device_token`), transmitido em `Authorization: Bearer <token>`.
   - No Android, o token é guardado em `EncryptedSharedPreferences` via `FlutterSecureStorage`.
   - O servidor armazena apenas o hash SHA-256 do token, permitindo revogação instantânea.
3. **Pareamento sem Exposição de Segredos:**
   - O QR Code contém apenas dados de descoberta e um PIN efêmero de 6 dígitos que expira em 5 minutos.
   - Nenhum segredo permanente é exposto visualmente ou transmitido em texto puro.
4. **Idempotência Transacional:**
   - Toda mutação envia cabeçalho `X-Idempotency-Key` (UUIDv4) para prevenir duplicação de vendas, compras e montagens.

## Como Executar

### Pré-requisitos
- Flutter SDK (>= 3.19.0) instalado e adicionado ao `PATH`.
- Para Windows Desktop: Visual Studio com ferramentas C++ para Desktop instaladas.
- Para Android: Android SDK e JDK configurados.

### Comandos de Build e Execução
```bash
# Obter dependências
flutter pub get

# Executar testes unitários do cliente
flutter test

# Executar no Windows Desktop
flutter run -d windows

# Executar no dispositivo Android conectado
flutter run -d android

# Gerar instalador/APK para Android
flutter build apk --release
```
