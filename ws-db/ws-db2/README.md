# DB2 (ws-db2) — Daily-Use Guide

A practical reference for working with the IBM DB2 Community Edition running in the Docker container `db2server`. The full setup history is in `DB2_Setup_Guide.md` (and `DB2_Setup_Guide.html`).

---

## 0. Readiness Check — Verified

Verified on 2026-09-05: the DB2 Community container is running and the sample `large_table` is loaded.

| Check | Command | Result |
|-------|---------|--------|
| Container up | `docker ps --filter name=db2server` | `Up` (stable) |
| Port open | `nc -zv localhost 50000` | `succeeded` |
| Database | `db2 connect to mydb` | connected |
| Large table | `SELECT COUNT(*) FROM large_table` | 50,000,000 rows |

**Ready:** the DB2 instance is up, port 50000 is listening, database `mydb` exists, and the 50,000,000-row `large_table` is loaded and verified.

---

## 1. Connect to DB2

All DB2 commands run inside the container as the instance user `db2inst1`:

```bash
docker exec db2server su - db2inst1 -c "db2 connect to mydb"
```

Then run SQL as a direct `db2` command argument (this is the reliable way to see query output):

```bash
docker exec db2server su - db2inst1 -c "db2 connect to mydb; db2 \"SELECT 1 AS one FROM SYSIBM.SYSDUMMY1\""
```

---

## 2. Databases

The DB2 Community image starts with the instance but no user database. Create one:

```bash
docker exec db2server su - db2inst1 -c "db2 create database mydb"
```

List databases:

```bash
docker exec db2server su - db2inst1 -c "db2 list db directory"
```

---

## 3. The Sample Table `large_table`

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

### Key notes for DB2

- **Primary key must be `NOT NULL`** — DB2 rejects a nullable primary key (`SQL0542N`).
- **No `generate_series`** — DB2 uses a recursive CTE (`WITH`) to generate the 50M row numbers.
- **Transaction log** — a single 50M-row insert can fill the default log. Increase the log size (`LOGFILSIZ 8192 LOGPRIMARY 200 LOGSECOND 56`, then deactivate/activate) and load in **10 chunks of 5M** (see `insert_chunks.sh`).

### Verify the structure

```bash
docker exec db2server su - db2inst1 -c "db2 connect to mydb; db2 describe table large_table"
```

Expected: 10 columns — `ID, NAME, CATEGORY, PRICE, STOCK, CREATED_AT, UPDATED_AT, IS_ACTIVE, DESCRIPTION, RATING`.

---

## 4. Verification of the 50M Rows

```bash
docker exec db2server su - db2inst1 -c "db2 connect to mydb; db2 \"SELECT COUNT(*) AS total_rows FROM large_table\""
```

Expected: `50,000,000`.

Sample rows:

```bash
docker exec db2server su - db2inst1 -c "db2 connect to mydb; db2 \"SELECT * FROM large_table ORDER BY id FETCH FIRST 5 ROWS ONLY\""
```

---

## 5. Files in This Folder

- `DB2_Setup_Guide.md` / `DB2_Setup_Guide.html` — the full setup and large-table guide (Markdown + HTML)
- `README.md` — this daily-use guide
- `env.list` — the DB2 environment file used for the container
- `large_table.sql` — SQL to create and load `large_table`
- `insert_chunks.sh` — chunked loader for the 50M rows

---

*Generated for local learning on IBM DB2 Community Edition 12.1 (Docker).*