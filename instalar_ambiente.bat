@echo off
setlocal
title Instalar Ambiente - ZM Cesta Basica
echo ========================================================
echo   INSTALANDO AMBIENTE DO SERVIDOR (.venv + dependencias)
echo ========================================================
echo.

set "ROOT_DIR=%~dp0"
set "BACKEND_DIR=%ROOT_DIR%backend"
set "VENV_DIR=%BACKEND_DIR%\.venv"
set "PYTHON_EXE=%VENV_DIR%\Scripts\python.exe"

if not exist "%BACKEND_DIR%\requirements.txt" (
    echo [ERRO] Arquivo nao encontrado: %BACKEND_DIR%\requirements.txt
    goto :fim
)

where python >nul 2>&1
if errorlevel 1 (
    echo [ERRO] Python nao foi encontrado no PATH.
    echo        Instale o Python 3 em https://www.python.org/downloads/
    echo        e marque a opcao "Add Python to PATH" na instalacao.
    goto :fim
)

if exist "%PYTHON_EXE%" (
    echo [1/2] Ambiente virtual ja existe. Mantendo: %VENV_DIR%
) else (
    echo [1/2] Criando ambiente virtual em %VENV_DIR% ...
    python -m venv "%VENV_DIR%"
    if errorlevel 1 (
        echo [ERRO] Falha ao criar o ambiente virtual.
        goto :fim
    )
)

echo.
echo [2/2] Instalando dependencias do requirements.txt ...
"%PYTHON_EXE%" -m pip install -r "%BACKEND_DIR%\requirements.txt"
if errorlevel 1 (
    echo [ERRO] Falha ao instalar dependencias.
    goto :fim
)

echo.
echo ========================================================
echo   [SUCESSO] Ambiente pronto!
echo   Agora execute iniciar_servidor.bat para ligar o servidor.
echo ========================================================

:fim
echo.
echo Pressione qualquer tecla para fechar...
pause >nul
endlocal
