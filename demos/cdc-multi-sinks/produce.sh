#!/bin/bash
set -e
times=${1:-1}

for i in $(seq $times); do
    id=$(date)   
    docker cp ./json-message.json pulsar:/message.json
    docker exec -it pulsar ./bin/pulsar-client produce -f /message.json -vs "json:{\"type\": \"record\",\"namespace\": \"com.example\",\"name\": \"FullName\", \"fields\": [{ \"name\": \"id\", \"type\": \"string\" }, { \"name\": \"value\", \"type\": \"string\" }]}" input-topic
done
