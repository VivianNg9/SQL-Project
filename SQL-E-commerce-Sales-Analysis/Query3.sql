-- 3. Customer Value, behavior & CLV-like signals--
-- 3.1. Loyalty tiers based on order count--

WITH customer_order_counts AS (
    SELECT
        customer_id,
        COUNT(DISTINCT order_id) AS order_count
    FROM v_orders_enriched
    GROUP BY customer_id
),
tiered_orders AS (
    SELECT
        v.*,
        c.order_count,
        CASE
            WHEN c.order_count = 1              THEN 'One-time'
            WHEN c.order_count BETWEEN 2 AND 4  THEN 'Occasional (2–4)'
            ELSE 'Frequent (5+)'
        END AS tier
    FROM v_orders_enriched v
    JOIN customer_order_counts c USING (customer_id)
),
agg AS (
    SELECT
        tier,
        COUNT(DISTINCT customer_id) AS customers,
        SUM(sales)                  AS sales,
        SUM(profit)                 AS profit
    FROM tiered_orders
    GROUP BY tier
)
SELECT
    tier,
    customers,
    sales,
    profit,
    ROUND(100.0 * profit / NULLIF(sales, 0), 2) AS margin_pct,
    ROUND(100.0 * sales / SUM(sales) OVER (), 2) AS sales_share_pct
FROM agg
ORDER BY sales DESC;

-- 3.2. RFM segmentation--
WITH max_date AS (
    SELECT MAX(order_date) AS max_order_date FROM v_orders_enriched
),
rfm AS (
    SELECT
        customer_id,
        MAX(order_date)      AS last_order_date,
        COUNT(DISTINCT order_id) AS frequency,
        SUM(sales)           AS monetary
    FROM v_orders_enriched
    GROUP BY customer_id
),
rfm_scored AS (
    SELECT
        r.*,
        (SELECT max_order_date FROM max_date) - r.last_order_date AS recency_days,
        NTILE(3) OVER (ORDER BY (SELECT max_order_date FROM max_date) - r.last_order_date ASC) AS r_score,  -- recent is good
        NTILE(3) OVER (ORDER BY frequency ASC)   AS f_score,
        NTILE(3) OVER (ORDER BY monetary ASC)    AS m_score
    FROM rfm r
),
rfm_bucketed AS (
    SELECT
        customer_id,
        (r_score + f_score + m_score) AS rfm_score
    FROM rfm_scored
)
SELECT
    CASE
        WHEN rfm_score >= 8 THEN 'High'
        WHEN rfm_score >= 6 THEN 'Medium'
        ELSE 'Low'
    END AS rfm_bucket,
    COUNT(DISTINCT customer_id)    AS customers,
    SUM(sales)                     AS sales,
    SUM(profit)                    AS profit,
    ROUND(100.0 * SUM(profit) / NULLIF(SUM(sales), 0), 2) AS margin_pct,
    ROUND(100.0 * SUM(sales) / SUM(SUM(sales)) OVER (), 2) AS sales_share_pct
FROM rfm_bucketed b
JOIN v_orders_enriched v USING (customer_id)
GROUP BY
    CASE
        WHEN rfm_score >= 8 THEN 'High'
        WHEN rfm_score >= 6 THEN 'Medium'
        ELSE 'Low'
    END
ORDER BY sales DESC;


--3.3. Toxic high-revenue customers--
WITH customer_perf AS (
    SELECT
        customer_id,
        customer_name,
        COUNT(DISTINCT order_id) AS n_orders,
        SUM(sales)               AS sales,
        SUM(profit)              AS profit
    FROM v_orders_enriched
    GROUP BY customer_id, customer_name
)
SELECT
    customer_id,
    customer_name,
    n_orders,
    sales,
    profit
FROM customer_perf
WHERE sales > 5000        -- high revenue
  AND profit < 0          -- but losing money
ORDER BY sales DESC;


