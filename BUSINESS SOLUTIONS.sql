-- PROBLEM 1  Generate a  sales report showing product names and total revenue for each product in 2024 --
SELECT 
    dp.product_name,
    SUM(fs.total_amount) as total_revenue,
    COUNT(fs.sale_id) as total_transactions
FROM fact_sales fs
JOIN dim_product dp ON fs.product_id = dp.product_id
JOIN dim_date dd ON fs.date_id = dd.date_id
WHERE dd.year = 2024
GROUP BY dp.product_id, dp.product_name
ORDER BY total_revenue DESC
LIMIT 20;


-- PROBLEM 2  How many B2B vs B2C customers do we have, and what's the average order value for each type? --
SELECT 
    dc.customer_type,
    COUNT(DISTINCT dc.customer_id) as customer_count,
    AVG(fs.total_amount) as avg_order_value,
    COUNT(fs.sale_id) as total_orders,
    SUM(fs.total_amount) as total_revenue
FROM dim_customer dc
JOIN fact_sales fs ON dc.customer_id = fs.customer_id
GROUP BY dc.customer_type
ORDER BY avg_order_value DESC;


-- PROBLEM 3 Show monthly sales trends for 2024 with month names and total revenue --
SELECT 
    dd.month,
    dd.month_name,
    COUNT(fs.sale_id) as total_transactions,
    SUM(fs.total_amount) as monthly_revenue,
    AVG(fs.total_amount) as avg_transaction_value
FROM fact_sales fs
JOIN dim_date dd ON fs.date_id = dd.date_id
WHERE dd.year = 2024
GROUP BY dd.month, dd.month_name
ORDER BY dd.month;


-- PROBLEM 4  Identify the top 10 sales representatives by total revenue in 2024, including their territory and performance tier --
SELECT 
    dsr.rep_name,
    dsr.territory,
    dsr.performance_tier,
    SUM(fs.total_amount) as total_revenue,
    COUNT(fs.sale_id) as total_sales,
    AVG(fs.total_amount) as avg_deal_size,
    ROUND(SUM(fs.profit_margin), 2) as total_profit
FROM dim_sales_rep dsr
JOIN fact_sales fs ON dsr.sales_rep_id = fs.sales_rep_id
JOIN dim_date dd ON fs.date_id = dd.date_id
WHERE dd.year = 2024 AND dsr.is_active = TRUE
GROUP BY dsr.sales_rep_id, dsr.rep_name, dsr.territory, dsr.performance_tier
ORDER BY total_revenue DESC
LIMIT 10;


-- PROBLEM 5 Analyze quarterly revenue performance by product category, showing growth rates compared to the previous quarter--
SELECT 
    dp.product_category,
    dd.year,
    dd.quarter,
    SUM(fs.total_amount) as quarterly_revenue,
    LAG(SUM(fs.total_amount)) OVER (
        PARTITION BY dp.product_category 
        ORDER BY dd.year, dd.quarter
    ) as previous_quarter_revenue,
    ROUND(
        ((SUM(fs.total_amount) - LAG(SUM(fs.total_amount)) OVER (
            PARTITION BY dp.product_category 
            ORDER BY dd.year, dd.quarter
        )) / NULLIF(LAG(SUM(fs.total_amount)) OVER (
            PARTITION BY dp.product_category 
            ORDER BY dd.year, dd.quarter
        ), 0)) * 100, 2
    ) as growth_rate_percent
FROM fact_sales fs
JOIN dim_product dp ON fs.product_id = dp.product_id
JOIN dim_date dd ON fs.date_id = dd.date_id
GROUP BY dp.product_category, dd.year, dd.quarter
ORDER BY dp.product_category, dd.year, dd.quarter;


-- Problem 6 :
-- Segment customers based on their total purchase value (High:>$10K, Medium:$5K-$10K, Low:<$5K) and show distribution by customer type. 
 SELECT 
    customer_type,
    customer_segment,
    COUNT(*) as customer_count,
    ROUND(AVG(total_spent), 2) as avg_spent_in_segment,
    ROUND((COUNT(*) * 100.0 / SUM(COUNT(*)) OVER ()), 2) as percentage_of_total
FROM (
    SELECT 
        dc.customer_type,
        SUM(fs.total_amount) as total_spent,
        CASE 
            WHEN SUM(fs.total_amount) > 10000 THEN 'High Value'
            WHEN SUM(fs.total_amount) >= 5000 THEN 'Medium Value'
            ELSE 'Low Value'
        END as customer_segment
    FROM dim_customer dc
    JOIN fact_sales fs ON dc.customer_id = fs.customer_id
    GROUP BY dc.customer_id, dc.customer_type
) customer_totals
GROUP BY customer_type, customer_segment
ORDER BY customer_type, 
    CASE customer_segment 
        WHEN 'High Value' THEN 1 
        WHEN 'Medium Value' THEN 2 
        ELSE 3 
    END;
    
    
