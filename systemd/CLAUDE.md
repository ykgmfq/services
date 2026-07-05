# Deployment Concerns

This directory holds the Podman Quadlet files that define how services run on the host.
They are deployed to `/etc/containers/systemd/`, where the Podman Quadlet generator turns them into systemd units.

## Quadlet types

Single-container services use a `*.container` quadlet.
Multi-container services use a `*.kube` quadlet that references a Kubernetes Pod v1 YAML file (`*.yml`).

## Sync & Deploy Workflow

```fish
fish sync.fish               # rclone systemd/ → /etc/containers/systemd/ (excludes *.md), validate, daemon-reload
systemctl isolate multi-user # stop all prod services cleanly
systemctl start prod.target  # start all prod services with new config
```

`sync.fish` excludes markdown files, so this `CLAUDE.md` is never copied into `/etc/containers/systemd/`.
You can also use the VS Code tasks "sync services", "daemon", "isolate multi-user", and "start target".

## Storage paths (on host)

| Path | Purpose | Backed up |
|---|---|---|
| `/var/mnt/persist/<service>/` | Persistent app data, databases | Yes (ZFS snapshots) |
| `/var/mnt/persist/<service>/db/` | PostgreSQL data dirs | Yes |
| `/var/mnt/ephemeral/` | Caches, downloads, this repo | No |
| Podman PVCs | Ephemeral managed volumes | No |


## Database Management

### PostgreSQL

PostgreSQL is used by cloud, docs, and immich.
The password is `a`, which is safe because the database is only reachable on the internal pod network.
Data lives in `/var/mnt/persist/<service>/db`.

Major-version upgrades use `fish update-pg.fish <service> <target-major>`.
PostgreSQL 18 and later use the `/var/lib/postgresql/<major>/docker` layout.

### SQLite (Vault)

Vaultwarden uses SQLite at `/var/mnt/persist/vault/db.sqlite3`.

## Secret Management

Sensitive values are podman secrets.
All secrets live under `/var/mnt/persist/secrets/`, in one of two formats:

- **`<name>.yml`** (Kubernetes Secret YAML) — for single values injected as environment variables or referenced via `secretKeyRef`.
  `/usr/local/bin/plain-secret.py <file>` extracts the first `stringData` value and creates a podman secret named `<metadata.name>_plain`, using `podman secret create --replace`; the `--suffix` flag overrides the default `_plain`.
  The `.container` quadlets inject these with `Secret=<name>_plain,type=env,target=<ENV_VAR>`.
- **`<name>.txt`** (plain text file) — for secrets that a service or the kernel reads directly as a file at runtime.
  These are registered with `podman secret create --replace <name> <file>`, using the bare name (no `_plain` suffix).
  `dyndns-password.txt` is loaded as a systemd credential via `LoadCredential` in `dyndns.service`.

Name secrets by account or credential so that they can be reused across services, rather than prefixing them with a service name.

A file-mounted podman secret surfaces inside the container at `/run/secrets/<name>` via `Secret=<name>,mode=0400`.

## Pod runtime conventions

Every pod sets `automountServiceAccountToken: false`.
Database passwords are `a` because the services are never exposed externally and are only reached through the Caddy reverse proxy.
