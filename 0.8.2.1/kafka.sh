#! /usr/bin/env bash

KAFKA_DIR=/var/lib/kafka
KAFKA_LOG_DIR=${KAFKA_DIR}/log
KAFKA_USER=kafka
KAFKA_HOME=/opt/kafka

# Fail hard and fast
set -eo pipefail

KAFKA_BROKER_ID=${KAFKA_BROKER_ID:-1}
echo "KAFKA_BROKER_ID=$KAFKA_BROKER_ID"

if [ -z "$KAFKA_ADVERTISED_HOST_NAME" ]; then
  echo "${KAFKA_ADVERTISED_HOST_NAME} not set, exiting."
  exit 1
fi
echo "KAFKA_ADVERTISED_HOST_NAME=${KAFKA_ADVERTISED_HOST_NAME}"

if [ -z "$KAFKA_ZOOKEEPER_CONNECT" ]; then
  echo "${KAFKA_ZOOKEEPER_CONNECT} not set, exiting."
  exit 1
fi
echo "KAFKA_ZOOKEEPER_CONNECT=${KAFKA_ZOOKEEPER_CONNECT}"

KAFKA_LOCK_FILE="${KAFKA_DIR}/.lock"
if [ -e "${KAFKA_LOCK_FILE}" ]; then
  echo "Removing stale lock file"
  rm -f ${KAFKA_LOCK_FILE}
fi

# Process general environment variables
for VAR in `env`; do
  if [[ $VAR =~ ^KAFKA_ && ! $VAR ~= ^KAFKA_HOME && ! $VAR ~= ^KAFKA_USER && ! $VAR ~= ^KAFKA_DIR && ! $VAR ~= ^KAFKA_LOG_DIR ]]; then
    KAFKA_CONFIG_VAR=`echo "$VAR" | sed -r "s/KAFKA_(.*)=.*/\1/g" | tr '[:upper:]' '[:lower:]' | tr _ .`
    KAFKA_ENV_VAR=`echo "$VAR" | sed -r "s/(.*)=.*/\1/g"`

    if egrep -q "(^|^#)$KAFKA_CONFIG_VAR" $KAFKA_HOME/config/server.properties; then
      sed -r -i "s\\(^|^#)$KAFKA_CONFIG_VAR=.*$\\$KAFKA_CONFIG_VAR=${!KAFKA_ENV_VAR}\\g" $KAFKA_HOME/config/server.properties
    else
      echo "$KAFKA_CONFIG_VAR=${!KAFKA_ENV_VAR}" >> $KAFKA_HOME/config/server.properties
    fi
  fi
done

# Logging config
sed -i "s/^kafka\.logs\.dir=.*$/kafka\.logs\.dir=${KAFKA_LOG_DIR}/" ${KAFKA_HOME}/config/log4j.properties

cd $KAFKA_HOME
$KAFKA_HOME/bin/kafka-server-start.sh config/server.properties
