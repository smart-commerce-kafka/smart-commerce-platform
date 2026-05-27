# Demo Presentation Script

> **Duration**: 15-20 minutes  
> **Goal**: Showcase event-driven microservices architecture with fault tolerance

---

## Pre-Demo Checklist

- [ ] All services running (Order, Payment, Notification, Analytics)
- [ ] Docker Compose infrastructure up (Kafka, PostgreSQL)
- [ ] Kafka UI accessible at http://localhost:8090
- [ ] Postman collection ready with test requests
- [ ] Terminal windows arranged (show logs)
- [ ] Browser tabs open (Swagger UIs for all services)
- [ ] Backup slides/diagrams ready

---

## Demo Flow

### Part 1: Architecture Overview (3 minutes)

**Say:**
> "We've built a distributed e-commerce platform using event-driven microservices. Let me walk you through the architecture."

**Show:**
- Architecture diagram from ARCHITECTURE.md
- Point out 4 microservices
- Explain Kafka as central nervous system

**Key Points:**
- ✅ **Asynchronous communication** via Kafka (not REST between services)
- ✅ **Saga pattern** for distributed transactions
- ✅ **Independent scalability** - each service isolated
- ✅ **Eventual consistency** - system reaches consistent state over time

---

### Part 2: Happy Path - Successful Order (5 minutes)

**Say:**
> "Let's create an order and watch it flow through the entire system."

#### Step 1: Show Starting State
1. Open Analytics Service dashboard: `GET http://localhost:8084/api/v1/analytics/summary`
   - Show current metrics (e.g., 0 orders, $0 revenue)

#### Step 2: Create Order
2. Open Postman → POST `http://localhost:8081/api/v1/orders`
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
3. **Execute request** → Note the `orderId` returned

