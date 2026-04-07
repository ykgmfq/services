---
description: "Perform database operations: PostgreSQL major upgrades, backup/restore, SQLite migration, or database troubleshooting"
argument-hint: "operation and service name, e.g. 'upgrade cloud to pg18' or 'check docs db health'"
agent: "agent"
---
Help with database operations for homelab services.

## Available Operations

### PostgreSQL Major Upgrade
Run `fish update-pg.fish <service> <target-major>` — this:
- Stops the service
- Creates a ZFS snapshot `data/persist/<service>/db@pre-pg-upgrade`
- Dumps from old major, clears datadir, restores into new major
- PostgreSQL 18+ mounts at `/var/lib/postgresql` (PGDATA=`/var/lib/postgresql/<major>/docker`)
- Pre-18 mounts at `/var/lib/postgresql/data`
- Rollback: `zfs rollback data/persist/<service>/db@pre-pg-upgrade`

### SQLite Migration (Vault)
Run `fish deploy-vault-sqlite.fish` to convert a PostgreSQL backup to SQLite for Vaultwarden.

### Diagnostics
- Check DB health: `podman exec <pod>-db pg_isready -U postgres`
- Connect: `podman exec -it <pod>-db psql -U postgres`
- Check PG version: `cat /var/mnt/persist/<service>/db/PG_VERSION`

Services with PostgreSQL: cloud, docs, immich. Vault uses SQLite at `/var/mnt/persist/vault/db.sqlite3`.
