# Guia Oficial de Execução e Compilação — ZM Cesta Básica

> **Atualização de 14/10/2026:** o cliente atual inclui montagem padrão antecipada
> e histórico em Tipos de Cesta → Montagens, por páginas novas. As telas antigas
> de produção/desmontagem e os demais módulos arquivados continuam no arquivo.
> Ver [Montagens e histórico](docs/MONTAGENS_E_HISTORICO.md).

> **Escopo do cliente — revisão de 14/10/2026:** produção em lote, desmontagem
> separada, responsáveis, expedição/conferência/acerto e tesouraria estão
> arquivados na interface, junto de seus relatórios exclusivos e formulário C.
> Seus serviços e dados históricos permanecem no backend. Montagem na venda,
> compras, vendas, fiado, contas a pagar e relatórios simplificados continuam
> ativos. Os comandos abaixo compilam/executam o código atual; não restauram
> automaticamente arquivos de `client/_archive`. Ver
> [mecânicas atuais](docs/README.md) e [funções arquivadas](docs/FUNCOES_ARQUIVADAS.md).

---

## ⚠️ 0. Como Abrir o Terminal na Pasta Certa (Passo Obrigatório)

Todos os comandos deste guia **devem ser executados na raiz do projeto** (`ZM CESTA BÁSICA`). Para não errar o caminho:

1. Abra a pasta do projeto `ZM CESTA BÁSICA` no seu **Explorador de Arquivos** do Windows.
2. Clique na **barra de endereço** no topo da janela (onde mostra o caminho das pastas).
3. Digite **`cmd`** (para abrir o Prompt de Comando) ou **`powershell`** (para abrir o PowerShell) e pressione **Enter**.
4. A janela preta/azul já abrirá exatamente dentro da pasta do projeto, pronta para receber os comandos abaixo!

---

## 📋 1. Pré-requisitos de Programas Instalados

Antes de rodar os comandos, confirme se o seu computador tem os programas necessários:

1. **Python 3.14+ no PATH para desenvolver/executar o backend:**
   `backend/pyproject.toml` declara `requires-python = ">=3.14"`. Verifique
   digitando `python --version`; se não reconhecer, instale uma versão
   compatível e adicione-a ao `PATH`.
2. **Flutter SDK no PATH:** Verifique digitando `flutter --version`. O comando deve responder normalmente.
3. **Para compilar o Windows Desktop (`flutter build windows`):** Visual Studio 2022 Community instalado com a carga de trabalho *"Desenvolvimento para desktop com C++"*.
4. **Para compilar o APK Android (`flutter build apk`):** Android Studio com Android SDK, JDK (Java) instalados e licenças aceitas via `flutter doctor --android-licenses`.

---

## 🚀 2. Configuração Inicial (Primeira Execução ou Nova Máquina)

Quando você clona o projeto em um computador novo ou precisa recriar a `.venv`, execute os passos abaixo a partir da raiz:

### Passo 1: Criar o ambiente virtual `.venv` no backend
- **No PowerShell:**
```powershell
python -m venv backend\.venv
```
- **No CMD:**
```cmd
python -m venv backend\.venv
```

### Passo 2: Instalar as dependências do Python (`requirements.txt`)
- **No PowerShell:**
```powershell
.\backend\.venv\Scripts\python.exe -m pip install -r backend\requirements.txt
```
- **No CMD:**
```cmd
backend\.venv\Scripts\python.exe -m pip install -r backend\requirements.txt
```

### Passo 3: Inicializar as tabelas do SQLite (Alembic)
- **No PowerShell:**
```powershell
.\backend\.venv\Scripts\python.exe -m alembic -c backend\alembic.ini upgrade head
```
- **No CMD:**
```cmd
backend\.venv\Scripts\python.exe -m alembic -c backend\alembic.ini upgrade head
```
*(Você também pode dar dois cliques no `iniciar_servidor.bat`, que ele já cria/atualiza o banco SQLite e os certificados TLS automaticamente)*.

### Passo 4: Baixar as dependências do Flutter no client
- **No PowerShell:**
```powershell
cd client; flutter pub get; cd ..
```
- **No CMD:**
```cmd
cd client && flutter pub get && cd ..
```

---

## ⚙️ 3. Comandos para o BACK-END (Python / FastAPI)

O backend em Python roda direto da pasta virtual e não precisa ser compilado em arquivo `.exe`.

