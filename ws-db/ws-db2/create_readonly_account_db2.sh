#!/bin/bash
# create_readonly_account_db2.sh
# Create the DB2 read-only account "pdodev09" on ODSDB and MISDB.
# Run from the host (the DB2 container is named db2server).
set -e

PASSWORD='Pdodev@2026'

echo "== Step 1: Create the OS user pdodev09 in the DB2 container =="
docker exec db2server useradd -m -g db2iadm1 pdodev09 || true

echo "== Step 2: Set the password for pdodev09 =="
docker exec db2server sh -c "echo 'pdodev09:$PASSWORD' | chpasswd"

echo "== Step 3: Grant DB2 CONNECT + SELECT privileges on ODSDB and MISDB =="
docker exec db2server su - db2inst1 -c "db2 connect to ODSDB; db2 grant connect on database to user pdodev09; db2 grant select on table DB2INST1.LARGE_TABLE to user pdodev09; db2 connect to MISDB; db2 grant connect on database to user pdodev09; db2 grant select on table DB2INST1.LARGE_TABLE to user pdodev09"

echo "DB2 read-only account pdodev09 created."