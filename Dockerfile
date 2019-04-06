FROM alpine:latest

RUN apk update && apk add --no-cache \
  bash \
  postfix \
  postfix-mysql \
  cyrus-sasl \
  cyrus-sasl-plain \
  # TODO use syslog-ng like in cyrus
  rsyslog \
  runit \
  --repository http://dl-cdn.alpinelinux.org/alpine/edge/main

# DEBUG TODO remove
RUN apk add --no-cache \
  vim \
  net-tools \
  procps \
  busybox-extras

COPY conf/main.cf /etc/postfix/main.cf
# COPY conf/master.cf /etc/postfix/master.cf
COPY conf/smtpd.conf /etc/sasl2/smtpd.conf
COPY conf/mysql_mailbox.cf /etc/postfix/mysql_mailbox.cf
COPY conf/mysql_alias.cf /etc/postfix/mysql_alias.cf
COPY conf/mysql_domains.cf /etc/postfix/mysql_domains.cf
COPY conf/rsyslog.conf /etc/rsyslog.conf

COPY runit_bootstrap /usr/sbin/runit_bootstrap
COPY service /etc/service

RUN chmod 640 /etc/postfix/mysql_*.cf && \
    chgrp postfix /etc/postfix/mysql_*.cf && \
    # User postfix has to be member of `sasl` group
    addgroup -S sasl && adduser postfix sasl && \
    mkdir -p /var/spool/mail/virtual && \
    addgroup -S -g 5000 virtual && \
    adduser -S -g 5000 virtual virtual && \
    chown -R virtual:virtual /var/spool/mail/virtual

RUN ln -sf /dev/stdout /var/log/mail.log

STOPSIGNAL SIGKILL

EXPOSE 25

ENTRYPOINT ["/usr/sbin/runit_bootstrap"]
