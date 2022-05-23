#!/bin/bash
set -e

docker exec -it kinesis awslocal kinesis list-shards --stream-name pulsar-stream
docker exec -it kinesis awslocal kinesis get-shard-iterator --stream-name pulsar-stream --shard-id  shardId-000000000000 --shard-iterator-type TRIM_HORIZON
docker exec -it kinesis awslocal kinesis get-records --shard-iterator AAAAAAAAAAGkQ24+110yglJ8eH21CIZxRwT+z3WyoORy9f+z2EigNyKnzMCDKrlNq8SSHmUM99DQ59Ro/J/2qfkmfZ2iLVMcHwGOwjfWxq6SF2o3F224dS/w+NpP/BIYmR5VfYyxTHFIxKG66cBlVT6ERj6Yk8eIqRadMGu99xInZWkl7dT6JD4nZdydv253vBeK+kJRRMrF2zd52Z1RDgNpS6vBatOl
