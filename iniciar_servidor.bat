@echo off
setlocal
chcp 65001 >nul
title Servidor Local - ZM Cesta Basica

rem ============================================================================
rem ZM CESTA BASICA - INICIALIZADOR DO SERVIDOR LOCAL (FASTAPI + HTTPS + SQLite)
rem Cria a pasta .venv e instala as dependencias automaticamente se faltarem.
rem ============================================================================

rem 1. Localiza a pasta backend de forma dinamica (na raiz ou dentro de scripts/)
if exist "%~dp0backend" (
    set "BACKEND_DIR=%~dp0backend"
) else if exist "%~dp0..\backend" (
    pushd "%~dp0.."
    set "BACKEND_DIR=%CD%\backend"
    popd
) else (
    echo [ERRO] Pasta backend nao encontrada!
    goto :fim
)

set "VENV_DIR=%BACKEND_DIR%\.venv"
set "PYTHON_EXE=%VENV_DIR%\Scripts\python.exe"

cd /d "%BACKEND_DIR%"
if errorlevel 1 (
    echo [ERRO] Nao foi possivel aceder a pasta backend: %BACKEND_DIR%
    goto :fim
)

echo ============================================================
echo           INICIANDO SERVIDOR LOCAL - ZM CESTA BASICA
echo ============================================================
echo Diretorio do Backend: %BACKEND_DIR%
echo.

if exist "%PYTHON_EXE%" goto :venv_ok

echo [0/3] Ambiente virtual nao encontrado. Criando em %VENV_DIR% ...
where python >nul 2>&1
if errorlevel 1 (
    echo [ERRO] Python nao foi encontrado no PATH.
    echo        Instale o Python 3 em https://www.python.org/downloads/
    echo        e marque a opcao "Add Python to PATH" na instalacao.
    goto :fim
)
python -m venv "%VENV_DIR%"
if errorlevel 1 (
    echo [ERRO] Falha ao criar o ambiente virtual.
    goto :fim
)
echo Instalando dependencias ^(pode demorar alguns minutos^)...
"%PYTHON_EXE%" -m pip install -r "%BACKEND_DIR%\requirements.txt"
if errorlevel 1 (
    echo [ERRO] Falha ao instalar dependencias.
    goto :fim
)

:venv_ok
echo [1/3] Verificando e aplicando migracoes no banco SQLite...
"%PYTHON_EXE%" -m alembic upgrade head
if errorlevel 1 (
    echo [ERRO] Falha ao migrar banco de dados!
    goto :fim
)

echo.
echo [2/2] Verificando certificados criptograficos TLS locais...
"%PYTHON_EXE%" -c "from app.core.config import settings; from app.core.security import generate_self_signed_cert; settings.ensure_directories(); generate_self_signed_cert(settings.CERTS_DIR / 'server.crt', settings.CERTS_DIR / 'server.key')"
if errorlevel 1 (
    echo [ERRO] Falha ao inicializar certificados TLS!
    goto :fim
)

echo.
echo [3/3] Servidor online em HTTPS!
echo       Endereco local:  https://127.0.0.1:8000
echo       Porta de rede:   8000 ^(disponivel para telemoveis/celulares^)
echo.
echo ============================================================
echo Mantenha esta janela aberta enquanto estiver utilizando o sistema.
echo Para encerrar o servidor, feche esta janela ou pressione Ctrl + C.
echo ============================================================
echo.

"%PYTHON_EXE%" -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --ssl-keyfile certs/server.key --ssl-certfile certs/server.crt --workers 1

echo.
echo Servidor encerrado.

:fim
echo.
echo Pressione qualquer tecla para fechar...
pause >nul
endlocal