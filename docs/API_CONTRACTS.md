# API Contracts & Integration Guide

> **Purpose**: Define contracts between microservices to prevent integration issues

---

## Service Communication Rules

### Golden Rules
1. ✅ **Services communicate ONLY via Kafka events** (no direct HTTP calls between services)
2. ✅ **All events must match schemas defined in CLAUDE.md exactly**
3. ✅ **Event schemas are immutable** - never modify existing fields, only add new ones
4. ✅ **Use semantic versioning for breaking changes** (OrderCreatedEventV2)
5. ✅ **All services must handle idempotency** (duplicate event detection)

---

## Event Schema Contracts

### Contract Version: 1.0
**Last Updated**: 2026-05-27

All events inherit base structure:
```json
{
  "eventId": "uuid",
  "eventType": "EVENT_TYPE",
  "timestamp": "2026-05-27T10:30:00Z"
}
```

### Event Catalog

| Event Name | Producer | Consumers | Payload Size | Retention |
|------------|----------|-----------|--------------|-----------|
| `commerce.order.created` | Order Service | Payment, Notification, Analytics | ~2KB | 7 days |
| `commerce.payment.processed` | Payment Service | Order, Notification, Analytics | ~1KB | 7 days |
| `commerce.payment.failed` | Payment Service | Order | ~1KB | 30 days |
| `commerce.inventory.reserved` | Payment Service | Order, Analytics | ~1KB | 7 days |
| `commerce.inventory.failed` | Payment Service | Order | ~1KB | 30 days |
| `commerce.order.completed` | Order Service | Notification, Analytics | ~1KB | 7 days |
| `commerce.order.cancelled` | Order Service | Payment, Notification, Analytics | ~1KB | 30 days |
| `commerce.dlq` | Any Service | Monitoring | Variable | 90 days |

---

## REST API Contracts

### Order Service APIs

#### POST /api/v1/orders
**Purpose**: Create new order

**Request**:
```json
{
  "customerId": "CUST-123",
  "items": [
    {
      "productId": "PROD-001",
      "productName": "Laptop",
      "quantity": 1,
      "unitPrice": 999.99
    }
  ]
}
```

**Response (201 Created)**:
```json
{
  "orderId": "ORD-12345",
  "customerId": "CUST-123",
  "totalAmount": 999.99,
  "currency": "USD",
  "status": "PENDING",
  "createdAt": "2026-05-27T10:30:00Z"
}
```

**Error Response (400 Bad Request)**:
```json
{
  "error": "INVALID_REQUEST",
  "message": "Customer ID is required",
  "timestamp": "2026-05-27T10:30:00Z"
}
```

#### GET /api/v1/orders/{orderId}
**Response (200 OK)**:
```json
{
  "orderId": "ORD-12345",
  "customerId": "CUST-123",
  "items": [...],
  "totalAmount": 999.99,
  "status": "COMPLETED",
  "createdAt": "2026-05-27T10:30:00Z",
  "completedAt": "2026-05-27T10:35:00Z"
}
```

---

### Payment & Inventory Service APIs

#### GET /api/v1/payments/{paymentId}
**Response (200 OK)**:
```json
{
  "paymentId": "PAY-67890",
  "orderId": "ORD-12345",
  "amount": 999.99,
  "status": "SUCCESS",
  "transactionId": "TXN-ABC123",
  "processedAt": "2026-05-27T10:32:00Z"
}
```

#### GET /api/v1/inventory/{productId}
**Response (200 OK)**:
```json
{
  "productId": "PROD-001",
  "productName": "Laptop",
  "quantityAvailable": 10,
  "quantityReserved": 2
}
```

---

### Notification Service APIs

#### GET /api/v1/notifications?customerId={customerId}
**Response (200 OK)**:
```json
{
  "notifications": [
    {
      "notificationId": "NOTIF-001",
      "type": "EMAIL",
      "subject": "Order Confirmation",
      "status": "SENT",
      "sentAt": "2026-05-27T10:30:05Z"
    }
  ],
  "total": 1
}
```

---

### Analytics Service APIs

