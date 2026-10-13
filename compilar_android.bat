@echo off
setlocal
chcp 65001 >nul
title Compilar Android - ZM Cesta Basica
echo ========================================================
echo       COMPILANDO APLICATIVO ANDROID (APK RELEASE)
echo ========================================================
echo.

rem Forca o Java e o Gradle a usarem UTF-8 nos processos filhos
set "JAVA_TOOL_OPTIONS=-Dfile.encoding=UTF-8 -Dsun.jnu.encoding=UTF-8"
set "GRADLE_OPTS=-Dfile.encoding=UTF-8 -Dsun.jnu.encoding=UTF-8"

rem 1. Localiza o executavel do Flutter
set "FLUTTER_CMD="
if exist "C:\dev\flutter\bin\flutter.bat" set "FLUTTER_CMD=C:\dev\flutter\bin\flutter.bat"
if not defined FLUTTER_CMD (
    where flutter.bat >nul 2>&1 && set "FLUTTER_CMD=flutter.bat"
)
if not defined FLUTTER_CMD (
    where flutter >nul 2>&1 && set "FLUTTER_CMD=flutter"
)
if not defined FLUTTER_CMD (
    echo [ERRO] Flutter nao encontrado em C:\dev\flutter nem no PATH do sistema.
    goto :fim
)

rem 2. Entra na pasta client
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
echo [2/2] A compilar APK Release...
call "%FLUTTER_CMD%" build apk --release
set "BUILD_STATUS=%ERRORLEVEL%"

echo.
if "%BUILD_STATUS%"=="0" (
    echo ========================================================
    echo   [SUCESSO] APK GERADO COM SUCESSO!
    echo   Local: client\build\app\outputs\flutter-apk\app-release.apk
    echo ========================================================
) else (
    echo ========================================================
    echo   [ERRO] Falha na compilacao do APK. Verifique os logs acima.
    echo ========================================================
)

:fim
echo.
echo Pressione qualquer tecla para fechar...
pause >nul
endlocal