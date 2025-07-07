# Bloque 1: Docker CLI y Arquitectura

## Objetivo del Bloque
Entender cómo funciona Docker por dentro, conocer su arquitectura y comprender los conceptos fundamentales para gestionar imágenes y contenedores de manera efectiva.

**Duración:** 45 minutos

## Contenido Teórico

### 1. ¿Qué es Docker CLI?

**Docker CLI** (Command Line Interface) es la herramienta principal para interactuar con Docker. Es la interfaz que permite a los desarrolladores y administradores de sistemas comunicarse con el Docker Engine.

#### **Características del Docker CLI:**
- **Herramienta unificada:** Un solo comando (`docker`) para todas las operaciones
- **Sintaxis consistente:** Patrones predecibles en todos los comandos
- **Extensible:** Soporta plugins y comandos personalizados
- **Multiplataforma:** Funciona igual en Windows, Mac y Linux

#### **¿Por qué es importante?**
El CLI es el punto de entrada para:
- Gestionar el ciclo de vida de contenedores
- Administrar imágenes y registros
- Configurar redes y volúmenes
- Monitorear y debuggear aplicaciones

### 2. Arquitectura de Docker

#### **Componentes Principales:**

```
┌─────────────────────────────────────────┐
│             DOCKER CLIENT              │ ← CLI, Compose, APIs
├─────────────────────────────────────────┤
│             DOCKER HOST                 │
│  ┌─────────────────────────────────────┐ │
│  │         DOCKER DAEMON              │ │ ← dockerd
│  │  ┌─────────┐ ┌─────────┐ ┌────────┐ │ │
│  │  │Container│ │Container│ │Container│ │ │
│  │  └─────────┘ └─────────┘ └────────┘ │ │
│  │  ┌─────────────────────────────────┐ │ │
│  │  │          IMAGES                │ │ │
│  │  └─────────────────────────────────┘ │ │
│  └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
                    ↕️
┌─────────────────────────────────────────┐
│          DOCKER REGISTRY               │ ← Docker Hub, registros privados (Azure Container Registry, Amazon Elastic Container Registry, etc)
└─────────────────────────────────────────┘
```

#### **Docker Client:**
- **Función:** Interfaz de usuario para enviar comandos
- **Comunicación:** Se conecta al Docker Daemon via REST API
- **Ubicación:** Puede estar en la misma máquina o remotamente

#### **Docker Daemon (dockerd):**
- **Núcleo del sistema:** Servicio que gestiona todo Docker
- **Responsabilidades:** 
  - Construir, ejecutar y gestionar contenedores
  - Administrar imágenes, redes y volúmenes
  - Exponer API REST para comunicación
- **Ejecución:** Corre como servicio del sistema operativo

#### **Docker Registry:**
- **Repositorio:** Almacena y distribuye imágenes Docker
- **Docker Hub:** Registro público oficial
- **Registros privados:** Para organizaciones (AWS ECR, Azure ACR, etc.)

### 3. Conceptos Fundamentales

#### **Imagen vs Contenedor**
Esta es la distinción más importante en Docker:

**Imagen Docker:**
- **Definición:** Plantilla de solo lectura para crear contenedores
- **Analogía:** Como una "clase" en programación orientada a objetos
- **Características:**
  - Inmutable (no cambia)
  - Capas superpuestas (layers)
  - Incluye código, runtime, librerías, configuración
- **Ejemplo:** `nginx:latest` es una imagen

**Contenedor Docker:**
- **Definición:** Instancia ejecutable de una imagen
- **Analogía:** Como un "objeto" instanciado de una clase
- **Características:**
  - Proceso aislado en ejecución
  - Tiene estado (puede modificarse)
  - Ciclo de vida: create → start → stop → remove
- **Ejemplo:** `mi-nginx` es un contenedor creado desde la imagen `nginx`

#### **Relación Imagen-Contenedor:**
```
Imagen nginx:latest  →  Contenedor web1
        ↓           →  Contenedor web2  
        (Imagen)    →  Contenedor web3
   (Una imagen)        (Múltiples contenedores)
```

### 4. Componentes del Ecosistema Docker

#### **Layers (Capas):**
- **¿Qué son?** Una imagen Docker se construye en capas (layers) superpuestas
- **Creación:** Cada instrucción en un Dockerfile (`FROM`, `RUN`, `COPY`...) genera una nueva capa inmutable

**Cómo funcionan:**
- **Union File System (OverlayFS):** Monta todas las capas de solo lectura y crea una capa de escritura encima
- **Inmutabilidad:** Las capas base nunca cambian, solo se agregan capas superiores
- **Copy-on-Write:** Al modificar archivos, se reflejan en la capa superior sin alterar las capas base

**Ventajas:**
- **Reutilización:** Si dos imágenes comparten capas base, se guarda una sola vez en disco
- **Eficiencia en descargas:** Al hacer `docker pull` solo se transfieren las capas nuevas
- **Cacheo inteligente:** Docker reutiliza capas si las instrucciones no cambian
- **Ahorro de espacio:** Capas compartidas reducen significativamente el almacenamiento

**Ejemplo de capas:**
```dockerfile
FROM ubuntu:20.04          # Capa 1: Sistema base
RUN apt-get update && ...  # Capa 2: Actualizaciones
COPY . /app               # Capa 3: Código de aplicación  
RUN make /app             # Capa 4: Compilación
```

#### **Docker Engine:**
- **Componentes:**
  - **dockerd:** Daemon principal
  - **containerd:** Runtime de contenedores de bajo nivel
  - **runc:** Ejecutor de contenedores OCI-compliant

#### **Namespaces:**
- **¿Qué son?** Mecanismo que aisla recursos del sistema para que un grupo de procesos "vea" únicamente lo que se le asigna
- **Propósito:** Crear ambientes aislados y seguros para contenedores

