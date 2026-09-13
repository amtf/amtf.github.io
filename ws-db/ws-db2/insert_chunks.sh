#!/bin/bash
# Load 50,000,000 rows into large_table in 10 chunks of 5,000,000 each.
# Each chunk is a separate transaction that commits, so the transaction log
# is reused instead of filling up in one single 50M-row transaction.
# Run inside the DB2 container as db2inst1: bash /tmp/insert_chunks.sh

set -e

DB2="db2"
CONNECT="db2 connect to mydb"

run_chunk() {
  local start=$1
  local end=$2
  echo "=== Chunk: $start .. $end ==="
  $CONNECT
  $DB2 "INSERT INTO large_table WITH cte (id) AS (SELECT $start FROM SYSIBM.SYSDUMMY1 UNION ALL SELECT id + 1 FROM cte WHERE id < $end) SELECT id, 'item_' || id, 'cat_' || MOD(id,10), MOD(id,1000)*0.99, MOD(id,5000), TIMESTAMP('2026-01-01') + id SECONDS, TIMESTAMP('2026-01-01') + (MOD(id,1000)) MINUTES, MOD(id,2), 'description for item ' || id, MOD(id,100)/100.0 FROM cte"
}

run_chunk 1 5000000
run_chunk 5000001 10000000
run_chunk 10000001 15000000
run_chunk 15000001 20000000
run_chunk 20000001 25000000
run_chunk 25000001 30000000
run_chunk 30000001 35000000
run_chunk 35000001 40000000
run_chunk 40000001 45000000
run_chunk 45000001 50000000

echo "=== ALL CHUNKS DONE ==="