#!/usr/bin/bash
# occ upgrade exits 3 when the schema is already current
set -euo pipefail
cd /usr/share/nextcloud
until php occ status >/dev/null 2>&1; do
	sleep 2
done
php occ upgrade || test $? -eq 3
# Baking only stages an app's code; app:enable is idempotent, so run it unconditionally here.
xargs -a apps.txt -I{} php occ app:enable {}
php occ maintenance:mode --off
