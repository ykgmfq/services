#!/usr/bin/fish
function abort
    buildah rm $argv
    exit 1
end
set tag (basename (pwd))
set ctr (buildah from --pull docker.io/library/caddy:2)
and buildah copy $ctr caddy /etc/caddy
and buildah commit --rm $ctr $tag
or abort $ctr
