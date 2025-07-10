#!/bin/bash
#
# Monitor de Healthchecks - Script de monitoreo automatizado
# Verifica el estado de contenedores y genera alertas
#

set -euo pipefail

# Configuración
MONITOR_INTERVAL=${MONITOR_INTERVAL:-30}
LOG_FILE=${LOG_FILE:-/var/log/docker-health-monitor.log}
ALERT_WEBHOOK=${SLACK_WEBHOOK_URL:-}
EMAIL_TO=${EMAIL_TO:-}
MAX_LOG_LINES=${MAX_LOG_LINES:-1000}

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función de logging con timestamp
log_message() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo -e "[${timestamp}] [${level}] ${message}" | tee -a "$LOG_FILE"
}

# Función de logging con colores para terminal
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
    log_message "INFO" "$*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
    log_message "WARN" "$*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
    log_message "ERROR" "$*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
    log_message "SUCCESS" "$*"
}

# Enviar alerta por Slack
send_slack_alert() {
    local message="$1"
    
    if [ -n "$ALERT_WEBHOOK" ]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"🚨 Docker Health Alert: $message\"}" \
            "$ALERT_WEBHOOK" >/dev/null 2>&1 || \
            log_error "Error enviando alerta a Slack"
    fi
}

# Enviar alerta por email (requiere mailx o sendmail)
send_email_alert() {
    local subject="$1"
    local message="$2"
    
    if [ -n "$EMAIL_TO" ] && command -v mail >/dev/null 2>&1; then
        echo "$message" | mail -s "$subject" "$EMAIL_TO" >/dev/null 2>&1 || \
            log_error "Error enviando email"
    fi
}

# Enviar alerta combinada
send_alert() {
    local container="$1"
    local status="$2"
    local message="Container $container is $status"
    
    log_error "$message"
    send_slack_alert "$message"
    send_email_alert "Docker Health Alert: $container" "$message"
}

# Obtener lista de contenedores con healthcheck
get_containers_with_healthcheck() {
    docker ps --format '{{.Names}}' | while read -r container; do
        if docker inspect "$container" 2>/dev/null | jq -e '.[0].Config.Healthcheck' >/dev/null 2>&1; then
            echo "$container"
        fi
    done
}

# Verificar estado de healthcheck de un contenedor
check_container_health() {
    local container="$1"
    
    if ! docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        return 1 # Contenedor no está corriendo
    fi
    
    local health_status=$(docker inspect --format='{{.State.Health.Status}}' "$container" 2>/dev/null || echo "none")
    echo "$health_status"
}

# Obtener último log de healthcheck
get_last_healthcheck_log() {
    local container="$1"
    docker inspect "$container" 2>/dev/null | \
        jq -r '.[0].State.Health.Log[-1] | "\(.Start) - \(.ExitCode) - \(.Output)"' 2>/dev/null || \
        echo "No health logs available"
}

# Verificar un contenedor específico
monitor_container() {
    local container="$1"
    local health_status
    
    health_status=$(check_container_health "$container")
    
    case "$health_status" in
        "healthy")
            log_success "✓ $container is healthy"
            return 0
            ;;
        "unhealthy")
            send_alert "$container" "UNHEALTHY"
            local last_log=$(get_last_healthcheck_log "$container")
            log_error "Last healthcheck log: $last_log"
            return 1
            ;;
        "starting")
            log_info "⏳ $container is starting (health check in progress)"
            return 0
            ;;
        "none")
            log_warn "⚪ $container has no healthcheck configured"
            return 0
            ;;
        *)
            log_error "❓ $container has unknown health status: $health_status"
            return 1
            ;;
    esac
}

# Generar reporte de estado
generate_status_report() {
    local containers_healthy=0
    local containers_unhealthy=0
    local containers_starting=0
    local containers_no_health=0
    local unhealthy_list=""
    
    log_info "=== Health Status Report ==="
    
    while read -r container; do
        if [ -z "$container" ]; then continue; fi
        
        local health_status=$(check_container_health "$container")
        
        case "$health_status" in
            "healthy")
                ((containers_healthy++))
                ;;
            "unhealthy")
                ((containers_unhealthy++))
                unhealthy_list="$unhealthy_list $container"
                ;;
            "starting")
                ((containers_starting++))
                ;;
            "none")
                ((containers_no_health++))
                ;;
        esac
    done < <(docker ps --format '{{.Names}}')
    
    log_info "Summary:"
    log_info "  Healthy: $containers_healthy"
    log_info "  Unhealthy: $containers_unhealthy"
    log_info "  Starting: $containers_starting"
    log_info "  No healthcheck: $containers_no_health"
    
    if [ $containers_unhealthy -gt 0 ]; then
        log_error "Unhealthy containers:$unhealthy_list"
        return 1
    fi
    
    return 0
}

