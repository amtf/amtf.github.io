# PostgreSQL Storage Check — ws-postgres

Date: 2026-09-05

## Database and Table Sizes

| Item | Size |
| --- | --- |
| Database `postgres` | **7087 MB (~7.1 GB)** |
| `large_table` | **7079 MB (~7.1 GB)** |
| `sample_products` | **32 kB** |

The 50,000,000-row `large_table` accounts for essentially all of the database's ~7.1 GB storage.

## Physical Data Directory

The actual on-disk location where the data lives is the PostgreSQL data directory:

```
/opt/homebrew/var/postgresql@18
```

## Size of Each Folder in the Data Directory

Command: `du -sh /opt/homebrew/var/postgresql@18/*`

| Folder / File | Size | Explanation |
| --- | --- | --- |
| `base` | **7.0G** | The actual database data lives here. Each database is a subdirectory under `base`; `large_table` (7079 MB) is stored here. |
| `pg_wal` | **1.0G** | Write-ahead log (WAL). Records all changes before they are committed, used for crash recovery and replication. |
| `global` | **552K** | System-wide catalog data shared across all databases (roles, databases, shared relations). |
| `postgresql.conf` | 32K | Main server configuration file. |
| `pg_multixact` | 16K | Multi-transaction status data (for shared row locks / multixact IDs). |
| `pg_hba.conf` | 8K | Client authentication (host-based auth) configuration. |
| `pg_subtrans` | 8K | Sub-transaction status data. |
| `pg_xact` | 8K | Transaction commit status data. |
| `pg_ident.conf` | 4K | Identity mapping for authentication. |
| `pg_logical` | 4K | Logical decoding (replication) state. |
| `PG_VERSION` | 4K | Version marker file. |
| `postgresql.auto.conf` | 4K | Auto-generated config overrides. |
| `postmaster.opts` | 4K | Command-line options of the running postmaster. |
| `postmaster.pid` | 4K | Postmaster process info / lock file. |
| `pg_commit_ts` | 0B | Commit timestamps (empty). |
| `pg_dynshmem` | 0B | Dynamic shared memory (empty). |
| `pg_notify` | 0B | LISTEN/NOTIFY state (empty). |
| `pg_replslot` | 0B | Replication slots (empty). |
| `pg_serial` | 0B | Serialized transaction state (empty). |
| `pg_snapshots` | 0B | Snapshot state (empty). |
| `pg_stat` | 0B | Statistics data (empty). |
| `pg_stat_tmp` | 0B | Temporary statistics (empty). |
| `pg_tblspc` | 0B | Tablespace mappings (empty). |
| `pg_twophase` | 0B | Two-phase commit state (empty). |

## Key Takeaways

- The ~7.1 GB database storage is physically in the `base` subdirectory.
- `pg_wal` holds 1.0G of write-ahead log.
- `large_table` is the dominant table, using 7079 MB of the 7087 MB database.