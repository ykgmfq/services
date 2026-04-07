---
description: "Use when writing or editing Podman Quadlet files (.container, .kube), systemd unit configuration, or Kubernetes Pod YAML (.yml) for service deployment."
applyTo: ["systemd/**"]
---
# Quadlet Deployment Conventions

## .container Files (single container)

```ini
[Unit]
Wants=image-bootstrap@%N.service image-build@%N.timer
After=image-bootstrap@%N.service

[Container]
Image=localhost/<service>
AutoUpdate=local
HealthCmd=<check command>
HealthOnFailure=kill

[Service]
Restart=on-failure
Slice=prod-tier0.slice

[Install]
WantedBy=prod.target
```

Required elements:
- `Wants` + `After` for image-bootstrap
- `image-build@%N.timer` in Wants for auto-rebuild
- `AutoUpdate=local` for locally-built images, `AutoUpdate=registry` for upstream
- A health check (`HealthCmd` or liveness probe) — every service must have one
- `HealthOnFailure=kill` for auto-restart
- `Slice=prod-tier0.slice` (critical) or `prod-tier1.slice` (best-effort)
- `WantedBy=prod.target`

## .kube + .yml Files (multi-container pod)

The `.kube` file is minimal:
```ini
[Unit]
Wants=image-bootstrap@%N.service image-build@%N.timer
After=image-bootstrap@%N.service

[Kube]
Yaml=/etc/containers/systemd/<service>.yml

[Service]
Restart=on-failure
Slice=prod-tier0.slice

[Install]
WantedBy=prod.target
```

The `.yml` is a Kubernetes Pod v1 spec:
- `automountServiceAccountToken: false` — always
- Each container gets a `livenessProbe` (HTTP, exec, or TCP)
- `periodSeconds: 300` for probes (5 min default)
- Containers in a pod share network — use `localhost:<port>` between siblings
- `hostPort` + `hostIP: 127.0.0.1` for ports exposed to the host (Caddy connects here)
- `hostPath` volumes for persistent data under `/var/mnt/persist/<service>/`
- `persistentVolumeClaim` for ephemeral managed volumes

## Port Binding

- Bind to `127.0.0.1` only — Caddy handles external traffic
- Exception: samba (port 445) binds to all interfaces

## Secrets

```ini
Secret=name,uid=X,gid=X,mode=0400       # File mount
Secret=name,type=env,target=VAR_NAME     # Environment variable
```

## PostgreSQL in Pods

```yaml
- image: docker.io/library/postgres:18-alpine
  name: db
  env:
    - name: POSTGRES_PASSWORD
      value: a
  volumeMounts:
    - mountPath: /var/lib/postgresql
      name: service-db-pvc
  livenessProbe:
    exec:
      command: [pg_isready, -U, postgres]
    periodSeconds: 300
```

Password is always `a` — internal pod network only.
