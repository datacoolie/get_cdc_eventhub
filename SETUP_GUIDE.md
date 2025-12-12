# CDC Real-time Setup Guide

Complete guide to set up and run Change Data Capture (CDC) from Oracle and PostgreSQL databases to Azure Event Hubs using Debezium Server.

## 📋 Table of Contents

- [Prerequisites](#prerequisites)
- [Project Overview](#project-overview)
- [Architecture](#architecture)
- [Initial Setup](#initial-setup)
- [Configuration](#configuration)
- [Building and Running](#building-and-running)
- [Testing the Setup](#testing-the-setup)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)
- [Production Considerations](#production-considerations)

---

## Prerequisites

### Required Software

- **Docker Desktop** (with Docker Compose)
  - Windows: Download from [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/)
  - Minimum 8GB RAM allocated to Docker
  - WSL 2 backend enabled (recommended for Windows)

- **Git** (for version control)

- **Text Editor** (VS Code, Notepad++, etc.)

### Azure Requirements (Optional)

- **Azure Subscription** with access to:
  - Azure Event Hubs namespace (for production)
  
- **Azure Credentials**:
  - Event Hubs connection string

**Note**: For local testing, you can use the file sink without Azure credentials.

### Network Requirements

- Ports required:
  - `1521` - Oracle Database
  - `5432` - PostgreSQL Database
  - `8080` - Debezium health endpoints

---

## Project Overview

This project provides a complete CDC pipeline using:

### Source Databases
- **Oracle XE (Express Edition)** - LogMiner-based CDC
- **PostgreSQL 15** - Logical replication-based CDC

### CDC Engine
- **Debezium Server 2.5** - Standalone CDC platform
- Custom Oracle image with Avro support

### Destination
- **Azure Event Hubs** - Real-time event streaming

### Features
- ✅ Real-time change capture
- ✅ JSON format support
- ✅ Automatic offset management
- ✅ Health monitoring endpoints
- ✅ Docker-based deployment
- ✅ Sample tables and data included

---

## Initial Setup

### Step 1: Clone and Navigate

```powershell
cd d:\GitHub\get_cdc_realtime
```

### Step 2: Create Required Directories

```powershell
# Create offset storage directories
New-Item -Path ".\debezium-server\oracle-offset-storage" -ItemType Directory -Force
New-Item -Path ".\debezium-server\postgres-offset-storage" -ItemType Directory -Force
```

### Step 3: Create Environment File

Create a file named `.env` in the `debezium-server` folder:

```powershell
New-Item -Path ".\debezium-server\.env" -ItemType File
```

Edit `debezium-server\.env` and add your Azure credentials (if using Event Hubs):

```properties
# Azure Event Hubs Configuration (only needed if using Event Hubs sink)
EVENTHUBS_CONNECTION_STRING=Endpoint=sb://<YOUR-NAMESPACE>.servicebus.windows.net/;SharedAccessKeyName=<KEY-NAME>;SharedAccessKey=<KEY>
POSTGRES_EVENTHUB_NAME=<YOUR-HUB-NAME>
AZURE_EVENTHUB_NAMESPACE=<YOUR-NAMESPACE>
SAS_KEY_NAME=<KEY-NAME>
SAS_KEY=<KEY>

# Data Format (JSON is default)
DATA_FORMAT=json
JSON_SCHEMAS_ENABLE=false
```

**Important**: Replace `<YOUR-NAMESPACE>`, `<KEY-NAME>`, `<KEY>`, etc. with your actual Azure credentials.

**For Testing**: Skip this step if using file sink locally. Just create an empty `.env` file.

---

## Configuration

### Oracle CDC Configuration

File: `debezium-server\oracle-application.properties`

**Key Settings**:
- **Snapshot Mode**: `schema_only` - Captures only new changes, no historical data
- **LogMiner Strategy**: `online_catalog` - Best performance for Oracle XE
- **Continuous Mining**: `true` - Real-time CDC
- **Format**: JSON (default)
- **User Separation**: 
  - `cdcuser` - Read-only access for CDC operations
  - `datauser` - Owns tables and data for application operations

**Table Selection** (lines 65-75 in the properties file):
```properties
debezium.source.table.include.list=XEPDB1.DATAUSER.CUSTOMERS,XEPDB1.DATAUSER.ORDERS
```

### PostgreSQL CDC Configuration

File: `debezium-server\postgres-application.properties`

**Key Settings**:
- **Snapshot Mode**: `no_data` - Only captures changes from now
- **Plugin**: `pgoutput` - Native PostgreSQL logical replication
- **Replication Slot**: Auto-created as `debezium_slot`
- **User Separation**: 
  - `cdcuser` - Read-only access for CDC operations
  - `datauser` - Owns tables and data for application operations

**Table Selection** (line 44 in the properties file):
```properties
debezium.source.table.include.list=datauser.products,datauser.inventory_transactions
```

**Note**: Tables are in the `datauser` schema (owned by datauser). The cdcuser only has SELECT permissions for CDC.

### Sink Configuration

**Option 1: File Sink (for local testing)**
```properties
debezium.sink.type=file
debezium.sink.file.destination=/debezium/data/output
```

**Option 2: Azure Event Hubs (for production)**
```properties
debezium.sink.type=eventhubs
debezium.sink.eventhubs.hubname=${POSTGRES_EVENTHUB_NAME}
debezium.sink.eventhubs.connectionstring=${POSTGRES_EVENTHUBS_CONNECTION_STRING:...}
```

**Data Format Configuration (JSON)**:
```properties
debezium.format.key=json
debezium.format.value=json
debezium.format.json.schemas.enable=false
```

**Topic Naming**:
- Oracle: `oracle.<schema>.<table>` (e.g., `oracle.DATAUSER.CUSTOMERS`)
- PostgreSQL: `postgres.<schema>.<table>` (e.g., `postgres.datauser.products`)

---

## Building and Running

### Step 1: Start All Services

```powershell
docker-compose up -d
```

This starts:
1. **Oracle Database** (takes ~2 minutes to initialize)
2. **PostgreSQL Database** (takes ~30 seconds)
3. **Debezium Oracle** (waits for Oracle health check)
4. **Debezium PostgreSQL** (waits for PostgreSQL health check)

### Step 2: Monitor Startup

Watch the logs to ensure everything starts correctly:

```powershell
# View all logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f postgres
docker-compose logs -f debezium-postgres
```

**Startup indicators**:
- PostgreSQL: `database system is ready to accept connections`
- Debezium: `Connected to PostgreSQL database` and `Started DebeziumServer`

### Step 3: Verify Service Health

```powershell
# Check container status
docker-compose ps

# All containers should show "healthy" or "running"
```

---

## Testing the Setup

### Test 0: Enable Archive Log and Supplemental Logging

**Before running CDC tests**, ensure Oracle is properly configured for LogMiner-based CDC.

**Connect to Oracle as SYSDBA**:
```powershell
docker exec -it oracle-cdc sqlplus sys/OraclePassword123 as sysdba
```

**Step 1: Enable Archive Log Mode**:
```sql
-- Check current archive log status
ARCHIVE LOG LIST;

-- If not in ARCHIVELOG mode, enable it
SHUTDOWN IMMEDIATE;
STARTUP MOUNT;
ALTER DATABASE ARCHIVELOG;
ALTER DATABASE OPEN;

-- Verify archive log is enabled
ARCHIVE LOG LIST;

```

**Step 2: Enable Supplemental Logging**:
```sql
-- Enable minimal supplemental logging at database level
ALTER DATABASE ADD SUPPLEMENTAL LOG DATA;

-- Verify supplemental logging is enabled
SELECT supplemental_log_data_min, 
       supplemental_log_data_pk, 
       supplemental_log_data_all 
FROM v$database;
-- Should return 'YES'

-- Switch to pluggable database
ALTER SESSION SET CONTAINER = XEPDB1;

-- Enable supplemental logging for CDC tables
ALTER TABLE DATAUSER.CUSTOMERS ADD SUPPLEMENTAL LOG DATA (PRIMARY KEY) COLUMNS;
ALTER TABLE DATAUSER.ORDERS ADD SUPPLEMENTAL LOG DATA (PRIMARY KEY) COLUMNS;
-- ALTER TABLE DATAUSER.CUSTOMERS ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;
-- ALTER TABLE DATAUSER.ORDERS ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;

-- Verify table-level supplemental logging
SELECT owner, table_name, log_group_name, log_group_type 
FROM dba_log_groups 
WHERE owner = 'DATAUSER';

EXIT;
```

**Step 3: Restart Debezium Oracle to Pick Up Changes**:
```powershell
docker-compose restart debezium-oracle

# Monitor logs to ensure successful connection
docker-compose logs -f debezium-oracle
```

Expected log message: `Mining session started` and `Connected to Oracle database`


### Test 1: Verify Database Connections

**Oracle**:
```powershell
docker exec -it oracle-cdc sqlplus cdcuser/CdcPassword123@XEPDB1
```

Inside SQL*Plus:
```sql
-- Check tables
SELECT table_name FROM user_tables;

-- Check sample data
SELECT COUNT(*) FROM CUSTOMERS;

-- Exit
EXIT;
```

```powershell
docker exec -it oracle-cdc sqlplus datauser/DataPassword123@XEPDB1
```

Inside SQL*Plus:
```sql
-- Check tables
SELECT table_name FROM user_tables;

-- Check sample data
SELECT COUNT(*) FROM CUSTOMERS;

-- Exit
EXIT;
```

**PostgreSQL** (using datauser for data operations):
```powershell
docker exec -it postgres-cdc psql -U datauser -d cdcdb
```

Inside psql:
```sql
-- Check tables
\dt datauser.*

-- Check sample data
SELECT COUNT(*) FROM datauser.products;

-- Exit
\q
```

**Note**: Use `datauser` for INSERT/UPDATE/DELETE operations. The `cdcuser` only has SELECT permissions for CDC.

### Test 2: Generate CDC Events

**Oracle - Insert a Customer**:
```powershell
docker exec -it oracle-cdc sqlplus datauser/DataPassword123@XEPDB1
```

```sql
-- Insert new customer
INSERT INTO CUSTOMERS (
    customer_id, first_name, last_name, email, phone, city, country
) VALUES (
    customers_seq.NEXTVAL, 'John', 'Doe', 'john.doe.2@example.com', 
    '+1-555-0123', 'New York', 'USA'
);
COMMIT;

-- Update customer
UPDATE CUSTOMERS 
SET credit_limit = 5000.00 
WHERE email = 'john.doe.2@example.com';
COMMIT;

-- Delete customer
DELETE FROM CUSTOMERS WHERE email = 'john.doe.2@example.com';
COMMIT;

EXIT;
```

**PostgreSQL - Insert a Product** (use datauser for write operations):
```powershell
docker exec -it postgres-cdc psql -U datauser -d cdcdb
```

```sql
-- Insert new product
INSERT INTO datauser.products (
    product_name, category, description, price, stock_quantity, supplier_name
) VALUES (
    'Mechanical Keyboard', 'Electronics', 'RGB mechanical keyboard', 
    89.99, 75, 'KeyTech Co'
);

-- Update product
UPDATE datauser.products 
SET price = 79.99, stock_quantity = 100 
WHERE product_name = 'Mechanical Keyboard';

-- Delete product
DELETE FROM datauser.products WHERE product_name = 'Mechanical Keyboard';

\q
```

### Test 3: Verify CDC Events in Debezium Logs

```powershell
# Check Oracle CDC logs
docker-compose logs debezium-oracle | Select-String "Enqueuing source record"

# Check PostgreSQL CDC logs  
docker-compose logs debezium-postgres | Select-String "Enqueuing source record"
```

You should see messages indicating events are being captured and sent.

### Test 4: Verify Events in Azure Event Hubs

Use Azure Portal or Azure CLI:

```powershell
# Using Azure CLI (if installed)
az eventhubs eventhub show --resource-group <YOUR-RG> --namespace-name <YOUR-NAMESPACE> --name oracle.CDCUSER.CUSTOMERS
```

Or check in Azure Portal:
1. Navigate to your Event Hubs namespace
2. Click on "Event Hubs"
3. Look for topics like `oracle.DATAUSER.CUSTOMERS` and `postgres.datauser.products`
4. Check "Incoming Messages" metrics

**Testing with File Sink**: If using file sink for testing, check output files:
```powershell
# View CDC event files
docker exec debezium-postgres ls -la /debezium/data/output/
docker exec debezium-postgres cat /debezium/data/output/postgres.datauser.products.txt
```

---

## Monitoring

### Health Endpoints

Both Debezium servers expose health endpoints (configured on port 8080 internally):

```powershell
# Check Oracle Debezium health
docker exec debezium-oracle curl -s http://localhost:8080/q/health

# Check PostgreSQL Debezium health
docker exec debezium-postgres curl -s http://localhost:8080/q/health
```

Healthy response:
```json
{
  "status": "UP",
  "checks": [...]
}
```

### Log Monitoring

```powershell
# Real-time logs
docker-compose logs -f

# Last 100 lines
docker-compose logs --tail=100

# Specific service with timestamp
docker-compose logs -f --timestamps debezium-oracle
```

### Container Resource Usage

```powershell
# View resource consumption
docker stats

# View specific containers
docker stats oracle-cdc postgres-cdc debezium-oracle debezium-postgres
```

### Database-Specific Monitoring

**Oracle - Check LogMiner Status**:
```sql
-- Connect to Oracle
docker exec -it oracle-cdc sqlplus cdcuser/CdcPassword123@XEPDB1

-- Check archive log status
SELECT name, value FROM v$parameter WHERE name LIKE '%archive%';

-- Check current log files
SELECT * FROM v$log;

-- Check archived logs
SELECT name, first_change#, next_change# FROM v$archived_log ORDER BY first_time DESC;
```

**PostgreSQL - Check Replication Slot**:
```sql
-- Connect to PostgreSQL (use postgres superuser for system views)
docker exec -it postgres-cdc psql -U postgres -d cdcdb

-- Check replication slots
SELECT * FROM pg_replication_slots;

-- Check publication
SELECT * FROM pg_publication;
SELECT * FROM pg_publication_tables;

-- Check WAL status
SELECT * FROM pg_stat_replication;

-- Verify user permissions
\du cdcuser
\du datauser
```

---

## Troubleshooting

### Common Issues

#### 1. Oracle Container Won't Start

**Symptom**: Oracle container keeps restarting or health check fails

**Solutions**:
```powershell
# Check logs
docker-compose logs oracle

# Common causes:
# - Insufficient memory (need at least 2GB for Oracle)
# - Port 1521 already in use

# Check port availability
netstat -ano | findstr :1521

# Allocate more memory in Docker Desktop:
# Settings > Resources > Memory > Increase to 8GB+
```

#### 2. Debezium Can't Connect to Database

**Symptom**: `Connection refused` or `Authentication failed` in Debezium logs

**Solutions**:
```powershell
# Verify database is healthy
docker-compose ps

# Test connection manually
docker exec -it oracle-cdc sqlplus cdcuser/CdcPassword123@XEPDB1
docker exec -it postgres-cdc psql -U cdcuser -d cdcdb

# Check network
docker network inspect get_cdc_realtime_cdc-network
```

#### 3. Oracle LogMiner Errors

**Symptom**: `ORA-01291: missing logfile` or `ORA-01281: SCN out of range`

**Solutions**:
```sql
-- Connect to Oracle as SYSDBA
docker exec -it oracle-cdc sqlplus sys/OraclePassword123@XEPDB1 as sysdba

-- Enable archive log mode (if needed)
SHUTDOWN IMMEDIATE;
STARTUP MOUNT;
ALTER DATABASE ARCHIVELOG;
ALTER DATABASE OPEN;

-- Check archive log status
ARCHIVE LOG LIST;
```

#### 4. PostgreSQL Replication Slot Issues

**Symptom**: `replication slot "debezium_slot" is active` or slot conflicts

**Solutions**:
```sql
-- Connect to PostgreSQL as superuser or datauser
docker exec -it postgres-cdc psql -U postgres -d cdcdb

-- Drop problematic slot (must be done as superuser)
SELECT pg_drop_replication_slot('debezium_slot');

-- Recreate publication as datauser (table owner)
docker exec -it postgres-cdc psql -U datauser -d cdcdb

DROP PUBLICATION IF EXISTS dbz_publication;
CREATE PUBLICATION dbz_publication FOR TABLE 
    datauser.products, 
    datauser.inventory_transactions
WITH (publish = 'insert,update,delete');
```

#### 5. Azure Event Hubs Connection Failures

**Symptom**: `Failed to send batch` or `UnauthorizedException`

**Solutions**:
```powershell
# Check environment variables
docker exec debezium-oracle env | findstr EVENTHUBS

# Verify .env file exists and is loaded
Get-Content .\debezium-server\.env

# Test connection string format (should be):
# Endpoint=sb://NAMESPACE.servicebus.windows.net/;SharedAccessKeyName=...;SharedAccessKey=...

# Restart Debezium with fresh environment
docker-compose restart debezium-oracle debezium-postgres
```

#### 6. No Events Being Captured

**Symptom**: Database changes occur but no events in logs or Event Hubs

**Solutions**:
```powershell
# Check table inclusion filters
docker exec debezium-oracle cat /debezium/conf/application.properties | findstr table.include

# Verify snapshot mode
docker exec debezium-oracle cat /debezium/conf/application.properties | findstr snapshot.mode

# Check if tables are being monitored
docker-compose logs debezium-oracle | Select-String "Creating table"
docker-compose logs debezium-postgres | Select-String "Starting snapshot"

# Ensure transactions are committed (Oracle)
# COMMIT; must be executed after DML operations
```

### Debugging Commands

```powershell
# Full diagnostic
docker-compose ps
docker-compose logs --tail=50 debezium-oracle
docker-compose logs --tail=50 debezium-postgres
docker exec debezium-oracle ls -la /debezium/data
docker exec debezium-postgres ls -la /debezium/data

# Check file permissions
docker exec debezium-oracle ls -la /debezium/conf/
docker exec debezium-postgres ls -la /debezium/conf/

# Inspect running process
docker exec debezium-oracle ps aux
docker exec debezium-postgres ps aux
```

---

## Production Considerations

### Security

1. **Change Default Passwords**: 
   ```yaml
   # Update in docker-compose.yml
   environment:
     - ORACLE_PASSWORD=<STRONG_PASSWORD>
     - APP_USER_PASSWORD=<STRONG_PASSWORD>
   ```

2. **Secure Connection Strings**:
   - Use Azure Key Vault for connection strings
   - Avoid committing `.env` file to Git
   - Add to `.gitignore`:
     ```
     debezium-server/.env
     debezium-server/*-offset-storage/
     ```

3. **Network Isolation**:
   - Use private networks for database communication
   - Restrict exposed ports
   - Enable TLS/SSL for database connections

### Performance Tuning

**Oracle**:
```properties
# Increase batch sizes for high-volume systems
debezium.source.log.mining.batch.size.default=50000
debezium.source.log.mining.batch.size.max=200000

# Adjust memory
environment:
  - JAVA_OPTS=-Xms1g -Xmx4g
```

**PostgreSQL**:
```properties
# Connection pooling
debezium.source.max.queue.size=16000
debezium.source.max.batch.size=4096
```

### High Availability

1. **Database Replication**: Set up Oracle Data Guard or PostgreSQL streaming replication
2. **Debezium Scaling**: Deploy multiple Debezium instances with task distribution
3. **Event Hubs**: Use premium tier for higher throughput and geo-replication
4. **Monitoring**: Implement Azure Monitor alerts for Event Hubs and container health

### Backup and Recovery

```powershell
# Backup offset storage (preserves CDC position)
docker cp debezium-oracle:/debezium/data ./backups/oracle-offset-backup
docker cp debezium-postgres:/debezium/data ./backups/postgres-offset-backup

# Restore offsets
docker cp ./backups/oracle-offset-backup debezium-oracle:/debezium/data
docker cp ./backups/postgres-offset-backup debezium-postgres:/debezium/data
```

### Data Volume Management

```powershell
# Monitor volume sizes
docker system df -v

# Clean up old data
docker-compose down -v  # WARNING: Removes ALL data volumes

# Backup before cleanup
docker run --rm -v get_cdc_realtime_oracle-data:/data -v ${PWD}:/backup alpine tar czf /backup/oracle-backup.tar.gz /data
```

---

## Stopping and Cleanup

### Stop Services

```powershell
# Stop all containers (keeps data)
docker-compose stop

# Stop and remove containers (keeps volumes)
docker-compose down

# Stop and remove everything including volumes
docker-compose down -v
```

### Clean Up Docker Resources

```powershell
# Remove unused images
docker image prune -a

# Remove all stopped containers
docker container prune

# Full system cleanup
docker system prune -a --volumes
```

---

## Quick Reference

### Essential Commands

| Task | Command |
|------|---------|
| Connect to PostgreSQL (data operations) | `docker exec -it postgres-cdc psql -U datauser -d cdcdb` |
| Start services | `docker-compose up -d` |
| Stop services | `docker-compose down` |
| View logs | `docker-compose logs -f` |
| Check health | `docker-compose ps` |
| Oracle SQL (CDC monitoring) | `docker exec -it oracle-cdc sqlplus cdcuser/CdcPassword123@XEPDB1` |
| Oracle SQL (data operations) | `docker exec -it oracle-cdc sqlplus datauser/DataPassword123@XEPDB1` |
| PostgreSQL SQL (data operations) | `docker exec -it postgres-cdc psql -U datauser -d cdcdb` |
| Restart Debezium | `docker-compose restart debezium-oracle debezium-postgres` |

### Configuration Files

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Container orchestration |
| `debezium-server/.env` | Azure credentials (optional) |
| `debezium-server/oracle-application.properties` | Oracle CDC config (if using Oracle) |
| `debezium-server/postgres-application.properties` | PostgreSQL CDC config |
| `oracle-init.sql` | Oracle schema and sample data (if using Oracle) |
| `postgres-init.sql` | PostgreSQL schema and sample data |

### Port Mappings

| Service | Port | Purpose |
|---------|------|---------|
| Oracle | 1521 | Database connections |
| PostgreSQL | 5432 | Database connections |
| Debezium | 8080 (internal) | Health checks |

---

## Additional Resources

- [Debezium Documentation](https://debezium.io/documentation/)
- [Debezium Oracle Connector](https://debezium.io/documentation/reference/stable/connectors/oracle.html)
- [Debezium PostgreSQL Connector](https://debezium.io/documentation/reference/stable/connectors/postgresql.html)
- [Azure Event Hubs Documentation](https://docs.microsoft.com/en-us/azure/event-hubs/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

---

## Support

For issues or questions:
1. Check the [Troubleshooting](#troubleshooting) section
2. Review Debezium logs: `docker-compose logs -f`
3. Consult Debezium community forums or GitHub issues

---

**Last Updated**: December 2025  
**Debezium Version**: 2.5  
**Docker Compose Version**: 3.8
