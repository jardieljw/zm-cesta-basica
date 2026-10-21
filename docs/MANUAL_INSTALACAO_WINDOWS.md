# Manual de Instalação, Configuração e Implantação no Servidor Windows
## ZM Cesta Básica — Sistema Local de Gestão de Estoque, Produção e Vendas

**Versão do Documento:** 1.0 (Sistema Homologado - Fases 1 a 9)  
**Ambiente Alvo:** Computador Principal da Loja/Galpão (Windows 10 / Windows 11 x64)  
**Topologia:** Servidor Local Privado (Wi-Fi/Ethernet) sem dependência de internet  

---

## 1. Requisitos Mínimos de Sistema e Rede

### 1.1. Computador Servidor (Windows)
- **Sistema Operacional:** Windows 10 (versão 2004 ou superior) ou Windows 11 (64 bits).
- **Processador:** Dual-Core 2.0 GHz ou superior.
- **Memória RAM:** Mínimo de 4 GB (recomendado 8 GB).
- **Armazenamento:** 2 GB livres em SSD ou disco rígido.
- **Rede:** Placa de rede conectada ao roteador Wi-Fi da loja/galpão.
- **Python (computador que hospeda a API):** Python 3.14 ou superior instalado e
  disponível no `PATH`, necessário para criar o ambiente virtual do backend. A
  instalação documentada executa a API com Python em `.venv`; o executável
  Flutter para Windows contém o cliente, não o backend. Executar somente o
  cliente Windows não exige Python instalado.

### 1.2. Rede Local da Empresa
- **Roteador Wi-Fi:** Não é necessário acesso à internet para o funcionamento da aplicação. Todos os dados transitam na rede local fechada.
- **Recomendação de IP Fixo:** É altamente recomendável fixar o endereço IP do computador Windows nas configurações do roteador Wi-Fi (ex.: `192.168.1.100` ou `192.168.50.100`).

---

## 2. Estrutura do Sistema no Servidor

O sistema é entregue na pasta principal do projeto com a seguinte organização:

```
C:\ZM CESTA BASICA\ (ou pasta na Área de Trabalho)
├── backend\
│   ├── app\             # Código-fonte da API FastAPI e regras de negócio
│   ├── backups\         # Cópias de segurança atômicas (.db) e logs
│   ├── certs\           # Certificado autoassinado TLS (server.crt e server.key)
│   ├── data\            # Base de dados relacional oficial (estoque.db)
│   └── alembic\         # Migrações versionadas do banco de dados
├── client\
│   └── build\           # Binários compilados (Windows .exe e Android .apk)
├── docs\                # Manuais operacionais e de instalação
└── scripts\             # Scripts de automação (.bat e .ps1)
    ├── start_backend_server.bat
    ├── run_scheduled_backup.bat
    ├── setup_firewall_rules.ps1
    ├── install_windows_service.ps1
    └── backup_cli.py
```

---

## 3. Passo a Passo de Instalação e Inicialização

### Passo 1: Configuração do Ambiente Virtual Python
Abra o **PowerShell** no diretório do projeto e execute:

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install --upgrade pip
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
```

### Passo 2: Aplicação das Migrações do Banco de Dados SQLite
Garante que todas as tabelas, triggers e restrições de integridade contábil estejam presentes no banco:

```powershell
.\.venv\Scripts\python.exe -m alembic upgrade head
```

### Passo 3: Geração dos Certificados de Segurança TLS (HTTPS)
O sistema opera 100% sobre conexões criptografadas HTTPS locais para proteger contra interceptação de senhas e dados na rede Wi-Fi. Se o diretório `backend/certs` estiver vazio, o próprio servidor gera os certificados automaticamente no primeiro arranque e exibe a impressão digital SHA-256 no console.

---

## 4. Liberação do Windows Defender Firewall

Para que os smartphones Android consigam se comunicar com o computador Windows pela rede Wi-Fi local:

1. Clique com o botão direito no menu Iniciar do Windows e selecione **Terminal (Administrador)** ou **PowerShell (Administrador)**.
2. Navegue até a pasta do projeto e execute:
   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   .\scripts\setup_firewall_rules.ps1
   ```
