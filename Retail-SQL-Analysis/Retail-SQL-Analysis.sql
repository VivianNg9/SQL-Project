
CREATE TABLE customers (
    ID VARCHAR (20) PRIMARY KEY,
    NAME VARCHAR(100),
    SEGMENT VARCHAR(50),
    COUNTRY VARCHAR(50),
    CITY VARCHAR(50),
    STATE VARCHAR(50),
    POSTAL_CODE INT,
    REGION VARCHAR(50)
);

CREATE TABLE employees (
    ID_EMPLOYEE INT PRIMARY KEY,
    NAME VARCHAR(100),
    CITY VARCHAR(50),
    REGION VARCHAR(50)
);

CREATE TABLE product (
    ID VARCHAR(100) PRIMARY KEY,
    NAME VARCHAR(50),
    CATEGORY VARCHAR(50),
    SUBCATEGORY VARCHAR(200)
);

SELECT * FROM product


CREATE TABLE orders (
    ROW_ID INT PRIMARY KEY,
    ORDER_ID VARCHAR(20),
    ORDER_DATE TEXT,
    SHIP_DATE TEXT,
    SHIP_MODE VARCHAR(50),
    CUSTOMER_ID VARCHAR REFERENCES customers(ID),
    PRODUCT_ID VARCHAR REFERENCES product(ID),
    SALES NUMERIC,
    QUANTITY INT,
    DISCOUNT NUMERIC,
    PROFIT NUMERIC,
    ID_EMPLOYEE INT REFERENCES employees(ID_EMPLOYEE)
);


/* The total sales of furniture products, grouped by each quarter of the year, and order the results chronologically.*/

SELECT 
    CONCAT('Q', EXTRACT(QUARTER FROM CAST(ORDER_DATE AS DATE)), '-', EXTRACT(YEAR FROM CAST(ORDER_DATE AS DATE))) AS Quarter_Year,
    SUM(SALES) AS Total_Sales
FROM 
    orders 
JOIN 
    product 
ON 
    orders.PRODUCT_ID = product.ID
WHERE 
    product.NAME = 'Furniture'
GROUP BY 
    EXTRACT(YEAR FROM CAST(ORDER_DATE AS DATE)), EXTRACT(QUARTER FROM CAST(ORDER_DATE AS DATE))
ORDER BY 
    EXTRACT(YEAR FROM CAST(ORDER_DATE AS DATE)), EXTRACT(QUARTER FROM CAST(ORDER_DATE AS DATE));


/* The impact of different discount levels on sales performance across product categories,
specifically looking at the number of orders and total profit generated for each discount classification*/


SELECT 
    product.CATEGORY AS Category,
    CASE 
        WHEN DISCOUNT = 0 THEN 'No Discount'
        WHEN DISCOUNT > 0 AND DISCOUNT <= 0.2 THEN 'Low Discount'
        WHEN DISCOUNT > 0.2 AND DISCOUNT <= 0.5 THEN 'Medium Discount'
        WHEN DISCOUNT > 0.5 THEN 'High Discount'
    END AS Discount_Level,
    COUNT(orders.ROW_ID) AS Total_Orders,
    SUM(orders.PROFIT) AS Total_Profit
FROM 
    orders 
JOIN 
    product 
ON 
    orders.PRODUCT_ID = product.ID
GROUP BY 
    product.CATEGORY,
    CASE 
        WHEN DISCOUNT = 0 THEN 'No Discount'
        WHEN DISCOUNT > 0 AND DISCOUNT <= 0.2 THEN 'Low Discount'
        WHEN DISCOUNT > 0.2 AND DISCOUNT <= 0.5 THEN 'Medium Discount'
        WHEN DISCOUNT > 0.5 THEN 'High Discount'
    END
ORDER BY 
    product.CATEGORY, 
    Discount_Level;


/* The top-performing product categories within each customer segment based on sales and profit, 
focusing specifically on these categories that rank within the top two for profitability"*/

