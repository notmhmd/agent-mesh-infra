# Deploy runbook

One place for **compose order**, **profiles**, and **post-deploy checks**. Core idea: **strategist → signal → Redis stream → execution**; everything else is optional.

## 1. Repo layout (siblings)

Clone **next to** `agent-mesh-infra` (same parent folder):

`agent-mesh-execution`, `agent-mesh-strategist`, `agent-mesh-signal`, `agent-mesh-dashboard`, `agent-mesh-pipeline`, `agent-mesh-realtime`, `agent-mesh-mesh-tools` (read-only operator API), `agent-mesh-contracts` (schemas).

## 2. Minimal stack (core trading path)

```bash
cd agent-mesh-infra
cp env.example .env
# Set POSTGRES_*, APCA_* paper keys, OPENAI_API_KEY or OLLAMA_*

docker compose up -d --build
docker compose --profile migrate run --rm migrate   # if volume already existed without migrations

docker compose --profile llm --profile signals up -d --build strategist signal-agent
```

**Do not** run **`pipeline`** (dev XADD) alongside **`signal-agent`** on the same stream without a plan.

## 3. Recommended add-ons (merge files)

| Goal | Merge file | Profile(s) |
|------|------------|------------|
| Mem0 OSS API | `docker-compose.mem0.yml` | `memory` |
| Learning → Mem0 | (same base compose) | `learning` |
| Prometheus + Grafana | `docker-compose.observability.yml` | (none) |
| OTLP collector | `docker-compose.otel.yml` | (none; set `OTEL_EXPORTER_OTLP_ENDPOINT` on services) |
| SSE/WebSocket live feed | `docker-compose.realtime.yml` | `realtime` |
| Read-only mesh status API (Hermes HTTP tool) | `docker-compose.mesh-tools.yml` | `mesh-tools` |
| Hermes + Telegram | `docker-compose.hermes.yml` | `hermes` (+ `hermes-research` for second bot) |

**Example — core + Mem0 + learning + realtime:**

```bash
docker compose \
  -f docker-compose.yml \
  -f docker-compose.mem0.yml \
  -f docker-compose.realtime.yml \
  --profile llm --profile signals --profile memory --profile learning --profile realtime \
  up -d --build
```

**Hermes** (first build is slow):

```bash
mkdir -p deploy/hermes/gateway-data && cp deploy/hermes/env.example deploy/hermes/gateway-data/.env
# edit gateway-data/.env — token, TELEGRAM_ALLOWED_USERS, LLM keys

docker compose -f docker-compose.yml -f docker-compose.hermes.yml --profile hermes up -d --build hermes-gateway
```

## 4. Loose ends (after `up`)

| Check | Action |
|-------|--------|
| Migrations | `docker compose --profile migrate run --rm migrate` |
| Strategist MI + notify | Logs show MI insert + `PUBLISH` `mesh:mi:new` |
| Signal-agent | Consumes MI; stream `stream:approved:intents` receives entries when risk passes |
| Execution | Polls stream; broker only here |
| Realtime (if enabled) | `curl -N http://localhost:8095/sse` while strategist runs |
| Mesh-tools (if enabled) | `curl -s http://localhost:8088/v1/market-intelligence/latest?limit=3` |
| Hermes (if enabled) | Message bot on Telegram; long-poll needs no Caddy change; point HTTP tool at `http://mesh-tools:8088` (see `deploy/hermes/README.md`) |
| Webhook Hermes | Set `TELEGRAM_WEBHOOK_URL` in `gateway-data/.env`, uncomment `/telegram/*` in `caddy/Caddyfile`, reload Caddy |

## 5. Smoke test (automated)

From `agent-mesh-infra`:

```bash
./scripts/verify_stack.sh
```

Brings up postgres, redis, execution, dashboard, **mesh-tools**, **realtime-bridge**, runs **migrate**, then curls health + metrics. Requires Docker.

## 6. Optional later

- **Second Hermes bot** — profile `hermes-research`, `deploy/hermes/research-data/.env`.
- **OTel `tracestate`** — still optional; Python agents now register **W3C Baggage** alongside trace context when the SDK provides it.

**Public VPS + TLS + subdomain (e.g. `mesh.skrr.cloud`):** [../deploy/vps/README.md](../deploy/vps/README.md) and `docker-compose.vps.yml`.

See [ARCHITECTURE.md](ARCHITECTURE.md) for design; [README.md](../README.md) for service table and ports. [SECURITY.md](SECURITY.md) for keys and rotation.
