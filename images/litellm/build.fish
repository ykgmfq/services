#!/usr/bin/fish
function abort
    buildah rm $argv
    exit 1
end
set tag (basename (pwd))
set config --cmd '["--config", "/app/config.yaml", "--port", "4000"]'
set ctr (buildah from --pull ghcr.io/berriai/litellm:main-stable)
and buildah copy $ctr config.yaml /app/config.yaml
and buildah config $config $ctr
and buildah commit --rm $ctr $tag
or abort $ctr
