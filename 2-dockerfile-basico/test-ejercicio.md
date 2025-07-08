# Guía de Ejercicios - Bloque 2: Dockerfile Básico

## Para Estudiantes: Ejercicios Paso a Paso

### Preparación Inicial

Antes de comenzar, asegúrate de tener Docker funcionando y estar en el directorio correcto:

```bash
# Verificar Docker está funcionando
docker --version
docker info

# Navegar al directorio del ejercicio
cd 2-dockerfile-basico/api-node ## En mi caso  cd /mnt/d/Development/Loteria/docker-capacitacion-inovabiz/2-dockerfile-basico/api-node/

# Verificar archivos del proyecto
ls -la
```

Deberías ver estos archivos:
- `package.json` (dependencias del proyecto)
- `app.js` (código de la API)
- `Dockerfile` (instrucciones para construir la imagen)
- `.dockerignore` (archivos a excluir del build)

### Ejercicio 1: Explorar la Aplicación Node.js

#### Objetivo: Entender qué aplicación vamos a containerizar

```bash
# 1. Revisar las dependencias
cat package.json

# 2. Revisar el código de la API
cat app.js

# 3. Revisar el Dockerfile
cat Dockerfile

# 4. Revisar qué archivos se excluyen del build
cat .dockerignore
```

**Verificación:** Deberías entender que es una API simple con Express que tiene dos endpoints: `/` y `/health`.

### Ejercicio 2: Construir tu Primera Imagen

#### Objetivo: Crear una imagen Docker personalizada desde un Dockerfile

```bash
# 1. Construir la imagen con un nombre y tag específico
docker build -t mi-api:v1.0.0 .

# Nota: El punto (.) indica que el contexto de build es el directorio actual
# -t significa "tag" para asignar nombre:versión a la imagen
```

**Durante el build observarás:**
- Descarga de la imagen base `node:18`
- Creación del directorio `/app`
- Copia de `package.json`
- Instalación de dependencias con `npm install`
- Copia del resto de archivos
- Exposición del puerto 3000

```bash
# 2. Verificar que la imagen se creó correctamente
docker images mi-api:v1.0.0

# 3. Ver todas las imágenes locales
docker images

# 4. Analizar las capas de la imagen
docker history mi-api:v1.0.0
```

**Verificación:** Deberías ver `mi-api:v1.0.0` en la lista de imágenes.

### Ejercicio 3: Ejecutar la API en un Contenedor

#### Objetivo: Correr la aplicación containerizada y probarla

```bash
# 1. Ejecutar el contenedor mapeando puertos
docker run -d -p 3000:3000 --name mi-api-container mi-api:v1.0.0

# -d: ejecutar en background (detached)
# -p 3000:3000: mapear puerto 3000 del host al puerto 3000 del contenedor
# --name: asignar nombre específico al contenedor

# 2. Verificar que el contenedor está corriendo
docker ps

# 3. Ver los logs de la aplicación
docker logs mi-api-container

# Deberías ver: "Servidor ejecutándose en puerto 3000"
```

#### Probar la API

```bash
# 4. Probar el endpoint principal
curl http://localhost:3000

# Deberías obtener:
# {"message":"Hello World desde Docker!","version":"1.0.0","timestamp":"..."}

# 5. Probar el endpoint de health check
curl http://localhost:3000/health

# Deberías obtener:
# {"status":"OK"}
```

**Verificación:** Ambos endpoints deben responder correctamente desde el navegador o curl.

### Ejercicio 4: Trabajar con Variables de Entorno

#### Objetivo: Personalizar el comportamiento usando variables de entorno

```bash
# 1. Ejecutar contenedor con variables de entorno personalizadas
docker run -d -p 3001:3000 \
  -e NODE_ENV=development \
  -e PORT=3000 \
  --name mi-api-dev \
  mi-api:v1.0.0

# -e: define variables de entorno
# Puerto del host 3001 para evitar conflicto

# 2. Verificar las variables dentro del contenedor
docker exec mi-api-dev env | grep NODE_ENV

# 3. Probar que funciona en el nuevo puerto
curl http://localhost:3001

# 4. Comparar logs de ambos contenedores
docker logs mi-api-container
docker logs mi-api-dev
```

**Verificación:** Ahora tienes dos versiones de la API corriendo en puertos 3000 y 3001.

### Ejercicio 5: Explorar el Interior del Contenedor

#### Objetivo: Investigar cómo se ve la aplicación dentro del contenedor

```bash
# 1. Entrar al contenedor interactivamente
docker exec -it mi-api-container bash

# Dentro del contenedor, ejecutar:
whoami
pwd
ls -la
cat package.json
cat app.js
ps aux
exit

# 2. Ejecutar comandos sin entrar al contenedor
docker exec mi-api-container ls -la /app
docker exec mi-api-container cat /app/package.json
docker exec mi-api-container ps aux

# 3. Ver estadísticas de recursos
docker stats mi-api-container

# Presiona Ctrl+C para salir de stats
```

