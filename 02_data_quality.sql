-- 02_data_quality.sql
USE amazon_sales_portfolio;

-- Run these checks after importing the CSV.

SELECT COUNT(*) AS row_count,
       COUNT(DISTINCT order_id) AS unique_orders,
       COUNT(DISTINCT sku) AS unique_skus
FROM amazon_sales;

SELECT MIN(order_date) first_order_date,
       MAX(order_date) last_order_date
FROM amazon_sales;

SELECT
    SUM(order_id IS NULL OR TRIM(order_id) = '') AS missing_order_id,
    SUM(sku IS NULL OR TRIM(sku) = '') AS missing_sku,
    SUM(amount IS NULL) AS missing_amount,
    SUM(order_date IS NULL) AS missing_date
FROM amazon_sales;

SELECT status, COUNT(*) row_count
FROM amazon_sales
GROUP BY status
ORDER BY row_count DESC;

SELECT category, COUNT(*) row_count
FROM amazon_sales
GROUP BY category
ORDER BY row_count DESC;

-- Check duplicate row identifiers
SELECT row_id, COUNT(*) AS duplicate_count
FROM amazon_sales
GROUP BY row_id
HAVING COUNT(*) > 1;

-- Check invalid quantities / amounts
SELECT COUNT(*) AS invalid_qty_rows
FROM amazon_sales
WHERE qty < 0;

SELECT COUNT(*) AS negative_amount_rows
FROM amazon_sales
WHERE amount < 0;
