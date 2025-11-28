/*
===========================================================================================
Stored Procedure: silver.load_silver
===========================================================================================
Script purpose: 
	Loads raw source data into Silver Layer from external csv files.

Process: 
	1. Truncates the targe silver tables to ensure a clean load.
	2. Uses BULK INSERT to load data from the source CSV files into silverschema. 

Input parameters:
	None

Output: 
	This procedure does not return values. It performs data load operations only.

Usage: 
	EXEC silver.load_silver;
==========================================================================================
*/

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME; 
    BEGIN TRY
        SET @batch_start_time = GETDATE();
        PRINT '================================================';
        PRINT 'Loading Silver Layer';
        PRINT '================================================';

		PRINT '------------------------------------------------';
		PRINT 'Loading CRM Tables';
		PRINT '------------------------------------------------';

 -- Loading silver.crm_cust_info
        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.crm_cust_info';
		TRUNCATE TABLE silver.crm_cust_info;
		PRINT '>> Inserting Data Into: silver.crm_cust_info';
		INSERT INTO silver.crm_cust_info (
			cst_id, 
			cst_key, 
			cst_firstname, 
			cst_lastname, 
			cst_marital_status, 
			cst_gndr,
			cst_create_date
		)
		SELECT
			cst_id,
			cst_key,
			TRIM(cst_firstname) AS cst_firstname,
			TRIM(cst_lastname) AS cst_lastname,
			CASE 
				WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
				WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
				ELSE 'n/a'
			END AS cst_marital_status, -- Normalize marital status values to readable format
			cst_gndr, -- Normalize gender values to readable format
			cst_create_date
		FROM (
			SELECT
				*,
				ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
			FROM bronze.crm_cust_info
			WHERE cst_id IS NOT NULL
		) t
		WHERE flag_last = 1; -- Select the most recent record per customer
		SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

		-- Loading silver.crm_prd_info
        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.crm_prd_info';
		TRUNCATE TABLE silver.crm_prd_info;
		PRINT '>> Inserting Data Into: silver.crm_prd_info';
		INSERT INTO silver.crm_prd_info (
			prd_id,
			prd_key,
			prd_nm,
			prd_cost,
			prd_line,
			prd_start_dt,
			prd_end_dt
		)
			SELECT
				prd_id,
				SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,
				prd_nm,
				ISNULL(prd_cost, 0) AS prd_cost,
				CASE 
				WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
				WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
				WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
				WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
				ELSE 'n/a'
			END AS prd_line, -- Map product line codes to descriptive values
			CAST(prd_start_dt AS DATE) AS prd_start_dt,
			CAST(
				LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) - 1 
				AS DATE
			) AS prd_end_dt -- Calculate end date as one day before the next start date
		FROM bronze.crm_prd_info;
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

