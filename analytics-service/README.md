# Analytics Service

**Owner**: Student D  
**Port**: 8084  
**Database**: analytics_db

## Responsibilities

- Real-time business intelligence and metrics
- Consume all Kafka events for analytics
- Dashboard APIs for visualization
- Revenue tracking and aggregation
- Order success/failure rate analysis
- Event replay capability

## Endpoints

### Get Analytics Summary
```http
GET /api/v1/analytics/summary
```

Response:
```json
{
  "totalOrders": 150,
  "completedOrders": 120,
  "cancelledOrders": 30,
  "totalRevenue": 125000.00,
  "averageOrderValue": 833.33,
  "successRate": 80.0,
  "lastUpdated": "2026-05-27T10:30:00Z"
}
```

### Get Revenue by Time Period
```http
GET /api/v1/analytics/revenue/today
GET /api/v1/analytics/revenue/this-week
GET /api/v1/analytics/revenue/this-month
```

### Get Top Products
```http
GET /api/v1/analytics/top-products?limit=10
```

### Get Order Trends
```http
GET /api/v1/analytics/trends?period=HOURLY&hours=24
GET /api/v1/analytics/trends?period=DAILY&days=30
```

### Replay Events (Admin)
```http
POST /api/v1/analytics/replay?from={timestamp}&to={timestamp}
```

## Kafka Integration

### Produces:
- None (pure consumer service)

### Consumes (ALL events):
- `commerce.order.created`
- `commerce.payment.processed`
- `commerce.payment.failed`
- `commerce.inventory.reserved`
- `commerce.inventory.failed`
- `commerce.order.completed`
- `commerce.order.cancelled`

## Database Schema

### order_analytics table
```sql
CREATE TABLE order_analytics (
    id VARCHAR(255) PRIMARY KEY,
    order_id VARCHAR(255) UNIQUE NOT NULL,
    customer_id VARCHAR(255) NOT NULL,
    total_amount NUMERIC(19,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    order_status VARCHAR(50) NOT NULL,
    created_at TIMESTAMP NOT NULL,
    completed_at TIMESTAMP,
    cancelled_at TIMESTAMP,
    cancellation_reason TEXT
);
```

### revenue_metrics table
```sql
CREATE TABLE revenue_metrics (
    id VARCHAR(255) PRIMARY KEY,
    metric_date DATE NOT NULL,
    metric_hour INTEGER, -- 0-23 for hourly metrics
    total_orders INTEGER DEFAULT 0,
    completed_orders INTEGER DEFAULT 0,
    cancelled_orders INTEGER DEFAULT 0,
    total_revenue NUMERIC(19,2) DEFAULT 0.00,
    average_order_value NUMERIC(19,2) DEFAULT 0.00,
    success_rate NUMERIC(5,2) DEFAULT 0.00,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL,
    UNIQUE(metric_date, metric_hour)
);
```

### product_analytics table
```sql
CREATE TABLE product_analytics (
    id VARCHAR(255) PRIMARY KEY,
    product_id VARCHAR(255) UNIQUE NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    total_ordered INTEGER DEFAULT 0,
    total_revenue NUMERIC(19,2) DEFAULT 0.00,
    last_ordered_at TIMESTAMP,
    updated_at TIMESTAMP NOT NULL
);
```

### event_log table (for replay)
```sql
CREATE TABLE event_log (
    id BIGSERIAL PRIMARY KEY,
    event_id VARCHAR(255) UNIQUE NOT NULL,
    event_type VARCHAR(100) NOT NULL,
    topic VARCHAR(255) NOT NULL,
    event_payload JSONB NOT NULL,
    processed_at TIMESTAMP NOT NULL,
    partition_id INTEGER,
    offset_id BIGINT
);
```

## Running Locally

```bash
cd analytics-service

# Build
./mvnw clean install

# Run
./mvnw spring-boot:run

# Access Swagger UI
open http://localhost:8084/swagger-ui.html
```

## Environment Variables

```bash
SERVER_PORT=8084
KAFKA_BOOTSTRAP_SERVERS=localhost:9092
DB_HOST=localhost
DB_PORT=5432
DB_NAME=analytics_db
DB_USERNAME=postgres
DB_PASSWORD=postgres
```

## Implementation Checklist

- [ ] Create Spring Boot project with dependencies
- [ ] Define Analytics entities (OrderAnalytics, RevenueMetrics, etc.)
- [ ] Create repositories
- [ ] Implement AnalyticsService with aggregation logic
- [ ] Configure Kafka consumers for all topics
- [ ] Implement real-time metrics calculation
- [ ] Create REST controllers for dashboard APIs
- [ ] Add event logging for replay capability
- [ ] Implement dashboard aggregation queries
- [ ] Add Swagger documentation
- [ ] Write integration tests
- [ ] Test with sample events

## Key Implementation Notes

