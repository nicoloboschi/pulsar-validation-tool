#!/bin/bash
set -e

DOCKER_ORG=${DOCKER_ORG:-$USER}
SKIP_BUILD=${SKIP_BUILD:-"false"}
MVN_COMMAND=${MVN_COMMAND:-"mvn"}
JAR_PREFIX=${JAR_PREFIX:-"com.datastax.oss"}


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


HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
cd $PULSAR_DIR

if [[ -z "$ref_from" ]]; then
    git_ref_cmd=""   
elif  [[ -z "$ref_to" ]]; then
    git_ref_cmd="${ref_from}"
else
    git_ref_cmd="${ref_from}..${ref_to}"
fi





BUILD_MODULES=$(git diff --name-only ${git_ref_cmd} | grep -v "pom\.xml" | grep -v "conf/" | grep -v "/src/test" | grep -v "pulsar-io/" | grep -v "tiered-storage/" | grep -v "LICENSE" | sed 's/\/src.*//'  | sort --unique | tr '[:space:]' ',')
echo "found modules: $BUILD_MODULES"
MODULES_ARR=(${BUILD_MODULES//,/ })
echo $MODULES_ARR

current_git=$(git rev-parse --abbrev-ref HEAD)
if [ -z "$DOCKER_PULSAR_VERSION" ]; then
    git checkout $ref_from
    DOCKER_PULSAR_VERSION=$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout -f pom.xml)
    git checkout $current_git
fi


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
                cp $jar /tmp/build-pulsar-replace-libs/libs/${JAR_PREFIX}-${jar_part}-${DOCKER_PULSAR_VERSION}.jar
            done
        else
            if [ -d "$file" ]; then
                cp_module_recursive $file
            fi
            
        fi
    done
}

if [ "$SKIP_BUILD" != "true" ]; then
    git checkout $ref_to

    projects=""
    for module in "${MODULES_ARR[@]}"; do
        artifact_id=$(mvn help:evaluate -Dexpression=project.artifactId -q -DforceStdout -f $module)
        projects+=":$artifact_id,$projects"
    done
    echo "Building modules: $projects"
    mvn_or_mvnd clean install -nsu -DskipTests -Dcheckstyle.skip -Dspotbugs.skip -Dlicense.skip -Djavadoc.skip -DskipSourceReleaseAssembly -q -pl $projects
fi

rm -rf /tmp/build-pulsar-replace-libs
mkdir /tmp/build-pulsar-replace-libs
cp $HERE/replace.sh /tmp/build-pulsar-replace-libs/replace.sh
mkdir /tmp/build-pulsar-replace-libs/libs

for module in "${MODULES_ARR[@]}"; do
    cp_module_recursive $module
done
tagname=${DOCKER_ORG}/lunastreaming-all:build${ref_to}
docker build -t $tagname -f ${HERE}/Dockerfile --build-arg FROM=$from_image /tmp/build-pulsar-replace-libs

echo "********************************************"
echo "Docker image created: $tagname"
echo "********************************************"

git checkout $current_git
