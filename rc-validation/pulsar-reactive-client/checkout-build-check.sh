#!/bin/bash

set -e 
this_dir=$( dirname -- "${BASH_SOURCE[0]}" )
version=$1
candidate=$2
if [[ -z $version || -z "$candidate" ]]; then
    echo "usage: <version> <candidate_number>"
    exit 1
fi

cd /tmp
rm -rf pulsar-rclient-validation
mkdir pulsar-rclient-validation
cd pulsar-rclient-validation

curl -Lf -s -o KEYS "https://dist.apache.org/repos/dist/dev/pulsar/KEYS"
gpg -q --import KEYS

download_and_check() {
    local artifact=$1
    base=https://dist.apache.org/repos/dist/dev/pulsar/pulsar-client-reactive-${version}-candidate-${candidate}
    echo "downloading ${base}/${artifact}.tar.gz"
    curl -Lf -s -o ${artifact}.tar.gz ${base}/${artifact}.tar.gz
    echo "done"
    curl -Lf -s -o ${artifact}.tar.gz.sha512sum ${base}/${artifact}.tar.gz.sha512
    curl -Lf -s -o ${artifact}.tar.gz.asc ${base}/${artifact}.tar.gz.asc

    actual=$(shasum -a 512 ${artifact}.tar.gz | awk '{print $1}')
    expected=$(cat ${artifact}.tar.gz.sha512sum| awk '{print $1}')
    if [ "$actual" != "$expected" ]; then
        echo "sha mismatch on ${artifact}, expected ${expected}, found $actual"
        exit 1
    fi
    echo "SHA for $artifact: OK"

    gpg --verify ${artifact}.tar.gz.asc ${artifact}.tar.gz
    echo "Signature for $artifact: OK"

}



download_and_check pulsar-client-reactive-${version}-src
tar xzvf pulsar-client-reactive-${version}-src.tar.gz
cd pulsar-client-reactive-${version}
gradle build