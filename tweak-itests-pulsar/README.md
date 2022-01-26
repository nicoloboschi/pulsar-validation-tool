## Easy run Pulsar integrations tests locally

This project helps you running integrations tests locally without waiting forever to get docker image up-to-date.

Warnings: 
* scripts work only by running from their parent directory (`pulsar-validation-tool/tweak-itests-pulsar`)
* For Functions tests: only Java functions are supported
* These scripts rely on Maven Daemon to fastify the builds.

### One time setup

```
# mvn clean install -DskipTests 
# mvn clean install -DskipTests -am -pl docker,docker-all -Pdocker
export PULSAR_DIR=${HOME}/mypulsardir

# Warning: this will replace the Dockerfile file
# "apachepulsar/pulsar-test-latest-version:latest" image will be created
./setup-latest-docker-image

```

### Rebuild docker image after some code changes

```
# "apachepulsar/pulsar-test-latest-version:latest-tweak" image will be created/updated
# The default modules that will be build and deployed are: pulsar-common,pulsar-broker-common,pulsar-broker,pulsar-metadata
# If you want add other modules, you have to set the BUILD_MODULES env variable.

export BUILD_MODULES="pulsar-client"
./rebuild-image

# Run the test. it must be in the tests/integration directory. Use TEST env variable to set the Java file name.

export TEST=PulsarFunctionsJavaProcessTest
TEST= ./run-test
```

