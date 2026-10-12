@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
set "ROOT_DIR=%SCRIPT_DIR%.."
set "PYTHON_EXE=%ROOT_DIR%\backend\.venv\Scripts\python.exe"
set "CLI_SCRIPT=%ROOT_DIR%\scripts\backup_cli.py"
set "LOGS_DIR=%ROOT_DIR%\backend\backups\logs"
set "LOG_FILE=%LOGS_DIR%\scheduled_backup.log"

if not exist "%LOGS_DIR%" (
    mkdir "%LOGS_DIR%" 2>nul
)

echo ============================================================ >> "%LOG_FILE%"
echo [%DATE% %TIME%] Iniciando Rotina de Backup Diario Agendado... >> "%LOG_FILE%"

"%PYTHON_EXE%" "%CLI_SCRIPT%" create --tag diario >> "%LOG_FILE%" 2>&1
if errorlevel 1 goto error

"%PYTHON_EXE%" "%CLI_SCRIPT%" cleanup --keep 30 >> "%LOG_FILE%" 2>&1
if errorlevel 1 goto error

echo [%DATE% %TIME%] Backup diario e rotacao concluidos com sucesso. >> "%LOG_FILE%"
echo Backup concluido com sucesso.
exit /b 0

:error
echo [%DATE% %TIME%] [ERRO CRITICO] Falha na execucao do backup diario! >> "%LOG_FILE%"
echo Falha na execucao do backup.
exit /b 1
