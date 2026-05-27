# Claude Code Project Reference - Smart Commerce Platform

> **CRITICAL**: Read this file completely before writing any code. This ensures consistency across all 4 microservices.

## Project Context

This is a **distributed event-driven e-commerce system** built by 4 students for a Scalable Services course. The system uses **Apache Kafka** for asynchronous communication between microservices.

### Core Principles
1. **Event-Driven Architecture** - Services communicate via Kafka events, not REST calls
2. **Service Independence** - Each microservice can be developed, deployed, and scaled independently
3. **Eventual Consistency** - Data consistency achieved through event propagation
4. **Fault Tolerance** - Saga pattern for distributed transaction rollback
5. **Real-time Processing** - Analytics and notifications update instantly
6. **Polyglot Architecture** - Services can use Java, Python, or Node.js (see docs/MULTI_LANGUAGE_GUIDE.md)

---

## System Architecture

### Microservices Overview

| Service | Port | Owner | Responsibility |
|---------|------|-------|----------------|
| Order Service | 8081 | Student A | Order creation, saga orchestration |
| Payment & Inventory Service | 8082 | Student B | Payment processing, inventory management, rollback |
| Notification Service | 8083 | Student C | Email/SMS notifications |
| Analytics Service | 8084 | Student D | Real-time metrics, dashboards |

### Infrastructure Components
- **Apache Kafka** (Port 9092) - Message broker
- **Zookeeper** (Port 2181) - Kafka coordination
- **PostgreSQL** (Port 5432) - Primary database
- **Kafka UI** (Port 8090) - Optional monitoring

---

## Kafka Topics & Events

### Topic Naming Convention
`{domain}.{entity}.{action}` - Example: `commerce.order.created`

### Standard Topics

#### 1. `commerce.order.created`
**Producer**: Order Service  
**Consumers**: Payment Service, Notification Service, Analytics Service

```json
{
  "eventId": "uuid",
  "eventType": "ORDER_CREATED",
  "timestamp": "2026-05-27T10:30:00Z",
  "orderId": "ORD-12345",
  "customerId": "CUST-789",
  "items": [
    {
      "productId": "PROD-001",
      "productName": "Laptop",
      "quantity": 1,
      "unitPrice": 999.99,
      "totalPrice": 999.99
    }
  ],
  "totalAmount": 999.99,
  "currency": "USD",
  "orderStatus": "PENDING"
}
```

#### 2. `commerce.payment.processed`
**Producer**: Payment Service  
**Consumers**: Order Service, Notification Service, Analytics Service

```json
{
  "eventId": "uuid",
  "eventType": "PAYMENT_PROCESSED",
  "timestamp": "2026-05-27T10:30:05Z",
  "orderId": "ORD-12345",
  "paymentId": "PAY-67890",
  "amount": 999.99,
  "currency": "USD",
  "paymentStatus": "SUCCESS",
  "paymentMethod": "CREDIT_CARD",
  "transactionId": "TXN-ABC123"
}
```

#### 3. `commerce.payment.failed`
**Producer**: Payment Service  
**Consumers**: Order Service (triggers rollback)

```json
{
  "eventId": "uuid",
  "eventType": "PAYMENT_FAILED",
  "timestamp": "2026-05-27T10:30:05Z",
  "orderId": "ORD-12345",
  "paymentId": "PAY-67890",
  "amount": 999.99,
  "failureReason": "INSUFFICIENT_FUNDS",
  "retryAttempt": 1,
  "maxRetries": 3
}
```

#### 4. `commerce.inventory.reserved`
**Producer**: Inventory Service (part of Payment Service)  
**Consumers**: Order Service, Analytics Service

```json
{
  "eventId": "uuid",
  "eventType": "INVENTORY_RESERVED",
  "timestamp": "2026-05-27T10:30:06Z",
  "orderId": "ORD-12345",
  "reservationId": "RES-999",
  "items": [
    {
      "productId": "PROD-001",
      "quantity": 1,
      "warehouseId": "WH-EAST"
    }
  ],
  "reservationStatus": "CONFIRMED"
}
```

