# Bloque 4: Orquestación con Docker Compose

## Objetivo del Bloque
Comprender la orquestación de múltiples servicios usando Docker Compose para crear aplicaciones multi-contenedor robustas y escalables.

**Duración:** 1 hora 15 minutos

## ¿Qué es Docker Compose?

Docker Compose es una herramienta oficial de Docker que permite definir y ejecutar aplicaciones que requieren múltiples contenedores. Utiliza un archivo YAML declarativo para configurar todos los servicios, redes y volúmenes necesarios.

### Analogía Conceptual

Si Docker es como gestionar un solo empleado en una empresa, Docker Compose es como dirigir un departamento completo:

- **Docker individual**: Un contenedor ejecuta una aplicación específica
- **Docker Compose**: Múltiples contenedores trabajan juntos como un sistema coordinado

Imagine una orquesta sinfónica:
- Cada músico (contenedor) tiene su instrumento y partitura específica
- El director (Docker Compose) coordina que todos toquen en armonía
- La sinfonía completa (aplicación) surge de la colaboración coordinada

### Beneficios de Docker Compose

**Simplicidad de Gestión**: Un solo comando (`docker-compose up`) levanta toda la infraestructura necesaria, incluyendo bases de datos, APIs, proxies reversos y servicios auxiliares.

**Declarativo vs Imperativo**: En lugar de ejecutar múltiples comandos `docker run` con decenas de parámetros, se describe el estado deseado en un archivo YAML legible.

**Networking Automático**: Docker Compose crea automáticamente una red interna donde los servicios pueden comunicarse entre sí usando nombres de servicio como hostnames.

**Consistencia de Entorno**: El mismo archivo funciona idénticamente en desarrollo, testing y producción, eliminando el problema de "funciona en mi máquina".

## Sintaxis y Estructura de docker-compose.yml

### Estructura Base

```yaml
version: '3.8'

services:
  # Definición de cada contenedor/servicio
  
volumes:
  # Almacenamiento persistente compartido
  
networks:
  # Redes personalizadas (opcional)
```

### Elementos Fundamentales

**Version**: Especifica la versión del formato de Docker Compose. La versión 3.8 es estable y ampliamente soportada.

**Services**: Cada servicio representa un contenedor con su configuración específica: imagen, puertos, variables de entorno, volúmenes y dependencias.

**Volumes**: Define almacenamiento persistente que sobrevive al ciclo de vida de los contenedores.

**Networks**: Permite crear redes personalizadas para segmentar la comunicación entre servicios.

### Configuración de Servicios

#### Usando Imágenes Existentes

```yaml
services:
  database:
    image: postgres:14-alpine
    environment:
      - POSTGRES_DB=myapp
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=secretpassword
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
```

#### Construyendo desde Dockerfile

```yaml
services:
  api:
    build: 
      context: ./backend
      dockerfile: Dockerfile
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgresql://postgres:secretpassword@database:5432/myapp
    ports:
      - "3000:3000"
    depends_on:
      - database
```

#### Usando Configuración Externa

```yaml
services:
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./static:/var/www/html:ro
    depends_on:
      - api
```

## Gestión de Dependencias entre Servicios

### Dependencias Básicas

La directiva `depends_on` establece el orden de inicio de los contenedores, asegurando que los servicios fundamentales estén disponibles antes de iniciar servicios dependientes.

```yaml
services:
  api:
    build: ./backend
    depends_on:
      - database
      - redis
    
  database:
    image: postgres:14-alpine
    
  redis:
    image: redis:alpine
```

### Limitaciones de depends_on

**Importante**: `depends_on` solo controla el orden de inicio, no espera que el servicio esté completamente listo para recibir conexiones. Para aplicaciones críticas, es necesario implementar lógica de reintentos o health checks.

### Health Checks y Dependencias Inteligentes

```yaml
services:
  database:
    image: postgres:14-alpine
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 30s
      timeout: 10s
      retries: 3
      
  api:
    build: ./backend
    depends_on:
      database:
        condition: service_healthy
```

## Redes Internas y Comunicación entre Servicios

### Red Automática por Defecto

Docker Compose crea automáticamente una red interna donde todos los servicios pueden comunicarse entre sí usando el nombre del servicio como hostname.

```yaml
services:
  api:
    image: node:18-alpine
    environment:
      # Conecta a 'database' directamente por nombre
      - DATABASE_HOST=database
      - REDIS_HOST=redis
    
  database:
    image: postgres:14-alpine
    # Accesible como 'database' desde otros servicios
    
  redis:
    image: redis:alpine
    # Accesible como 'redis' desde otros servicios
```

### Redes Personalizadas para Segmentación

```yaml
services:
  nginx:
    image: nginx:alpine
    networks:
      - frontend
      
  api:
    build: ./backend
    networks:
      - frontend  # Puede comunicarse con nginx
      - backend   # Puede comunicarse con database
      
  database:
    image: postgres:14-alpine
    networks:
      - backend   # Solo accesible desde api

networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
    internal: true  # Sin acceso a internet
```

### Resolución DNS Interna

Docker Compose implementa un servidor DNS interno que resuelve nombres de servicio a direcciones IP dinámicas. Esto permite que los servicios se descubran automáticamente sin configuración adicional.

## Gestión de Volúmenes y Persistencia

### Tipos de Almacenamiento

**Named Volumes**: Almacenamiento gestionado por Docker, ideal para datos que deben persistir entre reinicios.

```yaml
services:
  database:
    image: postgres:14-alpine
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
    driver: local
```

