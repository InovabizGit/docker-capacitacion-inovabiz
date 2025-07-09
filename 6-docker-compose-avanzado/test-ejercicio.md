# Ejercicios Prácticos - Bloque 6: Docker Compose Production-Ready

**Duración:** 90 minutos  
**Objetivo:** Dominar técnicas avanzadas de Docker Compose para arquitecturas production-ready

## Preparación Inicial

Todos los archivos necesarios ya están creados. Solo necesitas configurar el entorno:

```bash
# Copiar archivo de configuración
cp env-example .env

# Opcional: Personalizar configuración
# nano .env  # Editar puertos, passwords, etc.
```

## Ejercicio 1: Stack Base Completo

**Objetivo:** Desplegar stack completo con API, Frontend, Database y Cache usando perfiles.

### Comandos del Estudiante
```bash
# Verificar estructura de archivos creados
ls -la app/api/
ls -la app/frontend/
ls -la infrastructure/

# Verificar configuración del compose
cat compose/docker-compose.yml | grep -A 5 profiles

# Iniciar solo la base de datos y cache
cd compose
docker-compose --profile db --profile cache up -d

# Verificar que están corriendo
docker-compose ps

# Ver logs de inicialización de base de datos
docker-compose logs database

# Verificar health checks
docker-compose ps --filter "health=healthy"

# Detener para siguiente ejercicio
docker-compose down
```

## Ejercicio 2: Deployment por Perfiles

**Objetivo:** Experimentar con diferentes perfiles para deploys incrementales.

### Comandos del Estudiante
```bash
# Deploy incremental - solo backend
docker-compose --profile api --profile db --profile cache up -d

# Verificar que API se conecta a BD
curl http://localhost:3000/health
curl http://localhost:3000/api/users

# Agregar frontend y load balancer
docker-compose --profile full up -d

# Verificar acceso completo
curl http://localhost/health
curl http://localhost/api/users

# Ver distribución de carga (múltiples requests)
for i in {1..10}; do 
  curl -s http://localhost/api/users | grep server
  sleep 0.5
done

# Ver escalado de API (2 réplicas por defecto)
docker-compose ps api
```

## Ejercicio 3: Monitoreo y Métricas

**Objetivo:** Activar stack de monitoreo y analizar métricas de producción.

### Comandos del Estudiante
```bash
# Agregar monitoreo al stack existente
docker-compose --profile full --profile monitoring up -d

# Verificar todos los servicios
docker-compose ps

# Acceder a métricas de API
curl http://localhost/metrics

# Verificar Prometheus targets
curl -s http://localhost:9090/api/v1/targets | grep -o '"health":"[^"]*"'

# Verificar Grafana
curl http://localhost:3001/api/health

# Generar tráfico para métricas
./scripts/load-test.sh --duration 30 --users 5

# Visualizar métricas en tiempo real
echo "Abre en navegador:"
echo "- Prometheus: http://localhost:9090"
echo "- Grafana: http://localhost:3001 (admin/admin123)"
echo "- Frontend: http://localhost"
```

## Ejercicio 4: Scaling y Alta Disponibilidad

**Objetivo:** Experimentar con scaling manual y automático basado en métricas.

### Comandos del Estudiante
```bash
# Ver estado actual de réplicas
docker-compose ps api

# Scaling manual - aumentar a 4 réplicas
docker-compose up -d --scale api=4

# Verificar distribución de carga
for i in {1..20}; do 
  curl -s http://localhost/api/users | grep server
done | sort | uniq -c

# Probar auto-scaling (en background)
./scripts/scale.sh --service api --max 5 --cpu-up 60 &
SCALE_PID=$!

# Generar carga para activar scaling
./scripts/load-test.sh --duration 60 --users 15 &

# Monitorear scaling en otra terminal
watch 'docker-compose ps api'

# Detener auto-scaling después del test
kill $SCALE_PID
wait

# Ver resultado final
docker-compose ps api
```

## Ejercicio 5: Testing de Performance

**Objetivo:** Realizar testing exhaustivo de rendimiento y identificar bottlenecks.

### Comandos del Estudiante
```bash
# Test de carga básico
./scripts/load-test.sh simple --users 10 --duration 30

# Test de stress en endpoint específico
./scripts/load-test.sh stress --endpoint /api/users --requests 500

# Test de base de datos
./scripts/load-test.sh database

# Suite completa de performance
./scripts/load-test.sh full

# Monitorear recursos durante test
./scripts/load-test.sh monitor --duration 60 &
MONITOR_PID=$!

# Generar carga simultánea
for i in {1..3}; do
  ./scripts/load-test.sh simple --users 5 --duration 45 &
done

wait

# Detener monitoreo
kill $MONITOR_PID 2>/dev/null || true

# Analizar métricas post-test
echo "Verificar métricas en Prometheus:"
echo "Query: rate(http_request_duration_seconds_count[5m])"
```

## Ejercicio 6: Security Hardening

**Objetivo:** Validar configuraciones de seguridad implementadas en el stack.

### Comandos del Estudiante
```bash
# Verificar usuarios no-root
docker-compose exec api whoami
docker-compose exec frontend whoami

# Verificar redes aisladas
docker network ls | grep docker-compose

# Inspeccionar red backend (interna)
docker network inspect compose_backend

# Verificar que frontend no puede acceder directamente a BD
docker-compose exec frontend nslookup database || echo "✅ BD no accesible desde frontend"

# Verificar health checks
docker-compose ps --format "table {{.Names}}\t{{.Status}}"

# Verificar SSL certificates (si están configurados)
ls -la infrastructure/nginx/ssl/ || echo "⚠️ SSL certificates no configurados"

# Test de seguridad básico
echo "Verificando headers de seguridad..."
curl -I http://localhost | grep -E "(X-Frame-Options|X-Content-Type-Options)"
```