#### 5. `commerce.inventory.failed`
**Producer**: Inventory Service  
**Consumers**: Order Service (triggers rollback)

```json
{
  "eventId": "uuid",
  "eventType": "INVENTORY_FAILED",
  "timestamp": "2026-05-27T10:30:06Z",
  "orderId": "ORD-12345",
  "failureReason": "OUT_OF_STOCK",
  "unavailableItems": ["PROD-001"]
}
```

#### 6. `commerce.order.completed`
**Producer**: Order Service  
**Consumers**: Notification Service, Analytics Service

```json
{
  "eventId": "uuid",
  "eventType": "ORDER_COMPLETED",
  "timestamp": "2026-05-27T10:30:10Z",
  "orderId": "ORD-12345",
  "customerId": "CUST-789",
  "totalAmount": 999.99,
  "completedAt": "2026-05-27T10:30:10Z"
}
```

#### 7. `commerce.order.cancelled`
**Producer**: Order Service (during rollback)  
**Consumers**: Notification Service, Analytics Service

```json
{
  "eventId": "uuid",
  "eventType": "ORDER_CANCELLED",
  "timestamp": "2026-05-27T10:30:08Z",
  "orderId": "ORD-12345",
  "customerId": "CUST-789",
  "cancellationReason": "PAYMENT_FAILED",
  "refundRequired": false
}
```

#### 8. Dead Letter Queue: `commerce.dlq`
**Producer**: Any service on processing failure  
**Consumers**: Monitoring/alerting systems

```json
{
  "originalTopic": "commerce.order.created",
  "originalEvent": { /* full event payload */ },
  "failureReason": "Exception details",
  "failureTimestamp": "2026-05-27T10:30:15Z",
  "retryCount": 3,
  "serviceName": "payment-service"
}
```

---

## Language Support

**IMPORTANT**: While this document focuses on Java/Spring Boot examples, services can be built in:
- ✅ **Java** (Spring Boot) - Recommended for transaction-heavy services
- ✅ **Python** (FastAPI/Flask) - Great for analytics and data processing
- ✅ **Node.js** (Express) - Excellent for I/O-heavy services

**See [docs/MULTI_LANGUAGE_GUIDE.md](docs/MULTI_LANGUAGE_GUIDE.md) for Python and Node.js implementations.**

**Critical**: Regardless of language choice:
- All Kafka events MUST use the exact JSON schemas defined below
- All REST endpoints MUST follow the API contracts
- All services MUST use the same database schemas

---

## Code Standards

### Java/Spring Boot Conventions

#### Package Structure (All Services)
```
com.commerce.{service-name}/
├── config/               # Kafka, DB, Swagger config
│   ├── KafkaProducerConfig.java
│   ├── KafkaConsumerConfig.java
│   └── SwaggerConfig.java
├── controller/           # REST endpoints
│   └── {Entity}Controller.java
├── service/              # Business logic
│   ├── {Entity}Service.java
│   └── impl/
│       └── {Entity}ServiceImpl.java
├── repository/           # Database access
│   └── {Entity}Repository.java
├── model/                # Domain entities
│   ├── entity/
│   │   └── {Entity}.java
│   └── dto/
│       ├── {Entity}Request.java
│       └── {Entity}Response.java
├── event/                # Kafka events (shared)
│   ├── OrderCreatedEvent.java
│   ├── PaymentProcessedEvent.java
│   └── ...
├── kafka/                # Kafka producers/consumers
│   ├── producer/
│   │   └── {Entity}EventProducer.java
│   └── consumer/
│       └── {Entity}EventConsumer.java
└── exception/            # Custom exceptions
    ├── {Service}Exception.java
    └── GlobalExceptionHandler.java
```