#### GET /api/v1/analytics/summary
**Response (200 OK)**:
```json
{
  "totalOrders": 150,
  "completedOrders": 120,
  "cancelledOrders": 30,
  "totalRevenue": 125000.00,
  "averageOrderValue": 833.33,
  "successRate": 80.0,
  "lastUpdated": "2026-05-27T10:30:00Z"
}
```

---

## Event Flow Contracts

### Happy Path: Successful Order

```
1. Client → Order Service: POST /api/v1/orders
2. Order Service → Kafka: commerce.order.created
3. Payment Service ← Kafka: commerce.order.created
4. Payment Service → Kafka: commerce.payment.processed
5. Payment Service → Kafka: commerce.inventory.reserved
6. Order Service ← Kafka: commerce.payment.processed
7. Order Service ← Kafka: commerce.inventory.reserved
8. Order Service → Kafka: commerce.order.completed
9. Notification Service ← Kafka: commerce.order.completed
10. Analytics Service ← Kafka: (all events)
```

**Timing Expectations**:
- Step 1-2: < 200ms
- Step 3-5: < 3 seconds
- Step 6-8: < 500ms
- Total end-to-end: < 5 seconds

---

### Failure Path: Payment Failed

```
1. Client → Order Service: POST /api/v1/orders
2. Order Service → Kafka: commerce.order.created
3. Payment Service ← Kafka: commerce.order.created
4. Payment Service → Retry payment (3 attempts)
5. Payment Service → Kafka: commerce.payment.failed
6. Order Service ← Kafka: commerce.payment.failed
7. Order Service → Kafka: commerce.order.cancelled
```

---

## Data Consistency Rules

### 1. Order Status State Machine

```
PENDING → PROCESSING → COMPLETED
   ↓
CANCELLED
```

**Valid Transitions**:
- `PENDING → PROCESSING`: When payment starts
- `PROCESSING → COMPLETED`: When inventory reserved
- `PENDING → CANCELLED`: Payment failed before processing
- `PROCESSING → CANCELLED`: Inventory failed during processing

**Invalid Transitions**:
- ❌ `COMPLETED → CANCELLED`
- ❌ `COMPLETED → PENDING`
- ❌ `CANCELLED → COMPLETED`

### 2. Payment Status

```
PENDING → SUCCESS
   ↓
FAILED → DLQ
```

### 3. Inventory Reservation

```
REQUESTED → CONFIRMED
     ↓
  FAILED
     ↓
  RELEASED (on order cancellation)
```

---

## Error Handling Contracts

### Standard Error Response Format

All services must return errors in this format:

```json
{
  "error": "ERROR_CODE",
  "message": "Human-readable error description",
  "details": {
    "field": "customerId",
    "reason": "Customer ID is required"
  },
  "timestamp": "2026-05-27T10:30:00Z",
  "path": "/api/v1/orders"
}
```

### Standard Error Codes

| Code | HTTP Status | Meaning | Action |
|------|-------------|---------|--------|
| `INVALID_REQUEST` | 400 | Bad request data | Fix request and retry |
| `RESOURCE_NOT_FOUND` | 404 | Order/payment not found | Verify ID |
| `PAYMENT_FAILED` | 422 | Payment processing failed | Check payment details |
| `INSUFFICIENT_INVENTORY` | 422 | Product out of stock | Notify customer |
| `DUPLICATE_ORDER` | 409 | Order already exists | Use existing order |
| `INTERNAL_ERROR` | 500 | Unexpected error | Contact support |
| `SERVICE_UNAVAILABLE` | 503 | Service temporarily down | Retry later |

---

## Idempotency Contracts

### Event Idempotency

All consumers MUST implement idempotency using `eventId`:

```java
@Transactional
public void processEvent(OrderCreatedEvent event) {
    // Check if already processed
    if (processedEventRepository.existsByEventId(event.getEventId())) {
        log.warn("Event already processed: eventId={}", event.getEventId());
        return; // Skip duplicate
    }
    
    // Process event
    doProcessing(event);
    
    // Mark as processed
    processedEventRepository.save(
        ProcessedEvent.builder()
            .eventId(event.getEventId())
            .processedAt(LocalDateTime.now())
            .build()
    );
}
```

### API Idempotency

Order creation should use idempotency keys (optional enhancement):

