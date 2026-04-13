-- Optional: Postgres NOTIFY on new market_intelligence (for clients that LISTEN in-process).
-- Prefer `postgres/migrations/2_market_intelligence_pg_notify.up.sql` (golang-migrate).
-- Does not replace Redis mesh:mi:new; use one or both.

CREATE OR REPLACE FUNCTION notify_market_intelligence() RETURNS trigger AS $$
BEGIN
  PERFORM pg_notify('market_intelligence_new', NEW.id::text);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_mi_notify ON market_intelligence;
CREATE TRIGGER trg_mi_notify
AFTER INSERT ON market_intelligence
FOR EACH ROW EXECUTE FUNCTION notify_market_intelligence();
