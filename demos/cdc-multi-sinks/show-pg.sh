#!/bin/bash
set -e

docker exec -it postgres psql -U postgres -c 'select * from pulsar_table;' postgres

