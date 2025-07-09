# Bloque 5: Configuración Avanzada con Docker Compose

## Objetivo del Bloque
Dominar la gestión avanzada de configuraciones mediante la integración de variables de entorno con Docker Compose, interpolación de archivos `.env`, y gestión profesional de volúmenes y persistencia de datos.

**Duración:** 45 minutos

## Variables de Entorno en Docker Compose

### Concepto de Integración

En los bloques anteriores se han trabajado con variables de entorno de forma básica. Docker Compose proporciona mecanismos avanzados para integrar estas variables de manera profesional, permitiendo configuraciones dinámicas y flexibles para diferentes entornos de despliegue.

### Interpolación de Variables en docker-compose.yml

Docker Compose permite la **interpolación de variables** directamente en el archivo de configuración, utilizando la sintaxis `${VARIABLE_NAME}`:

```yaml
version: '3.8'

services:
  api:
    build: .
    ports:
      - "${API_PORT}:3000"
    environment:
      - NODE_ENV=${NODE_ENV}
      - DATABASE_URL=${DATABASE_URL}
      - SECRET_KEY=${SECRET_KEY}
    
  database:
    image: postgres:14-alpine
    environment:
      - POSTGRES_DB=${DB_NAME}
      - POSTGRES_USER=${DB_USER}
      - POSTGRES_PASSWORD=${DB_PASSWORD}
    ports:
      - "${DB_PORT}:5432"
```

### Carga Automática de Archivos .env

Docker Compose busca automáticamente un archivo `.env` en el directorio del proyecto y utiliza sus valores para la interpolación:

```bash
# .env
NODE_ENV=development
API_PORT=3000
DB_NAME=myapp
DB_USER=postgres
DB_PASSWORD=dev_password
DATABASE_URL=postgresql://postgres:dev_password@database:5432/myapp
SECRET_KEY=dev-secret-key
```

**Comportamiento automático:**
- Docker Compose carga `.env` sin configuración adicional
- Las variables están disponibles para interpolación con `${VARIABLE}`
- Los valores se resuelven al ejecutar `docker-compose up`

### Especificación de Archivos .env Alternativos

Para diferentes entornos, se pueden especificar archivos .env específicos:

```yaml
# docker-compose.yml
services:
  api:
    build: .
    env_file:
      - .env                # Archivo base
      - .env.local          # Sobrescribe valores locales
      - .env.${NODE_ENV}    # Específico del entorno
    environment:
      # Variables adicionales o sobrescritas
      - API_VERSION=v2
      - FEATURE_FLAG=true
```

**Uso por línea de comandos:**
```bash
# Usar archivo específico
docker-compose --env-file .env.production up -d

# Usar archivo de testing
docker-compose --env-file .env.testing up -d
```

### Precedencia de Variables en Docker Compose

Docker Compose resuelve variables en el siguiente orden (mayor a menor precedencia):

1. **Variables definidas en `environment`** (en docker-compose.yml)
2. **Variables del shell actual** (exportadas en la terminal)
3. **Variables en archivos `env_file`** (especificados en servicios)
4. **Variables en archivo `.env`** (en directorio del proyecto)
5. **Variables definidas en Dockerfile** con `ENV`

```yaml
services:
  api:
    build: .
    env_file:
      - .env.local          # Precedencia 3
    environment:
      - NODE_ENV=production # Precedencia 1 (más alta)
      - DATABASE_URL=${DATABASE_URL} # Precedencia 4 (desde .env)
```

### Validación de Variables en docker-compose.yml

Docker Compose proporciona herramientas para validar la configuración:

```bash
# Validar sintaxis y mostrar configuración final
docker-compose config

# Verificar variables interpoladas
docker-compose config --services

# Mostrar configuración con variables resueltas
docker-compose config | grep environment -A 10
```

### Configuraciones por Entorno

#### Estructura de Archivos por Entorno

```bash
# Archivos específicos por entorno
.env                    # Configuración base
.env.development        # Desarrollo local
.env.testing           # Testing/CI
.env.staging           # Ambiente de staging
.env.production        # Producción

# Template público
.env.example           # Template sin secretos
```

#### Configuración de Desarrollo

```bash
# .env.development
NODE_ENV=development
DEBUG=true
LOG_LEVEL=debug
API_PORT=3000
DB_NAME=myapp_dev
DATABASE_URL=postgresql://dev_user:dev_pass@database:5432/myapp_dev
```

#### Configuración de Producción

