#!/usr/bin/env bash

# Fail hard and fast
set -eo pipefail

# Setup shutdown handlers
pid=0
trap 'shutdown_handler' SIGTERM SIGINT

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

KAFKA_DIR=/var/lib/kafka
KAFKA_HOME=/opt/kafka
LOG_DIR=${KAFKA_HOME}/logs
KAFKA_CFG_FILE=${KAFKA_HOME}/config/server.properties

# Download the config file, if given a URL
if [ ! -z "${kafka_cfg_url}" ]; then
  log "Downloading config file from ${kafka_cfg_url}"
  curl -sSL ${kafka_cfg_url} --output ${KAFKA_CFG_FILE} || die "Unable to download ${kafka_cfg_url}"
fi

# Setup default variables, some best practices, some opinionated
: ${kafka_auto_create_topics_enable:=true}
: ${kafka_broker_id:=1}
: ${kafka_delete_topic_enable:=true}
: ${kafka_dual_commit_enabled:=false}
: ${kafka_log_cleaner_enable:=true}
: ${kafka_log_retention_hours:=168}
: ${kafka_num_partitions:=1}
: ${kafka_num_recovery_threads_per_data_dir:=1}
: ${kafka_offsets_storage:=kafka}
: ${kafka_port:=9092}
: ${kafka_zookeeper_connect:=$ZOOKEEPER_PORT_2181_TCP_ADDR:$ZOOKEEPER_PORT_2181_TCP_PORT}
: ${kafka_zookeeper_connection_timeout_ms:=6000}

export kafka_auto_create_topics_enable
export kafka_broker_id
export kafka_delete_topic_enable
export kafka_dual_commit_enabled
export kafka_log_cleaner_enable
export kafka_log_dir="${KAFKA_DIR}"
export kafka_log_retention_hours
export kafka_num_partitions
export kafka_num_recovery_threads_per_data_dir
export kafka_offsets_storage
export kafka_port
export kafka_zookeeper_connect
export kafka_zookeeper_connection_timeout_ms
export KAFKA_LOG4J_OPTS:="-Dlog4j.configuration=file:/etc/kafka/log4j.properties"

KAFKA_LOCK_FILE="${KAFKA_DIR}/.lock"
[ -e "${KAFKA_LOCK_FILE}" ] && log "[INFO] Removing stale lock file" && rm -f ${KAFKA_LOCK_FILE}

# Process general environment variables
for VAR in $(env | grep '^kafka_' | grep -v '^kafka_cfg_' | sort); do
  key=$(echo "${VAR}" | sed -r "s/kafka_(.*)=.*/\1/g" | tr _ .)
  value=$(echo "${VAR}" | sed -r "s/(.*)=.*/\1/g")
  if egrep -q "(^|^#)${key}" ${KAFKA_CFG_FILE}; then
    sed -r -i "s\\(^|^#)${key}=.*$\\${key}=${!value}\\g" ${KAFKA_CFG_FILE}
  else
    echo "$key=${!value}" >> ${KAFKA_CFG_FILE}
  fi
done

# The built-in start scripts set the first three system properties here, but
# we add two more to make remote JMX easier/possible to access in a Docker
# environment:
#
#   1. RMI port - pinning this makes the JVM use a stable one instead of
#      selecting random high ports each time it starts up.
#   2. RMI hostname - normally set automatically by heuristics that may have
#      hard-to-predict results across environments.
#
# These allow saner configuration for firewalls, EC2 security groups, Docker
# hosts running in a VM with Docker Machine, etc. See:
#
# https://issues.apache.org/jira/browse/CASSANDRA-7087
if [ -z ${KAFKA_JMX_OPTS} ]; then
  KAFKA_JMX_OPTS="-Dcom.sun.management.jmxremote=true"
  KAFKA_JMX_OPTS="${KAFKA_JMX_OPTS} -Dcom.sun.management.jmxremote.authenticate=false"
  KAFKA_JMX_OPTS="${KAFKA_JMX_OPTS} -Dcom.sun.management.jmxremote.ssl=false"
  KAFKA_JMX_OPTS="${KAFKA_JMX_OPTS} -Dcom.sun.management.jmxremote.rmi.port=${JMX_PORT}"
  KAFKA_JMX_OPTS="${KAFKA_JMX_OPTS} -Djava.rmi.server.hostname=${JAVA_RMI_SERVER_HOSTNAME:-$kafka_advertised_host_name} "
  export KAFKA_JMX_OPTS
fi

# if `docker run` first argument start with `--` the user is passing launcher arguments
if [[ "$1" == "-"* || -z $1 ]]; then
  exec ${KAFKA_HOME}/bin/kafka-server-start.sh ${KAFKA_CFG_FILE} "$@" &
  pid=$!
  log "[INFO] Started with PID: ${pid}"
  wait ${pid}
  trap - SIGTERM SIGINT
  wait ${pid}
else
  exec "$@"
fi
