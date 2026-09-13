#!/bin/bash
# clone_odsdb_to_misdb.sh
# Clone DB2 database ODSDB -> MISDB in the db2server container (DB2 LUW 12.1.5.0).
# Method: backup ODSDB, create MISDB, restore the backup INTO MISDB, verify.
# The original ODSDB is kept (this is a clone, not a rename).
#
# Executed and verified on 2026-09-06:
#   - Backup timestamp: 20260906003113
#   - MISDB verified: large_table = 50,000,000 rows
#   - Final directory: ODSDB + MISDB both present

set -e

CONTAINER=db2server
INST_USER=db2inst1
SRC_DB=odsdb
DST_DB=misdb
BACKUP_DIR=/tmp/db2_backup_misdb
BACKUP_TS=20260906003113   # timestamp from the backup output; update if you re-run

# Helper: run a db2 command inside the container as the instance user
db2cmd() {
  docker exec "$CONTAINER" su - "$INST_USER" -c "db2 $1"
}

echo "=== Step 1: Preflight — confirm ODSDB exists ==="
db2cmd "list db directory"

echo
echo "=== Step 2: Create a backup directory as db2inst1 (writable) ==="
docker exec "$CONTAINER" su - "$INST_USER" -c "mkdir -p $BACKUP_DIR"

echo
echo "=== Step 3: Backup ODSDB ==="
db2cmd "backup db $SRC_DB to $BACKUP_DIR"
# Expected: Backup successful. The timestamp for this backup image is : <ts>
# Note the timestamp; it is used in Step 5 (TAKEN AT).

echo
echo "=== Step 4: Create the new database MISDB ==="
db2cmd "create database $DST_DB"
# Expected: DB20000I  The CREATE DATABASE command completed successfully.

echo
echo "=== Step 5: Restore the backup INTO MISDB ==="
# INTO target-db-alias restores under the new name. TAKEN AT is required when
# multiple backup files exist. WITHOUT PROMPTING auto-confirms overwriting the
# empty MISDB. Verified working on DB2 12.1.5.0:
#   db2 restore db odsdb from /tmp/db2_backup_misdb TAKEN AT 20260906003113 INTO misdb WITHOUT PROMPTING
db2cmd "\"restore db $SRC_DB from $BACKUP_DIR TAKEN AT $BACKUP_TS INTO $DST_DB WITHOUT PROMPTING\""
# Expected: SQL2540W (warning only) / restore successful.

echo
echo "=== Step 6: Verify MISDB ==="
db2cmd "connect to $DST_DB"
db2cmd "connect to $DST_DB; db2 \"SELECT COUNT(*) AS total_rows FROM large_table\""
# Expected: 50,000,000

echo
echo "=== Step 7: Final check — both databases present ==="
db2cmd "list db directory"
# Expected: directory shows both ODSDB and MISDB.

echo
echo "Done. ODSDB cloned to MISDB (ODSDB kept)."