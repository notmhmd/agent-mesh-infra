# Agent Mesh — iteration tracker

## Done (latest iteration)
- [x] Prometheus metrics on execution (`/metrics` on port 9090, `prometheus-net`)
- [x] Dashboard: Postgres read + `st.fragment` periodic refresh (Streamlit ≥ 1.33)
- [x] Compose: expose `9090` for execution metrics; dashboard wired to Postgres
- [x] CI: GitHub Actions — `dotnet build` (execution), `docker build` (dashboard, pipeline)

## Backlog (next)
- [ ] Grafana + Prometheus scrape config (compose profile)
- [ ] OTEL traces for Redis/Npgsql (optional)
- [ ] Formal DB migrations (Flyway / `dotnet ef` / atlas)

## Review
- Execution exposes **Prometheus** scrape endpoint; dashboard uses **fragments** for efficient partial rerenders; CI validates **.NET 9** and **Docker** builds independently per repo.
