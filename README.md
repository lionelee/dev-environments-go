# Golang Dev Environemts for Docker

[![CD status](https://github.com/lionelee/dev-environments-go/actions/workflows/cd.yml/badge.svg?branch=1.16)](https://github.com/lionelee/dev-environments-go/actions/workflows/cd.yml)
[![Docker Hub](https://img.shields.io/badge/docker_hub-dev--environments--go-blue?labelColor=31373F&logo=docker&logoColor=lightgrey)](https://hub.docker.com/repository/docker/lionelee/dev-environments-go)


This repo is used to build base image for golang dev environments in Docker Desktop. This branch corresponds to golang version 1.16.

### Get Started
create file `compose-dev.yaml` in your project directory:
``` bash
cat << EOF >> compose-dev.yaml
services:
  app:
    entrypoint:
    - sleep
    - infinity
    image: lionelee/dev-environments-go:{version you want}
    init: true
    volumes:
    - type: bind
      source: /var/run/docker.sock
      target: /var/run/docker.sock
EOF
```

then, create a docker dev environments by following steps in the doc:
https://docs.docker.com/desktop/dev-environments/create-dev-env/

### Build on Your Own
clone this branch, and build the image:
``` bash
$ git clone -b 1.16 https://github.com/lionelee/dev-environments-go.git
$ cd dev-environments-go
$ docker buildx build --platform=linux/arm64,linux/amd64 --push -t {your tag} .
```

# License
Copyright (c) Lionel Lee. All rights reserved.

Licensed under the MIT License. See [LICENSE](https://github.com/lionelee/dev-environments-go/blob/master/LICENSE).
