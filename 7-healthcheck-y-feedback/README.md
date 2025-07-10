# Bloque 7: Healthcheck y Monitoreo

## Objetivo del Bloque
Comprender e implementar healthchecks efectivos y configurar monitoreo básico para contenedores en producción.

**Duración:** 40 minutos

## Conceptos Fundamentales

### ¿Qué son los Healthchecks?

Los **healthchecks** son verificaciones automáticas del estado de salud de un contenedor, proporcionando una forma sistemática de determinar si una aplicación está funcionando correctamente más allá de simplemente verificar que el proceso esté ejecutándose.

**Analogía médica:**
- **Síntomas vitales** → CPU, memoria, respuesta de red
- **Diagnóstico** → ¿La aplicación responde correctamente?
- **Tratamiento** → Reiniciar contenedor si está "enfermo"
- **Alertas** → Notificar cuando algo va mal

### Estados de un Contenedor

**starting** → Estado inicial durante el grace period
**healthy** → Todos los healthchecks pasan correctamente
**unhealthy** → Falló el número configurado de veces consecutivas
**none** → Sin healthcheck configurado

### Diferencias con Monitoring Tradicional

**Monitoring tradicional:** Verifica que el proceso esté corriendo
**Healthchecks:** Verifica que la aplicación funcione correctamente

Un contenedor puede estar "up" pero no estar "healthy" si la aplicación no responde adecuadamente.

## Configuración de Healthchecks

### Sintaxis en Dockerfile

```dockerfile
HEALTHCHECK [OPTIONS] CMD command
HEALTHCHECK NONE  # Deshabilitar healthcheck heredado
```

### Opciones de Configuración

**--interval=DURATION** (default: 30s)
Frecuencia de ejecución del healthcheck

**--timeout=DURATION** (default: 30s)
Tiempo máximo permitido para la ejecución

**--start-period=DURATION** (default: 0s)
Tiempo de gracia inicial antes de contar fallos

**--retries=N** (default: 3)
Número de fallos consecutivos antes de marcar como unhealthy

### Patrones de Implementación

#### Verificación HTTP Simple
Verificar que un endpoint HTTP responda correctamente con código de estado 200.

#### Verificación de Base de Datos
Comprobar que la base de datos acepta conexiones y responde a consultas básicas.

#### Verificación de Servicios Dependientes
Validar que las dependencias críticas estén disponibles y funcionales.

#### Verificación de Recursos del Sistema
Monitorear uso de memoria, CPU y espacio en disco dentro de límites aceptables.

## Configuración en Docker Compose

### Healthcheck Básico
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

### Dependencias con Healthchecks
```yaml
depends_on:
  database:
    condition: service_healthy
```

Esta configuración asegura que un servicio no inicie hasta que sus dependencias estén healthy.

### Restart Policies
Los healthchecks trabajan en conjunto con las políticas de reinicio para proporcionar auto-recuperación:

**restart: unless-stopped** → Reinicia automáticamente contenedores unhealthy
**restart: on-failure** → Reinicia solo en caso de fallo
**restart: always** → Reinicia independientemente del motivo de parada

## Diseño de Endpoints de Health

### Principios de Diseño

**Rapidez:** Respuesta en menos de 10 segundos
**Simplicidad:** Verificaciones esenciales únicamente
**Información útil:** Estado de componentes críticos
**Consistencia:** Formato estándar de respuesta

### Niveles de Verificación

#### Nivel 1: Liveness Check
Verificación básica de que la aplicación está corriendo y puede responder.

#### Nivel 2: Readiness Check  
Verificación de que la aplicación puede procesar requests (dependencias disponibles).

#### Nivel 3: Health Check Completo
Verificación exhaustiva incluyendo estado de dependencias externas.

### Formato de Respuesta Recomendado

```json
{
  "status": "healthy|degraded|unhealthy",
  "timestamp": "2024-01-15T10:30:00Z",
  "uptime": 3600,
  "version": "1.2.3",
  "checks": {
    "database": {"status": "healthy", "responseTime": "5ms"},
    "redis": {"status": "healthy", "responseTime": "2ms"},
    "external_api": {"status": "degraded", "responseTime": "15000ms"}
  }
}
```

## Scripts de Healthcheck Personalizados

### Ventajas de Scripts Personalizados

**Flexibilidad:** Lógica de verificación compleja
**Reutilización:** Mismo script para múltiples servicios
**Debugging:** Logs detallados de fallos
**Mantenimiento:** Actualizaciones sin rebuild de imagen

### Estructura Recomendada

1. **Verificación del proceso principal**
2. **Verificación de endpoints críticos**
3. **Verificación de dependencias externas**
4. **Verificación de recursos del sistema**
5. **Logging de resultados**
6. **Exit codes apropiados** (0=healthy, 1=unhealthy)

### Consideraciones de Implementación

**Timeouts:** Implementar timeouts en todas las verificaciones
**Error Handling:** Manejar excepciones y errores de red
**Performance:** Evitar operaciones costosas
**Security:** No exponer información sensible

## Monitoreo y Alertas

### Estrategias de Monitoreo

#### Monitoreo Reactivo
Responder a eventos de cambio de estado (healthy → unhealthy).

