#!/usr/bin/fish
function abort
    buildah rm $argv
    exit 1
end
set tag (basename (pwd))
set uid 832
set fedora 42
set caddy 2
echo "Base Image | $fedora"
echo "Tag        | $tag"
echo "User ID    | $uid"
# Web server
echo Web
set ctr (buildah from --pull docker.io/library/caddy:$caddy)
and buildah copy $ctr ./src/Caddyfile /etc/caddy/
and buildah run $ctr apk add --no-cache curl
and buildah commit --rm $ctr $tag-web
or abort $ctr
# PHP
echo PHP
set ctr (buildah from --pull quay.io/fedora/fedora-minimal:$fedora)
and buildah copy $ctr ./src tmp
and buildah config --cmd /sbin/init $ctr
and buildah run $ctr bash /tmp/install.sh $uid
and buildah commit --rm $ctr $tag
or abort $ctr
