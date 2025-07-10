#!/bin/sh
#
# Script de healthcheck personalizado
# Este script no requiere curl y puede verificar múltiples aspectos
#

set -e

# Configuración
PORT=${PORT:-3000}
HOST=${HOST:-localhost}
TIMEOUT=${HEALTH_TIMEOUT:-5}
LOG_FILE=${LOG_FILE:-/tmp/healthcheck.log}

# Función de logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Función para verificar conectividad TCP
check_tcp_port() {
    local host=$1
    local port=$2
    local timeout=${3:-5}
    
    # Usar netcat si está disponible, sino usar /dev/tcp
    if command -v nc >/dev/null 2>&1; then
        nc -z -w "$timeout" "$host" "$port" >/dev/null 2>&1
    elif command -v timeout >/dev/null 2>&1; then
        timeout "$timeout" sh -c "echo >/dev/tcp/$host/$port" >/dev/null 2>&1
    else
        # Fallback básico
        (echo >/dev/tcp/"$host"/"$port") >/dev/null 2>&1
    fi
}

# Función para hacer request HTTP básico
http_request() {
    local url=$1
    local timeout=${2:-5}
    
    # Intentar con wget primero
    if command -v wget >/dev/null 2>&1; then
        wget --timeout="$timeout" --tries=1 --spider "$url" >/dev/null 2>&1
        return $?
    fi
    
    # Intentar con curl si está disponible
    if command -v curl >/dev/null 2>&1; then
        curl -f -s --max-time "$timeout" "$url" >/dev/null 2>&1
        return $?
    fi
    
    # Fallback: verificar solo el puerto TCP
    check_tcp_port "$HOST" "$PORT" "$timeout"
}

# Verificación 1: Proceso principal corriendo
check_process() {
    log "Verificando proceso principal..."
    
    # Verificar procesos de Node.js
    if pgrep -f "node" >/dev/null 2>&1; then
        log "✓ Proceso Node.js encontrado"
        return 0
    fi
    
    # Verificar otros procesos comunes
    if pgrep -f "nginx\|apache\|httpd" >/dev/null 2>&1; then
        log "✓ Proceso web server encontrado"
        return 0
    fi
    
    log "✗ No se encontró proceso principal"
    return 1
}

# Verificación 2: Puerto TCP accesible
check_port() {
    log "Verificando puerto TCP $HOST:$PORT..."
    
    if check_tcp_port "$HOST" "$PORT" "$TIMEOUT"; then
        log "✓ Puerto $PORT accesible"
        return 0
    else
        log "✗ Puerto $PORT no accesible"
        return 1
    fi
}

# Verificación 3: Endpoint HTTP
check_http() {
    log "Verificando endpoint HTTP..."
    
    local endpoints="/health/simple /health / /ping /status"
    
    for endpoint in $endpoints; do
        local url="http://$HOST:$PORT$endpoint"
        if http_request "$url" "$TIMEOUT"; then
            log "✓ Endpoint $endpoint respondió correctamente"
            return 0
        fi
    done
    
    log "✗ Ningún endpoint HTTP respondió"
    return 1
}

# Verificación 4: Uso de memoria
check_memory() {
    log "Verificando uso de memoria..."
    
    if [ ! -f /proc/meminfo ]; then
        log "~ Verificación de memoria omitida (no disponible)"
        return 0
    fi
    
    # Obtener memoria disponible
    local mem_available=$(awk '/MemAvailable/ {print $2}' /proc/meminfo 2>/dev/null || echo "0")
    local mem_total=$(awk '/MemTotal/ {print $2}' /proc/meminfo 2>/dev/null || echo "1")
    
    if [ "$mem_total" -eq 0 ]; then
        log "~ Verificación de memoria omitida (no se puede calcular)"
        return 0
    fi
    
    # Calcular porcentaje de uso
    local mem_used_percent=$(( (mem_total - mem_available) * 100 / mem_total ))
    
    if [ "$mem_used_percent" -lt 90 ]; then
        log "✓ Uso de memoria OK: ${mem_used_percent}%"
        return 0
    else
        log "⚠ Uso de memoria alto: ${mem_used_percent}%"
        # Warning, pero no falla el healthcheck
        return 0
    fi
}

# Verificación 5: Espacio en disco
check_disk() {
    log "Verificando espacio en disco..."
    
    # Verificar espacio disponible en /tmp
    if command -v df >/dev/null 2>&1; then
        local disk_usage=$(df /tmp | awk 'NR==2 {print $(NF-1)}' | sed 's/%//')
        
        if [ "$disk_usage" -lt 95 ]; then
            log "✓ Espacio en disco OK: ${disk_usage}% usado"
            return 0
        else
            log "⚠ Poco espacio en disco: ${disk_usage}% usado"
            return 0  # Warning, pero no falla
        fi
    else
        log "~ Verificación de disco omitida (df no disponible)"
        return 0
    fi
}

# Función principal
main() {
    log "=== Iniciando healthcheck personalizado ==="
    
    local exit_code=0
    
    # Ejecutar verificaciones
    check_process || exit_code=1
    check_port || exit_code=1
    check_http || exit_code=1
    check_memory || true  # No falla el healthcheck
    check_disk || true    # No falla el healthcheck
    
    if [ $exit_code -eq 0 ]; then
        log "=== Healthcheck EXITOSO ==="
    else
        log "=== Healthcheck FALLIDO ==="
    fi
    
    # Limpiar log antiguo (mantener solo últimas 100 líneas)
    if [ -f "$LOG_FILE" ]; then
        tail -100 "$LOG_FILE" > "${LOG_FILE}.tmp" 2>/dev/null && mv "${LOG_FILE}.tmp" "$LOG_FILE" 2>/dev/null || true
    fi
    
    exit $exit_code
}

# Ejecutar función principal
main "$@" 