# ⚙️ Configuración detallada

Toda la configuración de OpenClaw se gestiona desde `~/.openclaw/openclaw.json` (formato JSON5).

En Windows: `C:\Users\TU_USUARIO\.openclaw\openclaw.json`

---

## Configuración FINAL que funciona (probada en el mundo real)

Este es el JSON **real** que usamos en nuestra instalación con Windows 11 + 8 GB RAM + Claude API:

```json
{
  "agents": {
    "defaults": {
      "workspace": "C:\\Users\\TU_USUARIO\\.openclaw\\workspace",
      "model": "anthropic/claude-3-haiku-20240307"
    },
    "list": [
      {
        "id": "main",
        "default": true,
        "model": "anthropic/claude-3-haiku-20240307"
      }
    ]
  },
  "gateway": {
    "mode": "local",
    "auth": {
      "mode": "token",
      "token": "TU_TOKEN_GATEWAY_SEGURO"
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
  "env": {
    "ANTHROPIC_API_KEY": "TU_API_KEY_DE_ANTHROPIC"
  },
  "models": {
    "providers": {
      "anthropic": {
        "baseUrl": "https://api.anthropic.com/v1",
        "apiKey": "TU_API_KEY_DE_ANTHROPIC",
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
      "botToken": "TU_BOT_TOKEN_DE_TELEGRAM",
      "dmPolicy": "pairing",
      "allowFrom": ["TU_ID_NUMERICO_TELEGRAM"]
    }
  }
}
```

> **IMPORTANTE**: Reemplaza todos los valores `TU_...` con tus datos reales.

---

## Explicación sección por sección

### Sección `agents` — El agente de IA

```json
{
  "agents": {
    "defaults": {
      "workspace": "C:\\Users\\TU_USUARIO\\.openclaw\\workspace",
      "model": "anthropic/claude-3-haiku-20240307"
    },
    "list": [
      {
        "id": "main",
        "default": true,
        "model": "anthropic/claude-3-haiku-20240307"
      }
    ]
  }
}
```

| Campo | Valor | Explicación |
|---|---|---|
| `workspace` | Ruta absoluta Windows | Directorio de trabajo del agente |
| `model` | `anthropic/claude-3-haiku-20240307` | Modelo por defecto — Haiku es rápido y barato |
| `list[].id` | `"main"` | Identificador del agente principal |
| `list[].default` | `true` | Este agente recibe los mensajes por defecto |

#### Modelos recomendados

| Modelo | Velocidad | Costo | Mejor para |
|---|---|---|---|
| `claude-3-haiku-20240307` | ⚡ Muy rápido | 💰 Barato | Uso diario, comandos simples |
| `claude-sonnet-4-5-20250514` | 🚀 Rápido | 💰💰 Medio | Tareas complejas, análisis |
| `claude-opus-4-20250514` | 🐢 Más lento | 💰💰💰 Caro | Máxima calidad |

---

### Sección `gateway` — Servidor central

```json
{
  "gateway": {
    "mode": "local",
    "auth": {
      "mode": "token",
      "token": "TU_TOKEN_GATEWAY_SEGURO"
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
  }
}
```

| Campo | Valor probado | Explicación |
|---|---|---|
| `mode` | `"local"` | El gateway corre en tu PC |
| `auth.token` | String largo aleatorio | Genera con `openclaw doctor --generate-gateway-token` |
| `port` | `18789` | Puerto por defecto de OpenClaw |
| `bind` | `"lan"` | Accesible desde la red local. Usa `"loopback"` para solo localhost |
| `http.endpoints.chatCompletions.enabled` | `true` | Habilita la API HTTP compatible OpenAI |

---

### Sección `env` — Variables de entorno

```json
{
  "env": {
    "ANTHROPIC_API_KEY": "sk-ant-..."
  }
}
```

Aquí puedes poner cualquier variable de entorno que OpenClaw necesite. Es **una de las formas** de configurar la API key (la otra es en `models.providers.anthropic.apiKey`).

