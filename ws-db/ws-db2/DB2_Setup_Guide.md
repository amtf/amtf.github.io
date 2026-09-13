# DB2 Community Docker Setup Guide

**Date:** 2026-09-05
**Result:** DB2 Community container `db2server` is running and fully set up, with a sample `large_table` (10 columns, 50,000,000 records) created and verified.

---

## 1. Summary

The goal was to run the IBM DB2 Community Edition (`icr.io/db2_community/db2`) in a Docker container on macOS (Docker Desktop, arm64 host, amd64 image via emulation). Two issues were encountered and resolved during setup:

1. **Missing `env.list` file** — the DB2 image requires an env file to configure the instance.
2. **Host bind-mount ownership problem** — on Docker Desktop macOS, a host bind mount (`~/ws-dsh/db2-data`) remaps all file ownership to `root:root` inside the container, so DB2's instance setup (`db2icrt`) could not create usable home directories.

The final working setup uses a **Docker named volume** instead of a host bind mount.

After setup, a database `mydb` was created and a sample table `large_table` (10 columns, 50,000,000 records) was loaded and verified.

---

## 2. The Working Command

```bash
docker run -h db2server --name db2server \
  --restart=always --detach --privileged=true \
  -p 50000:50000 \
  -v db2-data-vol:/database \
  --env-file env.list \
  --platform=linux/amd64 \
  icr.io/db2_community/db2
```

### Required `env.list` file

Create `env.list` in the working directory (`~/ws-dsh`):

```
LICENSE=accept
DB2INSTANCE=db2inst1
DB2INST1_PASSWORD=password
DB2PORT=50000
DB2INST1_OWNER=db2inst1
DB2INST1_OWNER_PASSWORD=password
DB2INST1_OWNER_UID=1000
DB2INST1_OWNER_GROUP=1000
```

---

## 3. Readiness Check

DB2 is ready when the container logs show `Setup has completed` and the instance is active.

```bash
# Quick check: setup completed
docker logs db2server --since 2m 2>&1 | grep -i "Setup has completed"

# Thorough check: instance responds
docker exec db2server su - db2inst1 -c "db2 list active databases"
```

If the first command prints `(*) Setup has completed.`, DB2 is ready.

---

## 4. What Went Wrong and the Fix

### Issue 1: Missing `env.list`

The original command used `--env-file env.list`, but no `env.list` file existed in `~/ws-dsh`. Docker failed to start the container.

**Fix:** Created `~/ws-dsh/env.list` with the required DB2 variables (see above).

### Issue 2: Host bind-mount ownership (the real blocker)

After creating `env.list`, the container started but kept restarting. The logs showed:

```
useradd: cannot create directory /database/config/db2inst1
useradd: cannot create directory /database/config/db2fenc1
```

and later:

```
ERROR: The instance home directory "/database/config/db2inst1" is invalid because it
is not owned by the user "db2inst1". Change the ownership of the home directory
to be owned by the instance user and its primary group.
```

**Root cause:** The `-v ~/ws-dsh/db2-data:/database` bind mount. On Docker Desktop macOS, files in a host bind mount are remapped to `root:root` inside the container, and `chown` does not take effect on the mount. DB2's setup requires the instance home directories (`/database/config/db2inst1`, `/database/config/db2fenc1`) to be owned by `db2inst1`/`db2fenc1`. Attempts to fix ownership on the host (`chown 1000:1000`) and inside the container both failed because the bind mount remaps ownership.

**Fix:** Switched to a Docker named volume, which is a real Linux filesystem inside the Docker VM where ownership works correctly:

```bash
docker volume create db2-data-vol
```

Then re-ran the container with `-v db2-data-vol:/database` instead of the host bind mount.

---

## 5. Verified Result

After switching to the named volume, the setup completed successfully:

```
(*) Configuring/updating instance ...
DBI1070I  Program db2icrt completed successfully.
(*) Cataloging existing databases
DB20000I  The UPDATE DATABASE MANAGER CONFIGURATION command completed
SQL1063N  DB2START processing was successful.
(*) All databases are now active.
(*) Setup has completed.
```

Container status: `Up About a minute` (stable, not restarting). Instance `db2inst1` running (PID 5040).

---

## 6. Important Note: Data Location

