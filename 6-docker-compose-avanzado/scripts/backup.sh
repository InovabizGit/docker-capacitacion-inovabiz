#!/bin/bash
set -euo pipefail

# =================================
# Backup Script for Production Stack
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

# Default configuration
BACKUP_DIR="$PROJECT_ROOT/backups"
RETENTION_DAYS=7
COMPRESS=true
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

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

# Create backup directory
prepare_backup_dir() {
    mkdir -p "$BACKUP_DIR"
    log "Backup directory: $BACKUP_DIR"
}

# Backup PostgreSQL database
backup_database() {
    log "Starting database backup..."
    
    local backup_file="$BACKUP_DIR/database_${TIMESTAMP}.sql"
    
    # Get database configuration from environment
    local db_name="${DB_NAME:-prodapp}"
    local db_user="${DB_USER:-postgres}"
    
    # Create database backup
    if docker-compose -f "$COMPOSE_FILE" exec -T database pg_dump -U "$db_user" -d "$db_name" > "$backup_file"; then
        if [[ "$COMPRESS" == "true" ]]; then
            gzip "$backup_file"
            backup_file="${backup_file}.gz"
        fi
        
        local backup_size
        backup_size=$(du -h "$backup_file" | cut -f1)
        success "Database backup completed: $backup_file ($backup_size)"
        return 0
    else
        error "Database backup failed"
        return 1
    fi
}

# Backup Redis data
backup_redis() {
    log "Starting Redis backup..."
    
    local backup_file="$BACKUP_DIR/redis_${TIMESTAMP}.rdb"
    
    # Force Redis to save current dataset
    if docker-compose -f "$COMPOSE_FILE" exec -T cache redis-cli BGSAVE; then
        # Wait for background save to complete
        sleep 5
        
        # Copy RDB file from container
        if docker-compose -f "$COMPOSE_FILE" exec -T cache cat /data/dump.rdb > "$backup_file"; then
            if [[ "$COMPRESS" == "true" ]]; then
                gzip "$backup_file"
                backup_file="${backup_file}.gz"
            fi
            
            local backup_size
            backup_size=$(du -h "$backup_file" | cut -f1)
            success "Redis backup completed: $backup_file ($backup_size)"
            return 0
        fi
    fi
    
    error "Redis backup failed"
    return 1
}

# Backup Docker volumes
backup_volumes() {
    log "Starting volumes backup..."
    
    local volumes_dir="$BACKUP_DIR/volumes_${TIMESTAMP}"
    mkdir -p "$volumes_dir"
    
    # List of volumes to backup
    local volumes=("db_data" "cache_data" "prometheus_data" "grafana_data")
    
    for volume in "${volumes[@]}"; do
        log "Backing up volume: $volume"
        
        local volume_backup="$volumes_dir/${volume}.tar"
        
        # Create tar archive of volume data
        if docker run --rm \
            -v "${PWD}_${volume}:/volume" \
            -v "$volumes_dir:/backup" \
            alpine:latest \
            tar -czf "/backup/${volume}.tar.gz" -C /volume . 2>/dev/null; then
            
            local backup_size
            backup_size=$(du -h "$volumes_dir/${volume}.tar.gz" | cut -f1)
            success "Volume $volume backup completed ($backup_size)"
        else
            warning "Failed to backup volume: $volume"
        fi
    done
    
    success "Volumes backup completed in: $volumes_dir"
}

# Backup application configuration
backup_config() {
    log "Starting configuration backup..."
    
    local config_backup="$BACKUP_DIR/config_${TIMESTAMP}.tar.gz"
    
    # Files to backup
    local config_files=(
        "$PROJECT_ROOT/.env"
        "$PROJECT_ROOT/env-example"
        "$COMPOSE_FILE"
        "$PROJECT_ROOT/infrastructure/"
        "$PROJECT_ROOT/scripts/"
    )
    
    # Create configuration backup
    tar -czf "$config_backup" -C "$PROJECT_ROOT" \
        --exclude="*.log" \
        --exclude="node_modules" \
        --exclude=".git" \
        $(printf "%s " "${config_files[@]/#/$PROJECT_ROOT/}" | sed "s|$PROJECT_ROOT/||g") 2>/dev/null || true
    
    if [[ -f "$config_backup" ]]; then
        local backup_size
        backup_size=$(du -h "$config_backup" | cut -f1)
        success "Configuration backup completed: $config_backup ($backup_size)"
    else
        warning "Configuration backup may be incomplete"
    fi
}

# Clean old backups
cleanup_old_backups() {
    log "Cleaning up backups older than $RETENTION_DAYS days..."
    
    if [[ -d "$BACKUP_DIR" ]]; then
        find "$BACKUP_DIR" -type f -mtime +$RETENTION_DAYS -delete 2>/dev/null || true
        find "$BACKUP_DIR" -type d -empty -delete 2>/dev/null || true
        success "Old backups cleaned up"
    fi
}

# Verify backup integrity
verify_backup() {
    local backup_file="$1"
    
    if [[ ! -f "$backup_file" ]]; then
        error "Backup file not found: $backup_file"
        return 1
    fi
    
    # Check if it's a gzip file
    if [[ "$backup_file" == *.gz ]]; then
        if gzip -t "$backup_file" 2>/dev/null; then
            success "Backup integrity verified: $backup_file"
            return 0
        else
            error "Backup integrity check failed: $backup_file"
            return 1
        fi
    fi
    
    # For non-compressed files, just check if readable
    if [[ -r "$backup_file" ]]; then
        success "Backup file is readable: $backup_file"
        return 0
    else
        error "Backup file is not readable: $backup_file"
        return 1
    fi
}

