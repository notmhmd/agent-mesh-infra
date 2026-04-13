# GitHub Actions secrets (deploy)

**Never commit** hostnames with live credentials. Add secrets in the repo: **Settings → Secrets and variables → Actions**.

Suggested names for **VPS deploy** (`.github/workflows/vps-deploy.yml`):


| Secret                | Purpose                                                                                                                                                                            |
| --------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `VPS_HOST`            | Server IP or hostname                                                                                                                                                              |
| `VPS_USER`            | SSH user (e.g. `root` or `deploy`)                                                                                                                                                 |
| `VPS_SSH_PRIVATE_KEY` | Full PEM or OpenSSH private key for key-based auth                                                                                                                                 |
| `VPS_DEPLOY_PATH`     | Optional. Path to **this** repo on the server (default in workflow: `/opt/agent-mesh/agent-mesh-infra`). Parent directory must contain sibling clones (`agent-mesh-execution`, …). |
| `VPS_GIT_BRANCH`      | Optional. Branch for `git pull` (default `main`).                                                                                                                                  |


**CI** (`.github/workflows/ci.yml`): optional `CLONE_PAT` — fine-grained GitHub PAT with read access to **private** sibling repos when the workflow clones `agent-mesh-`* repos next to this checkout.

### Set from CLI (`gh`)

```bash
gh auth login
gh secret set VPS_HOST
gh secret set VPS_USER
gh secret set VPS_SSH_PRIVATE_KEY < ~/.ssh/id_ed25519_vps
```

Paste or pipe carefully; avoid shell history with real keys.

### On the VPS

1. Add the **matching public key** to `~/.ssh/authorized_keys`.
2. Disable password authentication for SSH.

**CD (automatic):** after **`CI`** succeeds on a **push to `main`**, **`VPS deploy`** runs via **`workflow_run`** (see `.github/workflows/vps-deploy.yml`). You can still run **`VPS deploy`** manually from the Actions tab (e.g. to toggle **run_migrate**).

On the VPS, remove any legacy **Hydra / quant_** stack before binding Caddy to **:80/:443** — see `deploy/vps/remove-hydra.sh` and `deploy/vps/README.md`.