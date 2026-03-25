---Checking the data loaded so i can have an idea of the type of data i am working on

select * from `workspace`.`default`.`bright_coffee_shop_analysis` limit 100;

----------------------------------------------------------------------------

---As instructed below I will fix the decimal point problem as indicated in the question paper

SELECT
    transaction_id,
    transaction_date,
    transaction_time,
    product_id,
    transaction_qty,
    
    -- Fix decimal: replace ',' with '.' then cast
    CAST(REPLACE(unit_price, ',', '.') AS DECIMAL(10, 2)) AS unit_price

FROM bright_coffee_shop_analysis;


----------------------------------------------------------------------------------------------------
---Below we will use time to see how the Coffee Shop performs
----------------------------------------------------------------------------------------------------
---I have created a new time bucket where i split into 30min intervals

SELECT *,
    CASE 
        WHEN MINUTE(transaction_time) < 30 
        THEN CONCAT(HOUR(transaction_time), ':00 - ', HOUR(transaction_time), ':30')
        ELSE CONCAT(HOUR(transaction_time), ':30 - ', HOUR(transaction_time)+1, ':00')
    END AS time_bucket
FROM bright_coffee_shop_analysis;

---What are the stores opening and close times

SELECT 
    store_location,
    MIN(transaction_time) AS opening_time,
    MAX(transaction_time) AS closing_time
FROM bright_coffee_shop_analysis
GROUP BY store_location;

---What is the total revenue in each hour of the day

SELECT 
    hour(transaction_time) AS transaction_hour,
    SUM(CAST(unit_price AS DOUBLE) * transaction_qty) AS total_revenue
FROM bright_coffee_shop_analysis
GROUP BY hour(transaction_time)
ORDER BY transaction_hour;

---What is the busiest hour (most transactions)?

SELECT 
    HOUR(transaction_time) AS hour_of_day,
    COUNT(*) AS total_transactions,
    SUM(transaction_qty) AS total_items_sold,
    SUM(transaction_qty * unit_price) AS total_revenue,
    ROUND(AVG(transaction_qty * unit_price), 2) AS avg_transaction_value
FROM bright_coffee_shop_analysis
GROUP BY HOUR(transaction_time)
ORDER BY total_transactions DESC
LIMIT 1;

---What hour generates the highest revenue?

SELECT 
    HOUR(transaction_time) AS transaction_hour,
    SUM(CAST(unit_price AS DOUBLE) * transaction_qty) AS total_revenue
FROM bright_coffee_shop_analysis
GROUP BY HOUR(transaction_time)
ORDER BY total_revenue DESC
LIMIT 1;

---What hour generates the lowest revenue?

SELECT 
    HOUR(transaction_time) AS transaction_hour,
    SUM(CAST(unit_price AS DOUBLE) * transaction_qty) AS total_revenue
FROM bright_coffee_shop_analysis
GROUP BY HOUR(transaction_time)
ORDER BY total_revenue ASC
LIMIT 1;

---What is the average transaction value by hour?

SELECT 
    HOUR(transaction_time) AS transaction_hour,
    ROUND(AVG(CAST(unit_price AS DOUBLE) * transaction_qty), 2) AS avg_transaction_value
FROM bright_coffee_shop_analysis
GROUP BY HOUR(transaction_time)
ORDER BY transaction_hour;

---What is the slowest hour for each store?

SELECT
    store_location,
    HOUR(transaction_time) AS hour_of_day,
    COUNT(transaction_id) AS total_transactions
FROM bright_coffee_shop_analysis
GROUP BY store_location, HOUR(transaction_time)
ORDER BY store_location, total_transactions ASC;

------What is the revenue rank of each store?

SELECT
    store_location,
    ROUND(SUM(CAST(REPLACE(unit_price, ',', '.') AS DECIMAL(10,2))
          * transaction_qty), 2) AS total_revenue,
    RANK() OVER (ORDER BY SUM(CAST(REPLACE(unit_price, ',', '.') AS DECIMAL(10,2))
          * transaction_qty) DESC) AS revenue_rank
FROM bright_coffee_shop_analysis
GROUP BY store_location
ORDER BY revenue_rank;

---What is the average transaction value by hour?

SELECT 
    hour(transaction_time) AS transaction_hour,
    AVG(CAST(unit_price AS DOUBLE) * transaction_qty) AS avg_transaction_value
FROM bright_coffee_shop_analysis
GROUP BY hour(transaction_time)
ORDER BY transaction_hour;

---What is the revenue in each 30-minute bucket?

