#!/usr/bin/fish
function abort
    buildah rm $argv
    exit 1
end
set tag (basename (pwd))
set alpine 3
set idmedia 997
set idscan 879
set install (cat src/install.sh | string collect)
set config --port 445
set --append config --cmd 'sh /opt/entrypoint.sh'
set ctr (buildah from --pull docker.io/library/alpine:$alpine)
and buildah run --env idscan=$idscan --env idmedia=$idmedia $ctr sh -c $install
and buildah copy $ctr src/smb.conf /etc/samba/
and buildah copy $ctr src/entrypoint.sh /opt/entrypoint.sh
and buildah copy $ctr src/monitor /opt/monitor
and buildah config $config $ctr
and buildah commit --rm $ctr $tag
or abort $ctr
