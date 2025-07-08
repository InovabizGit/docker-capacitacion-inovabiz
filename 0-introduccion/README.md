# Bloque 0: Introducción a los Contenedores

## Objetivo del Bloque
Explicar el concepto de virtualización y comparar las dos tecnologías principales: Máquinas Virtuales (VMs) y Docker, comprendiendo cómo funcionan y cuándo usar cada una.

**Duración:** 30 minutos

## Contenido Teórico

### 1. ¿Qué es la Virtualización?

La **virtualización** es un proceso donde el software se usa para crear una **capa de abstracción**. Esta capa permite ejecutar múltiples sistemas o aplicaciones de manera aislada en el mismo hardware físico.

**Concepto clave:** Tanto las VMs como Docker abordan la virtualización, pero de maneras diferentes:
- **VMs:** Virtualizan el hardware completo
- **Docker:** Virtualiza el sistema operativo

### 2. Máquinas Virtuales (VMs) - Cómo Funcionan

#### **Arquitectura de VMs**
```
┌─────────────────────────────────────┐
│        VM1    │    VM2    │   VM3   │ ← Múltiples VMs
├─────────────────────────────────────┤
│             HYPERVISOR              │ ← Capa de abstracción
├─────────────────────────────────────┤
│             HARDWARE               │ ← Hardware físico
└─────────────────────────────────────┘
```

#### **¿Qué es un Hypervisor?**
Un **hypervisor** es el software que ayuda a una máquina virtual emular una computadora física. Gestiona la asignación de recursos entre diferentes VMs en un solo host físico.

**Tipos de Hypervisor:**
- **Type 1 (Bare Metal):** Ejecuta directamente sobre el hardware
  - Ejemplos: VMware vSphere, Microsoft Hyper-V, Xen
- **Type 2 (Hosted):** Ejecuta sobre un sistema operativo existente
  - Ejemplos: VMware Workstation, VirtualBox

#### **Características de VMs**
- **Sistema Operativo completo:** Cada VM incluye su propio Guest OS
- **Hardware virtual:** CPU virtual, memoria virtual, almacenamiento virtual
- **Aislamiento fuerte:** Separación completa a nivel de hardware
- **Recursos dedicados:** Cada VM tiene recursos asignados específicamente

### 3. Docker - Cómo Funciona la Containerización

#### **Arquitectura de Docker**
```
┌─────────────────────────────────────┐
│   Container1 │ Container2 │ Container3│ ← Múltiples contenedores
├─────────────────────────────────────┤
│            DOCKER ENGINE            │ ← Runtime de contenedores
├─────────────────────────────────────┤
│         HOST OPERATING SYSTEM       │ ← SO del host (compartido)
├─────────────────────────────────────┤
│             HARDWARE               │ ← Hardware físico
└─────────────────────────────────────┘
```

#### **¿Qué es Docker?**
Docker es una plataforma open source que usa tecnología de containerización. Permite a los desarrolladores empaquetar aplicaciones y sus dependencias en contenedores ligeros y portables.

#### **Diferencia clave con VMs**
En lugar de virtualizar el hardware como hace el hypervisor, **Docker virtualiza el sistema operativo**. Cada contenedor contiene solo la aplicación y sus librerías/dependencias.

### 4. Componentes Técnicos Detallados

#### 4.1 Componentes de Docker

**Docker Engine**
- Software central responsable del ciclo de vida de los contenedores
- Proporciona infraestructura para crear, ejecutar y orquestar contenedores
- Interactúa con el kernel del host para asignar recursos

**Mecanismos de Aislamiento**

Docker utiliza dos tecnologías fundamentales del kernel Linux para crear aislamiento:

**cgroups (Control Groups) - "El Administrador de Recursos"**

*¿Qué son?* Los cgroups son como un **administrador de apartamentos** que controla cuántos recursos puede usar cada inquilino.

