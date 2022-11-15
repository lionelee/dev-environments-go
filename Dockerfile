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
    'amd64') url='https://dl.google.com/go/go1.13.linux-amd64.tar.gz'; \
    sha256='68a2297eb099d1a76097905a2ce334e3155004ec08cdea85f24527be3c48e856'; ;; \
    'armel') export GOARCH='arm' GOARM='5' GOOS='linux'; ;; \
    'armhf') url='https://dl.google.com/go/go1.13.linux-armv6l.tar.gz'; \
    sha256='931906d67cae1222f501e7be26e0ee73ba89420be0c4591925901cb9a4e156f0'; ;; \
    'arm64') url='https://dl.google.com/go/go1.13.linux-arm64.tar.gz'; \
    sha256='e2a61328101eff3b9c1ba47ecfec5eb2fdc3eb35d8c27d505737ba98bfcb197b'; ;; \
    'i386') url='https://dl.google.com/go/go1.13.linux-386.tar.gz'; \
    sha256='519b3e6ae4db011b93b60e6fabb055773ae6448355b6909a6befef87e02d98f5'; ;; \
    'mips64el') export GOARCH='mips64le' GOOS='linux'; ;; \
    'ppc64el') url='https://dl.google.com/go/go1.13.linux-ppc64le.tar.gz'; \
    sha256='807b036bb058061b6090635e2a8612aaf301895dce70a773bbcd67fa1e57337c'; ;; \
    's390x') url='https://dl.google.com/go/go1.13.linux-s390x.tar.gz'; \
    sha256='b7122795910b70b68e4118d0d34685a30925f4dd861c065cf20b699a7783807a'; ;; \
    *) echo >&2 "error: unsupported architecture '$arch' (likely packaging update needed)"; exit 1 ;; esac; \ 
    build=; if [ -z "$url" ]; then build=1; url='https://dl.google.com/go/go1.13.src.tar.gz'; \
    sha256='3fc0b8b6101d42efd7da1da3029c0a13f22079c0c37ef9730209d8ec665bf122'; \
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
ENV GOLANG_VERSION=1.13
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