```bash
# .env.production
NODE_ENV=production
DEBUG=false
LOG_LEVEL=error
API_PORT=3000
DB_NAME=myapp_prod
DATABASE_URL=postgresql://prod_user:${PROD_PASSWORD}@prod-cluster:5432/myapp_prod
```

### Interpolación Avanzada y Valores por Defecto

Docker Compose soporta **valores por defecto** cuando una variable no está definida:

```yaml
services:
  api:
    ports:
      - "${API_PORT:-3000}:3000"    # Puerto 3000 por defecto
    environment:
      - LOG_LEVEL=${LOG_LEVEL:-info} # Nivel info por defecto
      - WORKERS=${WORKERS:-2}        # 2 workers por defecto
```

**Referencias entre variables:**
```bash
# .env
DB_HOST=database
DB_PORT=5432
DB_NAME=myapp
DB_USER=postgres
DB_PASSWORD=secret

# Variable computada
DATABASE_URL=postgresql://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}
```

### Configuración de Redes con Variables

Las variables también pueden usarse para configurar redes dinámicamente:

```yaml
services:
  nginx:
    image: nginx:alpine
    networks:
      - ${FRONTEND_NETWORK:-frontend}
      
  api:
    build: .
    networks:
      - ${FRONTEND_NETWORK:-frontend}
      - ${BACKEND_NETWORK:-backend}
      
  database:
    image: postgres:14-alpine
    networks:
      - ${BACKEND_NETWORK:-backend}

networks:
  ${FRONTEND_NETWORK:-frontend}:
    driver: bridge
  ${BACKEND_NETWORK:-backend}:
    driver: bridge
    internal: ${BACKEND_INTERNAL:-false}
```

### Gestión de Secretos y Variables Sensibles

Para variables sensibles, Docker Compose permite diferentes estrategias:

#### Variables Externas (no en archivos)

```bash
# Cargar desde variables del sistema
export SECRET_KEY="super-secret-production-key"
export DB_PASSWORD="secure-database-password"

# Docker Compose las usará automáticamente
docker-compose up -d
```

#### Archivos .env Separados por Sensibilidad

```yaml
services:
  api:
    env_file:
      - .env.public      # Variables públicas
      - .env.config      # Configuraciones
      - .env.secrets     # Solo secretos (gitignored)
```

### Troubleshooting de Variables en Docker Compose

#### Comandos de Diagnóstico

```bash
# Ver configuración final con variables resueltas
docker-compose config

# Verificar variables específicas
docker-compose config | grep DATABASE_URL

# Ver variables cargadas en un servicio
docker-compose exec api env | grep NODE_ENV

# Validar archivos .env
docker-compose config --quiet || echo "Error en configuración"
```

#### Errores Comunes y Soluciones

**Variable no definida:**
```bash
# Error: "WARNING: The NODE_ENV variable is not set"
# Solución: Definir en .env o usar valor por defecto
NODE_ENV=${NODE_ENV:-development}
```

**Archivo .env no encontrado:**
```bash
# Error: "Couldn't find env file"
# Solución: Verificar ruta del archivo
docker-compose --env-file ./config/.env up
```

**Interpolación no funciona:**
```bash
# Error: Variable no se interpola
# Causa: Sintaxis incorrecta o variable no exportada
# Solución: Usar ${VARIABLE} y verificar que esté en .env
```

## Gestión Avanzada de Volúmenes

### Tipos de Almacenamiento en Docker

**Named Volumes** (Gestionados por Docker):
```yaml
services:
  database:
    image: postgres:14-alpine
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - postgres_backups:/backups

volumes:
  postgres_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /data/postgres
  postgres_backups:
    driver: local
```

**Bind Mounts** (Vinculación directa):
```yaml
services:
  app:
    image: myapp:latest
    volumes:
      # Archivos de configuración (solo lectura)
      - ./config/app.conf:/etc/app/app.conf:ro
      - ./config/nginx.conf:/etc/nginx/nginx.conf:ro
      
      # Logs (lectura/escritura)
      - ./logs:/app/logs
      - /var/log/app:/var/log/app
      
      # Código fuente (desarrollo)
      - ./src:/app/src
      - ./node_modules:/app/node_modules
```

**Tmpfs Mounts** (Almacenamiento en memoria):
```yaml
services:
  cache:
    image: redis:alpine
    tmpfs:
      - /tmp:rw,size=100M,mode=755
      - /var/run:rw,size=50M,mode=755
    volumes:
      - type: tmpfs
        target: /app/cache
        tmpfs:
          size: 200M
          mode: 0755
```

### Estrategias de Persistencia por Tipo de Dato