**Tipos principales usados por Docker:**
- **PID namespace:** Cada contenedor tiene su propia tabla de procesos (PID 1 independiente)
- **NET namespace:** Pila de red independiente (interfaces, rutas, puertos propios)
- **MNT namespace:** Sistema de archivos aislado con montajes independientes
- **UTS namespace:** Nombres de host y dominio separados por contenedor
- **IPC namespace:** Colas de mensajes y semáforos independientes
- **User namespace:** (Opcional) Mapea IDs de usuario distintos dentro/fuera del contenedor

**Beneficios:**
- **Seguridad:** Un proceso no puede "ver" ni interferir con otros namespaces
- **Portabilidad:** Facilita empaquetar aplicaciones sin conflictos con el host
- **Aislamiento:** Cada contenedor opera como si fuera un sistema independiente

#### **Control Groups (cgroups):**
- **¿Qué son?** Característica del kernel Linux que permite limitar y contabilizar el uso de recursos de un conjunto de procesos
- **Función en Docker:** Cuando Docker crea un contenedor, asigna sus procesos a un cgroup específico
- **Capacidades:**
  - **Limitar recursos:** CPU, memoria, I/O de disco, bandwidth de red
  - **Priorizar contenedores:** Asignar más recursos a contenedores críticos
  - **Contabilizar consumo:** Útil para facturación y monitoreo
  - **Prevenir sobrecarga:** Evita que un contenedor consuma todos los recursos del host

**Ejemplo práctico:**
```bash
# Limitar memoria y CPU de un contenedor
docker run --memory=512m --cpus=1 nginx
# --memory=512m: máximo 512 MB de RAM
# --cpus=1: asigna una CPU lógica completa
```

### 5. Flujo de Trabajo con Docker

#### **Flujo Típico de Desarrollo:**
```
1. Desarrollar aplicación
2. Crear Dockerfile
3. Construir imagen (docker build)
4. Probar localmente (docker run)
5. Subir a registro (docker push)
6. Desplegar en producción (docker pull + run)
```

#### **Estados y Ciclo de Vida de un Contenedor:**

**Estados básicos:**
- **Created:** El contenedor existe pero no ha arrancado
- **Running:** Está en ejecución activa
- **Paused:** Su ejecución está congelada (SIGSTOP a todos los procesos)
- **Stopped/Exited:** Terminó su ejecución (con exit code)
- **Dead:** Fallo grave interno; necesita limpieza

**Comandos clave por acción:**
| Acción | Comando | Descripción |
|--------|---------|-------------|
| Crear (sin iniciar) | `docker create imagen` | Configura namespaces, cgroups, volúmenes |
| Iniciar | `docker start contenedor` | Arranca los procesos del contenedor |
| Ejecutar | `docker run imagen` | create + start en un solo comando |
| Parar | `docker stop contenedor` | Envía SIGTERM, luego SIGKILL |
| Pausar | `docker pause contenedor` | Congela todos los procesos |
| Reanudar | `docker unpause contenedor` | Reanuda procesos pausados |
| Eliminar | `docker rm contenedor` | Libera recursos definitivamente |

**Flujo típico:**
1. **Build:** Crear imagen desde Dockerfile
2. **Create:** Instanciar contenedor (configurar aislamiento)
3. **Start:** Arrancar procesos dentro del contenedor
4. **Run:** (create + start), y al terminar va a estado Exited
5. **Stop/Remove:** Detener y/o borrar para liberar recursos

**Diagrama visual del ciclo:**
```
[Imagen] --docker create--> [Created]
   |                          |
   +--docker run / start--> [Running]
                           /   |   \
                      docker pause   \
                           |          \
                       [Paused]      docker stop
                           |            |
                       docker unpause   |
                           |            |
                           v            v
                       [Running]    [Exited]
                                       |
                                   docker rm
                                       |
                                   (fin ciclo)
```

### 6. Buenas Prácticas Conceptuales

#### **Principios de Diseño:**
- **Un proceso por contenedor:** Cada contenedor debe tener una responsabilidad única
- **Contenedores inmutables:** No modificar contenedores en ejecución
- **Datos persistentes externos:** Usar volúmenes para datos importantes
- **Configuración por variables:** Usar environment variables

#### **Gestión de Recursos:**
- **Limitar recursos:** Siempre especificar límites de CPU y memoria
- **Monitoreo:** Supervisar uso de recursos regularmente
- **Limpieza:** Eliminar contenedores e imágenes no utilizados

#### **Seguridad:**
- **Usuarios no-root:** Ejecutar procesos con usuarios limitados
- **Imágenes oficiales:** Preferir imágenes oficiales verificadas
- **Actualizaciones:** Mantener imágenes base actualizadas
- **Escaneo:** Analizar vulnerabilidades en imágenes

#### **Eficiencia:**
- **Reutilización:** Aprovechar capas compartidas entre imágenes
- **Imágenes ligeras:** Usar imágenes base mínimas (alpine)
- **Multistage builds:** Optimizar tamaño de imágenes finales

## Conceptos Clave para Recordar

- **Docker CLI** es la herramienta principal de interacción
- **Arquitectura cliente-servidor** con Docker Daemon como núcleo
- **Imagen = Plantilla**, **Contenedor = Instancia ejecutable**
- **Layers compartidas** hacen eficiente el almacenamiento
- **Aislamiento** a través de namespaces y cgroups
- **Un proceso por contenedor** como principio fundamental

## Ejercicios Prácticos

Para ejercicios hands-on, comandos y verificaciones prácticas, consultar:
**test-ejercicio.md** - Guía completa de ejercicios prácticos

---
**Siguiente:** Bloque 2 - Construcción de Imágenes con Dockerfile 