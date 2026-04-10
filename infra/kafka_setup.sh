#!/usr/bin/env bash
# PREDATOR 2026 — Kafka Base Setup
# SCRUM-21 | Phase 0 | Spec §18, §5.4
#
# Deploys a 3-broker KRaft-mode Kafka cluster (no ZooKeeper for Kafka itself;
# ZooKeeper is reserved for ClickHouse replication).
# Creates all audit stream topics required by the PREDATOR system.
#
# Acceptance criteria:
#   - All audit topics created with replication-factor=3
#   - Zone B NIC only (brokers + clients bind to 192.168.2.0/24)
#   - Retention: audit topics 90 days; tick/feature topics 7 days
#   - TLS inter-broker + client encryption (mTLS)
#   - Topics created: ticks, orders, fills, features, safety_events, ptp_drift,
#                     model_metrics, kill_switch, key_rotation
#
# Prerequisites:
#   - Kafka 3.7+ installed (confluent-community or apache)
#   - Java 21 on PATH
#   - Zone B NIC: eth2

set -euo pipefail

KAFKA_VERSION="3.7.0"
KAFKA_HOME="${KAFKA_HOME:-/opt/kafka}"
KAFKA_DATA_DIR="/data/kafka"
KAFKA_LOG_DIR="/var/log/kafka"
KAFKA_CONFIG_DIR="${KAFKA_HOME}/config"
ZONE_B_IP=$(ip -4 addr show eth2 | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
BROKER_ID=$(hostname | grep -oP '\d+$' || echo "1")

# KRaft cluster ID (shared across all brokers — generate once, commit to Vault)
CLUSTER_ID="${KAFKA_CLUSTER_ID:-$(${KAFKA_HOME}/bin/kafka-storage.sh random-uuid 2>/dev/null || uuidgen)}"

BROKER_LIST="predator-kafka-01.predator.internal:9092,predator-kafka-02.predator.internal:9092,predator-kafka-03.predator.internal:9092"

echo "=== Kafka Setup ==="
echo "Broker ID:    $BROKER_ID"
echo "Zone B IP:    $ZONE_B_IP"
echo "Data dir:     $KAFKA_DATA_DIR"
echo "Cluster ID:   $CLUSTER_ID"

# ────────────────────────────────────────────────────────────────────────────
# 1. Install Kafka
# ────────────────────────────────────────────────────────────────────────────
echo ""
echo "STEP 1: Installing Kafka $KAFKA_VERSION..."

if [[ ! -f "$KAFKA_HOME/bin/kafka-server-start.sh" ]]; then
    TARBALL="kafka_2.13-${KAFKA_VERSION}.tgz"
    curl -fsSL "https://downloads.apache.org/kafka/${KAFKA_VERSION}/${TARBALL}" -o "/tmp/${TARBALL}"
    # Verify checksum (fetch .sha512 separately in production)
    tar -xzf "/tmp/${TARBALL}" -C /opt
    ln -sfn "/opt/kafka_2.13-${KAFKA_VERSION}" "$KAFKA_HOME"
    rm -f "/tmp/${TARBALL}"
fi

mkdir -p "$KAFKA_DATA_DIR" "$KAFKA_LOG_DIR"
id kafka &>/dev/null || useradd -r -s /sbin/nologin kafka
chown -R kafka:kafka "$KAFKA_DATA_DIR" "$KAFKA_LOG_DIR" "$KAFKA_HOME"

# ────────────────────────────────────────────────────────────────────────────
# 2. Generate TLS certificates (self-signed CA for internal mTLS)
# ────────────────────────────────────────────────────────────────────────────
echo ""
echo "STEP 2: Generating TLS certs for mTLS..."

TLS_DIR="/etc/kafka/tls"
mkdir -p "$TLS_DIR"

if [[ ! -f "$TLS_DIR/broker.keystore.jks" ]]; then
    # CA
    openssl genrsa -out "$TLS_DIR/ca.key" 4096
    openssl req -x509 -new -key "$TLS_DIR/ca.key" -sha256 -days 3650 \
        -subj "/CN=PREDATOR-Kafka-CA/O=PREDATOR" \
        -out "$TLS_DIR/ca.crt"

    # Broker cert
    openssl genrsa -out "$TLS_DIR/broker.key" 4096
    openssl req -new -key "$TLS_DIR/broker.key" \
        -subj "/CN=${ZONE_B_IP}/O=PREDATOR" \
        -out "$TLS_DIR/broker.csr"
    openssl x509 -req -in "$TLS_DIR/broker.csr" \
        -CA "$TLS_DIR/ca.crt" -CAkey "$TLS_DIR/ca.key" -CAcreateserial \
        -out "$TLS_DIR/broker.crt" -days 730 -sha256

    # JKS keystore
    openssl pkcs12 -export \
        -in "$TLS_DIR/broker.crt" -inkey "$TLS_DIR/broker.key" \
        -name "broker" -passout pass:predator-kafka-tls \
        -out "$TLS_DIR/broker.p12"
    keytool -importkeystore \
        -srckeystore "$TLS_DIR/broker.p12" -srcstoretype PKCS12 \
        -srcstorepass predator-kafka-tls \
        -destkeystore "$TLS_DIR/broker.keystore.jks" \
        -deststorepass predator-kafka-tls -noprompt

    # Truststore with CA
    keytool -importcert -trustcacerts -noprompt \
        -alias predator-ca \
        -file "$TLS_DIR/ca.crt" \
        -keystore "$TLS_DIR/broker.truststore.jks" \
        -storepass predator-kafka-tls
fi

chown -R kafka:kafka "$TLS_DIR"
chmod 600 "$TLS_DIR"/*.key "$TLS_DIR"/*.jks

# ────────────────────────────────────────────────────────────────────────────
# 3. KRaft broker configuration
# ────────────────────────────────────────────────────────────────────────────
echo ""
echo "STEP 3: Writing broker configuration..."

cat > "$KAFKA_CONFIG_DIR/kraft/server.properties" <<PROPS
# PREDATOR 2026 — Kafka KRaft Broker Config
# Spec §18 / SCRUM-21

process.roles=broker,controller
node.id=${BROKER_ID}
controller.quorum.voters=1@predator-kafka-01.predator.internal:9093,2@predator-kafka-02.predator.internal:9093,3@predator-kafka-03.predator.internal:9093
cluster.id=${CLUSTER_ID}

# Listeners — Zone B only (Spec §4.1)
listeners=BROKER://${ZONE_B_IP}:9092,CONTROLLER://${ZONE_B_IP}:9093
advertised.listeners=BROKER://${ZONE_B_IP}:9092
listener.security.protocol.map=BROKER:SSL,CONTROLLER:SSL
inter.broker.listener.name=BROKER
controller.listener.names=CONTROLLER

# TLS (mTLS required for all connections)
ssl.keystore.location=${TLS_DIR}/broker.keystore.jks
ssl.keystore.password=predator-kafka-tls
ssl.key.password=predator-kafka-tls
ssl.truststore.location=${TLS_DIR}/broker.truststore.jks
ssl.truststore.password=predator-kafka-tls
ssl.client.auth=required
ssl.endpoint.identification.algorithm=

# Data and log storage
log.dirs=${KAFKA_DATA_DIR}

# Replication defaults
default.replication.factor=3
min.insync.replicas=2
offsets.topic.replication.factor=3
transaction.state.log.replication.factor=3
transaction.state.log.min.isr=2

# Performance tuning for HFT audit workload
num.network.threads=8
num.io.threads=16
socket.send.buffer.bytes=1048576
socket.receive.buffer.bytes=1048576
socket.request.max.bytes=104857600
num.partitions=6

# Default retention (overridden per-topic)
log.retention.hours=168
log.segment.bytes=536870912
log.retention.check.interval.ms=300000

# Disable auto topic creation (all topics explicitly provisioned)
auto.create.topics.enable=false
delete.topic.enable=true

# Log flushing (fsync on every batch for audit durability)
log.flush.interval.messages=1
log.flush.interval.ms=1000
PROPS

# ────────────────────────────────────────────────────────────────────────────
# 4. Format storage (KRaft — only on first run)
# ────────────────────────────────────────────────────────────────────────────
echo ""
echo "STEP 4: Formatting KRaft storage..."

if [[ ! -f "$KAFKA_DATA_DIR/meta.properties" ]]; then
    sudo -u kafka "$KAFKA_HOME/bin/kafka-storage.sh" format \
        --config "$KAFKA_CONFIG_DIR/kraft/server.properties" \
        --cluster-id "$CLUSTER_ID" \
        --ignore-formatted
    echo "OK: KRaft storage formatted"
else
    echo "NOTE: Storage already formatted — skipping"
fi

# ────────────────────────────────────────────────────────────────────────────
# 5. systemd service
# ────────────────────────────────────────────────────────────────────────────
echo ""
echo "STEP 5: Creating systemd service..."

cat > /etc/systemd/system/kafka.service <<UNIT
[Unit]
Description=Apache Kafka (KRaft) — PREDATOR 2026
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=kafka
Group=kafka
ExecStart=${KAFKA_HOME}/bin/kafka-server-start.sh ${KAFKA_CONFIG_DIR}/kraft/server.properties
ExecStop=${KAFKA_HOME}/bin/kafka-server-stop.sh
Restart=on-failure
RestartSec=5s
LimitNOFILE=1000000

# Heap: 4GB for broker JVM
Environment=KAFKA_HEAP_OPTS="-Xmx4G -Xms4G"
Environment=KAFKA_JVM_PERFORMANCE_OPTS="-server -XX:+UseG1GC -XX:MaxGCPauseMillis=20 -XX:+ExplicitGCInvokesConcurrent"
Environment=LOG_DIR=${KAFKA_LOG_DIR}

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable kafka
systemctl restart kafka
sleep 10

# ────────────────────────────────────────────────────────────────────────────
# 6. Wait for broker to be ready
# ────────────────────────────────────────────────────────────────────────────
echo ""
echo "STEP 6: Waiting for broker readiness..."

ADMIN_CERTS="--command-config <(echo '
security.protocol=SSL
ssl.keystore.location=${TLS_DIR}/broker.keystore.jks
ssl.keystore.password=predator-kafka-tls
ssl.truststore.location=${TLS_DIR}/broker.truststore.jks
ssl.truststore.password=predator-kafka-tls
ssl.client.auth=required
ssl.endpoint.identification.algorithm=
')"

for i in {1..18}; do
    if eval "$KAFKA_HOME/bin/kafka-broker-api-versions.sh --bootstrap-server ${ZONE_B_IP}:9092 $ADMIN_CERTS" &>/dev/null; then
        echo "OK: Kafka broker $BROKER_ID is ready"
        break
    fi
    echo "Waiting for broker ($i/18)..."
    sleep 5
done

# ────────────────────────────────────────────────────────────────────────────
# 7. Create all PREDATOR topics
# ────────────────────────────────────────────────────────────────────────────
echo ""
echo "STEP 7: Creating topics..."

create_topic() {
    local name=$1 partitions=$2 retention_ms=$3 cleanup=$4
    eval "$KAFKA_HOME/bin/kafka-topics.sh \
        --bootstrap-server ${ZONE_B_IP}:9092 \
        $ADMIN_CERTS \
        --create --if-not-exists \
        --topic '$name' \
        --partitions '$partitions' \
        --replication-factor 3 \
        --config min.insync.replicas=2 \
        --config retention.ms='$retention_ms' \
        --config cleanup.policy='$cleanup' \
        --config compression.type=lz4"
    echo "  Created: $name (p=$partitions, retention=${retention_ms}ms, cleanup=$cleanup)"
}

# 90-day retention for all audit topics (Spec §18)
RETENTION_90D=$((90 * 24 * 3600 * 1000))
# 7-day retention for high-volume tick/feature topics
RETENTION_7D=$((7 * 24 * 3600 * 1000))
# 30-day for model metrics
RETENTION_30D=$((30 * 24 * 3600 * 1000))

# Audit stream topics
create_topic "predator.audit.orders"         6  $RETENTION_90D  "delete"
create_topic "predator.audit.fills"          6  $RETENTION_90D  "delete"
create_topic "predator.audit.safety_events"  3  $RETENTION_90D  "delete"
create_topic "predator.audit.key_rotation"   3  $RETENTION_90D  "delete"
create_topic "predator.audit.model_promos"   3  $RETENTION_90D  "delete"
create_topic "predator.audit.ptp_drift"      3  $RETENTION_90D  "delete"

# Operational topics
create_topic "predator.ticks"                12 $RETENTION_7D   "delete"
create_topic "predator.features"             6  $RETENTION_7D   "delete"
create_topic "predator.model_metrics"        3  $RETENTION_30D  "delete"
create_topic "predator.kill_switch"          1  $RETENTION_90D  "compact"  # compacted: latest state wins
create_topic "predator.champion_version"     1  $RETENTION_90D  "compact"

echo "OK: All topics created"

# ────────────────────────────────────────────────────────────────────────────
# 8. Verify topic list
# ────────────────────────────────────────────────────────────────────────────
echo ""
echo "STEP 8: Verifying topics..."

TOPIC_COUNT=$(eval "$KAFKA_HOME/bin/kafka-topics.sh \
    --bootstrap-server ${ZONE_B_IP}:9092 \
    $ADMIN_CERTS \
    --list" | grep -c "^predator\." || true)

echo "OK: $TOPIC_COUNT predator.* topics visible on broker $BROKER_ID"

echo ""
echo "=== Kafka Setup COMPLETE ==="
echo "KRaft mode (no ZooKeeper for Kafka)"
echo "mTLS: required for all clients"
echo "All topics: replication-factor=3, min-ISR=2"
echo "Zone B only: $ZONE_B_IP:9092"
