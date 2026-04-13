# agent-mesh-infra

Docker Compose + **Caddy** for the Agent Mesh stack. Assumes **sibling directories** on the host:

```text
parent/
  agent-mesh-contracts/   # JSON schemas (reference only in builds)
  agent-mesh-execution/     # Go gateway
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

## Services

| Service | Image / build | Notes |
|---------|----------------|--------|
| postgres | pgvector/pg16 | Add init SQL in a future change |
| redis | redis:7 | Queues + cache |
| execution | `../agent-mesh-execution` | Go consumer |
| dashboard | `../agent-mesh-dashboard` | Streamlit |
| caddy | caddy:2 | Reverse proxy |

## Adding pipeline workers

Add a `pipeline` service with `build: ../agent-mesh-pipeline` once a `Dockerfile` exists there.

## Related

- [agent-mesh-contracts](../agent-mesh-contracts) — shared schemas
- Legacy monolith scaffold: `alpaca-agent-mesh` (optional; can archive)