# Create backup manifest
create_manifest() {
    local manifest_file="$BACKUP_DIR/backup_${TIMESTAMP}_manifest.txt"
    
    cat > "$manifest_file" << EOF
# Backup Manifest
# Generated: $(date)
# Timestamp: $TIMESTAMP

## Backup Information
Backup Directory: $BACKUP_DIR
Retention Days: $RETENTION_DAYS
Compression: $COMPRESS

## Services Status
$(docker-compose -f "$COMPOSE_FILE" ps --format "table {{.Name}}\t{{.State}}\t{{.Status}}")

## Backup Files
$(find "$BACKUP_DIR" -name "*${TIMESTAMP}*" -type f -exec ls -lh {} \; | awk '{print $9 " (" $5 ")"}')

## Environment Variables
DB_NAME: ${DB_NAME:-prodapp}
DB_USER: ${DB_USER:-postgres}
NODE_ENV: ${NODE_ENV:-production}

## Docker Images
$(docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | head -10)

EOF

    success "Backup manifest created: $manifest_file"
}

# Full backup routine
full_backup() {
    log "Starting full backup routine..."
    
    prepare_backup_dir
    
    local backup_success=true
    
    # Backup database
    if ! backup_database; then
        backup_success=false
    fi
    
    # Backup Redis
    if ! backup_redis; then
        backup_success=false
    fi
    
    # Backup volumes
    backup_volumes
    
    # Backup configuration
    backup_config
    
    # Create manifest
    create_manifest
    
    # Cleanup old backups
    cleanup_old_backups
    
    if [[ "$backup_success" == "true" ]]; then
        success "🎉 Full backup completed successfully!"
        log "Backup location: $BACKUP_DIR"
    else
        warning "⚠️  Backup completed with some errors"
    fi
}

# Restore database from backup
restore_database() {
    local backup_file="$1"
    
    if [[ ! -f "$backup_file" ]]; then
        error "Backup file not found: $backup_file"
        return 1
    fi
    
    log "Restoring database from: $backup_file"
    
    local db_name="${DB_NAME:-prodapp}"
    local db_user="${DB_USER:-postgres}"
    
    # Determine if file is compressed
    if [[ "$backup_file" == *.gz ]]; then
        zcat "$backup_file" | docker-compose -f "$COMPOSE_FILE" exec -T database psql -U "$db_user" -d "$db_name"
    else
        cat "$backup_file" | docker-compose -f "$COMPOSE_FILE" exec -T database psql -U "$db_user" -d "$db_name"
    fi
    
    success "Database restore completed"
}

# List available backups
list_backups() {
    log "Available backups in $BACKUP_DIR:"
    
    if [[ -d "$BACKUP_DIR" ]]; then
        find "$BACKUP_DIR" -name "*.sql*" -o -name "*.rdb*" -o -name "*.tar.gz" | sort -r | head -20 | while read -r backup; do
            local size
            size=$(du -h "$backup" | cut -f1)
            local date
            date=$(stat -c %y "$backup" | cut -d' ' -f1)
            echo "   $(basename "$backup") - $size - $date"
        done
    else
        warning "Backup directory does not exist: $BACKUP_DIR"
    fi
}

usage() {
    cat << EOF
Usage: $0 [COMMAND] [OPTIONS]

Backup and restore utilities for production stack

COMMANDS:
    full        Create full backup (default)
    database    Backup database only
    redis       Backup Redis only
    volumes     Backup volumes only
    config      Backup configuration only
    restore     Restore database from backup file
    list        List available backups
    cleanup     Clean old backups

OPTIONS:
    --backup-dir DIR       Backup directory (default: ./backups)
    --retention-days DAYS  Retention period in days (default: 7)
    --no-compress         Don't compress backups
    --file FILE           Backup file for restore operation

EXAMPLES:
    $0                           # Full backup
    $0 database                  # Database backup only
    $0 restore --file backup.sql # Restore from specific file
    $0 list                      # List available backups
    $0 cleanup                   # Clean old backups

EOF
}

# Parse arguments
COMMAND="full"

while [[ $# -gt 0 ]]; do
    case $1 in
        full|database|redis|volumes|config|list|cleanup)
            COMMAND="$1"
            shift
            ;;
        restore)
            COMMAND="restore"
            shift
            ;;
        --backup-dir)
            BACKUP_DIR="$2"
            shift 2
            ;;
        --retention-days)
            RETENTION_DAYS="$2"
            shift 2
            ;;
        --no-compress)
            COMPRESS=false
            shift
            ;;
        --file)
            RESTORE_FILE="$2"
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
    full)
        full_backup
        ;;
    database)
        prepare_backup_dir
        backup_database
        ;;
    redis)
        prepare_backup_dir
        backup_redis
        ;;
    volumes)
        prepare_backup_dir
        backup_volumes
        ;;
    config)
        prepare_backup_dir
        backup_config
        ;;
    restore)
        if [[ -z "${RESTORE_FILE:-}" ]]; then
            error "Restore file not specified. Use --file option"
            exit 1
        fi
        restore_database "$RESTORE_FILE"
        ;;
    list)
        list_backups
        ;;
    cleanup)
        cleanup_old_backups
        ;;
    *)
        error "Unknown command: $COMMAND"
        usage
        exit 1
        ;;
esac 