# Agent Instructions

Homelab infrastructure project managing containerized services on a single host via **Podman Quadlets** and **systemd**. Domain: `dm-poepperl.de`.

## Toolchain

- **Shell**: Fish exclusively — use `and`/`or` chaining, not `&&`/`||`
- **Containers**: Podman (rootless) + Buildah (rootless image builds)
- **Orchestration**: systemd with Podman Quadlet generators
- **Reverse proxy**: Caddy (ingress service, host networking)
- **Databases**: PostgreSQL (pods), SQLite (vault)
- **Storage**: ZFS (`data/persist/*`, `data/media`)
- **Sync**: `rclone sync systemd /etc/containers/systemd` then `systemctl daemon-reload`

## Directory Layout

```
images/<service>/          Build context — each has a build.fish
  build.fish               Buildah recipe (fish shell)
  src/                     Files copied into image (install.sh, Caddyfile, configs)
    units/                 Systemd units that run inside the container
systemd/                   Quadlet files deployed to /etc/containers/systemd/
  *.container              Single-container quadlets
  *.kube + *.yml           Multi-container pod quadlets (Kubernetes Pod v1 YAML)
```

### Storage paths (on host)

| Path | Purpose | Backed up |
|---|---|---|
| `/var/mnt/persist/<service>/` | Persistent app data, databases | Yes (ZFS snapshots) |
| `/var/mnt/persist/<service>/db/` | PostgreSQL data dirs | Yes |
| `/var/mnt/ephemeral/` | Caches, downloads, this repo | No |
| Podman PVCs | Ephemeral managed volumes | No |

## Sync & Deploy Workflow

```fish
fish sync.fish              # rclone sync systemd/ → /etc/containers/systemd/, validates with podman generator dry-run, daemon-reload
systemctl daemon-reload     # already done by sync.fish
systemctl isolate multi-user  # stop all prod services cleanly
systemctl start prod.target   # start all prod services with new config
```

Or use VS Code tasks: "build <service>", "restart <service>", "sync services", "daemon", "start target".

## Database Management

### PostgreSQL

Used by: cloud, docs, immich. Password: `a` (internal pod network only). Data in `/var/mnt/persist/<service>/db`.

**Major version upgrade**: `fish update-pg.fish <service> <target-major>`
- Creates ZFS snapshot `data/persist/<service>/db@pre-pg-upgrade` for rollback
- Dumps from old major, clears datadir, restores into new major
- PostgreSQL 18+ uses `/var/lib/postgresql/<major>/docker` layout

### SQLite (Vault)

Vaultwarden uses SQLite at `/var/mnt/persist/vault/db.sqlite3`. Migration from PostgreSQL via `deploy-vault-sqlite.fish` + `pg2sqlite.py`.

## Services

| Service | Quadlet | Images | Notes |
|---|---|---|---|
| Nextcloud | cloud.kube + cloud.yml | cloud, cloud-web + postgres, valkey, imaginary | Multi-container pod |
| Paperless | docs.kube + docs.yml | docs + postgres, valkey | Multi-container pod |
| Immich | immich.kube + immich.yml | upstream + postgres, valkey | Multi-container pod |
| Vaultwarden | vault.kube + vault.yml | upstream | SQLite backend |
| Ingress | ingress.container | ingress (Caddy) | Host networking, TLS |
| Mosquitto | mosquitto.container | mosquitto | MQTT on 127.0.0.1:1883-1884 |
| Samba | samba.container | samba | File sharing, needs credentials |
| Jellyfin | media.container | media | Media server |
| FreshRSS | freshrss.container | freshrss | RSS reader |
| Node-RED | nodered.container | nodered | Automation |
| Ollama | ollama.container | upstream | LLM inference |
| Home | home.container | upstream | Home Assistant |
| Audiobookshelf | audiobookshelf.container | upstream (Nix) | Audiobooks/podcasts |
| Avahi | avahi.container | avahi | mDNS discovery |

## Conventions

- Service name = directory name = image tag = systemd unit name
- Fish shell for all scripts — no bash
- Buildah for image construction — no Dockerfile
- Security: `automountServiceAccountToken: false` in all pods
- DB passwords are `a` — services are not exposed externally, only via Caddy reverse proxy
- UIDs are per-service (832=cloud, 844=vault, 879=scan/docs, 997=media, 1883=mosquitto)
- Caddy strips `x-powered-by` and `server` headers, adds HSTS and security headers