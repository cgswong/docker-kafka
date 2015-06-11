# Dockerized Apache Kafka
This repository holds the build definition and supporting files for building a [Docker](https://www.docker.com) image to run [Apache Kafka](http://kafka.apache.org/) in containers. The image is available from [DockerHub](https://registry.hub.docker.com/repos/cgswong/)

Configuration is parameterized, enabling a Kafka cluster to be run from multiple container instances.

## How to use this image
### Zookeeper
Kafka requires a running [Zookeeper](http://zookeeper.apache.org/) ensemble in order to manage broker and consumer coordination for its [Topics](http://kafka.apache.org/documentation.html#introduction). Consumer offsets also get committed to [Zookeeper](http://zookeeper.apache.org/) as a way for all consumers in a single 'group' to synchronize with each other.

You should use the predefined [Zookeeper image](https://github.com/cgswong/docker-kafka) to start a [Zookeeper](http://zookeeper.apache.org/) ensemble prior to attempting to run a Kafka broker. You'll need to start an ensemble that can obtain a fail-over quorum, preferably 3 or 5 nodes.

The image provides a cluster-able Kafka broker. As a minimum the following environment variables must be set:

1. `KAFKA_BROKER_ID` - Defaults to 1.
2. `KAFKA_ADVERTISED_HOST_NAME` - This is given to a Consumer by Zookeeper when connecting to a Topic. Match your hostname/IP. If the port is different than the default 9092 then also set `KAFKA_ADVERTISED_PORT`.
3. `KAFKA_ZOOKEEPER_CONNECT` - Zookeeper connection string in the form `[hostname1/IP1]:[port],[hostname2/IP2]:[port],[hostname3/IP3]:[port]` where `[port]` defaults to `2181` if none is given.

So, assuming your Docker host is `172.17.8.101`, has [Zookeeper](http://zookeeper.apache.org/) running and should now run Kafka as well, execute the following:

  ```sh
  docker run -d --rm --name kafka1 --env KAFKA_BROKER_ID=1 --env KAFKA_ADVERTISED_HOST_NAME=172.17.8.101 --env KAFKA_ZOOKEEPER_CONNECT=172.17.8.101 cgswong/kafka:latest
  ```

### Additional configuration

Environment variables are accepted as a means to provide further configuration by reading those starting with `KAFKA_`. Any matching variables will get added to Kafka's `server.properties` file by

1. removing the `KAFKA_` prefix
2. transforming to lower case
3. replacing any occurrences of `_` with `.`

For example, an environment variable `KAFKA_NUM_PARTITIONS=3` will result in `num.partitions=3` within `server.properties`. Similarly, to auto create topics when a broker publishes to a non-existent topic you can use an environment variable `KAFKA_AUTO_CREATE_TOPICS_ENABLE=true` which will result in `auto.create.topics.enable=true` within `server.properties` with the default replication factor and number of partitions which can also be set similarly.

## Issues
If you have any problems with or questions about this image, please contact me through a [GitHub issue](https://github.com/cgswong/docker-kafka/issues).

