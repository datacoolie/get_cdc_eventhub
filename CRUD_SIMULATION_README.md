# CRUD Simulation Scripts

This directory contains scripts to simulate CRUD (Create, Read, Update, Delete) operations on Oracle and PostgreSQL databases for CDC testing.

## Overview

The simulation scripts perform various database operations to generate CDC events that can be captured by Debezium and sent to Azure Event Hub.

### Files Included

#### SQL Scripts
- `oracle-crud-simulation.sql` - Oracle CRUD operations on CUSTOMERS and ORDERS tables
- `postgres-crud-simulation.sql` - PostgreSQL CRUD operations on PRODUCTS and INVENTORY_TRANSACTIONS tables

#### Runner Scripts
- `run-oracle-simulation.sh` - Bash script to execute Oracle simulation (Linux/Mac)
- `run-oracle-simulation.ps1` - PowerShell script to execute Oracle simulation (Windows)
- `run-postgres-simulation.sh` - Bash script to execute PostgreSQL simulation (Linux/Mac)
- `run-postgres-simulation.ps1` - PowerShell script to execute PostgreSQL simulation (Windows)

## Prerequisites

1. Docker and Docker Compose must be installed
2. Database containers must be running:
   ```bash
   docker-compose up -d
   ```
3. Database initialization scripts must have been executed
4. Debezium server should be configured and running

## What the Scripts Do

### Oracle Simulation (`oracle-crud-simulation.sql`)

Performs operations on:
- **CUSTOMERS table**
  - Inserts 6 new customers
  - Updates customer status, contact info, and credit limits
  - Deletes 1 customer

- **ORDERS table**
  - Inserts 5 new orders
  - Updates order status and amounts
  - Deletes 1 order

### PostgreSQL Simulation (`postgres-crud-simulation.sql`)

Performs operations on:
- **PRODUCTS table**
  - Inserts 8 new products
  - Updates prices, stock quantities, and statuses
  - Deletes 1 product

- **INVENTORY_TRANSACTIONS table**
  - Inserts multiple transactions (IN, OUT, ADJUSTMENT)
  - Updates transaction notes
  - Deletes 1 transaction
  - Performs batch operations

## Usage

### Windows (PowerShell)

#### Run Oracle Simulation
```powershell
.\run-oracle-simulation.ps1
```

#### Run PostgreSQL Simulation
```powershell
.\run-postgres-simulation.ps1
```

### Linux/Mac (Bash)

#### Make scripts executable (first time only)
```bash
chmod +x run-oracle-simulation.sh
chmod +x run-postgres-simulation.sh
```

#### Run Oracle Simulation
```bash
./run-oracle-simulation.sh
```

#### Run PostgreSQL Simulation
```bash
./run-postgres-simulation.sh
```

## Manual Execution

If you prefer to run the SQL scripts manually:

### Oracle
```bash
# Copy script to container
docker cp oracle-crud-simulation.sql oracle-db:/tmp/

# Execute script
docker exec -it oracle-db sqlplus datauser/DataPassword123@XEPDB1 @/tmp/oracle-crud-simulation.sql
```

### PostgreSQL
```bash
# Copy script to container
docker cp postgres-crud-simulation.sql postgres-db:/tmp/

# Execute script
docker exec -it postgres-db psql -U datauser -d cdc_demo -f /tmp/postgres-crud-simulation.sql
```

## Expected CDC Events

After running the simulations, Debezium should capture and send the following events to Event Hub:

### Oracle CDC Events
- **INSERT** events for CUSTOMERS and ORDERS
- **UPDATE** events for both tables
- **DELETE** events for both tables

### PostgreSQL CDC Events
- **INSERT** events for PRODUCTS and INVENTORY_TRANSACTIONS
- **UPDATE** events for both tables
- **DELETE** events for both tables

## Verifying CDC Events

### Check Event Hub
1. Go to Azure Portal
2. Navigate to your Event Hub namespace
3. Select your Event Hub
4. Check the "Metrics" section for incoming messages
5. Use Event Hub Explorer or Stream Analytics to view message contents

### Check Debezium Logs
```bash
# Check Debezium server logs
docker logs debezium-server

# Follow logs in real-time
docker logs -f debezium-server
```

### Query Database Directly

#### Oracle
```bash
docker exec -it oracle-db sqlplus datauser/DataPassword123@XEPDB1

# Then in SQL*Plus:
SELECT COUNT(*) FROM CUSTOMERS;
SELECT COUNT(*) FROM ORDERS;
SELECT * FROM CUSTOMERS ORDER BY customer_id;
SELECT * FROM ORDERS ORDER BY order_id;
```

#### PostgreSQL
```bash
docker exec -it postgres-db psql -U datauser -d cdc_demo

# Then in psql:
SELECT COUNT(*) FROM datauser.products;
SELECT COUNT(*) FROM datauser.inventory_transactions;
SELECT * FROM datauser.products ORDER BY product_id;
SELECT * FROM datauser.inventory_transactions ORDER BY transaction_id;
```

## Timing and Delays

The scripts include deliberate delays (2 seconds) between operations to:
- Make CDC event sequencing easier to observe
- Prevent overwhelming the CDC pipeline
- Allow time for Debezium to process each batch of changes

You can modify these delays in the SQL scripts if needed:
- Oracle: `EXEC DBMS_LOCK.SLEEP(seconds);`
- PostgreSQL: `SELECT pg_sleep(seconds);`

## Troubleshooting

### Container Not Running
If you get an error that the container is not running:
```bash
docker-compose up -d
docker ps  # Verify containers are running
```

### Permission Denied (Linux/Mac)
If you get permission denied when running .sh scripts:
```bash
chmod +x run-*.sh
```

### Script Execution Policy (Windows)
If PowerShell blocks script execution:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### SQL Script Errors
If the SQL script fails:
1. Verify database initialization was successful
2. Check that tables exist
3. Verify user permissions
4. Check database logs for detailed errors

### No CDC Events
If CDC events are not appearing:
1. Verify Debezium server is running: `docker ps`
2. Check Debezium configuration in `debezium-server/` directory
3. Review Debezium logs: `docker logs debezium-server`
4. Verify Event Hub connection string is correct
5. Check Azure Event Hub metrics in Azure Portal

## Customization

You can customize the simulation scripts to:
- Add more records
- Perform different types of operations
- Test specific CDC scenarios
- Include additional tables
- Modify operation timing

Simply edit the `.sql` files with your preferred SQL client or text editor.

## Data Reset

To reset the databases and run simulations again:

### Oracle
```sql
DELETE FROM datauser.ORDERS;
DELETE FROM datauser.CUSTOMERS;
COMMIT;
```

### PostgreSQL
```sql
DELETE FROM datauser.inventory_transactions;
DELETE FROM datauser.products WHERE product_id > 5;
```

Or completely reinitialize:
```bash
docker-compose down -v
docker-compose up -d
# Wait for containers to be ready, then run init scripts
```

## Notes

- The Oracle simulation uses sequences for ID generation
- The PostgreSQL simulation uses SERIAL (auto-increment) for IDs
- All operations are committed to ensure CDC capture
- Foreign key constraints are respected (orders deleted before customers)
- Timestamps are automatically managed by database triggers
