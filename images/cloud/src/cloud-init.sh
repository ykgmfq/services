#!/usr/bin/bash
# occ upgrade exits 3 when the schema is already current
set -euo pipefail
cd /usr/share/nextcloud
until php occ status >/dev/null 2>&1; do
	sleep 2
done
php occ upgrade || test $? -eq 3
# Baking only stages an app's code; app:enable is idempotent, so run it unconditionally here.
xargs -a /usr/local/share/nextcloud-apps.txt -I{} php occ app:enable {}
# The document server fetches files by container name, so that name has to be trusted.
php occ config:system:set trusted_domains 3 --value=cloud-pod
# The editor runs in the browser, so it needs the public host; the two servers
# reach each other over the shared bridge network instead, which sidesteps the
# pod's inability to resolve its own public name.
php occ config:app:set eurooffice DocumentServerUrl --value=https://office.dm-poepperl.de/
php occ config:app:set eurooffice DocumentServerInternalUrl --value=http://office/
php occ config:app:set eurooffice StorageUrl --value=http://cloud-pod/
php occ config:app:set eurooffice jwt_header --value=AuthorizationJwt
php occ config:app:set eurooffice jwt_secret --value="$OFFICE_JWT_SECRET" >/dev/null
# The Anthropic shim listens on loopback, which counts as a local remote server.
php occ config:system:set allow_local_remote_servers --value=true --type=boolean
php occ config:app:set integration_openai url --value=http://127.0.0.1:8081/v1
php occ config:app:set integration_openai service_name --value=Anthropic
php occ config:app:set integration_openai chat_endpoint_enabled --value=1
php occ maintenance:mode --off
