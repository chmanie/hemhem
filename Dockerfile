# TODO: Use multistage-build https://docs.docker.com/develop/develop-images/multistage-build/

FROM debian:stretch

RUN apt-get update && apt-get -y install \
    # Cyrus dependencies and build tools
    git \
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
    # For virus scan support
    libclamav-dev \
    # SASL
    libsasl2-2 \
    sasl2-bin \
    libsasl2-modules \
    libpam-mysql \
    # For building the cyrus libs
    check \
    texinfo \
    cmake \
    libglib2.0-dev \
    graphviz \
    doxygen \
    help2man \
    python-docutils \
    libmagic-dev \
    tclsh \
    python-pygments \
    # syslog (because cyrus won't log to anywhere else)
    syslog-ng

# Install multirun https://nicolas-van.github.io/multirun/
ADD https://github.com/nicolas-van/multirun/releases/download/0.3.0/multirun-ubuntu-0.3.0.tar.gz /root
RUN cd /root && \
    tar -zxvf multirun-ubuntu-0.3.0.tar.gz && \
    mv multirun /bin && \
    rm multirun-ubuntu-0.3.0.tar.gz

RUN mkdir -p /root/cyrus

RUN cd /root/cyrus && git clone https://github.com/cyrusimap/cyruslibs.git && cd cyruslibs && ./build.sh

# https://github.com/cyrusimap/cyrus-imapd#how-to-install-cyrus-libraries-from-git-source
ENV CYRUSLIBS=/usr/local/cyruslibs
ENV PKG_CONFIG_PATH="$CYRUSLIBS/lib/pkgconfig:$PKG_CONFIG_PATH"
ENV LDFLAGS="-Wl,-rpath,$CYRUSLIBS/lib -Wl,-rpath,$CYRUSLIBS/lib/x86_64-linux-gnu"

RUN cd /root/cyrus && git clone https://github.com/cyrusimap/cyrus-imapd.git && \
    cd cyrus-imapd && \
    git checkout cyrus-imapd-3.1.6 && \
    autoreconf -i && \
    ./configure XAPIAN_CONFIG="$CYRUSLIBS/bin/xapian-config-1.5" --enable-http --enable-jmap --enable-xapian --prefix=/usr && \
    make && \
    make install

RUN useradd -c "Cyrus IMAP Server" -d /var/lib/cyrus -g mail -s /bin/bash -r cyrus

# saslauth for ubuntu, sasl for debian
RUN groupadd -fr sasl && usermod -aG sasl cyrus

# for root CAs (?)
# RUN usermod -aG ssl-cert cyrus

# Copy config files (TODO: make dynamic for k8s?)
COPY ./conf/pam-imap /etc/pam.d/imap
COPY ./conf/pam-mysql.conf /etc/pam-mysql.conf
COPY ./conf/cyrus.conf /etc/cyrus.conf
COPY ./conf/imapd.conf /etc/imapd.conf
COPY ./conf/syslog-ng.conf /etc/syslog-ng/syslog-ng.conf

# Add cyrus services (https://www.cyrusimap.org/imap/installing.html#protocol-ports)
RUN echo '\n# Services used for cyrus\n\
httpcyrus 8080/tcp # Cyrus HTTP API\n\
lmtp      2003/tcp # Lightweight Mail Transport Protocol service\n\
smmap     2004/tcp # Cyrus smmapd (quota check) service\n\
csync     2005/tcp # Cyrus replication service\n\
mupdate   3905/tcp # Cyrus mupdate service\n\
sieve     4190/tcp # timsieved Sieve Mail Filtering Language service' >> /etc/services

# Prepare directories
RUN mkdir -p /var/lib/cyrus /var/spool/cyrus && \
    chown -R cyrus:mail /var/lib/cyrus /var/spool/cyrus && \
    chmod 750 /var/lib/cyrus /var/spool/cyrus

RUN cd /root/cyrus/cyrus-imapd && sudo -u cyrus ./tools/mkimap

# https://www.cyrusimap.org/imap/installing.html#prepare-ephemeral-run-time-storage-directories
RUN mkdir -p /run/cyrus /run/cyrus/socket && \
    dpkg-statoverride --add cyrus mail 755 /run/cyrus && \
    dpkg-statoverride --add cyrus mail 750 /run/cyrus/socket && \
    chown -h cyrus:mail /run/cyrus && \
    chmod 755 /run/cyrus && \
    chown -h cyrus:mail /run/cyrus/socket && \
    chmod 750 /run/cyrus/socket

# TODO remove -d and -D (debugging) flags
ENTRYPOINT multirun "saslauthd -a pam -c -r -d" "/root/cyrus/cyrus-imapd/master/master -D"

# pop3 imap imaps pop3s kpop lmtp smmap csync mupdate sieve http
EXPOSE 110 143 993 995 1109 2003 2004 2005 3905 4190 8080
