# Configuração e autenticação por dispositivo

**Entrada FE-055:** Mais → Configurações e conexão separa **Aparência** de
**Conexão com o servidor**. Aparência guarda tema, destaque e fundo somente no
aparelho, preservando o azul original e ajustando contraste. Conexão abre o
fluxo de rede/pareamento/impressão/backup descrito abaixo; suas credenciais e
contratos foram preservados.

Revisão: **15/10/2026**. [Índice](README.md).

### Incidente de certificado em localhost — 19/10/2026

O app exibiu `CERTIFICATE_VERIFY_FAILED` porque duas cópias do servidor estavam
na porta 8000: a deste projeto em `0.0.0.0` e outra cópia do workspace em
`127.0.0.1`. A conexão a `https://127.0.0.1:8000` chegava à segunda cópia, cujo
certificado era diferente. O fingerprint salvo no cliente correspondia ao
`backend/certs/server.crt` deste projeto; normalizar o texto não resolveria.

Foi encerrada apenas a árvore de processo da cópia conflitante, após conferir
caminho e argumentos. Banco, certificados e pareamento foram preservados.
A consulta a `/api/v1/health` passou com HTTP 200, validação HTTPS usando o
certificado do projeto, banco `ok` e fingerprint informado igual ao salvo.
No app já aberto, usar **Atualizar** para repetir a consulta. Isso verifica o
servidor, sem afirmar inspeção visual posterior da janela ou homologação de
operações financeiras.

Se voltar a ocorrer, verificar primeiro os processos que escutam a porta e seus
workspaces. Servidores de desenvolvimento de outras cópias devem usar portas
distintas. Não aceitar automaticamente um certificado diferente nem apagar o
fingerprint para esconder esse conflito.

A tela apresenta status e verificação da conexão, pareamento e, no Windows,
o bloco **Rede e conexão** logo abaixo do pareamento de celulares/tablets.
**Impressão e impressoras** fica em seguida, imediatamente acima dos backups
(quando disponíveis), e continua acessível sem servidor ou autenticação.

## Computador Windows

Em Configurações, o bloco Rede e conexão permite informar a URL HTTPS do servidor,
o fingerprint e, opcionalmente, um token já emitido pelo servidor. O campo do token
é oculto e não mostra a credencial armazenada. Deixá-lo vazio preserva a credencial
atual quando o endereço não mudou.

Use **Salvar e autenticar este computador**. Se o servidor estiver no próprio
computador, use `https://127.0.0.1:8000` ou `https://localhost:8000`. O cliente Windows
usa o endpoint existente `pairing/local-master` quando necessário e guarda o token
recebido. Essa tentativa requer HTTPS e um endereço de loopback real.

Para um servidor em outro computador, informe um token válido ou use **Parear este
computador por PIN**. O pareamento manual reutiliza o mesmo fluxo e os mesmos
serviços usados no Android, com URL, fingerprint e PIN temporário. No Windows não
há inicialização de câmera nem aba de scanner.

O servidor precisa estar em execução. A mensagem de conexão verifica o endpoint
de saúde; o estado de autenticação verifica também o endpoint protegido `devices`.
Um token salvo que foi revogado ou rejeitado não é exibido como ativo. Ao trocar a
URL, as credenciais e a identidade do servidor anterior são limpas antes de salvar
as novas informações.

## Android

As configurações oferecem **Parear dispositivo**, com as opções existentes de
leitura de QR code e preenchimento manual do endereço, fingerprint e PIN.
O bloco separado de edição de rede e token do computador fica oculto. O Android
nunca tenta a autenticação automática de terminal local.

Ao tocar em **Parear Dispositivo (Escanear QR / PIN)**, o Android abre a aba
**Escanear QR** e inicia a câmera traseira. Na primeira utilização, autorize o
acesso à câmera. A solicitação de permissão pode tirar o foco do aplicativo;
o leitor aguarda sua conclusão sem iniciar uma segunda solicitação simultânea.
Ao ir para a aba de PIN ou colocar o aplicativo em segundo plano, a captura
é interrompida. Ao retornar ao QR com o aplicativo ativo, ela é reiniciada.

