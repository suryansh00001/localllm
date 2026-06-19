#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Starting Open WebUI..."
docker compose -f "${SCRIPT_DIR}/docker-compose.yml" up -d

echo "Open WebUI is available at: http://localhost:3000"
echo "Ensure llama-server is running on port 8080 first."
