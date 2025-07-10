# Guía de Escaneo de Vulnerabilidades en Imágenes Docker

## 🎯 Objetivo
Aprender a identificar y mitigar vulnerabilidades en imágenes Docker usando herramientas de escaneo.

## 🔍 ¿Qué son las Vulnerabilidades en Imágenes?

Las imágenes Docker pueden contener vulnerabilidades en:
- **Sistema operativo base** (Alpine, Ubuntu, etc.)
- **Librerías del lenguaje** (npm, pip, gem, etc.)
- **Dependencias de aplicación** (packages específicos)
- **Software instalado** (curl, wget, etc.)

## 🛠️ Herramientas de Escaneo

### 1. Docker Scout (Integrado)

#### Escanear Imagen Base
```bash
# Escanear imágenes populares
docker scout cves node:18-alpine
docker scout cves node:18-slim
docker scout cves ubuntu:22.04

# Comparar vulnerabilidades
docker scout compare node:18-alpine --to node:18-slim
```

#### Escanear tu Imagen
```bash
# Build y escanear imagen propia
docker build -t mi-app:latest .
docker scout cves mi-app:latest

# Ver recomendaciones específicas
docker scout recommendations mi-app:latest

# Escanear solo vulnerabilidades críticas/altas
docker scout cves mi-app:latest --only-severity critical,high
```

#### Análisis de Dependencias
```bash
# Ver dependencias vulnerables
docker scout cves mi-app:latest --format json | jq '.vulnerabilities[] | select(.severity == "critical")'

# Obtener estadísticas rápidas
docker scout quickview mi-app:latest
```

### 2. Trivy (Aqua Security)

#### Instalación y Uso Básico
```bash
# Ejecutar con Docker
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:latest image node:18-alpine

# Escanear imagen local
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:latest image mi-app:latest

# Solo vulnerabilidades críticas y altas
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:latest image --severity HIGH,CRITICAL mi-app:latest
```

#### Formatos de Salida
```bash
# Formato JSON
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:latest image --format json mi-app:latest > vulnerabilities.json

# Formato SARIF (para CI/CD)
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:latest image --format sarif mi-app:latest > trivy-results.sarif

# Formato tabla con detalles
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:latest image --format table mi-app:latest
```

### 3. Snyk (Comercial con Free Tier)

#### Escanear con Snyk
```bash
# Instalar Snyk CLI
npm install -g snyk

# Autenticarse
snyk auth

# Escanear Dockerfile
snyk container test node:18-alpine

# Escanear imagen local
snyk container test mi-app:latest

# Ver solo issues críticos
snyk container test mi-app:latest --severity-threshold=high
```

### 4. Anchore Engine

#### Configuración y Uso
```bash
# Ejecutar Anchore Engine
docker run -d --name anchore-engine \
  -p 8228:8228 \
  anchore/anchore-engine:latest

# Esperar inicialización (2-3 minutos)
sleep 180

# Analizar imagen
docker exec anchore-engine anchore-cli image add mi-app:latest
docker exec anchore-engine anchore-cli image wait mi-app:latest
docker exec anchore-engine anchore-cli image vuln mi-app:latest all
```

## 📊 Interpretación de Resultados

### Niveles de Severidad
- **CRITICAL** 🔴 → Requiere acción inmediata
- **HIGH** 🟠 → Debe ser solucionado pronto
- **MEDIUM** 🟡 → Planificar solución
- **LOW** 🟢 → Considerar en actualizaciones rutinarias

### Ejemplo de Reporte
```
Total: 15 vulnerabilities
├── 2 CRITICAL
├── 5 HIGH  
├── 6 MEDIUM
└── 2 LOW

CRITICAL Vulnerabilities:
- CVE-2023-1234: Remote Code Execution in openssl
  - Package: openssl@1.1.1
  - Fixed in: openssl@1.1.2
  - CVSS Score: 9.8

- CVE-2023-5678: SQL Injection in postgresql-client
  - Package: postgresql-client@13.1
  - Fixed in: postgresql-client@13.2
  - CVSS Score: 9.1
```

## 🛡️ Estrategias de Mitigación

### 1. Actualizar Imagen Base
```dockerfile
# ❌ Imagen con vulnerabilidades conocidas
FROM node:16-alpine

# ✅ Imagen actualizada
FROM node:18-alpine

# ✅ Mejor: Versión específica reciente
FROM node:18.19.0-alpine3.19
```

### 2. Actualizar Dependencias del SO
```dockerfile
FROM node:18-alpine

# Actualizar packages del sistema operativo
RUN apk update && apk upgrade
```

### 3. Minimizar Superficie de Ataque
```dockerfile
# ❌ Imagen completa con muchos packages
FROM node:18

# ✅ Imagen mínima
FROM node:18-alpine

# ✅ Mejor: Multistage build
FROM node:18-alpine AS builder
# ... build steps

FROM node:18-alpine AS runtime
# Solo copiar binarios necesarios
```

### 4. Usar Imágenes Distroless
```dockerfile
# Para aplicaciones Node.js
FROM gcr.io/distroless/nodejs18-debian11

# Para binarios estáticos (Go, Rust)
FROM gcr.io/distroless/static

# Para aplicaciones Java
FROM gcr.io/distroless/java17-debian11
```

