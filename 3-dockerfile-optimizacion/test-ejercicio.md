# Guía de Ejercicios - Bloque 3: Optimización de Imágenes

## Para Estudiantes: Ejercicios Paso a Paso

### Preparación Inicial

Antes de comenzar, asegúrate de tener las imágenes del bloque anterior y estar en el directorio correcto:

```bash
# Verificar Docker está funcionando
docker --version
docker info

# Verificar que tenemos la imagen del bloque 2
docker images mi-api:v1.0 || echo "Necesitas completar el bloque 2 primero"

# Navegar al directorio del ejercicio
cd 3-dockerfile-optimizacion/api-node-optimizada

# Verificar archivos del proyecto optimizado
ls -la
```

Deberías ver estos archivos:
- `package.json` (dependencias del proyecto)
- `app.js` (código de la API optimizada)
- `Dockerfile` (multistage build optimizado)
- `.dockerignore` (exclusiones optimizadas)

### Ejercicio 1: Análisis de la Imagen No Optimizada

#### Objetivo: Establecer baseline para comparación

```bash
# 1. Ir al directorio del bloque 2 (imagen no optimizada)
cd ../../2-dockerfile-basico/api-node

# 2. Construir imagen no optimizada (si no existe)
docker build -t mi-api:no-optimizada .

# 3. Analizar métricas de la imagen no optimizada
docker images mi-api:no-optimizada

# 4. Ver las capas de la imagen no optimizada
docker history mi-api:no-optimizada

# 5. Analizar tamaño específico
docker images mi-api:no-optimizada --format "Tamaño: {{.Size}}"

# 6. Ver uso de espacio total
docker system df
```

**Verificación:** Toma nota del tamaño de la imagen no optimizada (probablemente ~1.1GB).

### Ejercicio 2: Explorar el Dockerfile Optimizado

#### Objetivo: Entender las técnicas de optimización aplicadas

```bash
# 1. Volver al directorio optimizado
cd ../../3-dockerfile-optimizacion/api-node-optimizada

# 2. Analizar el Dockerfile optimizado
cat Dockerfile

# 3. Comparar con el Dockerfile no optimizado
diff ../../2-dockerfile-basico/api-node/Dockerfile ./Dockerfile || echo "Archivos diferentes (esperado)"

# 4. Revisar el .dockerignore optimizado
cat .dockerignore

# 5. Revisar el código de la API optimizada
cat app.js
```

**Nota las diferencias:**
- Multistage build (3 etapas)
- Imagen base Alpine
- Usuario no root
- Variables de entorno optimizadas
- Copy selectivo entre etapas

### Ejercicio 3: Construir la Imagen Optimizada

#### Objetivo: Crear la versión optimizada y observar el proceso

```bash
# 1. Construir imagen optimizada con logs detallados
docker build --progress=plain -t mi-api:optimizada .

# Durante el build observarás:
# - Etapa dependencies: Solo deps de producción
# - Etapa builder: Build completo
# - Etapa runtime: Imagen final mínima

# 2. Verificar que se creó correctamente
docker images mi-api:optimizada

# 3. Analizar las capas de la imagen optimizada
docker history mi-api:optimizada
```

**Verificación:** La imagen optimizada debe ser significativamente más pequeña (~180MB vs ~1.1GB).

### Ejercicio 4: Comparación Detallada de Métricas

#### Objetivo: Cuantificar las mejoras de optimización

```bash
# 1. Comparar tamaños lado a lado
echo "=== COMPARACIÓN DE TAMAÑOS ==="
docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}" | grep mi-api

# 2. Analizar diferencia de layers
echo ""
echo "=== LAYERS NO OPTIMIZADA ==="
docker history mi-api:no-optimizada --format "table {{.Size}}\t{{.CreatedBy}}" | head -8
echo ""
echo "=== LAYERS OPTIMIZADA ==="
docker history mi-api:optimizada --format "table {{.Size}}\t{{.CreatedBy}}" | head -8

# 3. Calcular reducción porcentual
echo ""
echo "=== MÉTRICAS ==="
SIZE_NO_OPT=$(docker images mi-api:no-optimizada --format "{{.Size}}")
SIZE_OPT=$(docker images mi-api:optimizada --format "{{.Size}}")
echo "Imagen no optimizada: $SIZE_NO_OPT"
echo "Imagen optimizada: $SIZE_OPT"

# 4. Comparar con imagen base
docker images node:18 --format "Imagen base node:18: {{.Size}}"
docker images node:18-alpine --format "Imagen base node:18-alpine: {{.Size}}"
```

**Verificación:** Deberías ver una reducción de más del 80% en el tamaño.

### Ejercicio 5: Probar Funcionalidad de Ambas Versiones

