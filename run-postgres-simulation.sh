#!/bin/bash

# ============================================
# PostgreSQL CRUD Simulation Runner
# ============================================
# This script runs the PostgreSQL CRUD simulation using Docker
# ============================================

echo "========================================"
echo "PostgreSQL CRUD Simulation"
echo "========================================"

# Configuration
CONTAINER_NAME="postgres-cdc"
POSTGRES_USER="datauser"
POSTGRES_PASSWORD="DataPassword123"
POSTGRES_DB="cdcdb"
SQL_SCRIPT="postgres-crud-simulation.sql"

# Check if Docker container is running
echo "Checking if PostgreSQL container is running..."
if ! docker ps | grep -q $CONTAINER_NAME; then
    echo "Error: PostgreSQL container '$CONTAINER_NAME' is not running."
    echo "Please start it using: docker-compose up -d"
    exit 1
fi

echo "PostgreSQL container is running."
echo ""

# Copy SQL script to container
echo "Copying SQL script to container..."
docker cp $SQL_SCRIPT $CONTAINER_NAME:/tmp/$SQL_SCRIPT

# Execute the SQL script
echo "Executing CRUD simulation script..."
echo "========================================"
docker exec -i $CONTAINER_NAME psql -U $POSTGRES_USER -d $POSTGRES_DB -f /tmp/$SQL_SCRIPT

echo ""
echo "========================================"
echo "CRUD Simulation Complete!"
echo "========================================"
echo ""
echo "The script has performed:"
echo "  - INSERT operations on PRODUCTS and INVENTORY_TRANSACTIONS tables"
echo "  - UPDATE operations to modify existing records"
echo "  - DELETE operations to remove records"
echo ""
echo "All CDC events should now be captured by Debezium."
echo "Check your Event Hub or sink destination for the changes."
