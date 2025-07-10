# 📋 Cheatsheet Docker CLI

## Comandos Básicos de Imágenes

```bash
# Descargar imagen
docker pull <imagen>:<tag>

# Listar imágenes locales
docker images

# Construir imagen desde Dockerfile
docker build -t <nombre>:<tag> .

# Eliminar imagen
docker rmi <imagen_id>

# Inspeccionar imagen
docker inspect <imagen>
```

## Comandos Básicos de Contenedores

```bash
# Ejecutar contenedor
docker run <imagen>
docker run -d <imagen>                    # en background
docker run -p <host_port>:<container_port> <imagen>  # mapeo de puertos
docker run --name <nombre> <imagen>       # con nombre personalizado
docker run -e VAR=valor <imagen>          # variables de entorno

# Listar contenedores
docker ps                                 # solo ejecutándose
docker ps -a                             # todos

# Ejecutar comando en contenedor
docker exec -it <container_id> /bin/bash

# Ver logs
docker logs <container_id>
docker logs -f <container_id>             # seguir logs

# Detener contenedor
docker stop <container_id>

# Eliminar contenedor
docker rm <container_id>
docker rm -f <container_id>               # forzar eliminación
```

## Docker Compose

```bash
# Levantar stack
docker-compose up
docker-compose up -d                      # en background

# Detener stack
docker-compose down

# Ver logs
docker-compose logs
docker-compose logs <servicio>

# Reconstruir servicios
docker-compose build
docker-compose up --build
```

## Limpieza y Mantenimiento

```bash
# Limpiar contenedores detenidos
docker container prune

# Limpiar imágenes no utilizadas
docker image prune

# Limpiar todo (¡cuidado!)
docker system prune

# Ver uso de espacio
docker system df
```

## Variables de Entorno Útiles

```bash
# Archivo .env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=myapp
DB_USER=postgres
DB_PASS=secretpassword
```

---
**💡 Tip:** Usa `docker --help` y `docker <comando> --help` para más información sobre cualquier comando. 