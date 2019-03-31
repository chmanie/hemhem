# We want postfix 3.4 so buster it is
FROM debian:buster

RUN apt-get update && apt-get -y install \
  postfix \
  postfix-mysql

COPY ./conf/main.cf /etc/postfix/main.cf
COPY ./conf/master.cf /etc/postfix/master.cf
COPY ./conf/smtpd.conf /etc/postfix/sasl/smtpd.conf
COPY ./conf/mysql-virtual-alias-maps.cf /etc/postfix/mysql-virtual-alias-maps.cf
COPY ./conf/mysql-virtual-email2email.cf /etc/postfix/mysql-virtual-email2email.cf
COPY ./conf/mysql-virtual-mailbox-domains.cf /etc/postfix/mysql-virtual-mailbox-domains.cf
COPY ./conf/mysql-virtual-mailbox-maps.cf /etc/postfix/mysql-virtual-mailbox-maps.cf
COPY ./conf/saslauthd /etc/default/saslauthd

COPY ./entrypoint.sh /root/entrypoint.sh

# Only postfix user should have access to mysql map files (passwords are in there!)
RUN chmod 640 /etc/postfix/mysql-*.cf && \
    chgrp postfix /etc/postfix/mysql-*.cf && \
    # User postfix has to be member of `sasl` group
    groupadd -fr sasl && usermod -aG sasl postfix
# https://wiki.debian.org/PostfixAndSASL#Implementation_using_Cyrus_SASL
    # dpkg-statoverride --add root sasl 710 /var/spool/postfix/var/run/saslauthd

ENTRYPOINT /root/entrypoint.sh

EXPOSE 25
