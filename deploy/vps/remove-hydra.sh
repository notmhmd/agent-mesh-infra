#!/usr/bin/env bash
# Tear down Hydra / quant_* stack on a VPS so agent-mesh Caddy can use host :80/:443.
# Run on the server (root):  bash /path/to/agent-mesh-infra/deploy/vps/remove-hydra.sh
# Optional: HYDRA_PATH=/opt/hydra   DRY_RUN=1

set -euo pipefail

HYDRA_PATH="${HYDRA_PATH:-/opt/hydra}"
DRY_RUN="${DRY_RUN:-0}"

run() {
  if [[ "$DRY_RUN" == "1" ]]; then
    printf '[dry-run] '; printf '%q ' "$@"; printf '\n'
  else
    "$@"
  fi
}

echo "== Disconnect quant_nginx from non-Hydra networks (e.g. agent-mesh) =="
if docker ps -a --format '{{.Names}}' | grep -qx 'quant_nginx'; then
  nets=$(docker inspect quant_nginx --format '{{range $k, $v := .NetworkSettings.Networks}}{{$k}} {{end}}' 2>/dev/null || true)
  for net in $nets; do
    [[ -z "$net" ]] && continue
    case "$net" in *quant_net*|bridge|host|none) continue ;; esac
    run docker network disconnect "$net" quant_nginx 2>/dev/null || true
  done
fi

echo "== docker compose down in ${HYDRA_PATH} (if compose files exist) =="
if [[ -d "$HYDRA_PATH" ]]; then
  for f in docker-compose.production.yml docker-compose.staging.yml docker-compose.yml; do
    if [[ -f "$HYDRA_PATH/$f" ]]; then
      echo "--- down: $f"
      run bash -c "cd \"$HYDRA_PATH\" && docker compose -f \"$f\" down --remove-orphans" || true
    fi
  done
fi

echo "== Force-remove remaining quant_* containers =="
while read -r c; do
  [[ -z "$c" ]] && continue
  run docker rm -f "$c"
done < <(docker ps -aq --filter 'name=quant_' || true)

echo "== Remove Hydra-style bridge networks (name *quant_net*, not agent-mesh) =="
while read -r net; do
  [[ -z "$net" ]] && continue
  case "$net" in agent-mesh*|agent_mesh*) continue ;; esac
  run docker network rm "$net" 2>/dev/null || true
done < <(docker network ls --format '{{.Name}}' | grep quant_net || true)

echo "== Data directory =="
if [[ -d "$HYDRA_PATH" ]]; then
  echo "Backup then delete when ready:"
  echo "  sudo tar czf \"\$HOME/hydra-backup-\$(date +%Y%m%d).tgz\" -C \"$(dirname "$HYDRA_PATH")\" \"$(basename "$HYDRA_PATH")\""
  echo "  sudo rm -rf \"$HYDRA_PATH\""
else
  echo "(no $HYDRA_PATH)"
fi

echo "== Next steps =="
echo "  1. Ensure .env has CADDY_HTTP_PORT=80 CADDY_HTTPS_PORT=443 (or unset both to use defaults)."
echo "  2. Switch Caddy to automatic HTTPS: use deploy/vps/Caddyfile.caddy-tls (see deploy/vps/README.md)."
echo "  3. Redeploy agent-mesh (docker compose ... up -d --build)."
