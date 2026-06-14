#!/usr/bin/fish
function abort
    buildah rm $argv
    exit 1
end
set tag (basename (pwd))
set alpine 3.23
echo "Alpine | $alpine"
echo "Tag    | $tag"
set config --port 8096
set --append config --env JELLYFIN_WEB_DIR=/usr/share/webapps/jellyfin-web
set --append config --env JELLYFIN_FFMPEG=/usr/lib/jellyfin-ffmpeg/ffmpeg
set --append config --env MALLOC_TRIM_THRESHOLD=131072
set --append config --cmd /usr/bin/jellyfin
set ctr (buildah from --pull docker.io/alpine:$alpine)
and buildah config $config $ctr
and buildah run $ctr /sbin/apk add --no-progress --no-cache jellyfin-web curl
and buildah commit --rm $ctr $tag
or abort $ctr