# Función de cleanup y rotación de logs
cleanup_logs() {
    if [ -f "$LOG_FILE" ] && [ $(wc -l < "$LOG_FILE") -gt $MAX_LOG_LINES ]; then
        tail -n $((MAX_LOG_LINES / 2)) "$LOG_FILE" > "${LOG_FILE}.tmp"
        mv "${LOG_FILE}.tmp" "$LOG_FILE"
        log_info "Log file rotated (keeping last $((MAX_LOG_LINES / 2)) lines)"
    fi
}

# Modo de monitoreo continuo
continuous_monitor() {
    log_info "Starting continuous health monitoring (interval: ${MONITOR_INTERVAL}s)"
    log_info "Log file: $LOG_FILE"
    
    if [ -n "$ALERT_WEBHOOK" ]; then
        log_info "Slack alerts enabled"
    fi
    
    if [ -n "$EMAIL_TO" ]; then
        log_info "Email alerts enabled for: $EMAIL_TO"
    fi
    
    local iteration=0
    
    while true; do
        ((iteration++))
        
        log_info "=== Monitor iteration $iteration ==="
        
        # Verificar si Docker está disponible
        if ! docker info >/dev/null 2>&1; then
            log_error "Docker is not available"
            sleep "$MONITOR_INTERVAL"
            continue
        fi
        
        # Obtener contenedores con healthcheck
        local containers_with_health
        containers_with_health=$(get_containers_with_healthcheck)
        
        if [ -z "$containers_with_health" ]; then
            log_warn "No containers with healthcheck found"
        else
            log_info "Monitoring containers: $(echo "$containers_with_health" | tr '\n' ' ')"
            
            # Monitorear cada contenedor
            while read -r container; do
                if [ -n "$container" ]; then
                    monitor_container "$container"
                fi
            done <<< "$containers_with_health"
        fi
        
        # Generar reporte de estado cada 10 iteraciones
        if [ $((iteration % 10)) -eq 0 ]; then
            generate_status_report
            cleanup_logs
        fi
        
        log_info "Next check in ${MONITOR_INTERVAL} seconds..."
        sleep "$MONITOR_INTERVAL"
    done
}

# Modo de verificación única
single_check() {
    log_info "Performing single health check..."
    
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker is not available"
        exit 1
    fi
    
    local containers_with_health
    containers_with_health=$(get_containers_with_healthcheck)
    
    if [ -z "$containers_with_health" ]; then
        log_warn "No containers with healthcheck found"
        exit 0
    fi
    
    local failed_containers=0
    
    while read -r container; do
        if [ -n "$container" ]; then
            if ! monitor_container "$container"; then
                ((failed_containers++))
            fi
        fi
    done <<< "$containers_with_health"
    
    generate_status_report
    
    if [ $failed_containers -gt 0 ]; then
        log_error "Health check completed with $failed_containers failed containers"
        exit 1
    else
        log_success "All containers are healthy!"
        exit 0
    fi
}

# Mostrar ayuda
show_help() {
    cat << EOF
Docker Health Monitor - Monitoreo automatizado de healthchecks

USAGE:
    $0 [OPTIONS] [COMMAND]

COMMANDS:
    monitor     Monitoreo continuo (default)
    check       Verificación única
    help        Mostrar esta ayuda

OPTIONS:
    -i, --interval SECONDS    Intervalo de monitoreo (default: 30)
    -l, --log-file FILE       Archivo de log (default: /var/log/docker-health-monitor.log)
    -w, --webhook URL         Webhook de Slack para alertas
    -e, --email EMAIL         Email para alertas

VARIABLES DE ENTORNO:
    MONITOR_INTERVAL          Intervalo de monitoreo en segundos
    LOG_FILE                  Archivo de log
    SLACK_WEBHOOK_URL         URL del webhook de Slack
    EMAIL_TO                  Email para alertas

EJEMPLOS:
    $0                                    # Monitoreo continuo con configuración por defecto
    $0 check                              # Verificación única
    $0 -i 60 monitor                      # Monitoreo cada 60 segundos
    $0 -w https://hooks.slack.com/... monitor    # Con alertas de Slack

EOF
}

# Función principal
main() {
    local command="monitor"
    
    # Procesar argumentos
    while [[ $# -gt 0 ]]; do
        case $1 in
            -i|--interval)
                MONITOR_INTERVAL="$2"
                shift 2
                ;;
            -l|--log-file)
                LOG_FILE="$2"
                shift 2
                ;;
            -w|--webhook)
                ALERT_WEBHOOK="$2"
                shift 2
                ;;
            -e|--email)
                EMAIL_TO="$2"
                shift 2
                ;;
            check|monitor|help)
                command="$1"
                shift
                ;;
            -h|--help)
                command="help"
                shift
                ;;
            *)
                echo "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # Crear directorio de log si no existe
    mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true
    
    # Ejecutar comando
    case "$command" in
        "monitor")
            continuous_monitor
            ;;
        "check")
            single_check
            ;;
        "help")
            show_help
            ;;
        *)
            echo "Unknown command: $command"
            exit 1
            ;;
    esac
}

# Manejar señales para cleanup
trap 'log_info "Monitoring stopped"; exit 0' SIGTERM SIGINT

# Ejecutar función principal con todos los argumentos
main "$@" 