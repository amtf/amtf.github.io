# create_readonly_account_mmedb.py
# Create the SQL Server read-only account "mmedb_ro" for the MMEDB database
# on the sqledge container.
# Run with the pymssql client (the SQL Edge image does not bundle sqlcmd):
#   /Users/ericho/ws-dsh/sqledge-venv/bin/python create_readonly_account_mmedb.py
#
# NOTE on sqlcmd: the native go-sqlcmd binary in this workspace CAN connect to
# this SQL Edge container if you disable encryption:
#   ./sqlcmd -S localhost -U sa -P '<ericho@Abcd1234>' -N disable -Q "SELECT @@VERSION"
# Without -N disable it fails with
#   "TLS Handshake failed: tls: failed to parse certificate from server: x509: negative serial number"
# even with -C (trust-server-certificate). Cause: SQL Edge's self-signed TLS
# certificate has a negative serial number, which Go's crypto/x509 rejects at
# parse time. -N disable skips the TLS handshake. pymssql is the simplest client.

import pymssql

# 1. Create the login (in master)
conn = pymssql.connect(
    server='localhost', port=1433, user='sa',
    password='<ericho@Abcd1234>', login_timeout=10
)
cur = conn.cursor()
cur.execute("CREATE LOGIN mmedb_ro WITH PASSWORD='Mmedb@2026'")
conn.commit()
conn.close()

# 2. Create the user in MMEDB and grant read-only (db_datareader role)
conn = pymssql.connect(
    server='localhost', port=1433, user='sa',
    password='<ericho@Abcd1234>', database='MMEDB', login_timeout=10
)
cur = conn.cursor()
cur.execute('CREATE USER mmedb_ro FOR LOGIN mmedb_ro')
cur.execute('ALTER ROLE db_datareader ADD MEMBER mmedb_ro')
conn.commit()
conn.close()
print('SQL_SERVER_MMEDB_READONLY_CREATED')