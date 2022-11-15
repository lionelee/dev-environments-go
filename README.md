# Golang Dev Environemts for Docker

[![CD status](https://github.com/lionelee/dev-environments-go/actions/workflows/cd.yml/badge.svg?branch=1.13)](https://github.com/lionelee/dev-environments-go/actions/workflows/cd.yml)


This repo is used to build base image for golang dev environments in Docker Desktop. This branch corresponds to golang version 1.13.

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

# License
Copyright (c) Lionel Lee. All rights reserved.

Licensed under the MIT License. See [LICENSE](https://github.com/lionelee/dev-environments-go/blob/master/LICENSE).