#### Objetivo: Verificar que la optimización no rompe funcionalidad

```bash
# 1. Ejecutar versión no optimizada
docker run -d -p 3000:3000 --name api-no-opt mi-api:no-optimizada

# 2. Ejecutar versión optimizada
docker run -d -p 3002:3000 --name api-optimizada mi-api:optimizada

# 3. Verificar que ambas están corriendo
docker ps

# 4. Probar endpoint principal de ambas
echo "=== PROBANDO VERSIÓN NO OPTIMIZADA ==="
curl http://localhost:3000
echo ""
echo ""
echo "=== PROBANDO VERSIÓN OPTIMIZADA ==="
curl http://localhost:3002

# 5. Probar endpoints específicos de la versión optimizada
echo ""
echo "=== ENDPOINT /metrics (solo optimizada) ==="
curl http://localhost:3002/metrics

echo ""
echo "=== ENDPOINT /info ==="
curl http://localhost:3002/info
```

**Verificación:** Ambas APIs deben funcionar correctamente, pero la optimizada tiene endpoints adicionales.

### Ejercicio 6: Análisis de Seguridad

#### Objetivo: Verificar mejoras de seguridad en la imagen optimizada

```bash
# 1. Verificar usuario en contenedor no optimizado
echo "=== USUARIO EN VERSIÓN NO OPTIMIZADA ==="
docker exec api-no-opt whoami
docker exec api-no-opt id

# 2. Verificar usuario en contenedor optimizado
echo ""
echo "=== USUARIO EN VERSIÓN OPTIMIZADA ==="
docker exec api-optimizada whoami
docker exec api-optimizada id

# 3. Verificar procesos ejecutándose
echo ""
echo "=== PROCESOS NO OPTIMIZADA ==="
docker exec api-no-opt ps aux

echo ""
echo "=== PROCESOS OPTIMIZADA ==="
docker exec api-optimizada ps aux

# 4. Verificar diferencias en el sistema de archivos
echo ""
echo "=== SISTEMA DE ARCHIVOS NO OPTIMIZADA ==="
docker exec api-no-opt ls -la /

echo ""
echo "=== SISTEMA DE ARCHIVOS OPTIMIZADA ==="
docker exec api-optimizada ls -la /
```

**Verificación:** La versión optimizada debe ejecutarse con usuario no root (UID 1001) y tener menos componentes del sistema.

### Ejercicio 7: Análisis de Performance

#### Objetivo: Medir diferencias de rendimiento

```bash
# 1. Comparar tiempo de startup
echo "=== TIEMPO DE STARTUP NO OPTIMIZADA ==="
time docker run --rm mi-api:no-optimizada node --version

echo ""
echo "=== TIEMPO DE STARTUP OPTIMIZADA ==="
time docker run --rm mi-api:optimizada node --version

# 2. Comparar uso de recursos en tiempo real
echo ""
echo "=== USO DE RECURSOS ==="
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" api-no-opt api-optimizada

# 3. Probar tiempo de descarga (simulado)
echo ""
echo "=== SIMULACIÓN TIEMPO DESCARGA ==="
echo "Imagen no optimizada tardaría: ~3-5 minutos en red lenta"
echo "Imagen optimizada tardaría: ~30-60 segundos en red lenta"

# 4. Verificar endpoints con tiempo de respuesta
echo ""
echo "=== TIEMPO DE RESPUESTA ==="
time curl -s http://localhost:3000 > /dev/null
time curl -s http://localhost:3002 > /dev/null
```

**Verificación:** La versión optimizada debe usar menos memoria y responder más rápido.

### Ejercicio 8: Análisis Avanzado con Docker History

#### Objetivo: Entender en detalle las diferencias de construcción

```bash
# 1. Analizar cada layer de la imagen no optimizada
echo "=== ANALYSIS DETALLADO NO OPTIMIZADA ==="
docker history mi-api:no-optimizada --format "table {{.CreatedBy}}\t{{.Size}}" --no-trunc

# 2. Analizar cada layer de la imagen optimizada
echo ""
echo "=== ANALYSIS DETALLADO OPTIMIZADA ==="
docker history mi-api:optimizada --format "table {{.CreatedBy}}\t{{.Size}}" --no-trunc

# 3. Identificar los layers más pesados
echo ""
echo "=== LAYERS MÁS PESADOS NO OPTIMIZADA ==="
docker history mi-api:no-optimizada --format "{{.Size}}\t{{.CreatedBy}}" | sort -hr | head -5

echo ""
echo "=== LAYERS MÁS PESADOS OPTIMIZADA ==="
docker history mi-api:optimizada --format "{{.Size}}\t{{.CreatedBy}}" | sort -hr | head -5
```

### Ejercicio 9: Optimización Adicional