-- PROBLEM 7 : Perform a cohort analysis showing customer retention rates by acquisition month --
WITH customer_cohorts AS (
    SELECT 
        customer_id,
        DATE_FORMAT(acquisition_date, '%Y-%m') as cohort_month
    FROM dim_customer
    WHERE acquisition_date IS NOT NULL
),
customer_activities AS (
    SELECT 
        cc.customer_id,
        cc.cohort_month,
        DATE_FORMAT(dd.full_date, '%Y-%m') as activity_month,
        TIMESTAMPDIFF(MONTH, 
            STR_TO_DATE(CONCAT(cc.cohort_month, '-01'), '%Y-%m-%d'),
            STR_TO_DATE(CONCAT(DATE_FORMAT(dd.full_date, '%Y-%m'), '-01'), '%Y-%m-%d')
        ) as months_since_acquisition
    FROM customer_cohorts cc
    JOIN fact_sales fs ON cc.customer_id = fs.customer_id
    JOIN dim_date dd ON fs.date_id = dd.date_id
),
cohort_sizes AS (
    SELECT 
        cohort_month,
        COUNT(DISTINCT customer_id) as cohort_size
    FROM customer_cohorts
    GROUP BY cohort_month
),
cohort_retention AS (
    SELECT 
        ca.cohort_month,
        ca.months_since_acquisition,
        COUNT(DISTINCT ca.customer_id) as active_customers
    FROM customer_activities ca
    GROUP BY ca.cohort_month, ca.months_since_acquisition
)
SELECT 
    cr.cohort_month,
    cs.cohort_size,
    cr.months_since_acquisition,
    cr.active_customers,
    ROUND((cr.active_customers * 100.0 / cs.cohort_size), 2) as retention_rate
FROM cohort_retention cr
JOIN cohort_sizes cs ON cr.cohort_month = cs.cohort_month
WHERE cr.months_since_acquisition <= 12
ORDER BY cr.cohort_month, cr.months_since_acquisition
LIMIT 50;


-- PROBLEM 8 : Create a comprehensive sales dashboard with running totals, moving averages, and performance rankings --
WITH monthly_category_sales AS (
    SELECT 
        dp.product_category,
        dd.year,
        dd.month,
        dd.month_name,
        SUM(fs.total_amount) as monthly_revenue,
        COUNT(DISTINCT fs.customer_id) as unique_customers
    FROM fact_sales fs
    JOIN dim_product dp ON fs.product_id = dp.product_id
    JOIN dim_date dd ON fs.date_id = dd.date_id
    WHERE dd.year IN (2023, 2024)
    GROUP BY dp.product_category, dd.year, dd.month, dd.month_name
)
SELECT 
    product_category,
    year,
    month,
    month_name,
    ROUND(monthly_revenue, 2) as monthly_revenue,
    
    -- Running total within each category
    ROUND(SUM(monthly_revenue) OVER (
        PARTITION BY product_category 
        ORDER BY year, month
        ROWS UNBOUNDED PRECEDING
    ), 2) as running_total,
    
    -- 3-month moving average
    ROUND(AVG(monthly_revenue) OVER (
        PARTITION BY product_category 
        ORDER BY year, month
        ROWS 2 PRECEDING
    ), 2) as three_month_avg,
    
    -- Rank by monthly performance within category
    ROW_NUMBER() OVER (
        PARTITION BY product_category 
        ORDER BY monthly_revenue DESC
    ) as performance_rank,
    
    -- Percentage of total sales for that month
    ROUND(
        (monthly_revenue * 100.0) / SUM(monthly_revenue) OVER (
            PARTITION BY year, month
        ), 2
    ) as pct_of_monthly_total
    
FROM monthly_category_sales
ORDER BY product_category, year, month;


