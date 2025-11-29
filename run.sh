#!/usr/bin/env bash
set -euo pipefail

echo "Restarting Docker Compose stack..."
docker compose down --remove-orphans >/dev/null 2>&1 || true
docker compose up -d

echo "Tailing Envoy logs (Ctrl+C to stop)..."
docker logs -f balancer-envoy
