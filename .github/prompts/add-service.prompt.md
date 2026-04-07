---
description: "Scaffold a new homelab service: build.fish, quadlet file, and Caddy site config"
argument-hint: "service name and base image type (alpine, fedora, upstream)"
agent: "agent"
---
Add a new service to the homelab. Create all required files following project conventions:

1. **`images/<service>/build.fish`** — Buildah build script using the `abort` pattern, `set tag (basename (pwd))`, `and`/`or` chaining
2. **`systemd/<service>.container`** (single container) or **`.kube` + `.yml`** (if it needs a database/redis) — with health check, slice, prod.target
3. **`images/ingress/caddy/sites/de.dm-poepperl.<subdomain>`** — reverse proxy site pointing to the service's hostPort

Use these conventions:
- Image tag = directory name = service name
- Bind hostPort to `127.0.0.1` only
- Include `HealthCmd` or `livenessProbe`
- Use `prod-tier0.slice` for critical, `prod-tier1.slice` for best-effort
- Add `automountServiceAccountToken: false` to any pod YAML
- Pick a unique UID for the new service (check AGENTS.md for used UIDs)
