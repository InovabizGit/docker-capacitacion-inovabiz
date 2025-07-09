# Ejercicios Prácticos - Bloque 5: Configuración Avanzada con Docker Compose

**Duración:** 45 minutos  
**Objetivo:** Dominar la integración de variables de entorno con Docker Compose y gestión avanzada de volúmenes

**REQUISITO PREVIO:** Tener completado el Bloque 4 con el stack docker-compose funcionando

## Ejercicio 1: Continuidad desde el Bloque 4

**Objetivo:** Verificar que el stack del bloque 4 sigue funcionando y preparar la base para agregar variables de entorno.

### Comandos del Estudiante
```bash
# Verificar que el stack del bloque 4 esté funcionando
cd ../4-docker-compose-basico
docker-compose ps

# Si no está corriendo, levantarlo
docker-compose up -d

# Verificar conectividad básica
curl -s http://localhost/health

# Navegar al bloque 5 manteniendo el stack corriendo
cd ../5-entornos-y-volumenes

# Verificar archivos del bloque 5
ls -la
cat env-example
```

## Ejercicio 2: Configuración Base de Variables de Entorno

**Objetivo:** Crear archivo .env personalizado y entender la estructura de variables de entorno para Docker Compose.

### Comandos del Estudiante
```bash
# Crear archivo .env desde el template
cat env-example
cp env-example .env

# Editar .env para personalizar configuración
nano .env
# Cambiar NODE_ENV a development
# Personalizar SECRET_KEY
# Verificar DATABASE_URL coincide con el stack del bloque 4

# Verificar variables definidas
cat .env | grep -v '^#' | grep -v '^$'

# Probar carga de variables con docker
docker run --rm --env-file .env alpine env | grep NODE_ENV
docker run --rm --env-file .env alpine env | grep DB_HOST

# Probar interpolación de variables con Docker Compose
echo "
services:
  test:
    image: alpine
    environment:
      - NODE_ENV=\${NODE_ENV}
      - API_PORT=\${API_PORT}
    command: ['sh', '-c', 'echo NODE_ENV=\$NODE_ENV && echo API_PORT=\$API_PORT && echo DB_HOST=\$DB_HOST']" > test-compose.yml

docker-compose -f test-compose.yml config
docker-compose -f test-compose.yml rm
rm test-compose.yml
```

## Ejercicio 3: Integración con Docker Compose

**Objetivo:** Modificar el stack del bloque 4 para usar variables de entorno del archivo .env con interpolación avanzada.

### Comandos del Estudiante
```bash
# Crear docker-compose.yml que use variables del bloque 5
cat > docker-compose.yml << 'EOF'

services:
  nginx:
    image: nginx:alpine
    ports:
      - "${NGINX_PORT:-80}:80"
    volumes:
      - ../4-docker-compose-basico/servicios/frontend/nginx.conf:/etc/nginx/nginx.conf
    depends_on:
      - api
    networks:
      - frontend

  api:
    build: ../3-dockerfile-optimizacion/api-node-optimizada
    environment:
      - NODE_ENV=${NODE_ENV:-development}
      - DATABASE_URL=${DATABASE_URL}
      - SECRET_KEY=${SECRET_KEY}
      - PORT=${API_PORT:-3000}
      - DEBUG=${DEBUG:-false}
    depends_on:
      - database
    networks:
      - frontend
      - backend

  database:
    image: postgres:14-alpine
    environment:
      - POSTGRES_DB=${DB_NAME:-myapp}
      - POSTGRES_USER=${DB_USER:-postgres}
      - POSTGRES_PASSWORD=${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ../4-docker-compose-basico/servicios/db/init.sql:/docker-entrypoint-initdb.d/init.sql
    networks:
      - backend

volumes:
  postgres_data:

networks:
  frontend:
  backend:
EOF

# Verificar configuración con interpolación
docker-compose config

# Levantar stack con variables
docker-compose up -d

# Verificar que las variables se aplicaron correctamente
docker-compose exec api printenv | grep -E "(NODE_ENV|DEBUG|SECRET_KEY)" | head -5
```

## Ejercicio 4: Configuraciones por Entorno

**Objetivo:** Crear archivos de configuración específicos para desarrollo, testing y producción usando diferentes archivos .env.

