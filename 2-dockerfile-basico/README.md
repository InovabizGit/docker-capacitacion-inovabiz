# Bloque 2: Construcción de Imágenes con Dockerfile

## Objetivo del Bloque
Crear imágenes personalizadas usando Dockerfile, entendiendo las instrucciones fundamentales y aplicándolas en un proyecto real.

**Duración:** 1 hora 15 minutos

## Contenido Teórico

### 1. ¿Qué es un Dockerfile?

Un **Dockerfile** es un archivo de texto que contiene instrucciones para construir una imagen Docker automáticamente.

**Analogía:** Es como una "receta de cocina" que le dice a Docker:
- Qué ingredientes usar (imagen base)
- Qué pasos seguir (copiar archivos, instalar dependencias)
- Cómo servir el plato (ejecutar la aplicación)

**Características clave:**
- **Reproducible:** Genera la misma imagen cada vez
- **Versionable:** Se puede guardar en control de versiones
- **Documentado:** Describe exactamente cómo se construye la imagen
- **Automatizable:** Integra con pipelines CI/CD

### 2. Instrucciones Fundamentales

#### FROM - La Base
Especifica la imagen base sobre la cual construir nuestra imagen.

```dockerfile
# Especifica la imagen base
FROM node:18
FROM ubuntu:22.04
FROM nginx:alpine
```

**Buenas prácticas:**
- Usar versiones específicas en lugar de `latest`
- Preferir imágenes oficiales y verificadas
- Elegir imágenes ligeras cuando sea posible (`alpine`)

#### WORKDIR - Directorio de Trabajo
Establece el directorio de trabajo dentro del contenedor para instrucciones subsecuentes.

```dockerfile
# Establece el directorio de trabajo dentro del contenedor
WORKDIR /app
```

**Ventajas:**
- Mantiene organización dentro del contenedor
- Evita problemas con rutas relativas
- Crea el directorio automáticamente si no existe

#### COPY - Copiar Archivos
Copia archivos y directorios del contexto de build al sistema de archivos del contenedor.

```dockerfile
# Copia archivos del host al contenedor
COPY package.json ./
COPY . .
COPY src/ /app/src/
```

**Diferencia con ADD:**
- `COPY` es más simple y predecible
- `ADD` puede descomprimir archivos automáticamente
- Preferir `COPY` para la mayoría de casos

#### RUN - Ejecutar Comandos
Ejecuta comandos durante la construcción de la imagen (build time).

```dockerfile
# Ejecuta comandos durante la construcción
RUN npm install
RUN apt-get update && apt-get install -y curl
RUN mkdir -p /app/logs
```

**Optimización:**
- Combinar comandos con `&&` para minimizar capas
- Limpiar archivos temporales en la misma capa

#### ENV - Variables de Entorno
Define variables de entorno que estarán disponibles en el contenedor.

```dockerfile
# Define variables de entorno
ENV NODE_ENV=production
ENV PORT=3000
ENV DB_HOST=localhost
```

**Usos comunes:**
- Configuración de aplicaciones
- Rutas de archivos importantes
- Flags de comportamiento

#### EXPOSE - Documentar Puertos
Documenta qué puertos usa la aplicación (no los publica automáticamente).

```dockerfile
# Documenta qué puerto usa la aplicación
EXPOSE 3000
EXPOSE 80 443
```

**Nota importante:** `EXPOSE` es solo documentación. Para publicar puertos se usa `docker run -p`.

#### CMD - Comando por Defecto
Especifica el comando que se ejecuta cuando se inicia el contenedor.

```dockerfile
# Comando que se ejecuta al iniciar el contenedor
CMD ["npm", "start"]
CMD ["node", "app.js"]
CMD ["nginx", "-g", "daemon off;"]
```

**Características:**
- Solo la última instrucción `CMD` tiene efecto
- Se puede sobrescribir al ejecutar `docker run`
- Usar formato array (exec form) es preferible

#### ENTRYPOINT - Punto de Entrada
Define el punto de entrada fijo que no se puede sobrescribir.

```dockerfile
# Punto de entrada fijo (no se puede sobrescribir)
ENTRYPOINT ["node"]
CMD ["app.js"]  # Se puede combinar con CMD
```

### 3. Diferencia: CMD vs ENTRYPOINT

```dockerfile
# Solo CMD
FROM node:18
CMD ["echo", "Hola"]
# docker run mi-imagen ls  → ejecuta "ls" (sobrescribe CMD)

# ENTRYPOINT + CMD
FROM node:18
ENTRYPOINT ["echo"]
CMD ["Hola"]
# docker run mi-imagen Mundo  → ejecuta "echo Mundo"
```

**Cuándo usar cada uno:**
- **CMD:** Para comandos que pueden ser sobrescritos
- **ENTRYPOINT:** Para definir el comportamiento principal del contenedor
- **Combinados:** ENTRYPOINT fija el comando, CMD proporciona argumentos por defecto