### Passo 1: Executar a suíte de testes (garantia de não-regressão)
- **No PowerShell:**
```powershell
.\backend\.venv\Scripts\python.exe -m pytest backend/tests -q
```
- **No CMD:**
```cmd
backend\.venv\Scripts\python.exe -m pytest backend/tests -q
```

### Passo 2: Executar o servidor backend manualmente (HTTPS / Porta 8000)
- **No PowerShell:**
```powershell
.\backend\.venv\Scripts\python.exe -m uvicorn app.main:app --app-dir backend --host 0.0.0.0 --port 8000
```
- **No CMD:**
```cmd
backend\.venv\Scripts\python.exe -m uvicorn app.main:app --app-dir backend --host 0.0.0.0 --port 8000
```
*(Você também pode dar dois cliques no arquivo `iniciar_servidor.bat` que já criamos na raiz)*.

---

## 📱 4. Comandos para COMPILAR O FRONT-END (Flutter)

Abra o terminal na raiz (`ZM CESTA BÁSICA`) e execute:

---

### A) Gerar Executável para WINDOWS Desktop

#### 1. Versão Debug (Desenvolvimento / Testes Rápidos):
- **No PowerShell:**
```powershell
cd client; flutter build windows --debug; cd ..
```
- **No CMD:**
```cmd
cd client && flutter build windows --debug && cd ..
```

#### 2. Versão Release (Produção Final Otimizada):
- **No PowerShell:**
```powershell
cd client; flutter build windows --release; cd ..
```
- **No CMD:**
```cmd
cd client && flutter build windows --release && cd ..
```

* **O que foi gerado:** A pasta completa em `client\build\windows\x64\runner\Debug\` (ou `Release\`).
* **O que você envia para o usuário de Windows:** Envie a pasta inteira compactada em `.zip` (ela contém o `zm_cesta_basica_client.exe` junto com as DLLs e a pasta `data`). Não envie apenas o `.exe` solto, pois ele precisa das DLLs irmãs para inicializar.

---

### B) Gerar Aplicativo para ANDROID (APK)

#### 1. Versão Debug:
- **No PowerShell:**
```powershell
cd client; flutter build apk --debug; cd ..
```
- **No CMD:**
```cmd
cd client && flutter build apk --debug && cd ..
```

#### 2. Versão Release (Produção):
- **No PowerShell:**
```powershell
cd client; flutter build apk --release; cd ..
```
- **No CMD (Prompt de Comando):**
```cmd
cd client && flutter build apk --release && cd ..
```

> **Dica técnica para o APK Release no Windows:**
> Caso o Gradle do Android acuse erro de limite de tamanho de caminho ou espaço no nome da pasta (`ZM CESTA BÁSICA`), use este comando seguro que cria um drive virtual temporário sem expor caminhos de usuário:
> - **No CMD:**
> ```cmd
> set "ORIGIN=%CD%" && subst X: "%CD%\client" && cd /d X:\ && flutter build apk --release && cd /d "%ORIGIN%" && subst X: /d
> ```
> - **No PowerShell:**
> ```powershell
> $orig =$PWD.Path; cmd /c "subst X: `"$orig\client`" && cd /d X:\ && flutter build apk --release && cd /d `"$orig`" && subst X: /d"
> ```

* **O que foi gerado:** O arquivo APK em `client\build\app\outputs\flutter-apk\app-release.apk` (ou `app-debug.apk`).
* **O que você envia para o usuário de celular Android:** Basta enviar apenas esse arquivo APK único (por WhatsApp, Google Drive, cabo USB ou Telegram). O usuário clica nele no celular e instala.

---

## 📦 5. Comando Único (Compilar Tudo de Uma Vez)

Se quiser rodar um único comando na raiz que compila o Flutter para Windows e Android sequencialmente:

- **No PowerShell:**
```powershell
cd client; flutter build windows --release; flutter build apk --release; cd ..
```

- **No CMD:**
```cmd
cd client && flutter build windows --release && flutter build apk --release && cd ..
```

---

## 🚚 6. Resumo do que Entregar

* **No computador que atuará como Servidor:** A pasta do projeto rodando o backend via `iniciar_servidor.bat` (ou via tarefa agendada do Windows).
* **Nos computadores Windows clientes:** A pasta `client\build\windows\x64\runner\Release\` (ou `Debug\`) compactada em `.zip`.
* **Nos celulares/tablets Android:** O arquivo `client\build\app\outputs\flutter-apk\app-release.apk` (ou `app-debug.apk`).
