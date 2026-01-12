---

# Apache ActiveMQ SSL Setup and Testing with Docker

This guide demonstrates setting up **Apache ActiveMQ 5.15.6** with **SSL/TLS**, producing and consuming messages securely, and verifying **KahaDB** message persistence.

---

## Prerequisites

* Docker installed on your machine
* ActiveMQ 5.15.6 installed inside the container at `/opt/activemq`
* Java 8 installed in the container
* OpenSSL and keytool available for certificate generation

---

## 1️⃣ Directory & Configuration

Assuming your ActiveMQ installation structure:

```
/opt/activemq/
├─ bin/
├─ conf/
│  └─ ssl/
├─ data/
├─ lib/
└─ activemq.xml
```

Ensure your `activemq.xml` is configured for SSL:

```xml
<transportConnectors>
    <transportConnector name="ssl"
      uri="ssl://0.0.0.0:61617?needClientAuth=false&amp;wantClientAuth=false"/>
</transportConnectors>

<sslContext>
    <sslContext
        keyStore="/opt/activemq/conf/ssl/broker.jks"
        keyStorePassword="changeit"
        trustStore="/opt/activemq/conf/ssl/client.ts"
        trustStorePassword="changeit"/>
</sslContext>
```

---

## 2️⃣ Generate Broker & Client Certificates

1. **Broker KeyStore** (`broker.jks`):

```bash
keytool -genkeypair -alias activemq-broker \
  -keyalg RSA -keysize 2048 \
  -dname "CN=localhost, OU=IT, O=Demo, L=BLR, ST=KA, C=IN" \
  -keystore /opt/activemq/conf/ssl/broker.jks \
  -storepass changeit -validity 7300
```

2. **Export Broker Certificate**:

```bash
keytool -export -alias activemq-broker \
  -keystore /opt/activemq/conf/ssl/broker.jks \
  -file /opt/activemq/conf/ssl/broker.cer -storepass changeit
```

3. **Create Client TrustStore** (`client.ts`) and import broker certificate:

```bash
keytool -import -alias activemq-broker \
  -file /opt/activemq/conf/ssl/broker.cer \
  -keystore /opt/activemq/conf/ssl/client.ts \
  -storepass changeit -noprompt
```

4. **Verify the truststore**:

```bash
keytool -list -v -keystore /opt/activemq/conf/ssl/client.ts -storepass changeit
```

---

## 3️⃣ Start ActiveMQ Broker

```bash
docker exec -it activemq-ssl sh -lc '/opt/activemq/bin/activemq start'
```

Verify broker starts with SSL:

```bash
docker logs activemq-ssl | grep ssl
```

Expected output:

```
INFO | Listening for connections at: ssl://<broker-id>:61617?needClientAuth=false&wantClientAuth=false
```

---

## 4️⃣ Produce Messages Over SSL

**Set `JAVA_TOOL_OPTIONS` to point to client truststore**:

```bash
docker exec activemq-ssl sh -lc '
export JAVA_TOOL_OPTIONS="-Djavax.net.ssl.trustStore=/opt/activemq/conf/ssl/client.ts -Djavax.net.ssl.trustStorePassword=changeit"
 /opt/activemq/bin/activemq producer \
  --brokerUrl ssl://localhost:61617 \
  --destination queue://SSL.TEST.QUEUE \
  --message "SSL WORKING FINAL"
'
```

Expected output:

```
INFO | producer-1 Produced: 1000 messages
```

---

## 5️⃣ Check KahaDB BEFORE Consume

```bash
docker exec activemq-ssl sh -lc 'echo "--- KahaDB BEFORE consume ---"; ls -lh /opt/activemq/data/kahadb'
```

Expected:

```
db-1.log  db.data  db.redo  lock
```

---

## 6️⃣ Consume Messages Over SSL

**Use `JAVA_TOOL_OPTIONS` for truststore**:

```bash
docker exec activemq-ssl sh -lc '
export JAVA_TOOL_OPTIONS="-Djavax.net.ssl.trustStore=/opt/activemq/conf/ssl/client.ts -Djavax.net.ssl.trustStorePassword=changeit"
 /opt/activemq/bin/activemq consumer \
  --brokerUrl ssl://localhost:61617 \
  --destination queue://SSL.TEST.QUEUE \
  --messageCount 1
'
```

Expected output:

```
INFO | Consuming queue://SSL.TEST.QUEUE
INFO | Received message: SSL WORKING FINAL
```

> ✅ Note: Using `JAVA_TOOL_OPTIONS` ensures the JVM trusts the broker certificate.

---

## 7️⃣ Check KahaDB AFTER Consume

```bash
docker exec activemq-ssl sh -lc 'echo "--- KahaDB AFTER consume ---"; ls -lh /opt/activemq/data/kahadb'
```

* Files remain (`db-*.log`, `db.data`, `db.redo`, `lock`)
* The consumed message is no longer in the queue
* ActiveMQ uses append-only journals, so physical files are not deleted

---

## 8️⃣ Observations

* SSL connection works for both producer and consumer.
* Broker certificate is trusted via `client.ts`.
* KahaDB persistence is verified; message consumption is correctly reflected in the broker.
* After consumption, the journal files remain (normal behavior).

---

## 9️⃣ Troubleshooting

| Problem                      | Solution                                                               |
| ---------------------------- | ---------------------------------------------------------------------- |
| `PKIX path building failed`  | Ensure `JAVA_TOOL_OPTIONS` points to truststore containing broker cert |
| `Could not create Transport` | Remove invalid URL parameters; use default: `ssl://localhost:61617`    |
| Messages not consumed        | Verify queue name matches producer destination                         |

---

## 10️⃣ References

* [ActiveMQ SSL Configuration](http://activemq.apache.org/ssl-transport-reference.html)
* [KahaDB Persistence](http://activemq.apache.org/kahadb)
* [Java Keytool Documentation](https://docs.oracle.com/javase/8/docs/technotes/tools/windows/keytool.html)

Do you want me to add that?
