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
    'amd64') url='https://dl.google.com/go/go1.15.linux-amd64.tar.gz'; \
    sha256='2d75848ac606061efe52a8068d0e647b35ce487a15bb52272c427df485193602'; ;; \
    'armel') export GOARCH='arm' GOARM='5' GOOS='linux'; ;; \
    'armhf') url='https://dl.google.com/go/go1.15.linux-armv6l.tar.gz'; \
    sha256='6d8914ddd25f85f2377c269ccfb359acf53adf71a42cdbf53434a7c76fa7a9bd'; ;; \
    'arm64') url='https://dl.google.com/go/go1.15.linux-arm64.tar.gz'; \
    sha256='7e18d92f61ddf480a4f9a57db09389ae7b9dadf68470d0cb9c00d734a0c57f8d'; ;; \
    'i386') url='https://dl.google.com/go/go1.15.linux-386.tar.gz'; \
    sha256='68ce979083126694ceef60233f69efe870f54af24d81a120f76265107a9e9aab'; ;; \
    'mips64el') export GOARCH='mips64le' GOOS='linux'; ;; \
    'ppc64el') url='https://dl.google.com/go/go1.15.linux-ppc64le.tar.gz'; \
    sha256='4603736a158b3d8ac52b9245f39bf715936c801e05bb5ad7c44b1edd6d5ef6a2'; ;; \
    's390x') url='https://dl.google.com/go/go1.15.linux-s390x.tar.gz'; \
    sha256='8825f93caaf87465e32f298408c48b98d4180f3ddb885bd027f2926e711d23e8'; ;; \
    *) echo >&2 "error: unsupported architecture '$arch' (likely packaging update needed)"; exit 1 ;; esac; \ 
    build=; if [ -z "$url" ]; then build=1; url='https://dl.google.com/go/go1.15.src.tar.gz'; \
    sha256='69438f7ed4f532154ffaf878f3dfd83747e7a00b70b3556eddabf7aaee28ac3a'; \
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
ENV GOLANG_VERSION=1.15
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
