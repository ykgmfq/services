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

## Services

| Service | Quadlet | Images | Notes |
|---|---|---|---|
| Nextcloud | cloud.kube + cloud.yml | cloud (php-fpm + Caddy + baked Nextcloud) + postgres, valkey, imaginary | Multi-container pod |
| Paperless | docs.kube + docs.yml | docs + postgres, valkey | Multi-container pod |
| Immich | immich.kube + immich.yml | upstream + postgres, valkey | Multi-container pod |
| Vaultwarden | vault.kube + vault.yml | upstream | SQLite backend |
| Ingress | ingress.container | ingress (Caddy) | Host networking, TLS |
| Mosquitto | mosquitto.container | mosquitto | MQTT on 127.0.0.1:1883-1884 |
| Samba | samba.container | samba | File sharing, runtime file secret `samba_passwords` |
| Jellyfin | media.container | media | Media server |
| FreshRSS | freshrss.container | freshrss | RSS reader |
| Node-RED | nodered.container | nodered | Automation |
| Ollama | ollama.container | upstream | LLM inference |
| Home | home.container | upstream | Home Assistant |
| Audiobookshelf | audiobookshelf.container | upstream (Nix) | Audiobooks/podcasts |
| Avahi | avahi.container | avahi | mDNS discovery |
| Forgejo | forgejo.container | upstream | Git service, SQLite |
| mail2task | mail2task.container | upstream (ghcr) | IMAP→Ollama→Todoist worker, no web UI |

## Database Management

### PostgreSQL

PostgreSQL is used by cloud, docs, and immich.
The password is `a`, which is safe because the database is only reachable on the internal pod network.
Data lives in `/var/mnt/persist/<service>/db`.

A major-version upgrade is run with `fish update-pg.fish <service> <target-major>`.
It creates the ZFS snapshot `data/persist/<service>/db@pre-pg-upgrade` so the upgrade can be rolled back.
It dumps from the old major, clears the data directory, and restores into the new major.
PostgreSQL 18 and later use the `/var/lib/postgresql/<major>/docker` layout.

### SQLite (Vault)

Vaultwarden uses SQLite at `/var/mnt/persist/vault/db.sqlite3`.
The migration from PostgreSQL is handled by `deploy-vault-sqlite.fish` together with `pg2sqlite.py`.

## Secret Management

Sensitive values are podman secrets created from Kubernetes Secret YAMLs.
The secrets live as `metadata.name` plus `stringData` in `/var/mnt/persist/secret-<name>.yml`.
`/usr/local/bin/plain-secret.py <file>` extracts the first `stringData` value and creates a plain podman secret named `<metadata.name>_plain`, using `podman secret create --replace`; the `--suffix` flag overrides the default `_plain`.
The `.container` quadlets inject these with `Secret=<name>_plain,type=env,target=<ENV_VAR>`, for example `ingress` injecting `ollama_api_key_plain`, and `mail2task` injecting `strato_verwaltung_plain` and `todoist_api_plain`.
Name secrets by account or credential so that they can be reused across services, rather than prefixing them with a service name.

A secret can also be mounted as a file rather than injected as an environment variable: `Secret=<name>,mode=0400` surfaces it inside the container at `/run/secrets/<name>`.
Such a file secret holds a whole file (for example a multi-line password map), so the YAML keeps that whole file as a single multi-line `stringData` block scalar, and `plain-secret.py --suffix '' <file>` creates the bare-named secret from it.
`samba` mounts `samba_passwords` this way: `/var/mnt/persist/secret-samba-passwords.yml` carries `<user>=<password>` lines that its entrypoint iterates over to build the user database at startup.
`mosquitto` mounts `mosquitto_passwords` similarly, though its secret is created directly from a password file with `podman secret create` rather than through a YAML.

## Pod runtime conventions

Every pod sets `automountServiceAccountToken: false` for security.
Database passwords are `a` because the services are never exposed externally and are only reached through the Caddy reverse proxy.
Caddy strips the `x-powered-by` and `server` headers and adds HSTS and other security headers.
