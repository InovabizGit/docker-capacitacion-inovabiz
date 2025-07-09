#!/bin/bash
set -euo pipefail

# =================================
# Auto-scaling Script
# =================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
COMPOSE_FILE="$PROJECT_ROOT/compose/docker-compose.yml"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
SERVICE_NAME="api"
MIN_REPLICAS=1
MAX_REPLICAS=5
CPU_THRESHOLD_UP=70
CPU_THRESHOLD_DOWN=30
CHECK_INTERVAL=30
SCALE_COOLDOWN=120

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Get current replica count
get_current_replicas() {
    docker-compose -f "$COMPOSE_FILE" ps "$SERVICE_NAME" --format "table {{.Name}}" | grep -c "$SERVICE_NAME" || echo "0"
}

# Get average CPU usage
get_cpu_usage() {
    local cpu_stats
    cpu_stats=$(docker stats --no-stream --format "{{.CPUPerc}}" $(docker-compose -f "$COMPOSE_FILE" ps -q "$SERVICE_NAME") 2>/dev/null || echo "")
    
    if [[ -z "$cpu_stats" ]]; then
        echo "0"
        return
    fi
    
    local total=0
    local count=0
    
    while IFS= read -r cpu; do
        if [[ -n "$cpu" ]]; then
            cpu_clean=${cpu%\%}
            total=$(echo "$total + $cpu_clean" | bc -l 2>/dev/null || echo "$total")
            count=$((count + 1))
        fi
    done <<< "$cpu_stats"
    
    if [[ $count -gt 0 ]]; then
        echo "scale=2; $total / $count" | bc -l 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

# Scale service up
scale_up() {
    local current_replicas=$1
    local new_replicas=$((current_replicas + 1))
    
    if [[ $new_replicas -le $MAX_REPLICAS ]]; then
        log "Scaling up $SERVICE_NAME from $current_replicas to $new_replicas replicas"
        docker-compose -f "$COMPOSE_FILE" up -d --scale "$SERVICE_NAME=$new_replicas"
        success "Scaled up to $new_replicas replicas"
        return 0
    else
        warning "Already at maximum replicas ($MAX_REPLICAS)"
        return 1
    fi
}

# Scale service down
scale_down() {
    local current_replicas=$1
    local new_replicas=$((current_replicas - 1))
    
    if [[ $new_replicas -ge $MIN_REPLICAS ]]; then
        log "Scaling down $SERVICE_NAME from $current_replicas to $new_replicas replicas"
        docker-compose -f "$COMPOSE_FILE" up -d --scale "$SERVICE_NAME=$new_replicas"
        success "Scaled down to $new_replicas replicas"
        return 0
    else
        warning "Already at minimum replicas ($MIN_REPLICAS)"
        return 1
    fi
}

# Check if we're in cooldown period
check_cooldown() {
    local last_scale_file="/tmp/docker_autoscale_$SERVICE_NAME"
    
    if [[ -f "$last_scale_file" ]]; then
        local last_scale
        last_scale=$(cat "$last_scale_file")
        local current_time
        current_time=$(date +%s)
        local time_diff=$((current_time - last_scale))
        
        if [[ $time_diff -lt $SCALE_COOLDOWN ]]; then
            return 1  # Still in cooldown
        fi
    fi
    
    return 0  # Not in cooldown
}

# Record scaling action
record_scaling() {
    local last_scale_file="/tmp/docker_autoscale_$SERVICE_NAME"
    date +%s > "$last_scale_file"
}

# Main scaling logic
auto_scale() {
    local current_replicas
    current_replicas=$(get_current_replicas)
    
    if [[ $current_replicas -eq 0 ]]; then
        error "No running instances of $SERVICE_NAME found"
        return 1
    fi
    
    local cpu_usage
    cpu_usage=$(get_cpu_usage)
    
    log "Current replicas: $current_replicas, Average CPU: ${cpu_usage}%"
    
    # Check if scaling action is needed
    if (( $(echo "$cpu_usage > $CPU_THRESHOLD_UP" | bc -l) )); then
        if check_cooldown; then
            if scale_up "$current_replicas"; then
                record_scaling
                log "Scaled up due to high CPU usage (${cpu_usage}% > ${CPU_THRESHOLD_UP}%)"
            fi
        else
            log "Scale up requested but in cooldown period"
        fi
    elif (( $(echo "$cpu_usage < $CPU_THRESHOLD_DOWN" | bc -l) )); then
        if check_cooldown; then
            if scale_down "$current_replicas"; then
                record_scaling
                log "Scaled down due to low CPU usage (${cpu_usage}% < ${CPU_THRESHOLD_DOWN}%)"
            fi
        else
            log "Scale down requested but in cooldown period"
        fi
    else
        log "CPU usage within normal range (${CPU_THRESHOLD_DOWN}% - ${CPU_THRESHOLD_UP}%)"
    fi
}

# Show current status
show_status() {
    echo "📊 Auto-scaling Status:"
    echo "   Service: $SERVICE_NAME"
    echo "   Current replicas: $(get_current_replicas)"
    echo "   CPU usage: $(get_cpu_usage)%"
    echo "   Min/Max replicas: $MIN_REPLICAS/$MAX_REPLICAS"
    echo "   CPU thresholds: ${CPU_THRESHOLD_DOWN}%/${CPU_THRESHOLD_UP}%"
    echo "   Check interval: ${CHECK_INTERVAL}s"
    echo "   Cooldown: ${SCALE_COOLDOWN}s"
}

# Continuous monitoring mode
monitor() {
    log "Starting continuous auto-scaling monitor..."
    log "Press Ctrl+C to stop"
    
    while true; do
        auto_scale
        echo "---"
        sleep "$CHECK_INTERVAL"
    done
}

usage() {
    cat << EOF
Usage: $0 [COMMAND] [OPTIONS]

Auto-scaling for Docker Compose services

COMMANDS:
    check       Check current status and perform one scaling decision
    monitor     Start continuous monitoring (default)
    status      Show current scaling status
    scale-up    Manually scale up by 1 replica
    scale-down  Manually scale down by 1 replica

OPTIONS:
    --service NAME      Service to scale (default: api)
    --min REPLICAS      Minimum replicas (default: 1)
    --max REPLICAS      Maximum replicas (default: 5)
    --cpu-up PERCENT    CPU threshold for scaling up (default: 70)
    --cpu-down PERCENT  CPU threshold for scaling down (default: 30)
    --interval SECONDS  Check interval (default: 30)
    --cooldown SECONDS  Cooldown between scaling actions (default: 120)

EXAMPLES:
    $0                          # Start continuous monitoring
    $0 check                    # Check once and exit
    $0 --service worker --max 3 # Monitor worker service with max 3 replicas
    $0 scale-up                 # Manually add one replica

EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        check)
            auto_scale
            exit 0
            ;;
        monitor)
            monitor
            exit 0
            ;;
        status)
            show_status
            exit 0
            ;;
        scale-up)
            current=$(get_current_replicas)
            scale_up "$current"
            exit $?
            ;;
        scale-down)
            current=$(get_current_replicas)
            scale_down "$current"
            exit $?
            ;;
        --service)
            SERVICE_NAME="$2"
            shift 2
            ;;
        --min)
            MIN_REPLICAS="$2"
            shift 2
            ;;
        --max)
            MAX_REPLICAS="$2"
            shift 2
            ;;
        --cpu-up)
            CPU_THRESHOLD_UP="$2"
            shift 2
            ;;
        --cpu-down)
            CPU_THRESHOLD_DOWN="$2"
            shift 2
            ;;
        --interval)
            CHECK_INTERVAL="$2"
            shift 2
            ;;
        --cooldown)
            SCALE_COOLDOWN="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Default action is monitor
monitor 