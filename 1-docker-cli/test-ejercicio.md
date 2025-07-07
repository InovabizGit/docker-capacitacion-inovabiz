# Guía de Ejercicios - Bloque 1: Docker CLI

## Para Estudiantes: Ejercicios Paso a Paso

### Ejercicio 1: Comandos Básicos de Imágenes

#### Objetivo: Familiarizarse con la gestión de imágenes Docker

```bash
# 1. Verificar Docker instalado
docker --version
docker info

# 2. Buscar imágenes en Docker Hub
docker search nginx

# 3. Descargar imagen nginx
docker pull nginx

# 4. Listar imágenes locales
docker images

# 5. Inspeccionar imagen (ver metadatos)
docker inspect nginx

# 6. Ver historial de capas
docker history nginx
```

**Verificación:** Deberías ver nginx en la lista de imágenes locales.

### Ejercicio 2: Primer Contenedor

#### Objetivo: Ejecutar y gestionar el ciclo de vida básico de un contenedor

```bash
# 1. Ejecutar contenedor básico (foreground)
docker run nginx
# Nota: Se queda "colgado" - esto es normal. Presiona Ctrl+C para salir.

# 2. Ejecutar en background (detached)
docker run -d nginx

# 3. Ejecutar con nombre personalizado
docker run -d --name mi-primer-contenedor nginx

# 4. Listar contenedores activos
docker ps

# 5. Listar todos los contenedores (incluidos detenidos)
docker ps -a

# 6. Detener contenedor
docker stop mi-primer-contenedor

# 7. Iniciar contenedor detenido
docker start mi-primer-contenedor

# 8. Reiniciar contenedor
docker restart mi-primer-contenedor

# 9. Eliminar contenedor (debe estar detenido)
docker stop mi-primer-contenedor
docker rm mi-primer-contenedor
```

**Verificación:** `docker ps -a` no debe mostrar ningún contenedor.

### Ejercicio 3: Servidor Web con Nginx

#### Objetivo: Crear un servidor web funcional y accesible

```bash
# 1. Ejecutar nginx con mapeo de puertos
docker run -d -p 8080:80 --name mi-web nginx

# 2. Verificar que está corriendo
docker ps

# 3. Acceder desde navegador
# Abrir: http://localhost:8080
# Deberías ver "Welcome to nginx!"

# 4. Ver logs del servidor
docker logs mi-web

# 5. Ver logs en tiempo real (Ctrl+C para salir)
docker logs -f mi-web
```

**Verificación:** Navegador debe mostrar la página de bienvenida de nginx.

### Ejercicio 4: Personalizar Contenido Web

#### Objetivo: Modificar el contenido del servidor web

```bash
# 1. Crear archivo HTML personalizado
cat > mi-pagina.html << 'EOF'
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Mi Primera Web en Docker #2</title>
    <style>
        body { font-family: Arial; text-align: center; margin-top: 50px; }
        h1 { color: #0066cc; }
        .container { background: #f0f8ff; padding: 20px; border-radius: 10px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🐳 ¡Hola desde Docker!</h1>
        <p>Esta página está ejecutándose en un contenedor nginx</p>
        <p>Capacitación Docker - Bloque 1</p>
    </div>
</body>
</html>
EOF

# 2. Copiar archivo al contenedor
docker cp mi-pagina.html mi-web:/usr/share/nginx/html/index.html

# 3. Recargar navegador para ver cambios
# http://localhost:8080 - ¡Ahora debería mostrar tu página personalizada!
```

**Verificación:** Navegador debe mostrar tu página HTML personalizada.

### Ejercicio 5: Explorar el Contenedor

#### Objetivo: Entrar y explorar el interior de un contenedor

```bash
# 1. Entrar al contenedor interactivamente
docker exec -it mi-web bash

# 2. Explorar estructura de archivos (DENTRO del contenedor):
whoami
ls -la /usr/share/nginx/html/
cat /usr/share/nginx/html/index.html
cat /etc/nginx/nginx.conf
exit

# 3. Ejecutar comandos sin entrar al contenedor
docker exec mi-web ls -la /usr/share/nginx/html/
docker exec mi-web cat /etc/os-release

# 4. Ver estadísticas en tiempo real
docker stats mi-web

# 5. Ver información detallada del contenedor
docker inspect mi-web
```

**Verificación:** Deberías poder navegar dentro del contenedor y ver los archivos.

### Ejercicio 6: Múltiples Contenedores

#### Objetivo: Gestionar varios contenedores simultáneamente

