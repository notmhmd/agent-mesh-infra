# Agent Mesh — architecture (AI insight, shared memory, self-sufficient agents)

## Principles

1. **Insight is AI-native** — Regime, narrative, and trend judgment come from **LLMs** (and future learned models), not from hand-tuned constants alone. Deterministic code **validates, risk-limits, and executes**; it does not replace reasoning about *what* the market is doing.
2. **Shared memory (Mem0)** — Cross-agent **semantic memory** lives in **Mem0** (OSS REST or managed). Agents **read** before acting and **write** after producing insight so the mesh **learns over time** (trends, mistakes, regime shifts). Postgres remains the **system of record** for orders and audits; Mem0 holds **narrative + lesson** retrieval.
3. **Continuous learning** — Pipeline services update **weights / features / memory** on a schedule or from outcomes (e.g. store “this regime call worked” in Mem0; optional online models in Python). Execution stays **fast and predictable**; learning is **asynchronous** to order submission.
4. **Self-sufficient agents** — Each service is a **long-running loop** with its own Docker image, env, health story, and dependencies: it **pulls** Redis/Postgres/Mem0 as needed and **does not require** a central orchestrator process. “Orchestration” is **compose + contracts + queues**.
5. **Outside-in is its own layer** — Operators use **[Hermes Agent](https://github.com/NousResearch/hermes-agent)** + **[Telegram](https://hermes-agent.nousresearch.com/docs/user-guide/messaging/telegram)** (token, long-poll or **webhook** behind Caddy, `TELEGRAM_ALLOWED_USERS`). For **live views outside Telegram**, the optional **`agent-mesh-realtime`** service turns Redis **`PUBLISH`** (e.g. **`mesh:mi:new`**) into **SSE/WebSocket** for a **browser or desktop** client — **no separate mobile app** in this design. **OpenClaw** is optional elsewhere.

## Data flow (target end state)

**Layers:** The diagram below is the **core** automated mesh. Around it is the **external interaction & insight layer**: **Hermes → Telegram**, plus an optional **Redis → SSE/WebSocket** bridge for **browser-style** live updates — all **off** the sub‑millisecond broker path.

```
┌─────────────────────────────────────────────────────────────────┐
│  Mem0 (shared semantic memory)                                   │
│    ←→ Strategist (LLM insight)  ←→  Signal router (LLM + Mem0)    │
│    ←→ Learning agent (execution → memory)                        │
├─────────────────────────────────────────────────────────────────┤
│  Postgres (auditable facts: market_intelligence, execution_*, …) │
│  Redis (streams, hot cache, heartbeats, agent cursors)           │
├─────────────────────────────────────────────────────────────────┤
│  Signal router — reads MI + Mem0 search, LLM proposes BUY/SELL/  │
│    HOLD, deterministic risk gate → ApprovedIntentV1               │
│         ↓                                                         │
│  stream:approved:intents (Redis Streams)                          │
│         ↓                                                         │
│  Execution (.NET) — idempotent broker submit, no LLM              │
└─────────────────────────────────────────────────────────────────┘
```

- **LLM** is on the **insight path** (strategist) and on the **intent planning path** (signal router). Multiple **self-sufficient agents** run in parallel; they coordinate via **Postgres**, **Redis**, and **Mem0**, not a central orchestrator process.  
- **Learning agent** closes the loop by writing **execution outcome** text into Mem0 for future retrieval.  
- **Execution** is intentionally **non-LLM** for latency and safety; it consumes **already-approved** intents.

## External layer (optional — not on the execution hot path)

**Hermes + [Telegram](https://hermes-agent.nousresearch.com/docs/user-guide/messaging/telegram)** — operator chat; configure via **`docker-compose.hermes.yml`** and **`deploy/hermes/`**. You can run a **second** service (**profile `hermes-research`**) for a separate bot / long jobs. Trades still go **ApprovedIntentV1 → stream → Execution**; Hermes never calls the broker directly.

**`agent-mesh-realtime`** — Redis **`SUBSCRIBE`** (default **`mesh:mi:new`**) → **`/sse`** and **`/ws`** for browser or desktop. Merge **`docker-compose.realtime.yml`**, profile **`realtime`**.

**`agent-mesh-mesh-tools`** — read-only HTTP **`/v1/market-intelligence/latest`**, **`/v1/execution-events/recent`**, **`/v1/redis/ping`** on the mesh (`http://mesh-tools:8088`) for operators and Hermes HTTP tools. Merge **`docker-compose.mesh-tools.yml`**, profile **`mesh-tools`**. No writes; no broker.

**OpenClaw** — optional alternative gateway; not assumed here.

**Deploy commands and merge files:** [DEPLOY.md](DEPLOY.md).

## Mem0 (OSS)

- Set `**MEM0_BASE_URL`** (e.g. `http://mem0:8000`) on agents that use memory.  
- Optional `**MEM0_API_KEY`** → `X-API-Key` (matches Mem0 `ADMIN_API_KEY` on the server).  
- Namespace with `**MEM0_USER_ID**` (e.g. `agent-mesh`) and `**MEM0_AGENT_ID**` (e.g. `strategist`).  
- API paths: OSS uses `**POST /memories**`, `**POST /search**` (no `/v1/` prefix). See [Mem0 REST docs](https://docs.mem0.ai/open-source/features/rest-api).

Deploy Mem0 via official Docker image `**mem0/mem0-api-server**` or compose from the Mem0 repo; use profile `**memory**` in compose when you add the service.

## Contracts

JSON schemas in `**agent-mesh-contracts**` describe events (signals, intents, insight events). Version fields prevent silent drift.

## Speed and freshness (markets move fast)

- **Insight cadence:** Strategist default interval targets **sub-minute** regime updates (`STRATEGIST_INTERVAL_SEC`; tune down when API budget allows). **Mem0 search** and **LLM calls** use bounded timeouts (`MEM0_*_TIMEOUT_SEC`, `LITELLM_REQUEST_TIMEOUT_SEC`); Mem0 **writes** run **off the hot path** (background) so Postgres + Redis notify are not blocked.
- **Wake signal-agent immediately:** After each `market_intelligence` insert, strategist `**PUBLISH`**es to Redis channel `**mesh:mi:new`** (override `MI_NOTIFY_CHANNEL`). Signal-agent **subscribes** and runs a tick on notify or at most every `**SIGNAL_IDLE_POLL_SEC`** (fallback if notify is missed). The same channel (and additional `**PUBLISH**` topics you add) can feed **realtime-bridge** for **live browser/desktop** views (see **External interaction & insight layer**).
- **Execution tight loop:** The .NET consumer uses a **short idle delay** between `XREADGROUP` polls so approved intents reach Postgres **within milliseconds** of `XADD` under load.
- **Trade-off:** Faster intervals and richer Mem0 context increase **cost and API load**; shrink `MEM0_CONTEXT_MAX_CHARS` and raise intervals when you need to throttle.

## Observability

- **Execution** exposes Prometheus on `**/metrics`** (port **9090**).
- **Strategist** and **signal-agent** expose `**prometheus_client`** metrics when `**METRICS_PORT` > 0** (defaults **9092** / **9093** in Compose). Histograms cover Mem0 search, LLM latency, and signal planner latency; counters record tick outcomes and MI routing (`xadd` vs `risk_skip` vs `planner_error`).
- Merge `**docker-compose.observability.yml`** so Prometheus scrapes all three jobs (targets are *down* until the corresponding compose profiles are running). **Grafana** loads a provisioned **Agent Mesh — overview** dashboard (`deploy/grafana/provisioning/dashboards/json/agent-mesh-overview.json`) for execution, strategist, and signal metrics.
- **OpenTelemetry:** when `**OTEL_EXPORTER_OTLP_ENDPOINT*`* is set (and `**OTEL_SDK_DISABLED**` is not `true`), **execution** (.NET `**Execution.Gateway`**), **strategist**, **signal-agent**, and **learning-agent** export OTLP **gRPC** spans. Spans carry `**intent.trace_id`** / `**market_intelligence.id**` / `**mesh.trace_id**` (`mesh-mi-{id}`) where applicable. **Distributed linkage:** **signal-agent** adds optional W3C `**traceparent`** on `**ApprovedIntentV1**` (current OTel context); **execution** parses it and starts `**ProcessStreamEntry`** as a **child** of that remote context when valid. Merge `**docker-compose.otel.yml`** for a dev **collector** that logs spans to stdout (`deploy/otel/otel-collector.yaml`). Set `**OTEL_SERVICE_NAME`** per process (Compose defaults include `agent-mesh-learning`).

## Database migrations

- Incremental SQL lives in `**postgres/migrations/**` (golang-migrate). `**init.sql**` still seeds a **new** empty volume; existing deployments run `**docker compose --profile migrate run --rm migrate`** to apply pending versions (see `**postgres/migrations/README.md**`).

## What “done” looks like

- Strategist: search Mem0 → LLM with memory in system prompt → Postgres + Redis notify + **add Mem0 memory** (async).  
- Signal agent: **search Mem0** + LLM planner → risk gate → `**stream:approved:intents`**.  
- Execution: **structured intents only**; optional **OTLP** traces when configured.

