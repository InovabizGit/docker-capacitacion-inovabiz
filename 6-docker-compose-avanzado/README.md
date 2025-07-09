# Bloque 6: Docker Compose Production-Ready

## Objetivo del Bloque
Dominar técnicas avanzadas de Docker Compose para crear arquitecturas production-ready completas, aplicando optimizaciones reales y patrones profesionales utilizados en entornos de producción.

**Duración:** 90 minutos

## Conceptos Clave

### Profiles y Configuración Multi-Entorno
Docker Compose permite definir **profiles** para ejecutar diferentes configuraciones del mismo stack según el entorno. Esto elimina la necesidad de múltiples archivos compose y centraliza la gestión de configuraciones.

```yaml
services:
  api:
    image: myapp:latest
    profiles: ["api", "full"]
  
  monitoring:
    image: prometheus:latest
    profiles: ["monitoring", "full"]
```

**Comandos por perfil:**
```bash
docker-compose --profile api up        # Solo API
docker-compose --profile monitoring up # Solo monitoreo  
docker-compose --profile full up       # Stack completo
```

### Health Checks Avanzados y Dependency Management
Los health checks inteligentes permiten que los servicios se autorecuperen y gestionen dependencias complejas entre servicios.

```yaml
services:
  api:
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
  
  database:
    depends_on:
      api:
        condition: service_healthy
```

### Resource Optimization
La optimización de recursos asegura rendimiento predecible y evita el consumo excesivo de CPU/memoria en producción.

```yaml
services:
  api:
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
```

### Load Balancing y Alta Disponibilidad
Nginx actúa como reverse proxy y load balancer, distribuyendo tráfico entre múltiples instancias de servicios backend.

```yaml
services:
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    depends_on:
      - api
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf
  
  api:
    build: ./app/api
    scale: 3  # Múltiples instancias para load balancing
```

### Override Files y Composición
Los archivos de override permiten extender configuraciones base sin duplicar código, manteniendo separación clara entre entornos.

```bash
# Desarrollo
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up

# Producción  
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up

# Con monitoreo
docker-compose -f docker-compose.yml -f docker-compose.monitoring.yml up
```

<!-- ### Networks Avanzadas y Segmentación
La segmentación de redes mejora la seguridad aislando servicios según su función y nivel de exposición.

```yaml
networks:
  frontend:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 172.20.0.0/16
  
  backend:
    driver: bridge
    internal: true  # Red interna sin acceso externo
  
  monitoring:
    driver: bridge
``` -->

### Secrets y Configuraciones Seguras
La gestión segura de secretos evita exponer credenciales en variables de entorno o archivos de configuración.

```yaml
services:
  api:
    secrets:
      - db_password
      - api_key
    configs:
      - app_config

secrets:
  db_password:
    file: ./secrets/db_password.txt
  api_key:
    external: true

configs:
  app_config:
    file: ./config/app.conf
```

### Monitoreo y Observabilidad
La observabilidad integrada proporciona visibilidad completa del stack mediante métricas, logs y trazas centralizadas.

```yaml
services:
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml
  
  grafana:
    image: grafana/grafana:latest
    ports:
      - "3001:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
```

### Rolling Deployments
Las estrategias de deployment sin downtime aseguran continuidad del servicio durante actualizaciones.

```yaml
services:
  api:
    image: myapp:${VERSION}
    deploy:
      update_config:
        parallelism: 1
        delay: 10s
        order: start-first
      rollback_config:
        parallelism: 1
        delay: 5s
```

## Stack Tecnológico

**Aplicación:**
- **API:** Node.js + Express con métricas integradas
- **Frontend:** Nginx + SPA con health monitoring
- **Worker:** Background tasks con queue management
- **Database:** PostgreSQL con replicación
- **Cache:** Redis con clustering

**Infraestructura:**
- **Load Balancer:** Nginx con upstream dinámico
- **Monitoring:** Prometheus + Grafana
- **Logging:** Centralized logging con ELK stack ligero
- **SSL:** Certificados SSL automatizados

## Mejores Prácticas de Producción

### Security Hardening
- Containers non-root
- Network segmentation
- Secrets management
- SSL/TLS termination
- Resource constraints

### Performance Optimization
- Resource limits apropiados
- Health checks optimizados
- Connection pooling
- Cache strategies
- Load balancing inteligente

### Operational Excellence
- Automated deployments
- Health monitoring
- Backup strategies
- Disaster recovery
- Performance testing

### Scalability Patterns
- Horizontal scaling
- Service discovery
- Circuit breaker
- Rate limiting
- Auto-scaling basado en métricas

La arquitectura resultante es un stack completo, optimizado y listo para producción que demuestra técnicas avanzadas de Docker Compose aplicadas a casos de uso reales. 