SELECT 
    CASE 
        WHEN minute(transaction_time) < 30 
            THEN concat(hour(transaction_time), ':00 - ', hour(transaction_time), ':30')
        ELSE 
            concat(hour(transaction_time), ':30 - ', hour(transaction_time) + 1, ':00')
    END AS time_bucket,

    SUM(CAST(unit_price AS DOUBLE) * transaction_qty) AS total_revenue

FROM bright_coffee_shop_analysis
GROUP BY 
    CASE 
        WHEN minute(transaction_time) < 30 
            THEN concat(hour(transaction_time), ':00 - ', hour(transaction_time), ':30')
        ELSE 
            concat(hour(transaction_time), ':30 - ', hour(transaction_time) + 1, ':00')
    END

ORDER BY time_bucket;

---What is the total revenue by quarterly?

SELECT 
    quarter(transaction_date) AS quarter_number,
    SUM(CAST(unit_price AS DOUBLE) * transaction_qty) AS total_revenue
FROM bright_coffee_shop_analysis
GROUP BY quarter(transaction_date)
ORDER BY quarter_number;

---What is the busiest hour on weekdays?

SELECT
    HOUR(transaction_time) AS hour_of_day,
    COUNT(transaction_id)  AS total_transactions,
    ROUND(SUM(CAST(REPLACE(unit_price, ',', '.') AS DECIMAL(10,2))
          * transaction_qty), 2) AS total_revenue
FROM bright_coffee_shop_analysis
WHERE DAYOFWEEK(transaction_date) NOT IN (1, 7)
GROUP BY HOUR(transaction_time)
ORDER BY total_transactions DESC
LIMIT 5;

-----------------------------------------------------------------
---We will use products to see how they affect revenue. E,g Which product sells less

-----------------------------------------------------------------------------------

---Which specific products are available at each store?
SELECT DISTINCT
    store_location,
    product_detail,
    product_type,
    product_category
FROM bright_coffee_shop_analysis
ORDER BY store_location, product_detail;

---Which store sells which specific product? (with revenue)
SELECT 
    store_location,
    product_detail,
    product_type,
    product_category,
    SUM(CAST(unit_price AS DECIMAL(10,2)) * transaction_qty) AS total_revenue,
    SUM(transaction_qty) AS total_units_sold,
    COUNT(DISTINCT transaction_id) AS times_purchased
FROM bright_coffee_shop_analysis
GROUP BY store_location, product_detail, product_type, product_category
ORDER BY store_location, total_revenue DESC;

---Best performing product_detail at each store (Top 3 per store)

WITH store_product_rank AS (
    SELECT 
        store_location,
        product_detail,
        product_type,
        product_category,
        SUM(CAST(unit_price AS DECIMAL(10,2)) * transaction_qty) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY store_location ORDER BY SUM(CAST(unit_price AS DECIMAL(10,2)) * transaction_qty) DESC) AS rank_in_store
    FROM bright_coffee_shop_analysis
    GROUP BY store_location, product_detail, product_type, product_category
)
SELECT 
    store_location,
    product_detail,
    product_type,
    product_category,
    total_revenue
FROM store_product_rank
WHERE rank_in_store <= 3
ORDER BY store_location, rank_in_store;

---Which product_detail sells best at which store? (One best per store)
WITH store_best_product AS (
    SELECT 
        store_location,
        product_detail,
        product_type,
        product_category,
        SUM(CAST(unit_price AS DECIMAL(10,2)) * transaction_qty) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY store_location ORDER BY SUM(CAST(unit_price AS DECIMAL(10,2)) * transaction_qty) DESC) AS rank_in_store
    FROM bright_coffee_shop_analysis
    GROUP BY store_location, product_detail, product_type, product_category
)
SELECT 
    store_location,
    product_detail AS best_selling_product,
    product_type,
    product_category,
    total_revenue
FROM store_best_product
WHERE rank_in_store = 1
ORDER BY total_revenue DESC;

---Which store sells the most of each product_detail?
WITH product_best_store AS (
    SELECT 
        product_detail,
        store_location,
        SUM(CAST(unit_price AS DECIMAL(10,2)) * transaction_qty) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY product_detail ORDER BY SUM(CAST(unit_price AS DECIMAL(10,2)) * transaction_qty) DESC) AS rank_for_product
    FROM bright_coffee_shop_analysis
    GROUP BY product_detail, store_location
)
SELECT 
    product_detail,
    store_location AS best_store,
    total_revenue
