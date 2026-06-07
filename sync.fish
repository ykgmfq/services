#!/usr/bin/fish
set confext /var/lib/confexts/services

mkdir -p $confext/etc/containers/systemd $confext/etc/extension-release.d
echo "ID=_any" > $confext/etc/extension-release.d/extension-release.services

rclone sync systemd $confext/etc/containers/systemd

if not systemd-confext refresh
    exit 1
end

if not /usr/lib/systemd/system-generators/podman-system-generator -dryrun
    exit 1
end

systemctl daemon-reload
