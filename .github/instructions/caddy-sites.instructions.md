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
  reverse_proxy localhost:<hostPort>
  import stdheader
  encode zstd gzip
}
```

Rules:
- Always `import stdheader` (HSTS, X-Frame-Options, CSP, etc.)
- Always `encode zstd gzip`
- `reverse_proxy` points to `localhost:<hostPort>` matching the container's hostPort
- Comment with Mozilla Observatory URL at top

## Header Snippets (defined in Caddyfile)

- `(baseheader)` — HSTS, strips `x-powered-by` and `server`
- `(stdheader)` — imports baseheader + X-Frame-Options, Referrer-Policy, CSP, X-XSS-Protection, X-Content-Type-Options

## Available vs Enabled

- `sites/` — active, included via `import sites/*`
- `avail/` — available but not currently served (move to `sites/` to enable)