FROM product_best_store
WHERE rank_for_product = 1
ORDER BY total_revenue DESC
LIMIT 20;

---Which product_type performs best at each store?
WITH store_type_rank AS (
    SELECT 
        store_location,
        product_type,
        product_category,
        SUM(CAST(unit_price AS DECIMAL(10,2)) * transaction_qty) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY store_location ORDER BY SUM(CAST(unit_price AS DECIMAL(10,2)) * transaction_qty) DESC) AS rank_in_store
    FROM bright_coffee_shop_analysis
    GROUP BY store_location, product_type, product_category
)
SELECT 
    store_location,
    product_type,
    product_category,
    total_revenue
FROM store_type_rank
WHERE rank_in_store = 1
ORDER BY store_location;

---Which store sells the most of each product_type?
WITH product_type_best_store AS (
    SELECT 
        product_type,
        store_location,
        SUM(CAST(unit_price AS DECIMAL(10,2)) * transaction_qty) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY product_type ORDER BY SUM(CAST(unit_price AS DECIMAL(10,2)) * transaction_qty) DESC) AS rank_for_type
    FROM bright_coffee_shop_analysis
    GROUP BY product_type, store_location
)
SELECT 
    product_type,
    store_location AS best_store,
    total_revenue
FROM product_type_best_store
WHERE rank_for_type = 1
ORDER BY total_revenue DESC;

---Revenue by product_type for each store
SELECT 
    store_location,
    product_type,
    product_category,
    SUM(CAST(unit_price AS DECIMAL(10,2)) * transaction_qty) AS total_revenue,
    SUM(transaction_qty) AS total_units_sold
FROM bright_coffee_shop_analysis
GROUP BY store_location, product_type, product_category
ORDER BY store_location, total_revenue DESC;

---Which product_category performs best at each store?
WITH store_category_rank AS (
    SELECT 
        store_location,
        product_category,
        SUM(CAST(unit_price AS DECIMAL(10,2)) * transaction_qty) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY store_location ORDER BY SUM(CAST(unit_price AS DECIMAL(10,2)) * transaction_qty) DESC) AS rank_in_store
    FROM bright_coffee_shop_analysis
    GROUP BY store_location, product_category
)
SELECT 
    store_location,
    product_category AS top_category,
    total_revenue
FROM store_category_rank
WHERE rank_in_store = 1
ORDER BY store_location;

---Which store sells the most of each product_category?
WITH category_best_store AS (
    SELECT 
        product_category,
        store_location,
        SUM(CAST(unit_price AS DECIMAL(10,2)) * transaction_qty) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY product_category ORDER BY SUM(CAST(unit_price AS DECIMAL(10,2)) * transaction_qty) DESC) AS rank_for_category
    FROM bright_coffee_shop_analysis
    GROUP BY product_category, store_location
)
SELECT 
    product_category,
    store_location AS best_store,
    total_revenue
FROM category_best_store
WHERE rank_for_category = 1
ORDER BY product_category;

---Which 10 products generate the lowest revenue?

SELECT
    product_detail,
    product_type,
    product_category,
    ROUND(SUM(CAST(REPLACE(unit_price, ',', '.') AS DECIMAL(10,2))
          * transaction_qty), 2) AS total_revenue
FROM bright_coffee_shop_analysis
GROUP BY product_detail, product_type, product_category
ORDER BY total_revenue ASC
LIMIT 10;

---Which 10 products generate the highest revenue?

SELECT
    product_detail,
    product_type,
    product_category,
    ROUND(SUM(CAST(REPLACE(unit_price, ',', '.') AS DECIMAL(10,2))
          * transaction_qty), 2)  AS total_revenue
FROM bright_coffee_shop_analysis
GROUP BY product_detail, product_type, product_category
ORDER BY total_revenue DESC
LIMIT 10;

---Which product is underperforming?

SELECT
    product_detail,
    product_type,
    product_category,
    SUM(transaction_qty) AS total_units_sold,
    ROUND(SUM(CAST(REPLACE(unit_price, ',', '.') AS DECIMAL(10,2))
          * transaction_qty), 2) AS total_revenue
FROM bright_coffee_shop_analysis
GROUP BY product_detail, product_type, product_category
ORDER BY total_revenue ASC
LIMIT 1;

----------------------------------------------------------------------
---We will look at each store and see how thier Total contribution to the BrightLearn Coffee Shop performance
-------------------------------------------------------------------------------------------------------------
---Basic store information

SELECT DISTINCT
    store_id,
    store_location
