# SQL Server (ws-sqlserver) — Read-Only Account `mmedb_ro` for `MMEDB`

Steps and scripts to create and verify a read-only database account named `mmedb_ro` on the SQL Edge container `sqledge` (port 1433), for the `MMEDB` database.

Verified on 2026-09-06: the account works — `SELECT` succeeds in `MMEDB` and `INSERT`/`CREATE TABLE` is denied.

---

## 1. What was done

1. Created the login `mmedb_ro` with password `Mmedb@2026`.
2. Created the user `mmedb_ro` in the `MMEDB` database.
3. Added `mmedb_ro` to the `db_datareader` database role (read-only: `SELECT` on all current and future tables in `MMEDB`).

The account is **read-only**: it can connect to `MMEDB` and `SELECT`, but cannot `INSERT`/`UPDATE`/`DELETE`/`CREATE`.

---

## 2. Scripts in this folder

- `create_readonly_account_mmedb.py` — creates the login, user, and read-only grant (uses `pymssql`).
- `test_readonly_account_mmedb.py` — verifies `SELECT` succeeds and `INSERT` is denied.

---

## 3. Run the create script

```bash
/Users/ericho/ws-dsh/sqledge-venv/bin/python create_readonly_account_mmedb.py
```

Expected output:

```
SQL_SERVER_MMEDB_READONLY_CREATED
```

---

## 4. Run the test script

```bash
/Users/ericho/ws-dsh/sqledge-venv/bin/python test_readonly_account_mmedb.py
```

Expected:

- `SELECT 1` → `1` and `SQL_SERVER_MMEDB_READ_OK`
- `CREATE TABLE`/`INSERT` → `INSERT_DENIED` (permission denied)

---

## 5. Manual verification (pymssql)

```python
import pymssql
# SELECT (should succeed)
conn = pymssql.connect(server='localhost', port=1433, user='mmedb_ro', password='Mmedb@2026', database='MMEDB', login_timeout=10)
cur = conn.cursor()
cur.execute('SELECT 1 AS ok')
print(cur.fetchone()[0])
conn.close()
# INSERT (should be denied)
conn = pymssql.connect(server='localhost', port=1433, user='mmedb_ro', password='Mmedb@2026', database='MMEDB', login_timeout=10)
cur = conn.cursor()
cur.execute('CREATE TABLE t (id INT); INSERT INTO t VALUES (1)')
```

---

## 6. Account details

| Item | Value |
|------|-------|
| Username | `mmedb_ro` |
| Password | `Mmedb@2026` |
| Database | `MMEDB` |
| Role | `db_datareader` (read-only) |
| Privileges | `SELECT` on all tables in `MMEDB` |

---

## 7. Note on sqlcmd

The native `go-sqlcmd` binary in this workspace (`/Users/ericho/ws-dsh/sqlcmd`, v1.10.0) **can connect** to this SQL Edge container if you disable encryption:

```bash
./sqlcmd -S localhost -U sa -P '<ericho@Abcd1234>' -N disable -Q "SELECT @@VERSION; SELECT name FROM sys.databases;"
```

Without `-N disable`, it fails with:

```
TLS Handshake failed: tls: failed to parse certificate from server: x509: negative serial number
```

**Cause of the problem:** SQL Edge's self-signed TLS certificate has a **negative serial number**, which Go's `crypto/x509` library rejects at parse time — before any trust check. The `-C` (trust-server-certificate) flag does not help because the certificate cannot even be parsed, and `-N false` (encryption disabled) still attempts the handshake. `-N disable` skips the TLS handshake entirely, so the query proceeds. `pymssql` remains the simplest working client (as documented in the main `README.md`).

*Generated for local learning on Microsoft Azure SQL Edge (Docker).*