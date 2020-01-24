FROM bitnami/minideb:buster

RUN install_packages \
  postfix \
  postfix-mysql \
  postfix-pgsql \
  runit \
  rsyslog

RUN mkdir -p /etc/postfix/sql

COPY conf/main.cf /etc/postfix/main.cf
COPY conf/master.cf /etc/postfix/master.cf
COPY conf/smtpd.conf /etc/sasl2/smtpd.conf
COPY conf/sql /etc/postfix/sql
# TODO: Use syslog-ng for this as well 
COPY conf/rsyslog.conf /etc/rsyslog.conf

COPY runit_bootstrap /usr/sbin/runit_bootstrap
COPY service /etc/service

# Set up directories and users
# http://flurdy.com/docs/postfix/#config-simple-mta
# Only postfix user should have access to mysql map files (passwords are in there!)
RUN chmod 640 /etc/postfix/sql/*.cf && \
    chgrp postfix /etc/postfix/sql/*.cf && \
    # User postfix has to be member of `sasl` group
    groupadd -fr sasl && usermod -aG sasl postfix && \
    mkdir /var/spool/mail/virtual && \
    groupadd --system virtual -g 5000 && \
    useradd --system virtual -u 5000 -g 5000 && \
    chown -R virtual:virtual /var/spool/mail/virtual

RUN ln -sf /dev/stdout /var/log/mail.log

STOPSIGNAL SIGKILL

EXPOSE 25

ENTRYPOINT ["/usr/sbin/runit_bootstrap"]
