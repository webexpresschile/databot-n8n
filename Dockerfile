# Usar la imagen oficial de n8n
FROM n8nio/n8n:latest

# Variables de entorno
ENV N8N_PROTOCOL=https
ENV N8N_PORT=5678
ENV N8N_HOST=0.0.0.0
ENV WEBHOOK_PATH=/webhook

# Autenticación básica
ENV N8N_BASIC_AUTH_ACTIVE=true
ENV N8N_BASIC_AUTH_USER=admin

# El puerto que expone n8n por defecto
EXPOSE 5678

# No necesitamos CMD - la imagen ya tiene el entrypoint correcto
# Solo dejamos que la imagen base haga su trabajo
