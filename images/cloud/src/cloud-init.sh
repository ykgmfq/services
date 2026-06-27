#!/usr/bin/bash
# Bring Nextcloud up to the level of the freshly baked image before php-fpm serves
# traffic. The database is a sibling pod container with no cross-container ordering,
# so first wait for it to answer. Then apply any schema migration the new code needs
# (occ upgrade exits 3 when the schema is already current) and clear maintenance mode.
set -euo pipefail
cd /usr/share/nextcloud
until php occ status >/dev/null 2>&1; do
	sleep 2
done
php occ upgrade || test $? -eq 3
php occ maintenance:mode --off
