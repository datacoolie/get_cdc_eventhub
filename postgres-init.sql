-- ============================================
-- PostgreSQL CDC Setup and Sample Tables
-- ============================================
-- Script for PostgreSQL to setup CDC tables
-- ============================================

-- ============================================
-- PART 1: DATA USER SETUP
-- ============================================

-- Create datauser for application data operations
-- CREATE USER datauser WITH PASSWORD 'DataPassword123';

-- Create Schema (owned by datauser)
CREATE SCHEMA IF NOT EXISTS datauser AUTHORIZATION datauser;

-- Set search path
SET search_path TO datauser, public;

-- Switch to datauser for creating tables and data
SET ROLE datauser;

-- Create Sample Tables
-- Sample Table 1: PRODUCTS
CREATE TABLE datauser.products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    category VARCHAR(50),
    description TEXT,
    price NUMERIC(10,2) NOT NULL,
    stock_quantity INTEGER DEFAULT 0,
    supplier_name VARCHAR(100),
    status VARCHAR(20) DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Sample Table 2: INVENTORY_TRANSACTIONS
CREATE TABLE datauser.inventory_transactions (
    transaction_id SERIAL PRIMARY KEY,
    product_id INTEGER NOT NULL,
    transaction_type VARCHAR(20) NOT NULL, -- 'IN', 'OUT', 'ADJUSTMENT'
    quantity INTEGER NOT NULL,
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reference_number VARCHAR(50),
    notes TEXT,
    performed_by VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_product 
        FOREIGN KEY (product_id) 
        REFERENCES datauser.products(product_id)
);

-- Create Indexes
CREATE INDEX idx_products_category ON datauser.products(category);
CREATE INDEX idx_products_status ON datauser.products(status);
CREATE INDEX idx_products_created ON datauser.products(created_at);

CREATE INDEX idx_transactions_product ON datauser.inventory_transactions(product_id);
CREATE INDEX idx_transactions_type ON datauser.inventory_transactions(transaction_type);
CREATE INDEX idx_transactions_date ON datauser.inventory_transactions(transaction_date);

-- Create Trigger for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_products_update
BEFORE UPDATE ON datauser.products
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Insert Sample Data
INSERT INTO datauser.products (
    product_name, category, description, price, stock_quantity, supplier_name, status
) VALUES 
    ('Laptop Pro 15', 'Electronics', 'High-performance laptop with 15-inch display', 1299.99, 50, 'TechSupply Inc', 'ACTIVE'),
    ('Wireless Mouse', 'Electronics', 'Ergonomic wireless mouse', 29.99, 200, 'Peripherals Ltd', 'ACTIVE'),
    ('Office Chair', 'Furniture', 'Ergonomic office chair with lumbar support', 299.99, 30, 'Furniture Plus', 'ACTIVE'),
    ('USB-C Cable', 'Electronics', '6ft USB-C charging cable', 19.99, 150, 'Cable World', 'ACTIVE'),
    ('Standing Desk', 'Furniture', 'Adjustable height standing desk', 599.99, 15, 'Furniture Plus', 'ACTIVE');

INSERT INTO datauser.inventory_transactions (
    product_id, transaction_type, quantity, reference_number, notes, performed_by
) VALUES 
    (1, 'IN', 50, 'PO-2025-001', 'Initial stock', 'admin'),
    (2, 'IN', 200, 'PO-2025-002', 'Initial stock', 'admin'),
    (3, 'IN', 30, 'PO-2025-003', 'Initial stock', 'admin'),
    (1, 'OUT', 5, 'SO-2025-001', 'Customer order', 'sales_team'),
    (2, 'OUT', 10, 'SO-2025-002', 'Customer order', 'sales_team');

-- ============================================
-- PART 2: CDC AND REPLICATION SETUP
-- ============================================

-- Switch back to superuser for CDC setup
RESET ROLE;

-- Create CDC user with replication privileges
CREATE USER cdcuser WITH REPLICATION LOGIN PASSWORD 'CdcPassword123';

-- Grant minimal read-only permissions to cdcuser for CDC/replication
GRANT USAGE ON SCHEMA datauser TO cdcuser;
GRANT SELECT ON ALL TABLES IN SCHEMA datauser TO cdcuser;
-- GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA datauser TO cdcuser;

-- Set default privileges for future tables (read-only for CDC)
ALTER DEFAULT PRIVILEGES IN SCHEMA datauser GRANT SELECT ON TABLES TO cdcuser;
-- ALTER DEFAULT PRIVILEGES IN SCHEMA datauser GRANT USAGE, SELECT ON SEQUENCES TO cdcuser;


-- Setup Replication Identity
-- Set REPLICA IDENTITY to FULL for better CDC tracking
-- This ensures all column values are included in WAL
-- ALTER TABLE datauser.products REPLICA IDENTITY FULL;
-- ALTER TABLE datauser.inventory_transactions REPLICA IDENTITY FULL;

-- Alternative: Use DEFAULT (primary key only)
ALTER TABLE datauser.products REPLICA IDENTITY DEFAULT;
ALTER TABLE datauser.inventory_transactions REPLICA IDENTITY DEFAULT;

-- Create Publication for Logical Replication
CREATE PUBLICATION dbz_publication FOR TABLE 
    datauser.products,
    datauser.inventory_transactions
;
-- WITH (publish = 'insert,update,delete');

-- ============================================
-- Setup Complete
-- ============================================
SELECT 'PostgreSQL CDC Setup Complete!' as status;
