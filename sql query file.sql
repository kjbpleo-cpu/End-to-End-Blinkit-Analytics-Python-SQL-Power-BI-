CREATE DATABASE blinkit_analysis;
USE blinkit_analysis;

select * from blinkit_data limit 10;
CREATE TABLE products AS
SELECT DISTINCT
    product_id,
    product_name,
    category,
    brand,
    is_organic,
    packaging_type,
    weight_g
FROM blinkit_data;
CREATE TABLE pricing AS
SELECT
    product_id,
    price,
    discount_pct,
    final_price,
    profit_margin_pct,
    discount_value
FROM blinkit_data;
CREATE TABLE sales AS
SELECT
    product_id,
    sold_quantity,
    revenue,
    demand_index,
    date_added
FROM blinkit_data;
CREATE TABLE reviews AS
SELECT
    product_id,
    rating,
    num_reviews,
    rating_category
FROM blinkit_data;
CREATE TABLE delivery AS
SELECT
    product_id,
    delivery_time_min,
    delivery_status,
    delivery_speed,
    city
FROM blinkit_data;
CREATE TABLE inventory AS
SELECT
    product_id,
    stock,
    reorder_level,
    shelf_life_days,
    expiry_date
FROM blinkit_data;
CREATE TABLE offers AS
SELECT
    product_id,
    offer_type
FROM blinkit_data;
show tables;
SELECT * FROM products LIMIT 5;
SELECT * FROM sales LIMIT 5;

/*top revenue categories*/
SELECT p.category, SUM(s.revenue) AS total_revenue
FROM sales s
JOIN products p ON s.product_id = p.product_id
GROUP BY p.category
ORDER BY total_revenue DESC;

/*impact of discount on sales */
SELECT discount_pct, AVG(sold_quantity) AS avg_sales
FROM pricing p
JOIN sales s ON p.product_id = s.product_id
GROUP BY discount_pct
ORDER BY avg_sales DESC;

/* rating vs sales */
SELECT r.rating_category, AVG(s.sold_quantity) AS avg_sales
FROM reviews r
JOIN sales s ON r.product_id = s.product_id
GROUP BY r.rating_category;

/*Delivery speed impact */
SELECT d.delivery_speed, AVG(r.rating) AS avg_rating
FROM delivery d
JOIN reviews r ON d.product_id = r.product_id
GROUP BY d.delivery_speed;

/*city wise revenue */
SELECT d.city, SUM(s.revenue) AS total_revenue
FROM delivery d
JOIN sales s ON d.product_id = s.product_id
GROUP BY d.city
ORDER BY total_revenue DESC;

/*low stock */
SELECT p.product_name, i.stock, i.reorder_level
FROM inventory i
JOIN products p ON i.product_id = p.product_id
WHERE i.stock < i.reorder_level;

/* products with high rating but low sales*/
SELECT p.product_name, r.rating, s.sold_quantity
FROM products p
JOIN reviews r ON p.product_id = r.product_id
JOIN sales s ON p.product_id = s.product_id
WHERE r.rating > 4.5 AND s.sold_quantity<20
order by sold_quantity;

/*profit analaysis*/
SELECT 
    p.category,
    AVG(pr.profit_margin_pct) AS avg_margin,
    SUM(s.revenue) AS total_revenue
FROM products p
JOIN pricing pr ON p.product_id = pr.product_id
JOIN sales s ON p.product_id = s.product_id
GROUP BY p.category;

/*offer impact on sales*/
SELECT o.offer_type, AVG(s.sold_quantity) AS avg_sales
FROM offers o
JOIN sales s ON o.product_id = s.product_id
GROUP BY o.offer_type
order by avg_sales DESC;

/*revenue by organic vs inorganic */
SELECT 
    p.is_organic,
    SUM(s.revenue) AS total_revenue
FROM products p
JOIN sales s ON p.product_id = s.product_id
GROUP BY p.is_organic;

/* does reviews impact sales */
SELECT 
    CASE 
        WHEN r.num_reviews < 50 THEN 'Low Reviews'
        WHEN r.num_reviews BETWEEN 50 AND 200 THEN 'Medium Reviews'
        ELSE 'High Reviews'
    END AS review_bucket,
    AVG(s.sold_quantity) AS avg_sales
FROM reviews r
JOIN sales s ON r.product_id = s.product_id
GROUP BY review_bucket
ORDER BY avg_sales DESC;
/* top category contribution */
SELECT 
    p.category,
    SUM(s.revenue) AS total_revenue,
    ROUND(
        SUM(s.revenue) * 100.0 / SUM(SUM(s.revenue)) OVER (),
        2
    ) AS revenue_percentage
FROM products p
JOIN sales s ON p.product_id = s.product_id
GROUP BY p.category
ORDER BY total_revenue DESC;


SELECT 
    MIN(final_price) AS min_price,
    MAX(final_price) AS max_price,
    AVG(final_price) AS avg_price
FROM pricing;

SELECT 
    price_range,
    total_revenue,
    ROUND(
        total_revenue * 100.0 / SUM(total_revenue) OVER (),
        2
    ) AS revenue_percentage
FROM (
    SELECT 
        CASE 
            WHEN p.final_price < 100 THEN 'Budget (<100)'
            WHEN p.final_price BETWEEN 100 AND 300 THEN 'Mid-range (100–300)'
            WHEN p.final_price BETWEEN 300 AND 700 THEN 'High (300–700)'
            ELSE 'Premium (700+)'
        END AS price_range,
        SUM(s.revenue) AS total_revenue
    FROM pricing p
    JOIN sales s ON p.product_id = s.product_id
    GROUP BY price_range
) t
ORDER BY total_revenue DESC;


/* demand vs supply */
SELECT 
    p.category,
    SUM(s.sold_quantity) AS demand,
    SUM(i.stock) AS supply
FROM products p
JOIN sales s ON p.product_id = s.product_id
JOIN inventory i ON p.product_id = i.product_id
GROUP BY p.category
ORDER BY demand DESC;

/* time trend */
SELECT 
    MONTH(date_added) AS month,
    SUM(revenue) AS total_revenue
FROM sales
GROUP BY month
ORDER BY month;

SELECT 
    p.product_name,
    SUM(s.revenue) AS revenue
FROM products p
JOIN sales s ON p.product_id = s.product_id
GROUP BY p.product_name
ORDER BY revenue DESC
LIMIT 10;