#### Naming Conventions
- **Classes**: PascalCase - `OrderService`, `PaymentController`
- **Methods**: camelCase - `createOrder()`, `processPayment()`
- **Variables**: camelCase - `orderId`, `totalAmount`
- **Constants**: UPPER_SNAKE_CASE - `MAX_RETRY_ATTEMPTS`, `TOPIC_ORDER_CREATED`
- **Packages**: lowercase - `com.commerce.order.service`

#### Event Class Template
```java
package com.commerce.shared.event;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import com.fasterxml.jackson.annotation.JsonFormat;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class OrderCreatedEvent {
    
    @Builder.Default
    private String eventId = UUID.randomUUID().toString();
    
    private String eventType = "ORDER_CREATED";
    
    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss'Z'")
    @Builder.Default
    private LocalDateTime timestamp = LocalDateTime.now();
    
    private String orderId;
    private String customerId;
    private List<OrderItem> items;
    private BigDecimal totalAmount;
    private String currency;
    private OrderStatus orderStatus;
    
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class OrderItem {
        private String productId;
        private String productName;
        private Integer quantity;
        private BigDecimal unitPrice;
        private BigDecimal totalPrice;
    }
    
    public enum OrderStatus {
        PENDING, CONFIRMED, CANCELLED, COMPLETED
    }
}
```

#### Kafka Producer Template
```java
package com.commerce.order.kafka.producer;

import com.commerce.shared.event.OrderCreatedEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.SendResult;
import org.springframework.stereotype.Component;
import java.util.concurrent.CompletableFuture;

@Slf4j
@Component
@RequiredArgsConstructor
public class OrderEventProducer {
    
    private static final String TOPIC_ORDER_CREATED = "commerce.order.created";
    
    private final KafkaTemplate<String, Object> kafkaTemplate;
    
    public void publishOrderCreatedEvent(OrderCreatedEvent event) {
        log.info("Publishing OrderCreatedEvent: orderId={}", event.getOrderId());
        
        CompletableFuture<SendResult<String, Object>> future = 
            kafkaTemplate.send(TOPIC_ORDER_CREATED, event.getOrderId(), event);
        
        future.whenComplete((result, ex) -> {
            if (ex == null) {
                log.info("Successfully published event to topic={}, partition={}, offset={}", 
                    TOPIC_ORDER_CREATED, 
                    result.getRecordMetadata().partition(),
                    result.getRecordMetadata().offset());
            } else {
                log.error("Failed to publish event to topic={}, error={}", 
                    TOPIC_ORDER_CREATED, ex.getMessage());
                // Consider implementing retry logic or DLQ here
            }
        });
    }
}
```

#### Kafka Consumer Template
```java
package com.commerce.payment.kafka.consumer;

import com.commerce.shared.event.OrderCreatedEvent;
import com.commerce.payment.service.PaymentService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.KafkaHeaders;
import org.springframework.messaging.handler.annotation.Header;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.stereotype.Component;

@Slf4j
@Component
@RequiredArgsConstructor
public class OrderEventConsumer {
    
    private final PaymentService paymentService;
    
    @KafkaListener(
        topics = "commerce.order.created",
        groupId = "payment-service-group",
        containerFactory = "kafkaListenerContainerFactory"
    )
    public void consumeOrderCreatedEvent(
            @Payload OrderCreatedEvent event,
            @Header(KafkaHeaders.RECEIVED_TOPIC) String topic,
            @Header(KafkaHeaders.RECEIVED_PARTITION) int partition,
            @Header(KafkaHeaders.OFFSET) long offset) {
        
        log.info("Consumed OrderCreatedEvent from topic={}, partition={}, offset={}, orderId={}", 
            topic, partition, offset, event.getOrderId());
        
        try {
            paymentService.processPayment(event);
            log.info("Successfully processed payment for orderId={}", event.getOrderId());
        } catch (Exception ex) {
            log.error("Error processing payment for orderId={}, error={}", 
                event.getOrderId(), ex.getMessage());
            // Send to DLQ or implement retry
            handleFailure(event, ex);
        }
    }
    
    private void handleFailure(OrderCreatedEvent event, Exception ex) {
        // Implement DLQ publishing or retry logic
    }
}
```

