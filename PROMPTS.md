**1. Comandos para o BACK-END (Python / FastAPI)**



O backend em Python não precisa de compilação em executável binário; ele roda a partir do ambiente virtual e das migrações do banco de dados SQLite.



Para preparar e testar se tudo está 100% pronto na raiz:

\# 1. Executa a suíte completa de testes do backend para garantir que não há erros

.\\backend\\.venv\\Scripts\\python.exe -m pytest backend/tests -q



\# 2. Executar o servidor backend (porta padrão com HTTPS/TLS local):

.\\backend\\.venv\\Scripts\\python.exe -m uvicorn app.main:app --app-dir backend --host 0.0.0.0 --port 8000



*(Você também pode dar dois cliques no arquivo iniciar\_servidor.bat que já criamos na raiz).*





**2. Comandos para COMPILAR O FRONT-END (Flutter)**



Abra o terminal PowerShell na raiz (ZM CESTA BÁSICA) e execute:



**A) Gerar Executável para WINDOWS Desktop:**

cd client

\& "C:\\dev\\flutter\\bin\\flutter.bat" build windows --debug

cd ..



O que foi gerado: A pasta completa em: client\\build\\windows\\x64\\runner\\Debug\\

O que você envia para o usuário de Windows: Envie a pasta inteira Debug compactada em .zip (ela contém o zm\_cesta\_basica\_client.exe junto com as DLLs e a pasta data necessárias para abrir o app). Não envie apenas o arquivo .exe solto, pois ele precisa das DLLs irmãs para inicializar.



**B) Gerar Aplicativo para ANDROID (APK):**

cd client

\& "C:\\dev\\flutter\\bin\\flutter.bat" build apk --debug

cd ..



O APK Release é gerado pelo comando flutter build apk --release (estou gerando ele agora para você).

cmd /c "subst X: C:\\Users\\jardi\\Desktop\\ZMCEST\~1\\client \&\& cd /d X:\\ \&\& C:\\dev\\flutter\\bin\\flutter.bat build apk --release \&\& subst X: /d"



O que foi gerado: O arquivo APK em: client\\build\\app\\outputs\\flutter-apk\\app-debug.apk

O que você envia para o usuário de celular Android: Basta enviar apenas esse arquivo único app-debug.apk (pelo WhatsApp, Google Drive, cabo USB ou Telegram). O usuário clica nele no celular e instala.



**3. Comando Único (Tudo de Uma Vez)**

Se quiser rodar um único comando na raiz que compila o Flutter para Windows e Android sequencialmente:

cd client; \& "C:\\dev\\flutter\\bin\\flutter.bat" build windows --debug; \& "C:\\dev\\flutter\\bin\\flutter.bat" build apk --debug; cd ..



Resumo do que entregar:

No computador que atuará como Servidor: A pasta do projeto rodando o backend via iniciar\_servidor.bat.

Nos computadores Windows clientes: A pasta client\\build\\windows\\x64\\runner\\Debug\\ (compactada em zip).

Nos celulares/tablets Android: O arquivo client\\build\\app\\outputs\\flutter-apk\\app-debug.apk.



**Quando você clona o projeto em um computador novo ou precisa recriar a .venv, você só precisa rodar 2 comandos simples no terminal a partir da raiz do projeto:**



\# 1. Cria a pasta .venv dentro de backend usando o Python instalado no computador

python -m venv backend\\.venv



\# 2. Instala todas as dependências do projeto listadas no requirements.txt

.\\backend\\.venv\\Scripts\\python.exe -m pip install -r backend\\requirements.txt





**E o banco de dados?**



Depois que a .venv for criada e as dependências instaladas, ao rodar o comando:

.\\backend\\.venv\\Scripts\\python.exe -m alembic -c backend/alembic.ini upgrade head



ou simplesmente dar dois cliques no iniciar\_servidor.bat, ele já cria/atualiza as tabelas do banco SQLite (backend/data/estoque.db) e os certificados TLS automaticamente.





