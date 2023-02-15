const Pulsar = require("pulsar-client");

function getFromEnv(name) {
  const value = process.env[name];
  if (!value) {
    throw "Env variable '" + name + "' is required"
  }
  return value
}

const pulsarUrl = getFromEnv("AS_URL");
const asToken = getFromEnv("AS_TOKEN");
const asTopic = getFromEnv("AS_TOPIC");
(async () => {
  const tokenStr = asToken;
  const pulsarUri = pulsarUrl;
  const topicName = asTopic;

  const auth = new Pulsar.AuthenticationToken({ token: tokenStr });
  const client = new Pulsar.Client({
    serviceUrl: pulsarUri,
    authentication: auth,
    operationTimeoutSeconds: 30,
  });
  Pulsar.Client.setLogHandler((level, file, line, message) => {
    console.log('[%s][%s:%d] %s', Pulsar.LogLevel.toString(level), file, line, message);
  });

  const producer = await client.createProducer({
    topic: topicName,
  })

  for (let i = 0; i < 10; i += 1) {
    await producer.send({
      data: Buffer.from("nodejs-message-" + i),
    });
    console.log("send message " + i);
  }
  await producer.flush();
  await producer.close();
  await client.close();
})();