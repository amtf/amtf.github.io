-- create_readonly_account_postgres.sql
-- Create the PostgreSQL read-only account "pdodev09" on the postgres database.
-- Run as the superuser (local trust auth connects as the macOS user, e.g. ericho):
--   psql -U ericho -d postgres -f create_readonly_account_postgres.sql

CREATE ROLE pdodev09 LOGIN PASSWORD 'Pdodev@2026';

GRANT CONNECT ON DATABASE postgres TO pdodev09;

GRANT SELECT ON ALL TABLES IN SCHEMA public TO pdodev09;

-- Also grant SELECT on any future tables created in public by the owner:
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO pdodev09;