3. O script criará a regra `ZM Cesta Basica - API Local HTTPS (8000)`, autorizando o tráfego da porta 8000 **apenas em perfis de rede Privada e Domínio**, bloqueando automaticamente qualquer acesso caso o computador seja conectado a redes públicas inseguras.

---

## 5. Configuração de Inicialização Automática no Windows

Para que a loja não precise iniciar o servidor manualmente toda vez que ligar o computador:

1. No PowerShell com privilégios de Administrador, execute:
   ```powershell
   .\scripts\install_windows_service.ps1
   ```
2. O script registrará duas tarefas no **Agendador de Tarefas do Windows (Task Scheduler)**:
   - **`ZMCestaBasica_Server`:** Inicia automaticamente o servidor FastAPI com TLS toda vez que o operador fizer login no Windows.
   - **`ZMCestaBasica_DailyBackup`:** Executa o backup quente diário atômico e a rotação de retenção todos os dias às 23:00.

---

## 6. Pareamento Seguro de Dispositivos Móveis (Android)

Para conectar o celular do motorista ou tablet do galpão ao servidor da loja:

1. **Abra o aplicativo no computador** ou acesse a tela de **Pareamento de Dispositivos**.
2. O servidor exibirá um **PIN efêmero de 6 dígitos** (válido por apenas 5 minutos) e um QR Code.
3. No smartphone Android:
   - Abra o aplicativo **ZM Cesta Básica**.
   - Na primeira abertura, informe o IP local do servidor (ex.: `https://192.168.1.100:8000`).
   - Digite o PIN de 6 dígitos exibido na tela do computador (ou escaneie o QR Code).
4. O servidor autenticará o dispositivo, validará a impressão digital SHA-256 do certificado e emitirá um **Token de Acesso Criptográfico** de longa duração, armazenado com segurança no cofre do Android (`Keystore`). O aparelho estará autenticado permanentemente para operar.

---

## 7. Como Executar o Aplicativo no Windows Desktop

O executável nativo compilado em modo Release está pronto para uso e não depende do Flutter instalado na máquina:

- **Localização do Executável:**  
  `client\build\windows\x64\runner\Release\zm_cesta_basica_client.exe`
- **Atalho na Área de Trabalho:**  
  Clique com o botão direito no arquivo `zm_cesta_basica_client.exe` $\rightarrow$ **Enviar para** $\rightarrow$ **Área de trabalho (criar atalho)**.
- Ao abrir o atalho, o aplicativo conecta-se imediatamente ao serviço local (`https://127.0.0.1:8000`) e carrega o painel principal.

---

## 8. Diagnóstico e Resolução de Problemas Comuns

| Sintoma | Causa Provável | Solução |
| :--- | :--- | :--- |
| **Android exibe "Servidor Inacessível"** | O celular e o computador estão em redes Wi-Fi diferentes (ex.: rede de visitantes). | Conecte ambos no mesmo Wi-Fi da loja e verifique se o IP informado no Android está correto. |
| **Firewall bloqueando porta 8000** | A rede do Windows está classificada como "Pública". | Altere o perfil de rede do Windows de Pública para **Privada** nas configurações de Wi-Fi e reexecute `.\scripts\setup_firewall_rules.ps1`. |
| **IP do computador mudou** | O roteador reiniciou e atribuiu novo IP por DHCP. | Fixe o endereço IP do servidor no roteador Wi-Fi ou atualize o IP na tela de configurações do aplicativo no celular. |
| **Porta 8000 já em uso** | Outro programa está usando a porta 8000. | Execute `netstat -ano \| findstr :8000` no CMD para identificar o processo ou altere a porta no arquivo `scripts\start_backend_server.bat`. |
