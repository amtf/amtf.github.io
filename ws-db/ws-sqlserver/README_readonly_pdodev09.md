# SQL Server (ws-sqlserver) — Read-Only Account `pdodev09`

Steps and scripts to create and verify a read-only database account named `pdodev09` on the SQL Edge container `sqledge` (port 1433).

Verified on 2026-09-06: the account works — `SELECT` returns 50,000,000 rows and `INSERT` is denied.

---

## 1. What was done

1. Created the login `pdodev09` with password `Pdodev@2026`.
2. Created the user `pdodev09` in the `master` database.
3. Granted `SELECT` on `large_table` to `pdodev09`.
4. Set the default schema to `dbo` (`ALTER USER pdodev09 WITH DEFAULT_SCHEMA = dbo`) so unqualified queries like `SELECT * FROM large_table` resolve to `dbo`.

The account is **read-only**: it can connect and `SELECT`, but cannot `INSERT`/`UPDATE`/`DELETE`.

---

## 2. Scripts in this folder

- `create_readonly_account_sqlserver.py` — creates the login, user, and read-only grant (uses `pymssql`).
- `test_readonly_account_sqlserver.py` — verifies `SELECT` succeeds and `INSERT` is denied.

---

## 3. Run the create script

```bash
/Users/ericho/ws-dsh/sqledge-venv/bin/python create_readonly_account_sqlserver.py
```

Expected output:

```
SQL_SERVER_ACCOUNT_CREATED
```

---

## 4. Run the test script

```bash
/Users/ericho/ws-dsh/sqledge-venv/bin/python test_readonly_account_sqlserver.py
```

Expected:

- `SELECT COUNT(*) FROM large_table` → `50000000` and `SQL_SERVER_READ_OK`
- `INSERT INTO large_table (id) VALUES (999999999)` → `INSERT_DENIED` (permission denied)

---

## 5. Manual verification (pymssql)

```python
import pymssql
# SELECT (should succeed)
conn = pymssql.connect(server='localhost', port=1433, user='pdodev09', password='Pdodev@2026', login_timeout=10)
cur = conn.cursor()
cur.execute('SELECT COUNT(*) AS total FROM large_table')
print(cur.fetchone()[0])
conn.close()
# INSERT (should be denied)
conn = pymssql.connect(server='localhost', port=1433, user='pdodev09', password='Pdodev@2026', login_timeout=10)
cur = conn.cursor()
cur.execute('INSERT INTO large_table (id) VALUES (999999999)')
```

---

## 6. Account details

| Item | Value |
|------|-------|
| Username | `pdodev09` |
| Password | `Pdodev@2026` |
| Database | `master` |
| Table granted | `large_table` |
| Default schema | `dbo` |
| Privileges | `SELECT` (read-only) |

---

## 7. Default schema `dbo`

The `large_table` is already in the `dbo` schema (schema_id 1), and `pdodev09`'s default schema is `dbo`. To make it explicit, run:

```sql
ALTER USER pdodev09 WITH DEFAULT_SCHEMA = dbo;
```

Verify:

```sql
SELECT name, default_schema_name
FROM sys.database_principals
WHERE name = 'pdodev09';
```

To move a table into `dbo` (if it is in another schema):

```sql
ALTER SCHEMA dbo TRANSFER large_table;
```

---

## 8. Note on sqlcmd

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