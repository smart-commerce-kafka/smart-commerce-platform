# Kafka Topics Reference

> **Purpose**: Complete reference for all Kafka topics, partitioning, and configuration

---

## Topic Overview

| Topic Name | Partitions | Replication | Retention | Producers | Consumers |
|------------|------------|-------------|-----------|-----------|-----------|
| `commerce.order.created` | 3 | 1 | 7 days | Order Service | Payment, Notification, Analytics |
| `commerce.payment.processed` | 3 | 1 | 7 days | Payment Service | Order, Notification, Analytics |
| `commerce.payment.failed` | 3 | 1 | 30 days | Payment Service | Order |
| `commerce.inventory.reserved` | 3 | 1 | 7 days | Payment Service | Order, Analytics |
| `commerce.inventory.failed` | 3 | 1 | 30 days | Payment Service | Order |
| `commerce.order.completed` | 3 | 1 | 7 days | Order Service | Notification, Analytics |
| `commerce.order.cancelled` | 3 | 1 | 30 days | Order Service | Payment, Notification, Analytics |
| `commerce.dlq` | 1 | 1 | 90 days | Any Service | Monitoring |

---

## Topic Creation Commands

Run these commands to manually create topics (optional - Kafka auto-creates with defaults):

```bash
# Access Kafka container
docker exec -it kafka bash

# Create topics with 3 partitions each
kafka-topics --create \
  --bootstrap-server localhost:9092 \
  --topic commerce.order.created \
  --partitions 3 \
  --replication-factor 1

kafka-topics --create \
  --bootstrap-server localhost:9092 \
  --topic commerce.payment.processed \
  --partitions 3 \
  --replication-factor 1

kafka-topics --create \
  --bootstrap-server localhost:9092 \
  --topic commerce.payment.failed \
  --partitions 3 \
  --replication-factor 1

kafka-topics --create \
  --bootstrap-server localhost:9092 \
  --topic commerce.inventory.reserved \
  --partitions 3 \
  --replication-factor 1

kafka-topics --create \
  --bootstrap-server localhost:9092 \
  --topic commerce.inventory.failed \
  --partitions 3 \
  --replication-factor 1

kafka-topics --create \
  --bootstrap-server localhost:9092 \
  --topic commerce.order.completed \
  --partitions 3 \
  --replication-factor 1

kafka-topics --create \
  --bootstrap-server localhost:9092 \
  --topic commerce.order.cancelled \
  --partitions 3 \
  --replication-factor 1

kafka-topics --create \
  --bootstrap-server localhost:9092 \
  --topic commerce.dlq \
  --partitions 1 \
  --replication-factor 1
```

---

## Partitioning Strategy

### Key-Based Partitioning

All events use `orderId` as the Kafka message key:

```java
kafkaTemplate.send(
    topicName,
    event.getOrderId(),  // KEY - ensures all events for same order go to same partition
    event                 // VALUE
);
```

**Benefits**:
- All events for same order land in same partition
- Preserves ordering for single order
- Enables parallel processing of different orders

---

## Consumer Groups

### Group IDs

| Service | Consumer Group ID | Topics Consumed |
|---------|-------------------|-----------------|
| Payment Service | `payment-service-group` | `commerce.order.created`, `commerce.order.cancelled` |
| Notification Service | `notification-service-group` | `commerce.order.created`, `commerce.order.completed`, `commerce.order.cancelled` |
| Analytics Service | `analytics-service-group` | All topics |
| Order Service | `order-service-group` | `commerce.payment.processed`, `commerce.payment.failed`, `commerce.inventory.reserved`, `commerce.inventory.failed` |

**Consumer Group Properties**:
- Each group consumes independently (all get same messages)
- Within a group, only ONE consumer processes each message
- Multiple instances of same service = load balancing within group

---

## Monitoring Topics

### List All Topics

```bash
docker exec -it kafka kafka-topics \
  --list \
  --bootstrap-server localhost:9092
```

### Describe Topic

```bash
docker exec -it kafka kafka-topics \
  --describe \
  --topic commerce.order.created \
  --bootstrap-server localhost:9092
```

### Check Consumer Group Lag

```bash
docker exec -it kafka kafka-consumer-groups \
  --bootstrap-server localhost:9092 \
  --describe \
  --group payment-service-group
```

Expected output:
```
TOPIC                    PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG
commerce.order.created   0          42              42              0
commerce.order.created   1          38              38              0
commerce.order.created   2          45              45              0
```

**Lag = 0** means consumer is caught up ✅

---

## Consuming Messages (Debug)

### Consume from Beginning

