CREATE OR REPLACE VIEW v_orders_enriched AS
WITH base AS (
    SELECT
        o.row_id,
        o.order_id,
        o.order_date,
        o.ship_date,
        o.ship_mode,
        o.customer_id,
        c.name              AS customer_name,
        c.segment,
        c.city              AS customer_city,
        c.state,
        c.postal_code,
        c.region            AS customer_region,

        o.product_id,
        p.category_group,
        p.subcategory,
        p.product_name,

        o.sales,
        o.quantity,
        o.discount,
        o.profit,

        o.id_employee,
        e.name              AS employee_name,
        e.city              AS employee_city,
        e.region            AS employee_region,

        EXTRACT(YEAR  FROM o.order_date)::int AS order_year,
        EXTRACT(MONTH FROM o.order_date)::int AS order_month,
        (o.ship_date - o.order_date)          AS lead_days,

        CASE
            WHEN o.discount = 0                         THEN '0%'
            WHEN o.discount > 0 AND o.discount <= 0.20  THEN '0–20%'
            WHEN o.discount > 0.20 AND o.discount <= 0.40 THEN '20–40%'
            WHEN o.discount > 0.40 AND o.discount <= 0.60 THEN '40–60%'
            ELSE '60%+'
        END AS discount_band
    FROM orders o
    JOIN customers c ON o.customer_id = c.id
    JOIN product   p ON o.product_id = p.product_id
    JOIN employees e ON o.id_employee = e.id_employee
)
SELECT * FROM base;


--1. Revenue & profit (segment, region, time)--
--1.1. Segement performance--
WITH seg AS (
    SELECT
        segment,
        COUNT(DISTINCT customer_id) AS customers,
        COUNT(DISTINCT order_id)    AS orders,
        SUM(sales)                  AS sales,
        SUM(profit)                 AS profit
    FROM v_orders_enriched
    GROUP BY segment
)
SELECT
    segment,
    customers,
    orders,
    sales,
    profit,
    ROUND(100.0 * profit / NULLIF(sales, 0), 2) AS margin_pct,
    ROUND(100.0 * sales / SUM(sales) OVER (), 2) AS sales_share_pct
FROM seg
ORDER BY sales DESC;

--1.2. Region and Category relationship--
WITH rc AS (
    SELECT
        customer_region AS region,
        category_group,
        SUM(sales)  AS sales,
        SUM(profit) AS profit
    FROM v_orders_enriched
    GROUP BY customer_region, category_group
)
SELECT
    region,
    category_group,
    sales,
    profit,
    ROUND(100.0 * profit / NULLIF(sales, 0), 2) AS margin_pct
FROM rc
ORDER BY region, category_group;

--1.3 Time: monthly seasonality--
WITH m AS (
    SELECT
        order_month,
        SUM(sales)  AS sales,
        SUM(profit) AS profit
    FROM v_orders_enriched
    GROUP BY order_month
)
SELECT
    order_month,
    sales,
    profit,
    ROUND(100.0 * profit / NULLIF(sales, 0), 2) AS margin_pct
FROM m
ORDER BY order_month;

