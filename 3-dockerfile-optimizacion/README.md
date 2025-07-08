# Bloque 3: Optimización de Imágenes

## Objetivo del Bloque
Aplicar buenas prácticas en la construcción de imágenes Docker, optimizando tamaño, tiempo de build y seguridad.

**Duración:** 1 hora 15 minutos

## Contenido Teórico

### 1. ¿Por qué Optimizar Imágenes?

**Problemas de imágenes no optimizadas:**
- **Despliegues lentos:** Subir/descargar GB toma tiempo
- **Costos altos:** Más almacenamiento = más dinero
- **Superficie de ataque mayor:** Más componentes = más vulnerabilidades
- **Uso ineficiente de recursos:** RAM y disco desperdiciados

**Beneficios de optimización:**
- **Despliegues rápidos:** Menos MB = menos tiempo
- **Menos costos:** Menos almacenamiento
- **Más seguro:** Menos componentes instalados
- **Eficiencia:** Solo lo necesario

### 2. Técnicas de Optimización

#### A. Imágenes Base Optimizadas

```dockerfile
# NO OPTIMIZADO (1.1GB)
FROM node:18

# OPTIMIZADO (180MB)
FROM node:18-alpine

# MÁS OPTIMIZADO (45MB con multistage)
FROM node:18-alpine AS builder
# ... build steps
FROM node:18-alpine
```

**Comparación de tamaños:**
- `node:18` → ~1.1GB
- `node:18-slim` → ~240MB
- `node:18-alpine` → ~180MB

**¿Por qué Alpine es mejor?**
- **Basado en musl libc:** Más ligero que glibc
- **Sistema mínimo:** Solo componentes esenciales
- **Administrador de paquetes:** apk es eficiente
- **Seguridad:** Menos superficie de ataque

#### B. Minimizar Capas y Cache Busting

```dockerfile
# MALO - Muchas capas innecesarias
RUN apt-get update
RUN apt-get install -y curl
RUN apt-get install -y git
RUN apt-get clean

# BUENO - Una sola capa optimizada
RUN apt-get update && \
    apt-get install -y curl git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
```

**Principios para minimizar capas:**
- Combinar comandos relacionados con `&&`
- Limpiar caches en la misma instrucción `RUN`
- Evitar crear archivos temporales entre capas
- Usar `.dockerignore` para contexto limpio

#### C. Aprovechar el Cache de Docker

```dockerfile
# OPTIMIZADO - Cambios en código no invalidan cache de deps
COPY package.json package-lock.json ./
RUN npm ci --only=production
COPY . .

# NO OPTIMIZADO - Cada cambio rebuilds todo
COPY . .
RUN npm install
```

**Estrategias de cache:**
- Copiar archivos que cambian poco primero
- Separar dependencias del código fuente
- Usar `npm ci` en lugar de `npm install`
- Ordenar instrucciones por frecuencia de cambio

### 3. Multistage Builds Avanzados

Los **multistage builds** permiten usar múltiples imágenes base en un solo Dockerfile, optimizando el resultado final.

#### Conceptos Clave:

```dockerfile
# Etapa 1: Build environment
FROM node:18 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install  # Incluye devDependencies
COPY . .
RUN npm run build  # Compilar/transpilar

# Etapa 2: Production runtime
FROM node:18-alpine AS production
WORKDIR /app
COPY --from=builder /app/dist ./
COPY --from=builder /app/package*.json ./
RUN npm ci --only=production
CMD ["npm", "start"]
```

#### Ventajas de Multistage:
- **Separación de concerns:** Build vs runtime
- **Tamaño reducido:** Solo artifacts finales
- **Seguridad mejorada:** Sin herramientas de desarrollo
- **Cache selectivo:** Cada etapa se cachea independientemente

#### Ejemplo Completo: API Node.js Optimizada

```dockerfile
# Etapa 1: Dependencias de producción
FROM node:18-alpine AS dependencies
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force

# Etapa 2: Build (compilación si es necesaria)
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build 2>/dev/null || echo "No build script found"

# Etapa 3: Runtime final
FROM node:18-alpine AS runtime
# Crear usuario no root
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodeuser -u 1001

WORKDIR /app
# Copiar solo las dependencias de producción
COPY --from=dependencies /app/node_modules ./node_modules
# Copiar solo los archivos necesarios
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/*.js ./

USER nodeuser
EXPOSE 3000
CMD ["node", "app.js"]
```

### 4. Optimizaciones Específicas por Tecnología

#### Node.js

**Instalación Optimizada de Dependencias:**
```dockerfile
# Usar npm ci para builds reproducibles
RUN npm ci --only=production

# Limpiar cache npm
RUN npm cache clean --force

# Eliminar archivos innecesarios
RUN rm -rf /tmp/* /var/tmp/* /root/.npm
```

**Variables de Entorno de Producción:**
```dockerfile
ENV NODE_ENV=production
ENV NPM_CONFIG_LOGLEVEL=warn
ENV NPM_CONFIG_FUND=false
ENV NPM_CONFIG_AUDIT=false
```

#### Python

```dockerfile
# Usar imagen slim
FROM python:3.11-slim

# Instalar solo dependencias necesarias
RUN pip install --no-cache-dir -r requirements.txt

# Limpiar archivos temporales
RUN apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
```

#### Java