Se a permissão for negada, a tela explica como autorizá-la e oferece **Ativar
Câmera** para tentar novamente. Quando o Android não exibir mais a pergunta,
habilite a câmera em Configurações do Android → Aplicativos → ZM Cestas →
Permissões e volte ao leitor. Outros erros de abertura têm uma mensagem própria
e permitem nova tentativa. A câmera anterior é liberada antes de criar outra,
inclusive quando uma autorização ainda estava em andamento.

Durante a confirmação de um QR lido, o scanner pausa para evitar pareamentos
duplicados. Se o servidor rejeitar a tentativa, a mensagem aparece e a leitura
é retomada. O QR deve ser o de pareamento gerado pelo computador, com URL,
fingerprint e PIN válidos. A inicialização da câmera é local e não depende de
o servidor estar acessível; a confirmação do pareamento depende da conexão.

## Implementação e verificação

Os fluxos continuam usando `SecureStorageService`, `ApiClient`, `AuthService` e
`ConnectivityService`. Nenhuma tela acessa diretamente o banco de dados e os
contratos do backend foram preservados.

`client/test/settings_authentication_test.dart` cobre autenticação local, rejeição
de token inválido, token fornecido manualmente, atualização do estado depois de
salvar e diferenças de interface/câmera entre Windows e Android.

`client/test/pairing_scanner_test.dart` simula a plataforma da câmera e cobre
primeira autorização, permissão negada e nova tentativa, retorno das permissões
do Android, alternância QR/PIN, segundo plano, fechamento durante autorização e
respostas de erro do servidor. Esses testes não homologam o hardware: validar
também em um Android físico com o APK atualizado, autorizando a primeira captura,
lendo o QR do computador e repetindo as trocas de aba/segundo plano.

Verificação da tentativa anterior em **14/10/2026**: 217 testes Flutter aprovados
(nove cenários específicos do scanner), 248 testes de backend aprovados em
bancos temporários e `flutter analyze` sem problemas. Nenhum Android físico
estava conectado durante essa verificação; a câmera real e o pareamento por
imagem continuam dependendo da validação no aparelho.
APK release recompilado com sucesso com `flutter build apk --release --no-pub`:
`client/build/app/outputs/flutter-apk/app-release.apk`. Instalar essa versão no
celular para que a correção substitua o comportamento do aplicativo anterior.

### Revisão nativa do leitor — 15/10/2026

O usuário informou que o APK anterior continuou sem abrir a câmera. Os testes
simulados acima validavam o controle da tela, mas não a integração nativa nem a
exibição dos quadros no aparelho. Eles não comprovaram a resolução da falha.

