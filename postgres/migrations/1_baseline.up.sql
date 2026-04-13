-- Baseline migration for golang-migrate.
-- Core tables are created by postgres/init.sql on first Docker volume init.
-- This version marks the DB as migration-managed for incremental changes going forward.
SELECT 1;
