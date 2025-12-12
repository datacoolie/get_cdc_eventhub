# ============================================
# Oracle CRUD Simulation Runner (PowerShell)
# ============================================
# This script runs the Oracle CRUD simulation using Docker
# ============================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Oracle CRUD Simulation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Configuration
$CONTAINER_NAME = "oracle-cdc"
$ORACLE_USER = "datauser"
$ORACLE_PASSWORD = "DataPassword123"
$ORACLE_SID = "XEPDB1"
$SQL_SCRIPT = "oracle-crud-simulation.sql"

# Check if Docker container is running
Write-Host "Checking if Oracle container is running..." -ForegroundColor Yellow
$containerRunning = docker ps --filter "name=$CONTAINER_NAME" --format "{{.Names}}"

if (-not $containerRunning) {
    Write-Host "Error: Oracle container '$CONTAINER_NAME' is not running." -ForegroundColor Red
    Write-Host "Please start it using: docker-compose up -d" -ForegroundColor Yellow
    exit 1
}

Write-Host "Oracle container is running." -ForegroundColor Green
Write-Host ""

# Copy SQL script to container
Write-Host "Copying SQL script to container..." -ForegroundColor Yellow
docker cp $SQL_SCRIPT ${CONTAINER_NAME}:/tmp/$SQL_SCRIPT

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to copy SQL script to container." -ForegroundColor Red
    exit 1
}

# Execute the SQL script
Write-Host "Executing CRUD simulation script..." -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
docker exec -i $CONTAINER_NAME sqlplus -S "${ORACLE_USER}/${ORACLE_PASSWORD}@${ORACLE_SID}" "@/tmp/$SQL_SCRIPT"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CRUD Simulation Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "The script has performed:" -ForegroundColor Yellow
Write-Host "  - INSERT operations on CUSTOMERS and ORDERS tables" -ForegroundColor White
Write-Host "  - UPDATE operations to modify existing records" -ForegroundColor White
Write-Host "  - DELETE operations to remove records" -ForegroundColor White
Write-Host ""
Write-Host "All CDC events should now be captured by Debezium." -ForegroundColor Green
Write-Host "Check your Event Hub or sink destination for the changes." -ForegroundColor Green