#### REST Controller Template
```java
package com.commerce.order.controller;

import com.commerce.order.model.dto.OrderRequest;
import com.commerce.order.model.dto.OrderResponse;
import com.commerce.order.service.OrderService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import javax.validation.Valid;

@RestController
@RequestMapping("/api/v1/orders")
@RequiredArgsConstructor
@Tag(name = "Order Management", description = "APIs for order creation and management")
public class OrderController {
    
    private final OrderService orderService;
    
    @PostMapping
    @Operation(summary = "Create new order", description = "Creates a new order and publishes event to Kafka")
    public ResponseEntity<OrderResponse> createOrder(@Valid @RequestBody OrderRequest request) {
        OrderResponse response = orderService.createOrder(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }
    
    @GetMapping("/{orderId}")
    @Operation(summary = "Get order by ID")
    public ResponseEntity<OrderResponse> getOrder(@PathVariable String orderId) {
        OrderResponse response = orderService.getOrderById(orderId);
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/{orderId}/status")
    @Operation(summary = "Get order status")
    public ResponseEntity<String> getOrderStatus(@PathVariable String orderId) {
        String status = orderService.getOrderStatus(orderId);
        return ResponseEntity.ok(status);
    }
}
```

#### application.yml Template
```yaml
spring:
  application:
    name: ${SERVICE_NAME:order-service}
  
  datasource:
    url: jdbc:postgresql://${DB_HOST:localhost}:${DB_PORT:5432}/${DB_NAME:commerce_db}
    username: ${DB_USERNAME:postgres}
    password: ${DB_PASSWORD:postgres}
    driver-class-name: org.postgresql.Driver
  
  jpa:
    hibernate:
      ddl-auto: update
    show-sql: true
    properties:
      hibernate:
        dialect: org.hibernate.dialect.PostgreSQLDialect
        format_sql: true
  
  kafka:
    bootstrap-servers: ${KAFKA_BOOTSTRAP_SERVERS:localhost:9092}
    
    producer:
      key-serializer: org.apache.kafka.common.serialization.StringSerializer
      value-serializer: org.springframework.kafka.support.serializer.JsonSerializer
      acks: all
      retries: 3
      properties:
        spring.json.add.type.headers: false
    
    consumer:
      group-id: ${spring.application.name}-group
      key-deserializer: org.apache.kafka.common.serialization.StringDeserializer
      value-deserializer: org.springframework.kafka.support.serializer.JsonDeserializer
      auto-offset-reset: earliest
      enable-auto-commit: false
      properties:
        spring.json.trusted.packages: "*"
        spring.json.use.type.headers: false
    
    listener:
      ack-mode: manual

server:
  port: ${SERVER_PORT:8081}

# Swagger/OpenAPI
springdoc:
  api-docs:
    path: /api-docs
  swagger-ui:
    path: /swagger-ui.html
    enabled: true

# Logging
logging:
  level:
    root: INFO
    com.commerce: DEBUG
    org.apache.kafka: WARN
  pattern:
    console: "%d{yyyy-MM-dd HH:mm:ss} - %msg%n"
```

---

## Database Schema Standards

### Naming Conventions
- **Tables**: plural, snake_case - `orders`, `payment_transactions`
- **Columns**: snake_case - `order_id`, `created_at`
- **Primary Keys**: `id` (UUID or Long)
- **Foreign Keys**: `{entity}_id` - `customer_id`, `product_id`
- **Timestamps**: `created_at`, `updated_at` (always include)