#### Monitoreo Proactivo  
Analizar tendencias y patrones antes de que ocurran fallos.

#### Monitoreo Predictivo
Usar métricas históricas para predecir problemas futuros.

### Integración con Sistemas de Alertas

**Webhooks:** Notificaciones HTTP a sistemas externos
**Log Aggregation:** Centralización de logs de healthcheck
**Metrics Collection:** Métricas de tiempo de respuesta y tasa de fallos
**Dashboard Visualization:** Visualización en tiempo real del estado

### Métricas Clave

**Health Check Success Rate:** Porcentaje de healthchecks exitosos
**Mean Time to Recovery (MTTR):** Tiempo promedio de recuperación
**Mean Time Between Failures (MTBF):** Tiempo promedio entre fallos
**Health Check Response Time:** Tiempo de respuesta de verificaciones

## Integración con Orquestadores

### Docker Swarm

**Update Strategy:** Usar healthchecks para rolling updates seguros
**Load Balancing:** Remover contenedores unhealthy del balanceador
**Scaling:** Healthchecks informan decisiones de escalado automático

### Kubernetes (Referencia)

**Liveness Probes:** Equivalente a Docker healthchecks
**Readiness Probes:** Control de tráfico independiente de liveness
**Startup Probes:** Verificaciones específicas para inicialización lenta

## Mejores Prácticas

### Configuración de Timing

**Aplicaciones Web:** interval=30s, timeout=10s, retries=3
**Bases de Datos:** interval=10s, timeout=5s, retries=5  
**Servicios Críticos:** interval=15s, timeout=5s, retries=2
**Servicios Batch:** interval=60s, timeout=30s, retries=2

### Diseño de Verificaciones

**Verificar solo lo esencial:** No todos los componentes necesitan verificación
**Evitar efectos secundarios:** Los healthchecks no deben modificar estado
**Usar timeouts apropiados:** Prevenir healthchecks colgados
**Implementar circuit breakers:** Evitar cascada de fallos

### Gestión de Dependencias

**Dependencias duras:** Sin el servicio, la aplicación no puede funcionar
**Dependencias blandas:** La aplicación puede funcionar con funcionalidad reducida
**Health check de dependencias:** Verificar solo dependencias críticas

## Troubleshooting Común

### Contenedores Reiniciando Constantemente

**Causa:** Healthcheck demasiado estricto o start_period insuficiente
**Solución:** Aumentar retries, timeout o start_period

### Healthchecks Lentos

**Causa:** Verificaciones complejas o timeouts largos  
**Solución:** Optimizar endpoint, usar verificaciones más simples

### Falsos Positivos

**Causa:** Verificaciones sensibles a latencia de red o carga temporal
**Solución:** Implementar tolerancia, promedios móviles

### Dependencias No Disponibles

**Causa:** Orden de inicio incorrecto o dependencias no configuradas
**Solución:** Usar depends_on con condition: service_healthy

## Patrones Avanzados

### Health Check Agregado

Combinar múltiples verificaciones en un solo endpoint con pesos y prioridades diferentes.

### Health Check Escalonado

Implementar diferentes niveles de verificación según la criticidad del servicio.

### Health Check Adaptativo

Ajustar frecuencia y profundidad de verificaciones según el estado actual del sistema.

### Circuit Breaker Pattern

Suspender temporalmente verificaciones de dependencias que fallan consistentemente para evitar cascada de errores.

## Principios de Diseño

### Fail Fast, Recover Fast

**Detección rápida** de problemas mediante healthchecks frecuentes
**Recuperación automática** a través de restart policies
**Feedback inmediato** sobre el estado del sistema

### Defense in Depth

**Múltiples niveles** de verificación (proceso, aplicación, dependencias)
**Redundancia** en verificaciones críticas
**Escalado gradual** de respuestas a problemas

### Observabilidad

**Logging estructurado** de todos los eventos de healthcheck
**Métricas cuantificables** de salud del sistema  
**Trazabilidad** de cambios de estado y sus causas

## Consideraciones de Seguridad

### Exposición de Información

Los endpoints de health no deben exponer:
- Información sensible del sistema
- Credenciales o tokens
- Detalles de arquitectura interna
- Datos de usuario

### Control de Acceso

**Endpoints internos:** Solo accesibles desde dentro del cluster
**Rate limiting:** Prevenir abuso de endpoints de health
**Authentication:** Para endpoints con información detallada

## Conceptos Avanzados

### Health Check Distribuido

En arquitecturas de microservicios, implementar verificaciones que consideren la salud del sistema completo, no solo del servicio individual.

### Correlation IDs

Implementar identificadores únicos para rastrear healthchecks a través de sistemas distribuidos.

### Health Check Caching

Cachear resultados de verificaciones costosas para mejorar performance sin sacrificar frecuencia.

### Anomaly Detection

Usar machine learning para detectar patrones anómalos en métricas de healthcheck que puedan indicar problemas emergentes.

---

**Archivos en este bloque:**
- `test-ejercicio.md` - Ejercicios prácticos paso a paso
- Archivos de demostración: `app-healthcheck-demo.js`, `docker-compose-healthcheck.yml`, etc.

**Siguiente:** Bloque 8 - Evaluación Final 