**Datos de Aplicación** (bases de datos, uploads):
```yaml
volumes:
  # Base de datos principal
  postgres_data:
    driver: local
  
  # Archivos subidos por usuarios
  app_uploads:
    driver: local
    driver_opts:
      type: nfs
      o: addr=nas.company.com,rw
      device: ":/data/uploads"
```

**Configuraciones** (archivos de configuración):
```yaml
services:
  nginx:
    volumes:
      # Configuraciones que cambian por entorno
      - ./config/${NODE_ENV}/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./config/common/mime.types:/etc/nginx/mime.types:ro
      
      # Certificados SSL
      - ./certs:/etc/ssl/certs:ro
```

**Logs y Monitoreo** (archivos de registro):
```yaml
services:
  app:
    volumes:
      # Logs estructurados para análisis
      - logs_data:/app/logs
      - /var/log/containers:/var/log/containers:ro
      
  logging:
    image: fluentd:latest
    volumes:
      - logs_data:/fluentd/log:ro
      - ./config/fluentd.conf:/fluentd/etc/fluentd.conf:ro
```

### Compartición de Volúmenes entre Servicios

```yaml
services:
  app:
    image: myapp:latest
    volumes:
      - shared_data:/app/data
      - media_files:/app/media
  
  worker:
    image: myapp:latest
    command: ["worker"]
    volumes:
      - shared_data:/app/data:ro  # Solo lectura para worker
      - media_files:/app/media
  
  backup:
    image: backup-tool:latest
    volumes:
      - shared_data:/backup/data:ro
      - media_files:/backup/media:ro
      - backup_storage:/backup/output

volumes:
  shared_data:
  media_files:
  backup_storage:
    external: true  # Volumen gestionado externamente
```

### Configuración de Volúmenes con Variables

Los volúmenes también pueden configurarse dinámicamente usando variables de entorno:

```yaml
services:
  database:
    image: postgres:14-alpine
    volumes:
      - ${POSTGRES_DATA_VOLUME:-postgres_data}:/var/lib/postgresql/data
      - ${BACKUP_PATH:-./backups}:/backups
      
  app:
    build: .
    volumes:
      - ${LOG_PATH:-./logs}:/app/logs
      - ${CONFIG_PATH:-./config}:/app/config:ro

volumes:
  ${POSTGRES_DATA_VOLUME:-postgres_data}:
    driver: ${VOLUME_DRIVER:-local}
```

### Mejores Prácticas para Configuración con Docker Compose

#### Organización de Archivos

```
proyecto/
├── .env.example           # Template público
├── .env                   # Configuración local (gitignored)
├── .env.development       # Desarrollo
├── .env.testing          # Testing/CI
├── .env.staging          # Staging
├── docker-compose.yml    # Configuración base
├── docker-compose.override.yml  # Desarrollo (automático)
├── docker-compose.prod.yml      # Producción
└── config/
    ├── nginx/            # Configuraciones nginx
    ├── app/              # Configuraciones de aplicación
    └── database/         # Scripts de BD
```

#### Documentación de Variables

```bash
# .env.example con documentación completa

# === APLICACIÓN ===
NODE_ENV=development                    # Entorno: development|testing|production
DEBUG=true                             # Habilitar logs de debug: true|false
LOG_LEVEL=info                         # Nivel de log: debug|info|warn|error

# === DOCKER COMPOSE ===
API_PORT=3000                          # Puerto expuesto para API
NGINX_PORT=80                          # Puerto expuesto para nginx
DB_PORT=5432                           # Puerto expuesto para PostgreSQL

# === BASE DE DATOS ===
DATABASE_URL=postgresql://user:pass@host:port/db  # URL completa de conexión
DB_NAME=myapp                          # Nombre de la base de datos
DB_USER=postgres                       # Usuario de PostgreSQL
DB_PASSWORD=change-in-production       # Contraseña (cambiar en producción)
```

#### Validación en Compose

```yaml
services:
  config-validator:
    image: alpine:latest
    command: |
      sh -c '
        echo "Validando configuración..."
        [ -n "$$DATABASE_URL" ] || (echo "ERROR: DATABASE_URL requerida" && exit 1)
        [ -n "$$SECRET_KEY" ] || (echo "ERROR: SECRET_KEY requerida" && exit 1)
        echo "Configuración válida"
      '
    environment:
      - DATABASE_URL=${DATABASE_URL}
      - SECRET_KEY=${SECRET_KEY}
```

La integración avanzada de variables de entorno con Docker Compose permite configuraciones profesionales, flexibles y mantenibles, facilitando despliegues consistentes entre diferentes entornos mientras se mantiene la seguridad y organización del proyecto. 