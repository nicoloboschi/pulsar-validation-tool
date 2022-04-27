#!/bin/bash

# docker run -v $HOME/dev/localscripts/pulsar-image-validation/simple-produce-consume.sh:/test.sh --rm -it  184aff6b0972 /bin/bash -c /test.sh
set -ex

apt-get update
apt-get install -y curl

count="0"
while [[ "$count" != "1000" ]] 
do
    
    count=$(curl -s -u "elastic:elastic" "http://$HOSTNAME_ELASTIC:9200/myindex/_count?q=myfield:789&pretty" | grep 'count' | sed -r 's/^[^:]*:(.*)$/\1/' | tr -d ',|\"| ')
    echo "Counting 'myfield' field: $count"
    sleep 5
done