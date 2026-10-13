@echo off
setlocal
chcp 65001 >nul
title Compilar Windows - ZM Cesta Basica
echo ========================================================
echo       COMPILANDO APLICATIVO WINDOWS (RELEASE)
echo ========================================================
echo.

rem 1. Localiza o executavel do Flutter (prioriza o PATH de qualquer utilizador)
set "FLUTTER_CMD="
where flutter.bat >nul 2>&1 && set "FLUTTER_CMD=flutter.bat"
if not defined FLUTTER_CMD (
    where flutter >nul 2>&1 && set "FLUTTER_CMD=flutter"
)
if not defined FLUTTER_CMD if exist "C:\dev\flutter\bin\flutter.bat" (
    set "FLUTTER_CMD=C:\dev\flutter\bin\flutter.bat"
)
if not defined FLUTTER_CMD (
    echo [ERRO] Flutter nao encontrado no PATH do sistema nem em C:\dev\flutter.
    goto :fim
)

rem 2. Entra na pasta client de forma dinamica (funciona na raiz ou em scripts/)
if exist "%~dp0client" (
    cd /d "%~dp0client"
) else if exist "%~dp0..\client" (
    cd /d "%~dp0..\client"
) else (
    echo [ERRO] Pasta client nao encontrada.
    goto :fim
)

echo Diretorio de trabalho: %CD%
echo.

echo [1/2] A verificar dependencias (flutter pub get)...
call "%FLUTTER_CMD%" pub get
if errorlevel 1 (
    echo [ERRO] Falha no flutter pub get.
    goto :fim
)

echo.
echo [2/2] A compilar executavel Windows (Release)...
call "%FLUTTER_CMD%" build windows --release
set "BUILD_STATUS=%ERRORLEVEL%"

echo.
if "%BUILD_STATUS%"=="0" (
    echo ========================================================
    echo   [SUCESSO] EXECUTAVEL WINDOWS GERADO COM SUCESSO!
    echo   Local: client\build\windows\x64\runner\Release\
    echo   Envie a PASTA Release inteira, nao apenas o .exe
    echo ========================================================
) else (
    echo ========================================================
    echo   [ERRO] Falha na compilacao do Windows. Verifique os logs acima.
    echo ========================================================
)

:fim
echo.
echo Pressione qualquer tecla para fechar...
pause >nul
endlocal