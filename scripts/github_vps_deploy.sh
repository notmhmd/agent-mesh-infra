#!/usr/bin/env bash
# Invoked on the VPS by GitHub Actions (appleboy ssh-action script_path + envs).
# Env (optional): DEPLOY_PATH, GIT_BRANCH, GITHUB_EVENT_NAME, RUN_MIGRATE

set -euo pipefail

D="${DEPLOY_PATH:-/opt/agent-mesh/agent-mesh-infra}"
BRANCH="${GIT_BRANCH:-main}"
[[ -z "$BRANCH" ]] && BRANCH=main
PARENT="$(dirname "$D")"
echo "Deploy path: $D  parent: $PARENT  branch: $BRANCH"

for repo in agent-mesh-infra agent-mesh-execution agent-mesh-strategist agent-mesh-signal agent-mesh-dashboard agent-mesh-pipeline agent-mesh-realtime agent-mesh-mesh-tools agent-mesh-contracts; do
  R="$PARENT/$repo"
  if [[ -d "$R/.git" ]]; then
    echo "== git pull: $repo =="
    git -C "$R" fetch origin "$BRANCH" --depth=120 || git -C "$R" fetch origin --depth=120
    git -C "$R" checkout "$BRANCH" || git -C "$R" checkout main
    git -C "$R" pull --ff-only origin "$BRANCH" || git -C "$R" pull --ff-only
  else
    echo "(skip missing clone: $R)"
  fi
done

cd "$D"
FILES="-f docker-compose.yml -f docker-compose.vps.yml -f docker-compose.mesh-tools.yml -f docker-compose.realtime.yml"
PROFILES="--profile llm --profile signals --profile mesh-tools --profile realtime"

if [[ "${GITHUB_EVENT_NAME:-}" == "workflow_dispatch" ]] && [[ "${RUN_MIGRATE:-false}" == "true" ]]; then
  echo "== migrate =="
  docker compose $FILES --profile migrate run --rm migrate
fi

echo "== compose up =="
docker compose $FILES $PROFILES up -d --build
