# SQL migrations (golang-migrate)

Files follow `{version}_{title}.up.sql` (e.g. `1_baseline.up.sql`). Versions are applied in order; state is stored in table **`schema_migrations`**.

## When to use

- **New Docker volume:** `init.sql` still creates the initial schema on first Postgres start.
- **Existing volume / production:** run `migrate up` (see `scripts/migrate_up.sh` and Compose service `migrate`) so additive changes apply without recreating the volume.

## Apply

From `agent-mesh-infra` with stack running:

```bash
docker compose --profile migrate run --rm migrate
```

Or locally with `migrate` CLI installed and `DATABASE_URL` / env vars as in the script.

Passwords with URL-reserved characters may need encoding in `DATABASE_URL`.
