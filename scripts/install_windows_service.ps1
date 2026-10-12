<#
.SYNOPSIS
    Instala e agenda a inicializacao automatica do servidor e dos backups no Windows.
.DESCRIPTION
    Registra duas tarefas agendadas no Agendador de Tarefas do Windows (Task Scheduler):
    1. ZMCestaBasica_Server: Inicia o backend FastAPI com TLS automaticamente ao ligar o computador / logon.
    2. ZMCestaBasica_DailyBackup: Executa o backup quente diario e limpeza de retencao as 23:00.
#>

param(
    [string]$InstallDir = ""
)

if (-not $InstallDir) {
    $InstallDir = (Resolve-Path "$PSScriptRoot\..").Path
}

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Instalador de Tarefas Agendadas - ZM Cesta Basica" -ForegroundColor Cyan
Write-Host "Diretorio do Projeto: $InstallDir" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Cyan

$serverScript = Join-Path $InstallDir "scripts\start_backend_server.bat"
$backupScript = Join-Path $InstallDir "scripts\run_scheduled_backup.bat"

if (-not (Test-Path $serverScript)) {
    Write-Error "Script do servidor nao encontrado em: $serverScript"
    exit 1
}

if (-not (Test-Path $backupScript)) {
    Write-Error "Script de backup nao encontrado em: $backupScript"
    exit 1
}

# 1. Agendamento do Servidor Local (Inicializacao no Logon)
$serverTaskName = "ZMCestaBasica_Server"
Write-Host "[*] Registrando tarefa agendada: $serverTaskName..." -ForegroundColor Green
$serverAction = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c `"$serverScript`"" -WorkingDirectory (Join-Path $InstallDir "backend")
$serverTrigger = New-ScheduledTaskTrigger -AtLogOn
$serverPrincipal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Highest
$serverSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Days 365)

Unregister-ScheduledTask -TaskName $serverTaskName -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
Register-ScheduledTask -TaskName $serverTaskName -Action $serverAction -Trigger $serverTrigger -Principal $serverPrincipal -Settings $serverSettings -Description "Inicia o servidor backend FastAPI do ZM Cesta Basica automaticamente." | Out-Null
Write-Host "[+] Tarefa $serverTaskName registrada com sucesso!" -ForegroundColor Green

# 2. Agendamento do Backup Quente Diario (23:00)
$backupTaskName = "ZMCestaBasica_DailyBackup"
Write-Host "[*] Registrando tarefa agendada: $backupTaskName..." -ForegroundColor Green
$backupAction = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c `"$backupScript`"" -WorkingDirectory $InstallDir
$backupTrigger = New-ScheduledTaskTrigger -Daily -At "23:00"
$backupSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

Unregister-ScheduledTask -TaskName $backupTaskName -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
Register-ScheduledTask -TaskName $backupTaskName -Action $backupAction -Trigger $backupTrigger -Principal $serverPrincipal -Settings $backupSettings -Description "Executa backup quente diario atômico do SQLite da base ZM Cesta Basica." | Out-Null
Write-Host "[+] Tarefa $backupTaskName registrada com sucesso (execucao diaria as 23:00)!" -ForegroundColor Green

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Instalacao concluida com sucesso!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
