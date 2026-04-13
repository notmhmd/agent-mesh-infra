-- Optional LISTEN/NOTIFY for market_intelligence inserts (complements Redis mesh:mi:new).
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
