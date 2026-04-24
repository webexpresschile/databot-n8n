FROM n8nio/n8n:latest

# Variables por defecto
ENV N8N_PROTOCOL=https
ENV N8N_PORT=5678
ENV N8N_HOST=0.0.0.0
ENV WEBHOOK_PATH=/webhook

# Autenticación básica (OPCIONAL pero recomendado)
ENV N8N_BASIC_AUTH_ACTIVE=true
ENV N8N_BASIC_AUTH_USER=admin

# Sin contraseña por defecto (la configuras en Railway)
# N8N_BASIC_AUTH_PASSWORD se setea en Railway

EXPOSE 5678

CMD ["n8n", "start"]
