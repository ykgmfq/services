#!/usr/bin/bash
set -euo pipefail
echo "Installed: "
REQUEST_METHOD=GET SCRIPT_NAME=/srv/de.dm-poepperl.cloud/html/status.php SCRIPT_FILENAME=/srv/de.dm-poepperl.cloud/html/status.php cgi-fcgi -bind -connect localhost:8000 | tail -n1 | jq --exit-status ".installed"
