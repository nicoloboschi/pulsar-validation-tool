# e2e-tests-framework

This framework enables you to easily run an e2e test against Pulsar and its integrations.

There are two main features:
* Run the tests locally using Docker
* Generate a valid Datastax Fallout test with a simpler language.

## Local tests
Usage:
`./runner.py -f tests/simple.yaml`

File tree:
* `tests/`: each YAML file is a test. You define the resources and some commands that must be run on the containers.
* `scripts`: it contains some utility script you may want to import into the test file.
