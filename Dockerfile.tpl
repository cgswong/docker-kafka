FROM cgswong/java:openjre8
MAINTAINER Stuart Wong <cgs.wong@gmail.com>

ENV KAFKA_VERSION %%VERSION%%
ENV KAFKA_USER kafka
ENV KAFKA_GROUP kafka
ENV KAFKA_HOME /opt/kafka
ENV KAFKA_DIR /var/lib/kafka

ENV SCALA_2_10_URL https://www.apache.org/dyn/closer.cgi?path=/kafka/${KAFKA_VERSION}/kafka_2.10-${KAFKA_VERSION}.tgz
ENV SCALA_2_11_URL https://www.apache.org/dyn/closer.cgi?path=/kafka/${KAFKA_VERSION}/kafka_2.11-${KAFKA_VERSION}.tgz

COPY kafka.sh /usr/local/bin/kafka.sh

RUN apk --update add \
      curl \
      bash \
      tar &&\
    mkdir -p ${KAFKA_DIR}/log /opt &&\
    [[ ${KAFKA_VERSION} =~ "0.9"* ]] && curl -sSL {$SCALA_2_11_URL} | tar zxf - -C /opt || curl -sSL {$SCALA_2_11_URL} | tar zxf - -C /opt &&\
    ln -s /opt/kafka_2.*-${KAFKA_VERSION} ${KAFKA_HOME} &&\
    addgroup $KAFKA_GROUP &&\
    adduser -h ${KAFKA_DIR} -D -s /bin/bash -G ${KAFKA_GROUP} ${KAFKA_USER} &&\
    chown -R ${KAFKA_USER}:${KAFKA_GROUP} ${KAFKA_DIR} ${KAFKA_HOME}/ &&\
    chmod +x /usr/local/bin/kafka.sh

USER ${KAFKA_USER}

# Expose client port (9092/tcp)
EXPOSE 9092

VOLUME ["${KAFKA_DIR}"]

ENTRYPOINT ["/usr/local/bin/kafka.sh"]
CMD [""]
