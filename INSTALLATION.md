# 📦 Guía de instalación paso a paso

Esta guía está basada en una **instalación real exitosa** en Windows 11 25H2 con 8 GB de RAM. Todas las versiones y comandos fueron probados y verificados.

---

## Programas que vamos a instalar

| Programa | Versión probada | Obligatorio | Método |
|---|---|---|---|
| Node.js | v24.14.1 | ✅ Sí | winget |
| npm | 11.11.0 | ✅ Sí | Incluido con Node.js |
| Git | Última | ✅ Sí | winget |
| OpenClaw | 2026.4.11 (769908e) | ✅ Sí | Script oficial |
| Ollama | 0.20.6 | ❌ Opcional | winget |
| Docker Desktop | 29.3.1 | ❌ Opcional | winget |
| Python | 3.11 | ❌ Opcional | winget |
| PM2 | Última | ❌ Opcional | npm |
| WSL2 + Ubuntu | Última | ❌ Opcional | wsl --install |

---

## Paso 1: Instalar Node.js

OpenClaw requiere **Node.js v22.14 o superior** (probamos con v24.14.1).

```powershell
winget install OpenJS.NodeJS.LTS
```

Verificar:

```powershell
node --version
# Esperado: v24.14.1 o superior

npm --version
# Esperado: 11.11.0 o superior
```

> **Si `node` no se reconoce tras instalar**: Cierra y reabre PowerShell. Si persiste, añade el directorio de npm al PATH:
> ```powershell
> $npmPath = (npm config get prefix)
> [System.Environment]::SetEnvironmentVariable("PATH", "$env:PATH;$npmPath", "User")
> ```

---

## Paso 2: Instalar Git

```powershell
winget install Git.Git
```

Verificar:

```powershell
git --version
```

---

## Paso 3: Instalar OpenClaw

### Método recomendado (script oficial)

```powershell
iwr -useb https://openclaw.ai/install.ps1 | iex
```

Este script instala OpenClaw globalmente y ejecuta el asistente de configuración (`openclaw onboard`).

### Método alternativo (npm directo)

```powershell
npm install -g openclaw@latest
openclaw onboard --install-daemon
```

Verificar:

```powershell
openclaw --version
# Esperado: 2026.4.11 o superior
```

---

## Paso 4: Instalar Ollama (opcional — solo si quieres IA local)

> ⚠️ **Advertencia basada en experiencia real**: Con 8 GB de RAM, Ollama es extremadamente lento. Los modelos que funcionan (qwen2.5:3b) tardan 30-60 segundos por respuesta y causan timeout frecuente. **Si tienes 8 GB RAM, salta este paso y usa Claude API.**

```powershell
winget install Ollama.Ollama
```

### Descargar modelos

```powershell
# Para 8 GB RAM (funciona pero lento)
ollama pull qwen2.5:3b

# Para 16 GB RAM
ollama pull qwen2.5:7b

# Para 24+ GB RAM (mejor experiencia)
ollama pull qwen2.5:32b
```

### Configurar contexto extendido (OBLIGATORIO)

OpenClaw requiere mínimo 16K de contexto. Ollama usa 4K por defecto.

```powershell
# Variable de entorno permanente
[Environment]::SetEnvironmentVariable('OLLAMA_CONTEXT_LENGTH', '65536', [EnvironmentVariableTarget]::User)

# Variable de entorno para la sesión actual
$env:OLLAMA_CONTEXT_LENGTH = "65536"
```

### Configurar acceso en red (si usas Docker/WSL2)

```powershell
[Environment]::SetEnvironmentVariable('OLLAMA_HOST', '0.0.0.0:11434', [EnvironmentVariableTarget]::User)
$env:OLLAMA_HOST = "0.0.0.0:11434"
```

### Modelos probados — resultado real

| Modelo | Tamaño | ¿Funciona en 8 GB RAM? | Notas |
|---|---|---|---|
| `llama3.2:1b` | 1.3 GB | ❌ No | Contexto 8192 < 16000 mínimo |
| `llama3.2:3b` | 2.0 GB | ❌ No | Contexto insuficiente |
| `qwen2.5:3b` | 1.9 GB | ⚠️ Lento (30-60s) | Funciona con timeout 180s |
| `qwen2.5:7b` | 4.7 GB | ❌ Timeout constante | No hay RAM suficiente para Windows + modelo |
| `qwen3:4b` | 2.5 GB | ⚠️ Lento | Similar a qwen2.5:3b |

---

## Paso 5: Instalar Docker Desktop (opcional)

Solo necesario para sandboxing o si quieres Open WebUI.

