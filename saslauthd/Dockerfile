FROM bitnami/minideb:buster

MAINTAINER Christian Maniewski <code@chmanie.com>

RUN install_packages libsasl2-2 sasl2-bin libpam-mysql wget libpq5

RUN wget http://ftp.br.debian.org/debian/pool/main/p/pam-pgsql/libpam-pgsql_0.7.3.2-1_amd64.deb && dpkg -i libpam-pgsql_0.7.3.2-1_amd64.deb && rm -rf libpam-pgsql_0.7.3.2-1_amd64.deb

COPY conf/pam-other /etc/pam.d/other
COPY conf/pam-mysql.conf /etc/pam-mysql.conf
COPY conf/pam-pgsql.conf /etc/pam-pgsql.conf
COPY run /etc/service/run

ENTRYPOINT ["/etc/service/run"]

