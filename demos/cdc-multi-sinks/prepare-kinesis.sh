#!/bin/bash
set -e

docker exec -it kinesis awslocal kinesis create-stream --stream-name pulsar-stream --shard-count 1 || echo "Stream already exists"
echo "Stream created"

docker exec -it pulsar bin/pulsar-admin sinks delete --namespace default --tenant public --name kinesis-sink || echo ""
docker exec -it pulsar bin/pulsar-admin sinks create --namespace default --tenant public \
    --sink-type kinesis \
    --inputs input-topic \
    --name kinesis-sink \
    --sink-config '{"awsKinesisStreamName": "pulsar-stream", "awsRegion": "us-east-1", "awsCredentialPluginParam": "{\"accessKey\":\"accesskey\",\"secretKey\":\"accesskey\"}", "messageFormat": "FULL_MESSAGE_IN_JSON_EXPAND_VALUE", "awsEndpoint": "kinesis", "awsEndpointPort": 4566, "skipCertificateValidation": true }' \
    --parallelism 1

echo "Sink uploaded"

docker exec -it pulsar bin/pulsar-admin sinks update --namespace default --tenant public \
    --name kinesis-sink \
    --sink-config '{"awsKinesisStreamName": "pulsar-stream", "awsRegion": "us-east-1", "awsCredentialPluginParam": "{\"accessKey\":\"accesskey\",\"secretKey\":\"secretkey\"}", "messageFormat": "FULL_MESSAGE_IN_JSON_EXPAND_VALUE", "awsEndpoint": "kinesis-service", "awsEndpointPort": 4566, "skipCertificateValidation": true }' \
