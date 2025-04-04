#!/usr/bin/fish
function abort
    buildah rm $argv
    exit 1
end
set tag (basename (pwd))
set branch 2
echo User ID for scan: $USERMAP_UID
echo Branch: $branch
set ctr (buildah from --pull docker.io/library/eclipse-mosquitto:$branch)
and buildah copy $ctr mosquitto.conf /mosquitto/config/mosquitto.conf
and buildah config --user 1883:1883 $ctr
and buildah commit --rm $ctr $tag
or abort $ctr
