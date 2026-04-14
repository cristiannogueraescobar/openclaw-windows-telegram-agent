# 🔧 Solución de problemas (15 errores reales documentados)

Todos los errores listados aquí fueron **encontrados y resueltos durante una instalación real** en Windows 11 con 8 GB de RAM.

---

## Diagnóstico rápido

Ejecuta estos comandos en orden:

```powershell
openclaw gateway status          # ¿El gateway está corriendo?
openclaw logs --follow           # ¿Qué errores aparecen?
openclaw doctor --fix            # ¿Puede auto-repararse?
openclaw channels status --probe # ¿Telegram funciona?
openclaw models status --probe   # ¿El modelo responde?
```

---

## Error #1: `openclaw infer` / modelo no responde

### Síntoma

```
openclaw infer model run → no responde o da respuestas incoherentes
```

### Causa

Modelo `llama3.2:1b` no soporta tool calling (function calling). Los modelos pequeños no tienen la capacidad de usar herramientas.

### Solución

```powershell
# Cambiar a un modelo que soporte tools
openclaw config set agents.defaults.model "anthropic/claude-3-haiku-20240307"

# O si usas Ollama, mínimo Qwen 2.5 3B
openclaw config set agents.defaults.model "ollama/qwen2.5:3b"
```

---

## Error #2: `Channel is required`

### Síntoma

```
Error: Channel is required
```

Al ejecutar `openclaw message send` o `openclaw pairing list`.

### Causa

No hay canales configurados, o el comando requiere especificar el canal.

### Solución

```powershell
# Especificar el canal
openclaw pairing list --channel telegram

# Verificar que Telegram está configurado
openclaw channels list
```

Si no hay canales, añade la sección `channels.telegram` en `openclaw.json` (ver [CONFIGURATION.md](CONFIGURATION.md)).

---

## Error #3: `RPC probe: failed` / `timeout`

### Síntoma

```
Gateway: running
RPC probe: failed (timeout after 5000ms)
```

### Causa

El gateway está corriendo pero no responde a conexiones RPC. Token desincronizado o proceso corrupto.

### Solución

```powershell
# Paso 1: Reiniciar
openclaw gateway restart

# Paso 2: Si persiste, matar procesos huérfanos
Get-Process -Name "node" | Where-Object { $_.CommandLine -like "*openclaw*" } | Stop-Process -Force

# Paso 3: Reinstalar servicio
openclaw gateway uninstall
openclaw gateway install
openclaw gateway start

# Paso 4: Sincronizar tokens
openclaw doctor --fix
```

---

## Error #4: `Pairing required`

### Síntoma

```
Error: Pairing required
```

Al usar la TUI o enviar mensajes.

### Causa

El dispositivo (TUI, CLI, Telegram) no ha sido aprobado.

### Solución

```powershell
# Ver dispositivos pendientes
openclaw devices list

# Aprobar dispositivo específico
openclaw devices approve ID_DEL_DISPOSITIVO

# Auto-reparar
openclaw doctor --fix
```

---

## Error #5: `Missing API key for provider anthropic`

### Síntoma

```
Error: Missing API key for provider anthropic
```

### Causa

La clave API no está en la ubicación correcta del JSON.

### Solución

La clave debe estar en **DOS lugares** del JSON para funcionar en todos los contextos:

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
# O re-ejecutar el onboarding
openclaw onboard
```

> **Error común**: Poner la clave solo en `env` o solo en `models.providers`. Ponla en ambos sitios.

---

## Error #6: `invalid x-api-key`

### Síntoma

```
Error: 401 invalid x-api-key
```

### Causa

La clave API de Anthropic es inválida, expirada o fue revocada.

### Solución

1. Ve a [console.anthropic.com/settings/keys](https://console.anthropic.com/settings/keys)
2. Revoca la clave antigua
3. Crea una nueva
4. Actualiza en `openclaw.json` (ambas ubicaciones)
5. `openclaw gateway restart`

---

## Error #7: `Model context window too small (8192). Minimum is 16000`

### Síntoma

```
Error: Model context window too small (8192 tokens). Minimum is 16000.
```

### Causa

Los modelos `llama3.2:1b` y `llama3.2:3b` tienen contexto de 8192, por debajo del mínimo de 16000 que exige OpenClaw. Ollama también reporta 4096 por defecto para algunos modelos.

### Solución

```powershell
# Opción 1: Usar Claude API (tiene 200K de contexto)
openclaw config set agents.defaults.model "anthropic/claude-3-haiku-20240307"

