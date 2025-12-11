-- ============================================
-- Oracle CDC User Setup and Sample Tables
-- ============================================
-- Script for Oracle XE to setup CDC user and tables
-- c##cdcuser: Common user for CDC operations (CDB level)
-- datauser: Local user for table ownership (PDB level)
-- ============================================
ALTER SESSION SET CONTAINER = CDB$ROOT;

CREATE TABLESPACE logminer_tbs DATAFILE '/opt/oracle/oradata/XE/logminer_tbs.dbf'
    SIZE 25M REUSE AUTOEXTEND ON MAXSIZE UNLIMITED;

ALTER SESSION SET CONTAINER = XEPDB1;

CREATE TABLESPACE logminer_tbs DATAFILE '/opt/oracle/oradata/XE/XEPDB1/logminer_tbs.dbf' 
    SIZE 25M REUSE AUTOEXTEND ON MAXSIZE UNLIMITED;

-- ============================================
-- STEP 1: Create Common CDC User at CDB Root
-- ============================================
-- Switch to CDB root to create common user
ALTER SESSION SET CONTAINER = CDB$ROOT;

-- ============================================
-- Create local user in pluggable database
CREATE USER c##cdcuser IDENTIFIED BY CdcPassword123
    DEFAULT TABLESPACE logminer_tbs
    QUOTA UNLIMITED ON logminer_tbs
    CONTAINER=ALL;

-- Grant privileges
GRANT CREATE SESSION TO c##cdcuser CONTAINER=ALL; 
GRANT SET CONTAINER TO c##cdcuser CONTAINER=ALL; 
GRANT SELECT ON V_$DATABASE to c##cdcuser CONTAINER=ALL; 
GRANT FLASHBACK ANY TABLE TO c##cdcuser CONTAINER=ALL; 
GRANT SELECT ANY TABLE TO c##cdcuser CONTAINER=ALL; 
GRANT SELECT_CATALOG_ROLE TO c##cdcuser CONTAINER=ALL; 
GRANT EXECUTE_CATALOG_ROLE TO c##cdcuser CONTAINER=ALL; 
GRANT SELECT ANY TRANSACTION TO c##cdcuser CONTAINER=ALL; 
GRANT LOGMINING TO c##cdcuser CONTAINER=ALL; 

GRANT CREATE TABLE TO c##cdcuser CONTAINER=ALL; 
GRANT LOCK ANY TABLE TO c##cdcuser CONTAINER=ALL; 
GRANT CREATE SEQUENCE TO c##cdcuser CONTAINER=ALL; 

GRANT EXECUTE ON DBMS_LOGMNR TO c##cdcuser CONTAINER=ALL; 
GRANT EXECUTE ON DBMS_LOGMNR_D TO c##cdcuser CONTAINER=ALL; 

GRANT SELECT ON V_$LOG TO c##cdcuser CONTAINER=ALL; 
GRANT SELECT ON V_$LOG_HISTORY TO c##cdcuser CONTAINER=ALL; 
GRANT SELECT ON V_$LOGMNR_LOGS TO c##cdcuser CONTAINER=ALL; 
GRANT SELECT ON V_$LOGMNR_CONTENTS TO c##cdcuser CONTAINER=ALL; 
GRANT SELECT ON V_$LOGMNR_PARAMETERS TO c##cdcuser CONTAINER=ALL; 
GRANT SELECT ON V_$LOGFILE TO c##cdcuser CONTAINER=ALL; 
GRANT SELECT ON V_$ARCHIVED_LOG TO c##cdcuser CONTAINER=ALL; 
GRANT SELECT ON V_$ARCHIVE_DEST_STATUS TO c##cdcuser CONTAINER=ALL; 
GRANT SELECT ON V_$TRANSACTION TO c##cdcuser CONTAINER=ALL; 

GRANT SELECT ON V_$MYSTAT TO c##cdcuser CONTAINER=ALL; 
GRANT SELECT ON V_$STATNAME TO c##cdcuser CONTAINER=ALL; 

-- ============================================
-- STEP 2: Switch to PDB and Create Data User
-- ============================================
ALTER SESSION SET CONTAINER = XEPDB1;

-- Create local user for owning tables and data
CREATE USER datauser IDENTIFIED BY DataPassword123;

-- Grant basic privileges to datauser
GRANT CREATE SESSION TO datauser;
GRANT CREATE TABLE TO datauser;
GRANT CREATE SEQUENCE TO datauser;
GRANT CREATE TRIGGER TO datauser;
GRANT UNLIMITED TABLESPACE TO datauser;

-- Grant c##cdcuser SELECT access to datauser's objects
-- (Will grant specific table access after tables are created)

-- ============================================
-- STEP 3: Create Sample Tables as datauser
-- ============================================

