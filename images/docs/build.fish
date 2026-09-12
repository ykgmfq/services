#!/usr/bin/fish
# https://regex101.com/r/xvHsoU/1
function abort
    buildah rm $argv
    exit 1
end
set tag (basename (pwd))
set USERMAP_UID 879
set USERMAP_GID $USERMAP_UID
set PAPERLESS_LOGGING_DIR /tmp/log
set PAPERLESS_PRE_CONSUME_SCRIPT /usr/src/paperless/scripts/removepassword.py
set config --env USERMAP_UID=$USERMAP_UID
set --append config --env USERMAP_GID=$USERMAP_GID
set --append config --env PAPERLESS_LOGGING_DIR=$PAPERLESS_LOGGING_DIR
set --append config --env PAPERLESS_PRE_CONSUME_SCRIPT=$PAPERLESS_PRE_CONSUME_SCRIPT
set url ghcr.io/paperless-ngx/paperless-ngx
set tags (podman search --list-tags --format "{{.Tag}}" --limit=300 $url)
set major (string collect $tags | grep --perl-regexp '^\d+.\d+$' | sort --version-sort | tail --lines 2)
if contains "$major[2].1" $tags
	set branch $major[2]
else
	set branch $major[1]
end
echo "User ID | $USERMAP_UID"
echo "Branch  | $branch"
set ctr (buildah from --pull $url:$branch)
and buildah add $ctr install.sh /tmp/install.sh
and buildah run $ctr bash /tmp/install.sh $PAPERLESS_LOGGING_DIR $PAPERLESS_PRE_CONSUME_SCRIPT
and buildah config $config $ctr
and buildah commit --rm $ctr $tag
or abort $ctr
