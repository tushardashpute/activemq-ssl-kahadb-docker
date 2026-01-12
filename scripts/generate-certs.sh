#!/bin/bash
set -e

PASSWORD=changeit
DAYS=3650

mkdir -p ssl
cd ssl

echo "== Generating broker keystore =="
keytool -genkeypair \
  -alias activemq-broker \
  -keyalg RSA \
  -keysize 2048 \
  -dname "CN=localhost, OU=IT, O=Demo, L=BLR, ST=KA, C=IN" \
  -keystore broker.jks \
  -storepass $PASSWORD \
  -keypass $PASSWORD \
  -validity $DAYS

echo "== Export broker certificate =="
keytool -exportcert \
  -alias activemq-broker \
  -keystore broker.jks \
  -storepass $PASSWORD \
  -file broker.crt

echo "== Create client truststore =="
keytool -importcert \
  -alias activemq-broker \
  -file broker.crt \
  -keystore client.ts \
  -storepass $PASSWORD \
  -noprompt

echo "✔ SSL artifacts generated"
