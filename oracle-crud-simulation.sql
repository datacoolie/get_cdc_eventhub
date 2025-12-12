-- ============================================
-- Oracle CRUD Simulation Script
-- ============================================
-- This script simulates CRUD operations on CUSTOMERS and ORDERS tables
-- Run this script to generate CDC events for testing
-- ============================================

-- Set session to PDB
ALTER SESSION SET CONTAINER = XEPDB1;

-- ============================================
-- INSERT Operations (CREATE)
-- ============================================

PROMPT '=== Starting INSERT Operations ==='

-- Insert Customers
INSERT INTO datauser.CUSTOMERS (
    customer_id, first_name, last_name, email, phone, address, city, country, status, credit_limit
) VALUES (
    datauser.customers_seq.NEXTVAL, 
    'John', 
    'Doe', 
    'john.doe@email.com', 
    '+1-555-0101', 
    '123 Main St', 
    'New York', 
    'USA', 
    'ACTIVE', 
    5000.00
);

INSERT INTO datauser.CUSTOMERS (
    customer_id, first_name, last_name, email, phone, address, city, country, status, credit_limit
) VALUES (
    datauser.customers_seq.NEXTVAL, 
    'Jane', 
    'Smith', 
    'jane.smith@email.com', 
    '+1-555-0102', 
    '456 Oak Ave', 
    'Los Angeles', 
    'USA', 
    'ACTIVE', 
    7500.00
);

INSERT INTO datauser.CUSTOMERS (
    customer_id, first_name, last_name, email, phone, address, city, country, status, credit_limit
) VALUES (
    datauser.customers_seq.NEXTVAL, 
    'Robert', 
    'Johnson', 
    'robert.johnson@email.com', 
    '+1-555-0103', 
    '789 Pine Rd', 
    'Chicago', 
    'USA', 
    'ACTIVE', 
    10000.00
);

INSERT INTO datauser.CUSTOMERS (
    customer_id, first_name, last_name, email, phone, address, city, country, status, credit_limit
) VALUES (
    datauser.customers_seq.NEXTVAL, 
    'Maria', 
    'Garcia', 
    'maria.garcia@email.com', 
    '+1-555-0104', 
    '321 Elm St', 
    'Miami', 
    'USA', 
    'ACTIVE', 
    6000.00
);

INSERT INTO datauser.CUSTOMERS (
    customer_id, first_name, last_name, email, phone, address, city, country, status, credit_limit
) VALUES (
    datauser.customers_seq.NEXTVAL, 
    'Michael', 
    'Brown', 
    'michael.brown@email.com', 
    '+1-555-0105', 
    '654 Maple Dr', 
    'Seattle', 
    'USA', 
    'ACTIVE', 
    8500.00
);

COMMIT;

PROMPT '=== Customers inserted ==='

-- Wait a moment for demonstration purposes
EXEC DBMS_LOCK.SLEEP(2);

-- Insert Orders
INSERT INTO datauser.ORDERS (
    order_id, customer_id, order_number, total_amount, tax_amount, discount_amount, 
    payment_method, order_status, shipping_address
) VALUES (
    datauser.orders_seq.NEXTVAL, 
    1, 
    'ORD-2025-001', 
    1250.00, 
    125.00, 
    50.00, 
    'CREDIT_CARD', 
    'PENDING', 
    '123 Main St, New York, USA'
);

INSERT INTO datauser.ORDERS (
    order_id, customer_id, order_number, total_amount, tax_amount, discount_amount, 
    payment_method, order_status, shipping_address
) VALUES (
    datauser.orders_seq.NEXTVAL, 
    2, 
    'ORD-2025-002', 
    875.50, 
    87.55, 
    0.00, 
    'PAYPAL', 
    'PENDING', 
    '456 Oak Ave, Los Angeles, USA'
);

INSERT INTO datauser.ORDERS (
    order_id, customer_id, order_number, total_amount, tax_amount, discount_amount, 
    payment_method, order_status, shipping_address
) VALUES (
    datauser.orders_seq.NEXTVAL, 
    3, 
    'ORD-2025-003', 
    2100.00, 
    210.00, 
    100.00, 
    'CREDIT_CARD', 
    'PENDING', 
    '789 Pine Rd, Chicago, USA'
);

COMMIT;

PROMPT '=== Orders inserted ==='

-- ============================================
-- SELECT Operations (READ)
-- ============================================

PROMPT '=== Performing SELECT Operations ==='

SELECT 'Total Customers:' AS info, COUNT(*) AS count FROM datauser.CUSTOMERS;
SELECT 'Total Orders:' AS info, COUNT(*) AS count FROM datauser.ORDERS;

SELECT 
    customer_id, 
    first_name, 
    last_name, 
    email, 
    status, 
    credit_limit 
FROM datauser.CUSTOMERS 
ORDER BY customer_id;

SELECT 
    order_id, 
    customer_id, 
    order_number, 
    total_amount, 
    order_status 
FROM datauser.ORDERS 
ORDER BY order_id;

-- ============================================
-- UPDATE Operations
-- ============================================

PROMPT '=== Starting UPDATE Operations ==='

-- Wait a moment
EXEC DBMS_LOCK.SLEEP(2);

