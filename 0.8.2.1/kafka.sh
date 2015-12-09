#!/usr/bin/env bash

# Fail hard and fast
set -eo pipefail

# Setup shutdown handlers
pid=0
trap 'shutdown_handler' SIGTERM SIGINT

KAFKA_DIR=/var/lib/kafka
KAFKA_LOG_DIR=${KAFKA_DIR}/log
KAFKA_HOME=/opt/kafka

# Write messages to screen
log() {
  echo "$(date +"[%F %X,000]") $(hostname) $1"
}

# Write exit failure messages to syslog and exit with failure code (i.e. non-zero)
die() {
  log "[FAIL] $1" && exit 1
}

shutdown_handler() {
  # Handle Docker shutdown signals to allow correct exit codes upon container shutdown
  log "[INFO] Requesting container shutdown..."
  kill -SIGINT "${pid}"
  log "[INFO] Container stopped."
  exit 0
}

: ${KAFKA_BROKER_ID:=1}
[ -z "${KAFKA_ADVERTISED_HOST_NAME}" ] && die "KAFKA_ADVERTISED_HOST_NAME not set, exiting."
[ -z "$KAFKA_ZOOKEEPER_CONNECT" ] && die "KAFKA_ZOOKEEPER_CONNECT not set, exiting."

export KAFKA_BROKER_ID

KAFKA_LOCK_FILE="${KAFKA_DIR}/.lock"
[ -e "${KAFKA_LOCK_FILE}" ] && log "Removing stale lock file" && rm -f ${KAFKA_LOCK_FILE}

# Process general environment variables
for VAR in `env`; do
  if [[ $VAR =~ ^KAFKA_ && ! $VAR ~= ^KAFKA_HOME && ! $VAR ~= ^KAFKA_USER && ! $VAR ~= ^KAFKA_VERSION && ! $VAR ~= ^KAFKA_GROUP && ! $VAR ~= ^KAFKA_DIR && ! $VAR ~= ^KAFKA_LOG_DIR ]]; then
    key=$(echo "${VAR}" | sed -r "s/KAFKA_(.*)=.*/\1/g" | tr '[:upper:]' '[:lower:]' | tr _ .)
    value=$(echo "${VAR}" | sed -r "s/(.*)=.*/\1/g")

    if egrep -q "(^|^#)${key}" ${KAFKA_HOME}/config/server.properties; then
      sed -r -i "s\\(^|^#)${key}=.*$\\${key}=${!value}\\g" ${KAFKA_HOME}/config/server.properties
    else
      echo "$key=${!value}" >> ${KAFKA_HOME}/config/server.properties
    fi
  fi
done

# Logging config
sed -i "s/^kafka\.logs\.dir=.*$/kafka\.logs\.dir=${KAFKA_LOG_DIR}/" ${KAFKA_HOME}/config/log4j.properties

# if `docker run` first argument start with `--` the user is passing launcher arguments
cd ${KAFKA_HOME}
if [[ "$1" == "--"* || -z $1 ]]; then
  exec ${KAFKA_HOME}/bin/kafka-server-start.sh config/server.properties "$@" &
  pid=$!
  log "[INFO] Started with PID: ${pid}"
  wait ${pid}
  trap - SIGTERM SIGINT
  wait ${pid}
else
  exec "$@"
fi