### 1. Kafka Consumer Configuration

```java
@Configuration
public class KafkaConsumerConfig {
    
    @Bean
    public ConcurrentKafkaListenerContainerFactory<String, Object> 
            analyticsKafkaListenerContainerFactory(
                ConsumerFactory<String, Object> consumerFactory) {
        
        ConcurrentKafkaListenerContainerFactory<String, Object> factory =
            new ConcurrentKafkaListenerContainerFactory<>();
        factory.setConsumerFactory(consumerFactory);
        
        // Allow consuming from earliest offset (for replay)
        factory.getContainerProperties()
            .setAckMode(ContainerProperties.AckMode.MANUAL);
        
        return factory;
    }
}
```

### 2. Event Consumers

```java
@Component
@RequiredArgsConstructor
@Slf4j
public class AnalyticsEventConsumer {
    
    private final AnalyticsService analyticsService;
    private final EventLogService eventLogService;
    
    @KafkaListener(
        topics = "commerce.order.created",
        groupId = "analytics-service-group"
    )
    public void handleOrderCreated(OrderCreatedEvent event) {
        log.info("Processing OrderCreatedEvent for analytics: orderId={}", 
            event.getOrderId());
        
        // Log event for replay
        eventLogService.logEvent(event, "commerce.order.created");
        
        // Update analytics
        analyticsService.recordOrderCreated(event);
    }
    
    @KafkaListener(
        topics = "commerce.order.completed",
        groupId = "analytics-service-group"
    )
    public void handleOrderCompleted(OrderCompletedEvent event) {
        log.info("Processing OrderCompletedEvent for analytics: orderId={}", 
            event.getOrderId());
        
        eventLogService.logEvent(event, "commerce.order.completed");
        analyticsService.recordOrderCompleted(event);
    }
    
    @KafkaListener(
        topics = "commerce.order.cancelled",
        groupId = "analytics-service-group"
    )
    public void handleOrderCancelled(OrderCancelledEvent event) {
        log.info("Processing OrderCancelledEvent for analytics: orderId={}", 
            event.getOrderId());
        
        eventLogService.logEvent(event, "commerce.order.cancelled");
        analyticsService.recordOrderCancelled(event);
    }
    
    // Similar methods for payment and inventory events
}
```

### 3. Real-Time Metrics Calculation

```java
@Service
@Transactional
@RequiredArgsConstructor
public class AnalyticsService {
    
    private final OrderAnalyticsRepository orderAnalyticsRepository;
    private final RevenueMetricsRepository revenueMetricsRepository;
    
    public void recordOrderCreated(OrderCreatedEvent event) {
        // Create order analytics record
        OrderAnalytics analytics = OrderAnalytics.builder()
            .orderId(event.getOrderId())
            .customerId(event.getCustomerId())
            .totalAmount(event.getTotalAmount())
            .currency(event.getCurrency())
            .orderStatus("PENDING")
            .createdAt(event.getTimestamp())
            .build();
        
        orderAnalyticsRepository.save(analytics);
        
        // Update daily metrics
        updateMetrics(LocalDate.now(), 1, 0, 0, BigDecimal.ZERO);
    }
    
    public void recordOrderCompleted(OrderCompletedEvent event) {
        // Update order analytics
        OrderAnalytics analytics = orderAnalyticsRepository
            .findByOrderId(event.getOrderId())
            .orElseThrow();
        
        analytics.setOrderStatus("COMPLETED");
        analytics.setCompletedAt(event.getCompletedAt());
        orderAnalyticsRepository.save(analytics);
        
        // Update metrics with revenue
        updateMetrics(
            LocalDate.now(), 
            0, 
            1, 
            0, 
            analytics.getTotalAmount()
        );
    }
    
    public void recordOrderCancelled(OrderCancelledEvent event) {
        OrderAnalytics analytics = orderAnalyticsRepository
            .findByOrderId(event.getOrderId())
            .orElseThrow();
        
        analytics.setOrderStatus("CANCELLED");
        analytics.setCancelledAt(event.getTimestamp());
        analytics.setCancellationReason(event.getCancellationReason());
        orderAnalyticsRepository.save(analytics);
        
        updateMetrics(LocalDate.now(), 0, 0, 1, BigDecimal.ZERO);
    }
    
    private void updateMetrics(LocalDate date, int totalOrders, 
                               int completedOrders, int cancelledOrders, 
                               BigDecimal revenue) {
        RevenueMetrics metrics = revenueMetricsRepository
            .findByMetricDateAndMetricHour(date, null)
            .orElseGet(() -> RevenueMetrics.builder()
                .metricDate(date)
                .metricHour(null) // Daily aggregation
                .build());
        
        metrics.setTotalOrders(metrics.getTotalOrders() + totalOrders);
        metrics.setCompletedOrders(metrics.getCompletedOrders() + completedOrders);
        metrics.setCancelledOrders(metrics.getCancelledOrders() + cancelledOrders);
        metrics.setTotalRevenue(metrics.getTotalRevenue().add(revenue));
        
        // Calculate average order value
        if (metrics.getCompletedOrders() > 0) {
            metrics.setAverageOrderValue(
                metrics.getTotalRevenue()
                    .divide(BigDecimal.valueOf(metrics.getCompletedOrders()), 
                        2, RoundingMode.HALF_UP)
            );
        }
        
        // Calculate success rate
        if (metrics.getTotalOrders() > 0) {
            metrics.setSuccessRate(
                BigDecimal.valueOf(metrics.getCompletedOrders())
                    .multiply(BigDecimal.valueOf(100))
                    .divide(BigDecimal.valueOf(metrics.getTotalOrders()), 
                        2, RoundingMode.HALF_UP)
            );
        }
        
        metrics.setUpdatedAt(LocalDateTime.now());
        revenueMetricsRepository.save(metrics);
    }
}
```

