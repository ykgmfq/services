# Service definitions
Here live definitions for self-hosted services.

## Services
| Service      | Depolyment                  |
|--------------|-----------------------------|
| Nextcloud    | Fedora base, php-fpm, caddy |
| Vaultwarden  | Upstream image              |
| Freshrss     | Fedora base, php-fpm, caddy |
| Caddy        | Upstream image              |
| Jellyfin     | Alpine base and package     |
| Paperlessngx | Upstream image              |
| Samba        | Alpine base and package     |
| Avahi        | Alpine base and package     |
| Nodered      | Upstream image              |
| Ollama       | Upstream image              |

## The `images` directory
The `images` directory contains build instructions for the service container files.
In each subdirectory, the respective image can be built by calling `build.fish`.

## The `systemd` directory
The `systemd` directory contains *quadlets* for service deployment and must be symlinked to `/etc/containers/systemd/`.
See the quadlet [documentation](https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html) for more information.