#### Step 3: Show Event Flow
4. Open **Kafka UI** (http://localhost:8090)
   - Navigate to Topics → `commerce.order.created`
   - Show the event just published (click to view JSON)
   
5. **Explain**: "Order Service just published this event to Kafka. Now watch what happens..."

#### Step 4: Show Service Logs
6. Switch to **terminal windows** showing service logs:
   - **Order Service**: "Published OrderCreatedEvent for orderId=ORD-12345"
   - **Payment Service**: "Consumed OrderCreatedEvent, processing payment..."
   - **Payment Service**: "Payment successful, publishing PaymentProcessedEvent"
   - **Inventory Service**: "Reserved inventory, publishing InventoryReservedEvent"
   - **Notification Service**: "Sending order confirmation email to customer"
   - **Analytics Service**: "Updated revenue metrics"

#### Step 5: Verify Final State
7. Check order status: `GET http://localhost:8081/api/v1/orders/{orderId}`
   - Show status: `COMPLETED`

8. Check analytics dashboard again: `GET http://localhost:8084/api/v1/analytics/summary`
   - Show updated metrics (1 order, $999.99 revenue)

**Say:**
> "Notice how all services worked together asynchronously. No service made direct HTTP calls to another. Everything communicated through Kafka events."

---

### Part 3: Failure Scenario - Payment Failure (5 minutes)

**Say:**
> "Now let's see how the system handles failures. We'll simulate a payment failure and watch the rollback."

#### Step 1: Create Order with Payment Failure Trigger
1. POST `http://localhost:8081/api/v1/orders`
   ```json
   {
     "customerId": "CUST-FAIL",
     "items": [
       {
         "productId": "PROD-002",
         "productName": "Phone",
         "quantity": 1,
         "unitPrice": 799.99
       }
     ]
   }
   ```
   *Note: `CUST-FAIL` is a special customer ID that triggers payment failure*

#### Step 2: Show Retry Mechanism
2. Watch **Payment Service logs**:
   ```
   [ERROR] Payment failed for orderId=ORD-12346, reason=INSUFFICIENT_FUNDS
   [INFO] Retry attempt 1/3...
   [ERROR] Payment failed again
   [INFO] Retry attempt 2/3...
   [ERROR] Payment failed again
   [INFO] Retry attempt 3/3...
   [ERROR] Max retries exceeded, sending to DLQ
   ```

#### Step 3: Show Dead Letter Queue
3. Open **Kafka UI** → Topic: `commerce.dlq`
   - Show the failed event with error details

#### Step 4: Show Rollback (Saga Pattern)
4. Watch **Order Service logs**:
   ```
   [INFO] Received PaymentFailedEvent for orderId=ORD-12346
   [INFO] Initiating rollback - cancelling order
   [INFO] Publishing OrderCancelledEvent
   ```

5. Check order status: `GET http://localhost:8081/api/v1/orders/ORD-12346`
   - Show status: `CANCELLED`

#### Step 5: Show Notification
6. **Notification Service logs**:
   ```
   [INFO] Sending order cancellation email: "Your order was cancelled due to payment failure"
   ```

**Say:**
> "This demonstrates the Saga pattern. When payment failed, the Order Service automatically rolled back by cancelling the order. The system maintained consistency despite the failure."

---

### Part 4: Real-Time Analytics (2 minutes)

**Say:**
> "Our Analytics Service consumes all events to provide real-time business intelligence."

#### Show Dashboard
1. `GET http://localhost:8084/api/v1/analytics/summary`
   ```json
   {
     "totalOrders": 2,
     "completedOrders": 1,
     "cancelledOrders": 1,
     "totalRevenue": 999.99,
     "averageOrderValue": 999.99,
     "successRate": 50.0
   }
   ```

2. `GET http://localhost:8084/api/v1/analytics/revenue/today`
   - Show revenue breakdown

**Say:**
> "Notice the metrics updated in real-time as events flowed through Kafka. No batch processing - everything is live."

---

### Part 5: Service Independence Demo (2 minutes)

**Say:**
> "Let me demonstrate service independence. I'll stop the Notification Service, and the rest of the system continues working."

#### Steps:
1. Stop Notification Service: `docker stop notification-service`
2. Create another order (use Postman)
3. **Show**: Order still completes successfully
4. **Explain**: "Payment and Inventory services don't care if Notification is down. They're loosely coupled."
5. Restart Notification Service: `docker start notification-service`
6. **Show logs**: Notification Service catches up on missed events (thanks to Kafka's durability)

---

### Part 6: Code Walkthrough (3 minutes)

**Show Key Code Snippets:**

#### 1. Kafka Producer (Order Service)
```java
@Component
public class OrderEventProducer {
    private final KafkaTemplate<String, Object> kafkaTemplate;
    
    public void publishOrderCreatedEvent(OrderCreatedEvent event) {
        kafkaTemplate.send("commerce.order.created", event.getOrderId(), event);
    }
}
```

#### 2. Kafka Consumer (Payment Service)
```java
@KafkaListener(
    topics = "commerce.order.created",
    groupId = "payment-service-group"
)
public void consumeOrderCreatedEvent(OrderCreatedEvent event) {
    paymentService.processPayment(event);
}
```

#### 3. Saga Orchestration (Order Service)
```java
@KafkaListener(topics = "commerce.payment.failed")
public void handlePaymentFailure(PaymentFailedEvent event) {
    // Trigger rollback
    Order order = orderRepository.findById(event.getOrderId());
    order.setStatus(OrderStatus.CANCELLED);
    orderRepository.save(order);
    
    // Publish cancellation event
    orderEventProducer.publishOrderCancelledEvent(order);
}
```

---

### Part 7: Q&A Preparation (Anticipated Questions)

**Q: Why Kafka instead of REST calls?**
> A: Kafka provides asynchronous, fault-tolerant communication. If a service is down, events are queued and processed when it recovers. REST calls would fail immediately.

**Q: How do you ensure events aren't processed twice?**
> A: We use idempotency - each event has a unique `eventId`. Services check if they've already processed an event before acting on it.

**Q: What happens if Kafka goes down?**
> A: Kafka stores events on disk with replication. Even if a broker fails, data is preserved. Services buffer events until Kafka recovers.

**Q: Can this scale to millions of orders?**
> A: Yes! Each service can scale horizontally (run multiple instances). Kafka partitions distribute load. We can add more Payment Service instances without changing code.

**Q: How do you handle refunds?**
> A: Similar saga pattern - publish `RefundRequestedEvent`, Payment Service processes refund, publishes `RefundCompletedEvent`.

---

## Demo Tips

### Before Demo
- ✅ Practice 3-4 times
- ✅ Have backup recordings/screenshots
- ✅ Clear all existing data (fresh demo)
- ✅ Test with demo data ahead of time
- ✅ Prepare explanation of any special customer IDs or test data

### During Demo
- 🎤 Speak clearly and confidently
- 🔄 Narrate what you're doing (don't go silent)
- 👀 Make eye contact with evaluators
- ⏱️ Watch time (don't rush, don't drag)
- 🐛 If something breaks, explain what *should* happen

### After Demo
- 📊 Highlight key achievements:
  - Event-driven architecture ✅
  - Distributed transactions ✅
  - Fault tolerance ✅
  - Real-time processing ✅
  - Service independence ✅

---

## Backup Slides (If Demo Fails)

### Slide 1: Architecture Diagram
- Show how services connect via Kafka

### Slide 2: Event Flow Diagram
- Happy path: Order → Payment → Inventory → Completed

### Slide 3: Failure Scenario Diagram
- Payment fails → Retry → DLQ → Rollback

### Slide 4: Code Snippets
- Kafka Producer/Consumer examples

### Slide 5: Metrics/Screenshots
- Pre-captured analytics dashboard
- Kafka UI showing topics

---

## Scoring Rubric (What Evaluators Look For)

| Criteria | Weight | How to Excel |
|----------|--------|--------------|
| Architecture Design | 25% | Clearly explain event-driven design, Saga pattern |
| Implementation Quality | 25% | Show clean code, proper error handling |
| Fault Tolerance | 20% | Demo retry, DLQ, rollback |
| Scalability | 15% | Explain horizontal scaling, Kafka partitions |
| Presentation | 15% | Clear communication, live demo, confidence |

---

## Post-Demo Questions to Ask

**"Would you like me to show...?"**
- API documentation (Swagger UI)?
- Docker Compose setup?
- Database schema?
- Test coverage?
- CI/CD pipeline (if implemented)?

---

**Good luck with your demo! 🚀**

*Remember: Confidence and clear explanation > perfect execution. If something breaks, explain what should happen and why.*
