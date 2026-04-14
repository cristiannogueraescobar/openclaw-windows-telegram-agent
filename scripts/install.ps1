#Requires -Version 5.1
<#
.SYNOPSIS
    Script de instalación automática de OpenClaw Windows Agent.
.DESCRIPTION
    Instala todas las dependencias necesarias y configura OpenClaw.
    Probado en: Windows 11 25H2, Build 26200, 8 GB RAM
    Versiones: Node.js v24.14.1, npm 11.11.0, OpenClaw 2026.4.11
.NOTES
    Ejecutar como: .\scripts\install.ps1
#>

param(
    [switch]$SkipNodeJS,
    [switch]$SkipOllama,
    [switch]$SkipOnboard,
    [switch]$Silent
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
$MIN_NODE_VERSION = [version]"22.14.0"
$OPENCLAW_CONFIG_DIR = Join-Path $env:USERPROFILE ".openclaw"
$LOG_FILE = Join-Path $PSScriptRoot "install.log"

# --- Funciones ---

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $LOG_FILE -Value "[$timestamp] [$Level] $Message"
    switch ($Level) {
        "ERROR"   { Write-Host "  ❌ $Message" -ForegroundColor Red }
        "WARNING" { Write-Host "  ⚠️  $Message" -ForegroundColor Yellow }
        "SUCCESS" { Write-Host "  ✅ $Message" -ForegroundColor Green }
        default   { if (-not $Silent) { Write-Host "  ℹ️  $Message" -ForegroundColor Cyan } }
    }
}

function Test-CommandExists {
    param([string]$Command)
    $null = Get-Command $Command -ErrorAction SilentlyContinue
    return $?
}

function Get-NodeVersion {
    try {
        $versionStr = (node --version 2>$null) -replace '^v', ''
        return [version]$versionStr
    } catch { return $null }
}

# --- Inicio ---

Write-Host ""
Write-Host "╔══════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║   🦞 OpenClaw Windows Agent - Instalador    ║" -ForegroundColor Magenta
Write-Host "║   Probado: Win11 25H2 / Node v24 / OC 2026 ║" -ForegroundColor Magenta
Write-Host "╚══════════════════════════════════════════════╝" -ForegroundColor Magenta
Write-Host ""

# Política de ejecución
try {
    $currentPolicy = Get-ExecutionPolicy -Scope CurrentUser
    if ($currentPolicy -eq "Restricted") {
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
        Write-Log "Política de ejecución configurada: RemoteSigned" "SUCCESS"
    }
} catch {
    Write-Log "No se pudo cambiar la política de ejecución: $($_.Exception.Message)" "WARNING"
}

# --- Paso 1: Node.js ---
Write-Host "── Paso 1/5: Node.js (necesario: v22.14+, probado: v24.14.1) ──" -ForegroundColor White

if (-not $SkipNodeJS) {
    $nodeVersion = Get-NodeVersion
    if ($null -eq $nodeVersion) {
        Write-Log "Node.js no encontrado. Instalando via winget..."
        if (Test-CommandExists "winget") {
            winget install OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements 2>&1 | Out-Null
            $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
            $nodeVersion = Get-NodeVersion
            if ($null -ne $nodeVersion) {
                Write-Log "Node.js $nodeVersion instalado" "SUCCESS"
            } else {
                Write-Log "Node.js se instaló pero no está en PATH. Cierra y reabre PowerShell." "ERROR"
                exit 1
            }
        } else {
            Write-Log "winget no disponible. Descarga Node.js de https://nodejs.org" "ERROR"
            exit 1
        }
    } elseif ($nodeVersion -lt $MIN_NODE_VERSION) {
        Write-Log "Node.js $nodeVersion es antiguo. Actualizando..."
        winget upgrade OpenJS.NodeJS.LTS --accept-source-agreements 2>&1 | Out-Null
        Write-Log "Node.js actualizado" "SUCCESS"
    } else {
        Write-Log "Node.js $nodeVersion (OK)" "SUCCESS"
    }
}

# --- Paso 2: Git ---
Write-Host ""
Write-Host "── Paso 2/5: Git ──" -ForegroundColor White

if (Test-CommandExists "git") {
    Write-Log "Git detectado (OK)" "SUCCESS"
} else {
    Write-Log "Instalando Git..."
    if (Test-CommandExists "winget") {
        winget install Git.Git --accept-source-agreements --accept-package-agreements 2>&1 | Out-Null
        Write-Log "Git instalado" "SUCCESS"
    } else {
        Write-Log "Git no instalado (opcional). Descarga: https://git-scm.com" "WARNING"
    }
}

# --- Paso 3: Ollama (opcional) ---
Write-Host ""
Write-Host "── Paso 3/5: Ollama (opcional — probado: v0.20.6) ──" -ForegroundColor White

