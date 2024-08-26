#!/usr/bin/fish
set tag (basename (pwd))
set nodejs 20
echo "Tag | $tag"
podman build --tag $tag --build-arg TAG_SUFFIX=minimal --build-arg NODE_VERSION=$nodejs node-red-docker/docker-custom

