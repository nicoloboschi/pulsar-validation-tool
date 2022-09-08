#!/bin/bash
set -e


here=$(pwd)
cd ~/dev/luna283
mvnd clean install -pl pulsar-io/kafka-connect-adaptor -DskipTests -Dspotbugs.skip -Dcheckstyle.skip
cd ../snowflake-connector
mvnd clean install -DskipTests -Dspotbugs.skip -Dcheckstyle.skip
cd $here
cp /Users/nicolo.boschi/dev/snowflake-connector/pulsar-snowflake-connector/target/pulsar-snowflake-connector-0.1.10-SNAPSHOT.nar .
docker build -t nicoloboschi/lunastreaming-all:283-kca-fix-2 --no-cache .
docker push nicoloboschi/lunastreaming-all:283-kca-fix-2