if (-not $SkipOllama) {
    if (Test-CommandExists "ollama") {
        Write-Log "Ollama detectado (OK)" "SUCCESS"
        # Configurar contexto extendido
        $currentCtx = [System.Environment]::GetEnvironmentVariable("OLLAMA_CONTEXT_LENGTH", "User")
        if ($null -eq $currentCtx -or [int]$currentCtx -lt 16384) {
            [System.Environment]::SetEnvironmentVariable("OLLAMA_CONTEXT_LENGTH", "65536", "User")
            $env:OLLAMA_CONTEXT_LENGTH = "65536"
            Write-Log "OLLAMA_CONTEXT_LENGTH=65536 configurado" "SUCCESS"
        }
        # Configurar acceso en red
        [System.Environment]::SetEnvironmentVariable("OLLAMA_HOST", "0.0.0.0:11434", "User")
        Write-Log "OLLAMA_HOST=0.0.0.0:11434 configurado" "SUCCESS"
    } else {
        Write-Host ""
        Write-Host "  ⚠️  NOTA: Con 8 GB RAM, Ollama es muy lento. Claude API es mejor opción." -ForegroundColor Yellow
        $installOllama = Read-Host "  ¿Instalar Ollama de todas formas? (s/n)"
        if ($installOllama -eq "s" -or $installOllama -eq "S") {
            winget install Ollama.Ollama --accept-source-agreements --accept-package-agreements 2>&1 | Out-Null
            [System.Environment]::SetEnvironmentVariable("OLLAMA_CONTEXT_LENGTH", "65536", "User")
            [System.Environment]::SetEnvironmentVariable("OLLAMA_HOST", "0.0.0.0:11434", "User")
            Write-Log "Ollama instalado con contexto 65536" "SUCCESS"
            Write-Log "Descarga modelo: ollama pull qwen2.5:3b"
        } else {
            Write-Log "Ollama omitido. Necesitarás Claude API." "WARNING"
        }
    }
}

# --- Paso 4: OpenClaw ---
Write-Host ""
Write-Host "── Paso 4/5: OpenClaw (probado: 2026.4.11) ──" -ForegroundColor White

if (Test-CommandExists "openclaw") {
    $ocVersion = openclaw --version 2>$null
    Write-Log "OpenClaw $ocVersion ya instalado" "SUCCESS"
    Write-Log "Actualizando..."
    npm update -g openclaw 2>&1 | Out-Null
    Write-Log "OpenClaw actualizado" "SUCCESS"
} else {
    Write-Log "Instalando OpenClaw via script oficial..."
    try {
        # Método recomendado: script oficial
        $installScript = Invoke-RestMethod -Uri "https://openclaw.ai/install.ps1"
        Invoke-Expression $installScript
        
        # Verificar
        $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
        
        # Añadir npm global al PATH si necesario
        $npmPrefix = npm config get prefix 2>$null
        if ($npmPrefix -and ($env:PATH -notlike "*$npmPrefix*")) {
            [System.Environment]::SetEnvironmentVariable("PATH", "$env:PATH;$npmPrefix", "User")
            $env:PATH = "$env:PATH;$npmPrefix"
        }
        
        if (Test-CommandExists "openclaw") {
            Write-Log "OpenClaw instalado correctamente" "SUCCESS"
        } else {
            Write-Log "Intentando via npm..."
            npm install -g openclaw@latest 2>&1 | Out-Null
            $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
            if (Test-CommandExists "openclaw") {
                Write-Log "OpenClaw instalado via npm" "SUCCESS"
            } else {
                Write-Log "OpenClaw no se encuentra en PATH. Ejecuta: npm config get prefix y añade al PATH" "ERROR"
                exit 1
            }
        }
    } catch {
        Write-Log "Error: $($_.Exception.Message). Intentando npm directo..."
        npm install -g openclaw@latest 2>&1 | Out-Null
    }
}

# --- Paso 5: Configuración ---
Write-Host ""
Write-Host "── Paso 5/5: Configuración inicial ──" -ForegroundColor White

if (-not (Test-Path $OPENCLAW_CONFIG_DIR)) {
    New-Item -ItemType Directory -Path $OPENCLAW_CONFIG_DIR -Force | Out-Null
    Write-Log "Directorio creado: $OPENCLAW_CONFIG_DIR" "SUCCESS"
}

$configFile = Join-Path $OPENCLAW_CONFIG_DIR "openclaw.json"
$exampleConfig = Join-Path $PSScriptRoot "..\config\openclaw.json.example"

if (-not (Test-Path $configFile)) {
    if (Test-Path $exampleConfig) {
        Copy-Item $exampleConfig $configFile
        Write-Log "Configuración de ejemplo copiada" "SUCCESS"
        Write-Log "EDITAR: notepad $configFile" "WARNING"
    }
}

# Crear .wslconfig para limitar RAM de WSL2
$wslConfig = Join-Path $env:USERPROFILE ".wslconfig"
if (-not (Test-Path $wslConfig)) {
    @"
[wsl2]
memory=3GB
processors=2
swap=2GB
"@ | Out-File -FilePath $wslConfig -Encoding utf8
    Write-Log ".wslconfig creado (WSL2 limitado a 3GB RAM)" "SUCCESS"
}

# Onboarding
if (-not $SkipOnboard) {
    Write-Host ""
    $runOnboard = Read-Host "  ¿Ejecutar asistente de configuración? (s/n)"
    if ($runOnboard -eq "s" -or $runOnboard -eq "S") {
        openclaw onboard --install-daemon
    }
}

# --- Resumen ---
Write-Host ""
Write-Host "╔══════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║      ✅ Instalación completada               ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

$nodeV = node --version 2>$null
$npmV = npm --version 2>$null
$ollamaV = if (Test-CommandExists "ollama") { "Instalado" } else { "No instalado" }

Write-Host "  Node.js:   $nodeV" -ForegroundColor White
Write-Host "  npm:       v$npmV" -ForegroundColor White
Write-Host "  OpenClaw:  $(openclaw --version 2>$null)" -ForegroundColor White
Write-Host "  Ollama:    $ollamaV" -ForegroundColor White
Write-Host ""
Write-Host "  Próximos pasos:" -ForegroundColor Yellow
Write-Host "    1. Editar config: notepad $configFile" -ForegroundColor White
Write-Host "    2. O usar script: .\scripts\configure.ps1" -ForegroundColor White
Write-Host "    3. Iniciar:       .\scripts\start.ps1" -ForegroundColor White
Write-Host ""
