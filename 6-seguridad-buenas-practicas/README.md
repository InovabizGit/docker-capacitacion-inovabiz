# Bloque 6: Seguridad en Docker y Buenas Prácticas

## Objetivo del Bloque
Comprender las medidas de seguridad esenciales en Docker y adoptar buenas prácticas para proteger aplicaciones en contenedores.

**Duración:** 45 minutos

## Fundamentos de Seguridad en Docker

### 1. ¿Por qué es Importante la Seguridad en Docker?

**Docker comparte el kernel del host**, por lo que las vulnerabilidades pueden afectar el sistema completo. A diferencia de las máquinas virtuales que tienen su propio kernel, los contenedores Docker dependen del kernel del sistema anfitrión.

**Principales riesgos de seguridad:**
- **Escape de contenedor** → Acceso no autorizado al host
- **Imágenes vulnerables** → CVEs conocidas en el software
- **Privilegios excesivos** → Uso innecesario de root
- **Puertos expuestos** → Mayor superficie de ataque
- **Secretos hardcodeados** → Credenciales comprometidas
- **Configuración de red insegura** → Comunicación no protegida
- **Falta de monitoreo** → Actividad maliciosa no detectada

### 2. Principio de Menor Privilegio

#### Problema del Usuario Root
Por defecto, los procesos dentro de los contenedores se ejecutan como usuario root (UID 0), lo que presenta riesgos significativos:

- **Acceso completo** a archivos del contenedor
- **Capacidades del kernel** disponibles por defecto
- **Escalación de privilegios** más fácil en caso de vulnerabilidad
- **Escape de contenedor** con privilegios máximos

#### Solución: Usuarios No Root
La mejor práctica es crear y usar usuarios específicos sin privilegios administrativos:

**Beneficios de usuarios no root:**
- Limitación de daño en caso de compromiso
- Cumplimiento de políticas de seguridad
- Aislamiento mejorado entre contenedores
- Reducción de superficie de ataque

**Estrategias de implementación:**
- Crear usuarios con UID/GID específicos (1001, 1002, etc.)
- Asignar ownership correcto a archivos y directorios
- Usar USER directive en Dockerfile
- Validar permisos en tiempo de ejecución

### 3. Selección de Imágenes Base Seguras

#### Tipos de Imágenes y Superficie de Ataque

**Imágenes completas (Mayor riesgo):**
- Ubuntu, CentOS, Debian full
- Incluyen herramientas del sistema completas
- Mayor número de paquetes = más vulnerabilidades potenciales
- Tamaño considerable (100MB+)

**Imágenes mínimas (Menor riesgo):**
- Alpine Linux (~5MB)
- Debian slim (~40MB)
- Solo paquetes esenciales incluidos

**Imágenes distroless (Mínimo riesgo):**
- Sin shell, package manager, o herramientas debug
- Solo runtime de aplicación y dependencias
- Superficie de ataque mínima
- Ideales para producción

#### Criterios de Selección
1. **Tamaño:** Menor tamaño generalmente significa menos paquetes
2. **Mantenimiento:** Frecuencia de actualizaciones de seguridad
3. **Vulnerabilidades conocidas:** Escaneo regular de CVEs
4. **Compatibilidad:** Con tu aplicación y dependencies
5. **Soporte oficial:** Imágenes mantenidas por organizaciones reconocidas

### 4. Gestión Segura de Secretos

#### Problemas de Hardcodear Secretos
- **Visibilidad en código:** Repositories públicos exponen credenciales
- **Docker history:** Layers pueden contener secretos
- **Variables de entorno:** Visibles en procesos y logs
- **Build context:** Archivos sensibles copiados accidentalmente

#### Estrategias de Gestión de Secretos
1. **Variables de entorno sin valores por defecto**
2. **Docker Secrets** (en Docker Swarm)
3. **Bind mounts** de archivos de secretos
4. **Servicios externos** (HashiCorp Vault, AWS Secrets Manager)
5. **Init containers** para fetch de secretos

#### Buenas Prácticas
- Validar presencia de secretos requeridos
- Usar archivos temporales en memoria (/run/secrets)
- Implementar rotación automática
- Logs que no expongan datos sensibles
- Nunca secretos en Dockerfile o código fuente
- Evitar echo o print de secretos

### 5. Configuración de Runtime Segura

#### Limitación de Recursos
La configuración adecuada de límites previene ataques de denegación de servicio y garantiza estabilidad:

**CPU y Memoria:**
- Límites máximos para prevenir consumo excesivo
- Reservas mínimas para garantizar disponibilidad
- Swap disabled para rendimiento predictible

**Storage:**
- Límites de tamaño de logs
- Tmpfs para datos temporales
- Read-only filesystems cuando sea posible

#### Capabilities del Kernel
Linux capabilities dividen los privilegios de root en unidades más granulares:

**Capabilities comunes que se pueden remover:**
- `CAP_SYS_ADMIN` - Administración del sistema
- `CAP_NET_RAW` - Sockets raw
- `CAP_SYS_TIME` - Modificar tiempo del sistema
- `CAP_AUDIT_WRITE` - Escribir logs de auditoría

**Principle of least privilege:**
- Remover todas las capabilities (`--cap-drop ALL`)
- Agregar solo las específicamente necesarias
- Documentar por qué cada capability es requerida

### 6. Seguridad de Red

#### Aislamiento de Redes
**Principio de segmentación:**
- Frontend, backend y database en redes separadas
- Comunicación controlada entre segmentos
- Acceso a internet limitado o bloqueado

**Tipos de redes Docker:**
- **Bridge:** Comunicación entre contenedores en el mismo host
- **Internal:** Sin acceso a internet, solo comunicación interna
- **Overlay:** Para clusters multi-host (Docker Swarm)
- **None:** Sin conectividad de red

#### Exposición de Puertos
- Solo exponer puertos absolutamente necesarios
- Usar bind específico de IP cuando sea posible
- Considerar proxy reverso para routing
- Implementar rate limiting y firewall rules

### 7. Monitoreo y Auditoría

#### Logs de Seguridad
**Información importante a monitorear:**
- Intentos de acceso no autorizados
- Cambios en configuración de contenedores
- Uso de recursos fuera de rangos normales
- Comunicación de red inesperada
- Errores de autenticación y autorización

#### Herramientas de Auditoría
**Docker Bench Security:**
- Verifica configuración según CIS benchmarks
- Auditoría automatizada de host y contenedores
- Recomendaciones específicas de mejora

**Análisis de Vulnerabilidades:**
- Docker Scout (integrado)
- Trivy (Aqua Security)
- Anchore Engine
- Snyk Container

**Detección de Amenazas en Runtime:**
- Falco (CNCF project)
- Twistlock/Prisma Cloud
- Aqua Security Platform

## Conceptos Avanzados

### Security Scanning en CI/CD
- **Pipeline integration** de herramientas de scanning
- **Failure thresholds** basados en severidad
- **Automated remediation** cuando sea posible
- **Security gates** en deployment pipelines

### Runtime Security
- **Behavioral analysis** de contenedores en ejecución
- **Anomaly detection** basado en machine learning
- **Real-time threat response** automatizada
- **Forensic capabilities** para incident response

### Zero Trust Architecture
- **Assume breach mentality**
- **Verify explicitly** todas las comunicaciones
- **Least privilege access** en todos los niveles
- **Continuous monitoring** y validation