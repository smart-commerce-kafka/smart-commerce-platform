#!/bin/bash

# Start all microservices
# Run this after setup.sh completes successfully

echo "🚀 Starting all microservices..."

services=("order-service" "payment-inventory-service" "notification-service" "analytics-service")
ports=("8081" "8082" "8083" "8084")

for i in "${!services[@]}"; do
    service=${services[$i]}
    port=${ports[$i]}

    if [ -d "$service" ]; then
        echo "▶️  Starting $service on port $port..."
        cd "$service"
        ./mvnw spring-boot:run &
        cd ..
        sleep 5
    else
        echo "⚠️  $service directory not found, skipping..."
    fi
done

echo ""
echo "✅ All services started!"
echo ""
echo "📍 Service endpoints:"
echo "   - Order Service: http://localhost:8081/swagger-ui.html"
echo "   - Payment Service: http://localhost:8082/swagger-ui.html"
echo "   - Notification Service: http://localhost:8083/swagger-ui.html"
echo "   - Analytics Service: http://localhost:8084/swagger-ui.html"
echo "   - Kafka UI: http://localhost:8090"
echo ""
echo "💡 To stop all services, run: ./scripts/stop-all-services.sh"
echo ""