```bash
docker exec -it kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic commerce.order.created \
  --from-beginning \
  --property print.key=true \
  --property print.timestamp=true
```

### Consume Only New Messages

```bash
docker exec -it kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic commerce.order.created \
  --property print.key=true
```

### Consume with JSON Formatting

```bash
docker exec -it kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic commerce.order.created \
  --from-beginning \
  | jq '.'
```

---

## Producing Test Messages (Debug)

```bash
docker exec -it kafka kafka-console-producer \
  --bootstrap-server localhost:9092 \
  --topic commerce.order.created \
  --property "parse.key=true" \
  --property "key.separator=:"

# Then type:
ORD-TEST-001:{"eventId":"test-uuid","eventType":"ORDER_CREATED","orderId":"ORD-TEST-001","totalAmount":100.00}
```

---

## Topic Retention Policies

### Default Configuration

```properties
# Retention time: 7 days (168 hours)
retention.ms=604800000

# Retention size: 1GB per partition
retention.bytes=1073741824

# Segment size: 1GB
segment.bytes=1073741824
```

### Modifying Retention (For Demo)

```bash
# Reduce retention to 1 hour for testing
docker exec -it kafka kafka-configs \
  --bootstrap-server localhost:9092 \
  --entity-type topics \
  --entity-name commerce.order.created \
  --alter \
  --add-config retention.ms=3600000
```

---

## Event Replay

### Resetting Consumer Group Offset

**Reset to beginning** (replay all events):

```bash
docker exec -it kafka kafka-consumer-groups \
  --bootstrap-server localhost:9092 \
  --group analytics-service-group \
  --reset-offsets \
  --to-earliest \
  --topic commerce.order.created \
  --execute
```

**Reset to specific timestamp**:

```bash
docker exec -it kafka kafka-consumer-groups \
  --bootstrap-server localhost:9092 \
  --group analytics-service-group \
  --reset-offsets \
  --to-datetime 2026-05-27T10:00:00.000 \
  --topic commerce.order.created \
  --execute
```

**Reset to specific offset**:

```bash
docker exec -it kafka kafka-consumer-groups \
  --bootstrap-server localhost:9092 \
  --group analytics-service-group \
  --reset-offsets \
  --to-offset 100 \
  --topic commerce.order.created:0 \
  --execute
```

---

## Troubleshooting

### Issue: Consumer Not Receiving Messages

**Check 1**: Is Kafka running?
```bash
docker ps | grep kafka
```

**Check 2**: Does topic exist?
```bash
docker exec -it kafka kafka-topics --list --bootstrap-server localhost:9092
```

**Check 3**: Are messages in the topic?
```bash
docker exec -it kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic commerce.order.created \
  --from-beginning \
  --max-messages 1
```

**Check 4**: Is consumer group stuck?
```bash
docker exec -it kafka kafka-consumer-groups \
  --bootstrap-server localhost:9092 \
  --describe \
  --group payment-service-group
```

### Issue: High Consumer Lag

**Causes**:
1. Consumer processing too slow (optimize business logic)
2. Too many messages (scale horizontally - add consumer instances)
3. Consumer crashed (check service logs)

**Solution**:
```bash
# Scale consumer (Docker Compose)
docker-compose up -d --scale payment-inventory-service=3
```

### Issue: Messages Going to Wrong Partition

**Cause**: Inconsistent message keys

**Fix**: Always use `orderId` as key
```java
// ❌ Wrong
kafkaTemplate.send("commerce.order.created", event);

// ✅ Correct
kafkaTemplate.send("commerce.order.created", event.getOrderId(), event);
```

---

## Kafka UI Access

**URL**: http://localhost:8090

**Features**:
- Browse topics and messages
- View consumer groups and lag
- Monitor broker health
- Search messages by key/value
- View topic configuration

---

## Performance Tuning (Optional)

### Increase Throughput

```yaml
# application.yml (producer)
spring:
  kafka:
    producer:
      batch-size: 16384
      linger-ms: 10
      compression-type: snappy
```

### Improve Consumer Performance

```yaml
# application.yml (consumer)
spring:
  kafka:
    consumer:
      fetch-min-size: 1024
      fetch-max-wait: 500
      max-poll-records: 500
    listener:
      concurrency: 3  # Number of consumer threads
```

---

## Demo Checklist

Before demo, verify:

- [ ] All topics created
- [ ] All consumers registered (check consumer groups)
- [ ] Consumer lag = 0 for all groups
- [ ] Kafka UI accessible
- [ ] Test message flows through all topics
- [ ] DLQ topic ready for failure scenarios

---

**Version**: 1.0  
**Last Updated**: 2026-05-27  
**Maintained By**: All Team Members
