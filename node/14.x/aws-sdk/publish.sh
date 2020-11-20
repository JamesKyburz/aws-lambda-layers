#!/bin/bash

set -eo pipefail

log_success() {
  local cs_color_reset="\033[0m"
  local cs_color_green="\033[1;92m"
  echo -e "${cs_color_reset:?}${cs_color_green:?}${*:1}${cs_color_reset:?}"
}

log_info() {
  local cs_color_reset="\033[0m"
  local cs_color_blue="\033[1;94m"
  echo -e "${cs_color_reset:?}${cs_color_blue:?}${*:1}${cs_color_reset:?}"
}

log_error() {
  local cs_color_reset="\033[0m"
  local cs_color_red="\033[1;91m"
  echo -e "${cs_color_reset:?}${cs_color_red:?}${*:1}${cs_color_reset:?}"
}

if [[ -z $AWS_SECRET_ACCESS_KEY ]]; then
  log_error "AWS_SECRET_ACCESS_KEY is missing"
  exit
fi

if [[ -z $AWS_ACCESS_KEY_ID ]]; then
  log_error "AWS_ACCESS_KEY_ID is missing"
  exit
fi

if [[ -z $1 ]]; then
  log_error "Missing aws-sdk version as first parameter (latest is valid)"
  exit 1
fi

if [[ -z $2 ]]; then
  log_error "Missing region(s) as second parameter (multiple regions delimited by a space)"
  exit 1
fi

set -u

export AWS_SDK_VERSION=${1:?}
export REGIONS=${2:?}

log_info "Building aws-sdk@${AWS_SDK_VERSION:?} layer"

docker build --no-cache --build-arg AWS_SDK_VERSION -t node-aws-sdk https://github.com/JamesKyburz/aws-lambda-layers.git#:node/14.x/aws-sdk
docker run --rm node-aws-sdk cat /tmp/aws-sdk.zip >./layer.zip
version=$(docker run --rm node-aws-sdk cat /tmp/aws-sdk-version)

log_success "Built aws-sdk@${version:?} layer"

log_info "Publishing layers"

for region in ${REGIONS:?}; do
  aws lambda publish-layer-version \
    --region ${region:?} \
    --layer-name "aws-sdk-nodejs14" \
    --zip-file fileb://layer.zip \
    --description "Node.js aws-sdk@${version:?}" \
    --compatible-runtimes nodejs14.x \
    --license-info "Apache-2.0" \
    --query 'LayerVersionArn' \
    --output text &
done

wait

rm -f layer.zip

log_success "Publish complete"
