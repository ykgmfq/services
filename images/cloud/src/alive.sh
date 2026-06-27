#!/usr/bin/bash
set -euo pipefail
echo "Installed: "
REQUEST_METHOD=GET SCRIPT_NAME=/usr/share/nextcloud/status.php SCRIPT_FILENAME=/usr/share/nextcloud/status.php cgi-fcgi -bind -connect /run/php-fpm/cloud.sock | tail -n1 | jq --exit-status ".installed"
