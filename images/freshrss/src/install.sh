#!/usr/bin/bash
set -eu
fedora=$(rpm -E %fedora)
function f { microdnf --{assumeyes,nodocs,setopt=install_weak_deps=0} $@; }
echo "Using ID $1 for freshrss user and group."
echo "This is Fedora $fedora."
mv /srv/* /srv/FreshRSS
ls -l /srv/
# Package management
f install caddy systemd \
php{,-{cli,gmp,fpm,xml,mbstring,intl,opcache,zip,sqlite3}}
#f reinstall tzdata
f clean all
# Create user and matching group
echo u freshrss $1 | systemd-sysusers -
chown -R freshrss:caddy /srv/FreshRSS
# Place PHP Config files
rm /etc/php-fpm.d/*
rm -R /etc/caddy/*
cd /tmp
mv php/fpm.ini /etc/php-fpm.d/freshrss.conf
mv php/php.ini /etc/php.d/99-freshrss.ini
rm --verbose /etc/php.d/*-{calendar,exif,ftp}.ini
mv Caddyfile /etc/caddy/
# Place system unit files
new_units=$(ls units/)
mv units/* /etc/systemd/system/
rm -r *
# Set system unit states
systemctl set-default container.target
systemctl enable $new_units
