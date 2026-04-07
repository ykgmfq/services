---
description: "Use when writing or editing Caddy reverse proxy configuration, virtual host site files, or TLS/header settings. Covers Caddyfile syntax and site naming."
applyTo: ["images/ingress/caddy/**"]
---
# Caddy Ingress Configuration

## Site Files

Each virtual host is a separate file in `images/ingress/caddy/sites/`.
File naming: reversed domain — e.g. `de.dm-poepperl.cloud` for `cloud.dm-poepperl.de`.

## Standard Site Template

```caddyfile
# Mozilla Observatory score
# https://observatory.mozilla.org/analyze/<subdomain>.dm-poepperl.de
<subdomain>.dm-poepperl.de {
  reverse_proxy <container-dns>:<containerPort>
  import stdheader
  encode zstd gzip
}
```

Rules:
- Always `import stdheader` (HSTS, X-Frame-Options, CSP, etc.)
- Always `encode zstd gzip`
- `reverse_proxy` points to the container DNS name and internal port — not localhost
- Comment with Mozilla Observatory URL at top

## Reverse Proxy Targets

Caddy runs on per-service Podman networks (not host networking). Backend targets depend on the service type:

| Service type | `reverse_proxy` target | Example |
|---|---|---|
| .container on custom network | `<containerName>:<port>` | `vault:8087` |
| .kube pod on custom network | `<pod-name>:<containerPort>` | `cloud-pod:80` |
| Host-networked service | `host.containers.internal:<port>` | `host.containers.internal:8123` |

Never use `localhost:<port>` — Caddy is not on the host network.

## Header Snippets (defined in Caddyfile)

- `(baseheader)` — HSTS, strips `x-powered-by` and `server`
- `(stdheader)` — imports baseheader + X-Frame-Options, Referrer-Policy, CSP, X-XSS-Protection, X-Content-Type-Options

## Available vs Enabled

- `sites/` — active, included via `import sites/*`
- `avail/` — available but not currently served (move to `sites/` to enable)
