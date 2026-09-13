-- Storage usage check for ws-postgres
-- Run: psql -U ericho -d postgres -f storage_check.sql

-- 1. Database size
SELECT pg_size_pretty(pg_database_size('postgres')) AS db_size;

-- 2. Table size (large_table)
SELECT pg_size_pretty(pg_total_relation_size('large_table')) AS large_table_size;

-- 3. Table size (sample_products)
SELECT pg_size_pretty(pg_total_relation_size('sample_products')) AS sample_products_size;

-- 4. All tables in the database with sizes
SELECT
    relname AS table_name,
    pg_size_pretty(pg_total_relation_size(oid)) AS total_size
FROM pg_class
WHERE relkind = 'r'
  AND relname NOT LIKE 'pg_%'
ORDER BY pg_total_relation_size(oid) DESC;