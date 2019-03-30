
# TODO later
# sed -i "s/{MYSQL_MAIL_PASSWORD}/${MYSQL_MAIL_PASSWORD}/g" etc/pam-mysql.conf

export CYRUS_VERBOSE=1

multirun "/usr/sbin/syslog-ng -p /var/run/syslog-ng.pid -F" "saslauthd -a pam -c -r -m /var/run/saslauthd -d" "/root/cyrus/cyrus-imapd/master/master -D"