-- Sample Table 1: CUSTOMERS
CREATE TABLE datauser.CUSTOMERS (
    customer_id NUMBER(10) PRIMARY KEY,
    first_name VARCHAR2(50) NOT NULL,
    last_name VARCHAR2(50) NOT NULL,
    email VARCHAR2(100) UNIQUE NOT NULL,
    phone VARCHAR2(20),
    address VARCHAR2(200),
    city VARCHAR2(50),
    country VARCHAR2(50),
    registration_date DATE DEFAULT SYSDATE,
    status VARCHAR2(20) DEFAULT 'ACTIVE',
    credit_limit NUMBER(12,2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create sequence for customer_id
CREATE SEQUENCE datauser.customers_seq 
START WITH 1 
INCREMENT BY 1 
CACHE 20 
NOCYCLE;

-- Sample Table 2: ORDERS
CREATE TABLE datauser.ORDERS (
    order_id NUMBER(10) PRIMARY KEY,
    customer_id NUMBER(10) NOT NULL,
    order_number VARCHAR2(50) UNIQUE NOT NULL,
    order_date DATE DEFAULT SYSDATE,
    total_amount NUMBER(12,2) NOT NULL,
    tax_amount NUMBER(12,2) DEFAULT 0,
    discount_amount NUMBER(12,2) DEFAULT 0,
    currency VARCHAR2(3) DEFAULT 'USD',
    payment_method VARCHAR2(50),
    order_status VARCHAR2(20) DEFAULT 'PENDING',
    shipping_address VARCHAR2(200),
    notes CLOB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_customer 
        FOREIGN KEY (customer_id) 
        REFERENCES datauser.CUSTOMERS(customer_id)
);

-- Create sequence for order_id
CREATE SEQUENCE datauser.orders_seq 
START WITH 1000 
INCREMENT BY 1 
CACHE 20 
NOCYCLE;

-- ============================================
-- STEP 4: Grant CDC User Access to Tables
-- ============================================
-- Grant c##cdcuser SELECT privileges on datauser's tables
GRANT SELECT ON datauser.CUSTOMERS TO c##cdcuser;
GRANT SELECT ON datauser.ORDERS TO c##cdcuser;

-- ============================================
-- STEP 5: Create Indexes
-- ============================================
CREATE INDEX idx_customers_status ON datauser.CUSTOMERS(status);
CREATE INDEX idx_customers_created ON datauser.CUSTOMERS(created_at);

CREATE INDEX idx_orders_customer ON datauser.ORDERS(customer_id);
CREATE INDEX idx_orders_status ON datauser.ORDERS(order_status);
CREATE INDEX idx_orders_date ON datauser.ORDERS(order_date);
CREATE INDEX idx_orders_created ON datauser.ORDERS(created_at);

-- ============================================
-- STEP 6: Enable Supplemental Logging on Tables
-- ============================================
-- Enable supplemental logging to capture all column changes
ALTER TABLE datauser.CUSTOMERS 
ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;

ALTER TABLE datauser.ORDERS 
ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;

-- ============================================
-- STEP 7: Create Triggers for updated_at
-- ============================================
CREATE OR REPLACE TRIGGER datauser.trg_customers_update
BEFORE UPDATE ON datauser.CUSTOMERS
FOR EACH ROW
BEGIN
    :NEW.updated_at := CURRENT_TIMESTAMP;
END;
/

CREATE OR REPLACE TRIGGER datauser.trg_orders_update
BEFORE UPDATE ON datauser.ORDERS
FOR EACH ROW
BEGIN
    :NEW.updated_at := CURRENT_TIMESTAMP;
END;
/

-- ============================================
-- STEP 8: Insert Sample Data
-- ============================================
-- Insert sample customers
INSERT INTO datauser.CUSTOMERS (
    customer_id, first_name, last_name, email, phone, 
    address, city, country, status, credit_limit
) VALUES (
    datauser.customers_seq.NEXTVAL,
    'John', 'Doe', 'john.doe@example.com', '+1-555-0101',
    '123 Main St', 'New York', 'USA', 'ACTIVE', 5000.00
);

INSERT INTO datauser.CUSTOMERS (
    customer_id, first_name, last_name, email, phone, 
    address, city, country, status, credit_limit
) VALUES (
    datauser.customers_seq.NEXTVAL,
    'Jane', 'Smith', 'jane.smith@example.com', '+1-555-0102',
    '456 Oak Ave', 'Los Angeles', 'USA', 'ACTIVE', 10000.00
);

INSERT INTO datauser.CUSTOMERS (
    customer_id, first_name, last_name, email, phone, 
    address, city, country, status, credit_limit
) VALUES (
    datauser.customers_seq.NEXTVAL,
    'Bob', 'Johnson', 'bob.johnson@example.com', '+1-555-0103',
    '789 Pine Rd', 'Chicago', 'USA', 'ACTIVE', 7500.00
);

-- Insert sample orders
INSERT INTO datauser.ORDERS (
    order_id, customer_id, order_number, total_amount, tax_amount,
    currency, payment_method, order_status, shipping_address
) VALUES (
    datauser.orders_seq.NEXTVAL,
    1, 'ORD-2025-001', 150.00, 12.00,
    'USD', 'CREDIT_CARD', 'PENDING', '123 Main St, New York, USA'
);

INSERT INTO datauser.ORDERS (
    order_id, customer_id, order_number, total_amount, tax_amount,
    currency, payment_method, order_status, shipping_address
) VALUES (
    datauser.orders_seq.NEXTVAL,
    2, 'ORD-2025-002', 275.50, 22.04,
    'USD', 'PAYPAL', 'PROCESSING', '456 Oak Ave, Los Angeles, USA'
);

COMMIT;

-- ============================================
-- Setup Complete
-- ============================================
SELECT 'Oracle CDC User Setup Complete!' as status FROM dual;
SELECT 'CDC User: c##cdcuser' as info FROM dual;
SELECT 'Data User: datauser' as info FROM dual;