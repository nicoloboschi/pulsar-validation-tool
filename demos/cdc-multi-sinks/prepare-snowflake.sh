#!/bin/bash
set -e


docker exec -it pulsar rm -rf logs/functions/public/default/snowflake-sink/snowflake-sink-0.log
docker cp snowflake-conf.yaml pulsar:/pulsar/snowflake-conf.yaml
docker cp /Users/nicolo.boschi/dev/snowflake-connector/pulsar-snowflake-connector/target/pulsar-snowflake-connector-0.1.10-SNAPSHOT.nar pulsar:/pulsar/connectors/pulsar-snowflake-connector-0.1.9.nar
docker exec -it pulsar bin/pulsar-admin sinks delete --namespace default --tenant public --name snowflake-sink || echo ""
docker exec -it pulsar bin/pulsar-admin sinks create --sink-config-file /pulsar/snowflake-conf.yaml \
     --sink-type snowflake \
     --name snowflake-sink \
     --inputs data-ks1.table1


echo "Sink uploaded"

docker exec -it pulsar cat logs/functions/public/default/snowflake-sink/snowflake-sink-0.log