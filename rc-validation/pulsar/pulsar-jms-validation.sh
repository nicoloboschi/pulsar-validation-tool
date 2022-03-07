#!/bin/bash
set -e
PULSAR_JMS_DIR=$1
PULSAR_VERSION=$2
PULSAR_DOCKER_IMAGE=${3:-apachepulsar/pulsar:$PULSAR_VERSION}
echo "PULSAR_VERSION: $PULSAR_VERSION, PULSAR_DOCKER_IMAGE: $PULSAR_DOCKER_IMAGE"

if [[ -z "$PULSAR_JMS_DIR" ]]; then
    echo "PULSAR_JMS_DIR not set"
    exit 1
fi
if [[ -z "$PULSAR_VERSION" ]]; then
    echo "PULSAR_VERSION not set"
    exit 1
fi

cd $PULSAR_JMS_DIR
git checkout master
git pull --rebase

mvn clean install -DskipTests -Dpulsar.version="$PULSAR_VERSION"
mvn test -pl pulsar-jms-integration-tests -Dpulsar.version="$PULSAR_VERSION" -DtestPulsarDockerImageName="$PULSAR_DOCKER_IMAGE" -Dtest='DockerTest#testGenericPulsar,DockerTest#testGenericPulsarTransactions'
mvn test -pl resource-adapter-tests -Dpulsar.version="$PULSAR_VERSION" -DtestResourceAdapterPulsarDockerImageName="$PULSAR_DOCKER_IMAGE"

export PULSAR_IMAGE_NAME="$PULSAR_DOCKER_IMAGE"
mvn test -pl tck-executor -Prun-tck -Dpulsar.version="$PULSAR_VERSION"

