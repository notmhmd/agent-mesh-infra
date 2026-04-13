# VPS deploy (e.g. `skrr.cloud`)

## Before you start

1. **Rotate every secret** that was ever pasted in chat (Alpaca, Telegram, Gemini, DB, SSH).
2. Use **SSH public keys**; disable password login (`PasswordAuthentication no` in `sshd_config`).
3. Create DNS: **A record** for your subdomain (e.g. `mesh.skrr.cloud`) → server **public IPv4**.

## One-time server setup

```bash
# On the VPS (Debian/Ubuntu example)
apt-get update && apt-get install -y git ca-certificates curl
curl -fsSL https://get.docker.com | sh
mkdir -p /opt && cd /opt
# Clone all sibling repos next to agent-mesh-infra (see main README)
git clone <your-fork-or-mirror>/agent-mesh-infra.git
# ... clone agent-mesh-execution, strategist, signal, dashboard, pipeline, realtime, mesh-tools, contracts
```

Place repos **flat** under `/opt` so paths match `../agent-mesh-execution` from `agent-mesh-infra`.

## Configure

```bash
cd /opt/agent-mesh-infra
cp deploy/vps/env.production.template .env
nano .env   # POSTGRES_PASSWORD, APCA_*, GEMINI_API_KEY, CADDY_DOMAIN=mesh.skrr.cloud
cp deploy/hermes/env.example deploy/hermes/gateway-data/.env
nano deploy/hermes/gateway-data/.env   # TELEGRAM_BOT_TOKEN, TELEGRAM_ALLOWED_USERS, LLM
```

**Gemini:** `LLM_MODEL=gemini/gemini-2.0-flash` (or `gemini/gemini-1.5-flash`) and **`GEMINI_API_KEY`** in `.env` (passed into strategist/signal via compose).

**Hermes webhook (optional):** set `TELEGRAM_WEBHOOK_URL=https://mesh.skrr.cloud/telegram` in `gateway-data/.env`, uncomment `handle_path /telegram/*` in `deploy/vps/Caddyfile`, merge `docker-compose.hermes.yml`, `up` Hermes.

## Bring up

```bash
docker compose -f docker-compose.yml -f docker-compose.vps.yml --profile migrate run --rm migrate
docker compose -f docker-compose.yml -f docker-compose.vps.yml --profile llm --profile signals up -d --build
```

Open **https://mesh.skrr.cloud** (replace with your `CADDY_DOMAIN`).

### Edge nginx (when host 80/443 is already used)

If another reverse proxy (for example `quant_nginx`) owns public **80/443**, keep **`CADDY_HTTP_PORT` / `CADDY_HTTPS_PORT`** on alternate ports, issue a certificate for **`CADDY_DOMAIN`**, copy **`deploy/vps/nginx-mesh.skrr.cloud.conf`** into that nginx’s `conf.d`, run **`docker network connect agent-mesh-infra_mesh <nginx_container>`** once so nginx can **`proxy_pass http://caddy:80`**, then **`nginx -s reload`**. TLS terminates at nginx; **`deploy/vps/Caddyfile`** uses **`http://{$CADDY_DOMAIN}`** so Caddy does not redirect to HTTPS internally.

Add profiles as needed: `memory` + `docker-compose.mem0.yml`, `realtime`, `mesh-tools`, `hermes`, etc. See [../../docs/DEPLOY.md](../../docs/DEPLOY.md).

## Smoke test (optional)

From `agent-mesh-infra` on the server:

```bash
./scripts/verify_stack.sh
```

## Removing Hydra (`quant_*`) from this host

If an older **Hydra** stack still holds **:80/:443** (e.g. `quant_nginx` under `/opt/hydra`):

1. From a clone of **agent-mesh-infra** on the server (or copy the script over), run:
   ```bash
   sudo bash deploy/vps/remove-hydra.sh
   ```
   Optional: `HYDRA_PATH=/opt/hydra` (default), `DRY_RUN=1` to print steps only.
2. **Backup** `/opt/hydra` (certs, DB volumes) if you need anything from it, then delete the directory when ready (the script prints `tar` / `rm` commands).
3. Point **Caddy** at public TLS again: copy `deploy/vps/Caddyfile.caddy-tls` over `deploy/vps/Caddyfile` (or merge the site block), set **`CADDY_HTTP_PORT=80`** and **`CADDY_HTTPS_PORT=443`** in `.env` (or unset to use defaults), recreate **caddy**.
4. Remove any hand-added **nginx** vhost that proxied to Caddy on alternate ports (e.g. `99-mesh.conf`) if that nginx container is gone.

## GitHub Actions (CI/CD)

- **CI:** `.github/workflows/ci.yml` — on each PR / push to `main`, clones public sibling repos (same GitHub **owner** as this repo) and runs `docker compose … config`. Optional secret **`CLONE_PAT`** for private siblings.
- **Deploy:** `.github/workflows/vps-deploy.yml` — **Run workflow** in the Actions tab; pulls all sibling repos under the parent of `VPS_DEPLOY_PATH`, then `docker compose` with **llm**, **signals**, **mesh-tools**, and **realtime** profiles. Checkbox **run_migrate** runs the one-shot migrate job.

Configure **SSH key** secrets on the repo — **not** the root password. See [../../docs/GITHUB_SECRETS.md](../../docs/GITHUB_SECRETS.md).
