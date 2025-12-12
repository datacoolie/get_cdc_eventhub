#!/bin/bash

# ============================================
# Oracle CRUD Simulation Runner
# ============================================
# This script runs the Oracle CRUD simulation using Docker
# ============================================

echo "========================================"
echo "Oracle CRUD Simulation"
echo "========================================"

# Configuration
CONTAINER_NAME="oracle-cdc"
ORACLE_USER="datauser"
ORACLE_PASSWORD="DataPassword123"
ORACLE_SID="XEPDB1"
SQL_SCRIPT="oracle-crud-simulation.sql"

# Check if Docker container is running
echo "Checking if Oracle container is running..."
if ! docker ps | grep -q $CONTAINER_NAME; then
    echo "Error: Oracle container '$CONTAINER_NAME' is not running."
    echo "Please start it using: docker-compose up -d"
    exit 1
fi

echo "Oracle container is running."
echo ""

# Copy SQL script to container
echo "Copying SQL script to container..."
docker cp $SQL_SCRIPT $CONTAINER_NAME:/tmp/$SQL_SCRIPT

# Execute the SQL script
echo "Executing CRUD simulation script..."
echo "========================================"
docker exec -i $CONTAINER_NAME sqlplus -S ${ORACLE_USER}/${ORACLE_PASSWORD}@${ORACLE_SID} @/tmp/$SQL_SCRIPT

echo ""
echo "========================================"
echo "CRUD Simulation Complete!"
echo "========================================"
echo ""
echo "The script has performed:"
echo "  - INSERT operations on CUSTOMERS and ORDERS tables"
echo "  - UPDATE operations to modify existing records"
echo "  - DELETE operations to remove records"
echo ""
echo "All CDC events should now be captured by Debezium."
echo "Check your Event Hub or sink destination for the changes."
