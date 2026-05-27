# 🚀 Quick Start Guide for Team

> **Welcome!** This is your complete project structure. Start here.

---

## 📦 What You've Got

This monorepo contains **everything** needed for your Event-Driven Smart Commerce Platform:

- ✅ **4 Microservice folders** (one per team member)
- ✅ **Complete Docker setup** (Kafka, PostgreSQL, all infrastructure)
- ✅ **Master reference doc** (CLAUDE.md - for AI assistance)
- ✅ **Detailed documentation** (architecture, APIs, demo script)
- ✅ **Setup scripts** (one-command deployment)

---

## 🏃 Getting Started (First Time Setup)

### 1. Clone/Open This Project

You're already here! If sharing with team:
```bash
# Initialize git (if not already done)
cd smart-commerce-platform
git init
git add .
git commit -m "Initial project structure"

# Create GitHub repo and push
git remote add origin <your-github-url>
git push -u origin main
```

### 2. Install Prerequisites

**Everyone needs**:
- ✅ Docker Desktop (includes Docker Compose)
- ✅ Git

**Language-specific (choose based on your service)**:

**For Java services**:
- ✅ Java 17 or higher
- ✅ Maven 3.8+

**For Python services**:
- ✅ Python 3.9+
- ✅ pip

**For Node.js services**:
- ✅ Node.js 18+
- ✅ npm

**Check your installations**:
```bash
docker --version          # Should show 20.x or higher
docker-compose --version  # Should show 2.x or higher

# Check language tools (based on your choice)
java -version            # For Java
python --version         # For Python
node --version           # For Node.js
```

**⚠️ IMPORTANT**: Decide as a team which language(s) to use! See [docs/LANGUAGE_CHOICE.md](docs/LANGUAGE_CHOICE.md)

### 3. Set Up Environment

```bash
# Copy environment template
cp .env.example .env

# No changes needed for local development!
# Default values work out of the box
```

### 4. Start Infrastructure

```bash
# Make scripts executable (Mac/Linux)
chmod +x scripts/*.sh

# Start Kafka, PostgreSQL, etc.
./scripts/setup.sh
```

This will:
- ✅ Start Kafka + Zookeeper
- ✅ Start PostgreSQL with all databases
- ✅ Start Kafka UI (monitoring)
- ✅ Wait for everything to be ready

**Access Points After Setup**:
- Kafka UI: http://localhost:8090
- PostgreSQL: localhost:5432 (user: postgres, password: postgres)

---

## 👥 Team Member Next Steps

### Student A - Order Service (Port 8081)

**Your folder**: `order-service/`

**Read first**:
1. [order-service/README.md](order-service/README.md) - Your service responsibilities
2. [CLAUDE.md](CLAUDE.md) - Code standards and event schemas

**Start building**:
```bash
cd order-service

# Create Spring Boot project (use Spring Initializr or CLI)
# Add dependencies: Spring Web, Spring Data JPA, Spring Kafka, PostgreSQL, Lombok

# Run your service
./mvnw spring-boot:run
```

**Your checklist**: See [order-service/README.md](order-service/README.md)

---

### Student B - Payment & Inventory Service (Port 8082)

**Your folder**: `payment-inventory-service/`

**Read first**:
1. [payment-inventory-service/README.md](payment-inventory-service/README.md)
2. [CLAUDE.md](CLAUDE.md) - Especially retry and DLQ sections

**Start building**:
```bash
cd payment-inventory-service
# Create Spring Boot project
./mvnw spring-boot:run
```

**Your checklist**: See [payment-inventory-service/README.md](payment-inventory-service/README.md)

---

### Student C - Notification Service (Port 8083)

**Your folder**: `notification-service/`

**Read first**:
1. [notification-service/README.md](notification-service/README.md)
2. [CLAUDE.md](CLAUDE.md) - Event schemas you'll consume

**Start building**:
```bash
cd notification-service
# Create Spring Boot project
./mvnw spring-boot:run
```

**Your checklist**: See [notification-service/README.md](notification-service/README.md)

---

### Student D - Analytics Service (Port 8084)

**Your folder**: `analytics-service/`

**Read first**:
1. [analytics-service/README.md](analytics-service/README.md)
2. [CLAUDE.md](CLAUDE.md) - All event schemas