# Opción 2: Aumentar contexto de Ollama y usar modelo compatible
[Environment]::SetEnvironmentVariable('OLLAMA_CONTEXT_LENGTH', '65536', [EnvironmentVariableTarget]::User)
$env:OLLAMA_CONTEXT_LENGTH = "65536"
# Reiniciar Ollama y usar qwen2.5:3b o superior
```

### Modelos que NO funcionan (probado)

| Modelo | Contexto real | ¿Sirve? |
|---|---|---|
| `llama3.2:1b` | 8192 | ❌ |
| `llama3.2:3b` | 8192 | ❌ |
| `qwen2.5:3b` (con OLLAMA_CONTEXT_LENGTH=65536) | 65536 | ✅ (lento) |
| Claude Haiku | 200000 | ✅ (rápido) |

---

## Error #8: `Profile ollama:default timed out`

### Síntoma

```
Error: Profile ollama:default timed out after 60000ms
```

### Causa

Ollama tarda demasiado en generar respuestas. En 8 GB RAM, los modelos tardan 30-60+ segundos.

### Solución

```powershell
# Opción 1: Aumentar timeout (si insistes en Ollama local)
# En openclaw.json, dentro del provider ollama:
# "idleTimeoutSeconds": 180

# Opción 2: Pre-cargar el modelo antes de usar OpenClaw
ollama run qwen2.5:3b
# Esperar a que cargue (verás >>>), luego Ctrl+C
openclaw gateway restart

# Opción 3 (recomendada): Cambiar a Claude API
openclaw config set agents.defaults.model "anthropic/claude-3-haiku-20240307"
```

---

## Error #9: `IndentationError` en scripts Python generados

### Síntoma

```
IndentationError: unexpected indent
```

Al ejecutar código Python generado por el agente.

### Causa

El agente de IA a veces genera código Python con indentación inconsistente (mezcla tabs y espacios).

### Solución

```powershell
# Pedir al agente que reescriba el archivo
# Desde Telegram: "Reescribe el archivo X.py corrigiendo la indentación"

# O corregir manualmente
py -3.11 -c "import py_compile; py_compile.compile('archivo.py')"
```

---

## Error #10: `mkdir` no acepta múltiples argumentos

### Síntoma

```
mkdir : A positional parameter cannot be found that accepts argument 'carpeta2'.
```

### Causa

PowerShell (`mkdir`) no acepta múltiples argumentos como bash.

### Solución

```powershell
# ❌ Esto falla en PowerShell
mkdir carpeta1 carpeta2 carpeta3

# ✅ Crear uno por uno
mkdir carpeta1
mkdir carpeta2
mkdir carpeta3

# ✅ O con bucle
"carpeta1","carpeta2","carpeta3" | ForEach-Object { mkdir $_ -Force }
```

> Cuando el agente genere comandos, puede cometer este error. Simplemente pídele que los ejecute uno por uno.

---

## Error #11: `Port already in use` (EADDRINUSE)

### Síntoma

```
Error: listen EADDRINUSE: address already in use :::18789
```

### Causa

Un proceso huérfano de OpenClaw (u otro programa) está usando el puerto 18789.

### Solución

```powershell
# Encontrar el proceso
netstat -ano | findstr :18789

# Matar por PID
taskkill /PID <PID> /F

# Si no sabes el PID, matar todos los node de OpenClaw
Get-Process -Name "node" -ErrorAction SilentlyContinue | Stop-Process -Force

