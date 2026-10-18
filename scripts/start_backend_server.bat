@echo off
setlocal

rem ============================================================================
rem ZM CESTA BASICA - INICIALIZADOR DO SERVIDOR LOCAL (FASTAPI + TLS + WAL)
rem ============================================================================

set "SCRIPT_DIR=%~dp0"
set "ROOT_DIR=%SCRIPT_DIR%.."
set "BACKEND_DIR=%ROOT_DIR%\backend"
set "PYTHON_EXE=%BACKEND_DIR%\.venv\Scripts\python.exe"

cd /d "%BACKEND_DIR%"

echo ============================================================
echo Iniciando Servidor ZM Cesta Basica...
echo Diretorio Backend: %BACKEND_DIR%
echo ============================================================

if not exist "%PYTHON_EXE%" (
    echo [ERRO] Ambiente virtual nao encontrado em: %PYTHON_EXE%
    pause
    exit /b 1
)

echo [1/3] Aplicando migracoes do banco de dados SQLite...
"%PYTHON_EXE%" -m alembic upgrade head
if errorlevel 1 (
    echo [ERRO] Falha ao aplicar migracoes do banco de dados!
    pause
    exit /b 1
)

echo [2/3] Garantindo certificados de seguranca TLS locais (HTTPS)...
"%PYTHON_EXE%" -c "from app.core.config import settings; from app.core.security import generate_self_signed_cert; settings.ensure_directories(); generate_self_signed_cert(settings.CERTS_DIR / 'server.crt', settings.CERTS_DIR / 'server.key')"
if errorlevel 1 (
    echo [ERRO] Falha ao verificar/gerar certificados TLS!
    pause
    exit /b 1
)

echo [3/3] Subindo servico HTTPS Local (porta 8000)...
"%PYTHON_EXE%" -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --ssl-keyfile certs/server.key --ssl-certfile certs/server.crt --workers 1 --timeout-keep-alive 65

pause
