#!/bin/sh
apk add --no-cache avahi
sed --in-place "s|#enable-dbus.*|enable-dbus=no|g" /etc/avahi/avahi-daemon.conf
