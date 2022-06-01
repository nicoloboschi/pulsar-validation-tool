#!/bin/bash
build_pulsar() {
    mvnd clean install -DskipTests -Dcheckstyle.skip -Dspotbugs.skip 
}
build_pulsar_core() {
    mvnd clean install -DskipTests -Dcheckstyle.skip -Dspotbugs.skip -Pcore-modules
}
build_pulsar_core_no_clean() {
    mvn clean install -DskipTests -Dcheckstyle.skip -Dspotbugs.skip -Pcore-modules -T 1C
}