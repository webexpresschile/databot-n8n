# Setup de N8N en Railway

## Requisitos Previos

- Cuenta en [Railway.app](https://railway.app)
- Cuenta de GitHub (para desplegar desde GitHub)

## Paso 1: Desplegar N8N en Railway

### Opción A: Despliegue con 1-Click (Recomendado)

1. Ve a [railway.new/n8n](https://railway.new/n8n)
2. Click en **Deploy Now**
3. Configura变量 de entorno:
   - `WEBHOOK_URL`: `/webhook`
   - `N8N_PROTOCOL`: `https`
   - `N8N_PORT`: `80`
   - `N8N_AUTH_ACTIVE`: `true`
   - `N8N_BASIC_AUTH_ACTIVE`: `true`
   - `N8N_BASIC_AUTH_USER`: `admin`
   - `N8N_BASIC_AUTH_PASSWORD`: `Elige una contraseña segura`
4. Click en **Deploy**

### Opción B: Despliegue desde GitHub

1. En Railway dashboard: **New** → **GitHub Repo**
2. Selecciona un repo vacío o crea uno nuevo
3. Railway detectará el Dockerfile y desplegará

## Paso 2: Configurar Credenciales en N8N

Una vez desplegado, accede a `https://tu-n8n.railway.app`

### Credenciales necesarias:

#### 1. Google Drive (OAuth2)
1. Ve a **Settings** → **Credentials**
2. Nueva credencial → **Google Drive API**
3. Crea proyecto en [Google Cloud Console](https://console.cloud.google.com):
   - Habilita Google Drive API
   - Crea OAuth 2.0 Client ID
   - Configura URIs de redirect
4. Autoriza acceso a Drive

#### 2. Supabase
1. Nueva credencial → **HTTP Header Auth**
2. Headers:
   - `apikey`: `Tu anon key de Supabase`
   - `Authorization`: `Bearer Tu anon key`

#### 3. OpenAI
1. Nueva credencial → **OpenAI API**
2. Ingresa tu API key

#### 4. Anthropic (Claude)
1. Nueva credencial → **HTTP Header Auth**
2. Headers:
   - `x-api-key`: `Tu API key de Anthropic`
   - `anthropic-version`: `2023-06-01`
   - `Content-Type`: `application/json`

## Paso 3: Configurar Webhook de Google Drive

1. En Google Drive, crea una carpeta llamada `manuales`
2. Ve a **Settings** → **Workflows** → **New**
3. Busca "Google Drive" → **Google Drive Watch Files**
4. Configura:
   - Folder ID: ID de la carpeta `manuales`
   - Trigger on: `fileCreated`
5. Save y activa el workflow

## Verificar que N8N Funciona

1. Accede a `https://tu-n8n.railway.app`
2. Login con credenciales del paso 1
3. Verifica que las credenciales están configuradas
4. Exporta los workflows de `n8n/workflows/`

## Costos

- Railway plan gratuito: 500 horas/mes
- Suficiente para 1 instancia N8N