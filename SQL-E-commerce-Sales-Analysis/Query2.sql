-- 2. Pricing & Discount (correlation, loss pockets)--
-- 2.1. Discount band performance (global)--
WITH banded AS (
    SELECT
        discount_band,
        sales,
        profit
    FROM v_orders_enriched
),
agg AS (
    SELECT
        discount_band,
        COUNT(*)   AS line_count,
        SUM(sales) AS sales,
        SUM(profit) AS profit
    FROM banded
    GROUP BY discount_band
)
SELECT
    discount_band,
    line_count,
    sales,
    profit,
    ROUND(100.0 * profit / NULLIF(sales, 0), 2) AS margin_pct,
    ROUND(100.0 * sales / SUM(sales) OVER (), 2) AS sales_share_pct
FROM agg
ORDER BY
    CASE discount_band
        WHEN '0%'    THEN 1
        WHEN '0–20%' THEN 2
        WHEN '20–40%' THEN 3
        WHEN '40–60%' THEN 4
        ELSE 5
    END;

--2.2. Discount sensitivity by subcategory (correlation analysis)--

WITH sub_corr AS (
    SELECT
        subcategory,
        corr(discount, profit) AS corr_discount_profit,
        COUNT(*)               AS n_rows
    FROM v_orders_enriched
    GROUP BY subcategory
)
SELECT
    subcategory,
    n_rows,
    ROUND(corr_discount_profit::numeric, 3) AS corr_discount_profit
FROM sub_corr
WHERE n_rows >= 50
ORDER BY corr_discount_profit;   -- most negative first

--2.3. Region × discount bands (structural loss pockets)--
WITH rd AS (
    SELECT
        customer_region AS region,
        discount_band,
        SUM(sales)  AS sales,
        SUM(profit) AS profit
    FROM v_orders_enriched
    GROUP BY customer_region, discount_band
)
SELECT
    region,
    discount_band,
    sales,
    profit,
    ROUND(100.0 * profit / NULLIF(sales, 0), 2) AS margin_pct
FROM rd
ORDER BY region,
    CASE discount_band
        WHEN '0%'    THEN 1
        WHEN '0–20%' THEN 2
        WHEN '20–40%' THEN 3
        WHEN '40–60%' THEN 4
        ELSE 5
    END;
