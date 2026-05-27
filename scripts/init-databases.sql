-- Create separate databases for each microservice
-- This ensures service isolation and independence

-- Order Service Database
CREATE DATABASE order_db;

-- Payment & Inventory Service Database
CREATE DATABASE payment_db;

-- Notification Service Database
CREATE DATABASE notification_db;

-- Analytics Service Database
CREATE DATABASE analytics_db;

-- Grant privileges (PostgreSQL will use the default user from environment)
-- Additional users can be created here if needed
