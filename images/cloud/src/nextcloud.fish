#!/usr/bin/fish
# Resolve which Nextcloud major to bake, then download the server and the pinned
# appstore apps into the staging directory passed as the first argument.
#
# Policy: track the latest stable major, but step down to the highest major where
# every baked app has a stable release, so the instance never lands on a major an
# app has not yet declared support for. The build host runs this; the result is
# copied into the image as a read-only tree.

set stage $argv[1]
set apps calendar contacts mail onlyoffice integration_openai
set base https://download.nextcloud.com/server/releases
set store https://apps.nextcloud.com/api/v1

# jq program selecting the newest stable (non-nightly, no pre-release suffix)
# release object for the app id passed as --arg id. The apps feed can be several
# megabytes, so it is read from a file rather than an argument.
set pick '.[] | select(.id == $id) | .releases
    | map(select(.isNightly == false and (.version | test("-") | not)))
    | sort_by(.version | split(".") | map(tonumber? // 0))
    | last'

# Read one field of an app's newest stable release from a downloaded apps feed.
# Usage: app_field <app-id> <feed-file> <jq-expression-after-pick>
function app_field
    jq -r --arg id $argv[1] "$pick | $argv[3]" $argv[2]
end

# True when every baked app has a stable release in the given apps feed.
# Usage: feed_has_all_apps <major> <feed-file>
function feed_has_all_apps
    set -l m $argv[1]
    set -l feed $argv[2]
    for a in $apps
        if test -z (app_field $a $feed '.version // ""')
            echo "  major $m | $a has no stable release, stepping down"
            return 1
        end
    end
    return 0
end

# Step down from the newest major until one is found whose apps feed has a
# stable release for every baked app. Sets the global $major and $feed.
function resolve_major
    set -l top $argv[1]
    for m in (seq $top -1 (math $top - 4))
        set -l candidate (mktemp)
        curl -fsSL $store/platform/$m.0.0/apps.json -o $candidate
        or begin
            rm -f $candidate
            continue
        end
        if feed_has_all_apps $m $candidate
            set -g major $m
            set -g feed $candidate
            return 0
        end
        rm -f $candidate
    end
    return 1
end

# Download and extract one appstore app into the staging apps directory.
function bake_app
    set -l a $argv[1]
    set -l url (app_field $a $feed .download)
    set -l relver (app_field $a $feed .version)
    echo "Baking app $a | $relver"
    curl -fsSL $url | tar -xz -C $stage/apps
end

# Newest stable major from the GitHub "latest release" tag, e.g. v34.0.1 -> 34.
set tag (curl -fsSL https://api.github.com/repos/nextcloud/server/releases/latest | jq -r .tag_name)
set top (string replace -r '^v' '' -- $tag | string split .)[1]
echo "Latest stable major | $top"

resolve_major $top
or begin
    echo "Could not resolve a Nextcloud major supporting every baked app." >&2
    exit 1
end
echo "Resolved major | $major"

# Server tarball ships a nextcloud/ prefix; strip it so the tree lands in $stage.
echo "Downloading Nextcloud server (latest-$major)"
curl -fsSL $base/latest-$major.tar.bz2 | tar -xj -C $stage --strip-components=1
or exit 1

# Each app tarball extracts to apps/<id>/.
for a in $apps
    bake_app $a
    or exit 1
end

rm -f $feed
