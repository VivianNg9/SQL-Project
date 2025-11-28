/*
===============================================================================
DDL Script: Create Gold Layer Views
===============================================================================
Purpose:
    This script defines and creates views for the Gold layer of the data warehouse. 
    The Gold layer serves as the presentation layer, containing the final 
    dimension and fact tables structured in a Star Schema.

Overview:
    - Each view applies business logic and transformations on top of the Silver layer.
    - The resulting views deliver clean, enriched, and analytics-ready datasets.

Usage:
    - Execute this script after all Silver layer transformations are complete.
    - The generated Gold views are intended for direct use in analytics, BI, 
      and reporting applications.
===============================================================================

-- View Creation: gold.dim_customers
-- Description: Defines the Customer Dimension view with standardized and 
--              enriched customer attributes.
*/

IF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL
    DROP VIEW gold.dim_customers;
GO

CREATE VIEW gold.dim_customers AS
SELECT
    ROW_NUMBER() OVER (ORDER BY cst_id) AS customer_key, -- Surrogate key
    ci.cst_id                          AS customer_id,
    ci.cst_key                         AS customer_number,
    ci.cst_firstname                   AS first_name,
    ci.cst_lastname                    AS last_name,
    la.cntry                           AS country,
    ci.cst_marital_status              AS marital_status,
    CASE 
        WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- CRM is the primary source for gender
        ELSE COALESCE(ca.gen, 'n/a')  			   -- Fallback to ERP data
    END                                AS gender,
    ca.bdate                           AS birthdate,
    ci.cst_create_date                 AS create_date
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
    ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la
    ON ci.cst_key = la.cid;
GO


-- Add new column (cat_id) to store the product category ID 
ALTER TABLE silver.crm_prd_info
ADD cat_id VARCHAR(20);
-- Fill the new column with the first two parts of prd_key
UPDATE silver.crm_prd_info
SET cat_id = LEFT(prd_key, CHARINDEX('-', prd_key) - 1) 
             + '-' + 
             SUBSTRING(prd_key, CHARINDEX('-', prd_key) + 1, 
                       CHARINDEX('-', prd_key, CHARINDEX('-', prd_key) + 1) - CHARINDEX('-', prd_key) - 1);
SELECT*FROM silver.crm_prd_info
SELECT prd_key,
       LEFT(prd_key, CHARINDEX('-', prd_key) - 1) 
       + '-' + 
       SUBSTRING(
           prd_key,
           CHARINDEX('-', prd_key) + 1,
           CHARINDEX('-', prd_key, CHARINDEX('-', prd_key) + 1) - CHARINDEX('-', prd_key) - 1
       ) AS cat_id
FROM silver.crm_prd_info
WHERE prd_key LIKE '%-%-%-%';
-- =============================================================================
-- Create Dimension: gold.dim_products
-- =============================================================================
IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
    DROP VIEW gold.dim_products
GO

CREATE VIEW gold.dim_products AS
SELECT
    ROW_NUMBER() OVER (ORDER BY pn.prd_start_dt, pn.prd_key) AS product_key, -- Surrogate key
    pn.prd_id       AS product_id,
    pn.prd_key      AS product_number,
    pn.prd_nm       AS product_name,
    pn.cat_id       AS category_id,
    pc.cat          AS category,
    pc.subcat       AS subcategory,
    pc.maintenance  AS maintenance,
    pn.prd_cost     AS cost,
    pn.prd_line     AS product_line,
    pn.prd_start_dt AS start_date
FROM silver.crm_prd_info pn
LEFT JOIN silver.erp_px_cat_g1v2 pc
    ON pn.cat_id = pc.id
WHERE pn.prd_end_dt IS NULL; -- Filter out all historical data
GO

-- =============================================================================
-- Create Fact Table: gold.fact_sales
-- =============================================================================
IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
    DROP VIEW gold.fact_sales;
GO

CREATE VIEW gold.fact_sales AS
SELECT
    sd.sls_ord_num  AS order_number,
    pr.product_key  AS product_key,
    cu.customer_key AS customer_key,
    sd.sls_order_dt AS order_date,
    sd.sls_ship_dt  AS shipping_date,
    sd.sls_due_dt   AS due_date,
    sd.sls_sales    AS sales_amount,
    sd.sls_quantity AS quantity,
    sd.sls_price    AS price
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_products pr
    ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers cu
    ON sd.sls_cust_id = cu.customer_id;
GO