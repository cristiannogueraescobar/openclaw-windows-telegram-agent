# 🦞 OpenClaw Windows Agent

**Controla tu PC con Windows de forma remota usando IA, desde Telegram.**

OpenClaw Windows Agent es un sistema completo que convierte tu PC en un agente de IA autónomo controlable desde Telegram. Usa Claude API (Anthropic) para respuestas rápidas e inteligentes, o Ollama para inferencia 100% local y gratuita.

---

## ¿Qué hace este proyecto?

- **Control remoto vía Telegram**: Envía mensajes a tu bot y la IA ejecuta acciones en tu PC
- **Ejecución de comandos**: PowerShell, CMD, scripts — todo desde tu teléfono
- **Gestión de archivos**: Crear, leer, modificar y eliminar archivos remotamente
- **IA flexible**: Usa Claude API (rápido, potente) o Ollama local (gratis, privado)
- **Seguridad por diseño**: Sistema de pairing, tokens de autenticación y perfiles de ejecución

---

## Hardware recomendado (probado en el mundo real)

> ⚠️ **Lección aprendida**: Con 8 GB de RAM, Ollama local es demasiado lento para uso práctico. Claude API es la única opción rápida en hardware limitado.

| Escenario | RAM | GPU VRAM | Proveedor recomendado | Experiencia real |
|---|---|---|---|---|
| **PC básico** | 8 GB | Integrada | **Claude API (obligatorio)** | Ollama timeout constante, inutilizable |
| **PC gaming** | 16 GB | 8 GB | Claude API o Ollama (qwen2.5:7b) | Ollama funcional pero lento (10-30s) |
| **Workstation** | 32 GB | 16+ GB | Ollama (qwen2.5:32b) | Ollama fluido, sin necesidad de API |

### Modelos de Ollama probados en 8 GB RAM

| Modelo | Tamaño | ¿Funciona? | Notas |
|---|---|---|---|
| `llama3.2:1b` | 1.3 GB | ❌ No | Contexto 8192 < 16000 mínimo requerido |
| `llama3.2:3b` | 2.0 GB | ❌ No | Contexto insuficiente para OpenClaw |
| `qwen2.5:3b` | 1.9 GB | ⚠️ Lento | Funciona pero 30-60s por respuesta, timeout frecuente |
| `qwen2.5:7b` | 4.7 GB | ❌ Inviable | Timeout constante en 8 GB RAM |
| `qwen3:4b` | 2.5 GB | ⚠️ Lento | Similar a qwen2.5:3b |

**Conclusión**: Si tienes 8 GB RAM → usa **Claude API**. Si insistes en local → `qwen2.5:3b` con timeout 180s y WSL2 limitado a 3 GB.

---

## Requisitos del sistema (versiones probadas)

| Componente | Versión probada | Instalación |
|---|---|---|
| **Windows** | 11 25H2, Build 26200 | Preinstalado |
| **PowerShell** | 5.1 / 7.x | Nativo |
| **Node.js** | v24.14.1 | `winget install OpenJS.NodeJS.LTS` |
| **npm** | 11.11.0 | Incluido con Node.js |
| **Git** | Última | `winget install Git.Git` |
| **OpenClaw** | 2026.4.11 (769908e) | `iwr -useb https://openclaw.ai/install.ps1 \| iex` |
| **Docker Desktop** | 29.3.1 (opcional) | `winget install Docker.DockerDesktop` |
| **Ollama** | 0.20.6 (opcional) | `winget install Ollama.Ollama` |
| **Python** | 3.11 (opcional) | `winget install Python.Python.3.11` |
| **PM2** | Última (opcional) | `npm install -g pm2` |

---

## Instalación rápida

```powershell
# Método recomendado (script oficial de OpenClaw)
iwr -useb https://openclaw.ai/install.ps1 | iex

# O con el script de este repositorio
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\scripts\install.ps1
```

> 📖 Guía completa paso a paso: **[INSTALLATION.md](INSTALLATION.md)**

---

## Uso rápido

### Iniciar el sistema

```powershell
.\scripts\start.ps1
```

### Ejemplos desde Telegram

```
Tú: Dime qué hora es en mi PC
Bot: Son las 14:32:05 del martes 14 de abril de 2026.

Tú: Crea un archivo notas.txt con "Recordar comprar café"
Bot: ✅ Archivo creado en C:\Users\tu_usuario\notas.txt

Tú: Ejecuta ipconfig y dime mi IP local
Bot: Tu dirección IPv4 es 192.168.1.45
```

### Comandos útiles probados

```powershell
openclaw gateway status                    # Estado del gateway
openclaw gateway restart                   # Reiniciar gateway
openclaw message send --target main --message "tu comando"
openclaw tui                               # Interfaz terminal
openclaw logs --follow                     # Logs en tiempo real
openclaw config set tools.profile "full"   # Activar control total
openclaw devices list                      # Dispositivos pendientes
openclaw devices approve ID                # Aprobar dispositivo
```

---

## Documentación completa

| Documento | Descripción |
|---|---|
| [INSTALLATION.md](INSTALLATION.md) | Instalación paso a paso con versiones exactas |
| [CONFIGURATION.md](CONFIGURATION.md) | JSON final probado y funcionando |
| [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | 15 errores reales con soluciones probadas |
| [LESSONS_LEARNED.md](LESSONS_LEARNED.md) | Todo lo que aprendimos en el proceso |
| [ERRORS_AND_SOLUTIONS.md](ERRORS_AND_SOLUTIONS.md) | Tabla rápida de errores y fixes |
| [docs/architecture.md](docs/architecture.md) | Arquitectura del sistema |
| [docs/security.md](docs/security.md) | Seguridad y buenas prácticas |
| [docs/api.md](docs/api.md) | Referencia de la API HTTP |

---

## ⚠️ Advertencia de seguridad

Este sistema otorga **control total sobre tu PC** a través de Telegram. Úsalo solo en PCs de tu propiedad y en redes de confianza. Lee [docs/security.md](docs/security.md).

---

## Licencia

Documentación bajo MIT. OpenClaw tiene su propia licencia — ver [repositorio oficial](https://github.com/openclaw/openclaw).
