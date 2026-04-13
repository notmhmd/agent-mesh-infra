# agent-mesh-infra

Docker Compose + **Caddy** for the Agent Mesh. **Deploy:** [docs/DEPLOY.md](docs/DEPLOY.md). **VPS + TLS + subdomain:** [deploy/vps/README.md](deploy/vps/README.md). **Design:** [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md). **Smoke test:** `./scripts/verify_stack.sh`.

## Sibling repos (same parent folder)

`agent-mesh-execution`, `agent-mesh-strategist`, `agent-mesh-signal`, `agent-mesh-dashboard`, `agent-mesh-pipeline`, `agent-mesh-realtime`, `agent-mesh-mesh-tools`, `agent-mesh-contracts`, and this **`agent-mesh-infra`** (run compose from here).

## Quick start (minimal)

```bash
cd agent-mesh-infra
cp env.example .env
# POSTGRES_*, APCA_* keys, LLM keys (e.g. OPENAI_API_KEY or Ollama)
docker compose up -d --build
docker compose --profile migrate run --rm migrate   # existing DBs only
docker compose --profile llm --profile signals up -d --build strategist signal-agent
```

Open **http://localhost** (Caddy → Streamlit). The **`pipeline`** dev publisher is opt-in (`docker compose --profile pipeline up`). **Do not** run it alongside **`signal-agent`** without intent.

**Profiles:** `llm` · `signals` · `learning` · `memory` (+ `docker-compose.mem0.yml`) · `realtime` (+ `docker-compose.realtime.yml`) · `mesh-tools` (+ `docker-compose.mesh-tools.yml`) · `hermes` / `hermes-research` (+ `docker-compose.hermes.yml`).

## Services

| Service | Build / image | Profile / notes |
|---------|----------------|-----------------|
| postgres | pgvector pg17 | — |
| redis | redis:8 | — |
| execution | `../agent-mesh-execution` | .NET broker path only |
| strategist | `../agent-mesh-strategist` | `llm` |
| signal-agent | `../agent-mesh-signal` | `signals` |
| learning-agent | same | `learning` |
| pipeline | `../agent-mesh-pipeline` | dev publisher |
| dashboard | `../agent-mesh-dashboard` | — |
| caddy | caddy:2 | :80 |
| mesh-tools | `../agent-mesh-mesh-tools` | `mesh-tools` — read-only API :8088 |
| realtime-bridge | `../agent-mesh-realtime` | `realtime` — `/sse`, `/ws` :8095 |
| hermes-gateway / hermes-research | upstream Hermes | `hermes`, `hermes-research` |

**Queue:** Redis stream `stream:approved:intents`, consumer group `execution`.

**Metrics:** execution `:9090`, strategist `:9092`, signal `:9093` (when profiles up).

## Related

- [agent-mesh-contracts](../agent-mesh-contracts) — JSON schemas  
- [agent-mesh-mesh-tools](../agent-mesh-mesh-tools) — operator / Hermes read API  
- [docs/DEPLOY.md](docs/DEPLOY.md) — **runbook**  
- `alpaca-agent-mesh` — legacy sketch (optional)