*Analogía:* Imagina un edificio de apartamentos donde el administrador decide:
- Cuánta electricidad puede usar cada apartamento (CPU)
- Cuánta agua puede consumir (memoria RAM)
- Cuánto espacio de almacén tienen disponible (disco)
- Cuánto ancho de banda de internet pueden usar (red)

```bash
# Ejemplo práctico de límites con cgroups:
docker run --memory="512m" --cpus="1.5" nginx
# Este contenedor solo puede usar máximo 512MB de RAM y 1.5 CPUs
```

*¿Por qué es importante?* Sin cgroups, un contenedor "malicioso" podría consumir toda la RAM o CPU del servidor, dejando sin recursos a otros contenedores.

**namespaces - "Las Paredes Invisibles"**

*¿Qué son?* Los namespaces son como **paredes invisibles** que hacen que cada contenedor vea solo su propio "mundo" y no pueda ver lo que hacen otros contenedores.

*Analogía:* Es como si cada apartamento tuviera ventanas con vidrio de una sola dirección:
- **PID namespace:** Cada apartamento tiene su propia numeración de habitaciones (procesos)
- **NET namespace:** Cada apartamento tiene su propia dirección IP y teléfono
- **MNT namespace:** Cada apartamento ve solo sus propios muebles (sistema de archivos)
- **UTS namespace:** Cada apartamento puede tener su propio nombre
- **USER namespace:** Cada apartamento tiene sus propios residentes (usuarios)

```bash
# Ejemplo: Dos contenedores ven diferentes "mundos"
# Contenedor 1 ve sus procesos:
docker exec container1 ps aux
# PID 1: nginx
# PID 2: worker

# Contenedor 2 ve sus propios procesos:
docker exec container2 ps aux  
# PID 1: apache
# PID 2: php-fpm

# ¡Ambos tienen PID 1, pero son procesos completamente diferentes!
```

**Ejemplo Práctico Combinado:**

Imagina que ejecutas 3 contenedores web en el mismo servidor:

```bash
# Contenedor A: Aplicación de producción
docker run --name prod-app --memory="2g" --cpus="2" nginx

# Contenedor B: Aplicación de testing  
docker run --name test-app --memory="512m" --cpus="0.5" nginx

# Contenedor C: Base de datos
docker run --name database --memory="4g" --cpus="3" postgres
```

**Lo que hace cgroups:**
- Prod-app: máximo 2GB RAM, 2 CPUs
- Test-app: máximo 512MB RAM, 0.5 CPUs  
- Database: máximo 4GB RAM, 3 CPUs
- **Garantía:** Si test-app se vuelve loco, NO puede robar recursos de prod-app

**Lo que hacen namespaces:**
- Cada contenedor ve solo SUS procesos (no puede ver los procesos de otros)
- Cada contenedor tiene SU propia red (diferentes IPs)
- Cada contenedor ve solo SU sistema de archivos
- **Resultado:** Aislamiento completo entre aplicaciones

**¿Por qué Docker es más rápido que VMs?**

```
VM Tradicional:
┌─────────────────┐  ┌─────────────────┐
│  App A + SO     │  │  App B + SO     │  ← Cada VM necesita SO completo
│  (2GB + 1GB)    │  │  (1GB + 1GB)    │
└─────────────────┘  └─────────────────┘
Total: 5GB de RAM

Docker:
┌─────────────────┐  ┌─────────────────┐
│      App A      │  │      App B      │  ← Apps comparten el mismo SO
│      (2GB)      │  │      (1GB)      │
└─────────────────┘  └─────────────────┘
        Kernel Linux Compartido (500MB)
Total: 3.5GB de RAM (30% menos recursos!)
```

**Resumen con Analogía Final:**

Docker es como un **hotel inteligente**:
- **cgroups** = El sistema de climatización que controla cuánta energía usa cada habitación
- **namespaces** = Las paredes que impiden que los huéspedes se molesten entre sí
- **Kernel compartido** = Los servicios comunes del hotel (recepción, seguridad, mantenimiento)

