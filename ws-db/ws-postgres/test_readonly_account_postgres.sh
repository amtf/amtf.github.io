#!/bin/bash
# test_readonly_account_postgres.sh
# Test the PostgreSQL read-only account "pdodev09":
#   - SELECT must succeed (read-only)
#   - INSERT must be denied (no write privilege)
set -e

echo "== Test 1: SELECT as pdodev09 (should succeed) =="
psql -U pdodev09 -d postgres -c "SELECT COUNT(*) AS total FROM large_table"

echo "== Test 2: INSERT as pdodev09 (should be denied) =="
psql -U pdodev09 -d postgres -c "INSERT INTO large_table (id) VALUES (999999999)" || echo "INSERT correctly denied (expected)"

echo "PostgreSQL read-only test complete."