### Standard Columns (All Tables)
```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
created_by VARCHAR(255),
updated_by VARCHAR(255),
version INTEGER DEFAULT 0  -- For optimistic locking
```

### Entity Template
```java
package com.commerce.order.model.entity;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.GenericGenerator;
import javax.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "orders")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Order {
    
    @Id
    @GeneratedValue(generator = "UUID")
    @GenericGenerator(name = "UUID", strategy = "org.hibernate.id.UUIDGenerator")
    @Column(name = "id", updatable = false, nullable = false)
    private String id;
    
    @Column(name = "customer_id", nullable = false)
    private String customerId;
    
    @Column(name = "total_amount", nullable = false, precision = 19, scale = 2)
    private BigDecimal totalAmount;
    
    @Enumerated(EnumType.STRING)
    @Column(name = "order_status", nullable = false)
    private OrderStatus orderStatus;
    
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
    
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
    
    @Version
    @Column(name = "version")
    private Integer version;
    
    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }
    
    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
```

---

## Error Handling & Resilience

### Retry Configuration
```java
@Configuration
public class KafkaRetryConfig {
    
    public static final int MAX_RETRY_ATTEMPTS = 3;
    public static final long RETRY_BACKOFF_MS = 1000L;
    
    @Bean
    public RetryTemplate kafkaRetryTemplate() {
        RetryTemplate retryTemplate = new RetryTemplate();
        
        FixedBackOffPolicy backOffPolicy = new FixedBackOffPolicy();
        backOffPolicy.setBackOffPeriod(RETRY_BACKOFF_MS);
        
        SimpleRetryPolicy retryPolicy = new SimpleRetryPolicy();
        retryPolicy.setMaxAttempts(MAX_RETRY_ATTEMPTS);
        
        retryTemplate.setBackOffPolicy(backOffPolicy);
        retryTemplate.setRetryPolicy(retryPolicy);
        
        return retryTemplate;
    }
}
```

### Dead Letter Queue Handler
```java
@Component
@RequiredArgsConstructor
public class DeadLetterQueueHandler {
    
    private static final String DLQ_TOPIC = "commerce.dlq";
    
    private final KafkaTemplate<String, Object> kafkaTemplate;
    
    public void sendToDLQ(String originalTopic, Object event, Exception ex) {
        DLQEvent dlqEvent = DLQEvent.builder()
            .originalTopic(originalTopic)
            .originalEvent(event)
            .failureReason(ex.getMessage())
            .failureTimestamp(LocalDateTime.now())
            .build();
        
        kafkaTemplate.send(DLQ_TOPIC, dlqEvent);
    }
}
```

---

## Testing Guidelines

### Integration Test Template
```java
@SpringBootTest
@Testcontainers
@TestPropertySource(properties = {
    "spring.kafka.bootstrap-servers=${spring.embedded.kafka.brokers}"
})
class OrderServiceIntegrationTest {
    
    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:15")
        .withDatabaseName("test_db")
        .withUsername("test")
        .withPassword("test");
    
    @Autowired
    private OrderService orderService;
    
    @Autowired
    private KafkaTemplate<String, Object> kafkaTemplate;
    
    @Test
    void shouldCreateOrderAndPublishEvent() {
        // Given
        OrderRequest request = OrderRequest.builder()
            .customerId("CUST-123")
            .items(List.of(/* items */))
            .build();
        
        // When
        OrderResponse response = orderService.createOrder(request);
        
        // Then
        assertThat(response.getOrderId()).isNotNull();
        assertThat(response.getStatus()).isEqualTo("PENDING");
        
        // Verify Kafka event published (using EmbeddedKafka or Testcontainers)
    }
}
```

---

## Docker & Deployment

### Service Dockerfile Template
```dockerfile
FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

COPY target/*.jar app.jar

EXPOSE ${SERVER_PORT}

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
```

