# Guía de Prueba - Bloque 0

## Para el Instructor

### Verificación Rápida
```bash
# 1. Verificar Docker instalado
docker --version

# 2. Verificar que Docker está corriendo
docker info

# 3. Probar hello-world (debería descargar primera vez)
docker run hello-world

# 4. Probar Alpine interactivo
docker run -it alpine sh
# Dentro: whoami, cat /etc/os-release, exit

# 5. Medir tiempo
time docker run alpine echo "Hola desde contenedor!"
```

### Puntos Clave para Destacar
- **Velocidad:** Alpine arranca en ~1-2 segundos
- **Tamaño:** Solo ~5MB vs GB de una VM
- **Simplicidad:** Un comando y funciona
- **Aislamiento:** Proceso separado del host

### Errores Comunes Esperados

#### 1. "docker: command not found"
**Solución:** Verificar instalación de Docker Desktop

#### 2. "Cannot connect to the Docker daemon"
**Síntomas:** `docker info` muestra error de conexión
**Solución:** 
- **Windows/Mac:** Iniciar Docker Desktop desde el menú
- **Linux:** `sudo systemctl start docker`

#### 3. Permisos en Linux
**Síntoma:** "permission denied"
**Solución:** `sudo usermod -aG docker $USER` (y reiniciar sesión)

#### 4. Primera descarga lenta
**Es normal:** Explicar que está descargando layers

#### 5. "Error response from daemon"
**Verificar:** Que Docker Desktop esté completamente iniciado (ícono sin animación)

### Preparación Previa (Recomendada)
```bash
# Pre-descargar imágenes para evitar demoras
docker pull hello-world
docker pull alpine
```

### Tiempo Estimado Real
- **Preparación:** 2-3 min (verificar Docker)
- **Explicación:** 15-20 min
- **Ejercicio práctico:** 8-10 min
- **Q&A:** 5 min
- **Total: ~30 min**

### Script de Verificación Completa
```bash
# Copiar y pegar para verificación rápida
echo "=== Verificando Docker ==="
docker --version
echo ""

echo "=== Estado de Docker ==="
docker info > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "Docker está corriendo"
else
    echo "Docker no está corriendo - iniciar Docker Desktop"
fi
echo ""

echo "=== Probando contenedor ==="
docker run alpine echo "Contenedor funcionando"
```

---
**Tips:**
- Tener Docker Desktop abierto antes de la capacitación
- Si hay problemas de red, usar imágenes pre-descargadas
- Mostrar el ícono de Docker Desktop como referencia visual

---
**Tip:** Si hay problemas de red, tener alpine image pre-descargada 