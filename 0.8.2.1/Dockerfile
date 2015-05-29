# DESC: Docker file to create Apache Kafka container

FROM gliderlabs/alpine:3.1

ENV KAFKA_VERSION 0.8.2.1
ENV KAFKA_USER kafka
ENV KAFKA_GROUP kafka
ENV KAFKA_HOME /opt/kafka
ENV KAFKA_DIR /var/lib/kafka

ENV SCALA_VERSION 2.11

ENV JAVA_VERSION_MAJOR 8
ENV JAVA_VERSION_MINOR 45
ENV JAVA_VERSION_BUILD 14
ENV JAVA_BASE /usr/local/java
ENV JAVA_HOME ${JAVA_BASE}/jdk
ENV PATH $PATH:$JAVA_HOME/bin

COPY kafka.sh /usr/local/bin/kafka.sh

RUN apk --update add \
      curl \
      bash &&\
    curl --insecure --silent --location "https://circle-artifacts.com/gh/andyshinn/alpine-pkg-glibc/6/artifacts/0/home/ubuntu/alpine-pkg-glibc/packages/x86_64/glibc-2.21-r2.apk" --output /tmp/glibc-2.21-r2.apk &&\
    curl --insecure --silent --location "https://circle-artifacts.com/gh/andyshinn/alpine-pkg-glibc/6/artifacts/0/home/ubuntu/alpine-pkg-glibc/packages/x86_64/glibc-bin-2.21-r2.apk" --output /tmp/glibc-bin-2.21-r2.apk &&\
    apk add --allow-untrusted /tmp/glibc-2.21-r2.apk \
      /tmp/glibc-bin-2.21-r2.apk &&\
    /usr/glibc/usr/bin/ldconfig /lib /usr/glibc/usr/lib &&\
    curl --insecure --silent --location --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-b${JAVA_VERSION_BUILD}/jdk-${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-linux-x64.tar.gz --output /tmp/jdk-${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-linux-x64.tar.gz &&\
    mkdir -p ${JAVA_BASE} /opt &&\
    tar zxf /tmp/jdk-${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-linux-x64.tar.gz -C ${JAVA_BASE} &&\
    ln -s ${JAVA_BASE}/jdk1.${JAVA_VERSION_MAJOR}.0_${JAVA_VERSION_MINOR} ${JAVA_BASE}/jdk &&\
    curl --insecure --silent --show-error --location http://mirrors.ibiblio.org/apache/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz | tar -xzf - -C /opt &&\
    ln -s /opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION} $KAFKA_HOME &&\
    rm -rf /tmp/* &&\
#    groupadd -r $KAFKA_GROUP &&\
#    useradd -c "Kafka" -d $KAFKA_DIR -g $KAFKA_GROUP -M -r -s /sbin/nologin $KAFKA_USER &&\
    mkdir -p ${KAFKA_DIR}/log &&\
#    chown -R $KAFKA_USER:$KAFKA_GROUP $KAFKA_DIR &&\
    chmod +x /usr/local/bin/kafka.sh

#USER $KAFKA_USER

# Expose client port (9092/tcp)
EXPOSE 9092

VOLUME ["${KAFKA_DIR}"]

ENTRYPOINT ["/usr/local/bin/kafka.sh"]
CMD [""]