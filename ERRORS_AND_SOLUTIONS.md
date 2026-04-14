# ❌ Tabla completa de errores y soluciones

Referencia rápida de todos los errores encontrados durante la configuración real del sistema.

---

## Tabla de errores

| # | Error | Causa | Solución |
|---|---|---|---|
| 1 | `openclaw infer` no responde | Modelo llama3.2:1b sin tool calling | Cambiar a Qwen 3B+ o Claude API |
| 2 | `Channel is required` | No hay canales configurados | Configurar Telegram como canal en openclaw.json |
| 3 | `RPC probe: failed` / `timeout` | Gateway no responde o token desincronizado | `openclaw gateway restart` o matar procesos con `taskkill` |
| 4 | `Pairing required` en TUI | Dispositivo no aprobado | `openclaw devices list` → `openclaw devices approve ID` |
| 5 | `Missing API key for provider anthropic` | Clave mal ubicada en JSON | Poner clave en `env` Y en `models.providers.anthropic.apiKey` |
| 6 | `invalid x-api-key` | Clave expirada o incorrecta | Regenerar en [console.anthropic.com](https://console.anthropic.com) |
| 7 | `Model context window too small (8192)` | Modelo 1B/3B con contexto < 16000 | Usar Claude API o OLLAMA_CONTEXT_LENGTH=65536 |
| 8 | `Profile ollama:default timed out` | Modelo tarda >60s en responder | Aumentar timeout a 180s o cambiar a Claude API |
| 9 | `IndentationError` en scripts Python | Código generado con indentación inconsistente | Pedir al agente que reescriba el archivo |
| 10 | `mkdir` no acepta múltiples argumentos | Limitación de PowerShell vs bash | Crear directorios uno por uno |
| 11 | `Port already in use` (EADDRINUSE) | Proceso huérfano en puerto 18789 | `netstat -ano \| findstr :18789` → `taskkill /PID X /F` |
| 12 | `Unauthorized` en API HTTP | Falta token Bearer o es incorrecto | Verificar con `openclaw config get gateway.auth.token` |
| 13 | Bot de Telegram no responde | Webhook conflictivo de configuración anterior | `deleteWebhook` via API de Telegram + restart gateway |
| 14 | `No pending pairing request found` | Código de pairing expirado | Enviar `/start` al bot → aprobar código nuevo rápidamente |
| 15 | Claude se niega a ejecutar comandos | `tools.profile` no está en "full" | `openclaw config set tools.profile "full"` + restart |

---

## Soluciones detalladas (comandos listos para copiar)

### Error #1 — Modelo no responde

```powershell
openclaw config set agents.defaults.model "anthropic/claude-3-haiku-20240307"
openclaw gateway restart
```

### Error #2 — Channel is required

```powershell
openclaw pairing list --channel telegram
```

### Error #3 — RPC probe failed

```powershell
openclaw doctor --fix
openclaw gateway restart
# Si persiste:
openclaw gateway uninstall
openclaw gateway install
openclaw gateway start
```

### Error #4 — Pairing required

```powershell
openclaw devices list
openclaw devices approve ID_DISPOSITIVO
# O auto-reparar:
openclaw doctor --fix
```

### Error #5 — Missing API key

Editar `openclaw.json` y poner la clave en ambos lugares:

```json
{
  "env": {
    "ANTHROPIC_API_KEY": "sk-ant-tu-clave"
  },
  "models": {
    "providers": {
      "anthropic": {
        "apiKey": "sk-ant-tu-clave"
      }
    }
  }
}
```

```powershell
openclaw gateway restart
```

### Error #6 — invalid x-api-key

1. Ir a [console.anthropic.com/settings/keys](https://console.anthropic.com/settings/keys)
2. Revocar clave antigua → crear nueva
3. Actualizar en `openclaw.json` (ambas ubicaciones)
4. `openclaw gateway restart`

### Error #7 — Context window too small

```powershell
# Para Ollama
[Environment]::SetEnvironmentVariable('OLLAMA_CONTEXT_LENGTH', '65536', [EnvironmentVariableTarget]::User)
$env:OLLAMA_CONTEXT_LENGTH = "65536"
# Reiniciar Ollama y gateway

# O cambiar a Claude API
openclaw config set agents.defaults.model "anthropic/claude-3-haiku-20240307"
openclaw gateway restart
```

### Error #8 — Profile timed out

```powershell
# Pre-cargar modelo
ollama run qwen2.5:3b
# Esperar carga, luego Ctrl+C

# O cambiar a Claude
openclaw config set agents.defaults.model "anthropic/claude-3-haiku-20240307"
openclaw gateway restart
```

### Error #9 — IndentationError Python

```
Desde Telegram: "Reescribe el archivo script.py corrigiendo toda la indentación"
```

### Error #10 — mkdir múltiples argumentos

```powershell
# En vez de: mkdir a b c
# Usar:
"a","b","c" | ForEach-Object { mkdir $_ -Force }
```

### Error #11 — Port already in use

```powershell
netstat -ano | findstr :18789
taskkill /PID <PID> /F
openclaw gateway start
```

### Error #12 — Unauthorized API

```powershell
# Obtener token correcto
openclaw config get gateway.auth.token

# Usar en peticiones
$headers = @{ "Authorization" = "Bearer EL_TOKEN_CORRECTO" }
```

### Error #13 — Telegram no responde

```powershell
$token = "TU_BOT_TOKEN"
Invoke-RestMethod -Uri "https://api.telegram.org/bot$token/deleteWebhook" -Method POST
openclaw gateway restart
```

### Error #14 — No pending pairing

1. En Telegram: enviar `/start` al bot
2. En PowerShell (rápidamente):

```powershell
openclaw pairing list --channel telegram
openclaw pairing approve telegram CODIGO
```

### Error #15 — Claude no ejecuta comandos

```powershell
openclaw config set tools.profile "full"
openclaw gateway restart
```

Verificar que `openclaw.json` tiene:

```json
{
  "tools": {
    "profile": "full",
    "exec": {
      "security": "full",
      "ask": "off"
    }
  }
}
```

---

## Flujo de diagnóstico general

Si ningún error de la lista aplica, sigue este flujo:

```
¿El gateway está corriendo?
  └─ NO → openclaw gateway start
  └─ SÍ → ¿RPC probe funciona?
              └─ NO → openclaw doctor --fix → restart
              └─ SÍ → ¿El canal responde?
                        └─ NO → deleteWebhook + restart
                        └─ SÍ → ¿El modelo responde?
                                  └─ NO → Cambiar a Claude API
                                  └─ SÍ → ¿tools.profile = "full"?
                                            └─ NO → Cambiar a "full"
                                            └─ SÍ → openclaw logs --follow
```