**Start building**:
```bash
cd analytics-service
# Create Spring Boot project
./mvnw spring-boot:run
```

**Your checklist**: See [analytics-service/README.md](analytics-service/README.md)

---

## 📚 Essential Documents (Must Read)

### For Everyone
1. **[CLAUDE.md](CLAUDE.md)** ⭐ MOST IMPORTANT
   - Master reference for Claude Code AI assistance
   - Event schemas (MUST match exactly)
   - Code templates and standards
   - Package structure
   - **Read this before writing ANY code!**

2. **[README.md](README.md)** - Project overview and quick start

3. **[docs/TEAM_COORDINATION.md](docs/TEAM_COORDINATION.md)**
   - Development workflow
   - Branch strategy
   - Meeting schedule
   - Communication protocols

### For Understanding the System
4. **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)**
   - System design diagrams
   - Data flow
   - Design patterns (Saga, CQRS, etc.)

5. **[docs/API_CONTRACTS.md](docs/API_CONTRACTS.md)**
   - Service integration rules
   - Event contracts
   - Error handling standards

6. **[docs/KAFKA_TOPICS.md](docs/KAFKA_TOPICS.md)**
   - All Kafka topics
   - Monitoring commands
   - Troubleshooting

### For Demo Day
7. **[docs/DEMO_SCRIPT.md](docs/DEMO_SCRIPT.md)**
   - Step-by-step presentation guide
   - What to show and when
   - Q&A prep

---

## 🛠️ Daily Development Workflow

### Morning Routine
```bash
# 1. Pull latest changes
git pull origin main

# 2. Start infrastructure (if not already running)
docker-compose up -d

# 3. Check everything is healthy
docker-compose ps
# All services should show "Up"

# 4. Start your service
cd <your-service-folder>
./mvnw spring-boot:run
```

### During Development
```bash
# Commit frequently
git add .
git commit -m "feat: add order creation endpoint"
git push
```

### Testing Your Changes
```bash
# 1. Test your API with Postman/curl
curl -X POST http://localhost:8081/api/v1/orders \
  -H "Content-Type: application/json" \
  -d '{"customerId":"CUST-123","items":[...]}'

# 2. Check Kafka UI for events
open http://localhost:8090

# 3. Check database
docker exec -it commerce-postgres psql -U postgres -d order_db
```

---

## 🤝 Working Together

### Integration Testing (2x per week)

**Coordinate with team**:
1. Everyone starts their service
2. Student A creates test order
3. Watch events flow through Kafka
4. Verify each service processes correctly
5. Fix any issues together

### Code Review

Before merging:
- [ ] Code follows CLAUDE.md standards
- [ ] Events match schemas exactly
- [ ] Tested with Docker Compose running
- [ ] At least 1 team member reviewed

---

## 🚨 Common Issues & Solutions

### "Port already in use"
```bash
# Kill process on port (example: 8081)
lsof -ti:8081 | xargs kill -9
```

### "Kafka connection refused"
```bash
# Restart Kafka
docker-compose restart kafka
# Wait 30 seconds
```

### "Database connection failed"
```bash
# Restart PostgreSQL
docker-compose restart postgres
```

### "Service won't start"
```bash
# Check logs
docker-compose logs <service-name>

# Clean restart
docker-compose down
docker-compose up -d
```

---

## 🎯 Project Milestones

### Week 1: Foundation ✅
- [ ] Environment setup complete
- [ ] All team members can run Docker Compose
- [ ] Basic Spring Boot projects created
- [ ] CLAUDE.md read and understood

### Week 2: Core Implementation 🏗️
- [ ] Database entities created
- [ ] REST endpoints implemented
- [ ] Kafka producers/consumers configured
- [ ] Basic event flow working

### Week 3: Integration 🔗
- [ ] All services communicating via Kafka
- [ ] Saga pattern implemented
- [ ] Failure scenarios handled
- [ ] End-to-end test successful

### Week 4: Polish ✨
- [ ] Swagger documentation complete
- [ ] Integration tests written
- [ ] Error handling robust
- [ ] Performance acceptable

### Week 5: Demo Ready 🎬
- [ ] Demo rehearsed 3+ times
- [ ] Backup plan prepared
- [ ] Presentation roles assigned
- [ ] Confidence level: HIGH!

