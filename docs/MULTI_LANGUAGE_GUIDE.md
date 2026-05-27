# Multi-Language Support Guide

> **Purpose**: Implementation guide for Python, Java (Spring Boot), and Node.js

---

## 🌐 Language Choice - Flexibility

Each microservice can be built in **any language** that supports:
- ✅ Kafka client library
- ✅ Database connectivity (PostgreSQL)
- ✅ REST API framework
- ✅ JSON serialization

**Recommended combinations**:
- **Java + Spring Boot** - Best ecosystem for microservices
- **Python + FastAPI/Flask** - Fast development, great for analytics
- **Node.js + Express** - High concurrency, event-driven by nature

---

## 📊 Technology Matrix

| Service | Recommended Language | Why | Alternative |
|---------|---------------------|-----|-------------|
| Order Service | Java (Spring Boot) | Saga orchestration, strong typing | Node.js |
| Payment & Inventory | Java (Spring Boot) | Transaction handling, retry logic | Python |
| Notification Service | Node.js / Python | I/O heavy, simple logic | Java |
| Analytics Service | Python (FastAPI) | Data processing, visualization | Java |

**But mix and match as needed!** That's the beauty of microservices. 🎨

---

## 🔧 Setup by Language

### Java (Spring Boot)

**Dependencies** (pom.xml):
```xml
<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.kafka</groupId>
        <artifactId>spring-kafka</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-data-jpa</artifactId>
    </dependency>
    <dependency>
        <groupId>org.postgresql</groupId>
        <artifactId>postgresql</artifactId>
    </dependency>
</dependencies>
```

**Project Structure**:
```
order-service/
├── pom.xml
└── src/main/java/com/commerce/order/
    ├── OrderServiceApplication.java
    ├── controller/
    ├── service/
    ├── repository/
    ├── model/
    ├── event/
    └── kafka/
```

---

### Python (FastAPI + Kafka)

**Dependencies** (requirements.txt):
```txt
fastapi==0.109.0
uvicorn==0.27.0
kafka-python==2.0.2
sqlalchemy==2.0.25
psycopg2-binary==2.9.9
pydantic==2.5.3
```

**Project Structure**:
```
analytics-service/
├── requirements.txt
├── main.py
├── app/
│   ├── __init__.py
│   ├── api/
│   │   └── routes.py
│   ├── models/
│   │   └── analytics.py
│   ├── kafka/
│   │   ├── producer.py
│   │   └── consumer.py
│   ├── db/
│   │   └── database.py
│   └── schemas/
│       └── events.py
```

---

### Node.js (Express + KafkaJS)

**Dependencies** (package.json):
```json
{
  "dependencies": {
    "express": "^4.18.2",
    "kafkajs": "^2.2.4",
    "pg": "^8.11.3",
    "sequelize": "^6.35.2",
    "joi": "^17.11.0",
    "dotenv": "^16.3.1"
  }
}
```

**Project Structure**:
```
notification-service/
├── package.json
├── index.js
├── src/
│   ├── routes/
│   │   └── notifications.js
│   ├── services/
│   │   └── notificationService.js
│   ├── kafka/
│   │   ├── producer.js
│   │   └── consumer.js
│   ├── models/
│   │   └── notification.js
│   └── db/
│       └── connection.js
```

---

## 📝 Event Schema (Language-Agnostic JSON)

**All services MUST use these exact schemas** regardless of language:

### OrderCreatedEvent
```json
{
  "eventId": "uuid-string",
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

**Implementation in each language** →

---

## 🚀 Implementation Examples

### 1. Kafka Producer

#### Java (Spring Boot)
```java
@Component
@RequiredArgsConstructor
public class OrderEventProducer {
    
    private final KafkaTemplate<String, Object> kafkaTemplate;
    
    public void publishOrderCreatedEvent(OrderCreatedEvent event) {
        kafkaTemplate.send("commerce.order.created", event.getOrderId(), event)
            .whenComplete((result, ex) -> {
                if (ex == null) {
                    log.info("Event published: orderId={}", event.getOrderId());
                } else {
                    log.error("Failed to publish event", ex);
                }
            });
    }
}
```

#### Python (kafka-python)
```python
from kafka import KafkaProducer
import json
from datetime import datetime

class OrderEventProducer:
    def __init__(self):
        self.producer = KafkaProducer(
            bootstrap_servers=['localhost:9092'],
            value_serializer=lambda v: json.dumps(v).encode('utf-8')
        )
    
    def publish_order_created_event(self, event_data):
        event = {
            "eventId": str(uuid.uuid4()),
            "eventType": "ORDER_CREATED",
            "timestamp": datetime.utcnow().isoformat() + "Z",
            **event_data
        }
        
        self.producer.send(
            'commerce.order.created',
            key=event['orderId'].encode('utf-8'),
            value=event
        )
        self.producer.flush()
        print(f"Event published: orderId={event['orderId']}")
```

#### Node.js (KafkaJS)
```javascript
const { Kafka } = require('kafkajs');

