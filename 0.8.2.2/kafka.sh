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
KAFKA_CFG_FILE=${KAFKA_HOME}/config

# Download the config file, if given a URL
if [ ! -z "${kafka_cfg_url}" ]; then
  log "Downloading config file from ${kafka_cfg_url}"
  curl -sSL ${kafka_cfg_url} --output ${KAFKA_CFG_FILE} || die "Unable to download ${kafka_cfg_url}"
fi

: ${kafka_broker_id:=1}
export kafka_broker_id

KAFKA_LOCK_FILE="${KAFKA_DIR}/.lock"
[ -e "${KAFKA_LOCK_FILE}" ] && log "[INFO] Removing stale lock file" && rm -f ${KAFKA_LOCK_FILE}

# Process general environment variables
for VAR in $(env | grep '^kafka_' | grep -v '^kafka_cfg_' | sort); do
  key=$(echo "${VAR}" | sed -r "s/KAFKA_(.*)=.*/\1/g" | tr _ .)
  value=$(echo "${VAR}" | sed -r "s/(.*)=.*/\1/g")
  if egrep -q "(^|^#)${key}" ${KAFKA_HOME}/config/server.properties; then
    sed -r -i "s\\(^|^#)${key}=.*$\\${key}=${!value}\\g" ${KAFKA_HOME}/config/server.properties
  else
    echo "$key=${!value}" >> ${KAFKA_HOME}/config/server.properties
  fi
done

# Logging config
sed -i "s/^kafka\.logs\.dir=.*$/kafka\.logs\.dir=${LOG_DIR}/" ${KAFKA_HOME}/config/log4j.properties

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
  exec ${KAFKA_HOME}/bin/kafka-server-start.sh config/server.properties "$@" &
  pid=$!
  log "[INFO] Started with PID: ${pid}"
  wait ${pid}
  trap - SIGTERM SIGINT
  wait ${pid}
else
  exec "$@"
fi