**Bind Mounts**: Vinculación directa con el sistema de archivos del host, útil para archivos de configuración y desarrollo.

```yaml
services:
  nginx:
    image: nginx:alpine
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./logs:/var/log/nginx
```

**Tmpfs Mounts**: Almacenamiento en memoria RAM, ideal para datos temporales sensibles.

```yaml
services:
  cache:
    image: redis:alpine
    tmpfs:
      - /tmp
      - /var/run
```

### Compartición de Volúmenes entre Servicios

```yaml
services:
  app:
    build: ./app
    volumes:
      - shared_data:/data
      
  worker:
    build: ./worker
    volumes:
      - shared_data:/data
      
  backup:
    image: alpine
    volumes:
      - shared_data:/backup/source:ro

volumes:
  shared_data:
```

## Comandos Esenciales de Docker Compose

### Gestión del Ciclo de Vida

**Inicio de Servicios**:
- `docker-compose up`: Inicia todos los servicios en primer plano
- `docker-compose up -d`: Inicia en segundo plano (detached)
- `docker-compose up --build`: Reconstruye imágenes antes de iniciar
- `docker-compose up --scale api=3`: Escala servicios específicos

**Detención y Limpieza**:
- `docker-compose stop`: Detiene contenedores sin eliminarlos
- `docker-compose down`: Detiene y elimina contenedores y redes
- `docker-compose down -v`: Incluye la eliminación de volúmenes
- `docker-compose down --rmi all`: Elimina también las imágenes

### Monitoreo y Debug

**Estado y Información**:
- `docker-compose ps`: Lista contenedores del proyecto
- `docker-compose top`: Muestra procesos ejecutándose
- `docker-compose logs`: Muestra logs de todos los servicios
- `docker-compose logs -f api`: Sigue logs en tiempo real

**Ejecución de Comandos**:
- `docker-compose exec api bash`: Accede al shell de un contenedor
- `docker-compose run api npm test`: Ejecuta comando en nuevo contenedor
- `docker-compose exec database psql -U postgres`: Conecta a base de datos

### Gestión de Imágenes y Construcción

- `docker-compose build`: Construye todas las imágenes
- `docker-compose pull`: Descarga imágenes desde registros
- `docker-compose images`: Lista imágenes del proyecto
- `docker-compose config`: Valida y muestra configuración final

## Casos de Uso Comunes

### Stack LAMP/LEMP

Servidor web con base de datos para aplicaciones web tradicionales:

```yaml
services:
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    
  php:
    image: php:8.1-fpm
    
  mysql:
    image: mysql:8.0
```

### Aplicación de Microservicios

Múltiples APIs independientes con servicios compartidos:

```yaml
services:
  user-api:
    build: ./services/users
    
  product-api:
    build: ./services/products
    
  order-api:
    build: ./services/orders
    
  gateway:
    image: nginx:alpine
    
  database:
    image: postgres:14
    
  redis:
    image: redis:alpine
```

### Stack de Desarrollo Full-Stack

Frontend, backend y base de datos para desarrollo local:

```yaml
services:
  frontend:
    build: ./frontend
    ports:
      - "3000:3000"
    
  backend:
    build: ./backend
    ports:
      - "8000:8000"
    
  database:
    image: postgres:14
    
  pgadmin:
    image: dpage/pgadmin4
```

## Mejores Prácticas

### Organización de Archivos

- Usar archivos separados para diferentes entornos (docker-compose.override.yml)
- Mantener configuraciones sensibles en archivos .env
- Documentar dependencias y puertos en comentarios

### Seguridad

- No exponer puertos de base de datos innecesariamente
- Usar redes internas para servicios que no necesitan acceso externo
- Gestionar secretos con Docker Secrets o variables de entorno

### Performance

- Usar imágenes Alpine cuando sea posible
- Implementar health checks apropiados
- Configurar restart policies para alta disponibilidad

### Mantenibilidad

- Usar nombres descriptivos para servicios y volúmenes
- Mantener archivos docker-compose.yml versionados
- Implementar logging centralizado para debugging

## Arquitectura de Orquestación Multi-Contenedor

### Principios de Diseño

**Separación de Responsabilidades**: Cada servicio tiene una responsabilidad específica y bien definida. Esto facilita el mantenimiento, testing y escalamiento independiente.

**Comunicación Asíncrona**: Los servicios se comunican através de APIs REST, mensajes o eventos, reduciendo el acoplamiento directo.

**Stateless vs Stateful**: Los servicios de aplicación deben ser stateless (sin estado), mientras que las bases de datos y sistemas de almacenamiento manejan el estado persistente.

### Patrones de Orquestación

**Proxy Reverso**: Un servicio nginx actúa como punto de entrada único, distribuyendo requests a múltiples instancias de aplicación.

**Service Discovery**: Los servicios se descubren automáticamente a través del DNS interno de Docker Compose.

**Circuit Breaker**: Implementación de tolerancia a fallos cuando servicios dependientes no están disponibles.

### Escalabilidad Horizontal

Docker Compose permite escalar servicios específicos independientemente:

```bash
docker-compose up --scale api=5 --scale worker=3
```

Esto crea múltiples instancias del mismo servicio, permitiendo distribución de carga y mayor throughput.

### Consideraciones de Producción

**Limitaciones**: Docker Compose está diseñado principalmente para desarrollo y testing. Para producción se recomiendan orquestadores más robustos como Kubernetes o Docker Swarm.

**Monitoreo**: Implementar logging centralizado y métricas para observabilidad del sistema completo.

**Backup y Recovery**: Establecer estrategias de respaldo para volúmenes persistentes y configuraciones críticas. 