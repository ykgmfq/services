#!/usr/bin/fish
# https://regex101.com/r/xvHsoU/1
# https://flows.nodered.org/node/node-red-contrib-home-assistant-websocket
# https://flows.nodered.org/node/node-red-contrib-sun-position
function abort
    buildah rm $argv
    exit 1
end
set tag (basename (pwd))
set node 24
set uid 1000
echo "Base Image | node:$node-alpine"
echo "Tag        | $tag"
echo "User ID    | $uid"
set runtime bash tzdata curl openssl ca-certificates
set install npm install --unsafe-perm --no-update-notifier --no-fund --omit=dev
set config --workingdir /usr/src/node-red --user $uid:0 --port 1880
set config $config --env NODE_PATH=/usr/src/node-red/node_modules:/data/node_modules
set config $config --env FLOWS=flows.json
set config $config --cmd '["/usr/src/node-red/node_modules/.bin/node-red", "--userDir", "/data"]'
set ctr (buildah from --pull docker.io/library/node:$node-alpine)
and buildah run $ctr apk add --no-progress --no-cache $runtime
and buildah run $ctr mkdir -p /usr/src/node-red /data
and buildah config --workingdir /usr/src/node-red $ctr
and buildah copy $ctr ./src/package.json /usr/src/node-red/package.json
and buildah run $ctr $install
and buildah run $ctr chown -R $uid:0 /data
and buildah config $config $ctr
and buildah commit --rm $ctr $tag
or abort $ctr
