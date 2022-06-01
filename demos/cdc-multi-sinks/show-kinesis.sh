#!/bin/bash
set -e

total_count=0

docker_cmd="docker exec -it kinesis"


shardid=$($docker_cmd awslocal kinesis list-shards --stream-name pulsar-stream | grep 'ShardId' | sed -r 's/^[^:]*:(.*)$/\1/'  | tr -d ',|\"| |\r|\n')
function read_iterator_and_count() {
    
    local it=$1
    if [[ -z "$it" ]]; then
        it=$($docker_cmd awslocal kinesis get-shard-iterator --stream-name pulsar-stream --shard-id $shardid --shard-iterator-type TRIM_HORIZON | grep 'ShardIterator' | sed -r 's/^[^:]*:(.*)$/\1/'  | tr -d ',|\"| |\r|\n')
    fi

    result=$($docker_cmd awslocal kinesis get-records --shard-iterator "$it")
    count=$(echo "$result" | grep "Data" | wc -l | tr -d ' ')
    echo "partial count is $count"
    if [[ -n "$count" ]]; then
        total_count=$((total_count + count))
    fi
    millis_behind_latest=$(echo "$result" | grep "MillisBehindLatest" | sed -r 's/^[^:]*:(.*)$/\1/'  | tr -d ',|\"| |\r|\n')
    if [[ "$millis_behind_latest" != "0" ]]; then
        next_iterator=$(echo "$result" | grep "NextShardIterator" | sed -r 's/^[^:]*:(.*)$/\1/'  | tr -d ',|\"| |\r|\n')
        echo "next_iterator: $next_iterator"
        if [[ -n "$next_iterator" ]]; then
            read_iterator_and_count $next_iterator
        fi
    fi
}

read_iterator_and_count
echo "total: $total_count"

