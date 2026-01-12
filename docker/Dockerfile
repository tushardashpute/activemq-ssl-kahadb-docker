FROM rmohr/activemq:5.15.16

USER root

# Create SSL directory
RUN mkdir -p /opt/activemq/conf/ssl

# Copy ActiveMQ configuration
COPY conf/activemq.xml /opt/activemq/conf/activemq.xml

# Copy SSL artifacts
COPY ssl /opt/activemq/conf/ssl

RUN chown -R activemq:activemq /opt/activemq/conf/ssl

USER activemq

EXPOSE 61616 61617 8161

CMD ["/opt/activemq/bin/activemq", "console"]
