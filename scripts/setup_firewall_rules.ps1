<#
.SYNOPSIS
    Configura regras do Windows Defender Firewall para o ZM Cesta Básica.
.DESCRIPTION
    Libera a porta 8000 TCP exclusivamente para redes Privadas e de Domínio (Wi-Fi local do galpão/loja).
    Bloqueia tráfego vindo de perfis Públicos de rede para garantir isolamento contra redes inseguras.
#>

param(
    [int]$Port = 8000,
    [string]$RuleName = "ZM Cesta Basica - API Local HTTPS (8000)"
)

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Configuracao de Firewall - ZM Cesta Basica" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# Verifica se está rodando como Administrador
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Warning "Este script necessita de privilegios administrativos para configurar o Windows Firewall."
    Write-Warning "Execute o PowerShell como Administrador para aplicar as regras."
    exit 1
}

# Remove regra anterior caso exista
$existing = Get-NetFirewallRule -DisplayName $RuleName -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "[*] Removendo regra anterior existente..." -ForegroundColor Yellow
    Remove-NetFirewallRule -DisplayName $RuleName
}

# Cria nova regra restrita a perfis Privado e Dominio
Write-Host "[*] Criando regra de entrada: Porta $Port TCP (Perfis Privado/Dominio)..." -ForegroundColor Green
New-NetFirewallRule -DisplayName $RuleName `
    -Direction Inbound `
    -LocalPort $Port `
    -Protocol TCP `
    -Action Allow `
    -Profile Private, Domain `
    -Description "Permite conexao de smartphones Android e clientes autorizados na rede Wi-Fi local da empresa para o ZM Cesta Basica." | Out-Null

Write-Host "[+] Regra criada com sucesso!" -ForegroundColor Green
Write-Host "    Nome da Regra:  $RuleName"
Write-Host "    Porta:          $Port (TCP)"
Write-Host "    Acao:           Permitir"
Write-Host "    Perfis:         Privado, Dominio (Publico bloqueado)"
Write-Host "============================================================" -ForegroundColor Cyan
