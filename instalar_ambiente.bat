@echo off
setlocal
chcp 65001 >nul
title Instalar Ambiente - ZM Cesta Basica
echo ========================================================
echo   INSTALANDO AMBIENTE DO SERVIDOR (.venv + dependencias)
echo ========================================================
echo.

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

if not exist "%BACKEND_DIR%\requirements.txt" (
    echo [ERRO] Ficheiro nao encontrado: %BACKEND_DIR%\requirements.txt
    goto :fim
)

rem 2. Verifica a presenca do Python no PATH do sistema
where python >nul 2>&1
if errorlevel 1 (
    echo [ERRO] O Python nao foi encontrado no PATH.
    echo        Instale o Python 3 a partir de https://www.python.org/downloads/
    echo        e selecione a opcao "Add Python to PATH" durante a instalacao.
    goto :fim
)

rem 3. Cria o ambiente virtual caso ainda nao exista
if exist "%PYTHON_EXE%" (
    echo [1/2] O ambiente virtual ja existe. Mantendo: %VENV_DIR%
) else (
    echo [1/2] A criar ambiente virtual em %VENV_DIR% ...
    python -m venv "%VENV_DIR%"
    if errorlevel 1 (
        echo [ERRO] Falha ao criar o ambiente virtual.
        goto :fim
    )
)

echo.
rem 4. Instala ou atualiza as dependencias do backend
echo [2/2] A instalar dependencias a partir de requirements.txt ...
"%PYTHON_EXE%" -m pip install -r "%BACKEND_DIR%\requirements.txt"
if errorlevel 1 (
    echo [ERRO] Falha ao instalar dependencias.
    goto :fim
)

echo.
echo ========================================================
echo   [SUCESSO] Ambiente configurado com sucesso!
echo   Execute iniciar_servidor.bat para colocar o servidor online.
echo ========================================================

:fim
echo.
echo Pressione qualquer tecla para fechar...
pause >nul
endlocal