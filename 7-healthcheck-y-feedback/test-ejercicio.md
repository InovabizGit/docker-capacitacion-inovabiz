# Test y Ejercicios - Bloque 7: Healthcheck y Monitoreo

**Duración total:** 40 minutos  
**Objetivos:** Implementar healthchecks efectivos, configurar monitoreo y solucionar problemas comunes

---

## **EJERCICIO 1: Healthcheck Básico (10 min)**

### Paso 1: Verificar Diferencia entre "Up" y "Healthy"
```bash
echo "=== DEMOSTRACIÓN: UP vs HEALTHY ==="

# Ejecutar contenedor sin healthcheck
docker run -d --name sin-health nginx:alpine
echo "Container sin healthcheck:"
docker ps --format "table {{.Names}}\t{{.Status}}"

# El estado muestra solo "Up" - no sabemos si funciona realmente
echo "Estado: Solo sabemos que está 'Up', no si funciona correctamente"
```

### Paso 2: Implementar Healthcheck Simple
```bash
# Analizar Dockerfile con healthcheck
echo "=== DOCKERFILE CON HEALTHCHECK ==="
cat Dockerfile-healthcheck

echo ""
echo "CONFIGURACIÓN EXPLICADA:"
echo "- interval=30s: Verificar cada 30 segundos"
echo "- timeout=10s: Timeout máximo para el comando"
echo "- retries=3: 3 fallos antes de marcar unhealthy"
echo "- start-period=5s: Grace period inicial"

# Build de imagen con healthcheck
docker build -f Dockerfile-healthcheck -t nginx-con-health .
echo "Imagen con healthcheck creada"
```

### Paso 3: Verificar Estados de Healthcheck
```bash
# Ejecutar contenedor con healthcheck
docker run -d --name health-app -p 3000:3000 healthcheck-app

echo "=== MONITOREANDO ESTADOS ==="
echo "Estados posibles: starting → healthy → unhealthy"

# Monitorear cambio de estado
for i in {1..6}; do
    echo "Chequeo $i:"
    docker ps --format "table {{.Names}}\t{{.Status}}" | grep con-health
    sleep 10
done

echo ""
echo "COMPARACIÓN:"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "(sin-health|con-health)"
```

---

## **EJERCICIO 2: Aplicación con Endpoint Personalizado (10 min)**

### Paso 1: Analizar Aplicación de Demostración
```bash
echo "=== APLICACIÓN CON ENDPOINT DE HEALTH ==="

# Mostrar código de la aplicación
echo "Contenido de app-healthcheck-demo.js:"
head -30 app-healthcheck-demo.js

echo ""
echo "ENDPOINTS DISPONIBLES:"
echo "- GET / → Endpoint principal"
echo "- GET /health → Endpoint de verificación"
echo "- POST /break → Simular fallo (para testing)"
echo "- POST /fix → Restaurar funcionamiento"
```

### Paso 2: Ejecutar Aplicación con Healthcheck Personalizado
```bash
# Build de aplicación personalizada
echo "=== CONSTRUYENDO APLICACIÓN ==="
docker build -t healthcheck-app .

# Ejecutar aplicación
docker run -d --name health-app -p 3000:3000 healthcheck-app

echo "Esperando inicialización (15 segundos)..."
sleep 15

# Verificar estado inicial
echo "=== ESTADO INICIAL ==="
docker ps --format "table {{.Names}}\t{{.Status}}" | grep health-app

# Probar endpoint manualmente
echo "Respuesta del endpoint de health:"
curl -s http://localhost:3000/health | jq '.' 2>/dev/null || curl -s http://localhost:3000/health
```

### Paso 3: Simular Fallo y Recuperación
```bash
echo "=== SIMULANDO FALLO ==="

# Provocar fallo en la aplicación
curl -X POST http://localhost:3000/break
echo "Fallo simulado - la aplicación ahora fallará healthchecks"

# Monitorear cambio a unhealthy
echo "Monitoreando cambio a unhealthy (puede tomar 1-2 minutos)..."
for i in {1..8}; do
    echo "Chequeo $i/8:"
    docker ps --format "table {{.Names}}\t{{.Status}}" | grep health-app
    sleep 15
done

echo ""
echo "=== RESTAURANDO FUNCIONAMIENTO ==="
curl -X POST http://localhost:3000/fix
echo "Aplicación restaurada"

# Verificar recuperación
sleep 30
docker ps --format "table {{.Names}}\t{{.Status}}" | grep health-app
```

---

## **EJERCICIO 3: Docker Compose con Dependencias (8 min)**

### Paso 1: Analizar Configuración de Docker Compose
```bash
echo "=== DOCKER COMPOSE CON HEALTHCHECKS ==="

# Mostrar configuración
echo "Contenido de docker-compose-healthcheck.yml:"
cat docker-compose-healthcheck.yml

echo ""
echo "CONFIGURACIONES CLAVE:"
echo "- Healthcheck para base de datos"
echo "- depends_on con condition: service_healthy"
echo "- Diferentes configuraciones de timing"
echo "- Restart policies configuradas"
```

### Paso 2: Ejecutar Stack Completo
```bash
# Levantar stack con dependencias
echo "=== LEVANTANDO STACK CON DEPENDENCIAS ==="
docker-compose -f docker-compose-healthcheck.yml up -d

echo "Servicios iniciando en orden por dependencias..."
sleep 5

# Monitorear inicio de servicios
for i in {1..6}; do
    echo "=== Estado $i/6 ==="
    docker-compose -f docker-compose-healthcheck.yml ps
    sleep 10
done
```

### Paso 3: Verificar Dependencias y Funcionamiento
```bash
# Verificar que todos los servicios están healthy
echo "=== VERIFICACIÓN FINAL ==="
docker-compose -f docker-compose-healthcheck.yml ps

# Verificar conectividad
echo "Probando conectividad entre servicios:"
docker-compose -f docker-compose-healthcheck.yml exec api curl -s http://localhost:3000/health | jq '.checks'

# Ver logs de healthcheck
echo "Logs de healthcheck de la API:"
docker-compose -f docker-compose-healthcheck.yml logs api | grep -i health | tail -5
```

## **LIMPIEZA DEL ENTORNO**

### Cleanup de Contenedores y Recursos
```bash
echo "=== LIMPIEZA FINAL ==="

# Parar todos los contenedores del ejercicio
docker stop sin-health con-health health-app slow-health restart-loop 2>/dev/null || true

# Parar docker-compose
docker-compose -f docker-compose-healthcheck.yml down 2>/dev/null || true

# Remover contenedores
docker rm sin-health con-health health-app slow-health restart-loop 2>/dev/null || true

# Remover imágenes de prueba
docker rmi nginx-con-health healthcheck-app 2>/dev/null || true

echo "Limpieza completada"
echo ""
echo "RESUMEN DEL BLOQUE:"
echo "- Implementaste healthchecks básicos y personalizados"
echo "- Configuraste dependencias con Docker Compose"
echo "- Solucionaste problemas comunes"
echo "- Monitoreaste estado de contenedores automáticamente"
echo ""
echo "SIGUIENTE: Bloque 8 - Evaluación Final"
``` 