---

## 📞 Getting Help

### From Team
- Daily standup meetings
- Team chat (WhatsApp/Slack)
- Pair programming sessions

### From AI (Claude Code)
1. Open this project in Claude Code
2. Claude automatically reads **CLAUDE.md**
3. Ask: "Help me implement order creation endpoint"
4. Claude will follow the standards in CLAUDE.md

### From Documentation
- Check relevant service README first
- Check CLAUDE.md for code examples
- Check ARCHITECTURE.md for design questions
- Check API_CONTRACTS.md for integration questions

---

## ✅ Pre-Demo Checklist (Week 5)

**Infrastructure**:
- [ ] Docker Compose starts all services
- [ ] Kafka UI accessible
- [ ] All databases created

**Code**:
- [ ] All services run without errors
- [ ] Swagger UI accessible for each service
- [ ] Events flowing through Kafka
- [ ] No hardcoded values

**Testing**:
- [ ] Happy path: Order completes successfully
- [ ] Failure path: Payment fails, order cancelled
- [ ] Failure path: Inventory out of stock
- [ ] Notifications sent correctly
- [ ] Analytics dashboard updates in real-time

**Demo**:
- [ ] Presentation rehearsed
- [ ] Backup slides/video ready
- [ ] Roles assigned
- [ ] Q&A prep done

---

## 🎓 Learning Resources

### Spring Boot + Kafka
- [Spring Kafka Documentation](https://docs.spring.io/spring-kafka/docs/current/reference/html/)
- [Kafka Quick Start](https://kafka.apache.org/quickstart)

### Microservices Patterns
- Saga Pattern
- Event Sourcing
- CQRS

### Tools
- [Postman](https://www.postman.com/) - API testing
- [Docker Desktop](https://www.docker.com/products/docker-desktop) - Containerization
- [DBeaver](https://dbeaver.io/) - Database GUI (optional)

---

## 🎉 Success Criteria

Your project will be successful if:

✅ **Technical**:
- All 4 services deployed and running
- Event-driven communication working
- Saga pattern implemented
- Failure scenarios handled
- Real-time analytics working

✅ **Presentation**:
- Clear architecture explanation
- Live demo works
- Failure scenario demonstrated
- Q&A handled confidently

✅ **Teamwork**:
- Code merged cleanly
- Everyone contributed equally
- Good communication throughout
- Fun experience! 😊

---

## 📂 Folder Structure Overview

```
smart-commerce-platform/
├── README.md                      ← Project overview
├── CLAUDE.md                      ⭐ MASTER REFERENCE (read first!)
├── docker-compose.yml             ← Infrastructure setup
├── .env.example                   ← Environment template
├── .gitignore                     ← Git ignore rules
│
├── docs/                          📚 Documentation
│   ├── ARCHITECTURE.md            ← System design
│   ├── API_CONTRACTS.md           ← Integration rules
│   ├── KAFKA_TOPICS.md            ← Event schemas
│   ├── DEMO_SCRIPT.md             ← Presentation guide
│   └── TEAM_COORDINATION.md       ← Workflow & communication
│
├── scripts/                       🛠️ Automation scripts
│   ├── setup.sh                   ← One-command setup
│   ├── start-all-services.sh     ← Start all microservices
│   ├── stop-all-services.sh      ← Stop everything
│   └── init-databases.sql        ← Database initialization
│
├── order-service/                 👤 Student A
│   └── README.md                  ← Service-specific guide
│
├── payment-inventory-service/     👤 Student B
│   └── README.md
│
├── notification-service/          👤 Student C
│   └── README.md
│
├── analytics-service/             👤 Student D
│   └── README.md
│
└── shared/                        📦 Common code
    ├── events/                    ← Kafka event DTOs (will be shared)
    └── utils/                     ← Common utilities
```

---

## 🚀 Ready to Start?

1. ✅ Read CLAUDE.md completely
2. ✅ Read your service's README.md
3. ✅ Run `./scripts/setup.sh`
4. ✅ Start building!

**Questions?** Check documentation or ask your team. You've got this! 💪

---

**Last Updated**: 2026-05-27  
**Team**: Students A, B, C, D  
**Project**: Event-Driven Smart Commerce Platform

**Good luck and happy coding! 🎉**
