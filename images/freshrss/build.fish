#!/usr/bin/fish
function abort
    buildah rm $argv
    exit 1
end
set tag (basename (pwd))
set uid 800
set fedora 40
echo "Base Image | $fedora"
echo "Tag        | $tag"
echo "User ID    | $uid"
wget --quiet -O /srv/FreshRSS.tar.gz (curl -s https://api.github.com/repos/FreshRSS/FreshRSS/releases/latest | jq -r ".tarball_url")
and set ctr (buildah from --pull quay.io/fedora/fedora-minimal:$fedora)
and buildah add $ctr /srv/FreshRSS.tar.gz /srv/
and buildah copy $ctr ./src tmp
and buildah config --cmd /sbin/init $ctr
and buildah run $ctr bash /tmp/install.sh $uid
and buildah commit --rm $ctr $tag
or abort $ctr
