-- ============================================
-- PostgreSQL CRUD Simulation Script
-- ============================================
-- This script simulates CRUD operations on PRODUCTS and INVENTORY_TRANSACTIONS tables
-- Run this script to generate CDC events for testing
-- ============================================

-- Set search path
SET search_path TO datauser, public;

-- ============================================
-- INSERT Operations (CREATE)
-- ============================================

\echo '=== Starting INSERT Operations ==='

-- Insert Products
INSERT INTO datauser.products (
    product_name, category, description, price, stock_quantity, supplier_name, status
) VALUES 
    ('Mechanical Keyboard', 'Electronics', 'RGB mechanical gaming keyboard', 129.99, 75, 'TechSupply Inc', 'ACTIVE'),
    ('Monitor 27"', 'Electronics', '27-inch 4K monitor with HDR', 449.99, 40, 'Display World', 'ACTIVE'),
    ('Desk Lamp', 'Furniture', 'LED desk lamp with adjustable brightness', 59.99, 100, 'Lighting Co', 'ACTIVE'),
    ('Webcam HD', 'Electronics', '1080p HD webcam with microphone', 79.99, 60, 'TechSupply Inc', 'ACTIVE'),
    ('Desk Organizer', 'Office Supplies', 'Multi-compartment desk organizer', 24.99, 120, 'Office Depot', 'ACTIVE');

\echo '=== Products inserted ==='

-- Wait a moment for demonstration purposes
SELECT pg_sleep(2);

-- Insert Inventory Transactions for new products
INSERT INTO datauser.inventory_transactions (
    product_id, transaction_type, quantity, reference_number, notes, performed_by
) VALUES 
    (6, 'IN', 75, 'PO-2025-010', 'New product initial stock', 'warehouse_manager'),
    (7, 'IN', 40, 'PO-2025-011', 'New product initial stock', 'warehouse_manager'),
    (8, 'IN', 100, 'PO-2025-012', 'New product initial stock', 'warehouse_manager'),
    (6, 'OUT', 5, 'SO-2025-010', 'Customer bulk order', 'sales_team'),
    (7, 'OUT', 2, 'SO-2025-011', 'Customer order', 'sales_team');

\echo '=== Inventory transactions inserted ==='

-- ============================================
-- SELECT Operations (READ)
-- ============================================

\echo '=== Performing SELECT Operations ==='

SELECT 'Total Products:' AS info, COUNT(*) AS count FROM datauser.products;
SELECT 'Total Transactions:' AS info, COUNT(*) AS count FROM datauser.inventory_transactions;

SELECT 
    product_id, 
    product_name, 
    category, 
    price, 
    stock_quantity,
    status
FROM datauser.products 
ORDER BY product_id;

SELECT 
    transaction_id, 
    product_id, 
    transaction_type, 
    quantity, 
    reference_number,
    performed_by
FROM datauser.inventory_transactions 
ORDER BY transaction_id;

-- ============================================
-- UPDATE Operations
-- ============================================

\echo '=== Starting UPDATE Operations ==='

-- Wait a moment
SELECT pg_sleep(2);

-- Update product prices
UPDATE datauser.products 
SET price = price * 1.1
WHERE category = 'Electronics';

-- Update product stock
UPDATE datauser.products 
SET stock_quantity = stock_quantity - 10
WHERE product_name = 'Wireless Mouse';

-- Update product status
UPDATE datauser.products 
SET status = 'LOW_STOCK'
WHERE stock_quantity < 30;

-- Update product information
UPDATE datauser.products 
SET description = 'Premium ergonomic office chair with advanced lumbar support',
    price = 349.99
WHERE product_name = 'Office Chair';

\echo '=== Products updated ==='

-- Wait a moment
SELECT pg_sleep(2);

-- Update transaction notes
UPDATE datauser.inventory_transactions 
SET notes = 'Stock adjustment after inventory audit'
WHERE transaction_type = 'ADJUSTMENT' 
AND transaction_id > 0;

-- ============================================
-- Additional INSERT Operations
-- ============================================

\echo '=== Inserting more data ==='

SELECT pg_sleep(2);

-- Insert more products
INSERT INTO datauser.products (
    product_name, category, description, price, stock_quantity, supplier_name, status
) VALUES 
    ('Noise Cancelling Headphones', 'Electronics', 'Premium wireless headphones with ANC', 299.99, 35, 'Audio Tech', 'ACTIVE'),
    ('Ergonomic Footrest', 'Furniture', 'Adjustable ergonomic footrest', 45.99, 50, 'Furniture Plus', 'ACTIVE'),
    ('Cable Management Kit', 'Office Supplies', 'Complete cable organization solution', 19.99, 200, 'Office Depot', 'ACTIVE');

-- Insert more inventory transactions
INSERT INTO datauser.inventory_transactions (
    product_id, transaction_type, quantity, reference_number, notes, performed_by
) VALUES 
    (11, 'IN', 35, 'PO-2025-020', 'Initial stock for new product', 'warehouse_manager'),
    (12, 'IN', 50, 'PO-2025-021', 'Initial stock for new product', 'warehouse_manager'),
    (1, 'OUT', 3, 'SO-2025-020', 'Corporate order', 'sales_team'),
    (6, 'OUT', 8, 'SO-2025-021', 'Bulk order', 'sales_team'),
    (7, 'ADJUSTMENT', -2, 'ADJ-2025-001', 'Damaged items removed from inventory', 'warehouse_manager');

