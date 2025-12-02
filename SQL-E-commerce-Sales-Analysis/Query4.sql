--4. Product portfolio--
--4.1. Category & subcategory profit drivers--

-- Category-level
SELECT
    category_group,
    SUM(sales)  AS sales,
    SUM(profit) AS profit,
    ROUND(100.0 * SUM(profit) / NULLIF(SUM(sales), 0), 2) AS margin_pct
FROM v_orders_enriched
GROUP BY category_group
ORDER BY sales DESC;

-- Subcategory-level
SELECT
    subcategory,
    SUM(sales)  AS sales,
    SUM(profit) AS profit,
    ROUND(100.0 * SUM(profit) / NULLIF(SUM(sales), 0), 2) AS margin_pct
FROM v_orders_enriched
GROUP BY subcategory
ORDER BY profit ASC;   -- start with worst
