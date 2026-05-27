# Order Service

**Owner**: Student A  
**Port**: 8081  
**Database**: order_db

## Responsibilities

- Create and manage orders
- Kafka producer for order events
- Saga orchestration for distributed transactions
- Order status tracking (PENDING → CONFIRMED → COMPLETED → CANCELLED)

## Endpoints

### Create Order
```http
POST /api/v1/orders
Content-Type: application/json

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

### Get Order
```http
GET /api/v1/orders/{orderId}
```

### Get Order Status
```http
GET /api/v1/orders/{orderId}/status
```

## Kafka Integration

### Produces:
- `commerce.order.created` - When new order is created
- `commerce.order.completed` - When all processing succeeds
- `commerce.order.cancelled` - When rollback is triggered

### Consumes:
- `commerce.payment.processed` - Payment success notification
- `commerce.payment.failed` - Payment failure (triggers rollback)
- `commerce.inventory.reserved` - Inventory confirmation
- `commerce.inventory.failed` - Inventory failure (triggers rollback)

## Database Schema

### orders table
```sql
CREATE TABLE orders (
    id VARCHAR(255) PRIMARY KEY,
    customer_id VARCHAR(255) NOT NULL,
    total_amount NUMERIC(19,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    order_status VARCHAR(50) NOT NULL,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL,
    version INTEGER DEFAULT 0
);
```

### order_items table
```sql
CREATE TABLE order_items (
    id VARCHAR(255) PRIMARY KEY,
    order_id VARCHAR(255) NOT NULL,
    product_id VARCHAR(255) NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    quantity INTEGER NOT NULL,
    unit_price NUMERIC(19,2) NOT NULL,
    total_price NUMERIC(19,2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(id)
);
```

## Running Locally

```bash
cd order-service

# Build
./mvnw clean install

# Run
./mvnw spring-boot:run

# Access Swagger UI
open http://localhost:8081/swagger-ui.html
```

## Environment Variables

```bash
SERVER_PORT=8081
KAFKA_BOOTSTRAP_SERVERS=localhost:9092
DB_HOST=localhost
DB_PORT=5432
DB_NAME=order_db
DB_USERNAME=postgres
DB_PASSWORD=postgres
```

## Implementation Checklist

- [ ] Create Spring Boot project with dependencies
- [ ] Define Order and OrderItem entities
- [ ] Create OrderRepository
- [ ] Implement OrderService with business logic
- [ ] Create REST controllers with Swagger docs
- [ ] Configure Kafka producer
- [ ] Implement event publishing (OrderCreatedEvent, etc.)
- [ ] Configure Kafka consumer for payment/inventory events
- [ ] Implement saga orchestration logic
- [ ] Add exception handling
- [ ] Write integration tests
- [ ] Test with Postman

## Key Implementation Notes

1. **Order ID Generation**: Use UUID for unique order IDs
2. **Saga Pattern**: Listen for success/failure events and update order status
3. **Rollback Logic**: Publish `OrderCancelledEvent` on any failure
4. **Idempotency**: Check if order already exists before processing
5. **Logging**: Log every state transition for debugging

## Testing Scenarios

1. **Happy Path**: Create order → Payment success → Inventory reserved → Order completed
2. **Payment Failure**: Create order → Payment fails → Order cancelled
3. **Inventory Failure**: Create order → Payment success → Inventory out of stock → Order cancelled + Refund

## Swagger Documentation

All endpoints should have proper Swagger annotations:

```java
@Operation(summary = "Create new order", description = "Creates a new order and publishes event to Kafka")
@ApiResponses(value = {
    @ApiResponse(responseCode = "201", description = "Order created successfully"),
    @ApiResponse(responseCode = "400", description = "Invalid request"),
    @ApiResponse(responseCode = "500", description = "Internal server error")
})
```

## Contact

For questions or issues, contact Student A or refer to CLAUDE.md
