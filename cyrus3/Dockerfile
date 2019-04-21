FROM alpine:3.9 AS libs-builder

# Install dependencies
RUN apk update && apk add --no-cache \
      git \
      bash \
      build-base \
      gcc \
      wget \
      sudo \
      automake \
      autoconf \
      libtool \
      pkgconfig \
      texinfo \
      check-dev  \
      util-linux-dev  \
      linux-headers \
      zlib-dev \
      cmake \
      glib-dev \
      libxml2-dev \
      graphviz \
      doxygen \
      help2man \
      py-docutils \
      icu-dev \
      file-dev \
      tcl \
      py-pygments && \
    ## Build musl-fts from source
    mkdir -p /root/cyrus && \
    cd /root/cyrus && \
    git clone https://github.com/pullmoll/musl-fts.git && \
    cd musl-fts && \
    autoreconf -vif && \
    ./configure && \
    make && \
    make install && \
    # Clone cyruslibs
    cd /root/cyrus && git clone --recursive https://github.com/cyrusimap/cyruslibs.git

COPY build/libical-fix-path.patch /root/cyrus/cyruslibs
COPY build/cre2-include-stdint-headers.patch /root/cyrus/cyruslibs/cre2

RUN cd /root/cyrus/cyruslibs/cre2 && \
    patch -p1 -i cre2-include-stdint-headers.patch && \
    cd /root/cyrus/cyruslibs && \
    patch -p1 -i libical-fix-path.patch && \
    cd /root/cyrus/cyruslibs && LIBS=-lfts ./build.sh

FROM alpine:3.9

# TODO define build-only deps
RUN apk update && apk add --no-cache \
      # Build tools
      git \
      build-base \
      gcc \
      wget \
      automake \
      autoconf \
      libtool \
      pkgconfig \
      # Required (I guess?)
      libxml2-dev \
      cyrus-sasl-dev \
      sqlite-dev \
      perl-dev \
      pcre-dev \
      util-linux-dev \
      bison \
      flex \
      # Optional:
      clamav-dev \
      nghttp2-dev \
      # Ops
      sudo \
      vim \
      bash \
      syslog-ng \
      runit && \
    # Build musl-fts from source
    mkdir -p /root/cyrus && \
    cd /root/cyrus && \
    git clone https://github.com/pullmoll/musl-fts.git && \
    cd musl-fts && \
    autoreconf -vif && \
    ./configure && \
    make && \
    make install

# Copy cyruslibs folder from builder
COPY --from=libs-builder /usr/local/cyruslibs /usr/local/cyruslibs

# Set some important environment variables to build cyrus from source
# https://github.com/cyrusimap/cyrus-imapd#how-to-install-cyrus-libraries-from-git-source
# https://cyrusimap.org/imap/developer/install-xapian.html
ENV CYRUSLIBS=/usr/local/cyruslibs
ENV PKG_CONFIG_PATH="$CYRUSLIBS/lib/pkgconfig:$PKG_CONFIG_PATH"
ENV LDFLAGS="-Wl,-rpath,$CYRUSLIBS/lib -Wl,-rpath,$CYRUSLIBS/lib/x86_64-linux-gnu"
ENV XAPIAN_CONFIG="$CYRUSLIBS/bin/xapian-config-1.5"

# Clone cyrus-imapd
RUN mkdir -p /root/cyrus && cd /root/cyrus && git clone https://github.com/cyrusimap/cyrus-imapd.git

# COPY build/cyrus-imapd-qsort_r-fix.patch /root/cyrus/cyrus-imapd

# Patch & make & install cyrus-imapd
RUN cd /root/cyrus/cyrus-imapd && \
    # git checkout cyrus-imapd-3.1.6 && \
    # patch -p1 -i cyrus-imapd-qsort_r-fix.patch && \
    autoreconf -i && \
    ./configure \
        --includedir=/usr/include \
        --datadir=/usr/share/cyrus \
        --sharedstatedir=/usr/share/cyrus \
        --localstatedir=/var/lib/cyrus \
        --libexecdir=/usr/lib/cyrus/bin \
        --bindir=/usr/lib/cyrus/bin \
        --sbindir=/usr/lib/cyrus/bin \
        --prefix=/usr/lib/cyrus \
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
        --enable-unit-tests \
        --enable-gssapi="/usr" \
        --with-cyrus-user=cyrus --with-cyrus-group=mail \
        --with-lock=fcntl \
        --with-ldap \
        --with-krb \
        --with-krbimpl=mit \
        --without-krbdes \
        --with-openssl \
        --with-zlib \
        --with-libcap \
        --with-pidfile=/run/cyrus-master.pid \
        --with-com_err="" \
        --with-syslogfacility=MAIL \
        --with-gss_impl=mit \
        --with-sasl \
        --with-perl=/usr/bin/perl \
        --with-snmp && \
    make && \
    make install

# Copy config files
COPY conf/cyrus.conf /etc/cyrus.conf
COPY conf/imapd.conf /etc/imapd.conf
COPY conf/syslog-ng.conf /etc/syslog-ng/syslog-ng.conf

# Add cyrus services (https://www.cyrusimap.org/imap/installing.html#protocol-ports)
COPY conf/cyrus.services /root/cyrus/cyrus.services

RUN cat /root/cyrus/cyrus.services >> /etc/services && \
    # User cyrus has to be member of `sasl` group
    addgroup -S sasl && adduser cyrus sasl && \
    mkdir -p /var/lib/cyrus /var/spool/cyrus && \
    chown -R cyrus:mail /var/lib/cyrus /var/spool/cyrus && \
    chmod 750 /var/lib/cyrus /var/spool/cyrus && \
    # https://www.cyrusimap.org/imap/reference/manpages/systemcommands/mkimap.html
    cd /root/cyrus/cyrus-imapd && sudo -u cyrus ./tools/mkimap && \
    # https://www.cyrusimap.org/imap/installing.html#prepare-ephemeral-run-time-storage-directories
    mkdir -p /run/cyrus /run/cyrus/socket && \
    # TODO Probably not needed
    # dpkg-statoverride --add cyrus mail 755 /run/cyrus && \
    # dpkg-statoverride --add cyrus mail 750 /run/cyrus/socket && \
    chown -h cyrus:mail /run/cyrus && \
    chmod 755 /run/cyrus && \
    chown -h cyrus:mail /run/cyrus/socket && \
    chmod 750 /run/cyrus/socket

# Copy run scripts
COPY runit_bootstrap /usr/sbin/runit_bootstrap
COPY service /etc/service

# Clean up after us
RUN rm -rf /root/cyrus
# TODO: delete packages?

STOPSIGNAL SIGKILL

# pop3 imap imaps pop3s kpop lmtp smmap csync mupdate sieve http
EXPOSE 110 143 993 995 1109 2003 2004 2005 3905 4190 8080

ENTRYPOINT ["/usr/sbin/runit_bootstrap"]
