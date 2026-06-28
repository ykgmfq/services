#!/bin/sh
# Read-only container rootfs: every writable Samba database lives on the /run
# tmpfs. Build the user database fresh at startup from the passwords mounted as
# a podman secret, then hand off to smbd. Nothing secret is baked in the image.
#
# Each `<user>=<password>` line in the secret defines one Samba user; the
# matching Unix account with its fixed uid is created at build time in
# install.sh. The monitor account uses a fixed, non-secret password for the
# healthcheck and is added separately.
set -e
install -d -m 0755 /run/samba/private /run/samba/state /run/samba/cache /run/samba/lock

while IFS='=' read -r user password; do
	case "$user" in
		''|'#'*) continue ;;
	esac
	printf '%s\n%s\n' "$password" "$password" | smbpasswd -s -a "$user"
done < /run/secrets/samba_passwords

printf '%s\n%s\n' monitor monitor | smbpasswd -s -a monitor

exec smbd --foreground --no-process-group --debug-stdout