#### Objetivo: Experimentar con optimizaciones extras

```bash
# 1. Crear versión ultra-optimizada
cat > Dockerfile.ultra << 'EOF'
# Dockerfile ultra-optimizado
FROM node:18-alpine AS dependencies
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production && \
    npm cache clean --force && \
    rm -rf /tmp/*

FROM node:18-alpine AS runtime
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodeuser -u 1001 && \
    apk del --no-cache npm

WORKDIR /app
ENV NODE_ENV=production
ENV NPM_CONFIG_LOGLEVEL=warn

COPY --from=dependencies --chown=nodeuser:nodejs /app/node_modules ./node_modules
COPY --chown=nodeuser:nodejs package*.json app.js ./

USER nodeuser
EXPOSE 3000
CMD ["node", "app.js"]
EOF

# 2. Construir versión ultra-optimizada
docker build -f Dockerfile.ultra -t mi-api:ultra .

# 3. Comparar tamaños
docker images | grep mi-api

# 4. Probar funcionalidad
docker run -d -p 3003:3000 --name api-ultra mi-api:ultra
curl http://localhost:3003
```

**Verificación:** La versión ultra debe ser aún más pequeña.

### Ejercicio 10: Limpieza y Benchmarking Final

#### Objetivo: Consolidar aprendizajes y limpiar el ambiente

```bash
# 1. Resumen final de todas las imágenes
echo "=== RESUMEN FINAL ==="
docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}" | grep -E "(mi-api|node:18)"

# 2. Calcular mejoras totales
echo ""
echo "=== CÁLCULO DE MEJORAS ==="
echo "Imagen base (node:18): $(docker images node:18 --format '{{.Size}}')"
echo "No optimizada: $(docker images mi-api:no-optimizada --format '{{.Size}}')"
echo "Optimizada: $(docker images mi-api:optimizada --format '{{.Size}}')"
echo "Ultra-optimizada: $(docker images mi-api:ultra --format '{{.Size}}' 2>/dev/null || echo 'N/A')"

# 3. Ver uso total de espacio
docker system df

# 4. Detener todos los contenedores del ejercicio
docker stop api-no-opt api-optimizada api-ultra 2>/dev/null || true

# 5. Eliminar contenedores
docker rm api-no-opt api-optimizada api-ultra 2>/dev/null || true

# 6. Opcional: Limpiar imágenes de prueba
echo ""
echo "Para limpiar las imágenes (opcional):"
echo "docker rmi mi-api:no-optimizada mi-api:optimizada mi-api:ultra"

# 7. Verificar limpieza
docker ps -a | grep mi-api || echo "Contenedores limpiados correctamente"
```

---

## Para Instructores: Verificación y Troubleshooting

### Script de Verificación Rápida
```bash
#!/bin/bash
echo "=== Verificación Bloque 3: Optimización de Imágenes ==="

# Limpiar ambiente previo
echo "Limpiando ambiente..."
docker stop api-optimizada api-no-opt 2>/dev/null || true
docker rm api-optimizada api-no-opt 2>/dev/null || true

# Build imagen no optimizada
echo "Construyendo imagen NO optimizada..."
cd 2-dockerfile-basico/api-node
time docker build -t mi-api:no-optimizada .
SIZE_NO_OPT=$(docker images mi-api:no-optimizada --format "{{.Size}}")

# Build imagen optimizada
echo "Construyendo imagen OPTIMIZADA..."
cd ../../3-dockerfile-optimizacion/api-node-optimizada
time docker build -t mi-api:optimizada .
SIZE_OPT=$(docker images mi-api:optimizada --format "{{.Size}}")

# Comparación de tamaños
echo ""
echo "COMPARACIÓN DE RESULTADOS:"
echo "================================================"
docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}" | grep mi-api
echo ""

# Análisis de layers
echo "Análisis de layers:"
echo "--- NO OPTIMIZADA ---"
docker history mi-api:no-optimizada --human=false --format "table {{.Size}}\t{{.CreatedBy}}" | head -5
echo ""
echo "--- OPTIMIZADA ---"
docker history mi-api:optimizada --human=false --format "table {{.Size}}\t{{.CreatedBy}}" | head -5
echo ""

# Probar ambas funcionalmente
echo "Probando funcionalidad..."
docker run -d -p 3000:3000 --name api-no-opt mi-api:no-optimizada
docker run -d -p 3002:3000 --name api-optimizada mi-api:optimizada
sleep 3

# Verificar endpoints
curl -s http://localhost:3000 | grep "Hello World" && echo "API no optimizada funcionando"
curl -s http://localhost:3002 | grep "Hello World" && echo "API optimizada funcionando"

# Comparar uso de recursos
echo ""
echo "Uso de recursos:"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" api-no-opt api-optimizada

echo ""
echo "RESUMEN:"
echo "Imagen no optimizada: $SIZE_NO_OPT"
echo "Imagen optimizada: $SIZE_OPT"
echo "APIs funcionando en puertos 3000 (no-opt) y 3002 (opt)"
```