### pom.xml Dependencies (All Services)
```xml
<dependencies>
    <!-- Spring Boot -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-data-jpa</artifactId>
    </dependency>
    
    <!-- Kafka -->
    <dependency>
        <groupId>org.springframework.kafka</groupId>
        <artifactId>spring-kafka</artifactId>
    </dependency>
    
    <!-- PostgreSQL -->
    <dependency>
        <groupId>org.postgresql</groupId>
        <artifactId>postgresql</artifactId>
        <scope>runtime</scope>
    </dependency>
    
    <!-- Lombok -->
    <dependency>
        <groupId>org.projectlombok</groupId>
        <artifactId>lombok</artifactId>
        <optional>true</optional>
    </dependency>
    
    <!-- Validation -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-validation</artifactId>
    </dependency>
    
    <!-- Swagger/OpenAPI -->
    <dependency>
        <groupId>org.springdoc</groupId>
        <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>
        <version>2.2.0</version>
    </dependency>
    
    <!-- Testing -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-test</artifactId>
        <scope>test</scope>
    </dependency>
    <dependency>
        <groupId>org.springframework.kafka</groupId>
        <artifactId>spring-kafka-test</artifactId>
        <scope>test</scope>
    </dependency>
</dependencies>
```

---

## Important Rules

### DO's
✅ Use the exact Kafka event schemas defined above  
✅ Follow package structure consistently across all services  
✅ Include comprehensive logging with SLF4J  
✅ Implement idempotency for event consumers  
✅ Use BigDecimal for all monetary values  
✅ Include Swagger annotations on all REST endpoints  
✅ Implement proper exception handling  
✅ Use DTOs for API requests/responses (never expose entities)  
✅ Include retry logic for Kafka producers  
✅ Send failed events to DLQ after max retries  
✅ Use environment variables for configuration  
✅ Write integration tests for critical flows  

### DON'Ts
❌ Never make synchronous HTTP calls between services (use Kafka)  
❌ Don't modify event schemas without team discussion  
❌ Don't use float/double for money (use BigDecimal)  
❌ Don't expose database entities directly in APIs  
❌ Don't hardcode configuration values  
❌ Don't commit sensitive data (.env files, credentials)  
❌ Don't skip error handling in Kafka consumers  
❌ Don't use auto-commit for Kafka consumers (use manual ack)  
❌ Don't create circular event dependencies  
❌ Don't deploy without testing locally with Docker Compose  

---

## Development Checklist

Before pushing code, verify:
- [ ] Code follows package structure
- [ ] Kafka events use exact schemas from this document
- [ ] All REST endpoints have Swagger documentation
- [ ] Proper logging at INFO and ERROR levels
- [ ] Exception handling implemented
- [ ] Service runs on correct port (8081/8082/8083/8084)
- [ ] Environment variables used (not hardcoded values)
- [ ] Integration test written for new feature
- [ ] Code tested with Docker Compose running
- [ ] No compilation errors or warnings
- [ ] Lombok annotations used correctly
- [ ] Database migrations/schema changes documented

---

## Contact & Coordination

When making changes that affect other services:
1. Discuss in team chat/meeting FIRST
2. Update this CLAUDE.md file if needed
3. Notify all team members
4. Test integration with affected services
5. Document breaking changes in commit message

---

## Quick Reference Commands

```bash
# Build all services
mvn clean install

# Run specific service
cd order-service && ./mvnw spring-boot:run

# Start infrastructure only
docker-compose up -d kafka zookeeper postgres

# View Kafka topics
docker exec -it kafka kafka-topics --list --bootstrap-server localhost:9092

# Consume from topic (debugging)
docker exec -it kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic commerce.order.created \
  --from-beginning

# Check service health
curl http://localhost:8081/actuator/health
```

---

**Last Updated**: 2026-05-27  
**Version**: 1.0  
**Maintained By**: All Team Members

**⚠️ When in doubt, refer to this document. When this document is unclear, discuss with the team before implementing.**
