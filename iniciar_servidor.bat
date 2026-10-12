@echo off
setlocal
title Servidor Local - ZM Cesta Basica
chcp 65001 >nul

rem ============================================================================
rem ZM CESTA BASICA - INICIALIZADOR DO SERVIDOR LOCAL (FASTAPI + HTTPS + SQLite)
rem ============================================================================

set "ROOT_DIR=%~dp0"
set "BACKEND_DIR=%ROOT_DIR%backend"
set "PYTHON_EXE=%BACKEND_DIR%\.venv\Scripts\python.exe"

cd /d "%BACKEND_DIR%"

cls
echo ============================================================
echo           INICIANDO SERVIDOR LOCAL - ZM CESTA BASICA
echo ============================================================
echo Diretorio do Backend: %BACKEND_DIR%
echo.

if not exist "%PYTHON_EXE%" (
    echo [ERRO] Ambiente virtual nao encontrado em:
    echo        %PYTHON_EXE%
    echo.
    echo Pressione qualquer tecla para fechar...
    pause >nul
    exit /b 1
)

echo [1/3] Verificando e aplicando migracoes no banco SQLite...
"%PYTHON_EXE%" -m alembic upgrade head
if errorlevel 1 (
    echo [ERRO] Falha ao migrar banco de dados!
    echo.
    pause
    exit /b 1
)

echo.
echo [2/3] Verificando certificados criptograficos TLS locais...
"%PYTHON_EXE%" -c "from app.core.config import settings; from app.core.security import generate_self_signed_cert; settings.ensure_directories(); generate_self_signed_cert(settings.CERTS_DIR / 'server.crt', settings.CERTS_DIR / 'server.key')"
if errorlevel 1 (
    echo [ERRO] Falha ao inicializar certificados TLS!
    echo.
    pause
    exit /b 1
)

echo.
echo [3/3] Servidor online em HTTPS!
echo       Endereço local:  https://127.0.0.1:8000
echo       Porta de rede:   8000 (disponivel para celulares)
echo.
echo ============================================================
echo Mantenha esta janela aberta enquanto estiver utilizando o sistema.
echo Para encerrar o servidor, feche esta janela ou pressione Ctrl + C.
echo ============================================================
echo.

"%PYTHON_EXE%" -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --ssl-keyfile certs/server.key --ssl-certfile certs/server.crt --workers 1

echo.
echo Servidor encerrado.
pause
