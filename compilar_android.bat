@echo off
chcp 65001 >nul
echo ========================================================
echo       COMPILANDO APLICATIVO ANDROID (APK RELEASE)
echo ========================================================
echo.

:: 1. Garante uma unidade virtual limpa para evitar problemas com acentos (Á)
subst Z: /d >nul 2>&1
subst Z: "%~dp0." >nul 2>&1

:: 2. Executa a compilação do Flutter a partir da unidade Z:
pushd Z:\client
call "C:\dev\flutter\bin\flutter.bat" build apk --release
set BUILD_STATUS=%ERRORLEVEL%
popd

:: 3. Remove a unidade temporária
subst Z: /d >nul 2>&1

echo.
if %BUILD_STATUS% equ 0 (
    echo ========================================================
    echo   [SUCESSO] APK GERADO COM SUCESSO!
    echo   Local: client\build\app\outputs\flutter-apk\app-release.apk
    echo ========================================================
) else (
    echo ========================================================
    echo   [ERRO] Falha na compilação do APK. Verifique os logs.
    echo ========================================================
)

echo.
pause
