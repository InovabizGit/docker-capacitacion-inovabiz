# Test y Ejercicios Prácticos - Bloque 6: Seguridad en Docker

## Duración: 45 minutos

---

## **EJERCICIO 1: Verificación Rápida del Entorno (5 min)**

### Script de Preparación y Verificación
```bash
#!/bin/bash
echo "=== VERIFICACIÓN BLOQUE 6: SEGURIDAD DOCKER ==="

cd 6-seguridad-buenas-practicas

# Verificar Docker Scout disponible
echo "1. Verificando herramientas de seguridad..."
docker scout version

```

### Comandos de Verificación
```bash
# Verificar versión de Docker
docker version

# Verificar estado del daemon
docker info | grep -i security

# Verificar que estamos en el directorio correcto
pwd
ls -la *.js dockerfile-* *.yml
```

---

## **EJERCICIO 2: Demostración Usuario Root vs No-Root (10 min)**

### Paso 1: Revisar Aplicación de Ejemplo
```bash
# Revisar la aplicación de demostración ya preparada
echo "=== REVISANDO APLICACIÓN DE SEGURIDAD ==="
echo "Contenido de app-security-demo.js:"
head -10 app-security-demo.js

echo ""
echo "Contenido de package.json:"
cat package.json

echo ""
echo "La aplicación expone información del usuario para demostrar diferencias de seguridad"
```

### Paso 2: Analizar Dockerfile INSEGURO (Usuario Root)
```bash
echo "=== ANALIZANDO DOCKERFILE INSEGURO ==="
echo "Contenido del dockerfile-inseguro:"
cat dockerfile-inseguro

echo ""
echo "PROBLEMAS IDENTIFICADOS:"
echo "1. No especifica usuario (corre como root)"
echo "2. Instala paquetes innecesarios (sudo, vim, etc.)"
echo "3. No implementa multi-stage build"
echo "4. No usa healthcheck"

# Build y test de imagen insegura
docker build -f dockerfile-inseguro -t app-insegura .

echo "=== DEMOSTRANDO PROBLEMAS DE SEGURIDAD ==="
echo "Información del usuario en contenedor inseguro:"
docker run --rm app-insegura whoami
docker run --rm app-insegura id
docker run --rm -p 3001:3000 -d --name demo-inseguro app-insegura

# Verificar la respuesta de la API
sleep 2
curl -s http://localhost:3001/ | jq '.'
```

### Paso 3: Analizar Dockerfile SEGURO (Usuario Específico)
```bash
echo "=== ANALIZANDO DOCKERFILE SEGURO ==="
echo "Contenido del dockerfile-seguro:"
head -30 dockerfile-seguro

echo ""
echo "BUENAS PRÁCTICAS IMPLEMENTADAS:"
echo "1. Multi-stage build para imagen mínima"
echo "2. Usuario específico no-root (nodeuser:1001)"
echo "3. Ownership correcto de archivos"
echo "4. Healthcheck integrado"
echo "5. Init system (dumb-init) para signal handling"
echo "6. Variables de entorno de producción"

# Build y test de imagen segura
docker build -f dockerfile-seguro -t app-segura .

echo "=== DEMOSTRANDO CONFIGURACIÓN SEGURA ==="
echo "Información del usuario en contenedor seguro:"
docker run --rm app-segura whoami
docker run --rm app-segura id

# Parar contenedor inseguro y levantar seguro
docker stop demo-inseguro
docker rm demo-inseguro

docker run --rm -p 3002:3000 -d --name demo-seguro app-segura

# Verificar la respuesta de la API segura
sleep 2
curl -s http://localhost:3002/ | jq '.'
```

### Verificación de Diferencias
```bash
# Comparar tamaños
echo "Tamaños de imágenes:"
docker images | grep -E "(app-insegura|app-segura)"
```

---

## **EJERCICIO 3: Análisis de Vulnerabilidades (15 min)**

### Paso 1: Escaneo Básico con Docker Scout
```bash
echo "=== ESCANEANDO VULNERABILIDADES ==="

# Escanear imagen insegura
echo "1. Vulnerabilidades en imagen insegura:"
docker scout cves local://app-insegura --format packages --only-severity critical,high

# Escanear imagen segura  
echo "2. Vulnerabilidades en imagen segura:"
docker scout cves local://app-segura --format packages --only-severity critical,high

### Paso 2: Análisis Detallado y Recomendaciones
```bash
# Obtener recomendaciones específicas
echo "4. Recomendaciones para imagen insegura:"
docker scout recommendations app-insegura

# Ver CVEs específicas más críticas
echo "5. CVEs críticas encontradas:"
docker scout cves local://app-segura --format sarif

# Generar reporte detallado en formato SARIF
docker scout cves local://app-segura --format sarif --output reporte-seguridad.sarif
echo "Reporte SARIF generado en reporte-seguridad.sarif"
```

### Paso 3: Uso de Trivy como Herramienta Adicional
```bash
# Usar Trivy para second opinion
echo "6. Análisis con Trivy:"
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
    aquasec/trivy:latest image --severity HIGH,CRITICAL app-insegura

# Comparar con imagen segura
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
    aquasec/trivy:latest image --severity HIGH,CRITICAL app-segura
```

---

---

## **EJERCICIO 4: Auditoría y Monitoreo (10 min)**

### Paso 1: Docker Bench Security
```bash
echo "=== EJECUTANDO DOCKER BENCH SECURITY ==="

# Ejecutar auditoría completa del sistema
docker run --rm -it \
  --pid host \
  --userns host \
  --cap-add audit_control \
  -e DOCKER_CONTENT_TRUST=$DOCKER_CONTENT_TRUST \
  -v /var/lib:/var/lib:ro \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -v /etc:/etc:ro \
  docker/docker-bench-security

# Generar reporte en archivo
docker run --rm \
  --pid host \
  --userns host \
  --cap-add audit_control \
  -v /var/lib:/var/lib:ro \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -v /etc:/etc:ro \
  -v $(pwd):/tmp \
  docker/docker-bench-security sh -c "docker-bench-security.sh > /tmp/docker-bench-report.txt"

echo "Reporte de auditoría generado en docker-bench-report.txt"
```

### Script de Limpieza
```bash
echo "=== LIMPIEZA DEL ENTORNO ==="

# Parar todos los contenedores del ejercicio
docker-compose -f docker-compose-seguro.yml down -v 2>/dev/null || true
docker stop demo-seguro 2>/dev/null || true
docker rm demo-seguro 2>/dev/null || true

# Eliminar imágenes de prueba
docker rmi app-insegura app-segura 2>/dev/null || true

# Limpiar archivos temporales generados durante ejercicios
rm -f reporte-seguridad.sarif docker-bench-report.txt
```

---

## **Recursos y Referencias Adicionales**

### Documentación Oficial
- [Docker Security Best Practices](https://docs.docker.com/develop/security-best-practices/)
- [Docker Scout Documentation](https://docs.docker.com/scout/)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)

### Herramientas Recomendadas
- **Docker Scout** - Análisis de vulnerabilidades integrado
- **Trivy** - Scanner comprehensivo de vulnerabilidades
- **Docker Bench Security** - Auditoría automática
- **Falco** - Detección de amenazas en runtime

### Comandos de Emergencia
```bash
# Si algo sale mal durante los ejercicios:

# Parar todos los contenedores
docker stop $(docker ps -aq)

# Eliminar todos los contenedores
docker rm $(docker ps -aq)

# Limpiar todo el sistema
docker system prune -a --volumes -f

# Reiniciar Docker daemon (Linux)
sudo systemctl restart docker
``` 