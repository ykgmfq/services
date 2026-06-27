#!/usr/bin/fish
function abort
    buildah rm $argv
    exit 1
end
set tag (basename (pwd))
set uid 832
set fedora 44
echo "Base Image | $fedora"
echo "Tag        | $tag"
echo "User ID    | $uid"
# Resolve and stage the Nextcloud tree (server + pinned apps) on the build host.
set stage (mktemp -d)
fish ./src/nextcloud.fish $stage
or begin
    rm -rf $stage
    exit 1
end
# Single image: Fedora php-fpm + Caddy + the baked, read-only Nextcloud tree.
echo Image
set ctr (buildah from --pull quay.io/fedora/fedora-minimal:$fedora)
and buildah copy $ctr ./src tmp
and buildah config --cmd /sbin/init $ctr
and buildah run $ctr bash /tmp/install.sh $uid
and buildah copy --chown root:root $ctr $stage /usr/share/nextcloud
and buildah commit --rm $ctr $tag
or begin
    rm -rf $stage
    abort $ctr
end
rm -rf $stage
