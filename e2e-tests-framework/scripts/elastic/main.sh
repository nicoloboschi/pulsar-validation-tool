#!/bin/bash

# docker run -v $HOME/dev/localscripts/pulsar-image-validation/simple-produce-consume.sh:/test.sh --rm -it  184aff6b0972 /bin/bash -c /test.sh
set -ex
#sleep 20
chmod +x /pulsar/bin/apply-config-from-env.py
/pulsar/bin/apply-config-from-env.py /pulsar/conf/client.conf

until $(curl -s --output /dev/null --fail http://$HOSTNAME_ELASTIC:9200); do
    sleep 5
done

until $(curl -s --output /dev/null  --fail ${webServiceUrl}admin/v3/sink/public/default); do
    sleep 5
done

/pulsar/bin/pulsar-admin sinks create -t elastic_search \
--tenant public --namespace default --name elasticsearch-sink \
--inputs elasticsearch_topic_input \
--sink-config "{\"elasticSearchUrl\":\"http://$HOSTNAME_ELASTIC:9200\",\"indexName\": \"myindex\",\"username\": \"scooby\",\"password\": \"doobie\",\"schemaEnable\":true}" \

jshell --class-path $(ls -d /pulsar/lib/* | tr '\n' ':') ${script:elastic/elastic-avro-ser.jsh}
/pulsar/bin/pulsar-client produce -f ser.bin -vs "avro:{\"type\":\"record\",\"name\":\"MyRecord\",\"namespace\":\"\",\"fields\":[{\"name\":\"count\",\"type\":\"int\"}]}" public/default/elasticsearch_topic_input
python3 ${script:elastic/elastic-checker.py} $HOSTNAME_ELASTIC myindex 789




