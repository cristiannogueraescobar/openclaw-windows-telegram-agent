# 🔒 Consideraciones de seguridad

## ⚠️ Advertencia

OpenClaw con `tools.profile = "full"` y `exec.security = "full"` otorga **control total sobre tu PC**. Esto incluye ejecutar cualquier comando, leer/escribir archivos y acceder a la red.

---

## Modelo de seguridad por capas

### Capa 1: Control de acceso (Telegram)

```json
{
  "channels": {
    "telegram": {
      "dmPolicy": "allowlist",
      "allowFrom": ["TU_ID_NUMERICO"],
      "groupPolicy": "disabled"
    }
  }
}
```

| Política | Seguridad | Descripción |
|---|---|---|
| `"disabled"` | Máxima | Nadie puede usar DMs |
| `"allowlist"` | Alta | Solo IDs explícitos |
| `"pairing"` | Media | Requiere aprobación manual (nuestra config) |
| `"open"` | Baja | Cualquiera puede interactuar |

### Capa 2: Gateway

```json
{
  "gateway": {
    "bind": "loopback",
    "auth": {
      "mode": "token",
      "token": "TOKEN_48_CARACTERES_ALEATORIOS"
    }
  }
}
```

> **Nota**: En nuestra config usamos `"bind": "lan"` para acceso desde la red local. Para máxima seguridad, usa `"loopback"`.

### Capa 3: Ejecución

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

Para mayor seguridad, cambia a `"ask": "on"` (pide confirmación) o `"security": "allowlist"` (solo comandos aprobados).

---

## Buenas prácticas

- Usa variables de entorno para API keys en vez de texto plano
- No publiques el username de tu bot de Telegram
- Mantén `bind: "loopback"` si no necesitas acceso desde otros dispositivos
- Para acceso remoto, usa **Tailscale** en vez de exponer puertos
- Ejecuta OpenClaw con un usuario de Windows sin privilegios de administrador
- Revisa logs periódicamente: `openclaw logs --follow`
- Ejecuta auditoría: `openclaw security audit`

---

## Checklist

- [ ] `dmPolicy` en `"allowlist"` o `"pairing"` con tu ID
- [ ] Token del Gateway con 32+ caracteres
- [ ] API keys en variables de entorno
- [ ] Puerto 18789 NO abierto en firewall público
- [ ] `openclaw doctor` sin errores
- [ ] Backups del sistema configurados