class OrderEventProducer {
    constructor() {
        const kafka = new Kafka({
            clientId: 'order-service',
            brokers: ['localhost:9092']
        });
        this.producer = kafka.producer();
    }
    
    async connect() {
        await this.producer.connect();
    }
    
    async publishOrderCreatedEvent(eventData) {
        const event = {
            eventId: uuidv4(),
            eventType: 'ORDER_CREATED',
            timestamp: new Date().toISOString(),
            ...eventData
        };
        
        await this.producer.send({
            topic: 'commerce.order.created',
            messages: [
                {
                    key: event.orderId,
                    value: JSON.stringify(event)
                }
            ]
        });
        
        console.log(`Event published: orderId=${event.orderId}`);
    }
}

module.exports = OrderEventProducer;
```

---

### 2. Kafka Consumer

#### Java (Spring Boot)
```java
@Component
@Slf4j
@RequiredArgsConstructor
public class OrderEventConsumer {
    
    private final PaymentService paymentService;
    
    @KafkaListener(
        topics = "commerce.order.created",
        groupId = "payment-service-group"
    )
    public void consumeOrderCreatedEvent(OrderCreatedEvent event) {
        log.info("Consumed OrderCreatedEvent: orderId={}", event.getOrderId());
        
        try {
            paymentService.processPayment(event);
        } catch (Exception e) {
            log.error("Error processing payment", e);
            // Send to DLQ
        }
    }
}
```

#### Python (kafka-python)
```python
from kafka import KafkaConsumer
import json

class OrderEventConsumer:
    def __init__(self, payment_service):
        self.consumer = KafkaConsumer(
            'commerce.order.created',
            bootstrap_servers=['localhost:9092'],
            group_id='payment-service-group',
            value_deserializer=lambda m: json.loads(m.decode('utf-8')),
            auto_offset_reset='earliest'
        )
        self.payment_service = payment_service
    
    def start_consuming(self):
        print("Starting Kafka consumer...")
        for message in self.consumer:
            event = message.value
            print(f"Consumed OrderCreatedEvent: orderId={event['orderId']}")
            
            try:
                self.payment_service.process_payment(event)
            except Exception as e:
                print(f"Error processing payment: {e}")
                # Send to DLQ

# Run in background thread or async
import threading
consumer = OrderEventConsumer(payment_service)
consumer_thread = threading.Thread(target=consumer.start_consuming, daemon=True)
consumer_thread.start()
```

#### Node.js (KafkaJS)
```javascript
const { Kafka } = require('kafkajs');

class OrderEventConsumer {
    constructor(paymentService) {
        const kafka = new Kafka({
            clientId: 'payment-service',
            brokers: ['localhost:9092']
        });
        this.consumer = kafka.consumer({ groupId: 'payment-service-group' });
        this.paymentService = paymentService;
    }
    
    async connect() {
        await this.consumer.connect();
        await this.consumer.subscribe({ 
            topic: 'commerce.order.created',
            fromBeginning: true 
        });
    }
    
    async startConsuming() {
        await this.consumer.run({
            eachMessage: async ({ topic, partition, message }) => {
                const event = JSON.parse(message.value.toString());
                console.log(`Consumed OrderCreatedEvent: orderId=${event.orderId}`);
                
                try {
                    await this.paymentService.processPayment(event);
                } catch (error) {
                    console.error('Error processing payment:', error);
                    // Send to DLQ
                }
            }
        });
    }
}

module.exports = OrderEventConsumer;
```

---

### 3. REST API Endpoint

#### Java (Spring Boot)
```java
@RestController
@RequestMapping("/api/v1/orders")
@RequiredArgsConstructor
public class OrderController {
    
    private final OrderService orderService;
    
