#!/bin/bash
set -e

set -e 
NEW_VERSION=$1
if [[ -z "$NEW_VERSION" ]]; then 
    echo "No version specified, exiting"
    exit 1
fi

echo "version $NEW_VERSION"


python3 -m pip install pulsar-client==3.0.0
python3 ./test.py