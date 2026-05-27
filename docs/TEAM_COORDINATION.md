# Team Coordination Guide

> **Purpose**: Communication protocols and development workflow for 4-person team

---

## Team Structure

| Role | Student | Service | Primary Focus | Port |
|------|---------|---------|---------------|------|
| **Student A** | [Name] | Order Service | Saga orchestration, order management | 8081 |
| **Student B** | [Name] | Payment & Inventory | Payment processing, retry/DLQ, inventory | 8082 |
| **Student C** | [Name] | Notification Service | Customer engagement, templates | 8083 |
| **Student D** | [Name] | Analytics Service | Real-time metrics, dashboards | 8084 |

**Team Lead**: [Assign one person for coordination]

---

## Communication Channels

### Primary: [Choose One]
- 📱 WhatsApp Group: [Group Name]
- 💬 Slack Channel: [Channel Name]
- 📧 Email Thread: [Subject Line]

### Emergency Contact
- When: Blocker issue that stops progress
- How: Tag @all in chat + call team lead

---

## Development Workflow

### Branch Strategy

```
main (production-ready code)
├── develop (integration branch)
│   ├── student-a/order-service
│   ├── student-b/payment-service
│   ├── student-c/notification-service
│   └── student-d/analytics-service
```

### Daily Workflow

**Morning (Before starting work)**:
```bash
git checkout develop
git pull origin develop
git checkout -b student-x/feature-name
```

**During work**:
```bash
# Commit frequently
git add .
git commit -m "feat: add order creation endpoint"
git push origin student-x/feature-name
```

**End of day**:
```bash
# Create Pull Request to develop branch
# Tag team for review
```

---

## Meeting Schedule

### Daily Standup (15 minutes)
**Time**: [Set time, e.g., 10:00 AM]  
**Format**: Virtual/In-person  

**Each person answers**:
1. What did I complete yesterday?
2. What will I work on today?
3. Any blockers?

### Integration Testing (2x per week)
**Days**: [e.g., Wednesday & Friday]  
**Time**: [e.g., 6:00 PM]  

**Agenda**:
- Start Docker Compose
- Each person runs their service
- Test end-to-end flow
- Fix integration issues together

### Demo Rehearsal (Final week)
**Frequency**: Daily in last week  
**Duration**: 1 hour  

---

## Task Assignment

### Week 1: Setup & Core Implementation
- **All**: Complete environment setup (Docker, Kafka, PostgreSQL)
- **Student A**: Order entity, repository, basic CRUD
- **Student B**: Payment & Inventory entities, repositories
- **Student C**: Notification entity, templates setup
- **Student D**: Analytics entities, database schema
- **All**: Review CLAUDE.md and confirm understanding

### Week 2: Kafka Integration
- **Student A**: Implement Kafka producer for order events
- **Student B**: Implement Kafka consumer for order events
- **Student C**: Implement Kafka consumer for all events
- **Student D**: Implement Kafka consumer for all events
- **Integration Test**: Create order → verify events published/consumed

### Week 3: Business Logic & Error Handling
- **Student A**: Saga orchestration, rollback logic
- **Student B**: Retry mechanism, DLQ implementation
- **Student C**: Template rendering, notification sending
- **Student D**: Metrics calculation, dashboard APIs
- **Integration Test**: Test failure scenarios

### Week 4: Testing & Documentation
- **All**: Write integration tests
- **All**: Complete Swagger documentation
- **All**: Test with Postman
- **Integration Test**: Full end-to-end testing

### Week 5: Demo Preparation
- **All**: Demo rehearsal
- **All**: Prepare backup slides
- **Team Lead**: Coordinate final presentation

---

## Code Review Process

### Pull Request Template

```markdown
## Description
[Brief description of changes]

## Type of Change
- [ ] New feature
- [ ] Bug fix
- [ ] Breaking change
- [ ] Documentation update

## Checklist
- [ ] Code follows package structure from CLAUDE.md
- [ ] Kafka events match schemas exactly
- [ ] Swagger documentation added
- [ ] Integration test written
- [ ] Tested locally with Docker Compose
- [ ] No compilation errors

## Testing
[How did you test this?]

## Related Issues
[Link to issue/task if applicable]
```

### Review Guidelines

**Reviewers should check**:
- ✅ Code follows CLAUDE.md standards
- ✅ Kafka event schemas match exactly
- ✅ No hardcoded values (uses environment variables)
- ✅ Proper exception handling
- ✅ Logging included
- ✅ No breaking changes to shared contracts

**Approval required from**: At least 1 other team member

**Merge to develop**: After approval + all checks pass

---

## Integration Points

### Dependencies Between Services

```
Order Service
    ↓ publishes: commerce.order.created
Payment Service (consumes ↑)
    ↓ publishes: commerce.payment.processed
Order Service (consumes ↑)
    ↓ publishes: commerce.order.completed
Notification & Analytics (consume ↑)
```

**Critical Dependencies**:
1. **Student B depends on Student A**: Payment Service needs OrderCreatedEvent schema
2. **Student A depends on Student B**: Order Service needs PaymentProcessedEvent
3. **Students C & D depend on A & B**: Notification and Analytics need all events

**Coordination Rule**: 
- Student A & B must coordinate closely (tight coupling)
- Students C & D are more independent (loose coupling)

---

## Communication Protocol

### Announcing Changes

