# agent-mesh-infra

Docker Compose + **Caddy** for the Agent Mesh stack. Assumes **sibling directories** on the host:

```text
parent/
  agent-mesh-contracts/   # JSON schemas (reference only in builds)
  agent-mesh-execution/     # .NET gateway
  agent-mesh-pipeline/      # Python workers (add service when ready)
  agent-mesh-dashboard/     # Streamlit
  agent-mesh-infra/         # this repo — run compose from here
```

## Quick start

```bash
cd agent-mesh-infra
cp env.example .env
# edit .env
docker compose up -d --build
```

Open `http://localhost` (Caddy → dashboard on port 80).

**Prometheus:** scrape `execution:9090/metrics` (mapped to host `localhost:9090` in compose).

## Services

| Service | Image / build | Notes |
|---------|----------------|--------|
| postgres | pgvector/pg17 | Init SQL + indexes |
| redis | redis:8-alpine | Streams + cache |
| execution | `../agent-mesh-execution` | .NET 8 gateway |
| pipeline | `../agent-mesh-pipeline` | Dev publisher → `approved:intents` |
| dashboard | `../agent-mesh-dashboard` | Streamlit |
| caddy | caddy:2 | Reverse proxy |

Postgres **17** + pgvector; loads `postgres/init.sql` on **first** volume init only.

**Queue:** `stream:approved:intents` (Redis Streams, consumer group `execution`). Dev publisher `agent-mesh-pipeline` uses **XADD**; execution **XREADGROUP** + **XACK**.

## Adding pipeline workers

Add a `pipeline` service with `build: ../agent-mesh-pipeline` once a `Dockerfile` exists there.

## Related

- [agent-mesh-contracts](../agent-mesh-contracts) — shared schemas
- Legacy monolith scaffold: `alpaca-agent-mesh` (optional; can archive)
