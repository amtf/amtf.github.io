# DB2 (ws-db2) — Read-Only Account `pdodev09`

Steps and scripts to create and verify a read-only database account named `pdodev09` on the DB2 instance running in the Docker container `db2server`.

Verified on 2026-09-06: the account works — `SELECT` returns 50,000,000 rows and `INSERT` is denied.

---

## 1. What was done

DB2 authenticates against OS users, so the account is an OS user inside the container plus DB2 privileges:

1. Created the OS user `pdodev09` (group `db2iadm1`) in the container.
2. Set the password `Pdodev@2026` via `chpasswd`.
3. Granted `CONNECT` on databases `ODSDB` and `MISDB`.
4. Granted `SELECT` on `DB2INST1.LARGE_TABLE` in both databases.

The account is **read-only**: it can connect and `SELECT`, but cannot `INSERT`/`UPDATE`/`DELETE`.

---

## 2. Scripts in this folder

- `create_readonly_account_db2.sh` — creates the OS user, sets the password, and grants the DB2 privileges.
- `test_readonly_account_db2.sh` — verifies `SELECT` succeeds and `INSERT` is denied.

---

## 3. Run the create script

```bash
./create_readonly_account_db2.sh
```

Expected output ends with:

```
DB2 read-only account pdodev09 created.
```

---

## 4. Run the test script

```bash
./test_readonly_account_db2.sh
```

Expected:

- `SELECT COUNT(*) FROM DB2INST1.LARGE_TABLE` → `50000000`
- `INSERT INTO DB2INST1.LARGE_TABLE (id) VALUES (999999999)` → denied with `SQL0551N` (insufficient privilege).

---

## 5. Manual verification commands

```bash
# SELECT (should succeed)
docker exec db2server su - pdodev09 -c "source /database/config/db2inst1/sqllib/db2profile; db2 connect to ODSDB; db2 \"SELECT COUNT(*) AS total FROM DB2INST1.LARGE_TABLE\""

# INSERT (should be denied)
docker exec db2server su - pdodev09 -c "source /database/config/db2inst1/sqllib/db2profile; db2 connect to ODSDB; db2 \"INSERT INTO DB2INST1.LARGE_TABLE (id) VALUES (999999999)\""
```

---

## 6. Account details

| Item | Value |
|------|-------|
| Username | `pdodev09` |
| Password | `Pdodev@2026` |
| Databases | `ODSDB`, `MISDB` |
| Tables granted | `DB2INST1.LARGE_TABLE` (both databases) |
| Privileges | `CONNECT`, `SELECT` (read-only) |

*Generated for local learning on IBM DB2 Community Edition 12.1 (Docker).*