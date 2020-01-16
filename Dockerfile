FROM centos:latest

RUN yum -y install wget unzip \
    && useradd -u 1001 -r -g 0 -s /usr/sbin/nologin default

# Install IBM Java

ENV JAVA_VERSION 1.8.0_sr5fp6
RUN export BASE_URL="https://public.dhe.ibm.com/ibmdl/export/pub/systems/cloud/runtimes/java/meta/sdk/linux/x86_64/index.yml"; \
    && wget -q -U UA_IBM_JAVA_Docker -O /tmp/index.yml ${BASE_URL}; \
    && JAVA_URL=$(cat /tmp/index.yml | sed -n '/'${JAVA_VERSION}'/{n;p}' | sed -n 's/\s*uri:\s//p' | tr -d '\r'); \
    && wget -q -U UA_IBM_JAVA_Docker -O /tmp/ibm-java.bin ${JAVA_URL}; \
    && echo "INSTALLER_UI=silent" > /tmp/response.properties; \
    && echo "USER_INSTALL_DIR=/opt/ibm/java" >> /tmp/response.properties; \
    && echo "LICENSE_ACCEPTED=TRUE" >> /tmp/response.properties; \
    && mkdir -p /opt/ibm; \
    && chmod +x /tmp/ibm-java.bin; \
    && /tmp/ibm-java.bin -i silent -f /tmp/response.properties; \
    && rm -f /tmp/response.properties; \
    && rm -f /tmp/index.yml; \
    && rm -f /tmp/ibm-java.bin; \
    && cd /opt/ibm/java/jre/lib; \
    && rm -rf icc;
ENV JAVA_HOME=/opt/ibm/java/jre \
    PATH=/opt/ibm/java/jre/bin:$PATH
RUN echo ${JAVA_HOME}; \
    echo ${PATH};

# Install WebSphere Liberty
ENV LIBERTY_VERSION 19.0.0_06
RUN LIBERTY_URL=$(wget -q -O - https://public.dhe.ibm.com/ibmdl/export/pub/software/websphere/wasdev/downloads/wlp/index.yml  | grep $LIBERTY_VERSION -A 3 | sed -n 's/\s*webProfile7:\s//p' | tr -d '\r')  \
    && echo $LIBERTY_URL \
    && wget -q $LIBERTY_URL -U UA-IBM-WebSphere-Liberty-Docker -O /tmp/wlp-beta.zip \
    && unzip -q /tmp/wlp-beta.zip -d /opt/ibm \
    && rm /tmp/wlp-beta.zip \
    && chown -R 1001:0 /opt/ibm/wlp \
    && chmod -R g+rw /opt/ibm/wlp
ENV PATH=/opt/ibm/wlp/bin:$PATH

# Set Path Shortcuts
ENV LOG_DIR=/logs \
    WLP_OUTPUT_DIR=/opt/ibm/wlp/output

# Configure WebSphere Liberty
RUN /opt/ibm/wlp/bin/server create \
    && rm -rf $WLP_OUTPUT_DIR/.classCache /output/workarea

# Install features

RUN /opt/ibm/wlp/bin/installUtility install --acceptLicense webProfile-7.0 localConnector-1.0 jndi-1.0 adminCenter-1.0 appSecurity-2.0 concurrent-1.0 ldapRegistry-3.0 javaMail-1.5 jdbc-4.1 jaxrs-2.0 jpa-2.1 ssl-1.0 webCache-1.0 \

# Create symlinks && set permissions for non-root user
RUN mkdir /logs \
    && mkdir /etc/wlp \
    && mkdir -p /opt/ibm/wlp/usr/shared/resources/lib.index.cache \
    && mkdir -p /home/default \
    && mkdir /output \
    && chmod -t /output \
    && rm -rf /output \
    && ln -s $WLP_OUTPUT_DIR/defaultServer /output \
    && ln -s /opt/ibm/wlp/usr/servers/defaultServer /config \
    && ln -s /opt/ibm /liberty \
    && ln -s /opt/ibm/wlp/usr/shared/resources/lib.index.cache /lib.index.cache \
    && mkdir -p /config/configDropins/defaults \
    && chown -R 1001:0 /config \
    && chmod -R g+rw /config \
    && chown -R 1001:0 /opt/ibm/wlp/usr \
    && chmod -R g+rw /opt/ibm/wlp/usr \
    && chown -R 1001:0 /opt/ibm/wlp/output \
    && chmod -R g+rw /opt/ibm/wlp/output \
    && chown -R 1001:0 /logs \
    && chmod -R g+rw /logs \
    && chown -R 1001:0 /etc/wlp \
    && chmod -R g+rw /etc/wlp \
    && chown -R 1001:0 /home/default \
    && chmod -R g+rw /home/default

USER 1001

EXPOSE 9080 9443

CMD ["/opt/ibm/wlp/bin/server", "run", "defaultServer"]
