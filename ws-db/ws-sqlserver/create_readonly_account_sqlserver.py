# create_readonly_account_sqlserver.py
# Create the SQL Server read-only account "pdodev09" on the sqledge container.
# Run with the pymssql client (the SQL Edge image does not bundle sqlcmd):
#   /Users/ericho/ws-dsh/sqledge-venv/bin/python create_readonly_account_sqlserver.py
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

conn = pymssql.connect(
    server='localhost', port=1433, user='sa',
    password='<ericho@Abcd1234>', login_timeout=10
)
cur = conn.cursor()

# 1. Create the login
cur.execute("CREATE LOGIN pdodev09 WITH PASSWORD='Pdodev@2026'")

# 2. Create the user in the master database
cur.execute("CREATE USER pdodev09 FOR LOGIN pdodev09")

# 3. Grant read-only (SELECT) on the large_table
cur.execute("GRANT SELECT ON large_table TO pdodev09")

# 4. Set the default schema to dbo so unqualified queries resolve to dbo
cur.execute("ALTER USER pdodev09 WITH DEFAULT_SCHEMA = dbo")

conn.commit()
print('SQL_SERVER_ACCOUNT_CREATED')
conn.close()