#!/usr/bin/fish
# https://regex101.com/r/xvHsoU/1
function abort
    buildah rm $argv
    exit 1
end
set tag (basename (pwd))
set branch 4.0
set ws 0.74
set sun 2.1
set ctr (buildah from --pull docker.io/nodered/node-red:$branch)
and buildah run $ctr npm install node-red-contrib-{sun-position@$sun.x,home-assistant-websocket@$ws.x,timed-counter,spline-curve} passport-openidconnect
and buildah commit --rm $ctr $tag
or abort $ctr
