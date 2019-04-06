# We want postfix 3.4 so buster it is
FROM debian:buster

RUN apt-get update && apt-get -y install \
  postfix \
  postfix-mysql

COPY ./conf/main.cf /etc/postfix/main.cf
COPY ./conf/master.cf /etc/postfix/master.cf
COPY ./conf/smtpd.conf /etc/postfix/sasl/smtpd.conf
COPY ./conf/mysql_mailbox.cf /etc/postfix/mysql_mailbox.cf
COPY ./conf/mysql_alias.cf /etc/postfix/mysql_alias.cf
COPY ./conf/mysql_domains.cf /etc/postfix/mysql_domains.cf

COPY ./entrypoint.sh /root/entrypoint.sh

# Set up directories and users
# http://flurdy.com/docs/postfix/#config-simple-mta
# Only postfix user should have access to mysql map files (passwords are in there!)
RUN chmod 640 /etc/postfix/mysql_*.cf && \
    chgrp postfix /etc/postfix/mysql_*.cf && \
    # User postfix has to be member of `sasl` group
    groupadd -fr sasl && usermod -aG sasl postfix && \
    echo 'mail.example.org' > /etc/mailname && \
    cp /etc/aliases /etc/postfix/aliases && \
    postalias /etc/postfix/aliases && \
    mkdir /var/spool/mail/virtual && \
    groupadd --system virtual -g 5000 && \
    useradd --system virtual -u 5000 -g 5000 && \
    chown -R virtual:virtual /var/spool/mail/virtual

# DEBUG
RUN apt-get update && apt-get -y install \
    # TODO make sure everything is logged to stdout, it's not the case right now
    rsyslog \
    mailutils \
    vim \
    net-tools \
    procps \
    telnet

ENTRYPOINT /root/entrypoint.sh

EXPOSE 25
