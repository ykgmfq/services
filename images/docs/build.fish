#!/usr/bin/fish
# https://regex101.com/r/xvHsoU/1
function abort
    buildah rm $argv
    exit 1
end
set tag (basename (pwd))
set -x USERMAP_UID 879
set -x USERMAP_GID $USERMAP_UID
set -x PAPERLESS_LOGGING_DIR /tmp/log
set -x PAPERLESS_PRE_CONSUME_SCRIPT /usr/src/paperless/scripts/removepassword.py
set url ghcr.io/paperless-ngx/paperless-ngx
set tags (podman search --list-tags --format "{{.Tag}}" --limit=300 $url)
set major (string collect $tags | grep --perl-regexp '^\d+.\d+$' | sort --version-sort | tail --lines 2)
if contains "$major[2].1" $tags
	set branch $major[2]
else
	set branch $major[1]
end
echo User ID for scan: $USERMAP_UID
echo Branch: $branch
set ctr (buildah from --pull $url:$branch)
and buildah add $ctr install.sh /tmp/install.sh
and buildah run $ctr bash /tmp/install.sh $PAPERLESS_LOGGING_DIR $PAPERLESS_PRE_CONSUME_SCRIPT
and buildah add $ctr passwords.txt /usr/src/paperless/scripts/passwords.txt
for e in USERMAP_{G,U}ID PAPERLESS_LOGGING_DIR PAPERLESS_PRE_CONSUME_SCRIPT
    and buildah config --env=$e $ctr
end
and buildah commit --rm $ctr $tag
or abort $ctr
