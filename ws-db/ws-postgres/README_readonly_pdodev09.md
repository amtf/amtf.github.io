# PostgreSQL (ws-postgres) — Read-Only Account `pdodev09`

Steps and scripts to create and verify a read-only database account named `pdodev09` on the local PostgreSQL server (Homebrew `postgresql@18`, port 5432).

Verified on 2026-09-06: the account works — `SELECT` returns 50,000,000 rows and `INSERT` is denied.

---

## 1. What was done

1. Created the role `pdodev09` with `LOGIN` and password `Pdodev@2026`.
2. Granted `CONNECT` on the `postgres` database.
3. Granted `SELECT` on all tables in the `public` schema.
4. Set default privileges so future tables in `public` are also `SELECT`-only for `pdodev09`.

The account is **read-only**: it can connect and `SELECT`, but cannot `INSERT`/`UPDATE`/`DELETE`.

---

## 2. Scripts in this folder

- `create_readonly_account_postgres.sql` — creates the role and grants the read-only privileges.
- `test_readonly_account_postgres.sh` — verifies `SELECT` succeeds and `INSERT` is denied.

---

## 3. Run the create script

```bash
psql -U ericho -d postgres -f create_readonly_account_postgres.sql
```

Expected output:

```
CREATE ROLE
GRANT
GRANT
ALTER DEFAULT PRIVILEGES
```

---

## 4. Run the test script

```bash
./test_readonly_account_postgres.sh
```

Expected:

- `SELECT COUNT(*) FROM large_table` → `50000000`
- `INSERT INTO large_table (id) VALUES (999999999)` → `ERROR: permission denied for table large_table`

---

## 5. Manual verification commands

```bash
# SELECT (should succeed)
psql -U pdodev09 -d postgres -c "SELECT COUNT(*) AS total FROM large_table"

# INSERT (should be denied)
psql -U pdodev09 -d postgres -c "INSERT INTO large_table (id) VALUES (999999999)"
```

---

## 6. Account details

| Item | Value |
|------|-------|
| Username | `pdodev09` |
| Password | `Pdodev@2026` |
| Database | `postgres` |
| Schema | `public` |
| Tables granted | `large_table`, `sample_products` (all public tables) |
| Privileges | `CONNECT`, `SELECT` (read-only) |

*Generated for local learning on PostgreSQL 18.6 (Homebrew).*