```bash
# 1. Crear segundo nginx en puerto diferente
docker run -d -p 8081:80 --name segundo-web nginx

# 2. Crear tercero nginx
docker run -d -p 8082:80 --name tercer-web nginx

# 3. Personalizar cada servidor
echo "<h1>Servidor 2 - Puerto 8081</h1>" > servidor2.html
echo "<h1>Servidor 3 - Puerto 8082</h1>" > servidor3.html

docker cp servidor2.html segundo-web:/usr/share/nginx/html/index.html
docker cp servidor3.html tercer-web:/usr/share/nginx/html/index.html

# 4. Verificar todos funcionan
docker ps

# 5. Probar en navegador:
# http://localhost:8080 (Servidor original)
# http://localhost:8081 (Servidor 2)
# http://localhost:8082 (Servidor 3)

# 6. Ver logs de todos
docker logs mi-web
docker logs segundo-web
docker logs tercer-web
```

**Verificación:** Tres servidores web diferentes funcionando en puertos distintos.

### Ejercicio 7: Gestión de Logs Avanzada

#### Objetivo: Monitorear y analizar logs de contenedores

```bash
# 1. Generar tráfico (visitar todas las páginas varias veces)

# 2. Ver logs con timestamps
docker logs -t mi-web

# 3. Ver solo últimas 10 líneas
docker logs --tail 10 mi-web

# 4. Ver logs desde una fecha específica
docker logs --since 5m mi-web

# 5. Seguir logs de múltiples contenedores
# Abrir terminal separado para cada uno:
docker logs -f mi-web
docker logs -f segundo-web
docker logs -f tercer-web
```

### Ejercicio 8: Gestión de Recursos y Limpieza

#### Objetivo: Monitorear recursos y limpiar el ambiente

```bash
# 1. Ver uso de espacio de Docker
docker system df

# 2. Ver estadísticas de todos los contenedores
docker stats

# 3. Ver puertos expuestos de un contenedor
docker port mi-web

# 4. Detener todos los contenedores
docker stop mi-web segundo-web tercer-web

# 5. Eliminar todos los contenedores
docker rm mi-web segundo-web tercer-web

# 6. Limpiar contenedores detenidos
docker container prune

# 7. Limpiar imágenes sin uso (opcional)
docker image prune

# 8. Ver sistema limpio
docker ps -a
docker images
```

**Verificación:** No debe haber contenedores en `docker ps -a`.

---

## Para Instructores: Verificación y Troubleshooting

### Script de Verificación Rápida
```bash
#!/bin/bash
echo "=== Verificación Bloque 1: Docker CLI ==="

# Limpiar ambiente previo
echo "Limpiando ambiente..."
docker stop mi-web segundo-web tercer-web 2>/dev/null || true
docker rm mi-web segundo-web tercer-web 2>/dev/null || true

# Verificar Docker funcional
echo "Verificando Docker..."
docker info > /dev/null && echo "Docker OK" || echo "Docker no está corriendo"

# Ejercicio completo automatizado
echo "Ejecutando ejercicio principal..."
docker pull nginx
docker run -d -p 8080:80 --name mi-web nginx
sleep 2

echo "Verificando funcionamiento..."
docker ps | grep mi-web && echo "Contenedor corriendo"
curl -s http://localhost:8080 | grep "Welcome to nginx" && echo "Web accesible en puerto 8080"

# Personalizar contenido
echo "Personalizando contenido..."
echo "<h1>¡Hola desde Docker!</h1><p>Capacitación funcionando</p>" > mi-pagina.html
docker cp mi-pagina.html mi-web:/usr/share/nginx/html/index.html
sleep 1
curl -s http://localhost:8080 | grep "Hola desde Docker" && echo "Contenido personalizado"

# Múltiples contenedores
echo "Creando múltiples servidores..."
docker run -d -p 8081:80 --name segundo-web nginx
docker run -d -p 8082:80 --name tercer-web nginx

echo "<h1>Servidor 2</h1>" > servidor2.html
echo "<h1>Servidor 3</h1>" > servidor3.html
docker cp servidor2.html segundo-web:/usr/share/nginx/html/index.html
docker cp servidor3.html tercer-web:/usr/share/nginx/html/index.html

echo "Demo completada. Navegadores disponibles:"
echo "   http://localhost:8080 (Principal)"
echo "   http://localhost:8081 (Servidor 2)"
echo "   http://localhost:8082 (Servidor 3)"
```

### Puntos Clave para Destacar Durante la Clase

- **Velocidad:** Nginx listo en ~2-3 segundos vs minutos de una VM
- **Simplicidad:** Un comando (`docker run`) y funciona
- **Flexibilidad:** Múltiples instancias en puertos diferentes desde la misma imagen
- **Aislamiento:** Cada contenedor es independiente
- **Gestión:** Ciclo completo start, stop, logs, rm
- **Interactividad:** `docker exec` para explorar internamente