FROM bright_coffee_shop_analysis
ORDER BY store_id;

---Daily performance of each store

SELECT 
    store_location,
    transaction_date,
    COUNT(DISTINCT transaction_id) AS daily_transactions,
    SUM(CAST(unit_price AS DECIMAL(10,2)) * transaction_qty) AS daily_revenue,
    SUM(transaction_qty) AS daily_units_sold,
    ROUND(AVG(CAST(unit_price AS DECIMAL(10,2)) * transaction_qty), 2) AS avg_transaction_value
FROM bright_coffee_shop_analysis
GROUP BY store_location, transaction_date
ORDER BY store_location, transaction_date;

--Hourly performance of each store

SELECT 
    store_location,
    hour(transaction_time) AS hour_of_day,
    COUNT(DISTINCT transaction_id) AS transactions,
    SUM(CAST(unit_price AS DOUBLE) * transaction_qty) AS revenue,
    SUM(transaction_qty) AS units_sold
FROM bright_coffee_shop_analysis
GROUP BY 
    store_location,
    hour(transaction_time)
ORDER BY 
    store_location,
    hour_of_day;

    ---Peak hour for each store
WITH store_hourly_rank AS (
    SELECT 
        store_location,
        HOUR(transaction_time) AS peak_hour,
        COUNT(DISTINCT transaction_id) AS transaction_count,
        ROW_NUMBER() OVER (PARTITION BY store_location ORDER BY COUNT(DISTINCT transaction_id) DESC) AS rank
    FROM bright_coffee_shop_analysis
    GROUP BY store_location, HOUR(transaction_time)
)
SELECT 
    store_location,
    peak_hour,
    transaction_count AS peak_hour_transactions
FROM store_hourly_rank
WHERE rank = 1
ORDER BY store_location;

