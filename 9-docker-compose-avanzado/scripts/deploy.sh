#!/bin/bash
set -euo pipefail

# =================================
# Production Deployment Script
# =================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
COMPOSE_FILE="$PROJECT_ROOT/compose/docker-compose.yml"
ENV_FILE="$PROJECT_ROOT/.env"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
PROFILE="full"
BUILD_FRESH=false
RUN_TESTS=false
VERBOSE=false

# Helper functions
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

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Deploy Production Docker Compose Stack

OPTIONS:
    -p, --profile PROFILE    Docker Compose profile to deploy (default: full)
                           Available: full, api, frontend, monitoring, db, cache
    -b, --build             Force rebuild all images
    -t, --test              Run health checks after deployment
    -v, --verbose           Verbose output
    -h, --help              Show this help message

PROFILES:
    full         Complete stack with all services
    api          API backend + database + cache
    frontend     Frontend + load balancer
    monitoring   Prometheus + Grafana
    db           Database only
    cache        Redis cache only

EXAMPLES:
    $0                      # Deploy full stack
    $0 -p api -b           # Deploy API stack with fresh build
    $0 -p monitoring -t    # Deploy monitoring with health checks
    $0 --build --test      # Full deployment with build and tests

EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -p|--profile)
                PROFILE="$2"
                shift 2
                ;;
            -b|--build)
                BUILD_FRESH=true
                shift
                ;;
            -t|--test)
                RUN_TESTS=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
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
}

# Validate environment
validate_environment() {
    log "Validating environment..."
    
    # Check if Docker is running
    if ! docker info > /dev/null 2>&1; then
        error "Docker is not running or not accessible"
        exit 1
    fi
    
    # Check if Docker Compose is available
    if ! command -v docker-compose > /dev/null 2>&1; then
        error "docker-compose is not installed"
        exit 1
    fi
    
    # Check if compose file exists
    if [[ ! -f "$COMPOSE_FILE" ]]; then
        error "Docker Compose file not found: $COMPOSE_FILE"
        exit 1
    fi
    
    # Check if .env file exists
    if [[ ! -f "$ENV_FILE" ]]; then
        warning ".env file not found, using defaults"
        warning "Copy env-example to .env and configure it"
    fi
    
    success "Environment validation passed"
}

# Pre-deployment cleanup
cleanup_old_resources() {
    log "Cleaning up old resources..."
    
    # Remove orphaned containers
    docker-compose -f "$COMPOSE_FILE" down --remove-orphans > /dev/null 2>&1 || true
    
    # Clean up unused networks
    docker network prune -f > /dev/null 2>&1 || true
    
    # Clean up unused volumes (be careful!)
    if [[ "$BUILD_FRESH" == "true" ]]; then
        warning "Cleaning up unused volumes..."
        docker volume prune -f > /dev/null 2>&1 || true
    fi
    
    success "Cleanup completed"
}

# Build or pull images
prepare_images() {
    log "Preparing Docker images..."
    
    if [[ "$BUILD_FRESH" == "true" ]]; then
        log "Building fresh images..."
        docker-compose -f "$COMPOSE_FILE" build --no-cache --parallel
    else
        log "Pulling/building images..."
        docker-compose -f "$COMPOSE_FILE" build --parallel
        docker-compose -f "$COMPOSE_FILE" pull --parallel || true
    fi
    
    success "Images prepared"
}

# Deploy stack
deploy_stack() {
    log "Deploying stack with profile: $PROFILE"
    
    local deploy_args=(
        "-f" "$COMPOSE_FILE"
        "--profile" "$PROFILE"
        "up" "-d"
        "--remove-orphans"
    )
    
    if [[ "$VERBOSE" == "true" ]]; then
        deploy_args+=("--no-log-prefix")
    fi
    
    docker-compose "${deploy_args[@]}"
    
    success "Stack deployed successfully"
}

# Wait for services to be healthy
wait_for_health() {
    log "Waiting for services to become healthy..."
    
    local timeout=300  # 5 minutes
    local interval=10
    local elapsed=0
    
    while [[ $elapsed -lt $timeout ]]; do
        local unhealthy_services
        unhealthy_services=$(docker-compose -f "$COMPOSE_FILE" ps --filter "health=unhealthy" --services 2>/dev/null || echo "")
        
        if [[ -z "$unhealthy_services" ]]; then
            success "All services are healthy"
            return 0
        fi
        
        log "Waiting for services: $unhealthy_services"
        sleep $interval
        elapsed=$((elapsed + interval))
    done
    
    error "Timeout waiting for services to become healthy"
    return 1
}

# Run health checks
run_health_checks() {
    log "Running health checks..."
    
    local services
    services=$(docker-compose -f "$COMPOSE_FILE" --profile "$PROFILE" config --services)
    
    local failed_checks=0
    
    for service in $services; do
        log "Checking $service..."
        
        if docker-compose -f "$COMPOSE_FILE" exec -T "$service" sh -c 'exit 0' > /dev/null 2>&1; then
            success "$service is running"
        else
            error "$service health check failed"
            failed_checks=$((failed_checks + 1))
        fi
    done
    
    if [[ $failed_checks -gt 0 ]]; then
        error "$failed_checks service(s) failed health checks"
        return 1
    fi
    
    success "All health checks passed"
}

# Show deployment status
show_status() {
    log "Deployment Status:"
    echo
    
    # Show running services
    docker-compose -f "$COMPOSE_FILE" ps
    echo
    
    # Show service URLs
    echo "🌐 Service URLs:"
    echo "   Frontend:    http://localhost:${FRONTEND_PORT:-80}"
    echo "   API Health:  http://localhost:${FRONTEND_PORT:-80}/health"
    echo "   Prometheus:  http://localhost:${PROMETHEUS_PORT:-9090}"
    echo "   Grafana:     http://localhost:${GRAFANA_PORT:-3001}"
    echo
    
    # Show resource usage
    echo "📊 Resource Usage:"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" $(docker-compose -f "$COMPOSE_FILE" ps -q) 2>/dev/null || echo "   Unable to fetch stats"
}

# Main deployment function
main() {
    parse_args "$@"
    
    log "Starting deployment with profile: $PROFILE"
    
    validate_environment
    cleanup_old_resources
    prepare_images
    deploy_stack
    wait_for_health
    
    if [[ "$RUN_TESTS" == "true" ]]; then
        run_health_checks
    fi
    
    show_status
    
    success "🚀 Deployment completed successfully!"
    log "Use 'docker-compose -f $COMPOSE_FILE logs -f' to view logs"
}

# Trap signals for cleanup
trap 'error "Deployment interrupted"; exit 130' INT TERM

# Run main function
main "$@" 