# Reiniciar
openclaw gateway start
```

---

## Error #12: `Unauthorized` en API HTTP

### Síntoma

```
HTTP 401 Unauthorized
```

### Causa

Falta el header `Authorization` o el token Bearer es incorrecto.

### Solución

```powershell
# Ver el token correcto
openclaw config get gateway.auth.token

# Usar así (PowerShell):
$headers = @{ "Authorization" = "Bearer TU_TOKEN_AQUI" }
Invoke-RestMethod -Uri "http://127.0.0.1:18789/v1/chat/completions" `
    -Method POST -Headers $headers `
    -ContentType "application/json" `
    -Body '{"model":"openclaw/main","messages":[{"role":"user","content":"Hola"}]}'
```

> **Error común**: Olvidar la palabra `Bearer` antes del token.

---

## Error #13: Telegram bot no responde

### Síntoma

Envías mensajes al bot en Telegram pero no hay respuesta.

### Causa

Webhook conflictivo de una configuración anterior.

### Solución

```powershell
# Limpiar webhook
$token = "TU_BOT_TOKEN_DE_TELEGRAM"
Invoke-RestMethod -Uri "https://api.telegram.org/bot$token/deleteWebhook" -Method POST

# Verificar
Invoke-RestMethod -Uri "https://api.telegram.org/bot$token/getWebhookInfo"
# url debe estar vacío: ""

# Reiniciar gateway
openclaw gateway restart
```

---

## Error #14: `No pending pairing request found`

### Síntoma

```
Error: No pending pairing request found for channel telegram
```

### Causa

El código de pairing expiró (duran 1 hora) o nunca se generó.

### Solución

1. Abre Telegram → envía `/start` a tu bot
2. Vuelve a PowerShell **inmediatamente**:

```powershell
openclaw pairing list --channel telegram
openclaw pairing approve telegram CODIGO
```

> **Tip**: Los códigos expiran en 1 hora, pero apruébalos lo antes posible para evitar problemas.

---

## Error #15: Claude se niega a ejecutar comandos

### Síntoma

Pides "ejecuta ipconfig" y el bot responde explicando qué es ipconfig en vez de ejecutarlo.

### Causa

`tools.profile` no está en `"full"` o `"coding"`. Sin el perfil correcto, el agente no tiene acceso a herramientas de ejecución.

### Solución

```powershell
# Verificar perfil actual
openclaw config get tools.profile

# Cambiar a full
openclaw config set tools.profile "full"

# Reiniciar
openclaw gateway restart
```

En `openclaw.json`, debe verse así:

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

## Tabla resumen rápida

| # | Error | Solución rápida |
|---|---|---|
| 1 | Modelo no responde | Cambiar a Claude API o Qwen 3B+ |
| 2 | Channel is required | Añadir `--channel telegram` |
| 3 | RPC probe: failed | `openclaw gateway restart` + `doctor --fix` |
| 4 | Pairing required | `openclaw devices approve ID` |
| 5 | Missing API key | Poner clave en `env` Y en `models.providers` |
| 6 | invalid x-api-key | Regenerar en console.anthropic.com |
| 7 | Context window too small | Usar Claude API o OLLAMA_CONTEXT_LENGTH=65536 |
| 8 | Profile timed out | Pre-cargar modelo o cambiar a Claude API |
| 9 | IndentationError Python | Pedir al agente que reescriba el código |
| 10 | mkdir múltiples args | Crear directorios uno por uno |
| 11 | Port already in use | `taskkill /PID X /F` |
| 12 | Unauthorized API | Verificar Bearer token |
| 13 | Telegram no responde | `deleteWebhook` + restart gateway |
| 14 | No pending pairing | `/start` en Telegram + aprobar rápido |
| 15 | Claude no ejecuta | `tools.profile = "full"` |

---

## ¿Problema no listado?

```powershell
openclaw logs --follow --level debug
openclaw doctor --fix
```

Consulta issues en GitHub: [github.com/openclaw/openclaw/issues](https://github.com/openclaw/openclaw/issues)
