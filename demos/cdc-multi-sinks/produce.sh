#!/bin/bash
set -e
times=${1:-1}

docker cp ./json-message.json pulsar:/message.json
docker exec -it pulsar ./bin/pulsar-client produce -f /message.json -n $times -vs "json:{\"type\": \"record\",\"namespace\": \"com.example\",\"name\": \"FullName\", \"fields\": [{ \"name\": \"id\", \"type\": \"string\" }, { \"name\": \"value\", \"type\": \"string\" }]}" input-topic

