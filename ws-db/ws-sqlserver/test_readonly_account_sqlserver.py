# test_readonly_account_sqlserver.py
# Test the SQL Server read-only account "pdodev09":
#   - SELECT must succeed (read-only)
#   - INSERT must be denied (no write privilege)
# Run with the pymssql client:
#   /Users/ericho/ws-dsh/sqledge-venv/bin/python test_readonly_account_sqlserver.py

import pymssql

# Test 1: SELECT should succeed
conn = pymssql.connect(
    server='localhost', port=1433, user='pdodev09',
    password='Pdodev@2026', login_timeout=10
)
cur = conn.cursor()
cur.execute('SELECT COUNT(*) AS total FROM large_table')
print('TOTAL:', cur.fetchone()[0])
conn.close()
print('SQL_SERVER_READ_OK')

# Test 2: INSERT should be denied
conn = pymssql.connect(
    server='localhost', port=1433, user='pdodev09',
    password='Pdodev@2026', login_timeout=10
)
cur = conn.cursor()
try:
    cur.execute('INSERT INTO large_table (id) VALUES (999999999)')
    conn.commit()
    print('INSERT_SUCCEEDED (unexpected)')
except Exception as e:
    print('INSERT_DENIED:', e)
conn.close()