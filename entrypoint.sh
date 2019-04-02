# Debugging
service rsyslog start

# Run chatty postfix in foreground (http://www.postfix.org/master.8.html)
/usr/lib/postfix/sbin/master -s -v