## Ejercicio 7: Rolling Deployments

**Objetivo:** Realizar deployments sin downtime usando el script automatizado.

### Comandos del Estudiante
```bash
# Ver script de deployment
cat scripts/deploy.sh | head -20

# Preparar nuevo "deployment" (simular cambio)
echo 'console.log("API v1.1 deployed!");' >> app/api/app.js

# Rebuild imagen local
docker-compose build api

# Rolling deployment automatizado
./scripts/deploy.sh --profile full --test

# Verificar que no hubo downtime
echo "Verificando continuidad de servicio..."
for i in {1..30}; do
  curl -s http://localhost/api/info || echo "❌ Downtime detectado en $i"
  sleep 1
done

# Verificar nueva versión desplegada
docker-compose logs api | tail -10

# Ver estado final
docker-compose ps
```

## Ejercicio 8: Backup y Recovery

**Objetivo:** Implementar y probar estrategias de backup automático.

### Comandos del Estudiante
```bash
# Crear datos de prueba primero
curl -X POST http://localhost/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@backup.com"}'

# Verificar datos
curl http://localhost/api/users

# Ejecutar backup completo
./scripts/backup.sh

# Ver backups creados
ls -la backups/
LATEST_BACKUP=$(ls -1t backups/ | head -n1)
echo "Último backup: $LATEST_BACKUP"

# Inspeccionar contenido del backup
ls -la "backups/$LATEST_BACKUP"

# Ver manifest del backup
cat "backups/$LATEST_BACKUP"/*.txt

# Simular disaster (CUIDADO: esto elimina datos)
echo "⚠️ Simulando desastre (eliminar contenedores)..."
docker-compose down -v

# Recovery automático
./scripts/backup.sh restore --file "backups/$LATEST_BACKUP"

# Verificar recovery
docker-compose --profile full up -d
sleep 30
curl http://localhost/api/users | grep "Test User" && echo "✅ Recovery exitoso"
```

## Ejercicio 9: Debugging y Troubleshooting

**Objetivo:** Usar herramientas de debugging para diagnosticar problemas comunes.

### Comandos del Estudiante
```bash
# Ver logs agregados de todos los servicios
docker-compose logs --tail=50

# Logs en tiempo real (en background)
docker-compose logs -f &
LOGS_PID=$!

# Simular problema de memoria
curl http://localhost/api/stress?duration=5000

# Ver recursos en tiempo real
docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"

# Detener logs
kill $LOGS_PID

# Inspeccionar servicio específico
docker-compose exec api ps aux
docker-compose exec api netstat -tulpn

# Ver health check status
docker inspect $(docker-compose ps -q api) | grep -A 5 '"Health"'

# Debugging de red
docker-compose exec api nslookup database
docker-compose exec api ping -c 3 cache

# Ver métricas de errores
curl -s http://localhost/metrics | grep error
```

## Ejercicio 10: Production Readiness Check

**Objetivo:** Validar que el stack cumple todos los requisitos de producción.

### Comandos del Estudiante
```bash
# Ejecutar checklist automático completo
./scripts/production-checklist.sh

# Verificar performance bajo carga
echo "=== TEST DE STRESS FINAL ==="

# Lanzar monitoreo continuo
docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" &
STATS_PID=$!

# Test de carga sostenida
./scripts/load-test.sh full &
LOAD_PID=$!

# Verificar que servicios siguen healthy durante carga
for i in {1..12}; do
  echo "=== Minuto $i ==="
  docker-compose ps --format "table {{.Names}}\t{{.Status}}" | grep healthy
  sleep 5
done

# Detener tests
kill $LOAD_PID $STATS_PID 2>/dev/null || true

# Resumen final completo
echo "=== RESUMEN FINAL BLOQUE 6 ==="
echo "✅ Stack production-ready validado"
echo "✅ Profiles y scaling funcionales"
echo "✅ Monitoreo con Prometheus/Grafana"
echo "✅ Security hardening implementado"
echo "✅ Rolling deployments sin downtime"
echo "✅ Backup/recovery automatizado"
echo "✅ Performance testing validado"
echo "✅ Load balancing y alta disponibilidad"

echo ""
echo "🌐 URLS DE ACCESO:"
echo "- Aplicación: http://localhost"
echo "- API Health: http://localhost/health"
echo "- Prometheus: http://localhost:9090"
echo "- Grafana: http://localhost:3001 (admin/admin123)"

echo ""
echo "📋 COMANDOS ÚTILES:"
echo "- Ver servicios: docker-compose ps"
echo "- Logs: docker-compose logs -f [servicio]"
echo "- Scaling: docker-compose up -d --scale api=X"
echo "- Detener todo: docker-compose down"
echo "- Backup: ./scripts/backup.sh"
echo "- Load test: ./scripts/load-test.sh"

echo ""
echo "🎓 ¡BLOQUE 6 COMPLETADO EXITOSAMENTE!"
```

**¡Felicidades!** Has completado el bloque más avanzado de Docker Compose, implementando un stack production-ready completo con todas las mejores prácticas de la industria. 