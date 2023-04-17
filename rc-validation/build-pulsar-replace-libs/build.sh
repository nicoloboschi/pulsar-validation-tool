#!/bin/bash
set -e

DOCKER_ORG=${DOCKER_ORG:-$USER}
MVN_COMMAND=${MVN_COMMAND:-"mvn"}
if [[ -z "$PULSAR_DIR" ]]; then
    echo "PULSAR_DIR not set"
    exit 1
fi
mvn_or_mvnd() {
    if command -v mvnd &> /dev/null; then
        mvnd "$@"
    else
        mvn "$@"
    fi
}

from_image=$1
ref_from=$2
ref_to=$3

if [[ -z "$from_image" ]]; then
    echo "Usage: ./build.sh <docker_image_from> <git_ref_from> <git_ref_to>"
    exit 1
fi

if [[ -z "$ref_from" ]]; then
    echo "Usage: ./build.sh <docker_image_from> <git_ref_from> <git_ref_to>"
    exit 1
fi

if [[ -z "$ref_to" ]]; then
    echo "Usage: ./build.sh <docker_image_from> <git_ref_from> <git_ref_to>"
    exit 1
fi


HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
cd $PULSAR_DIR

BUILD_MODULES=$(git diff --name-only ${ref_from}..${ref_to} | grep -v "pom\.xml" | grep -v "conf/" | grep -v "/src/test" | grep -v "pulsar-io/" | grep -v "tiered-storage/" | grep -v "LICENSE" | sed 's/\/src.*//'  | sort --unique | tr '[:space:]' ',')
echo "found modules: $BUILD_MODULES"


git checkout $ref_from
DOCKER_PULSAR_VERSION=$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout -f pom.xml)


git checkout $ref_to

rm -rf /tmp/build-pulsar-replace-libs
mkdir /tmp/build-pulsar-replace-libs
cp $HERE/replace.sh /tmp/build-pulsar-replace-libs/replace.sh
mkdir /tmp/build-pulsar-replace-libs/libs

MODULES_ARR=(${BUILD_MODULES//,/ })
echo $MODULES_ARR


cp_module_recursive() {
    local mod=$1
    for file in ${mod}/*; do
        
        base=$(basename $file)
        if [[ "$base" == "src" || "$base" == "target" ]]; then 
            continue 
        fi
        if [[ "$base" == "pom.xml" ]]; then
            find ${mod}/target/ -name "*.jar" | while read jar; do
                jar_part=$(basename $jar)
                jar_part=${jar_part//\.jar}
                cp $jar /tmp/build-pulsar-replace-libs/libs/com.datastax.oss-${jar_part}-${DOCKER_PULSAR_VERSION}.jar
            done
        else
            if [ -d "$file" ]; then
                cp_module_recursive $file
            fi
            
        fi
    done
}

projects=""
for module in "${MODULES_ARR[@]}"; do
    artifact_id=$(mvn help:evaluate -Dexpression=project.artifactId -q -DforceStdout -f $module)
    projects+=":$artifact_id,$projects"
done
echo "Building modules: $projects"
mvn_or_mvnd clean install -nsu -DskipTests -Dcheckstyle.skip -Dspotbugs.skip -Dlicense.skip -Djavadoc.skip -DskipSourceReleaseAssembly -q -pl $projects -am



for module in "${MODULES_ARR[@]}"; do
    cp_module_recursive $module
done

tagname=${DOCKER_ORG}/lunastreaming-all:build-${ref_to}
docker build -t $tagname -f ${HERE}/Dockerfile --build-arg FROM=$from_image /tmp/build-pulsar-replace-libs

echo "********************************************"
echo "Docker image created: $tagname"
echo "********************************************"
