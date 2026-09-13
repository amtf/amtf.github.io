# PostgreSQL Daily-Use Guide

A practical, day-to-day reference for working with PostgreSQL locally. Written for the setup installed via Homebrew (`postgresql@18`), but the SQL and psql commands apply to any PostgreSQL server.

---

## 0. Readiness Check — Verified

Verified on 2026-09-05: the PostgreSQL server is running and ready for use.

| Check | Command | Result |
|-------|---------|--------|
| Server process | `pgrep -fl postgres` | running (`postgresql@18`) |
| Port 5432 | `nc -zv localhost 5432` | succeeded |
| Connect + query | `psql -U ericho -d postgres -c "SELECT 1"` | `SELECT 1 -> 1` |
| Large table | `SELECT COUNT(*) FROM large_table` | 50,000,000 rows |

**Ready:** the server is up, port 5432 is listening, and authenticated queries execute successfully.

---

## 1. Getting Started

### Connect to the server

```bash
psql -d postgres          # connect to the default "postgres" database
psql -d mydb              # connect to a specific database
psql -U username -d mydb  # connect as a specific user
psql -h localhost -p 5432 # specify host and port (defaults: localhost:5432)
```

On the Homebrew setup, local connections use `trust` auth, so you connect as your macOS user (`ericho`) with no password.

### What is a database?

A **database** is a named collection of tables. PostgreSQL ships with a default database called `postgres` (used for maintenance) plus `template1` (a template for creating new databases). You almost never work directly in `postgres` — create your own.

### Create / drop a database

```bash
createdb mydb             # create a database (command-line tool)
dropdb mydb               # drop a database (command-line tool)
```

Or inside psql:

```sql
CREATE DATABASE mydb;
DROP DATABASE mydb;
```

> **Note:** `CREATE DATABASE` cannot run inside a transaction block, and you cannot drop a database you are currently connected to.

---

## 2. psql Essentials (Meta-Commands)

psql is the interactive terminal. Commands starting with `\` are **meta-commands** — they control psql itself, not SQL.

| Command | What it does |
| --- | --- |
| `\l` | List all databases |
| `\c mydb` | Connect to database `mydb` |
| `\dt` | List tables in the current database |
| `\d tablename` | Describe a table (columns, indexes, constraints) |
| `\di` | List indexes |
| `\dv` | List views |
| `\df` | List functions |
| `\dn` | List schemas |
| `\du` | List roles (users) |
| `\dp` | List table privileges |
| `\d+ tablename` | Detailed description of a table |
| `\dt+` | Tables with size and description |
| `\pset` | Adjust display options (e.g. `\pset pager off`) |
| `\x` | Toggle expanded (vertical) display for wide rows |
| `\q` | Quit psql |
| `\h` | Help on SQL syntax |
| `\?` | Help on meta-commands |
| `\e` | Open the last query in your editor |
| `\i file.sql` | Execute SQL from a file |
| `\timing` | Toggle query timing display |

**Tip:** `\d` is the most useful command — it shows you the structure of any table, view, or index in one glance.

---

## 3. SQL Fundamentals

### SELECT — read data

```sql
SELECT * FROM users;                    -- all columns, all rows
SELECT name, email FROM users;          -- specific columns
SELECT * FROM users WHERE age > 30;     -- filter rows
SELECT * FROM users ORDER BY name;      -- sort
SELECT * FROM users LIMIT 10;           -- first 10 rows
SELECT COUNT(*) FROM users;             -- count rows
SELECT AVG(age) FROM users;             -- average of a column
```

### INSERT — add data

```sql
INSERT INTO users (name, email) VALUES ('Alice', 'alice@example.com');
INSERT INTO users (name, email) VALUES
  ('Bob', 'bob@example.com'),
  ('Carol', 'carol@example.com');       -- multiple rows at once