-- Update customer status
UPDATE datauser.CUSTOMERS 
SET status = 'VIP', 
    credit_limit = credit_limit + 2500.00
WHERE email = 'john.doe@email.com';

-- Update customer information
UPDATE datauser.CUSTOMERS 
SET phone = '+1-555-9999', 
    address = '999 Updated St',
    city = 'Boston'
WHERE email = 'jane.smith@email.com';

-- Update multiple customers credit limit
UPDATE datauser.CUSTOMERS 
SET credit_limit = credit_limit * 1.1
WHERE status = 'ACTIVE' 
AND credit_limit >= 8000;

COMMIT;

PROMPT '=== Customers updated ==='

-- Wait a moment
EXEC DBMS_LOCK.SLEEP(2);

-- Update order status
UPDATE datauser.ORDERS 
SET order_status = 'PROCESSING'
WHERE order_number = 'ORD-2025-001';

UPDATE datauser.ORDERS 
SET order_status = 'SHIPPED',
    notes = 'Package shipped via express delivery'
WHERE order_number = 'ORD-2025-002';

UPDATE datauser.ORDERS 
SET order_status = 'COMPLETED',
    notes = 'Order delivered successfully'
WHERE order_number = 'ORD-2025-003';

-- Update order amounts
UPDATE datauser.ORDERS 
SET total_amount = total_amount + 50.00,
    tax_amount = (total_amount + 50.00) * 0.1
WHERE order_status = 'PENDING';

COMMIT;

PROMPT '=== Orders updated ==='

-- ============================================
-- Additional INSERT Operations
-- ============================================

PROMPT '=== Inserting more data ==='

EXEC DBMS_LOCK.SLEEP(2);

-- Insert more customers
INSERT INTO datauser.CUSTOMERS (
    customer_id, first_name, last_name, email, phone, address, city, country, status, credit_limit
) VALUES (
    datauser.customers_seq.NEXTVAL, 
    'Sarah', 
    'Williams', 
    'sarah.williams@email.com', 
    '+1-555-0106', 
    '111 Cedar Ln', 
    'Houston', 
    'USA', 
    'ACTIVE', 
    4500.00
);

-- Insert more orders
INSERT INTO datauser.ORDERS (
    order_id, customer_id, order_number, total_amount, tax_amount, discount_amount, 
    payment_method, order_status, shipping_address
) VALUES (
    datauser.orders_seq.NEXTVAL, 
    1, 
    'ORD-2025-004', 
    550.00, 
    55.00, 
    0.00, 
    'CREDIT_CARD', 
    'PENDING', 
    '123 Main St, New York, USA'
);

INSERT INTO datauser.ORDERS (
    order_id, customer_id, order_number, total_amount, tax_amount, discount_amount, 
    payment_method, order_status, shipping_address
) VALUES (
    datauser.orders_seq.NEXTVAL, 
    4, 
    'ORD-2025-005', 
    1800.00, 
    180.00, 
    150.00, 
    'BANK_TRANSFER', 
    'PENDING', 
    '321 Elm St, Miami, USA'
);

COMMIT;

PROMPT '=== Additional data inserted ==='

-- ============================================
-- DELETE Operations
-- ============================================

PROMPT '=== Starting DELETE Operations ==='

EXEC DBMS_LOCK.SLEEP(2);

-- Delete specific order (must delete orders before customers due to FK)
DELETE FROM datauser.ORDERS 
WHERE order_number = 'ORD-2025-005';

COMMIT;

PROMPT '=== Order deleted ==='

EXEC DBMS_LOCK.SLEEP(2);

-- Delete customer with no orders
DELETE FROM datauser.CUSTOMERS 
WHERE email = 'sarah.williams@email.com';

COMMIT;

PROMPT '=== Customer deleted ==='

-- ============================================
-- Final Status Check
-- ============================================

PROMPT '=== Final Status Check ==='

SELECT 
    'CUSTOMERS' AS table_name,
    COUNT(*) AS total_records,
    COUNT(CASE WHEN status = 'ACTIVE' THEN 1 END) AS active_records,
    COUNT(CASE WHEN status = 'VIP' THEN 1 END) AS vip_records
FROM datauser.CUSTOMERS;

SELECT 
    'ORDERS' AS table_name,
    COUNT(*) AS total_records,
    COUNT(CASE WHEN order_status = 'PENDING' THEN 1 END) AS pending_orders,
    COUNT(CASE WHEN order_status = 'PROCESSING' THEN 1 END) AS processing_orders,
    COUNT(CASE WHEN order_status = 'SHIPPED' THEN 1 END) AS shipped_orders,
    COUNT(CASE WHEN order_status = 'COMPLETED' THEN 1 END) AS completed_orders
FROM datauser.ORDERS;

-- Display final data
SELECT 'Final CUSTOMERS data:' AS info FROM dual;
SELECT customer_id, first_name, last_name, email, status, credit_limit 
FROM datauser.CUSTOMERS 
ORDER BY customer_id;

SELECT 'Final ORDERS data:' AS info FROM dual;
SELECT order_id, customer_id, order_number, total_amount, order_status 
FROM datauser.ORDERS 
ORDER BY order_id;

PROMPT '=== CRUD Simulation Complete ==='
