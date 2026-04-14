# 🏗️ Arquitectura del sistema

## Visión general

OpenClaw sigue una **arquitectura hub-and-spoke** donde un único proceso Gateway coordina todo.

```
  ┌─────────────────────────────────────────────┐
  │              CANALES DE ENTRADA              │
  │   Telegram  │  WhatsApp  │  API HTTP  │ CLI │
  └──────────────────┬──────────────────────────┘
                     │
                     ▼
  ┌─────────────────────────────────────────────┐
  │               GATEWAY (Hub)                  │
  │          ws://127.0.0.1:18789               │
  │                                              │
  │  • Router de mensajes                       │
  │  • Auth & Pairing                           │
  │  • Gestión de sesiones y memoria            │
  │  • Pool de proveedores IA                   │
  │  • Hot-reload de configuración              │
  └──────────────────┬──────────────────────────┘
                     │
          ┌──────────┼──────────┐
          ▼          ▼          ▼
  ┌────────────┐ ┌────────┐ ┌──────────┐
  │  Agente IA │ │  CLI   │ │ Control  │
  │ (Runtime)  │ │  Tool  │ │   UI     │
  └─────┬──────┘ └────────┘ └──────────┘
        │
        ▼
  ┌─────────────────────────────────────────────┐
  │         HERRAMIENTAS DE EJECUCIÓN            │
  │  Shell (PowerShell/CMD)  │  Sistema archivos │
  │  Navegador web           │  Memoria          │
  └─────────────────────────────────────────────┘
```

---

## Componentes principales

### Gateway (Proceso central)

Proceso Node.js de larga duración que escucha en el puerto **18789**. Multiplexa WebSocket y HTTP. En Windows usa **Scheduled Tasks** como servicio.

### Agente IA (Runtime)

Recibe mensajes del Gateway, ensambla contexto cargando los **8 archivos bootstrap** del workspace (SOUL.md, AGENTS.md, USER.md, TOOLS.md, IDENTITY.md, HEARTBEAT.md, MEMORY.md, BOOTSTRAP.md), llama al modelo de IA y ejecuta herramientas.

### Canales de entrada

Telegram (principal), API HTTP, CLI (`openclaw tui`, `openclaw message send`).

---

## Flujo de un mensaje (Telegram → acción en PC)

1. **Ingesta**: Telegram recibe mensaje → envía al Gateway
2. **Control de acceso**: Verifica pairing/allowlist
3. **Contexto**: Carga archivos bootstrap + historial de sesión
4. **Modelo**: Envía contexto + mensaje a Claude API (o Ollama)
5. **Herramientas**: Si el modelo pide ejecutar algo → shell/archivos en el PC
6. **Respuesta**: Resultado formateado → de vuelta a Telegram

---

## Estructura del workspace

```
~/.openclaw/
├── openclaw.json                 # Configuración principal (JSON5)
├── exec-approvals.json           # Política de ejecución
├── credentials/                  # Claves API y auth
├── agents/main/sessions/         # Transcripciones JSONL
└── workspace/
    ├── SOUL.md                   # Personalidad
    ├── AGENTS.md                 # Reglas procedimentales
    ├── USER.md                   # Info del usuario
    ├── IDENTITY.md               # Nombre, emoji
    ├── TOOLS.md                  # Guía de herramientas
    ├── HEARTBEAT.md              # Tareas periódicas
    ├── MEMORY.md                 # Memoria largo plazo
    ├── BOOTSTRAP.md              # Onboarding (solo 1ª vez)
    └── memory/YYYY-MM-DD.md      # Memorias diarias
```

Solo los **8 archivos exactos** se auto-cargan en cada sesión.

---

## Modelo de seguridad (3 capas)

1. **Canal**: Pairing + allowlist controlan quién habla con el bot
2. **Gateway**: Token Bearer protege la API HTTP
3. **Ejecución**: `exec-approvals.json` + `tools.profile` controlan qué puede hacer el agente

Ver [security.md](security.md) para detalles completos.
