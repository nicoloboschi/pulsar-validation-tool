# Package Pulsar image with custom connectors


## Usage

```
./build [connector_repository][..]
```

## Repository syntax

**URL|BRANCH|PATTERN**

Default is

**URL|master|*.nar**


## Env

- RESUME: if "true", the current work directory will be reused
- DOCKER_ORG: docker org for the image, default is $USER

## Example
```
RESUME=true DOCKER_ORG=nicoloboschi ./build.sh https://github.com/datastax/pulsar-sink "https://github.com/datastax/cdc-apache-cassandra|master|pulsar-cassandra-source*.nar"
```