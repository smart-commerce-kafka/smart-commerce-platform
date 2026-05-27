# Event-Driven Smart Commerce Platform

> A distributed e-commerce system built with Spring Boot microservices and Apache Kafka for event-driven communication.

## 🏗️ Architecture Overview

This project demonstrates enterprise-grade microservices architecture with:
- **4 Independent Microservices** communicating via Kafka
- **Event-Driven Architecture** for asynchronous processing
- **Saga Pattern** for distributed transactions
- **Docker Compose** for easy deployment
- **Real-time Analytics** and notifications

## 🚀 Quick Start

### Prerequisites
- Java 17+
- Docker & Docker Compose
- Maven 3.8+
- Git

### Run Everything
```bash
# Clone the repository
git clone <your-repo-url>
cd smart-commerce-platform

# Start infrastructure (Kafka, PostgreSQL, etc.)
docker-compose up -d

# Start all microservices (in separate terminals or use tmux/screen)
cd order-service && ./mvnw spring-boot:run
cd payment-inventory-service && ./mvnw spring-boot:run
cd notification-service && ./mvnw spring-boot:run
cd analytics-service && ./mvnw spring-boot:run
```

### Access Points
- **Order Service**: http://localhost:8081/swagger-ui.html
- **Payment & Inventory Service**: http://localhost:8082/swagger-ui.html
- **Notification Service**: http://localhost:8083/swagger-ui.html
- **Analytics Service**: http://localhost:8084/swagger-ui.html
- **Kafka UI**: http://localhost:8090 (if included)

## 📁 Project Structure

```
smart-commerce-platform/
├── docs/                           # All project documentation
│   ├── ARCHITECTURE.md            # System design and diagrams
│   ├── KAFKA_TOPICS.md            # Event schemas and topics
│   ├── API_CONTRACTS.md           # Inter-service APIs
│   └── DEMO_SCRIPT.md             # Presentation guide
├── shared/                         # Common code across services
│   ├── events/                    # Kafka event DTOs
│   └── utils/                     # Common utilities
├── order-service/                  # Student A - Order management
├── payment-inventory-service/      # Student B - Payment & inventory
├── notification-service/           # Student C - Notifications
├── analytics-service/              # Student D - Real-time analytics
├── docker-compose.yml             # Infrastructure setup
├── .env.example                   # Environment variables template
└── setup.sh                       # One-command setup script
```

## 👥 Team Responsibilities

### Student A - Order Service (Port 8081)
- Create and manage orders
- Kafka producer for order events
- Saga orchestration for distributed transactions
- Order status tracking

### Student B - Payment & Inventory Service (Port 8082)
- Process payments (simulation)
- Manage inventory reservation
- Kafka consumer for order events
- Retry mechanism and DLQ implementation
- Rollback handling

### Student C - Notification Service (Port 8083)
- Send email/SMS notifications (simulation)
- Kafka consumer for order and payment events
- Notification templates
- Event-driven customer engagement

### Student D - Analytics Service (Port 8084)
- Real-time revenue analytics
- Order metrics and dashboards
- Kafka stream processing
- Event replay capability

## 🔄 Event Flow

```
1. Order Created → Order Service publishes OrderCreatedEvent
2. Payment Service consumes event → Processes payment
3. Payment Success → PaymentProcessedEvent published
4. Inventory Service reserves stock → InventoryReservedEvent
5. Notification Service sends confirmation email
6. Analytics Service updates real-time dashboard
```

## 📋 Development Workflow

### Branch Strategy
```bash
main                    # Production-ready code
├── student-a/order     # Student A's feature branch
├── student-b/payment   # Student B's feature branch
├── student-c/notify    # Student C's feature branch
└── student-d/analytics # Student D's feature branch
```

### Making Changes
1. Pull latest changes: `git pull origin main`
2. Create feature branch: `git checkout -b student-x/feature-name`
3. Make changes in your service folder only
4. Test locally with Docker Compose running
5. Commit and push: `git push origin student-x/feature-name`
6. Create Pull Request for review

## 🧪 Testing

### Integration Testing
```bash
# Start infrastructure
docker-compose up -d

# Run all services
./run-all-services.sh

# Test end-to-end flow
./scripts/test-e2e.sh
```

### Manual Testing
1. Create order via Order Service API
2. Check Kafka topics for events
3. Verify payment processing
4. Confirm notifications sent
5. View analytics dashboard

## 📊 Demo Preparation

See [docs/DEMO_SCRIPT.md](docs/DEMO_SCRIPT.md) for detailed presentation flow.

**Key Points to Demonstrate:**
- ✅ Complete order lifecycle
- ✅ Event-driven communication via Kafka
- ✅ Failure handling and rollback (Saga pattern)
- ✅ Real-time notifications
- ✅ Live analytics updates
- ✅ Service independence and scalability

## 🛠️ Tech Stack

**Core Infrastructure**:
- **Message Broker**: Apache Kafka
- **Database**: PostgreSQL
- **Containerization**: Docker

**Microservices (Polyglot)**:
- **Option 1**: Java + Spring Boot (all services)
- **Option 2**: Python + FastAPI (all services)
- **Option 3**: Node.js + Express (all services)
- **Option 4**: Mix of Java, Python, and Node.js ✨

See [docs/MULTI_LANGUAGE_GUIDE.md](docs/MULTI_LANGUAGE_GUIDE.md) for implementation examples in each language.

## 📚 Documentation

- [Architecture Guide](docs/ARCHITECTURE.md) - System design and patterns
- [Kafka Topics](docs/KAFKA_TOPICS.md) - Event schemas and topic details
- [API Contracts](docs/API_CONTRACTS.md) - Service endpoints and contracts
- [Demo Script](docs/DEMO_SCRIPT.md) - Presentation walkthrough

## 🆘 Troubleshooting

### Kafka Connection Issues
```bash
docker-compose down
docker-compose up -d kafka zookeeper
```

### Port Already in Use
```bash
# Kill process on port 8081 (example)
lsof -ti:8081 | xargs kill -9
```

### Database Connection Failed
```bash
docker-compose restart postgres
```

## 🎯 Success Criteria

- [ ] All 4 services running independently
- [ ] Kafka events flowing between services
- [ ] Order lifecycle completes successfully
- [ ] Failure scenarios handled with rollback
- [ ] Notifications triggered correctly
- [ ] Analytics dashboard updates in real-time
- [ ] Docker Compose setup works
- [ ] API documentation complete
- [ ] Demo rehearsed and timed

## 📝 License

This is an academic project for [Your University] - Scalable Services Course.

## 👨‍💻 Contributors

- Student A - Order Service
- Student B - Payment & Inventory Service
- Student C - Notification Service
- Student D - Analytics Service

---

**Need Help?** Check the [docs/](docs/) folder or create an issue in this repository.
