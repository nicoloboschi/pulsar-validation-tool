#!/bin/bash
set -e

set -e 
# https://dist.apache.org/repos/dist/dev/pulsar/pulsar-client-python-3.1.0-candidate-3/macos/pulsar_client-3.1.0-cp310-cp310-macosx_10_15_universal2.whl
WHEEL_URL=$1
if [[ -z "$WHEEL_URL" ]]; then 
    echo "No wheel specified, exiting"
    exit 1
fi

echo "version $WHEEL_URL"

python3 -m pip install $WHEEL_URL
python3 ./test.py