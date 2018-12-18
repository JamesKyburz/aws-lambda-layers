#!/bin/sh

export NODE_VERSION=10.14.2

docker build --build-arg NODE_VERSION -t node-custom-runtime:${NODE_VERSION} .
docker run --rm node-custom-runtime:${NODE_VERSION} cat /tmp/node-v${NODE_VERSION}.zip > ./layer.zip
