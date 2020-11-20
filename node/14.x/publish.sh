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
  log_error "Missing node version as first parameter"
  exit 1
fi

if [[ -z $2 ]]; then
  log_error "Missing region(s) as second parameter (multiple regions delimited by a space)"
  exit 1
fi

set -u

export NODE_VERSION="${1:?}"
export REGIONS="${2:?}"

export NODE_MAJOR_VERSION=$(echo ${NODE_VERSION:?} | cut -d '.' -f1)

log_info "Building custom node ${NODE_VERSION:?} runtime"
docker build --no-cache --build-arg NODE_VERSION -t node-custom-runtime:${NODE_VERSION:?} https://github.com/JamesKyburz/aws-lambda-layers.git#:node/14.x
docker run --rm node-custom-runtime:${NODE_VERSION:?} cat /tmp/node-v${NODE_VERSION:?}.zip >./layer.zip
log_success "Built custom node ${NODE_VERSION:?} runtime"

log_info "Publishing runtimes"

for region in ${REGIONS:?}; do
  log_info "Publishing to region ${region:?}"
  aws lambda publish-layer-version \
    --region ${region:?} \
    --layer-name "nodejs-${NODE_MAJOR_VERSION:?}" \
    --zip-file fileb://layer.zip \
    --description "Node.js v${NODE_VERSION:?} custom runtime" \
    --compatible-runtimes nodejs14.x \
    --license-info "Apache-2.0" \
    --query 'LayerVersionArn' \
    --output text &
done

wait

rm -f layer.zip

log_success "Publish complete"
