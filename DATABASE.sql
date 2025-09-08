CREATE DATABASE IF NOT EXISTS productco_analytics;
USE productco_analytics;

-- ProductCo SQL Ad Hoc Analytics Database Schema --
-- Supplier Table --
CREATE TABLE dim_supplier (
    supplier_id INT AUTO_INCREMENT PRIMARY KEY,
    supplier_name VARCHAR(255) NOT NULL,
    supplier_country VARCHAR(100),
    supplier_email VARCHAR(255),
    supplier_phone VARCHAR(50),
    rating DECIMAL(3,2) DEFAULT 5.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 1. Product Dimension Table
CREATE TABLE dim_product (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(255) NOT NULL,
    product_category VARCHAR(100) NOT NULL,
    product_subcategory VARCHAR(100),
    brand VARCHAR(100) NOT NULL,
    supplier_id INT,
    unit_cost DECIMAL(10,2),
    launch_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (supplier_id) REFERENCES dim_supplier(supplier_id),
    INDEX idx_category (product_category),
    INDEX idx_brand (brand),
    INDEX idx_active (is_active)
);

-- 2. Customer Dimension Table  
CREATE TABLE dim_customer (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_name VARCHAR(255) NOT NULL,
    customer_type ENUM('B2B', 'B2C') NOT NULL,
    industry VARCHAR(100),
    company_size ENUM('Small', 'Medium', 'Large', 'Enterprise'),
    country VARCHAR(100) NOT NULL,
    region VARCHAR(100) NOT NULL,
    city VARCHAR(100) NOT NULL,
    acquisition_date DATE,
    customer_tier ENUM('Bronze', 'Silver', 'Gold', 'Platinum') DEFAULT 'Bronze',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_type (customer_type),
    INDEX idx_country (country),
    INDEX idx_tier (customer_tier),
    INDEX idx_industry (industry)
);

-- 3. Store/Channel Dimension Table
CREATE TABLE dim_store (
    store_id INT AUTO_INCREMENT PRIMARY KEY,
    store_name VARCHAR(255) NOT NULL,
    store_type ENUM('Online', 'Retail', 'Partner', 'Direct') NOT NULL,
    region VARCHAR(100) NOT NULL,
    country VARCHAR(100) NOT NULL,
    city VARCHAR(100) NOT NULL,
    manager_name VARCHAR(255),
    opening_date DATE,
    store_size ENUM('Small', 'Medium', 'Large') DEFAULT 'Medium',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_type (store_type),
    INDEX idx_region (region),
    INDEX idx_country (country)
);

-- 4. Date Dimension Table
CREATE TABLE dim_date (
    date_id INT AUTO_INCREMENT PRIMARY KEY,
    full_date DATE UNIQUE NOT NULL,
    day_of_week INT NOT NULL,
    day_name VARCHAR(10) NOT NULL,
    day_of_month INT NOT NULL,
    day_of_year INT NOT NULL,
    week_of_year INT NOT NULL,
    month INT NOT NULL,
    month_name VARCHAR(15) NOT NULL,
    quarter INT NOT NULL,
    year INT NOT NULL,
    is_weekend BOOLEAN DEFAULT FALSE,
    is_holiday BOOLEAN DEFAULT FALSE,
    fiscal_year INT,
    fiscal_quarter INT,
    INDEX idx_date (full_date),
    INDEX idx_year_month (year, month),
    INDEX idx_quarter (quarter),
    INDEX idx_weekend (is_weekend)
);

-- 5. Sales Representative Dimension Table
CREATE TABLE dim_sales_rep (
    sales_rep_id INT AUTO_INCREMENT PRIMARY KEY,
    rep_name VARCHAR(255) NOT NULL,
    rep_email VARCHAR(255) UNIQUE NOT NULL,
    hire_date DATE NOT NULL,
    territory VARCHAR(100) NOT NULL,
    manager_id INT,
    commission_rate DECIMAL(4,2) DEFAULT 0.05,
    performance_tier ENUM('Trainee', 'Junior', 'Senior', 'Expert', 'Master') DEFAULT 'Junior',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (manager_id) REFERENCES dim_sales_rep(sales_rep_id),
    INDEX idx_territory (territory),
    INDEX idx_performance (performance_tier),
    INDEX idx_active (is_active)
);

-- 6. Central Fact Table for Sales Transactions
CREATE TABLE fact_sales (
    sale_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    customer_id INT NOT NULL,
    store_id INT NOT NULL,
    date_id INT NOT NULL,
    sales_rep_id INT NOT NULL,
    
    -- Measures/Metrics
    quantity_sold INT NOT NULL DEFAULT 1,
    unit_price DECIMAL(10,2) NOT NULL,
    discount_amount DECIMAL(10,2) DEFAULT 0.00,
    total_amount DECIMAL(12,2) NOT NULL,
    cost_of_goods DECIMAL(10,2) NOT NULL,
    profit_margin DECIMAL(12,2) GENERATED ALWAYS AS (total_amount - cost_of_goods) STORED,
    
    -- Metadata
    sale_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Foreign Key Constraints
    FOREIGN KEY (product_id) REFERENCES dim_product(product_id),
    FOREIGN KEY (customer_id) REFERENCES dim_customer(customer_id),
    FOREIGN KEY (store_id) REFERENCES dim_store(store_id),
    FOREIGN KEY (date_id) REFERENCES dim_date(date_id),
    FOREIGN KEY (sales_rep_id) REFERENCES dim_sales_rep(sales_rep_id),
    
    -- Indexes for Performance
    INDEX idx_product (product_id),
    INDEX idx_customer (customer_id),
    INDEX idx_store (store_id),
    INDEX idx_date (date_id),
    INDEX idx_sales_rep (sales_rep_id),
    INDEX idx_sale_timestamp (sale_timestamp),
    INDEX idx_total_amount (total_amount),
    INDEX idx_composite_date_product (date_id, product_id),
    INDEX idx_composite_customer_product (customer_id, product_id)
);

-- Create helpful view for common queries
CREATE VIEW v_sales_summary AS
SELECT 
    fs.sale_id,
    dp.product_name,
    dp.product_category,
    dc.customer_name,
    dc.customer_type,
    ds.store_name,
    ds.store_type,
    dd.full_date,
    dd.year,
    dd.month_name,
    dd.quarter,
    dsr.rep_name,
    fs.quantity_sold,
    fs.unit_price,
    fs.total_amount,
    fs.profit_margin
FROM fact_sales fs
JOIN dim_product dp ON fs.product_id = dp.product_id
JOIN dim_customer dc ON fs.customer_id = dc.customer_id
JOIN dim_store ds ON fs.store_id = ds.store_id
JOIN dim_date dd ON fs.date_id = dd.date_id
JOIN dim_sales_rep dsr ON fs.sales_rep_id = dsr.sales_rep_id;

SHOW TABLES;

DESCRIBE dim_product;
DESCRIBE dim_customer;
DESCRIBE fact_sales;


-- Check record counts
SELECT 'dim_supplier' as table_name, COUNT(*) as records FROM dim_supplier
UNION ALL
SELECT 'dim_date', COUNT(*) FROM dim_date
UNION ALL
SELECT 'dim_product', COUNT(*) FROM dim_product
UNION ALL
SELECT 'dim_customer', COUNT(*) FROM dim_customer
UNION ALL
SELECT 'dim_store', COUNT(*) FROM dim_store
UNION ALL
SELECT 'dim_sales_rep', COUNT(*) FROM dim_sales_rep
UNION ALL
SELECT 'fact_sales', COUNT(*) FROM fact_sales;
