# export CYRUS_VERBOSE=1000

multirun "/usr/sbin/syslog-ng -p /var/run/syslog-ng.pid -F" "/root/cyrus/cyrus-imapd/master/master -D"
