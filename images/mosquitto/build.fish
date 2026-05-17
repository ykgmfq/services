#!/usr/bin/fish
function abort
    buildah rm $argv
    exit 1
end
set tag (basename (pwd))
set alpine 3
set ctr (buildah from --pull docker.io/library/alpine:$alpine)
and buildah run $ctr /sbin/apk add --no-progress --no-cache mosquitto mosquitto-clients
and buildah copy $ctr mosquitto.conf /etc/mosquitto/mosquitto.conf
and buildah config --user 1883:1883 --cmd '["mosquitto", "-c", "/etc/mosquitto/mosquitto.conf"]' $ctr
and buildah commit --rm $ctr $tag
or abort $ctr
