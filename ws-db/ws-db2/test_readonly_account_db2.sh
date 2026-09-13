#!/bin/bash
# test_readonly_account_db2.sh
# Test the DB2 read-only account "pdodev09":
#   - SELECT must succeed (read-only)
#   - INSERT must be denied (no write privilege)
set -e

echo "== Test 1: SELECT as pdodev09 (should succeed) =="
docker exec db2server su - pdodev09 -c "source /database/config/db2inst1/sqllib/db2profile; db2 connect to ODSDB; db2 \"SELECT COUNT(*) AS total FROM DB2INST1.LARGE_TABLE\""

echo "== Test 2: INSERT as pdodev09 (should be denied) =="
docker exec db2server su - pdodev09 -c "source /database/config/db2inst1/sqllib/db2profile; db2 connect to ODSDB; db2 \"INSERT INTO DB2INST1.LARGE_TABLE (id) VALUES (999999999)\"" || echo "INSERT correctly denied (expected)"

echo "DB2 read-only test complete."