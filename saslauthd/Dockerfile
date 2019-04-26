FROM bitnami/minideb:stretch

MAINTAINER Christian Maniewski <code@chmanie.com>

RUN install_packages libsasl2-2 sasl2-bin libpam-mysql

COPY conf/pam-other /etc/pam.d/other
COPY conf/pam-mysql.conf /etc/pam-mysql.conf
COPY run /etc/service/run

ENTRYPOINT ["/etc/service/run"]

