#!/usr/bin/fish
# https://regex101.com/r/xvHsoU/1
function abort
    buildah rm $argv
    exit 1
end
set tag (basename (pwd))
set -x USERMAP_UID 879
set -x USERMAP_GID $USERMAP_UID
set -x PAPERLESS_LOGGING_DIR /tmp/log
set url ghcr.io/paperless-ngx/paperless-ngx
#set branch (podman search --list-tags --format "{{.Tag}}" --limit=300 $url | grep -P '^\d+.\d+$' | sort -V | tail -n 2 | head -1)
set branch 2.11
echo User ID for scan: $USERMAP_UID
echo Branch: $branch
set ctr (buildah from --pull $url:$branch)
and buildah run $ctr mkdir --mode='ugo=rwx' $PAPERLESS_LOGGING_DIR
for e in USERMAP_{G,U}ID PAPERLESS_LOGGING_DIR
    and buildah config --env=$e $ctr
end
and buildah commit --rm $ctr $tag
or abort $ctr
