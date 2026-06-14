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

Every `build.fish` is a fish script that drives Buildah, and the scripts share a common shape.
They define an `abort` function that removes the working container and exits non-zero.
They derive the tag from the directory name with `set tag (basename (pwd))`.
They start a container with `set ctr (buildah from --pull <base>)`, then chain the build steps with `and` so any failure short-circuits to `or abort $ctr`.
They finish with `buildah commit --rm $ctr $tag`.

Multi-image services commit several tags from one script.
For example, `cloud/build.fish` builds both `cloud-web` (Caddy front end) and `cloud` (Fedora php-fpm).

## Build-time credentials

Some images need secrets at build time, which are read from `$CREDENTIALS_DIRECTORY`.
`samba/build.fish` sources `$CREDENTIALS_DIRECTORY/secrets` when present, and otherwise falls back to a credentials path passed as the first argument.
This keeps passwords out of the image history and the repository.

## Per-service UIDs

User IDs are fixed per service so that file ownership stays stable across rebuilds and on the host bind mounts.
The current assignments are 832 for cloud, 844 for vault, 879 for scan/docs, 997 for media, and 1883 for mosquitto.

## Locally built versus upstream

Built here: avahi, cloud, docs, freshrss, ingress, media, mosquitto, nodered, samba.
Pulled upstream instead of built here: immich, vaultwarden, ollama, home (Home Assistant), audiobookshelf, forgejo, mail2task.

## Conventions

Image construction uses Buildah, never a Dockerfile.
All build scripts are fish, never bash.
Avoid backslash line continuations in the recipes; collect multi-flag invocations such as `buildah config` into a fish list variable and expand it, as in `set config --port 8096 --cmd /usr/bin/jellyfin` followed by `buildah config $config $ctr`.
