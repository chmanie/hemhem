FROM bitnami/minideb:buster as libs-builder

RUN install_packages \
    # minideb additions
    ca-certificates \
    curl \
    # Cyrus lib dependencies and build tools
    git \
    cmake \
    build-essential \
    autoconf \
    automake \
    libtool \
    pkg-config \
    bison \
    flex \
    libssl-dev \
    libxml2-dev \
    libsqlite3-dev \
    libsasl2-dev \
    libpcre3-dev \
    uuid-dev \
    sudo \
    xxd \
    # For building the cyrus libs
    check \
    tcl \
    texinfo \
    libicu-dev \
    zlib1g \
    zlib1g-dev \
    libglib2.0-dev \
    graphviz \
    doxygen \
    help2man \
    python-docutils \
    libmagic-dev \
    tclsh \
    python-pygments \
    python3-sphinx

RUN mkdir -p /root/cyrus && \
    cd /root/cyrus && \
    git clone https://github.com/cyrusimap/cyruslibs.git && \
    cd cyruslibs && \
    git checkout dd656ed3e104373449f015c3590b0f839efc14ef

# COPY build/cre2_include_stdint_headers.patch /root/cyrus/cyruslibs/cre2

RUN cd /root/cyrus/cyruslibs && ./build.sh

FROM bitnami/minideb:buster

RUN install_packages \
    # minideb additions
    ca-certificates \
    curl \ 
    rsync \
    # Cyrus dependencies and build tools
    git \
    libcunit1 \
    build-essential \
    autoconf \
    automake \
    libtool \
    pkg-config \
    bison \
    flex \
    libssl-dev \
    libxml2-dev \
    libsqlite3-dev \
    libsasl2-dev \
    libpcre3-dev \
    uuid-dev \
    sudo \
    xxd \
    # http/2
    libnghttp2-dev \
    # For virus scan support
    libclamav-dev \
    # Run daemons
    runit \
    syslog-ng

# Copy cyruslibs folder from builder
COPY --from=libs-builder /usr/local/cyruslibs /usr/local/cyruslibs

# Install cyrus
# https://github.com/cyrusimap/cyrus-imapd#how-to-install-cyrus-libraries-from-git-source
# https://cyrusimap.org/imap/developer/install-xapian.html
ENV CYRUSLIBS=/usr/local/cyruslibs
ENV PKG_CONFIG_PATH="$CYRUSLIBS/lib/pkgconfig:$PKG_CONFIG_PATH"
ENV LDFLAGS="-Wl,-rpath,$CYRUSLIBS/lib -Wl,-rpath,$CYRUSLIBS/lib/x86_64-linux-gnu"
ENV XAPIAN_CONFIG="$CYRUSLIBS/bin/xapian-config-1.5"

RUN mkdir -p /root/cyrus && cd /root/cyrus && git clone https://github.com/cyrusimap/cyrus-imapd.git

RUN useradd -c "Cyrus IMAP Server" -d /var/lib/cyrus -g mail -s /bin/bash -r cyrus

RUN cd /root/cyrus/cyrus-imapd && \
    git checkout cyrus-imapd-3.1.9 && \
    autoreconf -i && \
    ./configure \
      --build=x86_64-linux-gnu \
      --prefix=/usr \
      --includedir=\${prefix}/include \
      --mandir=\${prefix}/share/man \
      --infodir=\${prefix}/share/info \
      --sysconfdir=/etc \
      --localstatedir=/var \
      --disable-silent-rules \
      --libdir=\${prefix}/lib/x86_64-linux-gnu \
      --runstatedir=/run \
      --disable-maintainer-mode \
      --disable-dependency-tracking \
      --build x86_64-linux-gnu \
      --includedir=/usr/include \
      --datadir=/usr/share/cyrus \
      --sharedstatedir=/usr/share/cyrus \
      --localstatedir=/var/lib/cyrus \
      --libexecdir=/usr/lib/cyrus/bin \
      --bindir=/usr/lib/cyrus/bin \
      --sbindir=/usr/lib/cyrus/bin \
      --with-cyrus-prefix=/usr/lib/cyrus \
      --disable-silent-rules \
      --enable-autocreate \
      --enable-idled \
      --enable-jmap \
      --enable-nntp \
      --enable-murder \
      --enable-http \
      --enable-replication \
      --enable-xapian \
      --enable-backup \
      --enable-calalarmd \
      --enable-gssapi=/usr \
      --with-cyrus-user=cyrus \
      --with-cyrus-group=mail \
      --with-lock=fcntl \
      --with-ldap \
      --with-krb \
      --with-krbimpl=mit \
      --without-krbdes \
      --with-openssl \
      --with-zlib \
      --with-libcap \
      --with-pidfile=/run/cyrus-master.pid \
      --with-com_err= \
      --with-syslogfacility=MAIL \
      --with-gss_impl=mit \
      --with-sasl \
      --with-perl=/usr/bin/perl \
      --with-snmp && \
    make && \
    make install

# User cyrus has to be member of `sasl` group
RUN groupadd -fr sasl && usermod -aG sasl cyrus

# for root CAs (?)
# RUN usermod -aG ssl-cert cyrus

# Copy config files (TODO: make dynamic for k8s?)
COPY ./conf/cyrus.conf /etc/cyrus.conf
COPY ./conf/imapd.conf /etc/imapd.conf
COPY ./conf/syslog-ng.conf /etc/syslog-ng/syslog-ng.conf
COPY ./conf/services /etc/services

# Prepare directories
RUN mkdir -p /var/lib/cyrus /var/spool/cyrus && \
    chown -R cyrus:mail /var/lib/cyrus /var/spool/cyrus && \
    chmod 750 /var/lib/cyrus /var/spool/cyrus


# https://www.cyrusimap.org/imap/installing.html#prepare-ephemeral-run-time-storage-directories
RUN mkdir -p /run/cyrus /run/cyrus/socket && \
    dpkg-statoverride --add cyrus mail 755 /run/cyrus && \
    dpkg-statoverride --add cyrus mail 750 /run/cyrus/socket && \
    chown -h cyrus:mail /run/cyrus && \
    chmod 755 /run/cyrus && \
    chown -h cyrus:mail /run/cyrus/socket && \
    chmod 750 /run/cyrus/socket

# Copy run scripts
COPY runit_bootstrap /usr/sbin/runit_bootstrap
COPY service /etc/service

# https://www.cyrusimap.org/imap/reference/manpages/systemcommands/mkimap.html
RUN cd /root/cyrus/cyrus-imapd && sudo -u cyrus ./tools/mkimap

# Clean up after us
RUN rm -rf /root/cyrus

# pop3 imap imaps pop3s kpop lmtp smmap csync mupdate sieve http
EXPOSE 110 143 993 995 1109 2003 2004 2005 3905 4190 8080

ENTRYPOINT ["/usr/sbin/runit_bootstrap"]
