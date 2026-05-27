# System Architecture

## Overview

The Smart Commerce Platform is built using **Event-Driven Microservices Architecture** with Apache Kafka as the central message broker.

## Architecture Diagram

```
┌─────────────┐
│   Client    │
│  (Postman/  │
│  Browser)   │
└──────┬──────┘
       │ HTTP REST
       ▼
┌─────────────────────────────────────────────────────────────┐
│                     API Layer                                │
└─────────────────────────────────────────────────────────────┘
       │                    │                    │
       ▼                    ▼                    ▼
┏━━━━━━━━━━━━━┓    ┏━━━━━━━━━━━━━┓    ┏━━━━━━━━━━━━━┓
┃   Order     ┃    ┃  Payment &  ┃    ┃Notification ┃
┃  Service    ┃    ┃  Inventory  ┃    ┃  Service    ┃
┃  (8081)     ┃    ┃  (8082)     ┃    ┃  (8083)     ┃
┗━━━━━┯━━━━━━━┛    ┗━━━━━┯━━━━━━━┛    ┗━━━━━┯━━━━━━━┛
      │ Produce          │ Consume          │ Consume
      │ Events           │ & Produce        │ Events
      ▼                  ▼                  ▼
┌─────────────────────────────────────────────────────────────┐
│                  Apache Kafka (9092)                         │
│  Topics: order.created, payment.processed,                   │
│         inventory.reserved, order.completed, dlq             │
└─────────────────────────────────────────────────────────────┘
                         ▲
                         │ Consume
                         │
                  ┏━━━━━━┻━━━━━━━┓
                  ┃  Analytics   ┃
                  ┃   Service    ┃
                  ┃   (8084)     ┃
                  ┗━━━━━━━━━━━━━━┛
                         │
                         ▼
                  ┌──────────────┐
                  │  PostgreSQL  │
                  │   (5432)     │
                  └──────────────┘
```

## Design Patterns

### 1. Event-Driven Architecture
- **Asynchronous Communication**: Services communicate via Kafka events
- **Loose Coupling**: Services don't need to know about each other
- **Scalability**: Each service can scale independently

### 2. Saga Pattern (Choreography-based)
- **Distributed Transactions**: Order lifecycle spans multiple services
- **Eventual Consistency**: System reaches consistent state over time
- **Compensating Transactions**: Rollback via cancellation events

**Saga Flow Example:**
```
Order Created → Payment Processing → Inventory Reserved → Order Completed
                    ↓ (failure)
                Payment Failed → Order Cancelled (rollback)
```

### 3. CQRS (Command Query Responsibility Segregation)
- **Analytics Service**: Read-optimized view from events
- **Separate Models**: Write model (Order) vs Read model (Analytics)

### 4. Dead Letter Queue (DLQ)
- **Failure Handling**: Failed events sent to DLQ after retries
- **Monitoring**: Alerts on DLQ growth
- **Manual Intervention**: Review and replay failed events

## Service Responsibilities

### Order Service (Student A)
**Role**: Saga orchestrator and order lifecycle manager

**Responsibilities:**
- Accept order creation requests
- Validate order data
- Publish `OrderCreatedEvent` to Kafka
- Listen for payment/inventory success/failure events
- Update order status (PENDING → CONFIRMED → COMPLETED)
- Trigger rollback on failure (publish `OrderCancelledEvent`)

**Database**: `order_db`
- `orders` table
- `order_items` table

**Kafka:**
- **Produces**: `commerce.order.created`, `commerce.order.completed`, `commerce.order.cancelled`
- **Consumes**: `commerce.payment.processed`, `commerce.payment.failed`, `commerce.inventory.failed`

---

### Payment & Inventory Service (Student B)
**Role**: Process payments and manage inventory reservations

**Responsibilities:**
- Consume `OrderCreatedEvent`
- Simulate payment processing (success/failure)
- Reserve inventory for order items
- Implement retry mechanism (3 attempts)
- Send failed events to DLQ after max retries
- Publish success/failure events

**Database**: `payment_db`
- `payments` table
- `inventory` table
- `inventory_reservations` table

**Kafka:**
- **Produces**: `commerce.payment.processed`, `commerce.payment.failed`, `commerce.inventory.reserved`, `commerce.inventory.failed`, `commerce.dlq`
- **Consumes**: `commerce.order.created`, `commerce.order.cancelled` (release inventory)

**Advanced Features:**
- Idempotency: Don't process same order twice
- Retry with exponential backoff
- DLQ for persistent failures

---

### Notification Service (Student C)
**Role**: Customer engagement via notifications

**Responsibilities:**
- Consume order, payment, and inventory events
- Send email/SMS notifications (simulated)
- Support multiple notification templates
- Track notification history

**Database**: `notification_db`
- `notifications` table
- `notification_templates` table

**Kafka:**
- **Produces**: None (pure consumer)
- **Consumes**: `commerce.order.created`, `commerce.payment.processed`, `commerce.order.completed`, `commerce.order.cancelled`

**Notification Types:**
- Order Confirmation (order created)
- Payment Success (payment processed)
- Order Shipped (order completed)
- Order Cancelled (order cancelled)

---

### Analytics Service (Student D)
**Role**: Real-time business intelligence

**Responsibilities:**
- Consume all events for analytics
- Calculate real-time metrics (revenue, order count, etc.)
- Provide dashboard APIs
- Support event replay for historical analysis

