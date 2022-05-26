#!/bin/bash
set -e

build_pulsar() {
    mvnd clean install -DskipTests -Dcheckstyle.skip -Dspotbugs.skip 
}
build_pulsar_core() {
    mvnd clean install -DskipTests -Dcheckstyle.skip -Dspotbugs.skip -Pcore-modules
}