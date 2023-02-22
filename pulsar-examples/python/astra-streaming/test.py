import pulsar
import logging
import os

service_url = os.getenv("AS_URL");
token = os.getenv("AS_TOKEN");
topic = os.getenv("AS_TOPIC");

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
logger.addHandler(logging.StreamHandler())
logging.getLogger().addHandler(logging.StreamHandler())
client = pulsar.Client(service_url,
tls_validate_hostname=True,
        logger=logger, authentication=pulsar.AuthenticationToken(token))

producer = client.create_producer(topic)

for i in range(10):
    producer.send(('Hello World! %d' % i).encode('utf-8'))

client.close()