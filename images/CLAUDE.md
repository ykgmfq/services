# Image Build Concerns

This directory holds one build context per service that is built locally rather than pulled from a registry.
Each subdirectory is named after its service, and that name is also the resulting image tag.

## Layout

```
<service>/
  build.fish     Buildah recipe (fish shell)
  src/           Files copied into the image (install.sh, Caddyfile, configs)
    units/       Systemd units that run inside the container
```

## The build.fish recipe pattern

Every `build.fish` follows the same Buildah shape: derive tag from directory name, start a working container, chain steps with `and` / `or abort`, commit.
A `build.fish` may commit several tags if a service needs more than one image.
The `cloud` recipe pins a Nextcloud major version resolved at build time by `cloud/src/nextcloud.fish`.

## Build-time credentials

No image needs secrets at build time; every build is reproducible and free of credential material.
`samba` receives its passwords at runtime through a podman file secret mounted at `/run/secrets/samba_passwords`, which its entrypoint reads to build the user database on a tmpfs.
`docs` receives `pdf_passwords.txt` at runtime through a `hostPath` volume mounted at `/usr/src/paperless/scripts/passwords.txt`.

## Per-service UIDs

User IDs are fixed per service so that file ownership stays stable across rebuilds and on the host bind mounts.
The current assignments are 832 for cloud, 844 for vault, 879 for scan/docs, 997 for media, and 1883 for mosquitto.

## Conventions

Image construction uses Buildah, never a Dockerfile.
All build scripts are fish, never bash.
Avoid backslash line continuations in the recipes; collect multi-flag invocations into a fish list variable instead.
