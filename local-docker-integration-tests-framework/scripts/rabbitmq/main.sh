#!/bin/bash
set -ex

echo "<settings><profiles><profile><id>skip-apache-repo</id><repositories><repository><id>apache.snapshots</id><url>https://repository.apache.org</url><releases><enabled>false</enabled></releases><snapshots><enabled>false</enabled></snapshots></repository></repositories></profile></profiles></settings>" > /pulsar/settings.xml

mkdir rabbit-client-lib

curl -sL --output maven.tar.gz https://dlcdn.apache.org/maven/maven-3/3.8.3/binaries/apache-maven-3.8.3-bin.tar.gz
tar xzvf maven.tar.gz

curl -sL --output rabbit.zip https://github.com/nicoloboschi/pulsar-rabbitmq-gw/archive/refs/heads/tests/use-ext-pulsar.zip
unzip rabbit.zip
cd pulsar-rabbitmq-gw-*


M2_HOME_HOST=${M2_HOME_HOST:-/pulsar/m2}

../apache-maven-3.8.3/bin/mvn -B install -Dmaven.repo.local=$M2_HOME_HOST -DskipTests -Dassembly.skipAssembly=true -Pskip-apache-repo --settings /pulsar/settings.xml
../apache-maven-3.8.3/bin/mvn -f rabbitmq-tests integration-test failsafe:verify --settings /pulsar/settings.xml \
    -Pskip-apache-repo -Dmaven.repo.local=$M2_HOME_HOST  -Dgroups=com.datastax.oss.starlight.rabbitmqtests.SystemTest \
    -Dtests.systemtests.enabled=true -Dtests.systemtests.pulsar.host=$HOSTNAME_PULSAR


