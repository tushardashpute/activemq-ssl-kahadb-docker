#!/bin/bash

docker exec activemq-ssl sh -lc '
export JAVA_TOOL_OPTIONS="-Djavax.net.ssl.trustStore=/opt/activemq/conf/ssl/client.ts -Djavax.net.ssl.trustStorePassword=changeit"

/opt/activemq/bin/activemq producer \
  --brokerUrl ssl://localhost:61617 \
  --destination queue://SSL.DEMO.QUEUE \
  --message "SSL WORKING"
'
