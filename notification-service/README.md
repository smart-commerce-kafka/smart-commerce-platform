# Notification Service

**Owner**: Student C  
**Port**: 8083  
**Database**: notification_db

## Responsibilities

- Send email/SMS notifications (simulated)
- Consume Kafka events for order, payment, and inventory updates
- Support multiple notification templates
- Track notification history
- Independent deployment and scaling

## Endpoints

### Get Notification History
```http
GET /api/v1/notifications?customerId={customerId}
```

### Get Notification by ID
```http
GET /api/v1/notifications/{notificationId}
```

### Manual Send (Admin/Testing)
```http
POST /api/v1/notifications/send
Content-Type: application/json

{
  "type": "EMAIL",
  "recipient": "customer@example.com",
  "subject": "Test Notification",
  "body": "This is a test message"
}
```

## Kafka Integration

### Produces:
- None (pure consumer service)

### Consumes:
- `commerce.order.created` → Send "Order Confirmation" email
- `commerce.payment.processed` → Send "Payment Successful" email
- `commerce.order.completed` → Send "Order Shipped" email
- `commerce.order.cancelled` → Send "Order Cancelled" email

## Database Schema

### notifications table
```sql
CREATE TABLE notifications (
    id VARCHAR(255) PRIMARY KEY,
    order_id VARCHAR(255),
    customer_id VARCHAR(255) NOT NULL,
    notification_type VARCHAR(50) NOT NULL, -- EMAIL, SMS
    template_name VARCHAR(100) NOT NULL,
    recipient VARCHAR(255) NOT NULL,
    subject VARCHAR(500),
    body TEXT NOT NULL,
    status VARCHAR(50) NOT NULL, -- SENT, FAILED, PENDING
    sent_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL,
    error_message TEXT
);
```

### notification_templates table
```sql
CREATE TABLE notification_templates (
    id VARCHAR(255) PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    type VARCHAR(50) NOT NULL,
    subject VARCHAR(500),
    body_template TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
);
```

## Running Locally

```bash
cd notification-service

# Build
./mvnw clean install

# Run
./mvnw spring-boot:run

# Access Swagger UI
open http://localhost:8083/swagger-ui.html
```

## Environment Variables

```bash
SERVER_PORT=8083
KAFKA_BOOTSTRAP_SERVERS=localhost:9092
DB_HOST=localhost
DB_PORT=5432
DB_NAME=notification_db
DB_USERNAME=postgres
DB_PASSWORD=postgres

# Email simulation (optional)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=noreply@commerce.com
SMTP_PASSWORD=secret
```

## Implementation Checklist

- [ ] Create Spring Boot project with dependencies
- [ ] Define Notification and Template entities
- [ ] Create NotificationRepository
- [ ] Implement NotificationService
- [ ] Configure Kafka consumers for all relevant topics
- [ ] Create notification templates
- [ ] Implement email/SMS simulation
- [ ] Add template rendering (replace placeholders)
- [ ] Create REST controllers for history/manual send
- [ ] Add exception handling
- [ ] Write integration tests
- [ ] Test with Kafka events

## Key Implementation Notes

### 1. Notification Templates

Seed data for templates:

```sql
-- Order Confirmation Email
INSERT INTO notification_templates (id, name, type, subject, body_template, created_at, updated_at)
VALUES (
    'TPL-001',
    'ORDER_CONFIRMATION',
    'EMAIL',
    'Order Confirmation - #{orderId}',
    'Dear Customer,

Thank you for your order!

Order ID: #{orderId}
Total Amount: #{totalAmount} #{currency}
Order Date: #{orderDate}

We will send you another email once your order has been shipped.

Best regards,
Smart Commerce Team',
    NOW(),
    NOW()
);

-- Payment Success Email
INSERT INTO notification_templates (id, name, type, subject, body_template, created_at, updated_at)
VALUES (
    'TPL-002',
    'PAYMENT_SUCCESS',
    'EMAIL',
    'Payment Received - #{orderId}',
    'Dear Customer,

Your payment has been successfully processed!

Order ID: #{orderId}
Amount Paid: #{amount} #{currency}
Transaction ID: #{transactionId}

Your order is now being prepared for shipment.

Best regards,
Smart Commerce Team',
    NOW(),
    NOW()
);

-- Order Completed Email
INSERT INTO notification_templates (id, name, type, subject, body_template, created_at, updated_at)
VALUES (
    'TPL-003',
    'ORDER_COMPLETED',
    'EMAIL',
    'Your Order Has Shipped - #{orderId}',
    'Dear Customer,

Great news! Your order has been shipped.

Order ID: #{orderId}
Total Amount: #{totalAmount} #{currency}
Estimated Delivery: 3-5 business days

Track your order: https://commerce.com/track/#{orderId}

Best regards,
Smart Commerce Team',
    NOW(),
    NOW()
);

-- Order Cancelled Email
INSERT INTO notification_templates (id, name, type, subject, body_template, created_at, updated_at)
VALUES (
    'TPL-004',
    'ORDER_CANCELLED',
    'EMAIL',
    'Order Cancelled - #{orderId}',
    'Dear Customer,

Unfortunately, your order has been cancelled.

Order ID: #{orderId}
Cancellation Reason: #{reason}

If payment was processed, a refund will be issued within 5-7 business days.

For questions, contact support@commerce.com

Best regards,
Smart Commerce Team',
    NOW(),
    NOW()
);
```

