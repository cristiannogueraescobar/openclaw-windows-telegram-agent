# 🌐 Uso de la API HTTP

El Gateway expone una API compatible con OpenAI en el puerto **18789**.

---

## Autenticación

Todas las peticiones requieren el header:

```
Authorization: Bearer TU_TOKEN_GATEWAY
```

Obtener el token:

```powershell
openclaw config get gateway.auth.token
```

---

## POST `/v1/chat/completions` — Chat con el agente

### PowerShell (probado y funcionando)

```powershell
$token = "TU_TOKEN_GATEWAY"
$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type"  = "application/json"
}
$body = '{"model":"openclaw/main","messages":[{"role":"user","content":"Dime la hora actual"}]}'

$response = Invoke-RestMethod -Uri "http://127.0.0.1:18789/v1/chat/completions" `
    -Method POST -Headers $headers -Body $body

Write-Output $response.choices[0].message.content
```

### curl

```bash
curl -sS http://127.0.0.1:18789/v1/chat/completions \
  -H "Authorization: Bearer TU_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"model":"openclaw/main","messages":[{"role":"user","content":"Hola"}]}'
```

### Parámetros

| Campo | Tipo | Requerido | Descripción |
|---|---|---|---|
| `model` | string | Sí | `"openclaw/main"` o `"openclaw:main"` |
| `messages` | array | Sí | Array de `{role, content}` |
| `stream` | boolean | No | `true` para Server-Sent Events |

---

## POST `/tools/invoke` — Invocar herramientas

```powershell
$headers = @{ "Authorization" = "Bearer $token"; "Content-Type" = "application/json" }
$body = '{"tool":"sessions_list","action":"json","args":{}}'

Invoke-RestMethod -Uri "http://127.0.0.1:18789/tools/invoke" `
    -Method POST -Headers $headers -Body $body
```

---

## Integración con Python

```python
from openai import OpenAI

client = OpenAI(
    base_url="http://127.0.0.1:18789/v1",
    api_key="TU_TOKEN_GATEWAY"
)

response = client.chat.completions.create(
    model="openclaw/main",
    messages=[{"role": "user", "content": "Lista archivos del escritorio"}]
)

print(response.choices[0].message.content)
```

---

## Códigos de error

| Código | Causa | Solución |
|---|---|---|
| 401 | Token inválido | Verificar Bearer token |
| 404 | Herramienta bloqueada | Verificar `tools.profile` |
| 429 | Rate limit | Esperar y reintentar |
| 500 | Error interno | `openclaw logs --follow` |
| 502 | Modelo no disponible | Verificar Claude/Ollama |
