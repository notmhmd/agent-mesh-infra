#!/usr/bin/env bash
# Smoke-test core services + mesh-tools + realtime. Run from agent-mesh-infra.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "== compose config (base + mesh-tools + realtime) =="
docker compose \
  -f docker-compose.yml \
  -f docker-compose.mesh-tools.yml \
  -f docker-compose.realtime.yml \
  config --quiet

echo "== build =="
docker compose \
  -f docker-compose.yml \
  -f docker-compose.mesh-tools.yml \
  -f docker-compose.realtime.yml \
  build execution dashboard mesh-tools realtime-bridge

echo "== up: postgres redis execution dashboard mesh-tools realtime =="
docker compose \
  -f docker-compose.yml \
  -f docker-compose.mesh-tools.yml \
  -f docker-compose.realtime.yml \
  --profile mesh-tools --profile realtime \
  up -d postgres redis execution dashboard mesh-tools realtime-bridge

echo "== migrate =="
docker compose --profile migrate run --rm migrate

echo "== health checks =="
for url in \
  "http://localhost:8088/healthz" \
  "http://localhost:8088/v1/market-intelligence/latest?limit=1" \
  "http://localhost:8095/healthz" \
  "http://localhost:9090/metrics"
do
  echo "GET $url"
  curl -fsS "$url" | head -c 400 || true
  echo ""
done

echo "== OK verify_stack finished =="