**Database**: `analytics_db`
- `order_analytics` table
- `revenue_metrics` table
- `event_log` table (for replay)

**Kafka:**
- **Produces**: None (pure consumer)
- **Consumes**: All topics (`commerce.order.*`, `commerce.payment.*`, `commerce.inventory.*`)

**Metrics Provided:**
- Total orders (today, this week, this month)
- Total revenue
- Success rate (completed vs cancelled orders)
- Average order value
- Top products

---

## Data Flow

### Happy Path: Successful Order
```
1. Client → POST /api/v1/orders → Order Service
2. Order Service → Save order (status: PENDING) → Database
3. Order Service → Publish OrderCreatedEvent → Kafka
4. Payment Service ← Consume OrderCreatedEvent ← Kafka
5. Payment Service → Process payment → Publish PaymentProcessedEvent
6. Inventory Service → Reserve inventory → Publish InventoryReservedEvent
7. Order Service ← Consume success events ← Kafka
8. Order Service → Update order (status: COMPLETED)
9. Notification Service ← Consume OrderCompletedEvent ← Send email
10. Analytics Service ← Consume all events ← Update metrics
```

### Failure Path: Payment Failed
```
1. Client → POST /api/v1/orders → Order Service
2. Order Service → Save order (status: PENDING)
3. Order Service → Publish OrderCreatedEvent → Kafka
4. Payment Service ← Consume OrderCreatedEvent
5. Payment Service → Process payment → FAILURE (insufficient funds)
6. Payment Service → Retry (attempt 1, 2, 3) → Still fails
7. Payment Service → Publish PaymentFailedEvent
8. Order Service ← Consume PaymentFailedEvent
9. Order Service → Update order (status: CANCELLED)
10. Order Service → Publish OrderCancelledEvent (rollback)
11. Notification Service → Send "Order Cancelled" email
12. Analytics Service → Update failure metrics
```

### Failure Path: Inventory Out of Stock
```
1-4. Same as happy path
5. Inventory Service → Check stock → OUT_OF_STOCK
6. Inventory Service → Publish InventoryFailedEvent
7. Order Service ← Consume InventoryFailedEvent
8. Order Service → Publish OrderCancelledEvent
9. Payment Service → Refund payment (if already processed)
10. Notification Service → Send "Order Cancelled - Out of Stock" email
```

---

## Resilience & Fault Tolerance

### 1. Retry Mechanism
```java
// Payment Service example
@RetryableTopic(
    attempts = "3",
    backoff = @Backoff(delay = 1000, multiplier = 2.0),
    include = {TransientException.class}
)
public void processPayment(OrderCreatedEvent event) {
    // Processing logic
}
```

### 2. Dead Letter Queue
- After 3 retry attempts, event sent to `commerce.dlq`
- Monitor DLQ for manual intervention
- Replay events after fixing issues

### 3. Circuit Breaker (Optional Enhancement)
```java
@CircuitBreaker(name = "paymentService", fallbackMethod = "paymentFallback")
public PaymentResponse processPayment(PaymentRequest request) {
    // Payment processing
}
```

### 4. Idempotency
- Use `eventId` (UUID) to detect duplicates
- Store processed event IDs in database
- Skip processing if already handled

---

## Scalability

### Horizontal Scaling
Each service can run multiple instances:
```bash
# Run 3 instances of Payment Service
docker-compose up --scale payment-inventory-service=3
```

**Kafka Consumer Groups** ensure:
- Each event processed by only one instance
- Automatic load balancing
- Fault tolerance (if one instance dies, others take over)

### Vertical Scaling
Increase resources (CPU, RAM) for individual services

---

## Security Considerations

### For Production (Not required for demo)
- **API Gateway**: Rate limiting, authentication
- **Kafka Security**: SASL/SSL encryption
- **Database**: Connection pooling, read replicas
- **Secrets Management**: HashiCorp Vault, AWS Secrets Manager

---

## Monitoring & Observability

### Recommended Tools (Optional)
- **Kafka UI**: Visualize topics, consumer groups, lag
- **Prometheus + Grafana**: Metrics dashboards
- **ELK Stack**: Centralized logging
- **Zipkin/Jaeger**: Distributed tracing

### Key Metrics to Track
- Kafka consumer lag
- Event processing time
- Order completion rate
- Service health (up/down)
- Error rates

---

## Technology Choices

### Why Apache Kafka?
- **High Throughput**: Millions of messages/second
- **Durability**: Messages persisted to disk
- **Scalability**: Partition-based architecture
- **Event Replay**: Consumers can rewind and replay

### Why Spring Boot?
- **Rapid Development**: Convention over configuration
- **Kafka Integration**: Spring Kafka simplifies producer/consumer
- **Ecosystem**: Rich set of starters and libraries

### Why PostgreSQL?
- **ACID Compliance**: Strong consistency guarantees
- **JSON Support**: Flexible schema with JSONB columns
- **Open Source**: No licensing costs

---

## Future Enhancements

1. **API Gateway** (Spring Cloud Gateway)
2. **Service Discovery** (Eureka/Consul)
3. **Distributed Tracing** (Sleuth + Zipkin)
4. **Config Server** (Spring Cloud Config)
5. **Authentication** (OAuth2/JWT)
6. **Rate Limiting** (Redis + Bucket4j)
7. **Caching** (Redis for analytics)

---

**Last Updated**: 2026-05-27  
**Version**: 1.0
