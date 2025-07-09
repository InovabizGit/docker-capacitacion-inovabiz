FROM nginx:alpine

# Instalar wget para health checks
RUN apk add --no-cache wget

# Copiar archivos del frontend
COPY index.html /usr/share/nginx/html/

# Copiar configuración nginx
COPY nginx.conf /etc/nginx/nginx.conf

# Crear usuario nginx si no existe
RUN addgroup -g 1001 -S nginx || true
RUN adduser -S nginx -u 1001 -G nginx || true

# Configurar permisos
RUN chown -R nginx:nginx /usr/share/nginx/html /var/cache/nginx /var/log/nginx /etc/nginx/conf.d
RUN touch /var/run/nginx.pid && chown nginx:nginx /var/run/nginx.pid

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/ || exit 1

# Exponer puerto
EXPOSE 8080

# Cambiar a usuario nginx
USER nginx

# Comando por defecto
CMD ["nginx", "-g", "daemon off;"] 