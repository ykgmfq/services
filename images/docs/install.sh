mkdir --mode='ugo=rwx' $1
mkdir --mode='ugo=rx' /usr/src/paperless/scripts
curl --silent https://raw.githubusercontent.com/ykgmfq/paperless-ngx-rmpw/refs/heads/main/removepassword.py -o $2
chmod +x $2
rm /tmp/install.sh
