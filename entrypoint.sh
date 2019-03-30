# We can either share cyrus' authentication via imap or share the saslauthd socket w/o starting saslauthd
# Run saslauthd with imap authentication via cyrus server
# "saslauthd -a rimap -O cyrus -c -r -d"

service rsyslog start
# service saslauthd start

# Run own saslauthd server using pam and pam-mysql
# Run chatty postfix in foreground (http://www.postfix.org/master.8.html)
multirun "/usr/lib/postfix/sbin/master" "saslauthd -a pam -c -r -m /var/spool/postfix/var/run/saslauthd -d"
