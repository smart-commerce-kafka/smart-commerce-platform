#!/bin/bash

# Stop all microservices and infrastructure

echo "🛑 Stopping all services..."

# Kill all Spring Boot processes
pkill -f "spring-boot:run"

# Stop Docker containers
docker-compose down

echo "✅ All services stopped"
