#!/bin/bash
set -ex

DOCKER_ORG=${DOCKER_ORG:-$USER}
RESUME=${RESUME:-"false"}
this_dir=$( dirname -- "${BASH_SOURCE[0]}" )
this_dir=$(realpath $this_dir)
temp_dir=/tmp/build-pulsar-snapshot-connectors
if [ "$RESUME" != "true" ]; then
    rm -rf $temp_dir
fi

mkdir -p $temp_dir
cd $temp_dir

mkdir -p context
cp $this_dir/replace.sh context/replace.sh
mkdir -p context/connectors

while [[ $# -gt 0 ]]; do
    echo "processing: $repo"
    repo="$1"
    shift
    branch="master"
    artifact_pattern="*.nar"
    IFS='|' read -ra parts <<< "$repo"
    count=0
    for i in "${parts[@]}"; do
        if [ $count -eq 0 ]; then
            repo=$i
        elif [ $count -eq 1 ]; then
            branch=$i
        elif [ $count -eq 2 ]; then
            artifact_pattern=$i
        else
            artifact_pattern="${artifact_pattern}|$i"
        fi
        count=$((count + 1))
    done


    to=$(basename $repo)-$branch
    if [ -d "$to" ]; then
        found_nar=
        find $to -name "$artifact_pattern" | while read nar; do
            found_nar=true
        done
        if [ "$found_nar" == "true" ]; then
            echo "skip building $repo, already built"   
            continue
        fi
    fi
    git clone $repo --depth 1 --branch $branch $to
    cd $to
    if [ -f "gradlew" ]; then
        ./gradlew build -x test
    else
        asap mvnd clean install -DskipTests 
    fi
    
    find . -name "$artifact_pattern" | while read nar; do
        mv $nar ../context/connectors
    done

    cd ..
done


ls -la context/connectors

image=$DOCKER_ORG/pulsar-all:connectors-snapshots
build_arg=""
if [ ! -z "$FROM" ]; then
    build_arg="--build-arg FROM=$FROM"
fi
docker build -f $this_dir/Dockerfile -t $image $build_arg context

docker run --rm $image bash -c "ls -la connectors"
docker push $image