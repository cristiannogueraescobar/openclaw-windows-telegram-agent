# 📝 Lecciones aprendidas

Todo lo que aprendimos configurando OpenClaw en un PC real con Windows 11 y 8 GB de RAM. Esta guía te ahorrará horas de prueba y error.

---

## Sobre el hardware

### 8 GB de RAM no es suficiente para Ollama

Esta fue la lección más importante y dolorosa. Con 8 GB de RAM:

- **Windows 11 consume ~3.5 GB** en reposo
- **Ollama necesita ~2-5 GB** dependiendo del modelo
- **OpenClaw (Node.js) consume ~300-500 MB**
- **No queda RAM** para que el modelo procese con velocidad razonable

**Resultado**: Timeout constante, respuestas de 30-60 segundos (cuando no falla), sistema general lento.

**Solución**: Usar **Claude API** como proveedor principal. Es rápido (1-3 segundos), barato (Haiku) y no consume RAM local.

### WSL2 debe limitarse

Si instalas WSL2 en un PC con 8 GB, por defecto reserva el 50% de la RAM (4 GB). Esto deja solo 4 GB para Windows + OpenClaw + todo lo demás.

**Crear `~/.wslconfig`**:

```ini
[wsl2]
memory=3GB
processors=2
swap=2GB
```

### Si insistes en Ollama local con 8 GB

El único modelo que funcionó (con mucha paciencia):

- **`qwen2.5:3b`** — 1.9 GB, contexto 65536 (con variable de entorno), 30-60s por respuesta
- Aumentar `idleTimeoutSeconds` a **180** en la configuración del provider
- Pre-cargar el modelo antes de usar OpenClaw: `ollama run qwen2.5:3b`, esperar carga, Ctrl+C
- Cerrar absolutamente todo lo que no sea esencial

---

## Sobre la configuración de OpenClaw

### La API key debe estar en DOS lugares

Este error nos costó bastante tiempo. La API key de Anthropic debe configurarse en:

1. `env.ANTHROPIC_API_KEY` — para que OpenClaw la pase al proceso
2. `models.providers.anthropic.apiKey` — para que el provider la use directamente

Si solo la pones en uno de los dos sitios, ciertos flujos fallan con "Missing API key".

### `tools.profile = "full"` es no negociable

Si quieres que el agente haga ALGO útil (ejecutar comandos, crear archivos, etc.), el perfil **debe** ser `"full"`. Con `"minimal"` o `"messaging"`, Claude solo puede chatear pero no actuar.

Nos pasó que Claude "se negaba" a ejecutar comandos. No era un problema del modelo — era que no tenía herramientas disponibles.

### `tools.exec.security = "full"` y `ask = "off"`

Para control remoto sin fricción:

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

Con `ask: "on"`, el agente pide confirmación antes de cada comando. Desde Telegram esto es impracticable.

### La baseUrl de Ollama NO lleva `/v1`

```
❌ "baseUrl": "http://localhost:11434/v1"    → ROMPE tool calling
✅ "baseUrl": "http://localhost:11434"        → Funciona
```

OpenClaw usa la API nativa de Ollama (`/api/chat`), no la compatible con OpenAI.

### `compat.supportsTools: true` es necesario

En la definición del modelo, hay que indicar explícitamente que soporta herramientas:

```json
{
  "compat": {
    "supportsTools": true,
    "supportsDeveloperRole": false
  }
}
```

Sin esto, el agente chatea pero no ejecuta acciones.

---

## Sobre Telegram

### Los códigos de pairing expiran rápido

El flujo de pairing tiene que ser así:

1. Envía `/start` al bot en Telegram
2. **Inmediatamente** ve a PowerShell
3. `openclaw pairing list --channel telegram`
4. `openclaw pairing approve telegram CODIGO`

Si tardas demasiado, el código expira y tienes que empezar de nuevo.

### Limpiar webhooks antes de empezar

Si el bot fue usado antes con otro servicio (o si cambias de webhook a long polling), hay que limpiar:

```powershell
$token = "TU_BOT_TOKEN"
Invoke-RestMethod -Uri "https://api.telegram.org/bot$token/deleteWebhook" -Method POST
```

### Los grupos necesitan @mención

En grupos de Telegram, el bot necesita ser mencionado (`@mi_bot haz algo`). Esto se configura con:

```json
{
  "groups": {
    "*": { "requireMention": true }
  }
}
```

---

## Sobre los modelos de Ollama

### Tabla final de compatibilidad (8 GB RAM)

| Modelo | Contexto | Tool Calling | Velocidad | Veredicto |
|---|---|---|---|---|
| `llama3.2:1b` | 8K | ❌ | Rápido pero inútil | ❌ No usar |
| `llama3.2:3b` | 8K | ❌ | OK | ❌ No usar |
| `qwen2.5:3b` | 65K* | ✅ | 30-60s | ⚠️ Funciona con paciencia |
| `qwen2.5:7b` | 65K* | ✅ | Timeout | ❌ No viable en 8 GB |
| `qwen3:4b` | 65K* | ✅ | 30-60s | ⚠️ Similar a qwen2.5:3b |

*Con `OLLAMA_CONTEXT_LENGTH=65536`

### El contexto mínimo es 16K — y Ollama reporta 4K por defecto

OpenClaw rechaza modelos con menos de 16000 tokens de contexto. Ollama, por defecto, reporta 4096 para la mayoría de modelos. Debes forzar el contexto con la variable de entorno:

```powershell
[Environment]::SetEnvironmentVariable('OLLAMA_CONTEXT_LENGTH', '65536', [EnvironmentVariableTarget]::User)
```

---

## Sobre PowerShell

### `mkdir` no acepta múltiples argumentos

```powershell
# ❌ Esto falla
mkdir carpeta1 carpeta2 carpeta3

# ✅ Esto funciona
"carpeta1","carpeta2","carpeta3" | ForEach-Object { mkdir $_ -Force }
```

Cuando el agente genera scripts, a veces asume sintaxis de bash. Hay que corregir manualmente o pedirle que ajuste para PowerShell.

### `py -3.11` en vez de `python`

En Windows, si instalas Python via winget, el comando es `py -3.11`, no `python` ni `python3`:

```powershell
py -3.11 -m pip install requests
py -3.11 script.py
```

---

## Sobre el flujo general

### El orden correcto de arranque es

1. **Ollama** (si lo usas): `ollama serve` → esperar a que esté listo
2. **OpenClaw gateway**: `openclaw gateway start`
3. **Verificar**: `openclaw gateway status`
4. **Telegram**: Enviar mensaje al bot → parear si es necesario

### Siempre reiniciar el gateway después de cambiar la configuración

```powershell
openclaw gateway restart
```

Los cambios en `openclaw.json` no se aplican automáticamente (excepto algunos que soportan hot-reload).

### `openclaw doctor --fix` es tu mejor amigo

Ante cualquier problema, ejecuta:

```powershell
openclaw doctor --fix
```

Esto valida la configuración, sincroniza tokens, repara permisos y detecta problemas comunes.

---

## Lo que haríamos diferente la próxima vez

1. **Empezar con Claude API directamente** — no perder tiempo con Ollama en 8 GB
2. **Configurar `tools.profile = "full"` desde el principio** — evita el error "Claude no ejecuta"
3. **Poner la API key en ambos lugares** — `env` y `models.providers`
4. **Crear `.wslconfig` antes de instalar WSL2** — previene la saturación de RAM
5. **Limpiar webhooks de Telegram antes de configurar** — evita el error de bot que no responde
6. **Usar `openclaw onboard`** — en vez de configurar manualmente el JSON (menos errores)
