#!/bin/bash

set -e 
this_dir=$( dirname -- "${BASH_SOURCE[0]}" )
tag=$1
version=$2
if [[ -z $tag || -z $version ]]; then
    echo "usage: <tag> <version>"
    exit 1
fi

$(realpath $this_dir)/../validate-rc.py -p pulsar -v $version -u https://dist.apache.org/repos/dist/dev/pulsar/pulsar-${tag:1}

cd /tmp

###
# sdk use java 17.0.1-zulu
###
git clone https://github.com/apache/pulsar.git --depth 1 --branch $tag pulsar-$tag || echo "local repo already exists"
cd pulsar-$tag
mvnd apache-rat:check
echo "Rat check done"
mvnd clean package -am -pl :pulsar-server-distribution,:pulsar-shell-distribution -DskipTests
echo "Build done"
./src/check-binary-license.sh distribution/server/target/apache-pulsar-$version-bin.tar.gz
echo "Server license check done"
./src/check-binary-license.sh distribution/shell/target/apache-pulsar-shell-$version-bin.tar.gz
echo "Shell license check done"


echo "Done"




