# Workflow N8N: Ingestión de PDFs

## Propósito

Este workflow se ejecuta cuando se sube un nuevo PDF a Google Drive. Extrae el texto, lo fragmenta en chunks, genera embeddings y los almacena en Supabase.

## Flujo Conceptual

```
[Google Drive:New File] 
    ↓
[Download PDF]
    ↓
[Extract Text (PDF)]
    ↓
[Split into Chunks]
    ↓
[Generate Embedding per Chunk]
    ↓
[Insert to Supabase Vectors]
    ↓
[Update Manual Status]
```

## Crear Workflow en N8N

### Nodo 1: Trigger - Google Drive Watch Files

```
Nombre: Google Drive - Watch Files
Credencial: Google Drive OAuth2
Parámetros:
  - Folder ID: ID de tu carpeta "manuales"
  - Watch for: fileCreated, fileModified
  - Limit: 10
```

### Nodo 2: Download PDF

```
Nombre: Google Drive - Download File
Campos:
  - File ID: {{ $json.fileId }}
  - Options: Binary data = true
```

### Nodo 3: Extract Text (método)

**Opción A: N8N native (sin código)**
```
Nombre: Edit Fields
Campos a crear:
  - pdf_content: "{{ $json.binary.data }}"
```

**Opción B: Código personalizado (más preciso)**

Usa nodo **Code** con esta función:

```javascript
// Nodo Code - Extract text from PDF
const pdfData = $input.first().json.binary.data;
const pdfBuffer = Buffer.from(pdfData, 'binary');

// Return como texto (N8N no tiene extractor PDF nativo)
// En este caso, usamos pdf-parse en un nodo Function
return {
  json: {
    text: pdfBuffer.toString('text'),
    name: $input.first().json.name
  }
};
```

### Nodo 4: Split into Chunks

Usa nodo **Code**:

```javascript
// Fragmentar texto en chunks de ~500 caracteres
const text = $input.first().json.text;
const chunkSize = 500;
const overlap = 50;
const chunks = [];

for (let i = 0; i < text.length; i += chunkSize - overlap) {
  const chunk = text.slice(i, i + chunkSize);
  if (chunk.trim().length > 50) {
    chunks.push({ text: chunk, index: chunks.length });
  }
  if (i + chunkSize > text.length) break;
}

return chunks.map(chunk => ({ json: chunk }));
```

### Nodo 5: Generate Embedding

**HTTP Request:**

```
Method: POST
URL: https://api.openai.com/v1/embeddings
Headers:
  Authorization: Bearer {{ $env.OPENAI_API_KEY }}
  Content-Type: application/json
Body (JSON):
{
  "model": "text-embedding-ada-002",
  "input": "{{ $json.text }}"
}
```

### Nodo 6: Insert to Supabase

**HTTP Request:**

```
Method: POST
URL: {{ $env.SUPABASE_URL }}/rest/v1/vectores
Headers:
  apikey: {{ $env.SUPABASE_ANON_KEY }}
  Authorization: Bearer {{ $env.SUPABASE_ANON_KEY }}
  Content-Type: application/json
  Prefer: return=minimal
Body (JSON):
{
  "manual_id": "{{ $json.manual_id }}",
  "chunk_text": "{{ $json.text }}",
  "embedding": "{{ $json.embedding }}",
  "page_number": {{ $json.page }}
}
```

### Nodo 7: Update Manual Status

```
Method: PATCH
URL: {{ $env.SUPABASE_URL }}/rest/v1/manuales?drive_file_id=eq.{{ $json.fileId }}
Body:
{
  "procesado": true,
  "total_chunks": {{ $json.chunkCount }}
}
```

## Alternativas Consideradas

| Decisión | Alternativa | Razón |
|----------|------------|-------|
| chunk 500 chars | ~1000 | Chunk más grandes = menos contexto |
| text-embedding-ada-002 | text-embedding-3-small | Ada-002 es más estable |
| N8N code | Python script externo | Más complejo de mantener |

## Exportar/Importar Workflow

En N8N:
1. Workflows → Import from JSON
2. Pega el JSON del archivo `n8n/workflows/ingest-pdf.json`