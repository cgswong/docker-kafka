#!/usr/bin/env bash

# Setup environment
docker_name=${1}
kafka_topic=${2:-"dsptest1"}
zk_ensemble=${3:-"ensemble"}
replica=${4:-1}
purpose=${5:-"consumer"}
port=${6:-"9092"}
zk_hosts=$(for zk in $(etcdctl ls /services/zk/$zk_ensemble); do etcdctl get $zk; done| paste -s -d',')
kafka_hosts=$(echo $zk_hosts | sed -e "s|,|:$port,|g" -e "s|$|:$port|g")

if [ "$purpose" != "consumer" ]; then
  # Create topic
  echo "Creating topic: $kafka_topic"
  docker exec -i $docker_name /opt/kafka/bin/kafka-topics.sh --create --zookeeper $zk_hosts --replication-factor $replica --partitions 1 --topic $kafka_topic

  # View topic
  echo "Listing topics..."
  docker exec -i $docker_name /opt/kafka/bin/kafka-topics.sh --list --zookeeper $zk_hosts
  echo "Describing topics..."
  docker exec -i $docker_name /opt/kafka/bin/kafka-topics.sh --describe --zookeeper $zk_hosts --topic $kafka_topic

  # Send some messages (PRODUCER)
  echo "Press any key when ready to continue..."
  read
  echo "PRODUCER: Sending some messages..."
  docker exec -i $docker_name /opt/kafka/bin/kafka-console-producer.sh --broker-list $kafka_hosts --topic $kafka_topic << EOF
message 1
message 2
message 3
message 4
EOF
else
  # read some messages (CONSUMER)
  echo "CONSUMER: Reading messages..."
  docker exec -i $docker_name /opt/kafka/bin/kafka-console-consumer.sh --zookeeper $zk_hosts --topic $kafka_topic --from-beginning
fi

