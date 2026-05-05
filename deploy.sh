#!/bin/bash
#
# Screeps Launcher Deployment Script
# Official screeps-launcher with MongoDB and Redis
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_header() { echo -e "${BLUE}=== $1 ===${NC}"; }

check_requirements() {
    log_info "Checking requirements..."

    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed!"
        exit 1
    fi

    if ! command -v docker compose &> /dev/null && ! docker compose version &> /dev/null; then
        log_error "Docker Compose is not installed!"
        exit 1
    fi

    if [ ! -f .screepsrc ]; then
        log_error ".screepsrc not found!"
        log_info "Create .screepsrc with your Steam API key"
        log_info "Run: ./setup-config.sh"
        log_info "Get your key from: https://steamcommunity.com/dev/apikey"
        exit 1
    fi

    if grep -q "YOUR_STEAM_API_KEY_HERE" .screepsrc 2>/dev/null; then
        log_error "Steam API key not configured in .screepsrc!"
        log_info "Edit .screepsrc and replace YOUR_STEAM_API_KEY_HERE with your actual key"
        log_info "Get your key from: https://steamcommunity.com/dev/apikey"
        exit 1
    fi

    log_info "Requirements check passed"
}

start_server() {
    log_header "Starting Screeps Server"

    log_info "Building Screeps image with Node.js 22..."
    docker compose build

    log_info "Starting services (this may take a few minutes on first run)..."
    docker compose up -d

    log_info "Waiting for MongoDB to be ready..."
    for i in {1..30}; do
        if docker exec screeps-mongo mongosh --eval "db.adminCommand('ping')" &>/dev/null; then
            log_info "MongoDB is ready"
            break
        fi
        sleep 2
    done

    log_info "Waiting for Screeps to initialize..."
    sleep 10

    log_info "Server started successfully!"
    show_status

    log_warn "First-time setup:"
    log_info "1. Initialize the database: ./deploy.sh init-db"
    log_info "2. Or reset all data: ./deploy.sh cli (then run: system.resetAllData())"
}

stop_server() {
    log_header "Stopping Screeps Server"
    docker compose down
    log_info "Server stopped"
}

restart_server() {
    log_header "Restarting Screeps Server"
    docker compose restart
    sleep 5
    show_status
}

reset_server() {
    log_header "RESETTING SERVER - ALL DATA WILL BE DELETED"

    echo -e "${RED}"
    echo "WARNING: This will delete:"
    echo "  - All game data"
    echo "  - All user accounts"
    echo "  - MongoDB database"
    echo "  - Redis cache"
    echo -e "${NC}"

    read -p "Type 'DELETE' to confirm: " -r
    if [[ $REPLY != "DELETE" ]]; then
        log_info "Reset cancelled"
        exit 0
    fi

    log_info "Stopping services..."
    docker compose down -v

    log_info "Removing volumes..."
    docker volume rm screeps-server_screeps-data 2>/dev/null || true
    docker volume rm screeps-server_mongo-data 2>/dev/null || true
    docker volume rm screeps-server_redis-data 2>/dev/null || true

    log_info "Server reset complete!"
    log_info "Starting fresh server..."
    start_server
}

init_db() {
    log_header "Initializing Database"

    if ! docker ps --format '{{.Names}}' | grep -q "screeps-server"; then
        log_error "Server is not running! Start it first with: ./deploy.sh start"
        exit 1
    fi

    # Wait for Screeps server to be fully initialized
    log_info "Waiting for Screeps server to be ready..."
    for i in {1..60}; do
        if docker exec screeps-server npx screeps version &>/dev/null 2>&1; then
            log_info "Screeps is ready"
            break
        fi
        if [ $i -eq 60 ]; then
            log_error "Screeps server failed to start after 60 seconds"
            docker logs screeps-server --tail 20
            exit 1
        fi
        sleep 2
    done

    # Check if running in interactive mode (has TTY)
    if [ -t 0 ]; then
        log_info "Connecting to CLI to initialize database..."
        log_info "Run this command in the CLI: system.resetAllData()"
        log_info "Then press Ctrl+C to exit"
        echo ""
        docker exec -it screeps-server npx screeps cli
    else
        log_info "Non-interactive mode detected (Jenkins/automation)"
        log_info "Initializing database automatically..."

        # Try to run the command and capture output
        if docker exec screeps-server sh -c "echo 'system.resetAllData()' | npx screeps cli" 2>&1; then
            log_info "Database initialized successfully"
        else
            log_error "Database initialization failed"
            log_info "Check logs: docker logs screeps-server"
            exit 1
        fi
    fi
}

show_status() {
    log_header "Screeps Server Status"
    docker compose ps
    echo ""

    if docker ps --format '{{.Names}}' | grep -q "screeps-server"; then
        echo -e "${GREEN}✓ Server is RUNNING${NC}"
        echo ""
        echo "Connection Info:"
        echo "  Game Port: 21025"
        echo ""
        echo "Connect via Steam:"
        echo "  Change Server → <your-server-ip>:21025"
    else
        echo -e "${RED}✗ Server is NOT RUNNING${NC}"
    fi
}

show_logs() {
    log_info "Showing logs (Ctrl+C to exit)..."
    docker compose logs -f screeps
}

cli_access() {
    log_info "Connecting to Screeps CLI..."
    log_info "Available commands:"
    log_info "  system.resetAllData() - Reset all data"
    log_info "  help() - Show help"
    log_info "Press Ctrl+C to exit"
    echo ""

    docker exec -it screeps-server npx screeps cli
}

backup_data() {
    log_header "Backing Up Server Data"

    BACKUP_DIR="./backups"
    BACKUP_FILE="screeps-backup-$(date +%Y%m%d-%H%M%S).tar.gz"

    mkdir -p "$BACKUP_DIR"

    log_info "Creating backup..."
    docker run --rm \
        -v screeps-server_mongo-data:/data/mongo \
        -v screeps-server_screeps-data:/data/screeps \
        -v "$(pwd)/$BACKUP_DIR:/backup" \
        alpine tar czf "/backup/$BACKUP_FILE" /data

    log_info "Backup created: $BACKUP_DIR/$BACKUP_FILE"
}

show_help() {
    cat << EOF
Screeps Launcher Deployment Script

Usage: $0 {start|stop|restart|reset|status|logs|cli|init-db|backup|help}

Commands:
  start     Start the Screeps server with MongoDB and Redis
  stop      Stop the server
  restart   Restart the server
  reset     Delete all data and start fresh (DESTRUCTIVE)
  status    Show server status
  logs      Show server logs (follow mode)
  cli       Connect to Screeps CLI console
  init-db   Initialize database (first-time setup)
  backup    Backup server data
  help      Show this help message

Configuration:
  Edit config.yml to configure your Steam API key and mods

Examples:
  $0 start          # Start the server
  $0 init-db        # First-time database setup
  $0 logs           # View logs
  $0 reset          # Reset weekly

First-time setup:
  1. Edit config.yml with your Steam API key
  2. ./deploy.sh start
  3. ./deploy.sh init-db
  4. In CLI, run: system.resetAllData()

EOF
}

# Main script
case "${1:-help}" in
    start)
        check_requirements
        start_server
        ;;
    stop)
        stop_server
        ;;
    restart)
        check_requirements
        restart_server
        ;;
    reset)
        check_requirements
        reset_server
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs
        ;;
    cli)
        cli_access
        ;;
    init-db)
        init_db
        ;;
    backup)
        backup_data
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        log_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