O cliente passou de `mobile_scanner` 5.2.3 para **7.4.2**, com versão do app
**1.0.1+2** para identificar a atualização. A versão foi fixada no `pubspec.yaml`
e no lockfile. O código da biblioteca antiga usava `createSurfaceTexture`; a
nova usa `SurfaceProducer`, incluindo limpeza/recriação da superfície. O
[histórico oficial](https://pub.dev/packages/mobile_scanner/changelog) registra
suporte ao Impeller, correções de inicialização com tela preta, compatibilidade
com AGP 9, tratamento de falhas do CameraX e regras de preservação do ML Kit
em compilações release. Consulte também a
[migração de superfícies do Flutter](https://docs.flutter.dev/release/breaking-changes/android-surface-plugins).
Esses achados justificam a atualização, mas não identificam isoladamente qual
dessas falhas ocorreu no telefone do usuário, cujo modelo/log não foi informado.

A tela foi adaptada aos callbacks da nova API, aguarda a montagem da prévia
antes de iniciar um novo controlador e trata erros do fluxo nativo de análise.
O ciclo de vida continua controlado pelo app, sem uma segunda rotina automática
de início/parada. A leitura Android continua usando o modelo do ML Kit incluído
no APK; não exige baixar um modelo na primeira utilização. Nenhum endpoint,
credencial, regra de pareamento ou tabela de negócio foi alterado.

O teste `client/integration_test/pairing_camera_android_test.dart` usa a câmera
nativa da plataforma, sem substituir `MobileScannerPlatform`. Ele verifica a
inicialização e o retorno de PIN para QR, com armazenamento fictício e sem
acessar servidor ou dados da empresa. Executar em Android de teste com permissão
de câmera concedida: `flutter test integration_test/pairing_camera_android_test.dart -d <id>`.
Esse teste complementa os testes simulados; um emulador não substitui a
homologação da imagem/leitura no telefone que apresentou a falha.

Verificação em **15/10/2026**: 238 testes Flutter aprovados, 248 testes de
backend aprovados em bancos temporários e análise estática sem problemas.
O teste nativo também passou no emulador **Android 17/API 37**, com câmera
emulada: abertura e reabertura retornaram captura de **1392 × 1856**. Esse
resultado confirma a inicialização da integração nativa nessa configuração;
não comprova os quadros exibidos ou a leitura de QR pela câmera física do
telefone do usuário, nem reproduz seu modelo/GPU. O acesso ao hardware não
foi substituído por um mock nesse teste; a cena da câmera é gerada pelo emulador.

APK de produção **1.0.1+2** gerado com sucesso usando `flutter build apk --release`:
`client/build/app/outputs/flutter-apk/ZM-Cestas-1.0.1-QR.apk` (cópia identificada
do `app-release.apk`). Após executar testes de integração, compilar com o comando
normal, sem `--no-pub`, para regenerar o registro de plugins de produção e
excluir o plugin nativo de testes. O script `compilar_android.bat` já usa esse
comando. Não desinstalar o app para substituir o APK: usar a atualização normal
e conferir a versão 1.0.1 antes de repetir a leitura.

## Efeitos no backend e no banco

Pareamento usa `/api/v1/pairing/initiate` e `/api/v1/pairing/confirm`; no terminal
local, o Windows pode usar `/api/v1/pairing/local-master` nas condições acima.
O PIN temporário e seu estado ficam em `pairing_sessions`. Os dispositivos,
identificação, status e hash SHA-256 do token ficam em `paired_devices`.
O cliente guarda a credencial pelo armazenamento seguro; o servidor não precisa
guardar o token bruto. URL e fingerprint são configuração de conexão do cliente,
não produtos ou operações comerciais no banco.

`GET /api/v1/devices` é uma consulta protegida. Revogação via
`POST /api/v1/devices/revoke` altera o status do dispositivo e impede sua
autenticação posterior. Salvar conexão ou parear não cria venda, compra ou ajuste
de estoque. Certificado/fingerprint verificam a identidade do servidor; o token
autoriza o dispositivo.

Exemplo: trocar o telefone não exige copiar o arquivo SQLite. Parear o telefone
novo permite consultar o banco central pelo servidor. Um telefone revogado não
é autenticado apenas por continuar com um token salvo.

## Onde conferir

- [Configurações](../client/lib/views/settings_view.dart), [pareamento](../client/lib/views/pairing_view.dart), [autenticação](../client/lib/services/auth_service.dart), [conectividade](../client/lib/services/connectivity_service.dart) e [armazenamento](../client/lib/core/secure_storage.dart).
- [API](../backend/app/api/v1/auth.py), [segurança](../backend/app/core/security.py) e [modelos](../backend/app/models/auth.py).
- [Testes de pareamento](../backend/tests/test_pairing_auth.py), [TLS](../backend/tests/test_security_tls.py) e [cliente](../client/test/settings_authentication_test.dart).
