FROM debian:stretch

RUN apt-get update && apt-get -y install \
  # DEBUG STUFF
  rsyslog \
  procps \
  vim \
  telnet \
  sudo \
  # DEBUG STUFF END
  postfix \
  postfix-mysql \
  libsasl2-2 \
  sasl2-bin \
  libsasl2-modules \
  libpam-mysql

# Install multirun https://nicolas-van.github.io/multirun/
ADD https://github.com/nicolas-van/multirun/releases/download/0.3.0/multirun-ubuntu-0.3.0.tar.gz /root
RUN cd /root && \
    tar -zxvf multirun-ubuntu-0.3.0.tar.gz && \
    mv multirun /bin && \
    rm multirun-ubuntu-0.3.0.tar.gz

COPY ./conf/pam-smtp /etc/pam.d/smtp
COPY ./conf/pam-mysql.conf /etc/pam-mysql.conf
COPY ./conf/main.cf /etc/postfix/main.cf
COPY ./conf/master.cf /etc/postfix/master.cf
COPY ./conf/smtpd.conf /etc/postfix/sasl/smtpd.conf
COPY ./conf/mysql-virtual-alias-maps.cf /etc/postfix/mysql-virtual-alias-maps.cf
COPY ./conf/mysql-virtual-email2email.cf /etc/postfix/mysql-virtual-email2email.cf
COPY ./conf/mysql-virtual-mailbox-domains.cf /etc/postfix/mysql-virtual-mailbox-domains.cf
COPY ./conf/mysql-virtual-mailbox-maps.cf /etc/postfix/mysql-virtual-mailbox-maps.cf
COPY ./conf/saslauthd /etc/default/saslauthd

COPY ./entrypoint.sh /root/entrypoint.sh

# User postfix has to be member of `sasl` group
RUN groupadd -fr sasl && usermod -aG sasl postfix && \
# Only postfix user should have access to mysql map files (passwords are in there!)
    chmod 640 /etc/postfix/mysql-*.cf && \
    chgrp postfix /etc/postfix/mysql-*.cf && \
# Move sasl socket dir, create link (https://serverfault.com/questions/319703/postfix-sasl-cannot-connect-to-saslauthd-server-no-such-file-or-directory)
    mkdir -p /var/spool/postfix/var/run/saslauthd && \
    # Delete the default directory (it might be there?)
    rm -rf /var/run/saslauthd && \
    ln -sfn /var/spool/postfix/var/run/saslauthd /var/run/saslauthd
    # chown root:sasl /var/run/saslauthd && \
    # mkdir -p /var/spool/postfix/var/run/ && \
    # ln -s /var/run/saslauthd /var/spool/postfix/var/run/saslauthd

ENTRYPOINT /root/entrypoint.sh