Resultado: Más "huéspedes" (aplicaciones) en el mismo "edificio" (servidor) con menos recursos y mejor aislamiento.

**Docker Images**
- Paquetes ligeros, independientes y ejecutables
- Incluyen todo lo necesario: código, runtime, herramientas del sistema, librerías, configuraciones
- Se construyen usando **Dockerfiles** (documentos simples con instrucciones)

**Docker Containers**
- Instancias en ejecución de las imágenes
- Entornos aislados y autosuficientes
- Se pueden iniciar, detener y reiniciar rápidamente

#### 4.2 Componentes de VMs

**Hypervisor**
- Software responsable de crear, gestionar y ejecutar máquinas virtuales
- Administra y asigna recursos virtuales a cada VM

**Hardware Virtual**
- Componentes emulados: CPU virtual, memoria virtual, almacenamiento virtual, interfaces de red virtuales
- Se presentan al Guest OS como si fueran hardware real

**Guest Operating System**
- Sistema operativo individual que ejecuta dentro de cada VM
- Cada VM puede tener un Guest OS diferente (Windows, Linux, etc.)
- Permite ejecutar múltiples SO en la misma máquina física

### 5. Cuándo Usar Cada Tecnología

#### 5.1 Casos de Uso para VMs

**Sistemas Operativos Diversos**
- Ejecutar diferentes SO simultáneamente (Windows + Linux)
- Útil para testing de aplicaciones en múltiples plataformas

**Aislamiento Máximo**
- Cada VM ejecuta su propio kernel y sistema operativo separado
- Ideal cuando se requiere seguridad y aislamiento completo

**Aplicaciones Legacy**
- Aplicaciones que dependen de versiones específicas del SO
- Configuraciones que no son compatibles con el host OS o contenedores
- Puedes crear un entorno perfecto sin modificar la aplicación

#### 5.2 Casos de Uso para Docker

**Microservicios**
- **Caso de uso #1 para contenedores**
- Naturaleza ligera, tiempos de arranque rápidos
- Capacidad de empaquetar y distribuir dependencias
- Ideal para arquitecturas basadas en microservicios

**Velocidad de Desarrollo**
- Desarrollo y deployment rápidos
- Capacidad de construir, desplegar y escalar contenedores rápidamente
- Perfecto para prácticas ágiles y pipelines CI/CD

**Eficiencia de Recursos**
- Los contenedores comparten el mismo kernel del host
- Footprint mucho menor que las VMs
- Permite ejecutar más contenedores en el mismo hardware con menos overhead

### 6. Enfoque Híbrido: Combinando Ambas Tecnologías

#### **Realidad en Producción**
Es común ver **ambas tecnologías** usadas en entornos híbridos:

- **Aplicaciones Legacy:** Ejecutan en VMs
- **Microservicios Modernos:** Ejecutan en contenedores Docker

#### **¿Por qué Híbrido?**
- **No es una decisión de "uno u otro"** para las organizaciones
- Cada tecnología tiene sus fortalezas específicas
- **Ejemplo real:** Aplicaciones legacy en VMs + microservicios en Docker containers

#### **Ejemplos en la Industria**
- **AWS:** ECS/EKS ejecuta contenedores dentro de VMs EC2
- **Azure:** Container Instances + Virtual Machines
- **Google Cloud:** GKE (Kubernetes) sobre VMs

#### **Estrategia Recomendada**
Considera las necesidades específicas de tu aplicación e infraestructura:
- **Para nuevos proyectos:** Evalúa contenedores primero
- **Para sistemas existentes:** Mantén VMs si funcionan bien
- **Para organizaciones grandes:** Muy probablemente necesitarás ambas

---
**Siguiente:** Bloque 1 - Docker CLI y Arquitectura

---
**Lectura adicional:** [Docker vs VMs - Docker Documentation](https://docs.docker.com/get-started/overview/) 