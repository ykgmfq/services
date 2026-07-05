#!/usr/bin/fish
rclone sync systemd /etc/containers/systemd --exclude '*.md' --quiet
set generator_output (/usr/lib/systemd/system-generators/podman-system-generator -dryrun 2>&1)
if test $status -ne 0
    echo $generator_output
    exit 1
end
systemctl daemon-reload
