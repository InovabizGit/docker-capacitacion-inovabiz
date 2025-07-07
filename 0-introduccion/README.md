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
- **cgroups (Control Groups):** Asignan recursos entre procesos
- **namespaces:** Restringen el acceso y visibilidad de un contenedor a otros recursos del sistema
- Garantizan que cada contenedor tenga su entorno aislado

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