### 4. Dashboard APIs

```java
@RestController
@RequestMapping("/api/v1/analytics")
@RequiredArgsConstructor
@Tag(name = "Analytics", description = "Real-time analytics and metrics")
public class AnalyticsController {
    
    private final AnalyticsService analyticsService;
    
    @GetMapping("/summary")
    @Operation(summary = "Get analytics summary")
    public ResponseEntity<AnalyticsSummary> getSummary() {
        AnalyticsSummary summary = analyticsService.getSummary();
        return ResponseEntity.ok(summary);
    }
    
    @GetMapping("/revenue/today")
    public ResponseEntity<RevenueResponse> getTodayRevenue() {
        return ResponseEntity.ok(
            analyticsService.getRevenueForDate(LocalDate.now())
        );
    }
    
    @GetMapping("/top-products")
    public ResponseEntity<List<ProductAnalytics>> getTopProducts(
            @RequestParam(defaultValue = "10") int limit) {
        return ResponseEntity.ok(
            analyticsService.getTopProducts(limit)
        );
    }
}
```

### 5. Event Replay

```java
@Service
@RequiredArgsConstructor
public class EventReplayService {
    
    private final EventLogRepository eventLogRepository;
    private final AnalyticsService analyticsService;
    
    @Transactional
    public void replayEvents(LocalDateTime from, LocalDateTime to) {
        log.info("Replaying events from {} to {}", from, to);
        
        List<EventLog> events = eventLogRepository
            .findByProcessedAtBetweenOrderByProcessedAt(from, to);
        
        log.info("Found {} events to replay", events.size());
        
        for (EventLog eventLog : events) {
            replayEvent(eventLog);
        }
        
        log.info("Event replay completed");
    }
    
    private void replayEvent(EventLog eventLog) {
        // Deserialize and process event based on type
        // This allows recalculating metrics from historical data
    }
}
```

## Testing Scenarios

### 1. Real-Time Updates
- Create order
- Check `/api/v1/analytics/summary` immediately
- Verify metrics updated

### 2. Revenue Tracking
- Complete multiple orders
- Check `/api/v1/analytics/revenue/today`
- Verify revenue aggregation

### 3. Success Rate
- Create 10 orders (5 success, 5 fail)
- Check success rate (should be ~50%)

### 4. Event Replay
- Generate historical events
- Call replay endpoint
- Verify metrics recalculated correctly

## Dashboard Visualization (Optional Frontend)

If time permits, create a simple HTML dashboard:

```html
<!DOCTYPE html>
<html>
<head>
    <title>Commerce Analytics Dashboard</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <h1>Real-Time Analytics</h1>
    
    <div id="summary">
        <p>Total Orders: <span id="totalOrders">0</span></p>
        <p>Revenue: $<span id="totalRevenue">0.00</span></p>
        <p>Success Rate: <span id="successRate">0.0</span>%</p>
    </div>
    
    <canvas id="revenueChart"></canvas>
    
    <script>
        // Fetch data every 5 seconds
        setInterval(() => {
            fetch('http://localhost:8084/api/v1/analytics/summary')
                .then(res => res.json())
                .then(data => {
                    document.getElementById('totalOrders').innerText = data.totalOrders;
                    document.getElementById('totalRevenue').innerText = data.totalRevenue;
                    document.getElementById('successRate').innerText = data.successRate;
                });
        }, 5000);
    </script>
</body>
</html>
```

## Advanced Features (Bonus)

- [ ] Real-time WebSocket updates for dashboard
- [ ] Export metrics to CSV/PDF
- [ ] Grafana integration
- [ ] Predictive analytics (ML-based forecasting)
- [ ] Customer segmentation analysis
- [ ] A/B testing metrics
- [ ] Anomaly detection (sudden revenue drops)

## Contact

For questions or issues, contact Student D or refer to CLAUDE.md
