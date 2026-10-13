@echo off
setlocal
title Compilar Windows - ZM Cesta Basica
echo ========================================================
echo       COMPILANDO APLICATIVO WINDOWS (RELEASE)
echo ========================================================
echo.

set "FLUTTER_BAT=C:\dev\flutter\bin\flutter.bat"
if not exist "%FLUTTER_BAT%" (
    where flutter.bat >nul 2>&1
    if errorlevel 1 (
        echo [ERRO] Flutter nao encontrado em C:\dev\flutter nem no PATH.
        goto :fim
    )
    set "FLUTTER_BAT=flutter.bat"
)

rem Unidade virtual evita problemas com acentos no caminho da pasta
subst Z: /d >nul 2>&1
subst Z: "%~dp0." >nul 2>&1
if errorlevel 1 (
    echo [ERRO] Nao foi possivel mapear a unidade virtual Z:
    goto :fim
)

pushd Z:\client
call "%FLUTTER_BAT%" build windows --release
set BUILD_STATUS=%ERRORLEVEL%
popd

subst Z: /d >nul 2>&1

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
