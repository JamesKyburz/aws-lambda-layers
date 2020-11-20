#!/bin/sh

docker build -t node-14-sandbox-debugger .
docker run --rm node-14-sandbox-debugger cat /tmp/sandbox-debugger.zip > ./layer.zip
docker run --rm node-14-sandbox-debugger cat /tmp/sandbox-debugger-version > ./layer.version
