# Agent Mesh — iteration tracker

## Done
- [x] Prometheus + Grafana merge compose (`docker-compose.observability.yml`)
- [x] **LLM strategist** service (`agent-mesh-strategist`, LiteLLM, profile `llm`)
- [x] Postgres `market_intelligence` table + dashboard panel
- [x] Execution remains LLM-free; metrics on `:9090/metrics`

## Backlog
- [ ] Wire **signal** worker to read `market_intelligence` + apply risk rules before `stream:approved:intents`
- [ ] OpenTelemetry traces (optional)
- [ ] Formal DB migrations (existing volumes need manual migrate for new columns)

## Architecture (LLM placement)

```
strategist (LLM) → Postgres market_intelligence + Redis strategist:latest
       ↓ (future)
signal / risk agents (rules + optional ML) → stream:approved:intents
       ↓
execution (.NET, no LLM) → Alpaca
```

## Review
- Parallel subagents produced observability files + strategist code; main thread wired schema, compose profile, dashboard, README.