---WITH store_hourly_rank AS (
WITH store_hourly_rank AS (
    SELECT 
        store_location,
        HOUR(transaction_time) AS peak_hour,
        COUNT(DISTINCT transaction_id) AS transaction_count,
        ROW_NUMBER() OVER (PARTITION BY store_location ORDER BY COUNT(DISTINCT transaction_id) DESC) AS rank
    FROM bright_coffee_shop_analysis
    GROUP BY store_location, HOUR(transaction_time)
)
SELECT 
    store_location,
    peak_hour,
    transaction_count AS peak_hour_transactions
FROM store_hourly_rank
WHERE rank = 1
ORDER BY store_location;

---Product category performance by store

SELECT 
    store_location,
    product_category,
    SUM(CAST(unit_price AS DECIMAL(10,2)) * transaction_qty) AS category_revenue,
    ROUND(SUM(CAST(unit_price AS DECIMAL(10,2)) * transaction_qty) * 100.0 / 
        SUM(SUM(CAST(unit_price AS DECIMAL(10,2)) * transaction_qty)) OVER (PARTITION BY store_location), 2) AS category_percentage
FROM bright_coffee_shop_analysis
GROUP BY store_location, product_category
ORDER BY store_location, category_revenue DESC;

---Product type performance by store

SELECT 
    store_location,
    product_type,
    product_category,
    SUM(CAST(unit_price AS DECIMAL(10,2)) * transaction_qty) AS type_revenue,
    SUM(transaction_qty) AS units_sold
FROM bright_coffee_shop_analysis
GROUP BY store_location, product_type, product_category
ORDER BY store_location, type_revenue DESC;

---Top 5 products for each store

WITH store_product_rank AS (
    SELECT 
        store_location,
        product_detail,
        product_type,
        product_category,
        SUM(CAST(unit_price AS DECIMAL(10,2)) * transaction_qty) AS product_revenue,
        ROW_NUMBER() OVER (PARTITION BY store_location ORDER BY SUM(CAST(unit_price AS DECIMAL(10,2)) * transaction_qty) DESC) AS rank
    FROM bright_coffee_shop_analysis
    GROUP BY store_location, product_detail, product_type, product_category
)
SELECT 
    store_location,
    product_detail,
    product_type,
    product_category,
    product_revenue
FROM store_product_rank
WHERE rank <= 5
ORDER BY store_location, rank;

--Unique products sold at each store

SELECT 
    store_location,
    COUNT(DISTINCT product_detail) AS unique_products,
    COUNT(DISTINCT product_type) AS unique_product_types,
    COUNT(DISTINCT product_category) AS unique_categories
FROM bright_coffee_shop_analysis
GROUP BY store_location
ORDER BY unique_products DESC;

---Store contribution to total company revenue

WITH total_company_revenue AS (
    SELECT SUM(CAST(unit_price AS DECIMAL(10,2)) * transaction_qty) AS total_rev
    FROM bright_coffee_shop_analysis
)
SELECT 
    store_location,
    SUM(CAST(unit_price AS DECIMAL(10,2)) * transaction_qty) AS store_revenue,
    ROUND(SUM(CAST(unit_price AS DECIMAL(10,2)) * transaction_qty) * 100.0 / (SELECT total_rev FROM total_company_revenue), 2) AS contribution_percentage
FROM bright_coffee_shop_analysis
GROUP BY store_location
ORDER BY store_revenue DESC;

---Which store has the highest sales?

SELECT
    store_location,
    ROUND(SUM(CAST(REPLACE(unit_price, ',', '.') AS DECIMAL(10,2))
          * transaction_qty), 2) AS total_revenue
FROM bright_coffee_shop_analysis
GROUP BY store_location
ORDER BY total_revenue DESC
LIMIT 1;

---Which store has the lowest sales?

SELECT
    store_location,
    ROUND(SUM(CAST(REPLACE(unit_price, ',', '.') AS DECIMAL(10,2))
          * transaction_qty), 2) AS total_revenue
FROM bright_coffee_shop_analysis
GROUP BY store_location
ORDER BY total_revenue ASC
LIMIT 1;

---What is the average transaction value per store?

SELECT
    store_location,
    ROUND(AVG(CAST(REPLACE(unit_price, ',', '.') AS DECIMAL(10,2))
          * transaction_qty), 2) AS avg_transaction_value
FROM bright_coffee_shop_analysis
GROUP BY store_location
ORDER BY avg_transaction_value DESC;

--Store ranking by revenue
SELECT 
    store_location,
    SUM(CAST(unit_price AS DECIMAL(10,2)) * transaction_qty) AS total_revenue,
    RANK() OVER (ORDER BY SUM(CAST(unit_price AS DECIMAL(10,2)) * transaction_qty) DESC) AS revenue_rank
FROM bright_coffee_shop_analysis
GROUP BY store_location;

--Best performing store

SELECT 
    store_location,
    SUM(CAST(unit_price AS DECIMAL(10,2)) * transaction_qty) AS total_revenue,
    'Best Store' AS performance_type
FROM bright_coffee_shop_analysis
GROUP BY store_location
ORDER BY total_revenue DESC
LIMIT 1;

---Worst performing store

SELECT 
    store_location,
    SUM(CAST(unit_price AS DECIMAL(10,2)) * transaction_qty) AS total_revenue,
    'Worst Store' AS performance_type
FROM bright_coffee_shop_analysis
GROUP BY store_location
ORDER BY total_revenue ASC
LIMIT 1;

---Revenue difference between best and worst store
WITH store_revenue AS (
    SELECT 
        store_location,
        SUM(CAST(unit_price AS DECIMAL(10,2)) * transaction_qty) AS total_revenue
    FROM bright_coffee_shop_analysis
    GROUP BY store_location
)
SELECT 
    MAX(total_revenue) AS highest_revenue,
    MIN(total_revenue) AS lowest_revenue,
    MAX(total_revenue) - MIN(total_revenue) AS revenue_gap,
    ROUND((MAX(total_revenue) - MIN(total_revenue)) / MIN(total_revenue) * 100, 2) AS percentage_gap
FROM store_revenue;

---Categorize stores by revenue performance
WITH store_metrics AS (
    SELECT 
        store_location,
        SUM(CAST(unit_price AS DECIMAL(10,2)) * transaction_qty) AS total_revenue,
        COUNT(DISTINCT transaction_id) AS total_transactions,
        ROUND(AVG(CAST(unit_price AS DECIMAL(10,2)) * transaction_qty), 2) AS avg_ticket
    FROM bright_coffee_shop_analysis
    GROUP BY store_location
)
SELECT 
    store_location,
    total_revenue,
    total_transactions,
    avg_ticket,
    CASE 
        WHEN total_revenue >= (SELECT AVG(total_revenue) FROM store_metrics) * 1.2 THEN 'Top Performer'
        WHEN total_revenue >= (SELECT AVG(total_revenue) FROM store_metrics) THEN 'Above Average'
        WHEN total_revenue >= (SELECT AVG(total_revenue) FROM store_metrics) * 0.8 THEN 'Average'
        ELSE 'Needs Improvement'
    END AS performance_category
FROM store_metrics
ORDER BY total_revenue DESC;

