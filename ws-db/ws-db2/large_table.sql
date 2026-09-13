-- Sample table: large_table, 10 columns, 50,000,000 records
-- Run: db2 connect to mydb; db2 -tvf large_table.sql
-- Uses a recursive CTE to generate 50,000,000 rows efficiently.

DROP TABLE IF EXISTS large_table;

CREATE TABLE large_table (
    id          INTEGER NOT NULL PRIMARY KEY,
    name        VARCHAR(50),
    category    VARCHAR(50),
    price       DECIMAL(10,2),
    stock       INTEGER,
    created_at  TIMESTAMP,
    updated_at  TIMESTAMP,
    is_active   SMALLINT,
    description VARCHAR(100),
    rating      DECIMAL(3,2)
);

INSERT INTO large_table
WITH cte (id) AS (
    SELECT 1 FROM SYSIBM.SYSDUMMY1
    UNION ALL
    SELECT id + 1 FROM cte WHERE id < 50000000
)
SELECT
    id,
    'item_' || id,
    'cat_' || MOD(id, 10),
    MOD(id, 1000) * 0.99,
    MOD(id, 5000),
    TIMESTAMP('2026-01-01') + id SECONDS,
    TIMESTAMP('2026-01-01') + (MOD(id, 1000)) MINUTES,
    MOD(id, 2),
    'description for item ' || id,
    MOD(id, 100) / 100.0
FROM cte;

-- Verify
SELECT COUNT(*) AS total_rows FROM large_table;
SELECT * FROM large_table ORDER BY id FETCH FIRST 5 ROWS ONLY;