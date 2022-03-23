#!/bin/bash

# docker run -v $HOME/dev/localscripts/pulsar-image-validation/simple-produce-consume.sh:/test.sh --rm -it  184aff6b0972 /bin/bash -c /test.sh
set -ex

chmod +x /pulsar/bin/apply-config-from-env.py || echo "skip chmod +x"
/pulsar/bin/apply-config-from-env.py /pulsar/conf/client.conf
until $(curl -s --output /dev/null  --fail ${webServiceUrl}admin/v3/sink/public/default); do
    sleep 5
done

/pulsar/bin/pulsar-client produce public/default/test -m "hello"
/pulsar/bin/pulsar-client consume -s sub -p Earliest public/default/test