```powershell
winget install Docker.DockerDesktop
```

Reiniciar el PC. Verificar:

```powershell
docker --version
# Esperado: Docker version 29.3.1 o superior
```

### Instalar Open WebUI (interfaz web para Ollama)

```powershell
docker run -d --net=host -v open-webui:/app/backend/data ghcr.io/open-webui/open-webui:main
```

Acceder en: `http://localhost:8080`

---

## Paso 6: Instalar WSL2 (opcional)

```powershell
wsl --install -d Ubuntu
```

### Limitar RAM de WSL2 (IMPORTANTE con 8 GB)

Crear archivo `C:\Users\TU_USUARIO\.wslconfig`:

```ini
[wsl2]
memory=3GB
processors=2
swap=2GB
```

```powershell
# Crear el archivo
@"
[wsl2]
memory=3GB
processors=2
swap=2GB
"@ | Out-File -FilePath "$env:USERPROFILE\.wslconfig" -Encoding utf8

# Reiniciar WSL para aplicar
wsl --shutdown
```

---

## Paso 7: Crear el bot de Telegram

### 7.1 Crear el bot con BotFather

1. Abre Telegram → busca **@BotFather**
2. Envía `/newbot`
3. Elige un nombre (ejemplo: "Mi PC Agent")
4. Elige un username que termine en `bot` (ejemplo: `mi_pc_agent_bot`)
5. **Guarda el token** (formato: `1234567890:ABCdefGHIjklMNOpqrsTUVwxyz`)

### 7.2 Obtener tu ID numérico

1. Busca **@userinfobot** en Telegram
2. Envíale cualquier mensaje
3. **Guarda tu ID numérico** (ejemplo: `123456789`)

---

## Paso 8: Obtener API Key de Anthropic

> Si solo usas Ollama, puedes saltar este paso. Pero con 8 GB RAM, **Claude API es prácticamente obligatorio**.

1. Ve a [https://console.anthropic.com](https://console.anthropic.com)
2. Crea cuenta → ve a **Settings → API Keys**
3. Clic en **Create Key** → copia la clave (empieza por `sk-ant-...`)
4. **Guarda la clave** — solo se muestra una vez

---

## Paso 9: Configurar OpenClaw

### Opción A: Usar el script de configuración

```powershell
.\scripts\configure.ps1
```

### Opción B: Configuración manual

```powershell
# Copiar configuración de ejemplo
Copy-Item ".\config\openclaw.json.example" "$env:USERPROFILE\.openclaw\openclaw.json"

# Editar
notepad "$env:USERPROFILE\.openclaw\openclaw.json"
```

Reemplaza los placeholders:

| Placeholder | Tu valor real |
|---|---|
| `TU_API_KEY_DE_ANTHROPIC` | Tu clave `sk-ant-...` |
| `TU_BOT_TOKEN_DE_TELEGRAM` | El token de BotFather |
| `TU_ID_NUMERICO_TELEGRAM` | Tu ID de @userinfobot |

### Opción C: Usar onboarding interactivo

```powershell
openclaw onboard
```

> 📖 Ver **[CONFIGURATION.md](CONFIGURATION.md)** para el JSON completo que funciona.

---

## Paso 10: Instalar y arrancar el gateway

```powershell
openclaw gateway install
openclaw gateway start
```

Verificar:

```powershell
openclaw gateway status
# Esperado: Gateway: running, Port: 18789
```

---

## Paso 11: Parear tu cuenta de Telegram

1. Envía cualquier mensaje a tu bot en Telegram
2. El bot mostrará un código de pairing
3. En PowerShell:

```powershell
openclaw pairing list --channel telegram
openclaw pairing approve telegram CODIGO
```

> Los códigos expiran en 1 hora. Si expira, envía `/start` al bot para generar uno nuevo.

---

## Paso 12: Verificar que todo funciona

```powershell
# Test rápido
openclaw message send --target main --message "Di hola"

# Test desde Telegram
# Envía: "Dime la fecha y hora actual de mi PC"

# Diagnóstico completo
openclaw doctor
openclaw status --deep
```

---

## Dependencias adicionales (opcionales)

```powershell
# Python y librerías
winget install Python.Python.3.11
py -3.11 -m pip install requests fastapi uvicorn

# PM2 para gestión de procesos
npm install -g pm2

# n8n para workflows de automatización
npm install -g n8n
```

---

## Siguiente paso

Lee **[CONFIGURATION.md](CONFIGURATION.md)** para entender el JSON de configuración completo.

Si algo falla, consulta **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** con los 15 errores documentados y sus soluciones.
