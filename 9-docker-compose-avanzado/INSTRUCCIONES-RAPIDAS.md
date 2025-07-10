# 🚀 Instrucciones Rápidas - Bloque 6

## Inicio Rápido (5 minutos)

### 1. Configurar Variables de Entorno
```bash
# Crear archivo de configuración
cp env-example .env

# Editar variables básicas (cambiar contraseñas)
nano .env
```

### 2. Ejecutar Ejercicios
```bash
# Navegar al directorio del bloque
cd 6-docker-compose-avanzado

# Seguir los ejercicios en orden
# Ejercicio 1: Crea la aplicación completa
# Ejercicio 2: Configura profiles
# ... continuar según test-ejercicio.md
```

### 3. Verificar que Funciona
```bash
# Después del Ejercicio 2, verificar:
cd compose
docker-compose --profile full up -d
curl http://localhost:8080
```

## ⚠️ Importante

Este bloque está diseñado para ser **completamente autosuficiente**. Los ejercicios van creando todos los archivos necesarios paso a paso.

**NO necesitas ningún archivo de bloques anteriores.**

## 📋 Estado Actual del Bloque

### ✅ Archivos Listos:
- `README.md` - Teoría y conceptos
- `test-ejercicio.md` - 10 ejercicios prácticos
- `env-example` - Template de configuración
- `.gitignore` - Protección de archivos sensibles

### 📝 Se Crean Durante los Ejercicios:
- Aplicación completa (API + Frontend + Worker)
- Configuraciones Docker Compose
- Scripts de automatización
- Configuraciones de infraestructura
- Archivos de monitoreo

## 🎯 Lo que Obtienes al Completar el Bloque:

1. **Stack Production-Ready Completo**
2. **Load Balancing con Alta Disponibilidad**
3. **Monitoreo con Prometheus + Grafana**
4. **Security Hardening Aplicado**
5. **Auto-scaling Basado en Métricas**
6. **Rolling Deployments Sin Downtime**
7. **Backup y Recovery Automatizado**
8. **Performance Testing Integrado**

## 🕐 Duración Estimada: 90 minutos

¡Comienza con el **Ejercicio 1** en `test-ejercicio.md`! 