-- PROBLEM 9 Calculate Customer Lifetime Value (CLV) and identify high-value customers at risk of churn --
WITH customer_metrics AS (
    SELECT 
        dc.customer_id,
        dc.customer_name,
        dc.customer_type,
        dc.acquisition_date,
        
        -- Order metrics
        COUNT(fs.sale_id) as total_orders,
        SUM(fs.total_amount) as total_spent,
        AVG(fs.total_amount) as avg_order_value,
        
        -- Time metrics
        MIN(dd.full_date) as first_purchase,
        MAX(dd.full_date) as last_purchase,
        DATEDIFF(MAX(dd.full_date), MIN(dd.full_date)) as customer_lifespan_days,
        DATEDIFF(CURDATE(), MAX(dd.full_date)) as days_since_last_purchase
        
    FROM dim_customer dc
    JOIN fact_sales fs ON dc.customer_id = fs.customer_id
    JOIN dim_date dd ON fs.date_id = dd.date_id
    GROUP BY dc.customer_id, dc.customer_name, dc.customer_type, dc.acquisition_date
    HAVING COUNT(fs.sale_id) >= 2 -- Only customers with multiple purchases
),
clv_calculations AS (
    SELECT 
        *,
        -- Simple CLV calculation
        ROUND(
            avg_order_value * 
            (total_orders / GREATEST((customer_lifespan_days / 30.44), 1)) * 
            0.3 * -- Assuming 30% gross margin
            GREATEST((customer_lifespan_days / 30.44), 1),
            2
        ) as calculated_clv,
        
        -- Risk scoring
        CASE 
            WHEN days_since_last_purchase > 180 THEN 'High Risk'
            WHEN days_since_last_purchase > 90 THEN 'Medium Risk'
            ELSE 'Low Risk'
        END as churn_risk,
        
        -- Value segmentation
        NTILE(4) OVER (ORDER BY total_spent) as value_quartile
        
    FROM customer_metrics
)
SELECT 
    customer_id,
    customer_name,
    customer_type,
    total_orders,
    ROUND(total_spent, 2) as total_spent,
    ROUND(avg_order_value, 2) as avg_order_value,
    customer_lifespan_days,
    days_since_last_purchase,
    calculated_clv,
    churn_risk,
    
    CASE value_quartile
        WHEN 4 THEN 'VIP'
        WHEN 3 THEN 'High Value'
        WHEN 2 THEN 'Medium Value'
        ELSE 'Low Value'
    END as customer_segment,
    
    -- Priority scoring for retention efforts
    CASE 
        WHEN value_quartile = 4 AND churn_risk = 'High Risk' THEN 'URGENT - High Value at Risk'
        WHEN value_quartile = 4 AND churn_risk = 'Medium Risk' THEN 'High Priority'
        WHEN value_quartile >= 3 AND churn_risk != 'Low Risk' THEN 'Medium Priority'
        ELSE 'Low Priority'
    END as retention_priority
    
FROM clv_calculations
WHERE calculated_clv > 500 -- Focus on customers with CLV > $500
ORDER BY calculated_clv DESC, days_since_last_purchase DESC
LIMIT 100;


-- PROBLEM 10 Analyze sales performance across multiple dimensions with statistical measures and recommendations --
WITH sales_attribution AS (
    SELECT 
        dsr.sales_rep_id,
        dsr.rep_name,
        dsr.territory,
        dsr.performance_tier,
        dp.product_category,
        dd.quarter,
        fs.total_amount,
        fs.profit_margin,
        
        -- Performance ratios
        fs.profit_margin / NULLIF(fs.total_amount, 0) as profit_ratio
        
    FROM fact_sales fs
    JOIN dim_sales_rep dsr ON fs.sales_rep_id = dsr.sales_rep_id
    JOIN dim_product dp ON fs.product_id = dp.product_id
    JOIN dim_date dd ON fs.date_id = dd.date_id
    WHERE dd.year = 2024
),
performance_benchmarks AS (
    SELECT 
        AVG(total_amount) as avg_sale_amount,
        AVG(profit_ratio) as avg_profit_ratio,
        STDDEV(total_amount) as stddev_sale_amount
    FROM sales_attribution
),
rep_performance AS (
    SELECT 
        sales_rep_id,
        rep_name,
        territory,
        performance_tier,
        product_category,
        COUNT(*) as sales_count,
        SUM(total_amount) as total_revenue,
        AVG(total_amount) as avg_deal_size,
        AVG(profit_ratio) as avg_profit_ratio,
        
        -- Performance vs benchmark (Z-score)
        (AVG(total_amount) - (SELECT avg_sale_amount FROM performance_benchmarks)) / 
        NULLIF((SELECT stddev_sale_amount FROM performance_benchmarks), 0) as deal_size_z_score,
        
        -- High-value deal success rate
        SUM(CASE WHEN total_amount > 2 * (SELECT avg_sale_amount FROM performance_benchmarks) 
                THEN 1 ELSE 0 END) as high_value_deals
        
    FROM sales_attribution
    GROUP BY sales_rep_id, rep_name, territory, performance_tier, product_category
)
SELECT 
    rep_name,
    territory,
    performance_tier,
    product_category,
    sales_count,
    ROUND(total_revenue, 2) as total_revenue,
    ROUND(avg_deal_size, 2) as avg_deal_size,
    ROUND(avg_profit_ratio * 100, 2) as avg_profit_margin_pct,
    ROUND(deal_size_z_score, 2) as performance_z_score,
    high_value_deals,
    
    -- Performance rating
    CASE 
        WHEN deal_size_z_score > 1.5 AND high_value_deals > 5 THEN 'Top Performer'
        WHEN deal_size_z_score > 0.5 THEN 'Above Average'
        WHEN deal_size_z_score > -0.5 THEN 'Average'
        ELSE 'Below Average'
    END as performance_rating,
    
    -- Automated recommendations
    CASE 
        WHEN deal_size_z_score < -1 AND performance_tier != 'Trainee' 
            THEN 'Needs coaching and support'
        WHEN high_value_deals = 0 
            THEN 'Focus on enterprise deals'
        WHEN avg_profit_ratio < 0.1 
            THEN 'Improve pricing strategy'
        ELSE 'Continue current approach'
    END as recommendation
    
FROM rep_performance
WHERE sales_count >= 10 -- Minimum sample size for statistical significance
ORDER BY total_revenue DESC, performance_z_score DESC
LIMIT 50;

