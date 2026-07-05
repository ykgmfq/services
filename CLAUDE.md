# Agent Instructions

This is a homelab infrastructure project that manages containerized services on a single host via Podman Quadlets and systemd.
The domain is `dm-poepperl.de`.

This file is the overview.
Image build details live in [images/CLAUDE.md](images/CLAUDE.md).
Deployment, database, and secret details live in [systemd/CLAUDE.md](systemd/CLAUDE.md).

## Toolchain

- **Shell**: Fish exclusively — use `and`/`or` chaining, not `&&`/`||`
- **Containers**: Podman (rootless) + Buildah (rootless image builds)
- **Orchestration**: systemd with Podman Quadlet generators
- **Reverse proxy**: Caddy (ingress service, host networking)
- **Databases**: PostgreSQL (pods), SQLite (vault)
- **Storage**: ZFS (`data/persist/*`, `data/media`)
- **Sync**: `fish sync.fish` — rclone `systemd/` → `/etc/containers/systemd/` (excludes `*.md`), podman generator dry-run, `daemon-reload`

## Directory Layout

```
images/     Build contexts, one per locally built service — see images/CLAUDE.md
systemd/    Quadlet files deployed to /etc/containers/systemd/ — see systemd/CLAUDE.md
sync.fish   Deploy script: rclone systemd/ → /etc/containers/systemd/, validate, daemon-reload
```

## Conventions

- Service name = directory name = image tag = systemd unit name
- Fish shell for all scripts — no bash
- Buildah for image construction — no Dockerfile
- Human-facing text — markdown, comments, log messages, and commit messages — uses proper prose: full sentences, plain words, no terse shorthand
- Documentation describes only the current state of the project; historical notes and migration stories belong in the git log, not in CLAUDE.md files
- CLAUDE.md files facilitate discovery of the codebase — where things live, why the structure exists, non-obvious constraints — not restatement of implementation details that are plain from reading the code
- Every line of documentation has a maintenance cost; when in doubt, omit it
- In markdown, each sentence starts on its own line, so a one-sentence change touches only one line in the diff
- The README is an abstract that answers "what is this and why does it exist?"; configuration, installation, and usage belong in the GitHub wiki. When wiki content needs updating, write it into the uncommitted `wiki.md` at the repo root
- In GitHub Actions, longer `run:` blocks live in `.github/scripts/` and are referenced from the step; one-liners stay inline
- Shell scripts avoid backslash line continuations; use intermediate variables instead
