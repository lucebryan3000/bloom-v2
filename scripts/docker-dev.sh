#!/usr/bin/env bash
# =============================================================================
# Docker Development Helper Commands
# =============================================================================

set -euo pipefail

COMPOSE_FILE="docker-compose.yml"

usage() {
    cat << HELP
Docker Development Commands

Usage: ./scripts/docker-dev.sh <command>

Commands:
  up          Start all services
  down        Stop all services
  restart     Restart all services
  logs        Follow all logs
  logs-app    Follow app logs only
  shell       Open shell in app container
  db-shell    Open psql shell
  db-reset    Reset database (WARNING: destroys data)
  clean       Remove containers, volumes, and images
  status      Show container status
HELP
}

case "${1:-}" in
    up)
        docker compose -f "$COMPOSE_FILE" up -d
        echo "Services started. View logs: docker compose logs -f"
        ;;
    down)
        docker compose -f "$COMPOSE_FILE" down
        ;;
    restart)
        docker compose -f "$COMPOSE_FILE" restart
        ;;
    logs)
        docker compose -f "$COMPOSE_FILE" logs -f
        ;;
    logs-app)
        docker compose -f "$COMPOSE_FILE" logs -f app
        ;;
    shell)
        docker compose -f "$COMPOSE_FILE" exec app sh
        ;;
    db-shell)
        docker compose -f "$COMPOSE_FILE" exec postgres psql -U "${DB_USER:-postgres}" -d "${DB_NAME:-app}"
        ;;
    db-reset)
        echo "WARNING: This will destroy all database data!"
        read -p "Continue? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker compose -f "$COMPOSE_FILE" down -v
            docker compose -f "$COMPOSE_FILE" up -d postgres
            echo "Database reset. Waiting for healthy state..."
            sleep 5
        fi
        ;;
    clean)
        docker compose -f "$COMPOSE_FILE" down -v --rmi local
        ;;
    status)
        docker compose -f "$COMPOSE_FILE" ps
        ;;
    *)
        usage
        exit 1
        ;;
esac
