#!/bin/sh

docker build -t node-12-sandbox-debugger .
docker run --rm node-12-sandbox-debugger cat /tmp/sandbox-debugger.zip > ./layer.zip
docker run --rm node-12-sandbox-debugger cat /tmp/sandbox-debugger-version > ./layer.version