    @PostMapping
    public ResponseEntity<OrderResponse> createOrder(@RequestBody OrderRequest request) {
        OrderResponse response = orderService.createOrder(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }
    
    @GetMapping("/{orderId}")
    public ResponseEntity<OrderResponse> getOrder(@PathVariable String orderId) {
        OrderResponse response = orderService.getOrderById(orderId);
        return ResponseEntity.ok(response);
    }
}
```

#### Python (FastAPI)
```python
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List

app = FastAPI()

class OrderItem(BaseModel):
    productId: str
    productName: str
    quantity: int
    unitPrice: float

class OrderRequest(BaseModel):
    customerId: str
    items: List[OrderItem]

class OrderResponse(BaseModel):
    orderId: str
    customerId: str
    totalAmount: float
    status: str

@app.post("/api/v1/orders", response_model=OrderResponse, status_code=201)
async def create_order(request: OrderRequest):
    response = await order_service.create_order(request)
    return response

@app.get("/api/v1/orders/{order_id}", response_model=OrderResponse)
async def get_order(order_id: str):
    response = await order_service.get_order_by_id(order_id)
    if not response:
        raise HTTPException(status_code=404, detail="Order not found")
    return response
```

#### Node.js (Express)
```javascript
const express = require('express');
const router = express.Router();

router.post('/api/v1/orders', async (req, res) => {
    try {
        const orderRequest = req.body;
        const response = await orderService.createOrder(orderRequest);
        res.status(201).json(response);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

router.get('/api/v1/orders/:orderId', async (req, res) => {
    try {
        const { orderId } = req.params;
        const response = await orderService.getOrderById(orderId);
        
        if (!response) {
            return res.status(404).json({ error: 'Order not found' });
        }
        
        res.json(response);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

module.exports = router;
```

---

### 4. Database Connection

#### Java (Spring Boot + JPA)
```yaml
# application.yml
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/order_db
    username: postgres
    password: postgres
  jpa:
    hibernate:
      ddl-auto: update
```

```java
@Entity
@Table(name = "orders")
public class Order {
    @Id
    private String id;
    private String customerId;
    private BigDecimal totalAmount;
    // ...
}
```

#### Python (SQLAlchemy)
```python
from sqlalchemy import create_engine, Column, String, Float
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

DATABASE_URL = "postgresql://postgres:postgres@localhost:5432/order_db"

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)
Base = declarative_base()

class Order(Base):
    __tablename__ = "orders"
    
    id = Column(String, primary_key=True)
    customer_id = Column(String, nullable=False)
    total_amount = Column(Float, nullable=False)
    # ...

Base.metadata.create_all(bind=engine)
```

#### Node.js (Sequelize)
```javascript
const { Sequelize, DataTypes } = require('sequelize');

const sequelize = new Sequelize(
    'order_db',
    'postgres',
    'postgres',
    {
        host: 'localhost',
        dialect: 'postgres'
    }
);

const Order = sequelize.define('Order', {
    id: {
        type: DataTypes.STRING,
        primaryKey: true
    },
    customerId: {
        type: DataTypes.STRING,
        allowNull: false
    },
    totalAmount: {
        type: DataTypes.FLOAT,
        allowNull: false
    }
}, {
    tableName: 'orders'
});

module.exports = { sequelize, Order };
```

---

## 🐳 Updated Docker Compose

Services can specify their language runtime:

```yaml
version: '3.8'

services:
  # Java service
  order-service:
    build:
      context: ./order-service
      dockerfile: Dockerfile.java
    ports:
      - "8081:8081"
    environment:
      - SERVER_PORT=8081
  
  # Python service
  analytics-service:
    build:
      context: ./analytics-service
      dockerfile: Dockerfile.python
    ports:
      - "8084:8084"
    environment:
      - PORT=8084
  
  # Node.js service
  notification-service:
    build:
      context: ./notification-service
      dockerfile: Dockerfile.node
    ports:
      - "8083:8083"
    environment:
      - PORT=8083
```

---

## 📦 Dockerfiles

### Dockerfile.java
```dockerfile
FROM openjdk:17-slim
WORKDIR /app
COPY target/*.jar app.jar
EXPOSE 8081
CMD ["java", "-jar", "app.jar"]
```

### Dockerfile.python
```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
EXPOSE 8084
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8084"]
```

### Dockerfile.node
```dockerfile
FROM node:20-slim
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 8083
CMD ["node", "index.js"]
```

---

## ✅ Language-Agnostic Checklist

**For ALL languages, ensure**:
- [ ] Kafka events match JSON schemas exactly
- [ ] REST endpoints follow API contracts
- [ ] Database schemas consistent
- [ ] Environment variables used (not hardcoded)
- [ ] Proper error handling
- [ ] Logging included
- [ ] Service runs on correct port

---

## 🎯 Recommended Language Assignments

### Option 1: All Same Language (Easiest)
- ✅ All Java (Spring Boot) - Most enterprise-ready
- ✅ All Python (FastAPI) - Fastest development
- ✅ All Node.js - Most JavaScript-friendly

### Option 2: Mixed (Most Impressive for Demo)
- **Order Service**: Java (complex orchestration)
- **Payment Service**: Java (transaction handling)
- **Notification Service**: Node.js (I/O heavy)
- **Analytics Service**: Python (data processing)

### Option 3: Your Team's Preference
- Use what your team knows best!
- Microservices = freedom to choose 🎨

---

## 📚 Resources by Language

### Java
- [Spring Boot Docs](https://spring.io/projects/spring-boot)
- [Spring Kafka](https://spring.io/projects/spring-kafka)

### Python
- [FastAPI Docs](https://fastapi.tiangolo.com/)
- [kafka-python](https://kafka-python.readthedocs.io/)

### Node.js
- [Express.js](https://expressjs.com/)
- [KafkaJS](https://kafka.js.org/)

---

## 🔄 Inter-Language Communication

**The beauty**: Services don't care about each other's language!

```
Java Order Service 
    → Kafka (JSON) 
        → Python Analytics Service
        → Node.js Notification Service
```

**All communicate via Kafka with JSON** ✅

---

**Next Steps**: Choose your languages and update service README files!

**Version**: 1.0  
**Last Updated**: 2026-05-27
