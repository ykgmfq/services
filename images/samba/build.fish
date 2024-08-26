#!/usr/bin/fish
if set --query $CREDENTIALS_DIRECTORY
	source $CREDENTIALS_DIRECTORY/secrets.fish
else if not set -q argv[1]
	echo Please provide credentials.
	exit 1
else
	source $argv
end
set tag (basename (pwd))
set alpine 3
set idmedia 997
set idscan 879
set install (cat src/install.sh | string collect)
set ctr (buildah from --pull docker.io/library/alpine:$alpine)
and buildah run --env pwscan=$pwscan --env pwmedia=$pwmedia --env idscan=$idscan --env idmedia=$idmedia $ctr sh -c $install
and buildah copy $ctr src/smb.conf /etc/samba/
and buildah config \
    --port 445 \
    --cmd 'smbd --foreground --no-process-group' \
    $ctr
and buildah commit --rm $ctr $tag
or exit 1
