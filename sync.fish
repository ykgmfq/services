#!/usr/bin/fish
rclone sync systemd /etc/containers/systemd --exclude '*.md'
if not /usr/lib/systemd/system-generators/podman-system-generator -dryrun
    exit 1
end
systemctl daemon-reload
