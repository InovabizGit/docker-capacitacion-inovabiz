#!/bin/bash
set -euo pipefail

# =================================
# Load Testing Script
# =================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default configuration
BASE_URL="http://localhost"
CONCURRENT_USERS=10
DURATION=60
RAMP_UP_TIME=10
TEST_TYPE="mixed"

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

# Check if services are running
check_services() {
    log "Checking if services are available..."
    
    local endpoints=("$BASE_URL/health" "$BASE_URL/api/info")
    
    for endpoint in "${endpoints[@]}"; do
        if curl -s -f "$endpoint" > /dev/null; then
            success "✓ $endpoint is responding"
        else
            error "✗ $endpoint is not responding"
            return 1
        fi
    done
    
    success "All services are ready for testing"
}

# Simple load test using curl
simple_load_test() {
    log "Starting simple load test..."
    log "Configuration: $CONCURRENT_USERS users, ${DURATION}s duration"
    
    local pids=()
    local results_dir="/tmp/load_test_$(date +%s)"
    mkdir -p "$results_dir"
    
    # Start concurrent users
    for ((i=1; i<=CONCURRENT_USERS; i++)); do
        {
            local requests=0
            local successful=0
            local start_time=$(date +%s)
            local end_time=$((start_time + DURATION))
            
            while [[ $(date +%s) -lt $end_time ]]; do
                local url
                case $((RANDOM % 4)) in
                    0) url="$BASE_URL/api/info" ;;
                    1) url="$BASE_URL/api/users" ;;
                    2) url="$BASE_URL/health" ;;
                    3) url="$BASE_URL/api/stress?duration=100" ;;
                esac
                
                if curl -s -w "%{http_code}" -o /dev/null "$url" | grep -q "^200"; then
                    successful=$((successful + 1))
                fi
                requests=$((requests + 1))
                
                # Small delay to avoid overwhelming
                sleep 0.1
            done
            
            echo "$i,$requests,$successful" > "$results_dir/user_$i.csv"
        } &
        pids+=($!)
        
        # Ramp up delay
        sleep $((RAMP_UP_TIME / CONCURRENT_USERS))
    done
    
    # Wait for all users to finish
    log "Load test in progress... (${DURATION}s)"
    for pid in "${pids[@]}"; do
        wait "$pid"
    done
    
    # Aggregate results
    local total_requests=0
    local total_successful=0
    
    for result_file in "$results_dir"/*.csv; do
        if [[ -f "$result_file" ]]; then
            local user_data
            user_data=$(cat "$result_file")
            local requests=${user_data#*,}
            requests=${requests%,*}
            local successful=${user_data##*,}
            
            total_requests=$((total_requests + requests))
            total_successful=$((total_successful + successful))
        fi
    done
    
    # Calculate metrics
    local success_rate=0
    if [[ $total_requests -gt 0 ]]; then
        success_rate=$((total_successful * 100 / total_requests))
    fi
    
    local rps=$((total_requests / DURATION))
    
    # Display results
    echo
    success "Load Test Results:"
    echo "   Total Requests: $total_requests"
    echo "   Successful: $total_successful"
    echo "   Success Rate: ${success_rate}%"
    echo "   Requests/sec: $rps"
    echo "   Duration: ${DURATION}s"
    echo "   Concurrent Users: $CONCURRENT_USERS"
    
    # Cleanup
    rm -rf "$results_dir"
}

# Stress test specific endpoint
stress_test_endpoint() {
    local endpoint="$1"
    local requests="$2"
    
    log "Stress testing: $endpoint"
    log "Target requests: $requests"
    
    local start_time=$(date +%s)
    local successful=0
    local failed=0
    local total_time=0
    
    for ((i=1; i<=requests; i++)); do
        local request_start=$(date +%s%3N)
        
        if curl -s -f "$BASE_URL$endpoint" > /dev/null; then
            successful=$((successful + 1))
        else
            failed=$((failed + 1))
        fi
        
        local request_end=$(date +%s%3N)
        local request_time=$((request_end - request_start))
        total_time=$((total_time + request_time))
        
        # Progress indicator
        if [[ $((i % 10)) -eq 0 ]]; then
            echo -n "."
        fi
    done
    
    echo
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local avg_response_time=$((total_time / requests))
    local rps=$((requests / duration))
    
    success "Stress Test Results for $endpoint:"
    echo "   Requests: $requests"
    echo "   Successful: $successful"
    echo "   Failed: $failed"
    echo "   Duration: ${duration}s"
    echo "   Avg Response Time: ${avg_response_time}ms"
    echo "   Requests/sec: $rps"
}

# Database load test
database_load_test() {
    log "Starting database load test..."
    
    local users_created=0
    local users_fetched=0
    local start_time=$(date +%s)
    
    # Create test users
    for ((i=1; i<=20; i++)); do
        local user_data="{\"name\":\"LoadTest User $i\",\"email\":\"loadtest$i@example.com\"}"
        
        if curl -s -X POST \
            -H "Content-Type: application/json" \
            -d "$user_data" \
            "$BASE_URL/api/users" > /dev/null; then
            users_created=$((users_created + 1))
        fi
        
        echo -n "+"
    done
    
    echo
    
    # Fetch users multiple times
    for ((i=1; i<=50; i++)); do
        if curl -s "$BASE_URL/api/users" > /dev/null; then
            users_fetched=$((users_fetched + 1))
        fi
        
        echo -n "."
    done
    
    echo
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    success "Database Load Test Results:"
    echo "   Users Created: $users_created/20"
    echo "   Users Fetched: $users_fetched/50"
    echo "   Duration: ${duration}s"
}

# Monitor system during test
monitor_system() {
    local monitor_duration="$1"
    local output_file="/tmp/system_monitor_$(date +%s).log"
    
    log "Monitoring system for ${monitor_duration}s..."
    
    {
        echo "# System Monitoring Report"
        echo "# Started: $(date)"
        echo
        
        for ((i=1; i<=monitor_duration; i++)); do
            echo "## Time: ${i}s"
            echo "### Docker Stats"
            docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" 2>/dev/null || echo "Error getting docker stats"
            echo
            echo "### System Load"
            uptime 2>/dev/null || echo "System load unavailable"
            echo
            echo "---"
            sleep 1
        done
        
        echo "# Monitoring completed: $(date)"
    } > "$output_file"
    
    success "System monitoring saved to: $output_file"
}

# Full performance test suite
full_performance_test() {
    log "Starting full performance test suite..."
    
    check_services
    
    # Start system monitoring in background
    monitor_system $((DURATION + 30)) &
    local monitor_pid=$!
    
    # Run load tests
    log "=== Phase 1: Simple Load Test ==="
    simple_load_test
    
    sleep 5
    
    log "=== Phase 2: API Stress Test ==="
    stress_test_endpoint "/api/info" 100
    
    sleep 5
    
    log "=== Phase 3: Database Load Test ==="
    database_load_test
    
    sleep 5
    
    log "=== Phase 4: Health Check Stress ==="
    stress_test_endpoint "/health" 200
    
    # Stop monitoring
    kill $monitor_pid 2>/dev/null || true
    
    success "🎉 Full performance test suite completed!"
    
    # Show final system status
    log "Final system status:"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" 2>/dev/null || echo "Unable to get stats"
}

usage() {
    cat << EOF
Usage: $0 [COMMAND] [OPTIONS]

Load testing utilities for production stack

COMMANDS:
    simple      Simple load test with concurrent users (default)
    stress      Stress test specific endpoint
    database    Database-focused load test
    monitor     Monitor system performance
    full        Full performance test suite

OPTIONS:
    --url URL           Base URL for testing (default: http://localhost)
    --users NUMBER      Concurrent users for load test (default: 10)
    --duration SECONDS  Test duration in seconds (default: 60)
    --rampup SECONDS    Ramp-up time for users (default: 10)
    --endpoint PATH     Endpoint for stress test
    --requests NUMBER   Number of requests for stress test

EXAMPLES:
    $0                                    # Simple load test
    $0 --users 20 --duration 120        # 20 users for 2 minutes
    $0 stress --endpoint /api/users --requests 1000
    $0 full                              # Complete test suite
    $0 monitor --duration 300           # Monitor for 5 minutes

EOF
}

# Parse arguments
COMMAND="simple"

while [[ $# -gt 0 ]]; do
    case $1 in
        simple|stress|database|monitor|full)
            COMMAND="$1"
            shift
            ;;
        --url)
            BASE_URL="$2"
            shift 2
            ;;
        --users)
            CONCURRENT_USERS="$2"
            shift 2
            ;;
        --duration)
            DURATION="$2"
            shift 2
            ;;
        --rampup)
            RAMP_UP_TIME="$2"
            shift 2
            ;;
        --endpoint)
            STRESS_ENDPOINT="$2"
            shift 2
            ;;
        --requests)
            STRESS_REQUESTS="$2"
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

# Execute command
case $COMMAND in
    simple)
        check_services
        simple_load_test
        ;;
    stress)
        if [[ -z "${STRESS_ENDPOINT:-}" ]] || [[ -z "${STRESS_REQUESTS:-}" ]]; then
            error "Stress test requires --endpoint and --requests options"
            exit 1
        fi
        check_services
        stress_test_endpoint "$STRESS_ENDPOINT" "$STRESS_REQUESTS"
        ;;
    database)
        check_services
        database_load_test
        ;;
    monitor)
        monitor_system "$DURATION"
        ;;
    full)
        full_performance_test
        ;;
    *)
        error "Unknown command: $COMMAND"
        usage
        exit 1
        ;;
esac 