```dockerfile
# Multistage para aplicaciones Spring Boot
FROM openjdk:17 AS builder
WORKDIR /app
COPY . .
RUN ./mvnw clean package -DskipTests

FROM openjdk:17-jre-slim
COPY --from=builder /app/target/*.jar app.jar
CMD ["java", "-jar", "app.jar"]
```

### 5. Seguridad en Imágenes Optimizadas

#### Usuario No Root

**¿Por qué es importante?**
- **Principio de menor privilegio:** Limitar permisos
- **Compliance:** Muchas organizaciones lo requieren
- **Prevención de escalación:** Limitar daño potencial

```dockerfile
# Crear usuario específico
RUN addgroup -g 1001 -S appgroup && \
    adduser -S appuser -u 1001

# Cambiar ownership si es necesario
COPY --chown=appuser:appgroup . /app

# Cambiar al usuario no root
USER appuser
```

#### Actualizaciones de Seguridad

```dockerfile
# Actualizar paquetes base (Alpine)
RUN apk update && apk upgrade && \
    apk add --no-cache <paquetes-necesarios> && \
    rm -rf /var/cache/apk/*

# Actualizar paquetes base (Debian/Ubuntu)
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y <paquetes-necesarios> && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
```

### 6. Archivo .dockerignore Optimizado

Un `.dockerignore` bien configurado mejora significativamente la velocidad de build:

```
# Archivos de desarrollo
node_modules
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Archivos de IDE
.vscode/
.idea/
*.swp
*.swo

# Control de versiones
.git
.gitignore

# Documentación
README.md
docs/
*.md

# Archivos de configuración local
.env
.env.local
.env.development
.env.test
.env.production

# Archivos temporales
tmp/
temp/
.tmp/

# Logs
logs/
*.log

# Cobertura de tests
coverage/
.nyc_output/

# Docker files
Dockerfile*
docker-compose*
.dockerignore
```

### 7. Herramientas de Análisis y Optimización

#### Análisis de Tamaño

```bash
# Ver tamaño detallado de todas las imágenes
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"

# Analizar layers específicos
docker history <imagen> --human=false --format "table {{.CreatedBy}}\t{{.Size}}"

# Herramientas externas
dive <imagen>  # Análisis interactivo de layers
```

#### Benchmark de Performance

```bash
# Medir tiempo de build
time docker build -t test:v1 .

# Medir tiempo de startup
time docker run --rm <imagen> <comando>

# Comparar uso de recursos
docker stats --no-stream <contenedor>
```

#### Análisis de Vulnerabilidades

```bash
# Docker scan (si está disponible)
docker scan <imagen>

# Herramientas de terceros
trivy <imagen>
snyk container test <imagen>
```

### 8. Comparación: Métricas de Optimización

| Métrica | No Optimizada | Optimizada | Mejora |
|---------|---------------|------------|--------|
| **Tamaño base** | ~1.1GB | ~180MB | 83% menor |
| **Layers** | 12+ layers | 6 layers | 50% menos |
| **Tiempo de pull** | 2-5 min | 30-60 seg | 75% más rápido |
| **Vulnerabilidades** | 200+ | 20-50 | 75% menos |
| **Tiempo de build** | 3-5 min | 1-2 min | 60% más rápido |
| **Tiempo de startup** | 5-10 seg | 1-3 seg | 70% más rápido |

### 9. Buenas Prácticas Generales

#### Hacer (DO)
- **Usar Alpine** cuando sea posible
- **Multistage builds** para separar build y runtime
- **Cache de layers** ordenando instrucciones inteligentemente
- **Usuario no root** para seguridad
- **Limpiar en misma capa** con `&& rm -rf`
- **Usar .dockerignore** para excluir archivos innecesarios
- **Versiones específicas** en lugar de `latest`

#### No Hacer (DON'T)
- **No usar `latest`** en producción
- **No incluir herramientas de desarrollo** en runtime
- **No crear capas innecesarias** con múltiples `RUN`
- **No copiar archivos grandes** innecesarios
- **No ejecutar como root** en producción
- **No incluir secretos** en la imagen

### 10. Estrategias Avanzadas

#### Distroless Images
Para máxima seguridad y mínimo tamaño:

```dockerfile
FROM gcr.io/distroless/nodejs18-debian11
COPY --from=builder /app .
CMD ["app.js"]
```

#### Scratch Images
Para binarios estáticos:

```dockerfile
FROM scratch
COPY --from=builder /app/binary /
CMD ["/binary"]
```

#### Layer Caching Strategies
Para teams distribuidos:

```dockerfile
# Base layer compartida
FROM node:18-alpine AS base
RUN apk add --no-cache git python3 make g++

# Layer de dependencias
FROM base AS deps
COPY package*.json ./
RUN npm ci --only=production
```

## Conceptos Clave para Recordar

- **Tamaño importa:** Imágenes pequeñas = despliegues rápidos
- **Alpine es tu amigo:** 80-90% reducción de tamaño típica
- **Multistage builds:** Separar build de runtime siempre
- **Cache layers:** Orden correcto = builds más rápidos
- **Usuario no root:** Seguridad básica obligatoria
- **Un comando RUN:** Combinar operaciones relacionadas
- **.dockerignore:** Tan importante como .gitignore
- **Medición constante:** Comparar métricas antes vs después

## Ejercicios Prácticos

Para ejercicios hands-on, comandos y verificaciones prácticas, consultar:
**test-ejercicio.md** - Guía completa de ejercicios prácticos

---
**Siguiente:** Bloque 4 - Docker Compose Básico 