# Workflow N8N: Chat Query

## Propósito

Este workflow recibe preguntas de técnicos desde la web app, busca en los vectores de manuales, y usa Claude para generar una respuesta contextualizada en español.

## Flujo Conceptual

```
[Web App Webhook]
    ↓
[Generate Query Embedding]
    ↓
[Search Similar Vectors in Supabase]
    ↓
[Build Context from Chunks]
    ↓
[Call Claude API]
    ↓
[Save to Historial (Supabase)]
    ↓
[Return Response to Web App]
```

## Crear Workflow en N8N

### Nodo 1: Webhook Trigger

```
Nombre: DataBot Chat Webhook
Endpoint: /webhook/chat
Method: POST
```

### Nodo 2: Generate Query Embedding (HTTP Request)

```
Method: POST
URL: https://api.openai.com/v1/embeddings
Headers:
  Authorization: Bearer {{ $credentials.openaiApiKey }}
  Content-Type: application/json
Body (JSON):
{
  "model": "text-embedding-ada-002",
  "input": "{{ $json.question }}"
}
```

### Nodo 3: Search Vectors in Supabase

**HTTP Request:**

```
Method: POST
URL: {{ $env.SUPABASE_URL }}/rest/v1/rpc/buscar_en_vectores
Headers:
  apikey: {{ $env.SUPABASE_ANON_KEY }}
  Authorization: Bearer {{ $env.SUPABASE_ANON_KEY }}
  Content-Type: application/json
Body (JSON):
{
  "query_text": "{{ $json.question }}",
  "match_count": 5
}
```

### Nodo 4: Build Context (Code)

```javascript
// Construir contexto desde los resultados de búsqueda
const searchResults = $input.first().json;
const contextChunks = [];

// Agrupar por similarity y construir contexto
if (searchResults && searchResults.length > 0) {
  for (const result of searchResults) {
    contextChunks.push(result.chunk_text);
  }
}

return [{
  json: {
    context: contextChunks.join('\n\n---\n\n'),
    question: searchResults.question,
    user_id: searchResults.user_id,
    session_id: searchResults.session_id
  }
}];
```

### Nodo 5: Call Claude API

**HTTP Request:**

```
Method: POST
URL: https://api.anthropic.com/v1/messages
Headers:
  x-api-key: {{ $credentials.claudeApiKey }}
  anthropic-version: 2023-06-01
  Content-Type: application/json
Body (JSON):
{
  "model": "claude-sonnet-4-20250514",
  "max_tokens": 1024,
  "system": "Eres un asistente técnico especializado en fotocopiadoras. \nRespondes SIEMPRE en español, de manera clara y concisa.\nUsa el siguiente contexto del manual para responder:\n\n{{ $json.context }}\n\nInstrucciones:\n- Si la respuesta está en el contexto, úsala\n- Si no está clara la respuesta, indica que no tienes esa información específica\n- Incluye el número de página cuando sea relevante\n- Da pasos claros para resolver el problema",
  "messages": [
    {
      "role": "user",
      "content": "{{ $json.question }}"
    }
  ]
}
```

### Nodo 6: Save to Historial (Supabase)

**Primero crear conversación si no existe:**

```
Method: POST
URL: {{ $env.SUPABASE_URL }}/rest/v1/conversaciones
(if not exists)
```

**Luego guardar mensaje del usuario:**

```
Method: POST
URL: {{ $env.SUPABASE_URL }}/rest/v1/mensajes
Body:
{
  "conversacion_id": "{{ $json.session_id }}",
  "rol": "user",
  "contenido": "{{ $json.question }}"
}
```

**Guardar respuesta del asistente:**

```
Method: POST
URL: {{ $env.SUPABASE_URL }}/rest/v1/mensajes
Body:
{
  "conversacion_id": "{{ $json.session_id }}",
  "rol": "assistant",
  "contenido": "{{ $json.claude_response }}"
}
```

### Nodo 7: Return to Web App

```
Method: POST
URL: /webhook/chat/response
Body:
{
  "answer": "{{ $json.claude_response }}",
  "sources": "{{ $json.sources }}"
}
```

## Alternativas Consideradas

| Decisión | Alternativa | Razón |
|----------|-------------|-------|
| Claude Sonnet | GPT-4o | Similar costo, menos especializado para instrucciones |
| Búsqueda en todos los manuales | Por modelo específico | Más preciso si el usuario indica modelo |
| RPC buscar_en_vectores | filter manual por nombre | RPC es más flexible |

## Notas Importantes

1. **Costos de API**: 
   - Embeddings: ~$0.0001/ consulta
   - Claude: ~$0.003/ consulta
   - Total ~$0.003 por pregunta

2. **Manejo de errores**: Si no hay resultados en la búsqueda, Claude responde "No encontré información específica..."

3. **Cacheo**: La web app cachea las últimas conversaciones localmente para conectividad intermitente