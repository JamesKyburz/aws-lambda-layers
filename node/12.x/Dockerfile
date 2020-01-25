FROM amazonlinux:2.0.20190228

LABEL maintainer="James Kyburz james.kyburz@gmail.com"

ARG NODE_VERSION

RUN yum install -y zip curl git git-core tar

RUN \
  curl -sSL https://nodejs.org/dist/v${NODE_VERSION:?}/node-v${NODE_VERSION:?}-linux-x64.tar.xz | \
  tar -xJ -C /opt --strip-components 1 -- node-v${NODE_VERSION:?}-linux-x64/bin/node && \
  strip /opt/bin/node

COPY bootstrap bootstrap.js /opt/

RUN \
  cd /opt && \
  zip -yr /tmp/node-v${NODE_VERSION:?}.zip ./*
