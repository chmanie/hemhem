FROM alpine:latest

MAINTAINER Christian Maniewski <code@chmanie.com>

RUN mkdir -p /tmp/cyrus-sasl /var/run/saslauthd && \
    export BUILD_DEPS=" \
      autoconf \
      automake \
      curl \
      db-dev \
      g++ \
      gcc \
      gzip \
      heimdal-dev \
      libtool \
      make \
      tar \
      git \
    " && \
    apk add --update ${BUILD_DEPS} \
      bash \
      openssl-dev \
      mariadb-dev \
      linux-pam-dev \
      cyrus-sasl && \
    # Install cyrus-sasl from source
    curl -fL https://github.com/cyrusimap/cyrus-sasl/releases/download/cyrus-sasl-2.1.27/cyrus-sasl-2.1.27.tar.gz -o /tmp/cyrus-sasl.tgz && \
    curl -fL http://git.alpinelinux.org/cgit/aports/plain/main/cyrus-sasl/cyrus-sasl-2.1.27-avoid_pic_overwrite.patch -o /tmp/cyrus-sasl-2.1.27-avoid_pic_overwrite.patch && \
    curl -fL http://git.alpinelinux.org/cgit/aports/plain/main/cyrus-sasl/cyrus-sasl-2.1.27-as_needed.patch -o /tmp/cyrus-sasl-2.1.27-as_needed.patch && \
    curl -fL http://git.alpinelinux.org/cgit/aports/plain/main/cyrus-sasl/cyrus-sasl-2.1.27-autotools_fixes.patch -o /tmp/cyrus-sasl-2.1.27-autotools_fixes.patch && \
    curl -fL http://git.alpinelinux.org/cgit/aports/plain/main/cyrus-sasl/cyrus-sasl-2.1.27-doc_build_fix.patch -o /tmp/cyrus-sasl-2.1.27-doc_build_fix.patch && \
    curl -fL http://git.alpinelinux.org/cgit/aports/plain/main/cyrus-sasl/cyrus-sasl-2.1.27-gss_c_nt_hostbased_service.patch -o /tmp/cyrus-sasl-2.1.27-gss_c_nt_hostbased_service.patch && \
    tar -xzf /tmp/cyrus-sasl.tgz --strip=1 -C /tmp/cyrus-sasl && \
    cd /tmp/cyrus-sasl && \
    patch -p1 -i /tmp/cyrus-sasl-2.1.27-avoid_pic_overwrite.patch && \
    patch -p1 -i /tmp/cyrus-sasl-2.1.27-as_needed.patch && \
    patch -p1 -i /tmp/cyrus-sasl-2.1.27-autotools_fixes.patch && \
    patch -p1 -i /tmp/cyrus-sasl-2.1.27-doc_build_fix.patch && \
    patch -p1 -i /tmp/cyrus-sasl-2.1.27-gss_c_nt_hostbased_service.patch && \
    autoreconf -vif && \
     ./configure \
        --build=$CBUILD \
        --host=$CHOST \
        --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --mandir=/usr/share/man \
        --enable-static \
        --enable-shared \
        --disable-java \
        --with-plugindir=/usr/lib/sasl2 \
        --with-configdir=/etc/sasl2 \
        --with-dbpath=/etc/sasl2/sasldb2 \
        --disable-krb4 \
        --with-gss_impl=mit \
        --enable-gssapi \
        --with-rc4 \
        --with-dblib=berkeley \
        --with-saslauthd=/var/run/saslauthd \
        --without-pwcheck \
        --with-devrandom=/dev/urandom \
        --enable-anon \
        --enable-cram \
        --enable-digest \
        --enable-ntlm \
        --enable-plain \
        --enable-login \
        --enable-auth-sasldb \
        --enable-alwaystrue \
        --disable-otp && \
      make -j1 && \
      make -j1 install && \
      # Build pam-mysql from source
      mkdir -p /tmp/pam-mysql && \
      cd /tmp/pam-mysql && \
      git clone https://github.com/NigelCunningham/pam-MySQL.git . && \
      autoreconf -f -i && \
      ./configure --with-cyrus-sasl2 --with-openssl=yes && \
      make && \
      make install && \
      # Clean up build-time packages
      apk del --purge ${BUILD_DEPS} && \
      # Clean up anything else
      rm -fr \
        /tmp/* \
        /var/tmp/* \
        /var/cache/apk/*

# DEBUG TODO remove
RUN apk add rsyslog

# other is some sort of catch all for pam rules: https://linux.die.net/man/5/pam.d
COPY conf/pam-other /etc/pam.d/other
COPY conf/pam-mysql.conf /etc/pam-mysql.conf
COPY run /etc/service/run

ENTRYPOINT ["/etc/service/run"]
