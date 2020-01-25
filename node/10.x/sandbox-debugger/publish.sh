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
  log_error "Missing sandbox-debugger version as first parameter (latest is valid)"
  exit 1
fi

if [[ -z $2 ]]; then
  log_error "Missing region(s) as second parameter (multiple regions delimited by a space)"
  exit 1
fi

set -u

export SANDBOX_DEBUGGER_VERSION=${1:?}
export REGIONS=${2:?}

log_info "Building sandbox-debugger@${SANDBOX_DEBUGGER_VERSION:?} layer"

docker build --no-cache --build-arg SANDBOX_DEBUGGER_VERSION -t node-sandbox-debugger https://github.com/JamesKyburz/aws-lambda-layers.git#:node/10.x/sandbox-debugger
docker run --rm node-sandbox-debugger cat /tmp/sandbox-debugger.zip >./layer.zip
version=$(docker run --rm node-sandbox-debugger cat /tmp/sandbox-debugger-version)

log_success "Built sandbox-debugger@${version:?} layer"

log_info "Publishing layers"

for region in ${REGIONS:?}; do
  aws lambda publish-layer-version \
    --region ${region:?} \
    --layer-name "sandbox-debugger-nodejs10" \
    --zip-file fileb://layer.zip \
    --description "Node.js sandbox-debugger@${version:?}" \
    --compatible-runtimes nodejs10.x \
    --license-info "Apache-2.0" \
    --query 'LayerVersionArn' \
    --output text &
done

wait

rm -f layer.zip

log_success "Publish complete"
