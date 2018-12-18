#!/bin/sh

docker build -t node-10-aws-sdk .
docker run --rm node-10-aws-sdk cat /tmp/aws-sdk.zip > ./layer.zip
docker run --rm node-10-aws-sdk cat /tmp/aws-sdk-version > ./layer.version
