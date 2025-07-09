# Ejercicios Prácticos - Bloque 4: Docker Compose Básico

**Duración:** 1 hora 15 minutos  
**Objetivo:** Dominar la orquestación de múltiples servicios con Docker Compose

## Ejercicio 1: Verificación del Entorno Docker Compose

**Objetivo:** Confirmar que Docker Compose está disponible y funcionando correctamente.

### Comandos del Estudiante
```bash
# Verificar versión de Docker Compose
docker-compose --version

# Verificar que Docker está corriendo
docker ps

# Navegar al directorio del bloque
cd 4-docker-compose-basico

# Explorar la estructura del proyecto
ls -la
tree
```

## Ejercicio 2: Análisis del Archivo docker-compose.yml

**Objetivo:** Comprender la estructura y configuración de cada servicio definido.

### Comandos del Estudiante
```bash
# Examinar el contenido del docker-compose.yml
cat docker-compose.yml

# Validar la sintaxis del archivo
docker-compose config

# Verificar que las imágenes base estén disponibles
docker-compose config --services
```

## Ejercicio 3: Construcción de Imágenes Necesarias

**Objetivo:** Preparar todas las imágenes requeridas por el stack antes del despliegue.

### Comandos del Estudiante
```bash
# Verificar que existe la imagen optimizada del bloque anterior
docker images | grep api-node-optimizada

# Si no existe, construirla
cd ../3-dockerfile-optimizacion/api-node-optimizada
docker build -t api-node-optimizada .
cd ../../4-docker-compose-basico

# Construir imágenes definidas en docker-compose
docker-compose build

# Verificar imágenes creadas
# docker-compose images
```

## Ejercicio 4: Primer Despliegue del Stack Completo

**Objetivo:** Levantar todos los servicios y verificar que se comunican correctamente.

### Comandos del Estudiante
```bash
# Levantar todos los servicios en segundo plano
docker-compose up -d

# Verificar que todos los contenedores están corriendo
docker-compose ps

# Verificar logs de todos los servicios
docker-compose logs

# Esperar a que los servicios estén completamente inicializados
# sleep 30
```

## Ejercicio 5: Pruebas de Conectividad del Stack

**Objetivo:** Verificar que el proxy reverso nginx se comunica correctamente con la API y la base de datos.

### Comandos del Estudiante
```bash
# Probar acceso través de nginx (puerto 80)
curl -s http://localhost/

# Probar endpoint de salud
curl -s http://localhost/health

# Probar acceso directo a la API (puerto 3000)
curl -s http://localhost:3000/

# Verificar información del entorno
curl -s http://localhost/info
```

## Ejercicio 6: Exploración de Redes Internas

**Objetivo:** Comprender cómo Docker Compose maneja la comunicación entre servicios.

### Comandos del Estudiante
```bash
# Listar redes creadas por Docker Compose
docker network ls

# Inspeccionar la red frontend
docker network inspect 4-docker-compose-basico_frontend

# Inspeccionar la red backend  
docker network inspect 4-docker-compose-basico_backend

# Verificar conectividad interna desde el contenedor API
docker-compose exec api ping -c 3 database
docker-compose exec api ping -c 3 nginx
docker-compose exec api nslookup database
# Verificar conectividad interna desde el contenedor Frontend
docker-compose exec nginx ping -c 3 api
docker-compose exec nginx ping -c 3 database # Prueba no debe funcionar
```

## Ejercicio 7: Gestión de Logs y Monitoreo

**Objetivo:** Aprender a monitorear y diagnosticar problemas en el stack multi-contenedor.

### Comandos del Estudiante
```bash
# Ver logs de todos los servicios
docker-compose logs

# Ver logs de un servicio específico
docker-compose logs nginx
docker-compose logs api
docker-compose logs database

# Seguir logs en tiempo real
docker-compose logs -f api

# Ver las últimas 20 líneas de logs
docker-compose logs --tail=20 api

# Verificar procesos corriendo en cada contenedor
docker-compose top
```

## Ejercicio 8: Escalamiento de Servicios

**Objetivo:** Demostrar la capacidad de escalar servicios horizontalmente con Docker Compose.

### Comandos del Estudiante
```bash
# Escalar el servicio API a 3 instancias
docker-compose up --scale api=3 -d

# Verificar que se crearon múltiples instancias
docker-compose ps

# Probar que nginx distribuye carga entre instancias REVISAR
for i in {1..100}; do
    curl -s http://localhost/info | grep hostname
done

# Escalar de vuelta a 1 instancia
docker-compose up --scale api=1 -d
```

## Ejercicio 9: Gestión de Volúmenes y Persistencia

**Objetivo:** Verificar que los datos persisten entre reinicios de contenedores.

### Comandos del Estudiante
```bash
# Verificar volúmenes creados
docker volume ls | grep postgres

# Inspeccionar el volumen de PostgreSQL
docker volume inspect 4-docker-compose-basico_postgres_data

# Agregar datos a la base de datos
docker-compose exec database psql -U postgres -d myapp -c "
INSERT INTO users (name, email) VALUES ('Test User', 'test@example.com');"

# Verificar datos insertados
docker-compose exec database psql -U postgres -d myapp -c "SELECT * FROM users;"

# Reiniciar solo el contenedor de base de datos
docker-compose restart database

# Verificar que los datos persisten
docker-compose exec database psql -U postgres -d myapp -c "SELECT COUNT(*) FROM users;"
```

## Ejercicio 10: Limpieza y Gestión del Ciclo de Vida

**Objetivo:** Aprender a gestionar completamente el ciclo de vida del stack de servicios.

### Comandos del Estudiante
```bash
# Detener todos los servicios
docker-compose stop

# Verificar que están detenidos pero no eliminados
docker-compose ps

# Reiniciar todos los servicios
docker-compose start

# Eliminar completamente el stack (contenedores y redes)
docker-compose down

# Verificar que se eliminaron contenedores
docker-compose ps

# Eliminar también volúmenes (CUIDADO: datos se pierden)
docker-compose down -v

# Verificar que volúmenes fueron eliminados
docker volume ls | grep postgres

# Recrear todo desde cero
docker-compose up -d
```