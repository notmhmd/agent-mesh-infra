# Hermes (Telegram)

Optional operator chat — **not** the execution hot path. See **[docs/DEPLOY.md](../../docs/DEPLOY.md)** for the full runbook.

From **`agent-mesh-infra`**:

```bash
mkdir -p deploy/hermes/gateway-data && cp deploy/hermes/env.example deploy/hermes/gateway-data/.env
# Edit: TELEGRAM_BOT_TOKEN, TELEGRAM_ALLOWED_USERS, LLM keys

docker compose -f docker-compose.yml -f docker-compose.hermes.yml --profile hermes up -d --build hermes-gateway
```

**Gemini-only keys:** Hermes’ stock default model is `anthropic/claude-opus-4.6`. If you only set **`GEMINI_API_KEY`**, Telegram can fail with **`models/anthropic/... is not found`** on **`generateContent`** (Google’s API). This repo ships **`gateway-data/config.yaml`** with `model.provider: gemini` and a Google **API model id** (e.g. **`gemini-2.5-flash-lite`**). Do **not** use LiteLLM-style names like **`gemini/gemini-2.5-flash-lite`** here — the native `gemini` provider turns that into **`models/gemini/gemini-2.5-flash-lite`**, which returns **404**. Override `model.default` for other Gemini ids (see [Google’s model list](https://ai.google.dev/gemini-api/docs/models)). For Anthropic models, set **`ANTHROPIC_API_KEY`** and `model.provider: anthropic` (or use OpenRouter with **`OPENROUTER_API_KEY`**).

**Still seeing 404 after fixing `config.yaml`?** Telegram sessions **pin the model** from when the chat started. Run **`/model`** (or **`/model gemini-2.5-flash-lite`**) in that chat, or **`/reset`** / start a **new session** so the gateway picks up the updated default. Restarting the container alone does not rewrite existing session files under `gateway-data/sessions/`.

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

### API / “UI” (OpenAI-compatible)

Hermes does **not** ship a full browser app in this image. It can expose an **OpenAI-compatible HTTP API** (default port **8642**) for clients such as **Open WebUI**, LobeChat, or `curl` — see [API server](https://hermes-agent.nousresearch.com/docs/user-guide/features/api-server).

Enable in **`gateway-data/.env`**: `API_SERVER_ENABLED=true`, `API_SERVER_HOST=0.0.0.0`, `API_SERVER_PORT=8642`, `API_SERVER_KEY=…`. Compose maps **8642:8642**.

**Subdomain (e.g. `hermes.skrr.cloud`):** add a DNS **A** record like the mesh host. In **`deploy/vps/Caddyfile`**, a `hermes.skrr.cloud` site block proxies **`hermes-gateway:8642`**. Test: `curl https://hermes.skrr.cloud/health` (after DNS + TLS).
