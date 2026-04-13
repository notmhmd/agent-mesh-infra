#!/bin/sh
set -e
# golang-migrate: apply all pending migrations in /migrations (Compose) or ./postgres/migrations (host).
# Env: POSTGRES_HOST (default postgres), POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DB

POSTGRES_HOST="${POSTGRES_HOST:-postgres}"
: "${POSTGRES_USER:?POSTGRES_USER required}"
: "${POSTGRES_PASSWORD:?POSTGRES_PASSWORD required}"
: "${POSTGRES_DB:?POSTGRES_DB required}"

MIGRATIONS_PATH="${MIGRATIONS_PATH:-/migrations}"
DATABASE_URL="postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:5432/${POSTGRES_DB}?sslmode=disable"

echo "migrate up: path=${MIGRATIONS_PATH} host=${POSTGRES_HOST} db=${POSTGRES_DB}"
exec migrate -path "$MIGRATIONS_PATH" -database "$DATABASE_URL" up
