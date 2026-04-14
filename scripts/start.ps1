#Requires -Version 5.1
<#
.SYNOPSIS
    Inicia todos los servicios para OpenClaw Windows Agent.
.DESCRIPTION
    Verifica dependencias, inicia Ollama (si disponible), arranca gateway.
    Orden de arranque probado: Ollama → Gateway → Verificación
#>

param(
    [switch]$NoOllama,
    [switch]$Foreground
)

$ErrorActionPreference = "Continue"

function Test-CommandExists {
    param([string]$Command)
    $null = Get-Command $Command -ErrorAction SilentlyContinue
    return $?
}

function Test-PortInUse {
    param([int]$Port)
    $conn = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue
    return $null -ne $conn
}

Write-Host ""
Write-Host "╔══════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║      🦞 OpenClaw Windows Agent - Inicio     ║" -ForegroundColor Magenta
Write-Host "╚══════════════════════════════════════════════╝" -ForegroundColor Magenta
Write-Host ""

# --- Verificaciones ---

Write-Host "── Verificando requisitos ──" -ForegroundColor White

if (-not (Test-CommandExists "node")) {
    Write-Host "  ❌ Node.js no encontrado. Ejecuta .\scripts\install.ps1" -ForegroundColor Red; exit 1
}
Write-Host "  ✅ Node.js $(node --version)" -ForegroundColor Green

if (-not (Test-CommandExists "openclaw")) {
    Write-Host "  ❌ OpenClaw no encontrado. Ejecuta: npm install -g openclaw@latest" -ForegroundColor Red; exit 1
}
Write-Host "  ✅ OpenClaw instalado" -ForegroundColor Green

$configFile = Join-Path $env:USERPROFILE ".openclaw\openclaw.json"
if (-not (Test-Path $configFile)) {
    Write-Host "  ❌ Configuración no encontrada. Ejecuta .\scripts\configure.ps1" -ForegroundColor Red; exit 1
}
Write-Host "  ✅ Configuración encontrada" -ForegroundColor Green

# --- Ollama (si disponible) ---

if (-not $NoOllama -and (Test-CommandExists "ollama")) {
    Write-Host ""
    Write-Host "── Iniciando Ollama ──" -ForegroundColor White
    
    $ollamaRunning = $false
    try {
        Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -TimeoutSec 3 -ErrorAction SilentlyContinue | Out-Null
        $ollamaRunning = $true
    } catch {}
    
    if ($ollamaRunning) {
        Write-Host "  ✅ Ollama ya está corriendo" -ForegroundColor Green
    } else {
        $env:OLLAMA_CONTEXT_LENGTH = "65536"
        $env:OLLAMA_HOST = "0.0.0.0:11434"
        Start-Process "ollama" -ArgumentList "serve" -WindowStyle Hidden
        
        $retries = 0
        while ($retries -lt 15) {
            Start-Sleep -Seconds 2
            try {
                Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -TimeoutSec 3 -ErrorAction SilentlyContinue | Out-Null
                break
            } catch { $retries++ }
        }
        
        if ($retries -ge 15) {
            Write-Host "  ⚠️  Ollama no respondió. Continuando sin Ollama." -ForegroundColor Yellow
        } else {
            Write-Host "  ✅ Ollama iniciado" -ForegroundColor Green
        }
    }
}

# --- Gateway ---

Write-Host ""
Write-Host "── Iniciando Gateway ──" -ForegroundColor White

if (Test-PortInUse 18789) {
    # Verificar si es nuestro gateway
    $status = openclaw gateway status 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ Gateway ya corriendo" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  Puerto 18789 en uso. Limpiando..." -ForegroundColor Yellow
        $conns = Get-NetTCPConnection -LocalPort 18789 -ErrorAction SilentlyContinue
        $conns | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue }
        Start-Sleep -Seconds 2
        
        if ($Foreground) {
            openclaw gateway run
        } else {
            openclaw gateway start 2>$null
        }
    }
} else {
    if ($Foreground) {
        Write-Host "  Modo primer plano (Ctrl+C para detener)..." -ForegroundColor Cyan
        openclaw gateway run
    } else {
        openclaw gateway start 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  Instalando servicio..." -ForegroundColor Yellow
            openclaw gateway install 2>$null
            openclaw gateway start 2>$null
        }
        
        Start-Sleep -Seconds 3
        openclaw gateway status 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✅ Gateway iniciado" -ForegroundColor Green
        } else {
            Write-Host "  ⚠️  Intenta: openclaw gateway run (modo foreground para ver errores)" -ForegroundColor Yellow
        }
    }
}

# --- Estado ---

if (-not $Foreground) {
    Write-Host ""
    Write-Host "── Estado del sistema ──" -ForegroundColor White
    openclaw gateway status 2>$null
    
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║           🦞 Sistema iniciado                ║" -ForegroundColor Green
    Write-Host "╚══════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Envía un mensaje a tu bot en Telegram para probar." -ForegroundColor White
    Write-Host ""
    Write-Host "  Comandos útiles:" -ForegroundColor Gray
    Write-Host "    openclaw gateway status    # Ver estado" -ForegroundColor Gray
    Write-Host "    openclaw logs --follow     # Logs en tiempo real" -ForegroundColor Gray
    Write-Host "    openclaw gateway stop      # Detener" -ForegroundColor Gray
    Write-Host "    openclaw tui               # Interfaz terminal" -ForegroundColor Gray
    Write-Host ""
}
