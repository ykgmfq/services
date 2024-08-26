#!/bin/sh
adduser --disabled-password --no-create-home --uid $idscan scan
adduser --disabled-password --no-create-home --uid $idmedia media
adduser --disabled-password --no-create-home monitor
apk add --no-cache samba
(echo $pwmedia; sleep 1; echo $pwmedia ) | smbpasswd -s -a media
(echo $pwscan; sleep 1; echo $pwscan ) | smbpasswd -s -a scan
(echo monitor; sleep 1; echo monitor ) | smbpasswd -s -a monitor
mkdir /opt/monitor
echo "OK" > /opt/monitor/m.txt