SELECT*FROM silver.crm_prd_info

        -- Loading crm_sales_details
			PRINT '>>Update Table silver.crm_sales_details  to fit with our new data cleansing'
			IF OBJECT_ID ('silver.crm_sales_details', 'U') IS NOT NULL
				DROP TABLE silver.crm_sales_details;
			CREATE TABLE silver.crm_sales_details (
					sls_ord_num  NVARCHAR(50),
					sls_prd_key  NVARCHAR(50),
					sls_cust_id  INT,
					sls_order_dt DATE,
					sls_ship_dt  DATE,
					sls_due_dt   DATE,
					sls_sales    INT,
					sls_quantity INT,
					sls_price    INT,
					dwh_create_date DATETIME2 DEFAULT GETDATE()
				);
				PRINT '>> Truncating Table: silver.crm_sales_details';
				TRUNCATE TABLE silver.crm_sales_details;
				PRINT '>> Inserting Data Into: silver.crm_sales_details';
				INSERT INTO silver.crm_sales_details (
					sls_ord_num,
					sls_prd_key,
					sls_cust_id,
					sls_order_dt,
					sls_ship_dt,
					sls_due_dt,
					sls_sales,
					sls_quantity,
					sls_price
				)
				SELECT
					sls_ord_num,
					sls_prd_key,
					sls_cust_id,
					-- Order Date
					CASE 
						WHEN sls_order_dt IS NULL OR sls_order_dt <= 0 OR LEN(CAST(sls_order_dt AS VARCHAR)) != 8 
							THEN NULL
						ELSE TRY_CAST(
							SUBSTRING(CAST(sls_order_dt AS VARCHAR(8)), 5, 4) + '-' +
							SUBSTRING(CAST(sls_order_dt AS VARCHAR(8)), 1, 2) + '-' +
							SUBSTRING(CAST(sls_order_dt AS VARCHAR(8)), 3, 2) 
							AS DATE
						)
					END,
					-- Ship Date
					CASE 
						WHEN sls_ship_dt IS NULL OR sls_ship_dt <= 0 OR LEN(CAST(sls_ship_dt AS VARCHAR)) != 8 
							THEN NULL
						ELSE TRY_CAST(
							SUBSTRING(CAST(sls_ship_dt AS VARCHAR(8)), 5, 4) + '-' +
							SUBSTRING(CAST(sls_ship_dt AS VARCHAR(8)), 1, 2) + '-' +
							SUBSTRING(CAST(sls_ship_dt AS VARCHAR(8)), 3, 2) 
							AS DATE
						)
					END,
					-- Due Date
					CASE 
						WHEN sls_due_dt IS NULL OR sls_due_dt <= 0 OR LEN(CAST(sls_due_dt AS VARCHAR)) != 8 
							THEN NULL
						ELSE TRY_CAST(
							SUBSTRING(CAST(sls_due_dt AS VARCHAR(8)), 5, 4) + '-' +
							SUBSTRING(CAST(sls_due_dt AS VARCHAR(8)), 1, 2) + '-' +
							SUBSTRING(CAST(sls_due_dt AS VARCHAR(8)), 3, 2) 
							AS DATE
						)
					END,
					-- Sales
					CASE 
						WHEN sls_sales <= 0 OR sls_sales IS NULL OR sls_sales != sls_quantity * ABS(sls_price)
							THEN sls_quantity * ABS(sls_price)
						ELSE sls_sales
					END,
					sls_quantity,
					-- Price
					CASE 
						WHEN sls_price <= 0 OR sls_price IS NULL 
							THEN sls_sales / NULLIF(sls_quantity,0)
						ELSE sls_price
					END
				FROM bronze.crm_sales_details;

		-- Loading erp_cust_az12
			SET @start_time = GETDATE();
			PRINT '>> Truncating Table: [silver].[erp_cust_az12]';
				TRUNCATE TABLE [silver].[erp_cust_az12];
				PRINT '>> Inserting Data Into: [silver].[erp_cust_az12]';
				INSERT INTO [silver].[erp_cust_az12] (
						cid,
						bdate,
						gen
				)
				SELECT 
				CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
					 ELSE cid
				END AS cid,
				CASE WHEN bdate > GETDATE() THEN NULL
					ELSE bdate
				END AS bdate,
				CASE WHEN TRIM(UPPER(gen)) IN ('F','Female') THEN 'Female'
					 WHEN TRIM(UPPER(gen)) IN ('M','Male') THEN 'Male'
					 ELSE 'N/a'
				END AS gen
				FROM [bronze].[erp_cust_az12]
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '>> -------------';


        -- Loading erp_loc_a101
        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.erp_loc_a101';
		TRUNCATE TABLE silver.erp_loc_a101;
		PRINT '>> Inserting Data Into: silver.erp_loc_a101';
		INSERT INTO silver.erp_loc_a101 (
			cid,
			cntry
		)
		SELECT
			REPLACE(cid, '-', '') AS cid, 
			CASE
				WHEN TRIM(cntry) = 'DE' THEN 'Germany'
				WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
				WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
				ELSE TRIM(cntry)
			END AS cntry -- Normalize and Handle missing or blank country codes
		FROM bronze.erp_loc_a101;
	    SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

		-- Loading erp_px_cat_g1v2
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.erp_px_cat_g1v2';
		TRUNCATE TABLE silver.erp_px_cat_g1v2;
		PRINT '>> Inserting Data Into: silver.erp_px_cat_g1v2';
		INSERT INTO silver.erp_px_cat_g1v2 (
			id,
			cat,
			subcat,
			maintenance
		)
		SELECT
			id,
			cat,
			subcat,
			maintenance
		FROM bronze.erp_px_cat_g1v2;
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

		SET @batch_end_time = GETDATE();
		PRINT '=========================================='
		PRINT 'Loading Silver Layer is Completed';
        PRINT '   - Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
		PRINT '=========================================='
		
	END TRY
	BEGIN CATCH
		PRINT '=========================================='
		PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER'
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Message' + CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error Message' + CAST (ERROR_STATE() AS NVARCHAR);
		PRINT '=========================================='
	END CATCH
END

