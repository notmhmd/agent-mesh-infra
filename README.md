# agent-mesh-infra

Docker Compose + **Caddy** for the Agent Mesh stack. Assumes **sibling directories** on the host:

```text
parent/
  agent-mesh-contracts/     # JSON schemas (reference only in builds)
  agent-mesh-execution/     # .NET gateway (no LLM)
  agent-mesh-strategist/    # LiteLLM regime/sentiment → Postgres + Redis (optional `--profile llm`)
  agent-mesh-pipeline/      # Python workers / dev publisher
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

**LLM strategist (optional):** writes `market_intelligence` + Redis `strategist:latest`; **never** calls Alpaca. Requires an API key (e.g. `OPENAI_API_KEY`) or local **Ollama** (`LLM_MODEL=ollama/llama3.2`, `OLLAMA_BASE_URL`).

```bash
docker compose --profile llm up -d --build strategist
```

**Observability (optional):** Prometheus + Grafana on the `mesh` network.

```bash
docker compose -f docker-compose.yml -f docker-compose.observability.yml up -d
```

- Prometheus UI: `http://localhost:9091` (config: `deploy/prometheus/prometheus.yml`; scrapes `execution:9090/metrics`).
- Grafana: `http://localhost:3000` (datasource Prometheus at `http://prometheus:9090`).

Open `http://localhost` (Caddy → dashboard on port 80).

**Execution metrics:** `http://localhost:9090/metrics` on the host (execution container); Prometheus scrapes `execution:9090` inside Docker.

## Services

| Service | Image / build | Notes |
|---------|----------------|--------|
| postgres | pgvector/pg17 | Init SQL + indexes |
| redis | redis:8-alpine | Streams + cache |
| execution | `../agent-mesh-execution` | .NET 9 gateway (LLM-free) |
| strategist | `../agent-mesh-strategist` | **Profile `llm`** — LiteLLM analysis |
| pipeline | `../agent-mesh-pipeline` | Dev publisher → stream |
| dashboard | `../agent-mesh-dashboard` | Streamlit |
| caddy | caddy:2 | Reverse proxy |

Postgres **17** + pgvector; loads `postgres/init.sql` on **first** volume init only.

**Queue:** `stream:approved:intents` (Redis Streams, consumer group `execution`). Dev publisher `agent-mesh-pipeline` uses **XADD**; execution **XREADGROUP** + **XACK**.

## Adding pipeline workers

Add a `pipeline` service with `build: ../agent-mesh-pipeline` once a `Dockerfile` exists there.

## Related

- [agent-mesh-contracts](../agent-mesh-contracts) — shared schemas
- Legacy monolith scaffold: `alpaca-agent-mesh` (optional; can archive)
