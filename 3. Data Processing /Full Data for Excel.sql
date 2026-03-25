-- =============================================================================
-- ORIGINAL CODE WITH NEW COLUMNS ADDED
-- All new columns are added at the bottom
-- =============================================================================

-- Checking the data loaded so i can have an idea of the type of data i am working on

select * from `workspace`.`default`.`bright_coffee_shop_analysis` limit 100;

----------------------------------------------------------------------------

-- As instructed below I will fix the decimal point problem as indicated in the question paper

SELECT
    transaction_id,
    transaction_date,
    transaction_time,
    product_id,
    transaction_qty,
    store_id,
    store_location,
    product_category,
    product_type,
    product_detail,
    unit_price,
    
    -- Fix decimal: replace ',' with '.' then cast
    CAST(REPLACE(unit_price, ',', '.') AS DECIMAL(10, 2)) AS unit_price_clean,
    
    -- ==================== NEW COLUMNS ADDED ====================
    
    -- 1. Total amount (revenue)
    CAST(REPLACE(unit_price, ',', '.') AS DECIMAL(10, 2)) * transaction_qty AS total_amount,
    
    -- 2. Time bucket (30-minute intervals)
    CASE 
        WHEN MINUTE(transaction_time) < 30 
        THEN CONCAT(HOUR(transaction_time), ':00 - ', HOUR(transaction_time), ':30')
        ELSE CONCAT(HOUR(transaction_time), ':30 - ', HOUR(transaction_time)+1, ':00')
    END AS time_bucket,
    
    -- 3. Hour of day
    HOUR(transaction_time) AS hour_of_day,
    
    -- 4. Day of week number
    DAYOFWEEK(transaction_date) AS day_of_week_num,
    
    -- 5. Day of week name
    CASE DAYOFWEEK(transaction_date)
        WHEN 1 THEN 'Sunday'
        WHEN 2 THEN 'Monday'
        WHEN 3 THEN 'Tuesday'
        WHEN 4 THEN 'Wednesday'
        WHEN 5 THEN 'Thursday'
        WHEN 6 THEN 'Friday'
        WHEN 7 THEN 'Saturday'
    END AS day_of_week_name,
    
    -- 6. Month number
    MONTH(transaction_date) AS month_num,
    
    -- 7. Month name
    CASE MONTH(transaction_date)
        WHEN 1 THEN 'January'
        WHEN 2 THEN 'February'
        WHEN 3 THEN 'March'
        WHEN 4 THEN 'April'
        WHEN 5 THEN 'May'
        WHEN 6 THEN 'June'
        WHEN 7 THEN 'July'
        WHEN 8 THEN 'August'
        WHEN 9 THEN 'September'
        WHEN 10 THEN 'October'
        WHEN 11 THEN 'November'
        WHEN 12 THEN 'December'
    END AS month_name,
    
    -- 8. Quarter number
    QUARTER(transaction_date) AS quarter_num,
    
    -- 9. Year
    YEAR(transaction_date) AS year,
    
    -- 10. Day type (Weekend/Weekday)
    CASE 
        WHEN DAYOFWEEK(transaction_date) IN (1, 7) THEN 'Weekend'
        ELSE 'Weekday'
    END AS day_type,
    
    -- 11. Time of day category
    CASE 
        WHEN HOUR(transaction_time) BETWEEN 6 AND 11 THEN 'Morning'
        WHEN HOUR(transaction_time) BETWEEN 12 AND 16 THEN 'Afternoon'
        WHEN HOUR(transaction_time) BETWEEN 17 AND 20 THEN 'Evening'
        ELSE 'Late Night'
    END AS time_of_day_category,
    
    -- 12. Transaction size category
    CASE 
        WHEN transaction_qty = 1 THEN 'Single Item'
        WHEN transaction_qty = 2 THEN '2 Items'
        WHEN transaction_qty = 3 THEN '3 Items'
        WHEN transaction_qty >= 4 THEN '4+ Items'
    END AS transaction_size_category,
    
    -- 13. Revenue tier
    CASE 
        WHEN CAST(REPLACE(unit_price, ',', '.') AS DECIMAL(10,2)) * transaction_qty < 5 THEN 'Under 5'
        WHEN CAST(REPLACE(unit_price, ',', '.') AS DECIMAL(10,2)) * transaction_qty BETWEEN 5 AND 10 THEN '5 - 10'
        WHEN CAST(REPLACE(unit_price, ',', '.') AS DECIMAL(10,2)) * transaction_qty BETWEEN 10 AND 15 THEN '10 - 15'
        WHEN CAST(REPLACE(unit_price, ',', '.') AS DECIMAL(10,2)) * transaction_qty BETWEEN 15 AND 20 THEN '15 - 20'
        ELSE 'Over 20'
    END AS revenue_tier,
    
    -- 14. Price tier
    CASE 
        WHEN CAST(REPLACE(unit_price, ',', '.') AS DECIMAL(10,2)) < 3 THEN 'Budget'
        WHEN CAST(REPLACE(unit_price, ',', '.') AS DECIMAL(10,2)) BETWEEN 3 AND 5 THEN 'Standard'
        WHEN CAST(REPLACE(unit_price, ',', '.') AS DECIMAL(10,2)) > 5 THEN 'Premium'
    END AS price_tier,
    
    -- 15. Store opening and closing times
    MIN(transaction_time) OVER (PARTITION BY store_location) AS store_opening_time,
    MAX(transaction_time) OVER (PARTITION BY store_location) AS store_closing_time,
    
    -- 16. Store total revenue
    SUM(CAST(REPLACE(unit_price, ',', '.') AS DECIMAL(10,2)) * transaction_qty) OVER (PARTITION BY store_location) AS store_total_revenue,
    
    -- 17. Store revenue rank
    RANK() OVER (ORDER BY SUM(CAST(REPLACE(unit_price, ',', '.') AS DECIMAL(10,2)) * transaction_qty) OVER (PARTITION BY store_location) DESC) AS store_revenue_rank,
    
    -- 18. Product total revenue
    SUM(CAST(REPLACE(unit_price, ',', '.') AS DECIMAL(10,2)) * transaction_qty) OVER (PARTITION BY product_detail) AS product_total_revenue,
    
    -- 19. Product rank
    RANK() OVER (ORDER BY SUM(CAST(REPLACE(unit_price, ',', '.') AS DECIMAL(10,2)) * transaction_qty) OVER (PARTITION BY product_detail) DESC) AS product_rank,
    
    -- 20. Category total revenue
    SUM(CAST(REPLACE(unit_price, ',', '.') AS DECIMAL(10,2)) * transaction_qty) OVER (PARTITION BY product_category) AS category_total_revenue,
    
    -- 21. Category revenue percentage
    ROUND(
        SUM(CAST(REPLACE(unit_price, ',', '.') AS DECIMAL(10,2)) * transaction_qty) OVER (PARTITION BY product_category) 
        / NULLIF(SUM(CAST(REPLACE(unit_price, ',', '.') AS DECIMAL(10,2)) * transaction_qty) OVER (), 0) * 100, 2
    ) AS category_revenue_percentage,
    
    -- 22. Store contribution percentage
    ROUND(
        SUM(CAST(REPLACE(unit_price, ',', '.') AS DECIMAL(10,2)) * transaction_qty) OVER (PARTITION BY store_location) 
        / NULLIF(SUM(CAST(REPLACE(unit_price, ',', '.') AS DECIMAL(10,2)) * transaction_qty) OVER (), 0) * 100, 2
    ) AS store_contribution_percentage,
    
    -- 23. Product rank in each store
    ROW_NUMBER() OVER (PARTITION BY store_location ORDER BY SUM(CAST(REPLACE(unit_price, ',', '.') AS DECIMAL(10,2)) * transaction_qty) OVER (PARTITION BY store_location, product_detail) DESC) AS product_rank_in_store,
    
    -- 24. Store top product badge
    CASE 
        WHEN ROW_NUMBER() OVER (PARTITION BY store_location ORDER BY SUM(CAST(REPLACE(unit_price, ',', '.') AS DECIMAL(10,2)) * transaction_qty) OVER (PARTITION BY store_location, product_detail) DESC) = 1 
        THEN 'Best Seller'
        WHEN ROW_NUMBER() OVER (PARTITION BY store_location ORDER BY SUM(CAST(REPLACE(unit_price, ',', '.') AS DECIMAL(10,2)) * transaction_qty) OVER (PARTITION BY store_location, product_detail) DESC) <= 3 
        THEN 'Top 3'
        ELSE NULL
    END AS store_top_product,
    
    -- 25. Store rank for each product
    ROW_NUMBER() OVER (PARTITION BY product_detail ORDER BY SUM(CAST(REPLACE(unit_price, ',', '.') AS DECIMAL(10,2)) * transaction_qty) OVER (PARTITION BY product_detail, store_location) DESC) AS store_rank_for_product,
    
    -- 26. Best store for each product
    CASE 
        WHEN ROW_NUMBER() OVER (PARTITION BY product_detail ORDER BY SUM(CAST(REPLACE(unit_price, ',', '.') AS DECIMAL(10,2)) * transaction_qty) OVER (PARTITION BY product_detail, store_location) DESC) = 1 
        THEN 'Best Store'
        ELSE NULL
    END AS best_store_for_product,
    
    -- 27. Peak hour flag
    CASE 
        WHEN HOUR(transaction_time) = (
            SELECT HOUR(transaction_time) 
            FROM bright_coffee_shop_analysis 
            GROUP BY HOUR(transaction_time) 
            ORDER BY COUNT(*) DESC 
            LIMIT 1
        ) THEN 'Busiest Hour'
        ELSE NULL
    END AS is_peak_hour,
    
    -- 28. Highest revenue hour flag
    CASE 
        WHEN HOUR(transaction_time) = (
            SELECT HOUR(transaction_time) 
            FROM bright_coffee_shop_analysis 
            GROUP BY HOUR(transaction_time) 
            ORDER BY SUM(CAST(REPLACE(unit_price, ',', '.') AS DECIMAL(10,2)) * transaction_qty) DESC 
            LIMIT 1
        ) THEN 'Highest Revenue Hour'
        ELSE NULL
    END AS is_top_revenue_hour,
    
    -- 29. Slowest hour flag
    CASE 
        WHEN HOUR(transaction_time) = (
            SELECT HOUR(transaction_time) 
            FROM bright_coffee_shop_analysis 
            GROUP BY HOUR(transaction_time) 
            ORDER BY COUNT(*) ASC 
            LIMIT 1
        ) THEN 'Slowest Hour'
        ELSE NULL
    END AS is_slow_hour,
    
    -- 30. Average transaction value by hour
    ROUND(AVG(CAST(REPLACE(unit_price, ',', '.') AS DECIMAL(10,2)) * transaction_qty) OVER (PARTITION BY HOUR(transaction_time)), 2) AS avg_ticket_by_hour,
    
    -- 31. Average items per transaction by store
    ROUND(AVG(transaction_qty) OVER (PARTITION BY store_location), 2) AS avg_items_per_tx_by_store,
    
    -- 32. Store performance category
    CASE 
        WHEN SUM(CAST(REPLACE(unit_price, ',', '.') AS DECIMAL(10,2)) * transaction_qty) OVER (PARTITION BY store_location) 
            >= (SELECT AVG(store_total) FROM (SELECT SUM(CAST(REPLACE(unit_price, ',', '.') AS DECIMAL(10,2)) * transaction_qty) AS store_total FROM bright_coffee_shop_analysis GROUP BY store_location) t) * 1.2 
        THEN 'Top Performer'
        WHEN SUM(CAST(REPLACE(unit_price, ',', '.') AS DECIMAL(10,2)) * transaction_qty) OVER (PARTITION BY store_location) 
            >= (SELECT AVG(store_total) FROM (SELECT SUM(CAST(REPLACE(unit_price, ',', '.') AS DECIMAL(10,2)) * transaction_qty) AS store_total FROM bright_coffee_shop_analysis GROUP BY store_location) t)
        THEN 'Above Average'
        WHEN SUM(CAST(REPLACE(unit_price, ',', '.') AS DECIMAL(10,2)) * transaction_qty) OVER (PARTITION BY store_location) 
            >= (SELECT AVG(store_total) FROM (SELECT SUM(CAST(REPLACE(unit_price, ',', '.') AS DECIMAL(10,2)) * transaction_qty) AS store_total FROM bright_coffee_shop_analysis GROUP BY store_location) t) * 0.8
        THEN 'Average'
        ELSE 'Needs Improvement'
    END AS store_performance_category,
    
    -- 33. Product popularity score
    ROUND(
        SUM(transaction_qty) OVER (PARTITION BY product_detail) * 1.0 / 
        NULLIF(SUM(transaction_qty) OVER (), 0) * 100, 2
    ) AS product_popularity_score

FROM bright_coffee_shop_analysis;
