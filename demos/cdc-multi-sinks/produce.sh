#!/bin/bash
set -e




id=$(date)


docker exec -it pulsar ./bin/pulsar-client produce -m "{\"id\":\"${id}\"}" -vs "json:{\"type\": \"record\",\"namespace\": \"com.example\",\"name\": \"FullName\", \"fields\": [{ \"name\": \"id\", \"type\": \"string\" }]}" input-topic
