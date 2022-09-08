#!/bin/bash
set -e

#docker exec -it pulsar curl -f -L --output pulsar-io-cloud-storage.nar  https://github.com/streamnative/pulsar-io-cloud-storage/releases/download/v2.10.0.4/pulsar-io-cloud-storage-2.10.0.4.nar         
#docker exec -it pulsar curl -f -L --output pulsar-io-cloud-storage.nar  https://github.com/streamnative/pulsar-io-cloud-storage/releases/download/v2.8.3.3/pulsar-io-cloud-storage-2.8.3.3.nar


name=gcs-sink
docker exec -it pulsar bin/pulsar-admin sinks delete --namespace default --tenant public --name $name || echo ""
# GCP
docker exec -it pulsar bin/pulsar-admin sinks create --namespace default --tenant public \
    --archive ./pulsar-io-cloud-storage.nar \
    --inputs input-topic \
    --name $name \
    --sink-config '{"provider": "google-cloud-storage", "bucket": "nicolo-gcs-connector", "formatType": "json", "partitionerType": "default", "gcsServiceAccountKeyFileContent": "{}" }'

# AWS
docker exec -it pulsar bin/pulsar-admin sinks create --namespace default --tenant public \
    --archive ./pulsar-io-cloud-storage.nar \
    --inputs input-topic \
    --name $name \
    --sink-config '{"provider": "aws-s3", "accessKeyId": "", "secretAccessKey": "+eNulLI5LJ7D/4gmWM8Za", "endpoint": "https://nicolotestbucket.s3.us-east-1.amazonaws.com", "bucket": "nicolotestbucket", "formatType": "json", "partitionerType": "default"}'




docker exec -it pulsar cat logs/functions/public/default/${name}/${name}-0.log








