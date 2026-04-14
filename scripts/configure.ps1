#Requires -Version 5.1
<#
.SYNOPSIS
    Configuración interactiva de OpenClaw Windows Agent.
.DESCRIPTION
    Guía para configurar Telegram, API keys y preferencias.
    Genera el openclaw.json basado en la configuración REAL probada.
#>

$ErrorActionPreference = "Stop"
$CONFIG_DIR = Join-Path $env:USERPROFILE ".openclaw"
$CONFIG_FILE = Join-Path $CONFIG_DIR "openclaw.json"

# --- Inicio ---

Write-Host ""
Write-Host "╔══════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║  🦞 OpenClaw Windows Agent - Configuración  ║" -ForegroundColor Magenta
Write-Host "╚══════════════════════════════════════════════╝" -ForegroundColor Magenta

if (-not (Test-Path $CONFIG_DIR)) {
    New-Item -ItemType Directory -Path $CONFIG_DIR -Force | Out-Null
}

if (Test-Path $CONFIG_FILE) {
    Write-Host ""
    Write-Host "  Configuración existente: $CONFIG_FILE" -ForegroundColor Green
    $overwrite = Read-Host "  ¿Reconfigurar? (s/n)"
    if ($overwrite -ne "s" -and $overwrite -ne "S") { exit 0 }
}

# --- Paso 1: Proveedor de IA ---

Write-Host ""
Write-Host "── Paso 1: Proveedor de IA ──" -ForegroundColor Cyan
Write-Host ""
Write-Host "  [1] Claude API (Anthropic) - Rápido, recomendado para 8 GB RAM" -ForegroundColor White
Write-Host "  [2] Ollama (Local) - Gratis pero lento en < 16 GB RAM" -ForegroundColor White
Write-Host "  [3] Ambos (Claude primario + Ollama fallback)" -ForegroundColor White
Write-Host ""

$providerChoice = Read-Host "  Elige (1/2/3)"

$anthropicKey = ""
$useOllama = $false

switch ($providerChoice) {
    "1" {
        Write-Host "  Introduce tu API Key de Anthropic (sk-ant-...):" -ForegroundColor Yellow -NoNewline
        $anthropicKey = Read-Host " "
    }
    "2" {
        $useOllama = $true
        Write-Host "  ⚠️  Con 8 GB RAM, espera respuestas de 30-60 segundos." -ForegroundColor Yellow
    }
    "3" {
        Write-Host "  API Key de Anthropic (sk-ant-...):" -ForegroundColor Yellow -NoNewline
        $anthropicKey = Read-Host " "
        $useOllama = $true
    }
    default { 
        Write-Host "  API Key de Anthropic (sk-ant-...):" -ForegroundColor Yellow -NoNewline
        $anthropicKey = Read-Host " "
    }
}

# --- Paso 2: Telegram ---

Write-Host ""
Write-Host "── Paso 2: Telegram ──" -ForegroundColor Cyan
Write-Host "  Crear bot: Telegram → @BotFather → /newbot" -ForegroundColor Gray
Write-Host "  Obtener ID: Telegram → @userinfobot" -ForegroundColor Gray
Write-Host ""

Write-Host "  Token del bot:" -ForegroundColor Yellow -NoNewline
$telegramToken = Read-Host " "
Write-Host "  Tu ID numérico:" -ForegroundColor Yellow -NoNewline
$telegramUserId = Read-Host " "

# --- Paso 3: Generar token gateway ---

$gatewayToken = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 48 | ForEach-Object { [char]$_ })
Write-Host ""
Write-Host "  ✅ Token de gateway generado (48 caracteres)" -ForegroundColor Green

# --- Generar JSON ---

Write-Host ""
Write-Host "── Generando configuración ──" -ForegroundColor Cyan

$workspace = "C:\\Users\\$env:USERNAME\\.openclaw\\workspace"
$model = if ($anthropicKey) { "anthropic/claude-3-haiku-20240307" } else { "ollama/qwen2.5:3b" }

$config = @"
{
  "agents": {
    "defaults": {
      "workspace": "$($workspace -replace '\\','\\')",
      "model": "$model"
    },
    "list": [
      {
        "id": "main",
        "default": true,
        "model": "$model"
      }
    ]
  },
  "gateway": {
    "mode": "local",
    "auth": {
      "mode": "token",
      "token": "$gatewayToken"
    },
    "port": 18789,
    "bind": "lan",
    "http": {
      "endpoints": {
        "chatCompletions": {
          "enabled": true
        }
      }
    }
  },
"@

if ($anthropicKey) {
    $config += @"

  "env": {
    "ANTHROPIC_API_KEY": "$anthropicKey"
  },
  "models": {
    "providers": {
      "anthropic": {
        "baseUrl": "https://api.anthropic.com/v1",
        "apiKey": "$anthropicKey",
        "models": [
          {
            "id": "claude-3-haiku-20240307",
            "name": "Claude Haiku",
            "contextWindow": 200000,
            "maxTokens": 4096,
            "compat": {
              "supportsTools": true,
              "supportsDeveloperRole": false
            }
          }
        ]
      }
    }
  },
"@
}

if ($useOllama) {
    $ollamaBlock = @"

  "models": {
    "providers": {
      "ollama": {
        "baseUrl": "http://localhost:11434",
        "apiKey": "ollama-local",
        "api": "ollama",
        "models": [
          {
            "id": "qwen2.5:3b",
            "name": "Qwen 2.5 3B (Local)",
            "contextWindow": 65536,
            "maxTokens": 4096,
            "compat": { "supportsTools": true }
          }
        ]
      }
    }
  },
"@
    if (-not $anthropicKey) { $config += $ollamaBlock }
}

$config += @"

  "tools": {
    "profile": "full",
    "exec": {
      "security": "full",
      "ask": "off"
    }
  },
  "channels": {
    "telegram": {
      "enabled": true,
      "botToken": "$telegramToken",
      "dmPolicy": "pairing",
      "allowFrom": ["$telegramUserId"]
    }
  }
}
"@

$config | Set-Content -Path $CONFIG_FILE -Encoding UTF8

# Variables de entorno
if ($anthropicKey) {
    [System.Environment]::SetEnvironmentVariable("ANTHROPIC_API_KEY", $anthropicKey, "User")
    Write-Host "  ✅ ANTHROPIC_API_KEY configurada" -ForegroundColor Green
}

if ($useOllama) {
    [System.Environment]::SetEnvironmentVariable("OLLAMA_CONTEXT_LENGTH", "65536", "User")
    [System.Environment]::SetEnvironmentVariable("OLLAMA_HOST", "0.0.0.0:11434", "User")
    Write-Host "  ✅ Variables de Ollama configuradas" -ForegroundColor Green
}

Write-Host "  ✅ Configuración guardada en: $CONFIG_FILE" -ForegroundColor Green
Write-Host ""
Write-Host "╔══════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║      ✅ Configuración completada              ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "  Modelo:    $model" -ForegroundColor White
Write-Host "  Telegram:  Configurado" -ForegroundColor White
Write-Host "  Gateway:   $($gatewayToken.Substring(0,12))..." -ForegroundColor White
Write-Host ""
Write-Host "  Próximo paso: .\scripts\start.ps1" -ForegroundColor Yellow
