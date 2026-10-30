mkdir --mode='ugo=rwx' $1
mkdir --mode='ugo=rx' /usr/src/paperless/scripts
mv /tmp/removepassword.py $2
chmod +x $2
rm /tmp/install.sh
