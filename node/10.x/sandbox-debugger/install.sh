#!/bin/sh

set -e
. /root/.nvm/nvm.sh
nvm use 10
export NPM_CONFIG_LOGLEVEL=error
cd /tmp
npm init -y > /dev/null
npm i sandbox-debugger@${SANDBOX_DEBUGGER_VERSION:?}
node-prune node_modules
npx modclean -r
npm ls sandbox-debugger --depth=0 | tail -n +2 | cut -d '@' -f2 | tr --delete '\n ' > /tmp/sandbox-debugger-version
mkdir -p nodejs/node10
mv node_modules nodejs/node10/node_modules
zip -yr /tmp/sandbox-debugger.zip ./nodejs/
