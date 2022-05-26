#!/bin/bash
set -e

docker exec -it postgres psql -U postgres -c 'create table if not exists pulsar_table (id VARCHAR(255) PRIMARY KEY, value VARCHAR(255) NULL);' postgres
echo "Table created"


docker exec -it pulsar bin/pulsar-admin sinks delete --namespace default --tenant public --name jdbc-sink || echo ""
#--sink-type jdbc-postgres \
docker cp /Users/nicolo.boschi/dev/pulsar/pulsar-io/jdbc/postgres/target/pulsar-io-jdbc-postgres-2.11.0-SNAPSHOT.nar pulsar:/pulsar/connectors/pulsar-io-jdbc-postgres-2.10.0.2.nar

docker exec -it pulsar bin/pulsar-admin sinks create --namespace default --tenant public \
    --archive "/pulsar/connectors/pulsar-io-jdbc-postgres-2.10.0.2.nar" \
    --inputs input-topic \
    --name jdbc-sink \
    --sink-config '{"userName": "postgres", "password": "password", "jdbcUrl": "jdbc:postgresql://postgres:5432/postgres", "tableName": "pulsar_table" }' \
    --parallelism 1

echo "Sink uploaded"