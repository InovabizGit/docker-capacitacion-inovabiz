# Archivos de Ejercicios - Bloque 7: Healthcheck y Monitoreo

Este directorio contiene archivos pre-creados para optimizar la experiencia de aprendizaje en los ejercicios de healthcheck y monitoreo.

## Archivos de Aplicación

### `app-healthcheck-demo.js`
**Propósito:** Aplicación Node.js de demostración con endpoints de health  
**Contenido:**
- Endpoint principal (`/`) con información básica
- Endpoint de health completo (`/health`) con verificaciones múltiples
- Endpoint de health simple (`/health/simple`) para healthchecks básicos
- Endpoints de control (`/break`, `/break/db`, `/fix`) para simular fallos
- Endpoint de información del sistema (`/info`)

**Características:**
- Estado interno simulado (aplicación, base de datos)
- Logging detallado para debugging
- Respuestas JSON estructuradas
- Múltiples niveles de verificación

### `package.json`
**Propósito:** Configuración de dependencias para la aplicación de demo  
**Contenido:**
- Dependencia de Express.js
- Scripts npm para desarrollo y health check
- Metadatos del proyecto

## Archivos de Configuración Docker

### `Dockerfile-healthcheck`
**Propósito:** Imagen Docker optimizada con healthcheck configurado  
**Características:**
- Base Node.js Alpine (ligera)
- Instalación de curl para healthcheck
- Usuario no root (seguridad)
- Healthcheck con configuración óptima:
  - `interval=30s` - Verificación cada 30 segundos
  - `timeout=10s` - Timeout máximo
  - `retries=3` - Intentos antes de marcar unhealthy
  - `start-period=5s` - Grace period para startup

### `docker-compose-healthcheck.yml`
**Propósito:** Stack completo con dependencias y healthchecks  
**Servicios incluidos:**
- **api**: Aplicación principal con healthcheck personalizado
- **database**: PostgreSQL con healthcheck de conexión
- **cache**: Redis con healthcheck de ping
- **proxy**: Nginx como proxy reverso
- **monitor**: Contenedor de monitoreo automático

**Características avanzadas:**
- Dependencias con `condition: service_healthy`
- Límites de recursos configurados
- Redes segmentadas (frontend/backend)
- Restart policies apropiadas

### `nginx.conf`
**Propósito:** Configuración de proxy reverso para Nginx  
**Contenido:**
- Upstream hacia la API
- Endpoint de health específico para nginx
- Headers de proxy apropiados

## Scripts de Utilidad

### `healthcheck-custom.sh`
**Propósito:** Script de healthcheck personalizado que no depende de curl  
**Verificaciones incluidas:**
1. **Proceso principal** - Verifica que el proceso esté corriendo
2. **Puerto TCP** - Conectividad básica al puerto
3. **Endpoint HTTP** - Respuesta HTTP usando wget/curl/fallback
4. **Memoria** - Uso de memoria del sistema
5. **Disco** - Espacio disponible en disco

**Características:**
- Compatible con múltiples herramientas (wget, curl, nc)
- Fallbacks robustos
- Logging detallado con timestamps
- Exit codes apropiados para Docker

### `monitor-health.sh`
**Propósito:** Script de monitoreo automatizado para healthchecks  
**Funcionalidades:**
- Monitoreo continuo o verificación única
- Detección automática de contenedores con healthcheck
- Alertas por Slack webhook
- Alertas por email (si está configurado)
- Logging con colores y timestamps
- Rotación automática de logs
- Reportes de estado detallados

**Modos de uso:**
```bash
./monitor-health.sh                    # Monitoreo continuo
./monitor-health.sh check              # Verificación única
./monitor-health.sh -i 60 monitor      # Intervalo personalizado
```

## Uso en Ejercicios

### Ejercicio 1: Healthcheck Básico
**Archivos utilizados:**
- `Dockerfile-healthcheck` - Para demostrar configuración
- Scripts para mostrar diferencia entre "up" y "healthy"

### Ejercicio 2: Aplicación Personalizada
**Archivos utilizados:**
- `app-healthcheck-demo.js` - Aplicación completa lista para usar
- `package.json` - Dependencias configuradas
- `Dockerfile-healthcheck` - Build optimizado

### Ejercicio 3: Docker Compose
**Archivos utilizados:**
- `docker-compose-healthcheck.yml` - Stack completo
- `nginx.conf` - Configuración de proxy
- Todos los archivos anteriores como dependencias

### Ejercicio 4: Troubleshooting
**Archivos utilizados:**
- `healthcheck-custom.sh` - Alternativa sin curl
- Ejemplos de configuraciones problemáticas

### Ejercicio 5: Monitoreo
**Archivos utilizados:**
- `monitor-health.sh` - Monitoreo automatizado
- Todos los contenedores previos para monitorear

## Ventajas de Archivos Pre-creados

### Para Estudiantes:
- **Enfoque en conceptos** en lugar de sintaxis
- **Tiempo optimizado** sin crear archivos desde cero
- **Ejemplos realistas** con mejores prácticas
- **Experiencia fluida** sin errores de tipeo

### Para Instructores:
- **Demostraciones consistentes** cada vez
- **Tiempo de setup reducido** significativamente
- **Troubleshooting minimizado** de errores de sintaxis
- **Calidad garantizada** de ejemplos

## Comandos de Setup Rápido

```bash
# Hacer scripts ejecutables
chmod +x healthcheck-custom.sh monitor-health.sh

# Verificar archivos
ls -la *.js *.json *.yml *.sh

# Test básico de aplicación
node app-healthcheck-demo.js

# Build de imagen
docker build -f Dockerfile-healthcheck -t healthcheck-demo .

# Stack completo
docker-compose -f docker-compose-healthcheck.yml up -d
```

## Archivos de Soporte

Estos archivos están diseñados para ser reutilizables en diferentes contextos de capacitación y proporcionan una base sólida para experimentación y aprendizaje práctico.

**Nota:** Todos los archivos incluyen comentarios explicativos y están optimizados para propósitos educativos. 