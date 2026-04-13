# Hermes (Telegram)

Optional operator chat — **not** the execution hot path. See **[docs/DEPLOY.md](../../docs/DEPLOY.md)** for the full runbook.

From **`agent-mesh-infra`**:

```bash
mkdir -p deploy/hermes/gateway-data && cp deploy/hermes/env.example deploy/hermes/gateway-data/.env
# Edit: TELEGRAM_BOT_TOKEN, TELEGRAM_ALLOWED_USERS, LLM keys

docker compose -f docker-compose.yml -f docker-compose.hermes.yml --profile hermes up -d --build hermes-gateway
```

Long-polling needs no Caddy change. **Webhook:** set `TELEGRAM_WEBHOOK_URL` in `gateway-data/.env`, uncomment `/telegram/*` in `caddy/Caddyfile`.

**Second bot:** `deploy/hermes/research-data/.env` + compose profile **`hermes-research`**.

**HTTP tools (mesh status):** With **`mesh-tools`** running (`docker-compose.mesh-tools.yml`, profile **`mesh-tools`**), configure Hermes to fetch e.g. `http://mesh-tools:8088/v1/market-intelligence/latest?limit=5` (read-only). Trades still go through signal-agent → stream → execution.

## Why you “don’t see” Hermes config in git

`deploy/hermes/gateway-data/.env` is **gitignored** (secrets). In this repo you only get **`deploy/hermes/env.example`**. One-time:

```bash
mkdir -p deploy/hermes/gateway-data
cp deploy/hermes/env.example deploy/hermes/gateway-data/.env
# edit gateway-data/.env — never commit it
```

**Hermes does not run** until you merge **`docker-compose.hermes.yml`** and start the **`hermes`** profile (first image build clones upstream Hermes and can take many minutes):

```bash
docker compose -f docker-compose.yml -f docker-compose.hermes.yml --profile llm --profile signals --profile mesh-tools --profile realtime --profile hermes up -d --build
```

Having `gateway-data/.env` on disk alone is not enough; the **`hermes-gateway`** container must be up.
