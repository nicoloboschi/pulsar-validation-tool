#!/bin/bash
set -e

export SNOWSQL_PWD=''
result=$(/Applications/SnowSQL.app/Contents/MacOS/snowsql -a dmb76871.us-east-1 -u pulsar_haxx_user_1 -d PULSAR_HAXX_DATABASE -q "select count(*) from PULSAR_HAXX_DATABASE.PULSAR_HAXX_SCHEMA.MYMAPPEDTABLE;")

while :
do
    echo "$result"
    if [[ "$result" == *"10"* ]]; then
        echo "Found records!"
        exit 0
    fi
done