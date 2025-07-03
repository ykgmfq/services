#!/usr/bin/fish
function abort
    buildah rm $argv
    exit 1
end
set tag (basename (pwd))
set alpine 3.22
echo "Alpine | $alpine"
echo "Tag    | $tag"
set ctr (buildah from --pull docker.io/alpine:$alpine)
and buildah config \
--port 8096 \
--env JELLYFIN_WEB_DIR=/usr/share/webapps/jellyfin-web \
--env JELLYFIN_FFMPEG=/usr/lib/jellyfin-ffmpeg/ffmpeg \
--env MALLOC_TRIM_THRESHOLD=131072 \
--cmd /usr/bin/jellyfin \
$ctr
and buildah run $ctr /sbin/apk add --no-progress --no-cache jellyfin-web curl
and buildah commit --rm $ctr $tag
or abort $ctr
