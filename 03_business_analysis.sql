-- 03_business_analysis.sql
USE amazon_sales_portfolio;

-- ============================================================
-- AMAZON SALES SQL PORTFOLIO PROJECT
-- Core sales definition:
-- Successful orders = Shipped + Shipped - Delivered to Buyer
-- ============================================================

-- 01. Overall successful KPIs
SELECT
    ROUND(SUM(amount), 2) AS revenue,
    SUM(qty) AS units,
    COUNT(DISTINCT order_id) AS orders,
    ROUND(SUM(amount) / COUNT(DISTINCT order_id), 2) AS avg_order_value
FROM amazon_sales
WHERE status IN ('Shipped','Shipped - Delivered to Buyer');

-- 02. Overall order status distribution
SELECT status, COUNT(*) AS order_lines
FROM amazon_sales
GROUP BY status
ORDER BY order_lines DESC;

-- 03. Cancellation rate
SELECT
    ROUND(100.0 * SUM(status = 'Cancelled') / COUNT(*), 2) AS cancellation_rate_pct
FROM amazon_sales;

-- 04. Monthly performance
SELECT
    DATE_FORMAT(order_date, '%Y-%m') AS month,
    ROUND(SUM(amount),2) AS revenue,
    SUM(qty) AS units,
    COUNT(DISTINCT order_id) AS orders
FROM amazon_sales
WHERE status IN ('Shipped','Shipped - Delivered to Buyer')
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY month;

-- 05. Month-over-month growth
WITH monthly AS (
    SELECT DATE_FORMAT(order_date,'%Y-%m') AS month,
           SUM(amount) AS revenue
    FROM amazon_sales
    WHERE status IN ('Shipped','Shipped - Delivered to Buyer')
    GROUP BY DATE_FORMAT(order_date,'%Y-%m')
)
SELECT month,
       ROUND(revenue,2) AS revenue,
       ROUND(
           100 * (revenue - LAG(revenue) OVER (ORDER BY month))
           / NULLIF(LAG(revenue) OVER (ORDER BY month),0), 2
       ) AS mom_growth_pct
FROM monthly
ORDER BY month;

-- 06. Category performance
SELECT
    LOWER(category) AS category,
    ROUND(SUM(amount),2) AS revenue,
    SUM(qty) AS units,
    COUNT(DISTINCT order_id) AS orders
FROM amazon_sales
WHERE status IN ('Shipped','Shipped - Delivered to Buyer')
GROUP BY LOWER(category)
ORDER BY revenue DESC;

-- 07. Category revenue share
WITH category_sales AS (
    SELECT LOWER(category) category, SUM(amount) revenue
    FROM amazon_sales
    WHERE status IN ('Shipped','Shipped - Delivered to Buyer')
    GROUP BY LOWER(category)
)
SELECT category,
       ROUND(revenue,2) revenue,
       ROUND(100 * revenue / SUM(revenue) OVER (),2) revenue_share_pct
FROM category_sales
ORDER BY revenue DESC;

-- 08. Top 20 SKUs
SELECT sku,
       ROUND(SUM(amount),2) revenue,
       SUM(qty) units,
       COUNT(DISTINCT order_id) orders
FROM amazon_sales
WHERE status IN ('Shipped','Shipped - Delivered to Buyer')
GROUP BY sku
ORDER BY revenue DESC
LIMIT 20;

-- 09. Top 10 styles
SELECT style,
       ROUND(SUM(amount),2) revenue,
       SUM(qty) units
FROM amazon_sales
WHERE status IN ('Shipped','Shipped - Delivered to Buyer')
GROUP BY style
ORDER BY revenue DESC
LIMIT 10;

-- 10. Top states
SELECT ship_state,
       ROUND(SUM(amount),2) revenue,
       COUNT(DISTINCT order_id) orders
FROM amazon_sales
WHERE status IN ('Shipped','Shipped - Delivered to Buyer')
GROUP BY ship_state
ORDER BY revenue DESC
LIMIT 10;

-- 11. Top cities
SELECT ship_city, ship_state,
       ROUND(SUM(amount),2) revenue,
       COUNT(DISTINCT order_id) orders
