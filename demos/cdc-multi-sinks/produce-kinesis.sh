#!/bin/bash
set -e
times=${1:-1}

for i in $(seq $times); do
    id=$(date)   
    docker exec -it kinesis awslocal kinesis put-records --stream-name pulsar-stream --records Data=blob1,PartitionKey=partitionkey1 Data=blob2,PartitionKey=partitionkey2
done
