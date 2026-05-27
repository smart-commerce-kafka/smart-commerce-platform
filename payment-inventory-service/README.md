# Payment & Inventory Service

**Owner**: Student B  
**Port**: 8082  
**Database**: payment_db

## Responsibilities

- Process payments (simulation)
- Manage inventory reservations
- Kafka consumer for order events
- Retry mechanism implementation
- Dead Letter Queue (DLQ) handling
- Rollback and refund processing

## Endpoints

### Get Payment Status
```http
GET /api/v1/payments/{paymentId}
```

### Get Inventory Stock
```http
GET /api/v1/inventory/{productId}
```

### Manual Refund (Admin)
```http
POST /api/v1/payments/{paymentId}/refund
```

## Kafka Integration

### Produces:
- `commerce.payment.processed` - Payment success
- `commerce.payment.failed` - Payment failure after retries
- `commerce.inventory.reserved` - Inventory successfully reserved
- `commerce.inventory.failed` - Inventory out of stock
- `commerce.dlq` - Failed events after max retries

### Consumes:
- `commerce.order.created` - Triggers payment and inventory processing
- `commerce.order.cancelled` - Releases inventory reservation

## Database Schema

### payments table
```sql
CREATE TABLE payments (
    id VARCHAR(255) PRIMARY KEY,
    order_id VARCHAR(255) NOT NULL,
    amount NUMERIC(19,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    payment_status VARCHAR(50) NOT NULL,
    payment_method VARCHAR(50),
    transaction_id VARCHAR(255),
    failure_reason TEXT,
    retry_count INTEGER DEFAULT 0,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
);
```

### inventory table
```sql
CREATE TABLE inventory (
    id VARCHAR(255) PRIMARY KEY,
    product_id VARCHAR(255) UNIQUE NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    quantity_available INTEGER NOT NULL,
    quantity_reserved INTEGER DEFAULT 0,
    updated_at TIMESTAMP NOT NULL
);
```

### inventory_reservations table
```sql
CREATE TABLE inventory_reservations (
    id VARCHAR(255) PRIMARY KEY,
    order_id VARCHAR(255) NOT NULL,
    product_id VARCHAR(255) NOT NULL,
    quantity INTEGER NOT NULL,
    reservation_status VARCHAR(50) NOT NULL,
    created_at TIMESTAMP NOT NULL,
    expires_at TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES inventory(product_id)
);
```

## Running Locally

```bash
cd payment-inventory-service

# Build
./mvnw clean install

# Run
./mvnw spring-boot:run

# Access Swagger UI
open http://localhost:8082/swagger-ui.html
```

## Environment Variables

```bash
SERVER_PORT=8082
KAFKA_BOOTSTRAP_SERVERS=localhost:9092
DB_HOST=localhost
DB_PORT=5432
DB_NAME=payment_db
DB_USERNAME=postgres
DB_PASSWORD=postgres
MAX_RETRY_ATTEMPTS=3
RETRY_BACKOFF_MS=1000
```

## Implementation Checklist

- [ ] Create Spring Boot project with dependencies
- [ ] Define Payment, Inventory, and Reservation entities
- [ ] Create repositories
- [ ] Implement PaymentService with simulation logic
- [ ] Implement InventoryService with reservation logic
- [ ] Configure Kafka consumer for order events
- [ ] Implement retry mechanism (3 attempts with backoff)
- [ ] Implement DLQ handler
- [ ] Configure Kafka producer for success/failure events
- [ ] Add idempotency checks (don't process same order twice)
- [ ] Create REST controllers for manual operations
- [ ] Write integration tests
- [ ] Test failure scenarios

## Key Implementation Notes

### 1. Payment Simulation
```java
public PaymentResult processPayment(OrderCreatedEvent event) {
    // Simulate payment based on customer ID
    if (event.getCustomerId().contains("FAIL")) {
        throw new PaymentFailedException("INSUFFICIENT_FUNDS");
    }
    
    // Simulate processing delay
    Thread.sleep(2000);
    
    return PaymentResult.success(generateTransactionId());
}
```

### 2. Retry Configuration
```java
@RetryableTopic(
    attempts = "3",
    backoff = @Backoff(delay = 1000, multiplier = 2.0),
    dltTopicSuffix = "",
    kafkaTemplate = "kafkaTemplate"
)
@KafkaListener(topics = "commerce.order.created")
public void processOrder(OrderCreatedEvent event) {
    // Processing logic with automatic retry
}
```

### 3. Idempotency
```java
@Transactional
public void processPayment(OrderCreatedEvent event) {
    // Check if already processed
    if (paymentRepository.existsByOrderId(event.getOrderId())) {
        log.warn("Payment already processed for orderId={}", event.getOrderId());
        return; // Skip duplicate
    }
    
    // Process payment
    Payment payment = createPayment(event);
    paymentRepository.save(payment);
}
```

### 4. Inventory Reservation
```java
@Transactional
public void reserveInventory(OrderCreatedEvent event) {
    for (OrderItem item : event.getItems()) {
        Inventory inventory = inventoryRepository.findByProductId(item.getProductId());
        
        if (inventory.getQuantityAvailable() < item.getQuantity()) {
            throw new InsufficientInventoryException(item.getProductId());
        }
        
        // Reserve inventory
        inventory.reserveQuantity(item.getQuantity());
        inventoryRepository.save(inventory);
        
        // Create reservation record
        InventoryReservation reservation = InventoryReservation.builder()
            .orderId(event.getOrderId())
            .productId(item.getProductId())
            .quantity(item.getQuantity())
            .build();
        reservationRepository.save(reservation);
    }
}
```

### 5. DLQ Handler
```java
@Component
public class DeadLetterQueueHandler {
    
    @KafkaListener(topics = "commerce.dlq")
    public void handleDLQEvent(DLQEvent event) {
        log.error("Event sent to DLQ: topic={}, error={}", 
            event.getOriginalTopic(), 
            event.getFailureReason());
        
        // Send alert/notification
        // Store in database for manual review
        // Trigger monitoring alert
    }
}
```

## Testing Scenarios

### 1. Payment Success
- Create order with normal customer ID
- Verify payment processed
- Verify inventory reserved
- Check Kafka events published

### 2. Payment Failure
- Create order with `CUST-FAIL` customer ID
- Verify retry attempts (3 times)
- Verify PaymentFailedEvent published
- Check DLQ contains failed event

### 3. Inventory Out of Stock
- Create order for product with 0 stock
- Verify InventoryFailedEvent published
- Verify no inventory reservation created

### 4. Concurrent Orders (Race Condition)
- Create 2 orders simultaneously for same product
- Verify one succeeds, one fails
- Check inventory consistency

## Inventory Seed Data

```sql
-- Insert sample inventory for testing
INSERT INTO inventory (id, product_id, product_name, quantity_available, updated_at)
VALUES
    ('INV-001', 'PROD-001', 'Laptop', 10, NOW()),
    ('INV-002', 'PROD-002', 'Phone', 5, NOW()),
    ('INV-003', 'PROD-003', 'Tablet', 0, NOW()), -- Out of stock for testing
    ('INV-004', 'PROD-004', 'Headphones', 20, NOW());
```

## Advanced Features (Bonus)

- [ ] Implement circuit breaker pattern (Resilience4j)
- [ ] Add payment gateway simulation (Stripe/PayPal)
- [ ] Implement inventory reservation expiry (auto-release after 10 mins)
- [ ] Add distributed locking for concurrent inventory updates
- [ ] Create admin dashboard for DLQ monitoring

## Contact

For questions or issues, contact Student B or refer to CLAUDE.md
