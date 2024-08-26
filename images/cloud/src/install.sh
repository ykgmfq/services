#!/usr/bin/bash
set -eu
fedora=$(rpm -E %fedora)
function f { microdnf --{assumeyes,nodocs,setopt=install_weak_deps=0} $@; }
echo "Using ID $1 for cloud user and group."
echo "This is Fedora $fedora."
# Package management
f install systemd fcgi jq iproute bind-utils \
php{,-{cli,bcmath,gmp,fpm,xml,process,gd,mbstring,intl,opcache,json,zip,pgsql,sodium,redis,pecl-{apcu,imagick}}}
#f reinstall tzdata
f clean all
# Create user and matching group
echo u cloud $1 | systemd-sysusers -
# Place PHP Config files
rm /etc/php-fpm.d/*
cd /tmp
mv php/fpm.ini /etc/php-fpm.d/cloud.conf
mv php/php.ini /etc/php.d/99-nextcloud.ini
# Place system unit files
new_units=$(ls units/)
mv units/* /etc/systemd/system/
mv alive.sh /usr/local/bin/
chmod o+x /usr/local/bin/*
rm -r *
# Set system unit states
systemctl set-default container.target
systemctl enable $new_units