FROM amazon_sales
WHERE status IN ('Shipped','Shipped - Delivered to Buyer')
GROUP BY ship_city, ship_state
ORDER BY revenue DESC
LIMIT 15;

-- 12. Fulfilment comparison
SELECT fulfilment,
       ROUND(SUM(amount),2) revenue,
       SUM(qty) units,
       COUNT(DISTINCT order_id) orders
FROM amazon_sales
WHERE status IN ('Shipped','Shipped - Delivered to Buyer')
GROUP BY fulfilment
ORDER BY revenue DESC;

-- 13. B2B vs B2C
SELECT
    CASE WHEN b2b = 1 THEN 'B2B' ELSE 'B2C' END customer_type,
    ROUND(SUM(amount),2) revenue,
    SUM(qty) units,
    COUNT(DISTINCT order_id) orders
FROM amazon_sales
WHERE status IN ('Shipped','Shipped - Delivered to Buyer')
GROUP BY b2b;

-- 14. Sales channel
SELECT sales_channel,
       ROUND(SUM(amount),2) revenue,
       COUNT(DISTINCT order_id) orders
FROM amazon_sales
WHERE status IN ('Shipped','Shipped - Delivered to Buyer')
GROUP BY sales_channel
ORDER BY revenue DESC;

-- 15. Size analysis
SELECT size,
       SUM(qty) units,
       ROUND(SUM(amount),2) revenue
FROM amazon_sales
WHERE status IN ('Shipped','Shipped - Delivered to Buyer')
GROUP BY size
ORDER BY units DESC;

-- 16. Top products within each category
WITH product_sales AS (
    SELECT LOWER(category) category, sku, SUM(amount) revenue
    FROM amazon_sales
    WHERE status IN ('Shipped','Shipped - Delivered to Buyer')
    GROUP BY LOWER(category), sku
),
ranked AS (
    SELECT category, sku, revenue,
           DENSE_RANK() OVER (
               PARTITION BY category ORDER BY revenue DESC
           ) AS category_rank
    FROM product_sales
)
SELECT category, sku, ROUND(revenue,2) revenue, category_rank
FROM ranked
WHERE category_rank <= 3
ORDER BY category, category_rank;

-- 17. Running monthly revenue
WITH monthly AS (
    SELECT DATE_FORMAT(order_date,'%Y-%m') month, SUM(amount) revenue
    FROM amazon_sales
    WHERE status IN ('Shipped','Shipped - Delivered to Buyer')
    GROUP BY DATE_FORMAT(order_date,'%Y-%m')
)
SELECT month,
       ROUND(revenue,2) revenue,
       ROUND(SUM(revenue) OVER (ORDER BY month),2) running_revenue
FROM monthly
ORDER BY month;

-- 18. High-volume SKUs
SELECT sku, SUM(qty) units
FROM amazon_sales
WHERE status IN ('Shipped','Shipped - Delivered to Buyer')
GROUP BY sku
HAVING SUM(qty) > 500
ORDER BY units DESC;

-- 19. Products with high orders but comparatively low revenue
SELECT sku,
       COUNT(DISTINCT order_id) orders,
       ROUND(SUM(amount),2) revenue,
       ROUND(SUM(amount)/COUNT(DISTINCT order_id),2) revenue_per_order
FROM amazon_sales
WHERE status IN ('Shipped','Shipped - Delivered to Buyer')
GROUP BY sku
HAVING COUNT(DISTINCT order_id) >= 50
ORDER BY revenue_per_order ASC
LIMIT 20;

-- 20. Cancelled quantity by category
SELECT LOWER(category) category,
       SUM(qty) cancelled_units,
       COUNT(*) cancelled_lines
FROM amazon_sales
WHERE status = 'Cancelled'
GROUP BY LOWER(category)
ORDER BY cancelled_units DESC;

-- 21. Cancellation rate by category
SELECT LOWER(category) category,
       ROUND(100.0 * SUM(status='Cancelled') / COUNT(*),2) cancellation_rate_pct
