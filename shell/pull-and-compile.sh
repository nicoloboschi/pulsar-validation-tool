#!/bin/bash
set -e 

git clone https://github.com/apache/pulsar --depth 1 --branch $1 pulsar-check
cd pulsar-check
mvn clean install -DskipTests -Dcheckstyle.skip -Dspotbugs.skip -T 1C
