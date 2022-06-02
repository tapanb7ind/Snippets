FROM alpine:latest

ARG JMETER_VERSION="5.4.3"
ENV JMETER_HOME /opt/apache-jmeter
ENV	JMETER_BIN	${JMETER_HOME}/bin
ENV	JMETER_DOWNLOAD_URL https://dlcdn.apache.org//jmeter/binaries/apache-jmeter-${JMETER_VERSION}.tgz


## Installing java and dependencies
RUN    apk update \
    && apk upgrade \
    && apk add ca-certificates \
    && update-ca-certificates \
    && apk add --update openjdk8-jre tzdata curl unzip bash coreutils tar \
    && rm -rf /var/cache/apk/* \
    \
    # download jmeter during image creation
    && mkdir -p /tmp/dependencies \
    && echo "Downloading Jmeter Binary [${JMETER_DOWNLOAD_URL}]" \
    && curl -L ${JMETER_DOWNLOAD_URL} -o /tmp/dependencies/jmeter.tgz \
    && mkdir /opt/jmeter \
    && tar -xzf /tmp/dependencies/jmeter.tgz -C /opt/jmeter --strip-components 1  \    
    && mkdir -p /opt/jmeter/results \
    && mkdir /opt/jmeter/logs/ \
    && mkdir /temp \    
    # Update user.properties to disable secured communication between master and slave
    && echo "Updating user.properties file [START]" \
    && sed 's/#server.rmi.ssl.disable=false/server.rmi.ssl.disable=true/g' /opt/jmeter/bin/user.properties > /tmp/dependencies/user.properties \
    && cp /tmp/dependencies/user.properties /opt/jmeter/bin/user.properties \    
    && grep 'server.rmi.ssl.disable' /opt/jmeter/bin/user.properties \
    && echo "Updating user.properties file [COMPLETE]" \
    \    
    && rm -rf /tmp/dependencies

ENTRYPOINT ["/opt/entrypoint.sh"]

COPY ./entrypointV2.sh /opt/entrypoint.sh
RUN chmod 775 /opt/entrypoint.sh
ENV HOME /opt/jmeter/


# Instructions
# Build using the command [docker build -f Dockerfile -t POD/perf-jmeter:5.4.3.1a .]
