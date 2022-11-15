FROM debian:bullseye-20221024

LABEL maintainer="lixycm@gmail.com"

RUN set -eux; apt-get update; apt-get install -y --no-install-recommends \
    ca-certificates curl netbase wget; rm -rf /var/lib/apt/lists/*
RUN set -eux; apt-get update; apt-get install -y --no-install-recommends \
    gnupg dirmngr; rm -rf /var/lib/apt/lists/*
RUN set -eux; apt-get update; apt-get install -y --no-install-recommends \
    git mercurial openssh-client subversion procps; rm -rf /var/lib/apt/lists/*
RUN set -eux; apt-get update; apt-get install -y --no-install-recommends \
    g++ gcc libc6-dev make pkg-config ; rm -rf /var/lib/apt/lists/*

ENV PATH=/usr/local/go/bin:$PATH
RUN set -eux; arch="$(dpkg --print-architecture)"; arch="${arch##*-}"; url=; \
    case "$arch" in \
    'amd64') url='https://dl.google.com/go/go1.14.linux-amd64.tar.gz'; \
    sha256='08df79b46b0adf498ea9f320a0f23d6ec59e9003660b4c9c1ce8e5e2c6f823ca'; ;; \
    'armel') export GOARCH='arm' GOARM='5' GOOS='linux'; ;; \
    'armhf') url='https://dl.google.com/go/go1.14.linux-armv6l.tar.gz'; \
    sha256='b5e682176d7ad3944404619a39b585453a740a2f82683e789f4279ec285b7ecd'; ;; \
    'arm64') url='https://dl.google.com/go/go1.14.linux-arm64.tar.gz'; \
    sha256='cd813387f770c07819912f8ff4b9796a4e317dee92548b7226a19e60ac79eb27'; ;; \
    'i386') url='https://dl.google.com/go/go1.14.linux-386.tar.gz'; \
    sha256='cdcdab6c8d1f2dcea3bbec793352ef84db167a2eb6c60ff69e5cf94dca575f9a'; ;; \
    'mips64el') export GOARCH='mips64le' GOOS='linux'; ;; \
    'ppc64el') url='https://dl.google.com/go/go1.14.linux-ppc64le.tar.gz'; \
    sha256='b896b5eba616d27fd3bb8218de6bef557cb62221e42f73c84ae4b89cdb602dec'; ;; \
    's390x') url='https://dl.google.com/go/go1.14.linux-s390x.tar.gz'; \
    sha256='22e67470fe872c893face196f02323a11ffe89999260c136b9c50f06619e0243'; ;; \
    *) echo >&2 "error: unsupported architecture '$arch' (likely packaging update needed)"; exit 1 ;; esac; \ 
    build=; if [ -z "$url" ]; then build=1; url='https://dl.google.com/go/go1.14.src.tar.gz'; \
    sha256='6d643e46ad565058c7a39dac01144172ef9bd476521f42148be59249e4b74389'; \
    echo >&2; echo >&2 "warning: current architecture ($arch) does not have a compatible Go binary release; \
    will be building from source"; echo >&2; fi; \
    wget -O go.tgz.asc "$url.asc"; wget -O go.tgz "$url" --progress=dot:giga; \
    echo "$sha256 *go.tgz" | sha256sum -c -; GNUPGHOME="$(mktemp -d)"; export GNUPGHOME; \
    curl -s 'https://dl.google.com/dl/linux/linux_signing_key.pub' | gpg --homedir "$GNUPGHOME" --import; \
    gpg --batch --verify go.tgz.asc go.tgz; gpgconf --kill all; rm -rf "$GNUPGHOME" go.tgz.asc; \
    tar -C /usr/local -xzf go.tgz; rm go.tgz;\
    if [ -n "$build" ]; then savedAptMark="$(apt-mark showmanual)"; \
    apt-get update; apt-get install -y --no-install-recommends golang-go; export GOCACHE='/tmp/gocache'; \
    (cd /usr/local/go/src; export GOROOT_BOOTSTRAP="$(go env GOROOT)" GOHOSTOS="$GOOS" GOHOSTARCH="$GOARCH"; ./make.bash;); \
    apt-mark auto '.*' > /dev/null; apt-mark manual $savedAptMark > /dev/null; \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; rm -rf /var/lib/apt/lists/*; \
    rm -rf /usr/local/go/pkg/*/cmd /usr/local/go/pkg/bootstrap /usr/local/go/pkg/obj /usr/local/go/pkg/tool/*/api; \
    rm -rf /usr/local/go/pkg/tool/*/go_bootstrap /usr/local/go/src/cmd/dist/dist "$GOCACHE" ; fi; \
    go version

ENV GOPATH=/go
ENV GO111MODULE=auto
ENV GOLANG_VERSION=1.14
ENV PATH=/go/bin:$PATH
RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"
WORKDIR /go

ARG INSTALL_ZSH=true
ARG UPGRADE_PACKAGES=true
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=1000

COPY library-scripts/*.sh /tmp/library-scripts/
RUN bash /tmp/library-scripts/common-debian.sh \
    "${INSTALL_ZSH}" "${USERNAME}" "${USER_UID}" "${USER_GID}" "${UPGRADE_PACKAGES}" "true" "true" \
    && apt-get clean -y && rm -rf /var/lib/apt/lists/*

RUN bash /tmp/library-scripts/go-debian.sh \
    "none" "/usr/local/go" "${GOPATH}" "${USERNAME}" "false"; apt-get clean -y && rm -rf /var/lib/apt/lists/*

ARG NODE_VERSION=none
ENV NVM_DIR=/usr/local/share/nvm
ENV NVM_SYMLINK_CURRENT=true
ENV PATH=/usr/local/share/nvm/current/bin:$PATH
RUN INSTALL_ZSH=true UPGRADE_PACKAGES=true USERNAME=vscode USER_UID=1000 USER_GID=1000 NODE_VERSION=none \
    bash /tmp/library-scripts/node-debian.sh "${NVM_DIR}" "${NODE_VERSION}" "${USERNAME}"; \
    apt-get clean -y; rm -rf /var/lib/apt/lists/*

RUN rm -rf /tmp/library-scripts
RUN groupadd docker; usermod -aG docker vscode || usermod -aG docker node
