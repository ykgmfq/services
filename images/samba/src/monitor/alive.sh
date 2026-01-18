#!/bin/sh
SMB_OUTPUT=$(smbclient "//localhost/monitor" "monitor" -U "monitor" -c "get m.txt -" 2>/dev/null)
LOCAL_OUTPUT=$(cat /opt/monitor/m.txt 2>/dev/null)
if [ "$SMB_OUTPUT" != "$LOCAL_OUTPUT" ]; then
    echo "Healthcheck failed: Samba output does not match local file"
    exit 1
fi
