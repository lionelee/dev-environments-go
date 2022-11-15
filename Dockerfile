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
    'amd64') url='https://dl.google.com/go/go1.17.linux-amd64.tar.gz'; \
    sha256='6bf89fc4f5ad763871cf7eac80a2d594492de7a818303283f1366a7f6a30372d'; ;; \
    'armel') export GOARCH='arm' GOARM='5' GOOS='linux'; ;; \
    'armhf') url='https://dl.google.com/go/go1.17.linux-armv6l.tar.gz'; \
    sha256='ae89d33f4e4acc222bdb04331933d5ece4ae71039812f6ccd7493cb3e8ddfb4e'; ;; \
    'arm64') url='https://dl.google.com/go/go1.17.linux-arm64.tar.gz'; \
    sha256='01a9af009ada22122d3fcb9816049c1d21842524b38ef5d5a0e2ee4b26d7c3e7'; ;; \
    'i386') url='https://dl.google.com/go/go1.17.linux-386.tar.gz'; \
    sha256='c19e3227a6ac6329db91d1af77bbf239ccd760a259c16e6b9c932d527ff14848'; ;; \
    'mips64el') export GOARCH='mips64le' GOOS='linux'; ;; \
    'ppc64el') url='https://dl.google.com/go/go1.17.linux-ppc64le.tar.gz'; \
    sha256='ee84350114d532bf15f096198c675aafae9ff091dc4cc69eb49e1817ff94dbd7'; ;; \
    's390x') url='https://dl.google.com/go/go1.17.linux-s390x.tar.gz'; \
    sha256='a50aaecf054f393575f969a9105d5c6864dd91afc5287d772449033fbafcf7e3'; ;; \
    *) echo >&2 "error: unsupported architecture '$arch' (likely packaging update needed)"; exit 1 ;; esac; \ 
    build=; if [ -z "$url" ]; then build=1; url='https://dl.google.com/go/go1.17.src.tar.gz'; \
    sha256='3a70e5055509f347c0fb831ca07a2bf3b531068f349b14a3c652e9b5b67beb5d'; \
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
ENV GOLANG_VERSION=7
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
