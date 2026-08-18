-- 01_schema.sql
CREATE DATABASE IF NOT EXISTS amazon_sales_portfolio;
USE amazon_sales_portfolio;

DROP TABLE IF EXISTS amazon_sales;

CREATE TABLE amazon_sales (
    row_id INT,
    order_id VARCHAR(50),
    order_date DATE,
    status VARCHAR(100),
    fulfilment VARCHAR(30),
    sales_channel VARCHAR(100),
    ship_service_level VARCHAR(50),
    style VARCHAR(50),
    sku VARCHAR(80),
    category VARCHAR(100),
    size VARCHAR(20),
    asin VARCHAR(30),
    courier_status VARCHAR(50),
    qty INT,
    currency VARCHAR(10),
    amount DECIMAL(12,2),
    ship_city VARCHAR(100),
    ship_state VARCHAR(100),
    ship_postal_code VARCHAR(20),
    ship_country VARCHAR(10),
    promotion_ids TEXT,
    b2b BOOLEAN,
    fulfilled_by VARCHAR(50)
);
