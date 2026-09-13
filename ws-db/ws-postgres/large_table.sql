-- Sample table: large_table, 10 columns, 50,000,000 records
-- Run: psql -U ericho -d postgres -f large_table.sql
-- Uses generate_series for efficient bulk insert.

DROP TABLE IF EXISTS large_table;

CREATE TABLE large_table (
    id          INTEGER PRIMARY KEY,
    name        TEXT,
    category    TEXT,
    price       NUMERIC(10,2),
    stock       INTEGER,
    created_at  TIMESTAMP,
    updated_at  TIMESTAMP,
    is_active   BOOLEAN,
    description TEXT,
    rating      NUMERIC(3,2)
);

INSERT INTO large_table
SELECT
    gs,
    'item_' || gs,
    'cat_' || (gs % 10),
    (gs % 1000) * 0.99,
    gs % 5000,
    now() - (gs || ' seconds')::interval,
    now() - ((gs % 1000) || ' minutes')::interval,
    (gs % 2) = 0,
    'description for item ' || gs,
    (gs % 100) / 100.0
FROM generate_series(1, 50000000) AS gs;

-- Verify
SELECT count(*) AS total_rows FROM large_table;
SELECT * FROM large_table ORDER BY id LIMIT 5;