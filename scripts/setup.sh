#!/bin/bash

# Smart Commerce Platform - Setup Script
# This script sets up the entire project with one command

echo "🚀 Starting Smart Commerce Platform Setup..."

# Check prerequisites
echo "📋 Checking prerequisites..."

if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

if ! command -v java &> /dev/null; then
    echo "❌ Java is not installed. Please install Java 17+ first."
    exit 1
fi

if ! command -v mvn &> /dev/null; then
    echo "❌ Maven is not installed. Please install Maven 3.8+ first."
    exit 1
fi

echo "✅ All prerequisites satisfied"

# Create .env file from template
if [ ! -f .env ]; then
    echo "📝 Creating .env file from template..."
    cp .env.example .env
    echo "✅ .env file created"
else
    echo "ℹ️  .env file already exists, skipping..."
fi

# Start infrastructure services
echo "🐳 Starting infrastructure services (Kafka, PostgreSQL)..."
docker-compose up -d zookeeper kafka postgres kafka-ui

echo "⏳ Waiting for services to be ready..."
sleep 20

# Check if Kafka is ready
echo "🔍 Checking Kafka availability..."
until docker exec kafka kafka-broker-api-versions --bootstrap-server localhost:9092 &> /dev/null; do
    echo "⏳ Waiting for Kafka..."
    sleep 5
done
echo "✅ Kafka is ready"

# Check if PostgreSQL is ready
echo "🔍 Checking PostgreSQL availability..."
until docker exec commerce-postgres pg_isready -U postgres &> /dev/null; do
    echo "⏳ Waiting for PostgreSQL..."
    sleep 5
done
echo "✅ PostgreSQL is ready"

# Build all services
echo "🔨 Building microservices..."

services=("order-service" "payment-inventory-service" "notification-service" "analytics-service")

for service in "${services[@]}"; do
    if [ -d "$service" ] && [ -f "$service/pom.xml" ]; then
        echo "📦 Building $service..."
        cd "$service"
        ./mvnw clean install -DskipTests
        if [ $? -eq 0 ]; then
            echo "✅ $service built successfully"
        else
            echo "❌ Failed to build $service"
            exit 1
        fi
        cd ..
    else
        echo "⚠️  $service directory or pom.xml not found, skipping..."
    fi
done

echo ""
echo "✅ Setup complete!"
echo ""
echo "📍 Access points:"
echo "   - Order Service Swagger: http://localhost:8081/swagger-ui.html"
echo "   - Payment Service Swagger: http://localhost:8082/swagger-ui.html"
echo "   - Notification Service Swagger: http://localhost:8083/swagger-ui.html"
echo "   - Analytics Service Swagger: http://localhost:8084/swagger-ui.html"
echo "   - Kafka UI: http://localhost:8090"
echo ""
echo "🚀 To start all services, run: ./scripts/start-all-services.sh"
echo ""