### Métricas Objetivo de Optimización

#### Esperado vs Real:
| Métrica | Imagen Base (node:18) | No Optimizada | Optimizada | Mejora |
|---------|----------------------|---------------|------------|--------|
| **Tamaño** | ~1.1GB | ~1.1GB | ~180MB | 85% menor |
| **Layers** | ~15 | ~20 | ~8 | 60% menos |
| **Superficie ataque** | Alta | Alta | Baja | 70% menos |
| **Tiempo pull** | 3-5min | 3-5min | 45-90seg | 75% menos |

### Puntos Clave para Destacar

#### 1. Multistage Builds
- **Separación clara:** build vs runtime
- **Copy selectivo:** solo lo necesario en imagen final
- **Múltiples FROM:** cada etapa independiente

#### 2. Imagen Base Alpine
- **Tamaño:** 5MB vs 200MB+ de Ubuntu-based
- **Seguridad:** Menos componentes instalados
- **Performance:** Menos overhead

#### 3. Usuario No Root
- **Seguridad:** Principio de menor privilegio
- **Buena práctica:** Crear usuario específico
- **Compliance:** Muchas organizaciones lo requieren

#### 4. Optimizaciones npm
- `npm ci --only=production`: Solo deps de prod
- `npm cache clean --force`: Limpiar cache
- Variables ENV para reducir output

### Errores Comunes Esperados

#### 1. "Permission denied" con usuario no root
**Causa:** Archivos copiados como root, usuario no puede acceder
**Solución:**
```dockerfile
# Cambiar ownership después de copiar
COPY --from=builder --chown=nodeuser:nodejs /app/*.js ./
# O usar USER root temporalmente para setup
```

#### 2. "Module not found" en imagen optimizada
**Causa:** Dependencia de desarrollo requerida en runtime
**Solución:**
```bash
# Verificar que esté en dependencies, no devDependencies
# Revisar que COPY --from= copie lo correcto
```

#### 3. Multistage no reduce tamaño esperado
**Causa:** Copia completa de etapa anterior
**Verificar:**
```dockerfile
# MALO
COPY --from=builder /app .

# BUENO  
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package.json ./
```

#### 4. "sh not found" en Alpine
**Causa:** Alpine usa ash, no bash
**Solución:**
```dockerfile
# Usar sh o instalar bash
RUN apk add --no-cache bash
```

### Tiempo Estimado Real
- **Explicación optimización:** 20-25 min
- **Ejercicio multistage:** 30-35 min
- **Comparación y análisis:** 15-20 min
- **Q&A:** 5-10 min
- **Total: ~75 min**

### Preparación Previa
```bash
# Pre-descargar imágenes
docker pull node:18
docker pull node:18-alpine

# Verificar imagen del bloque 2 existe
docker images mi-api:v1.0 || echo "Necesita imagen del bloque 2"

# Asegurar archivos optimizados están listos
cd 3-dockerfile-optimizacion/api-node-optimizada
ls -la Dockerfile .dockerignore package.json app.js
```

### Comandos de Limpieza Post-Clase
```bash
# Limpiar contenedores
docker stop $(docker ps -aq --filter "name=api-") 2>/dev/null || true
docker rm $(docker ps -aq --filter "name=api-") 2>/dev/null || true

# Opcional: limpiar imágenes de prueba
docker rmi mi-api:no-optimizada mi-api:optimizada mi-api:ultra 2>/dev/null || true

# Limpiar builder cache
docker builder prune -f
```

### Checklist de Objetivos Cumplidos

Al final de la clase, los participantes deben poder:

- [ ] Comprender el impacto de optimización (>70% reducción de tamaño)
- [ ] Implementar multistage builds correctamente
- [ ] Usar imagen base Alpine efectivamente
- [ ] Aplicar usuario no root para seguridad
- [ ] Limpiar archivos temporales en misma capa
- [ ] Comprender trade-offs de cada optimización
- [ ] Comparar métricas antes vs después cuantitativamente
- [ ] Identificar layers pesados en imágenes
- [ ] Optimizar .dockerignore para mejor performance
- [ ] Aplicar variables de entorno optimizadas

---
**Tips para Instructores:**
- Mostrar diferencia dramática de tamaños visualmente
- Demostrar seguridad comparando usuarios (root vs no-root)
- Enfatizar que optimización es proceso iterativo
- Usar `docker system df` para mostrar uso total de espacio
- Destacar que Alpine no siempre es compatible (mencionar musl vs glibc) 