**Event Schema Changes**:
```
🔔 BREAKING CHANGE ALERT 🔔

Service: Order Service
Change: Adding new field "customerEmail" to OrderCreatedEvent
Impact: All consumers must update
Deadline: 2026-05-28
PR: #42

@student-b @student-c @student-d please review
```

**API Changes**:
```
📢 API Update

Endpoint: POST /api/v1/orders
Change: Added optional "notes" field
Impact: No breaking change (backward compatible)
PR: #45
```

**Bug Found**:
```
🐛 Bug Report

Service: Payment Service
Issue: Retry mechanism not working
Status: Working on fix
ETA: EOD today
Workaround: Manually retry failed orders

cc: @team-lead
```

---

## Conflict Resolution

### Code Conflicts

**If Git merge conflict**:
1. Don't panic 😊
2. Ask team lead for help
3. Schedule quick sync meeting
4. Resolve together

**If integration issue**:
1. Identify which services affected
2. Check Kafka UI for event flow
3. Review service logs together
4. Test fix in shared environment

---

## Testing Coordination

### Local Testing (Individual)

Each person should test independently:
```bash
# Start infrastructure only
docker-compose up -d kafka zookeeper postgres

# Run your service
cd <your-service>
./mvnw spring-boot:run

# Test your endpoints with Postman
```

### Integration Testing (Team)

Everyone together:
```bash
# Student 1: Start infrastructure
docker-compose up -d

# Each student: Start their service
cd order-service && ./mvnw spring-boot:run
cd payment-inventory-service && ./mvnw spring-boot:run
cd notification-service && ./mvnw spring-boot:run
cd analytics-service && ./mvnw spring-boot:run

# Student A: Create test order via Postman
# Everyone: Watch service logs
# Everyone: Verify events in Kafka UI
```

---

## Shared Resources

### Documentation
- **CLAUDE.md**: Master reference (READ THIS FIRST)
- **API_CONTRACTS.md**: Service integration rules
- **KAFKA_TOPICS.md**: Event schemas
- **DEMO_SCRIPT.md**: Presentation guide

### Tools
- **Postman Collection**: [Share link to collection]
- **Kafka UI**: http://localhost:8090
- **Sample Data**: [shared/test-data/]
- **Docker Commands**: [docs/DOCKER_COMMANDS.md]

---

## Progress Tracking

### Task Board

Use GitHub Projects or Trello:

**Columns**:
- 📋 Backlog
- 🏃 In Progress
- 👀 In Review
- ✅ Done

**Labels**:
- `student-a`, `student-b`, `student-c`, `student-d`
- `blocker`, `urgent`, `enhancement`
- `bug`, `feature`, `docs`

---

## Emergency Protocols

### Service Won't Start

**Step 1**: Check logs
```bash
# For Docker services
docker logs <container-name>

# For local Spring Boot
cat logs/application.log
```

**Step 2**: Check environment
```bash
# Verify .env file exists
cat .env

# Check ports not already in use
lsof -i :8081
```

**Step 3**: Ask team lead

---

### Kafka Issues

**Reset everything** (nuclear option):
```bash
docker-compose down -v  # -v removes volumes
docker-compose up -d
```

---

### Integration Test Fails

1. Check each service logs individually
2. Verify Kafka events with Kafka UI
3. Test services one by one
4. Schedule debugging session with affected team members

---

## Knowledge Sharing

### Documentation Updates

**Who**: Person who figures out something tricky  
**What**: Update relevant .md file  
**When**: Immediately after solving issue

**Example**: 
```markdown
## Troubleshooting: Consumer Not Receiving Messages

**Solution**: Make sure consumer group ID is unique per service.

❌ Wrong:
spring.kafka.consumer.group-id=commerce-group

✅ Correct:
spring.kafka.consumer.group-id=payment-service-group
```

---

## Demo Day Responsibilities

### Student A (Order Service)
- [ ] Explain system architecture
- [ ] Create test order
- [ ] Show order status tracking
- [ ] Demonstrate rollback scenario

### Student B (Payment & Inventory)
- [ ] Explain retry mechanism
- [ ] Show DLQ handling
- [ ] Demonstrate inventory reservation
- [ ] Explain idempotency

### Student C (Notification)
- [ ] Show notification templates
- [ ] Demonstrate email sending (logs)
- [ ] Explain service independence

### Student D (Analytics)
- [ ] Show real-time dashboard
- [ ] Explain metrics calculation
- [ ] Demonstrate event replay (if time)

### Team Lead
- [ ] Coordinate timing
- [ ] Handle Q&A
- [ ] Manage backup plan if tech fails

---

## Final Week Checklist

**Everyone**:
- [ ] Code complete and merged to main
- [ ] All tests passing
- [ ] Swagger docs complete
- [ ] Service README updated
- [ ] No TODO comments in code

**Integration**:
- [ ] Full end-to-end test successful
- [ ] Failure scenarios tested
- [ ] Performance acceptable (< 5s per order)

**Demo**:
- [ ] Rehearsed 3+ times
- [ ] Backup slides ready
- [ ] Roles assigned
- [ ] Q&A prep done

---

## Celebration Plan 🎉

After successful demo:
- [ ] Team dinner/lunch
- [ ] Update LinkedIn with project
- [ ] GitHub repo made public (portfolio)
- [ ] Screenshots/recording for resume

---

**Remember**: We're in this together! Ask for help early, communicate often, and support each other. 💪

**Version**: 1.0  
**Last Updated**: 2026-05-27
