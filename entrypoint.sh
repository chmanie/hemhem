# service rsyslog start
service saslauthd start

# Run own saslauthd server using pam and pam-mysql
# Run chatty postfix in foreground (http://www.postfix.org/master.8.html)

multirun "/usr/lib/postfix/sbin/master -s -v"
# TODO restart saslauthd when failing
# supervisord instead of multirun?
# /usr/lib/postfix/sbin/master
