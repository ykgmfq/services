#!/usr/bin/fish
function abort
    buildah rm $argv
    exit 1
end
set tag (basename (pwd))
set alpine 3
set ctr (buildah from --pull docker.io/library/alpine:$alpine)
set install (cat install.sh | string collect)
and buildah run $ctr sh -c $install
and buildah copy $ctr samba.service /etc/avahi/services
and buildah config --cmd avahi-daemon $ctr
and buildah commit --rm $ctr $tag
or abort $ctr
