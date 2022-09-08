#!/bin/bash
set -e

docker run --rm -d -e PULSAR_PREFIX_transactionCoordinatorEnabled=true -p 8080:8080 -p 6650:6650 --name pulsar apachepulsar/pulsar:2.10.0 /bin/bash -c "/pulsar/bin/apply-config-from-env.py /pulsar/conf/standalone.conf && bin/pulsar standalone -nss"
sleep 15
docker exec -it pulsar bin/pulsar-admin tenants create mytenant
docker exec -it pulsar bin/pulsar-admin namespaces create mytenant/ns
docker exec -it pulsar bin/pulsar-admin topics create persistent://mytenant/ns/consumetopic
docker exec -it pulsar bin/pulsar-admin topics create persistent://mytenant/ns/producetopic
docker exec -it pulsar bin/pulsar-perf produce -m 50 --exit-on-failure -t 1  persistent://mytenant/ns/consumetopic
docker exec -it pulsar bin/pulsar-perf transaction --topics-c persistent://mytenant/ns/consumetopic --topics-p persistent://mytenant/ns/producetopic -threads 1 -ntxn 50 -ss testSub  -nmp 1 -nmc 1

docker exec -it pulsar bin/pulsar-client consume -s test -st auto_consume -p Earliest -n 100 persistent://public/default/__transaction_buffer_snapshot
docker exec -it pulsar bin/pulsar-admin topics unload persistent://mytenant/ns/producetopic



docker run -it \                                                              
    -p 9527:9527 -p 7750:7750 \
    -e SPRING_CONFIGURATION_FILE=/pulsar-manager/pulsar-manager/application.properties \
    --link pulsar \         
    apachepulsar/pulsar-manager:v0.2.0