### 4. Conceptos Avanzados

#### Contexto de Build
El contexto de build es el conjunto de archivos enviados al Docker daemon para construir la imagen.

```bash
# Todo el directorio actual se envía como contexto
docker build -t mi-app .

# Especificar Dockerfile diferente
docker build -f Dockerfile.dev -t mi-app .
```

**Consideraciones:**
- Archivos grandes en el contexto ralentizan el build
- Usar `.dockerignore` para excluir archivos innecesarios
- El contexto se envía al daemon antes de leer el Dockerfile

#### Cache de Layers
Docker cachea cada layer (capa) de la imagen para acelerar builds subsecuentes.

**Orden óptimo para aprovechar cache:**
```dockerfile
# 1. Instrucciones que cambian poco primero
FROM node:18
WORKDIR /app

# 2. Dependencias (cambian poco)
COPY package.json package-lock.json ./
RUN npm ci --only=production

# 3. Código fuente (cambia frecuentemente) al final
COPY . .
CMD ["npm", "start"]
```

#### Multistage Builds
Permite usar múltiples imágenes base en un solo Dockerfile para optimizar el tamaño final.

```dockerfile
# Etapa 1: Build
FROM node:18 AS builder
WORKDIR /app
COPY package.json ./
RUN npm install
COPY . .
RUN npm run build

# Etapa 2: Runtime
FROM node:18-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package.json ./
RUN npm install --only=production
CMD ["npm", "start"]
```

**Ventajas:**
- Imágenes finales más pequeñas
- Separación clara entre dependencias de build y runtime
- Mayor seguridad (menos herramientas en producción)

### 5. Archivo .dockerignore

Similar a `.gitignore`, especifica qué archivos excluir del contexto de build.

```
node_modules
npm-debug.log*
.git
.DS_Store
.env
.env.local
README.md
Dockerfile
.dockerignore
```

**Beneficios:**
- Reduce el tamaño del contexto de build
- Mejora la velocidad de build
- Evita copiar archivos sensibles o innecesarios

### 6. Buenas Prácticas para Dockerfile

#### Hacer (DO)
```dockerfile
# 1. Usar imágenes base específicas
FROM node:18-alpine

# 2. Orden óptimo para cache
COPY package.json ./
RUN npm install
COPY . .

# 3. Limpiar en la misma capa
RUN apt-get update && apt-get install -y curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 4. Usuario no root
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nextjs -u 1001
USER nextjs

# 5. Usar formato array para CMD/ENTRYPOINT
CMD ["npm", "start"]
```

#### No Hacer (DON'T)
```dockerfile
# 1. No usar latest
FROM node:latest

# 2. No copiar todo al principio
COPY . .
RUN npm install

# 3. No crear capas innecesarias
RUN apt-get update
RUN apt-get install -y curl
RUN apt-get clean

# 4. No dejar secretos
ENV DATABASE_PASSWORD=secret123

# 5. No usar formato shell innecesariamente
CMD npm start
```

### 7. Patrones Comunes por Tecnología

#### Node.js
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 3000
USER node
CMD ["npm", "start"]
```

#### Python
```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 8000
CMD ["python", "app.py"]
```

#### Java (Spring Boot)
```dockerfile
FROM openjdk:17-jre-slim
WORKDIR /app
COPY target/*.jar app.jar
EXPOSE 8080
CMD ["java", "-jar", "app.jar"]
```

### 8. Optimización de Imágenes

#### Estrategias de Reducción de Tamaño
1. **Imágenes base ligeras:** Usar variantes `alpine` o `slim`
2. **Multistage builds:** Separar build de runtime
3. **Minimizar capas:** Combinar comandos RUN
4. **Limpiar caches:** Remover archivos temporales
5. **Dependencias justas:** Solo instalar lo necesario

#### Análisis de Tamaño
```bash
# Ver tamaño de imagen
docker images mi-app

# Analizar capas
docker history mi-app

# Comparar tamaños
docker images | grep mi-app
```

## Conceptos Clave para Recordar

- **Dockerfile = Receta** para construir imágenes automáticamente
- **FROM** define la imagen base
- **Orden importa** para aprovechar cache de layers
- **COPY dependencias antes** que el código fuente
- **RUN** ejecuta en build time, **CMD** en runtime
- **ENTRYPOINT + CMD** para flexibilidad en argumentos
- **Multistage builds** optimizan tamaño final
- **.dockerignore** mejora velocidad y seguridad
- **Usuario no-root** aumenta seguridad

## Ejercicios Prácticos

Para ejercicios hands-on, comandos y verificaciones prácticas, consultar:
**test-ejercicio.md** - Guía completa de ejercicios prácticos

---
**Siguiente:** Bloque 3 - Optimización de Imágenes 