```http
POST /api/v1/orders
Idempotency-Key: client-generated-uuid

{
  "customerId": "CUST-123",
  ...
}
```

---

## Testing Contracts

### Integration Test Requirements

Each service must have integration tests covering:

1. ✅ Happy path event flow
2. ✅ Event consumer receives and processes events
3. ✅ Event producer publishes correctly
4. ✅ Idempotency (duplicate events ignored)
5. ✅ Error handling (invalid data rejected)
6. ✅ Retry mechanism (for Payment Service)
7. ✅ DLQ handling (for Payment Service)

### Test Data Conventions

**Customer IDs**:
- `CUST-123`: Normal customer (payment succeeds)
- `CUST-FAIL`: Triggers payment failure
- `CUST-SLOW`: Simulates slow processing (3s delay)

**Product IDs**:
- `PROD-001`: In stock (qty: 10)
- `PROD-002`: Low stock (qty: 1)
- `PROD-003`: Out of stock (qty: 0)

**Order IDs**:
- Format: `ORD-{UUID}` or `ORD-{timestamp}`

---

## Change Management Protocol

### Adding New Fields to Events

✅ **Allowed** (backward compatible):
```java
// Version 1
public class OrderCreatedEvent {
    private String orderId;
    private BigDecimal totalAmount;
}

// Version 2 (adds field, still compatible)
public class OrderCreatedEvent {
    private String orderId;
    private BigDecimal totalAmount;
    private String customerEmail; // NEW - optional
}
```

❌ **Not Allowed** (breaks consumers):
```java
// Version 1
public class OrderCreatedEvent {
    private String orderId;
    private BigDecimal totalAmount;
}

// Version 2 (removes field - BREAKS COMPATIBILITY)
public class OrderCreatedEvent {
    private String orderId;
    // totalAmount removed - BREAKING CHANGE!
}
```

### Making Breaking Changes

1. Create new event version: `OrderCreatedEventV2`
2. Publish to new topic: `commerce.order.created.v2`
3. Update all consumers to handle both versions
4. Deprecate old topic after transition period
5. Update documentation

### Notification Process

**Before making ANY schema changes:**

1. 📢 Announce in team chat/meeting
2. 📝 Update `CLAUDE.md` with new schema
3. 🔔 Tag all affected service owners
4. ⏰ Give 24-hour notice before deploying
5. ✅ Verify all services updated

---

## Monitoring Contracts

### Service Health Checks

All services must implement:

```http
GET /actuator/health

Response:
{
  "status": "UP",
  "components": {
    "kafka": {"status": "UP"},
    "db": {"status": "UP"}
  }
}
```

### Kafka Consumer Lag

Monitor consumer lag to detect processing delays:

```bash
# Should be < 100 messages under normal load
kafka-consumer-groups --bootstrap-server localhost:9092 \
  --describe --group payment-service-group
```

**Alert if**:
- Lag > 1000 messages
- Lag not decreasing over 5 minutes

---

## SLA Commitments (For Demo)

| Metric | Target | Measurement |
|--------|--------|-------------|
| Order creation latency | < 200ms | 95th percentile |
| End-to-end order processing | < 10s | Average |
| Event processing latency | < 1s | 99th percentile |
| Service uptime | > 99% | During demo |
| Payment retry attempts | 3 | Before DLQ |

---

## FAQ

**Q: What if I need to add a new event type?**
A: Follow these steps:
1. Add event schema to CLAUDE.md
2. Notify all team members
3. Update this document with event details
4. Implement producer and consumers
5. Test integration with other services

**Q: What if two services publish conflicting data?**
A: Order Service is the source of truth for order status. Payment/Inventory services publish their results, but Order Service makes final decision.

**Q: How do we handle clock skew between services?**
A: Use UTC timestamps consistently. Event timestamps are set by producer, not consumer.

**Q: What if Kafka is down during demo?**
A: Have backup slides/video showing the expected flow. Explain how Kafka provides durability (events would queue and process when it recovers).

---

**Version**: 1.0  
**Last Updated**: 2026-05-27  
**Next Review**: Before integration testing phase

**For questions, contact the team lead or refer to CLAUDE.md**