WITH SegmentCategoryPerformance AS (
    SELECT 
        customers.SEGMENT AS Segment,
        product.CATEGORY AS Category,
        SUM(orders.SALES) AS Total_Sales,
        SUM(orders.PROFIT) AS Total_Profit
    FROM 
        orders 
    JOIN 
        customers 
    ON 
        orders.CUSTOMER_ID = customers.ID
    JOIN 
        product 
    ON 
        orders.PRODUCT_ID = product.ID
    GROUP BY 
        customers.SEGMENT, product.CATEGORY
),
RankedPerformance AS (
    SELECT 
        Segment,
        Category,
        Total_Sales,
        Total_Profit,
        RANK() OVER (PARTITION BY Segment ORDER BY Total_Profit DESC) AS Profit_Rank,
        RANK() OVER (PARTITION BY Segment ORDER BY Total_Sales DESC) AS Sales_Rank
    FROM 
        SegmentCategoryPerformance
)
SELECT 
    Segment,
    Category,
    Sales_Rank,
    Profit_Rank
FROM 
    RankedPerformance
WHERE 
    Profit_Rank <= 2
ORDER BY 
    Segment, Profit_Rank;


/* Each employee's performance across different product categories, 
showing not only the total profit per category but also what percentage of 
their total profit each category represents, with the results ordered by 
the percentage in descending order for each employee"*/


WITH EmployeeCategoryProfit AS (
    SELECT 
        employees.ID_EMPLOYEE AS ID_EMPLOYEE,
        product.CATEGORY AS CATEGORY,
        COALESCE(SUM(orders.PROFIT), 0) AS Total_Profit
    FROM 
        orders 
    JOIN 
        employees 
    ON 
        orders.ID_EMPLOYEE = employees.ID_EMPLOYEE
    JOIN 
        product 
    ON 
        orders.PRODUCT_ID = product.ID
    GROUP BY 
        employees.ID_EMPLOYEE, product.CATEGORY
),
EmployeeTotalProfit AS (
    SELECT 
        ID_EMPLOYEE,
        COALESCE(SUM(Total_Profit), 0) AS Total_Employee_Profit
    FROM 
        EmployeeCategoryProfit
    GROUP BY 
        ID_EMPLOYEE
)
SELECT 
    ecp.ID_EMPLOYEE,
    ecp.CATEGORY,
    ROUND(ecp.Total_Profit, 2) AS Rounded_Total_Profit,
    ROUND(CASE 
        WHEN etp.Total_Employee_Profit = 0 THEN 0
        ELSE (ecp.Total_Profit / etp.Total_Employee_Profit) * 100
    END, 2) AS Profit_Percentage
FROM 
    EmployeeCategoryProfit ecp
JOIN 
    EmployeeTotalProfit etp
ON 
    ecp.ID_EMPLOYEE = etp.ID_EMPLOYEE
ORDER BY 
    ecp.ID_EMPLOYEE, Profit_Percentage DESC;


/* Develop a user-defined function to calculate the profitability ratio for 
each product category an employee has sold, and then apply this function to 
generate a report that ranks each employee's product categories by their profitablitiy ratio"*/

CREATE OR REPLACE FUNCTilitCalculateProfitabilityRatio(
    TotalSales NUMERIC,
    TotalProfit NUMERIC
) RETURNS NUMERIC AS $$
BEGIN
    RETURN CASE 
        WHEN TotalSales = 0 THEN 0
        ELSE (TotalProfit / TotalSales)
    END;
END;
$$ LANGUAGE plpgsql;


WITH EmployeeCategoryPerformance AS (
    SELECT 
        employees.ID_EMPLOYEE AS ID_EMPLOYEE,
        product.CATEGORY AS CATEGORY,
        SUM(orders.SALES) AS Total_Sales,
        SUM(orders.PROFIT) AS Total_Profit
    FROM 
        orders 
    JOIN 
        employees 
    ON 
        orders.ID_EMPLOYEE = employees.ID_EMPLOYEE
    JOIN 
        product 
    ON 
        orders.PRODUCT_ID = product.ID
    GROUP BY 
        employees.ID_EMPLOYEE, product.CATEGORY
)
SELECT 
    ecp.ID_EMPLOYEE,
    ecp.CATEGORY,
    ROUND(ecp.Total_Sales, 2) AS Total_Sales,
    ROUND(ecp.Total_Profit, 2) AS Total_Profit,
    ROUND(CalculateProfitabilityRatio(ecp.Total_Sales, ecp.Total_Profit), 2) AS Profitability_Ratio
FROM 
    EmployeeCategoryPerformance ecp
ORDER BY 
    ecp.ID_EMPLOYEE, Profitability_Ratio DESC;




