# Service definitions
Self-hosted services running as Podman Quadlets on a single Fedora host. Domain: `dm-poepperl.de`.

For agent/contributor context see [CLAUDE.md](CLAUDE.md).
For host system setup see https://github.com/ykgmfq/ansible.

## Layout
- `images/<service>/` — Buildah image build scripts
- `systemd/` — Quadlet files (deployed via confext, see CLAUDE.md)

## Quick start
```fish
fish sync.fish               # deploy quadlets via confext + daemon-reload
systemctl start prod.target  # start all services
```
