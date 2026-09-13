# test_readonly_account_mmedb.py
# Test the SQL Server read-only account "mmedb_ro" for the MMEDB database:
#   - SELECT must succeed (read-only)
#   - INSERT/CREATE must be denied (no write privilege)
# Run with the pymssql client:
#   /Users/ericho/ws-dsh/sqledge-venv/bin/python test_readonly_account_mmedb.py

import pymssql

# Test 1: SELECT should succeed
conn = pymssql.connect(
    server='localhost', port=1433, user='mmedb_ro',
    password='Mmedb@2026', database='MMEDB', login_timeout=10
)
cur = conn.cursor()
cur.execute('SELECT 1 AS ok')
print('SELECT 1:', cur.fetchone()[0])
cur.execute('SELECT DB_NAME() AS db')
print('DB:', cur.fetchone()[0])
conn.close()
print('SQL_SERVER_MMEDB_READ_OK')

# Test 2: INSERT should be denied
conn = pymssql.connect(
    server='localhost', port=1433, user='mmedb_ro',
    password='Mmedb@2026', database='MMEDB', login_timeout=10
)
cur = conn.cursor()
try:
    cur.execute('CREATE TABLE t (id INT); INSERT INTO t VALUES (1)')
    conn.commit()
    print('INSERT_SUCCEEDED (unexpected)')
except Exception as e:
    print('INSERT_DENIED:', e)
conn.close()