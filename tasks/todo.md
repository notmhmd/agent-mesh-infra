# Agent Mesh — tracker

## Product complete (v2)

- **Core mesh:** postgres, redis, execution, strategist, signal-agent, learning-agent, dashboard, caddy, migrations  
- **Observability:** Prometheus/Grafana merge, OTel merge + **W3C Baggage** propagator (with trace context) on strategist + signal **when** SDK provides it  
- **Mem0** merge, contracts, dashboard panels  
- **agent-mesh-realtime** — SSE/WebSocket  
- **agent-mesh-mesh-tools** — read-only HTTP API for operators / Hermes (`docker-compose.mesh-tools.yml`, profile **`mesh-tools`**)  
- **Hermes** compose merge + `deploy/hermes/`  
- **Smoke test:** `scripts/verify_stack.sh` (executed successfully: health + migrate + metrics)  
- Docs: [ARCHITECTURE.md](../docs/ARCHITECTURE.md), [DEPLOY.md](../docs/DEPLOY.md), README  

## You still configure at runtime (secrets / keys)

| Item | Action |
|------|--------|
| Alpaca + LLM keys | `.env` |
| Hermes Telegram | `deploy/hermes/gateway-data/.env` — BotFather token, `TELEGRAM_ALLOWED_USERS`, LLM keys |
| Hermes webhook | `TELEGRAM_WEBHOOK_URL` + Caddy `/telegram/*` if needed |
| Second Hermes bot | `research-data/.env` + profile `hermes-research` |

## Architecture

```
Mem0 ←→ strategist → market_intelligence + Redis notify
Mem0 ←→ signal-agent → stream:approved:intents
Mem0 ←  learning-agent ← execution_events
       ↓
execution (.NET) → broker
```
