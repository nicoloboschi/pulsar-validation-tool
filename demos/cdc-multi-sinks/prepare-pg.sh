#!/bin/bash
set -e

docker exec -it postgres psql -U postgres -c 'create table if not exists pulsar_table (id VARCHAR(255) PRIMARY KEY);' postgres
echo "Table created"

docker exec -it pulsar bin/pulsar-admin sinks delete --namespace default --tenant public --name jdbc-sink || echo ""
docker exec -it pulsar bin/pulsar-admin sinks create --namespace default --tenant public \
    --sink-type jdbc-postgres \
    --inputs input-topic \
    --name jdbc-sink \
    --sink-config '{"userName": "postgres", "password": "password", "jdbcUrl": "jdbc:postgresql://postgres:5432/postgres", "tableName": "pulsar_table" }' \
    --parallelism 1

echo "Sink uploaded"