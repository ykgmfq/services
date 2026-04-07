---
description: "Use when writing or editing build.fish scripts, buildah image builds, or fish shell scripts in this project. Covers buildah patterns, fish syntax, error handling, and image tagging conventions."
applyTo: "**/*.fish"
---
# Fish + Buildah Conventions

## Fish Shell
- Use `and`/`or` for chaining — never `&&`/`||`
- Use `set --query VAR` to test if a variable is set
- Use `set -q argv[1]` to test for arguments
- Use `(basename (pwd))` for current directory name
- Use `string collect` to capture multiline output into a single variable
- Use `string trim` to strip whitespace
- Use `string match -qr` for regex matching
- Quote variables: `"$var"` not `$var`

## build.fish Structure

Every image build script must follow this exact pattern:

```fish
#!/usr/bin/fish
function abort
    buildah rm $argv
    exit 1
end
set tag (basename (pwd))
set ctr (buildah from --pull <base-image>)
and buildah copy $ctr <src> <dest>
and buildah run $ctr <command>
and buildah config --cmd <cmd> $ctr
and buildah commit --rm $ctr $tag
or abort $ctr
```

Rules:
- `set tag (basename (pwd))` — image tag = directory name, always
- Every `buildah` step must be chained with `and`
- Always end with `or abort $ctr` for cleanup
- Use `--rm` on `buildah commit` to remove the working container
- Use `--pull` on `buildah from` to get fresh base images
- If building multiple images (e.g. cloud), build each sequentially with its own `$ctr`

## Credentials Pattern

For builds needing secrets:
```fish
if set --query CREDENTIALS_DIRECTORY
    source $CREDENTIALS_DIRECTORY/secrets
else if not set -q argv[1]
    echo Please provide credentials.
    exit 2
else
    source $argv
end
```

## Common Base Images

| Use Case | Image |
|---|---|
| PHP apps | `quay.io/fedora/fedora-minimal:43` |
| Lightweight | `docker.io/library/alpine:3` |
| Web proxy | `docker.io/library/caddy:2` |
| MQTT | `docker.io/library/eclipse-mosquitto:2` |
