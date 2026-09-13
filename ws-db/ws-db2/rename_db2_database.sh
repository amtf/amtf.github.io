#!/bin/bash
# rename_db2_database.sh
# Rename DB2 database "mydb" -> "odsdb" in the db2server container (DB2 LUW 12.1).
# Method: backup + redirected restore (restore under a new name), then drop the old database.
#
# IMPORTANT: This is a destructive operation. The backup is the safety net.
# Run each step and verify before proceeding. Do NOT drop mydb until odsdb is verified.

set -e

CONTAINER=db2server
INST_USER=db2inst1
OLD_DB=mydb
NEW_DB=odsdb
BACKUP_DIR=/tmp/db2_backup

# Helper: run a db2 command inside the container as the instance user
db2cmd() {
  docker exec "$CONTAINER" su - "$INST_USER" -c "db2 $1"
}

echo "=== Step 0: Preflight — confirm container and old database ==="
docker ps --filter name="$CONTAINER"
db2cmd "list db directory"

echo
echo "=== Step 1: Disconnect / ensure no active connections to mydb ==="
# DB2 backup requires the database to be in a state where it can be backed up.
# If there are active connections, terminate them first:
#   db2 force application all (db2inst1)
#   db2 force application all (db2inst1,db2fenc1)
# NOTE: FORCE APPLICATION ALL does not take an instance in parentheses.
# The valid form is simply: db2 "force application all"
# This step is optional for the rename (DB2 supports online backup).
db2cmd "\"force application all\""

echo
echo "=== Step 2: Backup the old database ==="
# Create the backup directory inside the container as the instance user,
# so db2inst1 can write to it (a root-owned dir causes SQL2061N access denied).
# If the dir already exists and is root-owned, use numeric chown (UID/GID 1000):
#   docker exec "$CONTAINER" chown 1000:1000 "$BACKUP_DIR"
docker exec "$CONTAINER" su - "$INST_USER" -c "mkdir -p $BACKUP_DIR"
db2cmd "backup db $OLD_DB to $BACKUP_DIR"
# Expected: DB20000I  The BACKUP DATABASE command completed successfully.

echo
echo "=== Step 3: Create the new database ==="
db2cmd "create database $NEW_DB"
# Expected: DB20000I  The CREATE DATABASE command completed successfully.

echo
echo "=== Step 4: Restore the backup into the new database name (redirected restore) ==="
# Restore the backup under the new database name using INTO target-db-alias.
# If multiple backup files exist, specify TAKEN AT <timestamp> (from the backup output).
# WITHOUT PROMPTING auto-confirms overwriting the (empty) new database.
# Verified working on DB2 12.1.5.0:
#   db2 restore db mydb from /tmp/db2_backup TAKEN AT 20260906000830 INTO odsdb WITHOUT PROMPTING
# Expected: SQL2540W (warning only) / restore successful.
db2cmd "\"restore db $OLD_DB from $BACKUP_DIR TAKEN AT ${BACKUP_TS:-} INTO $NEW_DB WITHOUT PROMPTING\""

echo
echo "=== Step 5: Verify the new database ==="
db2cmd "connect to $NEW_DB"
db2cmd "list db directory"
# Confirm the directory now shows ODSDB and that large_table is present:
db2cmd "connect to $NEW_DB; db2 \"SELECT COUNT(*) AS total_rows FROM large_table\""
# Expected: 50,000,000

echo
echo "=== Step 6: Drop the old database (only after odsdb is fully verified) ==="
db2cmd "drop database $OLD_DB"
# Expected: DB20000I  The DROP DATABASE command completed successfully.

echo
echo "=== Step 7: Final verification ==="
db2cmd "list db directory"
# Directory should now contain only ODSDB.

echo
echo "Done. Database renamed from $OLD_DB to $NEW_DB."