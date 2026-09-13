#!/bin/bash
# list_db2_backups.sh
# List all backup images in a DB2 database's history file.
# Correct DB2 syntax: db2 list history backup all for <database>
# (The "ALL" and "FOR <database>" clauses are required.)

CONTAINER=db2server
INST_USER=db2inst1
DB=odsdb

docker exec "$CONTAINER" su - "$INST_USER" -c "db2 list history backup all for $DB"