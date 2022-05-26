#!/bin/bash
set -e

shardid=$(docker exec -it kinesis awslocal kinesis list-shards --stream-name pulsar-stream | grep 'ShardId' | sed -r 's/^[^:]*:(.*)$/\1/'  | tr -d ',|\"| |\r|\n')
iterator=$(docker exec -it kinesis awslocal kinesis get-shard-iterator --stream-name pulsar-stream --shard-id $shardid --shard-iterator-type TRIM_HORIZON | grep 'ShardIterator' | sed -r 's/^[^:]*:(.*)$/\1/'  | tr -d ',|\"| |\r|\n')
result=$(docker exec -it kinesis awslocal kinesis get-records --shard-iterator $iterator)
count=$(echo "$result" | grep "Data" | wc -l | tr -d ' ')
echo "count is $count"

echo "$result" | grep "Data" | sed -r 's/^[^:]*:(.*)$/\1/'  | tr -d ',|\"| ' | while read data; do 
    decoded=$(echo "$data" | base64 --decode)
    if [[ "$decoded" != *"\"payload\":{\"id\":"* ]]; then 
        echo "found invalid record: $decoded"
        exit 1
    fi
done

    