**Verificación:** Deberías ver que la aplicación está en `/app` y el proceso Node.js corriendo.

### Ejercicio 6: Gestión del Ciclo de Vida

#### Objetivo: Practicar operaciones básicas de gestión de contenedores

```bash
# 1. Ver todos los contenedores (activos e inactivos)
docker ps -a

# 2. Detener un contenedor
docker stop mi-api-dev

# 3. Verificar estado
docker ps -a

# 4. Reiniciar el contenedor
docker start mi-api-dev

# 5. Probar que volvió a funcionar
curl http://localhost:3001

# 6. Ver logs desde el reinicio
docker logs --since 2m mi-api-dev
```

### Ejercicio 7: Modificar y Reconstruir

#### Objetivo: Entender cómo los cambios afectan el build

```bash
# 1. Modificar el código de la aplicación
cat > app.js << 'EOF'
// API básica Node.js para capacitación Docker
const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.json({ 
    message: '¡Hola desde Docker! (Versión modificada)',
    version: '1.1.0',
    environment: process.env.NODE_ENV || 'production',
    timestamp: new Date().toISOString()
  });
});

app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK',
    uptime: process.uptime()
  });
});

app.get('/info', (req, res) => {
  res.json({
    node_version: process.version,
    platform: process.platform,
    memory_usage: process.memoryUsage()
  });
});

app.listen(PORT, () => {
  console.log(`Servidor ejecutándose en puerto ${PORT}`);
});
EOF

# 2. Construir nueva versión
docker build -t mi-api:v1.1 .

# Observar que reutiliza capas cacheadas hasta llegar a COPY

# 3. Ejecutar la nueva versión
docker run -d -p 3002:3000 --name mi-api-v1.1 mi-api:v1.1

# 4. Probar el nuevo endpoint
curl http://localhost:3002
curl http://localhost:3002/info


















```

**Verificación:** La nueva versión debe mostrar el mensaje modificado y el endpoint `/info`.

### Ejercicio 8: Optimización Básica

#### Objetivo: Aplicar buenas prácticas para mejorar el build

```bash
# 1. Crear un Dockerfile optimizado
cat > Dockerfile.optimized << 'EOF'
# Usar imagen base más ligera
FROM node:18-alpine

# Establecer directorio de trabajo
WORKDIR /app

# Crear usuario no-root
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodeuser -u 1001

# Copiar solo package.json primero (mejor cache)
COPY package.json ./

# Instalar dependencias
RUN npm ci --only=production

# Copiar el resto del código
COPY . .

# Cambiar al usuario no-root
USER nodeuser

# Exponer puerto
EXPOSE 3000

# Comando para ejecutar la aplicación
CMD ["npm", "start"]
EOF

# 2. Construir versión optimizada
docker build -f Dockerfile.optimized -t mi-api:optimized .

# 3. Comparar tamaños
docker images | grep mi-api

# 4. Ejecutar versión optimizada
docker run -d -p 3003:3000 --name mi-api-optimized mi-api:optimized

# 5. Verificar funcionalidad
curl http://localhost:3003
```

**Verificación:** La imagen optimizada debe ser significativamente más pequeña.

### Ejercicio 9: Limpieza y Mejores Prácticas

#### Objetivo: Limpiar recursos y aplicar orden en el desarrollo

```bash
# 1. Ver uso de espacio de Docker
docker system df

# 2. Detener todos los contenedores del ejercicio
docker stop mi-api-container mi-api-dev mi-api-v1.1 mi-api-optimized

# 3. Eliminar contenedores
docker rm mi-api-container mi-api-dev mi-api-v1.1 mi-api-optimized

# 4. Ver imágenes creadas
docker images | grep mi-api

# 5. Opcional: Limpiar imágenes no utilizadas
docker image prune

# 6. Verificar limpieza
docker ps -a
docker images
```

### Ejercicio 10: Troubleshooting Común

#### Objetivo: Practicar resolución de problemas típicos

```bash
# 1. Intentar build con error intencional
cat > Dockerfile.error << 'EOF'
FROM node:18
WORKDIR /app
COPY package-inexistente.json ./
RUN npm install
COPY . .
CMD ["npm", "start"]
EOF

docker build -f Dockerfile.error -t mi-api:error .

# Observar el error y entender por qué falla

# 2. Build con logs detallados
docker build --no-cache --progress=plain -f Dockerfile -t mi-api:debug .

# 3. Diagnosticar problemas de red/conectividad
docker run --rm mi-api:v1.0 curl --version || echo "curl no disponible"

# 4. Verificar logs si algo no funciona
docker run -d --name test-api mi-api:v1.0
docker logs test-api
docker exec test-api ps aux
docker stop test-api && docker rm test-api
```

---

## Para Instructores: Verificación y Troubleshooting

