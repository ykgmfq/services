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
ContainerName=<service>
Network=<service>.network
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
- `ContainerName=<service>` — explicit name for DNS resolution on the network
- `Network=<service>.network` — per-service Podman network (see Networking below)
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
Network=<service>.network

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
- Only `containerPort` needed — no `hostPort`/`hostIP` (Caddy reaches pods via the shared network using the pod name as DNS)
- `hostPath` volumes for persistent data under `/var/mnt/persist/<service>/`
- `persistentVolumeClaim` for ephemeral managed volumes

## Networking

Each web-facing service has a dedicated Podman network (`<service>.network` quadlet file).
Caddy (ingress) joins every service network to reach backends by DNS name.

### .network Files

Minimal — one per service in `systemd/`:
```ini
[Network]
```
Podman auto-assigns subnets. Aardvark-dns provides container DNS resolution.

### How Caddy reaches services

| Service type | Network | Caddy `reverse_proxy` target |
|---|---|---|
| .container with network | `<service>.network` | `<containerName>:<containerPort>` |
| .kube pod with network | `<service>.network` | `<pod-metadata-name>:<containerPort>` |
| Host-networked (.container with `Network=host`) | none | `host.containers.internal:<port>` |

### Ingress container

Caddy publishes ports 80 and 443, and joins all service networks:
```ini
[Container]
PublishPort=443:443
PublishPort=80:80
Network=cloud.network
Network=docs.network
# ... one Network= line per service
```

### Exceptions

- **Home Assistant, Node-RED, Avahi** — `Network=host` (need host device access / mDNS). Caddy reaches them via `host.containers.internal:<port>`.
- **Samba** — `PublishPort=445:445` on all interfaces (SMB, not proxied by Caddy).
- **Mosquitto** — joins `mosquitto.network` for Caddy WebSocket proxy, plus `PublishPort=127.0.0.1:1883:1883` so host-networked services (Home/NodeRED) can reach MQTT via localhost.

## Port Binding

- Services on custom networks do not publish ports — Caddy reaches them via the network
- Host-networked services bind on all interfaces (managed by the application)
- Exception: samba (port 445) and mosquitto (loopback 1883/1884) still use `PublishPort`

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
