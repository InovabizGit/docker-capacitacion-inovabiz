# Dockerfile optimizado con multistage build

# Etapa 1: Dependencias de producción
FROM node:18-alpine AS dependencies
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force

# Etapa 2: Build (si necesitas compilar TypeScript, etc.)
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
# Si hay build script, ejecutarlo, sino continuar
RUN npm run build 2>/dev/null || echo "No build script found"

# Etapa 3: Runtime final optimizado
FROM node:18-alpine AS runtime

# Crear usuario no root para seguridad
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodeuser -u 1001

# Establecer directorio de trabajo
WORKDIR /app

# Variables de entorno optimizadas
ENV NODE_ENV=production
ENV NPM_CONFIG_LOGLEVEL=warn
ENV NPM_CONFIG_FUND=false
ENV NPM_CONFIG_AUDIT=false

# Copiar solo las dependencias de producción
COPY --from=dependencies /app/node_modules ./node_modules

# Copiar solo los archivos necesarios
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/*.js ./

# Cambiar al usuario no root
USER nodeuser

# Exponer puerto
EXPOSE 3000

# Usar node directamente para mejor performance
CMD ["node", "app.js"] 