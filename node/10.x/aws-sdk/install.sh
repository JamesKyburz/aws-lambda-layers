#!/bin/sh

set -e
. /root/.nvm/nvm.sh
nvm use 10
export NPM_CONFIG_LOGLEVEL=error
cd /tmp
npm init -y > /dev/null
npm i aws-sdk@${AWS_SDK_VERSION:?}
node-prune node_modules
npx modclean -r
npm ls aws-sdk --depth=0 | tail -n +2 | cut -d '@' -f2 | tr --delete '\n ' > /tmp/aws-sdk-version
mkdir -p nodejs/node10
mv node_modules nodejs/node10/node_modules
zip -yr /tmp/aws-sdk.zip ./nodejs/
