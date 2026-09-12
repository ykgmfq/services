#!/usr/bin/fish
function abort
    buildah rm $argv
    exit 1
end
set tag (basename (pwd))
set uid 800
set fedora 44
echo "Base Image | $fedora"
echo "Tag        | $tag"
echo "User ID    | $uid"
set stage (mktemp -d)
curl -sL (curl -s https://api.github.com/repos/FreshRSS/FreshRSS/releases/latest | jq -r '.tarball_url') -o $stage/FreshRSS.tar.gz
and set ctr (buildah from --pull quay.io/fedora/fedora-minimal:$fedora)
and buildah add $ctr $stage/FreshRSS.tar.gz /srv/
and buildah copy $ctr ./src tmp
and buildah config --cmd /sbin/init $ctr
and buildah run $ctr bash /tmp/install.sh $uid
and buildah commit --rm $ctr $tag
or begin
    rm -r $stage
    abort $ctr
end
rm -r $stage