```

### UPDATE — change data

```sql
UPDATE users SET email = 'new@example.com' WHERE name = 'Alice';
```

> **Always use a `WHERE` clause.** Without it, `UPDATE` changes every row in the table.

### DELETE — remove data

```sql
DELETE FROM users WHERE name = 'Bob';
```

> **Always use a `WHERE` clause.** Without it, `DELETE` removes every row.

### WHERE conditions

```sql
WHERE age > 30
WHERE age BETWEEN 18 AND 65
WHERE name LIKE 'A%'        -- starts with A
WHERE email IS NULL         -- check for null
WHERE city IN ('NYC', 'LA')
WHERE age > 30 AND city = 'NYC'
WHERE age > 30 OR city = 'NYC'
```

---

## 4. Tables & Data Types

### Create a table

```sql
CREATE TABLE users (
  id         SERIAL PRIMARY KEY,        -- auto-incrementing integer
  name       TEXT NOT NULL,
  email      TEXT UNIQUE,
  age        INTEGER,
  created_at TIMESTAMPTZ DEFAULT now()
);
```

### Common data types

| Type | Use it for |
| --- | --- |
| `SERIAL` / `BIGSERIAL` | Auto-incrementing integer primary keys |
| `INTEGER` / `BIGINT` | Whole numbers |
| `NUMERIC(p,s)` | Exact decimals (money, prices) |
| `REAL` / `DOUBLE PRECISION` | Approximate floating point |
| `TEXT` | Long strings |
| `VARCHAR(n)` | String with max length n |
| `BOOLEAN` | true / false |
| `DATE` | Just a date |
| `TIMESTAMP` / `TIMESTAMPTZ` | Date + time (TZ = with time zone) |
| `JSONB` | Stored JSON, queryable |
| `UUID` | Globally unique identifiers |
| `BYTEA` | Binary data (files, images) |

> **Prefer `TIMESTAMPTZ` over `TIMESTAMP`** for timestamps — it stores the time zone and converts correctly.

### Alter a table

```sql
ALTER TABLE users ADD COLUMN phone TEXT;        -- add a column
ALTER TABLE users DROP COLUMN phone;            -- remove a column
ALTER TABLE users RENAME COLUMN phone TO mobile; -- rename a column
ALTER TABLE users ALTER COLUMN age SET DEFAULT 0;
```

### Drop a table

```sql
DROP TABLE users;
DROP TABLE IF EXISTS users;   -- safe: no error if it doesn't exist
```

---

## 5. Keys & Indexes

### Primary key

Uniquely identifies each row. PostgreSQL automatically creates an index for it.

```sql
CREATE TABLE users (
  id SERIAL PRIMARY KEY
);
```

### Foreign key — link tables

```sql
CREATE TABLE orders (
  id         SERIAL PRIMARY KEY,
  user_id    INTEGER REFERENCES users(id),
  amount     NUMERIC(10,2)
);
```

### Unique constraint

```sql
CREATE TABLE users (
  email TEXT UNIQUE
);
```

### Indexes — speed up lookups

```sql
CREATE INDEX idx_users_email ON users (email);
CREATE INDEX idx_orders_user ON orders (user_id);
```

> **When to index:** columns used in `WHERE`, `JOIN`, or `ORDER BY`. Don't index everything — each index costs space and slows writes.

### Check a query plan

```sql
EXPLAIN SELECT * FROM users WHERE email = 'x@y.com';
EXPLAIN ANALYZE SELECT * FROM users WHERE email = 'x@y.com';
```

`EXPLAIN ANALYZE` actually runs the query and shows real timings — great for finding slow queries.

---

## 6. Transactions

A **transaction** groups multiple statements into one atomic unit: all succeed or all roll back.

```sql
BEGIN;
UPDATE accounts SET balance = balance - 100 WHERE id = 1;
UPDATE accounts SET balance = balance + 100 WHERE id = 2;
COMMIT;   -- make it permanent
```

If something goes wrong, undo everything:

```sql
BEGIN;
DELETE FROM orders WHERE id = 5;
-- oops, that was a mistake
ROLLBACK; -- undo the whole transaction
```

> **Rule of thumb:** any multi-step change (transfer money, update several tables) belongs in a transaction.

---

## 7. Backups & Restore

### Dump a single database (SQL format)

```bash
pg_dump mydb > mydb.sql
```

### Restore it

```bash
psql -d mydb < mydb.sql
```

### Dump with compression

```bash
pg_dump mydb | gzip > mydb.sql.gz
zcat mydb.sql.gz | psql -d mydb
```

### Dump all databases

```bash
pg_dumpall > all.sql
```

### Custom-format dump (faster, selective restore)

```bash
pg_dump -F c mydb > mydb.dump
pg_restore -d mydb mydb.dump
```

> **Daily habit:** `pg_dump` before any risky change. Restoring is just `psql < file`.

---

## 8. Performance & Practical Tips

### See what's running

```sql
SELECT pid, state, query
FROM pg_stat_activity
WHERE state = 'active';
```

### Find slow queries

```sql
SELECT query, calls, total_time, mean_time
FROM pg_stat_statements
ORDER BY total_time DESC
LIMIT 10;
```

> Requires the `pg_stat_statements` extension: `CREATE EXTENSION pg_stat_statements;`

### Vacuum (clean up dead rows)

```bash
vacuumdb mydb
```

### Check disk usage of tables

```sql
SELECT relname, n_live_tuples, n_dead_tuples
FROM pg_stat_user_tables;
```

### Useful settings

```bash
# In psql:
SHOW shared_buffers;      -- memory for caching
SHOW work_mem;            -- memory for sorting/hashing
SHOW max_connections;
```

---

## 9. Common Daily Tasks (Cheat Sheet)

| Task | Command |
| --- | --- |
| Connect to a database | `psql -d mydb` |
| List databases | `\l` |
| List tables | `\dt` |
| Describe a table | `\d users` |
| Create a database | `createdb mydb` |
| Drop a database | `dropdb mydb` |
| Create a table | `CREATE TABLE ...` |
| Add a column | `ALTER TABLE ... ADD COLUMN ...` |
| Back up a database | `pg_dump mydb > mydb.sql` |
| Restore a database | `psql -d mydb < mydb.sql` |
| Start the server | `brew services start postgresql@18` |
| Stop the server | `brew services stop postgresql@18` |
| Check server status | `pg_ctl -D /opt/homebrew/var/postgresql@18 status` |

---

## 10. Where the files live (Homebrew setup)

- Binaries: `/opt/homebrew/opt/postgresql@18/bin`
- Data cluster: `/opt/homebrew/var/postgresql@18`
- Config: `/opt/homebrew/var/postgresql@18/postgresql.conf`
- Access rules: `/opt/homebrew/var/postgresql@18/pg_hba.conf`

Add the binaries to your PATH:

```bash
export PATH="/opt/homebrew/opt/postgresql@18/bin:$PATH"
```

---

*Generated for local learning on PostgreSQL 18.6 (Homebrew).*