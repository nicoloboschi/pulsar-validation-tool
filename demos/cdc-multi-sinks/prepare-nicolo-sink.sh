#!/bin/bash
set -e

docker_cmd=""
file_path="/Users/nicolo.boschi/dev/pulsar-examples/java-sink/target/java-sink-1.0-SNAPSHOT.nar"


#docker_cmd="docker exec -it pulsar"
#file_path="/pulsar/nicolo-sink.nar"
#docker cp /Users/nicolo.boschi/dev/pulsar-examples/java-sink/target/java-sink-1.0-SNAPSHOT.nar pulsar:/pulsar/nicolo-sink.nar

$docker_cmd bin/pulsar-admin sinks delete --namespace default --tenant public --name nicolo-sink || echo ""
$docker_cmd bin/pulsar-admin sinks create -a $file_path \
     --tenant public \
     --namespace default \
     --name nicolo-sink \
     --inputs data-ks1.table1


echo "Sink uploaded"

docker exec -it pulsar cat logs/functions/public/default/nicolo-sink/nicolo-sink-0.log