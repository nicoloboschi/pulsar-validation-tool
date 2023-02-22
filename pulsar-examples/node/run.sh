#!/bin/bash
set -e 
NEW_VERSION=$1
if [[ -z "$NEW_VERSION" ]]; then 
    echo "No version specified, exiting"
    exit 1
fi

echo "version $NEW_VERSION"

# For < 1.8
# brew install libpulsar
# export PULSAR_CPP_DIR=/usr/local/Cellar/libpulsar/3.1.2 
cd astra-streaming
if [[ "$NEW_VERSION" == *"rc"* ]]; then
    npm i pulsar-client@$NEW_VERSION --pulsar_binary_host_mirror=https://dist.apache.org/repos/dist/dev/pulsar/pulsar-client-node/
else
    npm i pulsar-client@$NEW_VERSION
fi

#pulsar-shell -np -e "admin topics create $AS_TOPIC" 
node produce.js

