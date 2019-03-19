FROM debian:stretch

RUN apt-get update && apt-get -y install \
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
    python-pygments
    # TODO: install syslog

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

# Copy config files (TODO: make dynamic for k8s?)
COPY ./conf/pam-imap /etc/pam.d/imap
COPY ./conf/pam-mysql.conf /etc/pam-mysql.conf

ADD https://github.com/nicolas-van/multirun/releases/download/0.3.0/multirun-ubuntu-0.3.0.tar.gz /root
RUN cd /root && \
    tar -zxvf multirun-ubuntu-0.3.0.tar.gz && \
    mv multirun /bin && \
    rm multirun-ubuntu-0.3.0.tar.gz

ENTRYPOINT multirun "saslauthd -a pam -d"
