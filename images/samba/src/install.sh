#!/bin/sh
adduser --disabled-password --no-create-home --uid $idscan scan
adduser --disabled-password --no-create-home --uid $idmedia media
adduser --disabled-password --no-create-home monitor
apk add --no-cache samba
