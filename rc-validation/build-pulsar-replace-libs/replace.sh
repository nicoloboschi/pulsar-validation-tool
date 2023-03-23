#!/bin/bash
set -ex
replace_in_dir() {
    local from=$1
    local to=$2

    for f in $from/*; do
        echo "Found file $f"
        rm_file=$(basename $f)
        rm_file=$(echo "$rm_file" | sed 's/-[0-9].*//')
        rm_file=${rm_file//-SNAPSHOT/}
        
        echo "remove $to/$rm_file*.jar"
        rm -rf $to/$rm_file*.jar
        mv $f $to 
    done
}

replace_in_dir /pulsar/tmp-lib /pulsar/lib