The data now lives in the Docker named volume `db2-data-vol`, **not** in `~/ws-dsh/db2-data`. If you specifically need the data in a host folder, the host bind-mount approach will not work on Docker Desktop macOS for this image — that is the tradeoff. To use the host folder, you would need a different Docker engine (e.g., Docker on Linux) or a different volume-sharing setup.

---

## 7. Files in This Guide

- `DB2_Setup_Guide.md` — this guide (Markdown)
- `DB2_Setup_Guide.html` — the same guide in HTML format
- `env.list` — the DB2 environment file used for the container
- `large_table.sql` — the SQL script that creates and loads the sample `large_table`

---

## 8. Creating a Database

The DB2 Community image starts with the instance but no user database (the `/database/data` directory is empty). Create a database before creating tables:

```bash
docker exec db2server su - db2inst1 -c "db2 create database mydb"
```

Expected output:

```
DB20000I  The CREATE DATABASE command completed successfully.
```

Connect to the new database for all subsequent work:

```bash
docker exec db2server su - db2inst1 -c "db2 connect to mydb"
```

---

## 9. Creating the Sample Table `large_table`

The sample table has **10 columns** and **50,000,000 records**. The SQL is in `large_table.sql`:

```sql
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
```

### 9a. Primary key must be `NOT NULL`

DB2 rejects a primary key column that can contain nulls:

```
SQL0542N  The column named "ID" cannot be a column of a primary key or unique
key constraint because it can contain null values.  SQLSTATE=42831
```

**Fix:** declare the key column `INTEGER NOT NULL PRIMARY KEY`.

### 9b. Transaction log full — increase the log size

The first 50M-row insert failed with:

```
SQL0964C  The transaction log for the database is full.  SQLSTATE=57011
```

The default DB2 Community database has a small transaction log (13 primary + 12 secondary files × 4MB ≈ 100MB), which is too small for a 50M-row insert. Increase the log size (DB2 requires `logprimary + logsecond <= 256`):

```bash
docker exec db2server su - db2inst1 -c "db2 connect to mydb; db2 \"UPDATE DATABASE CONFIGURATION FOR mydb USING LOGFILSIZ 8192 LOGPRIMARY 200 LOGSECOND 56\""
```

Expected output:

```
DB20000I  The UPDATE DATABASE CONFIGURATION command completed successfully.
SQL1363W  One or more of the parameters submitted for immediate modification
were not changed dynamically. ... the database must be shutdown and reactivated
before the configuration parameter changes become effective.
```

Apply the change by deactivating and reactivating the database:

```bash
docker exec db2server su - db2inst1 -c "db2 deactivate db mydb; db2 activate db mydb"
```

Expected output:

```
DB20000I  The DEACTIVATE DATABASE command completed successfully.
DB20000I  The ACTIVATE DATABASE command completed successfully.
```

This gives 256 log files × 32MB ≈ 8GB of transaction log space.

### 9c. Load 50,000,000 records

DB2 has no `generate_series`, so the insert uses a recursive CTE (`WITH`) to generate the 50M row numbers, then derives the other 9 columns from the row number:

```sql
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
```

Run it (as a single `db2` command, or via `db2 -tvf large_table.sql`):

```bash
docker exec db2server su - db2inst1 -c "db2 connect to mydb; db2 -tvf large_table.sql"
```

---

## 10. Verification

After the insert, verify the row count and sample rows:

```bash
docker exec db2server su - db2inst1 -c "db2 connect to mydb; db2 \"SELECT COUNT(*) AS total_rows FROM large_table\""
docker exec db2server su - db2inst1 -c "db2 connect to mydb; db2 \"SELECT * FROM large_table ORDER BY id FETCH FIRST 5 ROWS ONLY\""
```

Expected row count: `50,000,000`.

---

## 11. Summary

| Check | Command | Result |
|-------|---------|--------|
| Container up | `docker ps --filter name=db2server` | `Up` (stable) |
| Port open | `nc -zv localhost 50000` | `succeeded` |
| Database created | `db2 create database mydb` | `DB20000I` completed |
| Table created | `CREATE TABLE large_table` | `DB20000I` completed |
| 50M rows loaded | `INSERT INTO large_table` | completed |
| Row count | `SELECT COUNT(*) FROM large_table` | `50,000,000` |

The DB2 Community container is **fully working**: the instance is running, port 50000 is published, database `mydb` exists, and the 50,000,000-row `large_table` is loaded and verified.