## 🔄 Integración en CI/CD

### GitHub Actions
```yaml
# .github/workflows/security-scan.yml
name: Security Scan

on: [push, pull_request]

jobs:
  security-scan:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Build Docker image
      run: docker build -t ${{ github.repository }}:latest .
    
    - name: Run Trivy vulnerability scanner
      uses: aquasecurity/trivy-action@master
      with:
        image-ref: '${{ github.repository }}:latest'
        format: 'sarif'
        output: 'trivy-results.sarif'
    
    - name: Upload Trivy scan results
      uses: github/codeql-action/upload-sarif@v2
      with:
        sarif_file: 'trivy-results.sarif'
    
    - name: Fail on Critical/High vulnerabilities
      run: |
        docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
          aquasec/trivy:latest image --exit-code 1 --severity HIGH,CRITICAL \
          ${{ github.repository }}:latest
```

### GitLab CI
```yaml
# .gitlab-ci.yml
security_scan:
  stage: test
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker build -t $CI_PROJECT_NAME:$CI_COMMIT_SHA .
    - docker run --rm -v /var/run/docker.sock:/var/run/docker.sock 
        aquasec/trivy:latest image --exit-code 1 --severity HIGH,CRITICAL 
        $CI_PROJECT_NAME:$CI_COMMIT_SHA
  allow_failure: false
```

### Jenkins Pipeline
```groovy
pipeline {
    agent any
    stages {
        stage('Security Scan') {
            steps {
                script {
                    def image = docker.build("myapp:${env.BUILD_ID}")
                    
                    // Scan with Trivy
                    sh """
                        docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
                        aquasec/trivy:latest image --format json \
                        myapp:${env.BUILD_ID} > trivy-report.json
                    """
                    
                    // Parse results and fail if critical vulnerabilities
                    def report = readJSON file: 'trivy-report.json'
                    def criticalVulns = report.Results?.findAll { 
                        it.Vulnerabilities?.any { vuln -> 
                            vuln.Severity in ['CRITICAL', 'HIGH'] 
                        } 
                    }
                    
                    if (criticalVulns) {
                        error("Critical vulnerabilities found!")
                    }
                }
            }
        }
    }
}
```

## 📋 Checklist de Seguridad de Imágenes

### Pre-Build
- [ ] Usar imagen base oficial y mínima
- [ ] Revisar historial de vulnerabilidades de la imagen base
- [ ] Minimizar packages instalados
- [ ] Usar versiones específicas (no `latest`)

### Post-Build
- [ ] Escanear imagen con al menos 2 herramientas
- [ ] No aceptar vulnerabilidades CRITICAL/HIGH sin plan de mitigación
- [ ] Documentar vulnerabilidades aceptadas temporalmente
- [ ] Configurar alertas para nuevas vulnerabilidades

### Producción
- [ ] Escanear imágenes regularmente (semanal/mensual)
- [ ] Actualizar imágenes base automáticamente
- [ ] Monitorear CVE databases para dependencias
- [ ] Tener plan de respuesta para vulnerabilidades críticas

## 🚨 Respuesta a Vulnerabilidades Críticas

### Plan de Acción Inmediata
1. **Evaluar impacto** → ¿Está la vulnerabilidad expuesta?
2. **Priorizar** → CVSS score y explotabilidad
3. **Mitigar** → Patch, workaround, o aislamiento
4. **Comunicar** → Notificar al equipo y stakeholders
5. **Verificar** → Re-escanear después del fix

### Script de Respuesta Automática
```bash
#!/bin/bash
# critical-vuln-response.sh

IMAGE_NAME="$1"
SEVERITY_THRESHOLD="CRITICAL"

echo "🔍 Escaneando imagen: $IMAGE_NAME"
SCAN_RESULT=$(docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:latest image --format json --severity $SEVERITY_THRESHOLD $IMAGE_NAME)

CRITICAL_COUNT=$(echo $SCAN_RESULT | jq '.Results[].Vulnerabilities | length')

if [ "$CRITICAL_COUNT" -gt 0 ]; then
    echo "🚨 ALERTA: $CRITICAL_COUNT vulnerabilidades críticas encontradas"
    
    # Enviar notificación (Slack, email, etc.)
    curl -X POST -H 'Content-type: application/json' \
      --data "{\"text\":\"🚨 Vulnerabilidades críticas en $IMAGE_NAME\"}" \
      $SLACK_WEBHOOK_URL
    
    # Detener deployment automático
    exit 1
else
    echo "✅ No se encontraron vulnerabilidades críticas"
    exit 0
fi
```

## 📚 Recursos Adicionales

- **Docker Scout:** https://docs.docker.com/scout/
- **Trivy:** https://trivy.dev/
- **Snyk:** https://snyk.io/
- **NIST CVE Database:** https://nvd.nist.gov/
- **Alpine Security:** https://secdb.alpinelinux.org/
- **Distroless Images:** https://github.com/GoogleContainerTools/distroless

---
**💡 Consejo:** Automatiza el escaneo en tu pipeline de CI/CD y establece políticas claras sobre qué nivel de vulnerabilidades es aceptable para cada entorno. 