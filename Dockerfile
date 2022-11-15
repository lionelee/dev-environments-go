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
    'amd64') url='https://dl.google.com/go/go1.16.linux-amd64.tar.gz'; \
    sha256='013a489ebb3e24ef3d915abe5b94c3286c070dfe0818d5bca8108f1d6e8440d2'; ;; \
    'armel') export GOARCH='arm' GOARM='5' GOOS='linux'; ;; \
    'armhf') url='https://dl.google.com/go/go1.16.linux-armv6l.tar.gz'; \
    sha256='d1d9404b1dbd77afa2bdc70934e10fbfcf7d785c372efc29462bb7d83d0a32fd'; ;; \
    'arm64') url='https://dl.google.com/go/go1.16.linux-arm64.tar.gz'; \
    sha256='3770f7eb22d05e25fbee8fb53c2a4e897da043eb83c69b9a14f8d98562cd8098'; ;; \
    'i386') url='https://dl.google.com/go/go1.16.linux-386.tar.gz'; \
    sha256='ea435a1ac6d497b03e367fdfb74b33e961d813883468080f6e239b3b03bea6aa'; ;; \
    'mips64el') export GOARCH='mips64le' GOOS='linux'; ;; \
    'ppc64el') url='https://dl.google.com/go/go1.16.linux-ppc64le.tar.gz'; \
    sha256='27a1aaa988e930b7932ce459c8a63ad5b3333b3a06b016d87ff289f2a11aacd6'; ;; \
    's390x') url='https://dl.google.com/go/go1.16.linux-s390x.tar.gz'; \
    sha256='be4c9e4e2cf058efc4e3eb013a760cb989ddc4362f111950c990d1c63b27ccbe'; ;; \
    *) echo >&2 "error: unsupported architecture '$arch' (likely packaging update needed)"; exit 1 ;; esac; \ 
    build=; if [ -z "$url" ]; then build=1; url='https://dl.google.com/go/go1.16.src.tar.gz'; \
    sha256='7688063d55656105898f323d90a79a39c378d86fe89ae192eb3b7fc46347c95a'; \
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
ENV GOLANG_VERSION=1.16
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