### Script de Verificación Rápida
```bash
#!/bin/bash
echo "=== Verificación Bloque 2: Dockerfile Básico ==="

# Limpiar ambiente previo
echo "Limpiando ambiente..."
docker stop test-api test-api-dev 2>/dev/null || true
docker rm test-api test-api-dev 2>/dev/null || true
docker rmi mi-api:v1.0 2>/dev/null || true

cd 2-dockerfile-basico/api-node

# Build de imagen
echo "Construyendo imagen..."
docker build -t mi-api:v1.0 .

# Verificar imagen
echo "Verificando imagen creada..."
docker images mi-api:v1.0

# Ejecutar API
echo "Ejecutando API..."
docker run -d -p 3000:3000 --name test-api mi-api:v1.0
sleep 3

# Probar endpoints
echo "Probando endpoints..."
curl -s http://localhost:3000 | grep "Hello World" && echo "Endpoint principal funcionando"
curl -s http://localhost:3000/health | grep "OK" && echo "Health check funcionando"

# Probar variables de entorno
echo "Probando variables de entorno..."
docker run -d -p 3001:3000 \
  -e NODE_ENV=development \
  --name test-api-dev \
  mi-api:v1.0

sleep 2
curl -s http://localhost:3001 && echo "Variables de entorno funcionando"

# Inspeccionar contenedor
echo "Inspeccionando contenedor..."
docker exec test-api env | grep NODE_ENV

echo "Demo completada - APIs en puerto 3000 y 3001"
```

### Puntos Clave para Destacar

#### 1. Instrucciones Dockerfile
- **FROM:** Base de la imagen (explicar layers)
- **WORKDIR:** Directorio de trabajo dentro del contenedor
- **COPY:** Optimización con package.json primero
- **RUN:** Ejecución durante build vs runtime
- **CMD vs ENTRYPOINT:** Diferencias prácticas

#### 2. Build Process
- Cache de layers (mostrar rebuild después de cambio)
- Contexto de build (todo en directorio actual)
- Tags y versioning

#### 3. Best Practices Introducidas
- Orden de instrucciones para aprovechar cache
- .dockerignore para archivos innecesarios
- Variables de entorno para configuración

### Errores Comunes Esperados

#### 1. "No such file or directory" durante COPY
**Causa:** Archivo no existe en contexto de build
**Solución:** 
```bash
# Verificar contexto
ls -la
# Verificar .dockerignore
cat .dockerignore
```

#### 2. "npm install failed" 
**Causa:** Problemas de red o dependencias
**Solución:**
```bash
# Verificar package.json
npm install --dry-run
# Build con logs detallados
docker build --no-cache -t debug .
```

#### 3. "Cannot connect to API"
**Verificar:**
```bash
# Puerto mapeado correctamente?
docker port test-api
# Contenedor corriendo?
docker ps | grep test-api
# Logs del contenedor
docker logs test-api
```

#### 4. Build muy lento primera vez
**Explicar:** Descarga de imagen base y dependencias es normal

### Tiempo Estimado Real
- **Explicación conceptos:** 25-30 min
- **Ejercicio hands-on:** 35-40 min
- **Q&A y troubleshooting:** 10-15 min
- **Total: ~75 min**

### Preparación Previa
```bash
# Pre-descargar imagen base
docker pull node:18

# Verificar archivos están en su lugar
cd 2-dockerfile-basico/api-node
ls -la package.json app.js Dockerfile .dockerignore

# Tener puertos libres
netstat -tlnp | grep ':300[0-3]' || echo "Puertos 3000-3003 libres"
```

### Comandos de Limpieza Post-Clase
```bash
# Limpiar contenedores de prueba
docker stop $(docker ps -aq --filter "name=mi-api") 2>/dev/null || true
docker rm $(docker ps -aq --filter "name=mi-api") 2>/dev/null || true

# Limpiar imágenes creadas durante ejercicios
docker rmi mi-api:v1.0 mi-api:v1.1 mi-api:optimized 2>/dev/null || true

# Restaurar app.js original si fue modificado
cd 2-dockerfile-basico/api-node
git checkout app.js 2>/dev/null || echo "app.js no en git, restaurar manualmente"
```

### Checklist de Objetivos Cumplidos

Al final de la clase, los participantes deben poder:

- [ ] Comprender qué es un Dockerfile y su propósito
- [ ] Conocer instrucciones básicas: FROM, COPY, RUN, ENV, CMD
- [ ] Entender diferencia entre CMD y ENTRYPOINT
- [ ] Construir su primera imagen personalizada con `docker build`
- [ ] Ejecutar contenedores desde su imagen personalizada
- [ ] Usar variables de entorno efectivamente
- [ ] Comprender concepto de layers y cache
- [ ] Aplicar orden correcto de instrucciones para optimización
- [ ] Usar .dockerignore para optimizar contexto de build
- [ ] Probar APIs containerizadas con curl

---
**Tips para Instructores:**
- Mostrar build verbose primera vez: `docker build --progress=plain -t mi-api .`
- Demostrar cache: Cambiar app.js y rebuild
- Explicar tamaño: `docker images` y comparar con nginx
- Mostrar layers: `docker history mi-api:v1.0`
- Enfatizar .dockerignore: Mostrar diferencia con/sin él 