> ⚠️ **Lección aprendida**: La API key debe estar **tanto** en `env.ANTHROPIC_API_KEY` **como** en `models.providers.anthropic.apiKey` para que funcione en todos los contextos. Si solo la pones en uno, ciertos flujos fallan con "Missing API key".

---

### Sección `models` — Proveedores de IA

#### Con Claude API (configuración probada):

```json
{
  "models": {
    "providers": {
      "anthropic": {
        "baseUrl": "https://api.anthropic.com/v1",
        "apiKey": "sk-ant-...",
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
  }
}
```

> **Nota**: `compat.supportsTools: true` es necesario para que el agente pueda ejecutar comandos y manejar archivos. Sin esto, Claude solo chatea pero no actúa.

#### Con Ollama (si tienes suficiente RAM):

```json
{
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
            "compat": {
              "supportsTools": true
            }
          }
        ]
      }
    }
  }
}
```

> ⚠️ **NUNCA** uses `"baseUrl": "http://localhost:11434/v1"` — OpenClaw usa la API nativa de Ollama (`/api/chat`), no la compatible con OpenAI. Añadir `/v1` rompe las herramientas.

---

### Sección `tools` — CRÍTICA para control del PC

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

| Campo | Valor | Efecto |
|---|---|---|
| `profile` | `"full"` | **OBLIGATORIO** para control total del PC |
| `exec.security` | `"full"` | Permite ejecución sin restricciones |
| `exec.ask` | `"off"` | No pide confirmación antes de ejecutar |

#### Los 4 perfiles de herramientas

| Perfil | Herramientas | Resultado |
|---|---|---|
| `"minimal"` | Solo `session_status` | El bot solo puede chatear, no hace nada |
| `"coding"` | Archivos, ejecución, sesiones | Puede programar y ejecutar código |
| `"messaging"` | Mensajería, sesiones | Solo envía/recibe mensajes |
| `"full"` | **Todas sin restricción** | **Control total del PC** |

> ⚠️ **Error #15**: Si Claude "se niega a ejecutar comandos" y solo te explica qué haría, el problema es que `tools.profile` NO está en `"full"`. Este fue uno de los errores más frustrantes y tiene una solución simple.

---

### Sección `channels` — Telegram

```json
{
  "channels": {
    "telegram": {
      "enabled": true,
      "botToken": "1234567890:ABCdefGHIjklMNOpqrsTUVwxyz",
      "dmPolicy": "pairing",
      "allowFrom": ["123456789"]
    }
  }
}
```

| Campo | Valor | Explicación |
|---|---|---|
| `botToken` | Token de @BotFather | El token completo del bot |
| `dmPolicy` | `"pairing"` | Nuevos usuarios necesitan aprobación |
| `allowFrom` | Array de IDs | Tu ID numérico de Telegram |

---

## Variables de entorno del sistema

```powershell
# API Key de Anthropic
[Environment]::SetEnvironmentVariable('ANTHROPIC_API_KEY', 'sk-ant-tu-clave', [EnvironmentVariableTarget]::User)

# Contexto extendido para Ollama (si lo usas)
[Environment]::SetEnvironmentVariable('OLLAMA_CONTEXT_LENGTH', '65536', [EnvironmentVariableTarget]::User)

# Ollama accesible en red (si lo usas con Docker/WSL2)
[Environment]::SetEnvironmentVariable('OLLAMA_HOST', '0.0.0.0:11434', [EnvironmentVariableTarget]::User)
```

---

## Cambiar configuración via CLI

```powershell
# Cambiar modelo
openclaw config set agents.defaults.model "anthropic/claude-3-haiku-20240307"

# Cambiar perfil de herramientas
openclaw config set tools.profile "full"

# Ver valor actual
openclaw config get gateway.auth.token

# Reiniciar para aplicar cambios
openclaw gateway restart
```

---

## Validar configuración

```powershell
openclaw doctor
openclaw doctor --fix    # Auto-reparar problemas
```
