# Dockerized Apache Kafka
This repository holds the build definition and supporting files for building a [Docker](https://www.docker.com) image to run [Apache Kafka](http://kafka.apache.org/) in containers. The image is available from [DockerHub](https://registry.hub.docker.com/repos/cgswong/)

Configuration is parameterized, enabling a Kafka cluster to be run from multiple container instances.

## How to use this image
### ZooKeeper
Kafka requires a running [ZooKeeper](http://zookeeper.apache.org/) ensemble in order to manage broker and consumer coordination for its [Topics](http://kafka.apache.org/documentation.html#introduction). Consumer offsets also get committed to [ZooKeeper](http://zookeeper.apache.org/) as a way for all consumers in a single 'group' to synchronize with each other.

You should use the predefined [ZooKeeper image](https://github.com/cgswong/docker-kafka) to start a [ZooKeeper](http://zookeeper.apache.org/) ensemble prior to attempting to run a Kafka broker. You'll need to start an ensemble that can obtain a fail-over quorum, preferably 3 or 5 nodes.

The image provides a cluster-able Kafka broker. As a minimum the following Docker `run` environment variables (i.e. `docker run -e`) must be set:

- `kafka_broker_id` - Defaults to 1.
- `kafka_advertised_host_name` - This is given to a consumer by ZooKeeper when connecting to a topic.
- `kafka_zookeeper_connect` - Comma separated ZooKeeper connection string in the form `[hostname/IP]:[port]` where `[port]` defaults to `2181` if none is given. In a shared ZooKeeper environment use a chroot syntax where the directory to store the specific Kafka environment is appended to the last ZooKeeper entry, for example, `[hostname1/IP1]:[port],[hostname2/IP2]:[port]/kafka1`, where Kafka entries would then go under `/kafka1`.

So, assuming your Docker host is `172.17.8.101`, has [ZooKeeper](http://zookeeper.apache.org/) running and should now run Kafka as well, execute the following:

  ```sh
  docker run -d --name kafka1 -e kafka_broker_id=1 -e kafka_advertised_host_name=172.17.8.101 -e kafka_zookeeper_connect=172.17.8.101/kafka cgswong/kafka:latest
  ```

### Additional configuration
Environment variables are accepted as a means to provide further configuration by reading those starting with `kafka_`. Any matching variables will get added to Kafka's `server.properties` file by

1. removing the `kafka_` prefix
2. replacing any occurrences of `_` with `.`

For example, an environment variable `kafka_num_partitions=3` will result in `num.partitions=3` within `server.properties`. Similarly, to auto create topics when a broker publishes to a non-existent topic you can use an environment variable `kafka_auto_create_topics_enable=true` which will result in `auto.create.topics.enable=true` within `server.properties` with the default replication factor and number of partitions which can also be set similarly.

You can also download a configuration file by setting the special environment variable `kafka_cfg_url` to the download file location. Within this file you can also take advantage of variable substitution.

Other Kafka settings can also be enabled via Docker `run` environment variables, for example, `-e KAFKA_JMX_OPTS=-Dcom.sun.management.jmxremote=false`. A few environment variables of interest:

- GC_LOG_ENABLED: Set to `true` to enable garbage collection logging.
- **JMX_PORT:** JMX port for remote monitoring. Defaults to exposed port 19092 in this image.
- KAFKA_GC_LOG_OPTS: Garbage collection logging options. `GC_LOG_ENABLED` must be enabled.
- KAFKA_HEAP_OPTS: JVM memory settings or heap size, defaults to `-Xmx1G -Xms1G` (1GB).
- KAFKA_JMX_OPTS: JMX options
- KAFKA_JVM_PERFORMANCE_OPTS: JVM performance options. Defaults to `-server -XX:+UseG1GC -XX:MaxGCPauseMillis=20 -XX:InitiatingHeapOccupancyPercent=35 -XX:+DisableExplicitGC -Djava.awt.headless=true`
- KAFKA_LOG4J_OPTS: Log4j options
- KAFKA_OPTS: Generic JVM settings that you may want to set.

## Issues
If you have any problems with or questions about this image, please contact me through a [GitHub issue](https://github.com/cgswong/docker-kafka/issues).