### Errores Comunes Esperados y Soluciones

#### 1. "Port already in use"
**Síntoma:** `bind: address already in use`
**Causa:** Puerto 8080 ya está ocupado por otro servicio
**Solución:**
```bash
# Opción 1: Usar otro puerto
docker run -d -p 8082:80 --name mi-web nginx

# Opción 2: Encontrar qué usa el puerto
netstat -tlnp | grep :8080  # Linux
lsof -i :8080              # Mac
Get-NetTCPConnection -LocalPort 8080  # Windows PowerShell
```

#### 2. "No route to host" o conexión rechazada
**Verificaciones:**
```bash
# ¿Contenedor corriendo?
docker ps | grep nginx

# ¿Puerto mapeado correctamente?
docker port mi-web

# ¿Firewall bloqueando?
curl -v http://localhost:8080
```

#### 3. "Cannot connect to the Docker daemon"
**Síntomas:** Todos los comandos docker fallan
**Solución:**
- **Windows/Mac:** Iniciar Docker Desktop desde el menú
- **Linux:** `sudo systemctl start docker` o `sudo service docker start`

#### 4. Página no se actualiza después de `docker cp`
**Causa:** Nginx puede cachear contenido
**Soluciones:**
```bash
# Esperar unos segundos y recargar
# O forzar recarga de nginx
docker exec mi-web nginx -s reload
```

#### 5. "No such container"
**Causa:** Contenedor fue eliminado o nombre incorrecto
**Verificación:** `docker ps -a` para ver todos los contenedores

#### 6. Permisos en Linux
**Síntoma:** "permission denied" al ejecutar comandos docker
**Solución:**
```bash
sudo usermod -aG docker $USER
# Reiniciar sesión o usar: newgrp docker
```

### Preparación Previa Recomendada

```bash
# 1. Pre-descargar imagen nginx para evitar demoras
docker pull nginx

# 2. Verificar puertos libres
netstat -tlnp | grep ':808[0-2]' || echo "Puertos 8080-8082 libres"

# 3. Tener archivos HTML de respaldo listos
echo "<h1>Test</h1>" > test.html

# 4. Verificar conectividad a Docker Hub
docker search nginx | head -5
```

### Tiempo Estimado Real por Ejercicio

- **Ejercicio 1 (Imágenes):** 5-8 min
- **Ejercicio 2 (Primer contenedor):** 5-8 min
- **Ejercicio 3 (Nginx básico):** 5-8 min
- **Ejercicio 4 (Personalizar):** 8-10 min
- **Ejercicio 5 (Explorar):** 8-10 min
- **Ejercicio 6 (Múltiples):** 5-8 min
- **Ejercicio 7 (Logs):** 3-5 min
- **Ejercicio 8 (Limpieza):** 3-5 min
- **Total: ~45 min**

### Comandos de Limpieza Post-Clase

```bash
# Detener y eliminar todos los contenedores de la práctica
docker stop mi-web segundo-web tercer-web 2>/dev/null || true
docker rm mi-web segundo-web tercer-web 2>/dev/null || true

# Limpiar archivos temporales
rm -f mi-pagina.html servidor2.html servidor3.html test.html

# Opcional: eliminar imagen nginx si no se usa más
docker rmi nginx

# Verificar limpieza
docker ps -a
echo "Ambiente limpio para próxima clase"
```

### Checklist de Objetivos Cumplidos

Al final de la clase, los participantes deben poder:

- [ ] Distinguir entre imagen y contenedor conceptualmente
- [ ] Descargar imágenes con `docker pull`
- [ ] Ejecutar contenedores con diferentes opciones (`-d`, `-p`, `--name`)
- [ ] Gestionar ciclo de vida: start, stop, restart, rm
- [ ] Acceder a nginx desde navegador (puerto 8080)
- [ ] Modificar contenido usando `docker cp`
- [ ] Entrar a contenedores con `docker exec -it`
- [ ] Monitorear logs con `docker logs`
- [ ] Ejecutar múltiples contenedores simultáneamente
- [ ] Limpiar contenedores e imágenes no utilizados
- [ ] Usar `docker ps` para verificar estado de contenedores

---
**Tips para Instructores:**
- Demostrar en proyector antes de que practiquen individualmente
- Tener puertos alternativos listos (8083, 8084) por si hay conflictos
- Enfatizar frecuentemente que cada `docker run` crea un nuevo contenedor
- Mostrar `docker ps` después de cada comando para visualizar cambios
- Recordar que los contenedores son efímeros - el estado se pierde al eliminarlos 