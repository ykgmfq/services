#!/usr/bin/fish
set output (rclone sync systemd /etc/containers/systemd --exclude '*.md' --log-level INFO --stats 0 2>&1)
or begin
    printf '%s\n' $output
    exit 1
end
set changes (printf '%s\n' $output | string match -r '.*: (?:Copied|Deleted|Updated|Removing directory|Making directory).*')
set generator_output (/usr/lib/systemd/system-generators/podman-system-generator -dryrun 2>&1)
if test $status -ne 0
    echo $generator_output
    exit 1
end
# Last line is the verdict, for Ansible's changed_when
if test (count $changes) -gt 0
    printf '%s\n' $changes
    systemctl daemon-reload
    echo changed
else
    echo unchanged
end