FROM amazon_sales
GROUP BY LOWER(category)
ORDER BY cancellation_rate_pct DESC;

-- 22. Fulfilment share of revenue
WITH f AS (
    SELECT fulfilment, SUM(amount) revenue
    FROM amazon_sales
    WHERE status IN ('Shipped','Shipped - Delivered to Buyer')
    GROUP BY fulfilment
)
SELECT fulfilment,
       ROUND(revenue,2) revenue,
       ROUND(100 * revenue / SUM(revenue) OVER (),2) revenue_share_pct
FROM f
ORDER BY revenue DESC;

-- 23. Average selling value by category
SELECT LOWER(category) category,
       ROUND(SUM(amount)/NULLIF(SUM(qty),0),2) avg_selling_value
FROM amazon_sales
WHERE status IN ('Shipped','Shipped - Delivered to Buyer')
GROUP BY LOWER(category)
ORDER BY avg_selling_value DESC;

-- 24. Orders by weekday
SELECT DAYNAME(order_date) weekday,
       COUNT(DISTINCT order_id) orders,
       ROUND(SUM(amount),2) revenue
FROM amazon_sales
WHERE status IN ('Shipped','Shipped - Delivered to Buyer')
GROUP BY DAYOFWEEK(order_date), DAYNAME(order_date)
ORDER BY DAYOFWEEK(order_date);

-- 25. Highest-revenue month
WITH m AS (
    SELECT DATE_FORMAT(order_date,'%Y-%m') month, SUM(amount) revenue
    FROM amazon_sales
    WHERE status IN ('Shipped','Shipped - Delivered to Buyer')
    GROUP BY DATE_FORMAT(order_date,'%Y-%m')
)
SELECT month, ROUND(revenue,2) revenue
FROM m
ORDER BY revenue DESC
LIMIT 1;

-- 26. State contribution to total revenue
WITH s AS (
    SELECT ship_state, SUM(amount) revenue
    FROM amazon_sales
    WHERE status IN ('Shipped','Shipped - Delivered to Buyer')
    GROUP BY ship_state
)
SELECT ship_state,
       ROUND(revenue,2) revenue,
       ROUND(100 * revenue / SUM(revenue) OVER (),2) revenue_share_pct
FROM s
ORDER BY revenue DESC;

-- 27. Top 5 cities in each state
WITH city_sales AS (
    SELECT ship_state, ship_city, SUM(amount) revenue
    FROM amazon_sales
    WHERE status IN ('Shipped','Shipped - Delivered to Buyer')
    GROUP BY ship_state, ship_city
),
ranked AS (
    SELECT ship_state, ship_city, revenue,
           ROW_NUMBER() OVER (
               PARTITION BY ship_state ORDER BY revenue DESC
           ) AS city_rank
    FROM city_sales
)
SELECT ship_state, ship_city, ROUND(revenue,2) revenue, city_rank
FROM ranked
WHERE city_rank <= 5
ORDER BY ship_state, city_rank;

-- 28. Orders containing more than one line
SELECT order_id,
       COUNT(*) AS line_count,
       SUM(qty) AS units,
       ROUND(SUM(amount),2) AS order_value
FROM amazon_sales
WHERE status IN ('Shipped','Shipped - Delivered to Buyer')
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY order_value DESC
LIMIT 20;

-- 29. Average order value by fulfilment
SELECT fulfilment,
       ROUND(SUM(amount)/COUNT(DISTINCT order_id),2) avg_order_value
FROM amazon_sales
WHERE status IN ('Shipped','Shipped - Delivered to Buyer')
GROUP BY fulfilment
ORDER BY avg_order_value DESC;

-- 30. Portfolio-ready executive summary
SELECT
    ROUND(SUM(amount),2) AS successful_revenue,
    COUNT(DISTINCT order_id) AS successful_orders,
    SUM(qty) AS successful_units,
    ROUND(SUM(amount)/COUNT(DISTINCT order_id),2) AS avg_order_value
FROM amazon_sales
WHERE status IN ('Shipped','Shipped - Delivered to Buyer');