\echo '=== Additional data inserted ==='

-- ============================================
-- More UPDATE Operations
-- ============================================

\echo '=== Performing additional UPDATE operations ==='

SELECT pg_sleep(2);

-- Bulk update prices for promotions
UPDATE datauser.products 
SET price = price * 0.9
WHERE category = 'Office Supplies';

-- Update stock after sales
UPDATE datauser.products 
SET stock_quantity = stock_quantity + 50
WHERE product_id IN (1, 2, 3);

-- Update supplier for multiple products
UPDATE datauser.products 
SET supplier_name = 'Global Tech Supply'
WHERE supplier_name = 'TechSupply Inc';

-- Change product status
UPDATE datauser.products 
SET status = 'DISCONTINUED'
WHERE product_name = 'USB-C Cable';

\echo '=== Additional updates complete ==='

-- ============================================
-- DELETE Operations
-- ============================================

\echo '=== Starting DELETE Operations ==='

SELECT pg_sleep(2);

-- Delete specific transaction
DELETE FROM datauser.inventory_transactions 
WHERE reference_number = 'ADJ-2025-001';

\echo '=== Transaction deleted ==='

SELECT pg_sleep(2);

-- Delete product (must delete related transactions first in real scenario)
-- For demo, we'll delete a product without transactions
DELETE FROM datauser.products 
WHERE product_name = 'Cable Management Kit';

\echo '=== Product deleted ==='

-- ============================================
-- Batch Operations
-- ============================================

\echo '=== Performing batch operations ==='

SELECT pg_sleep(2);

-- Batch insert transactions
INSERT INTO datauser.inventory_transactions (
    product_id, transaction_type, quantity, reference_number, notes, performed_by
)
SELECT 
    product_id,
    'ADJUSTMENT' AS transaction_type,
    5 AS quantity,
    'BATCH-ADJ-' || product_id AS reference_number,
    'Quarterly inventory adjustment' AS notes,
    'inventory_admin' AS performed_by
FROM datauser.products
WHERE status = 'ACTIVE'
AND category = 'Electronics'
LIMIT 3;

\echo '=== Batch operations complete ==='

-- ============================================
-- Complex UPDATE with Subquery
-- ============================================

\echo '=== Performing complex UPDATE operations ==='

SELECT pg_sleep(2);

-- Update stock based on transaction totals
UPDATE datauser.products p
SET stock_quantity = stock_quantity + COALESCE((
    SELECT SUM(CASE 
        WHEN it.transaction_type = 'IN' THEN it.quantity 
        WHEN it.transaction_type = 'OUT' THEN -it.quantity
        WHEN it.transaction_type = 'ADJUSTMENT' THEN it.quantity
        ELSE 0 
    END)
    FROM datauser.inventory_transactions it
    WHERE it.product_id = p.product_id
    AND it.transaction_id > 100
), 0) * 0
WHERE p.product_id IN (1, 2, 3);

\echo '=== Complex updates complete ==='

-- ============================================
-- Final Status Check
-- ============================================

\echo '=== Final Status Check ==='

SELECT 
    'PRODUCTS' AS table_name,
    COUNT(*) AS total_records,
    COUNT(CASE WHEN status = 'ACTIVE' THEN 1 END) AS active_records,
    COUNT(CASE WHEN status = 'LOW_STOCK' THEN 1 END) AS low_stock_records,
    COUNT(CASE WHEN status = 'DISCONTINUED' THEN 1 END) AS discontinued_records
FROM datauser.products;

SELECT 
    'INVENTORY_TRANSACTIONS' AS table_name,
    COUNT(*) AS total_records,
    COUNT(CASE WHEN transaction_type = 'IN' THEN 1 END) AS in_transactions,
    COUNT(CASE WHEN transaction_type = 'OUT' THEN 1 END) AS out_transactions,
    COUNT(CASE WHEN transaction_type = 'ADJUSTMENT' THEN 1 END) AS adjustment_transactions
FROM datauser.inventory_transactions;

-- Display final data
\echo 'Final PRODUCTS data:'
SELECT product_id, product_name, category, price, stock_quantity, status 
FROM datauser.products 
ORDER BY product_id;

\echo 'Final INVENTORY_TRANSACTIONS summary:'
SELECT 
    p.product_name,
    COUNT(it.transaction_id) AS transaction_count,
    SUM(CASE WHEN it.transaction_type = 'IN' THEN it.quantity ELSE 0 END) AS total_in,
    SUM(CASE WHEN it.transaction_type = 'OUT' THEN it.quantity ELSE 0 END) AS total_out
FROM datauser.products p
LEFT JOIN datauser.inventory_transactions it ON p.product_id = it.product_id
GROUP BY p.product_id, p.product_name
ORDER BY p.product_id;

\echo '=== CRUD Simulation Complete ==='