### 2. Template Rendering

```java
@Service
public class TemplateService {
    
    public String renderTemplate(String templateBody, Map<String, String> variables) {
        String result = templateBody;
        
        for (Map.Entry<String, String> entry : variables.entrySet()) {
            String placeholder = "#{" + entry.getKey() + "}";
            result = result.replace(placeholder, entry.getValue());
        }
        
        return result;
    }
}
```

### 3. Kafka Consumer Implementation

```java
@Component
@RequiredArgsConstructor
public class OrderEventConsumer {
    
    private final NotificationService notificationService;
    
    @KafkaListener(
        topics = "commerce.order.created",
        groupId = "notification-service-group"
    )
    public void handleOrderCreated(OrderCreatedEvent event) {
        log.info("Sending order confirmation for orderId={}", event.getOrderId());
        
        Map<String, String> variables = Map.of(
            "orderId", event.getOrderId(),
            "totalAmount", event.getTotalAmount().toString(),
            "currency", event.getCurrency(),
            "orderDate", event.getTimestamp().toString()
        );
        
        notificationService.sendNotification(
            event.getCustomerId(),
            "ORDER_CONFIRMATION",
            variables
        );
    }
    
    @KafkaListener(
        topics = "commerce.order.completed",
        groupId = "notification-service-group"
    )
    public void handleOrderCompleted(OrderCompletedEvent event) {
        log.info("Sending order shipped notification for orderId={}", event.getOrderId());
        
        Map<String, String> variables = Map.of(
            "orderId", event.getOrderId(),
            "totalAmount", event.getTotalAmount().toString(),
            "currency", event.getCurrency()
        );
        
        notificationService.sendNotification(
            event.getCustomerId(),
            "ORDER_COMPLETED",
            variables
        );
    }
    
    @KafkaListener(
        topics = "commerce.order.cancelled",
        groupId = "notification-service-group"
    )
    public void handleOrderCancelled(OrderCancelledEvent event) {
        log.info("Sending order cancellation notification for orderId={}", event.getOrderId());
        
        Map<String, String> variables = Map.of(
            "orderId", event.getOrderId(),
            "reason", event.getCancellationReason()
        );
        
        notificationService.sendNotification(
            event.getCustomerId(),
            "ORDER_CANCELLED",
            variables
        );
    }
}
```

### 4. Email Simulation

```java
@Service
@Slf4j
public class EmailService {
    
    public void sendEmail(String recipient, String subject, String body) {
        // Simulate email sending (for demo purposes)
        log.info("=" .repeat(80));
        log.info("📧 SENDING EMAIL");
        log.info("To: {}", recipient);
        log.info("Subject: {}", subject);
        log.info("-" .repeat(80));
        log.info("{}", body);
        log.info("=" .repeat(80));
        
        // In production, use JavaMailSender
        // mailSender.send(createMimeMessage(recipient, subject, body));
        
        // Simulate processing delay
        try {
            Thread.sleep(500);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}
```

### 5. SMS Simulation

```java
@Service
@Slf4j
public class SmsService {
    
    public void sendSms(String phoneNumber, String message) {
        log.info("=" .repeat(80));
        log.info("📱 SENDING SMS");
        log.info("To: {}", phoneNumber);
        log.info("-" .repeat(80));
        log.info("{}", message);
        log.info("=" .repeat(80));
        
        // In production, use Twilio, AWS SNS, etc.
    }
}
```

## Testing Scenarios

### 1. Order Confirmation
- Create order in Order Service
- Verify notification logged in console
- Check database for notification record

### 2. Payment Success
- Wait for payment processing
- Verify payment success notification sent

### 3. Order Completed
- Complete full order flow
- Verify "Order Shipped" notification sent

### 4. Order Cancelled
- Create order with failing payment
- Verify cancellation notification sent

### 5. Service Independence
- Stop Notification Service
- Create order (should still work)
- Start Notification Service
- Verify it catches up on missed events

## Advanced Features (Bonus)

- [ ] Real email integration with JavaMailSender
- [ ] SMS integration with Twilio
- [ ] Push notification support (Firebase)
- [ ] Notification preferences (customer opt-in/opt-out)
- [ ] Rich HTML email templates (Thymeleaf)
- [ ] Notification retry on failure
- [ ] Rate limiting (prevent spam)
- [ ] Scheduled notifications (e.g., reminders)

## Contact

For questions or issues, contact Student C or refer to CLAUDE.md
