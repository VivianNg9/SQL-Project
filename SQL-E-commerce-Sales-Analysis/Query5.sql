-- 5. Operations & Shipping performance--
-- 5.1. Shipping mode--

SELECT
    ship_mode,
    COUNT(DISTINCT order_id)                    AS orders,
    SUM(sales)                                  AS sales,
    SUM(profit)                                 AS profit,
    ROUND(AVG(lead_days), 2)                    AS avg_lead_days,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY lead_days) AS median_lead_days,
    ROUND(100.0 * SUM(profit) / NULLIF(SUM(sales), 0), 2) AS margin_pct
FROM v_orders_enriched
GROUP BY ship_mode
ORDER BY sales DESC;

--5.2. Region & Shiping Mode--
WITH rs AS (
    SELECT
        customer_region AS region,
        ship_mode,
        SUM(sales)  AS sales,
        SUM(profit) AS profit,
        AVG(lead_days) AS avg_lead
    FROM v_orders_enriched
    GROUP BY customer_region, ship_mode
)
SELECT
    region,
    ship_mode,
    sales,
    profit,
    ROUND(avg_lead, 2) AS avg_lead_days,
    ROUND(100.0 * profit / NULLIF(sales, 0), 2) AS margin_pct
FROM rs
ORDER BY region, ship_mode;