### Comandos del Estudiante
```bash
# Crear archivo para testing
cat > .env.testing << 'EOF'
NODE_ENV=test
DEBUG=false
LOG_LEVEL=warn
API_PORT=3001
NGINX_PORT=8081
DB_NAME=myapp_test
DB_USER=test_user
DB_PASSWORD=test_pass
DATABASE_URL=postgresql://test_user:test_pass@database:5432/myapp_test
SECRET_KEY=test-secret-key-for-testing
EOF

# Crear archivo para producción
cat > .env.production << 'EOF'
NODE_ENV=production
DEBUG=false
LOG_LEVEL=error
API_PORT=3000
NGINX_PORT=80
DB_NAME=myapp_prod
DB_USER=prod_user
DB_PASSWORD=super-secure-prod-password
DATABASE_URL=postgresql://prod_user:super-secure-prod-password@database:5432/myapp_prod
SECRET_KEY=super-secure-production-secret-key-32chars
EOF

# Probar cada configuración
echo "=== TESTING ==="
docker-compose --env-file .env.testing config | grep NODE_ENV

echo "=== PRODUCTION ==="
docker-compose --env-file .env.production config | grep NODE_ENV

# Levantar stack con configuración de testing
docker-compose down
docker-compose --env-file .env.testing up -d

# Verificar variables aplicadas
docker-compose exec api printenv | grep NODE_ENV
```

## Ejercicio 5: Gestión Avanzada de Volúmenes

**Objetivo:** Configurar diferentes tipos de volúmenes para logs, configuraciones y persistencia avanzada.

### Comandos del Estudiante
```bash
# Crear directorios para volúmenes REVISAR PARA GENERAR LOGS DE LOS ESTADOS DEL API HEALTH
mkdir -p volumes/{logs,backups}

# Actualizar docker-compose.yml con volúmenes avanzados
cat > docker-compose.yml << 'EOF'

services:
  nginx:
    image: nginx:alpine
    ports:
      - "${NGINX_PORT:-80}:80"
    volumes:
      - ../4-docker-compose-basico/servicios/frontend/nginx.conf:/etc/nginx/nginx.conf
    depends_on:
      - api
    networks:
      - frontend

  api:
    build: ../3-dockerfile-optimizacion/api-node-optimizada
    environment:
      - NODE_ENV=${NODE_ENV:-development}
      - DATABASE_URL=${DATABASE_URL}
      - SECRET_KEY=${SECRET_KEY}
      - PORT=${API_PORT:-3000}
      - DEBUG=${DEBUG:-false}
    depends_on:
      - database
    networks:
      - frontend
      - backend

  database:
    image: postgres:14-alpine
    environment:
      - POSTGRES_DB=${DB_NAME:-myapp}
      - POSTGRES_USER=${DB_USER:-postgres}
      - POSTGRES_PASSWORD=${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ../4-docker-compose-basico/servicios/db/init.sql:/docker-entrypoint-initdb.d/init.sql
    networks:
      - backend
      - backup

  # Servicio de logs
  logging:
    image: alpine:latest
    command: ["sh", "-c", "while true; do echo 'Log entry at' $(date) >> /logs/app.log; sleep 30; done"]
    volumes:
      - app_logs:/logs

  # Servicio de backup
  backup:
    image: postgres:14-alpine
    command: ["sh", "-c", "while true; do pg_dump ${DATABASE_URL} > /backups/backup_$(date +%Y%m%d_%H%M%S).sql 2>/dev/null || echo 'Backup failed'; sleep 3600; done"]
    volumes:
      - ./volumes/backups:/backups
      - postgres_data:/var/lib/postgresql/data:ro
    environment:
      - DATABASE_URL=${DATABASE_URL}
    depends_on:
      - database
    networks:
      - backup

volumes:
  postgres_data:
  app_logs:
    driver: local

networks:
  frontend:
  backend:
  backup:
EOF

# Recrear stack con volúmenes
docker-compose down
docker-compose up -d

# Verificar volúmenes
docker volume ls | grep 5-entornos
docker volume inspect 5-entornos-y-volumenes_postgres_data

# Verificar bind mounts
ls -la volumes/
docker-compose exec logging ls -la /logs/
```