SELECT * FROM public.financial_loan

--1. KPI's--
--1.1. Total Loan Application--

--Total Loan Applications--
SELECT COUNT(id) AS Total_Loan_Applications FROM public.financial_loan

--Month-to-Date Loan Applications
SELECT COUNT(id) AS MTD_Total_Loan_Applications
FROM public.financial_loan
WHERE EXTRACT(MONTH FROM TO_DATE(issue_date, 'DD-MM_YYYY')) = 12
AND EXTRACT(YEAR FROM TO_DATE(issue_date, 'DD-MM_YYYY')) = 2021;

--Previous Month-to-Date Loan Applications
SELECT COUNT(id) AS PMTD_Total_Loan_Applications
FROM public.financial_loan
WHERE EXTRACT(MONTH FROM TO_DATE(issue_date, 'DD-MM_YYYY')) = 11
AND EXTRACT(YEAR FROM TO_DATE(issue_date, 'DD-MM_YYYY')) = 2021;

--1.2. Total Funded Amount--
--Total Funded Amount-- 
SELECT SUM(loan_amount) AS Total_Funded_Amount FROM public.financial_loan

--Month-to-Date Total Funded Amount--
SELECT SUM(loan_amount) AS MTD_Total_Loan_Applications
FROM public.financial_loan
WHERE EXTRACT(MONTH FROM TO_DATE(issue_date, 'DD-MM_YYYY')) = 12
AND EXTRACT(YEAR FROM TO_DATE(issue_date, 'DD-MM_YYYY')) = 2021;

--Previous Month-to-Date Total Funded Amount--
SELECT SUM(loan_amount) AS PMTD_Total_Funded_Amount 
FROM public.financial_loan
WHERE EXTRACT(MONTH FROM TO_DATE(issue_date, 'DD-MM_YYYY')) = 11
AND EXTRACT(YEAR FROM TO_DATE(issue_date, 'DD-MM_YYYY')) = 2021;

--1.3. Total Amount Received--
--Total Amount Received
SELECT SUM(total_payment) AS Total_Amount_received FROM financial_loan

--Month-to-Date Total Amount Received--
SELECT SUM(total_payment) AS MTD_Total_Amount_Received
FROM public.financial_loan
WHERE EXTRACT(MONTH FROM TO_DATE(issue_date, 'DD-MM_YYYY')) = 12
AND EXTRACT(YEAR FROM TO_DATE(issue_date, 'DD-MM_YYYY')) = 2021;

--Previous Month-to-Date Total Amount Received--
SELECT SUM(total_payment) AS PMTD_Total_Amount_Received
FROM public.financial_loan
WHERE EXTRACT(MONTH FROM TO_DATE(issue_date, 'DD-MM_YYYY')) = 11
AND EXTRACT(YEAR FROM TO_DATE(issue_date, 'DD-MM_YYYY')) = 2021;

--1.4. Average Interest--
--Average Interest Rate--
SELECT ROUND(AVG(int_rate),4) * 100 AS Avg_Interest_Rate FROM financial_loan 

--Month-to-Date Average Interest--
SELECT ROUND(AVG(int_rate),4) *100 AS MTD_Average_Interest
FROM public.financial_loan
WHERE EXTRACT(MONTH FROM TO_DATE(issue_date, 'DD-MM_YYYY')) = 12
AND EXTRACT(YEAR FROM TO_DATE(issue_date, 'DD-MM_YYYY')) = 2021;

--Previous Month-to-Date Average Interest--
SELECT ROUND(AVG(int_rate),4) *100 AS PMTD_Average_Interest
FROM public.financial_loan
WHERE EXTRACT(MONTH FROM TO_DATE(issue_date, 'DD-MM_YYYY')) = 11
AND EXTRACT(YEAR FROM TO_DATE(issue_date, 'DD-MM_YYYY')) = 2021;

--1.5. Average Debt to Income Ratio-- 
-- Average Debt to Income Ratio--
SELECT ROUND(AVG(dti),4) * 100 AS Avg_DTI FROM financial_loan 

--Month-to-Date Average Debt to Income Ratio--
SELECT ROUND(AVG(dti),4) *100 AS MTD_Average_Debt_to_Income_Ratio
FROM public.financial_loan
WHERE EXTRACT(MONTH FROM TO_DATE(issue_date, 'DD-MM_YYYY')) = 12
AND EXTRACT(YEAR FROM TO_DATE(issue_date, 'DD-MM_YYYY')) = 2021;

--Previous Month-to-Date Debt to Income Ratio--
SELECT ROUND(AVG(int_rate),4) *100 AS PMTD_Average_Debt_to_Income_Ratio
FROM public.financial_loan
WHERE EXTRACT(MONTH FROM TO_DATE(issue_date, 'DD-MM_YYYY')) = 11
AND EXTRACT(YEAR FROM TO_DATE(issue_date, 'DD-MM_YYYY')) = 2021;


--2. Good Loan Issued--
--2.1. Good Loan Percentage--
SELECT 
	(COUNT(CASE WHEN loan_status = 'Fully Paid' OR loan_status = 'Current' THEN id
END) * 100.0)/
		COUNT(id) AS Good_Loan_Percentage
FROM public.financial_loan

--2.2. Good Loan Applications--
SELECT COUNT(id) AS Good_Loan_Applications FROM public.financial_loan
WHERE loan_status = 'Fully Paid' OR loan_status = 'Current'

--2.3. Good Loan Funded Amount--
SELECT SUM(loan_amount) AS Good_Loan_Funded_amount FROM public.financial_loan
WHERE loan_status = 'Fully Paid' OR loan_status = 'Current'

--2.4. Good Loan Amount Received--
SELECT SUM(total_payment) AS Good_Loan_Amount_Received FROM public.financial_loan
WHERE loan_status = 'Fully Paid' OR loan_status = 'Current'


--3. Bad Loan Issued--
--3.1. Bad Loan Percentage-- 
SELECT
    (COUNT(CASE WHEN loan_status = 'Charged Off' THEN id END) * 100.0) / 
	COUNT(id) AS Bad_Loan_Percentage
FROM public.financial_loan

--3.2. Bad Loan Applications--
SELECT COUNT(id) AS Bad_Loan_Applications FROM public.financial_loan
WHERE loan_status = 'Charged Off'

--3.3. Bad Loan Funded Amount--
SELECT SUM(loan_amount) AS Bad_Loan_Funded_Amount FROM public.financial_loan
WHERE loan_status = 'Charged Off'

--3.4. Bad Loan Amount Recieved-- 
SELECT SUM(total_payment) AS Bad_Loan_Amount_Received FROM public.financial_loan
WHERE loan_status = 'Charged Off'


--4. Loan Status-- 
SELECT
	loan_status,
	COUNT(id) AS Loan_Count,
    SUM(total_payment) AS Total_Amount_Received,
    SUM(loan_amount) AS Total_Funded_Amount,
        AVG(int_rate * 100) AS Interest_Rate,
        AVG(dti * 100) AS DTI
    FROM
        public.financial_loan
    GROUP BY
        loan_status

SELECT 
	loan_status,
	SUM(total_payment) AS MTD_Total_Amount_Received, 
	SUM(loan_amount) AS MTD_Total_Funded_Amount
FROM public.financial_loan
WHERE EXTRACT(MONTH FROM TO_DATE(issue_date, 'DD-MM_YYYY')) = 12
GROUP BY loan_status


--5. By Month--
SELECT 
    EXTRACT(MONTH FROM TO_DATE(issue_date, 'DD-MM_YYYY')) AS Month_Number,
    TO_CHAR(TO_DATE(issue_date, 'DD-MM_YYYY'), 'Month') AS Month_Name, 
	COUNT(id) AS Total_Loan_Applications,
	SUM(loan_amount) AS Total_Funded_Amount,
	SUM(total_payment) AS Total_Amount_Received
FROM public.financial_loan
GROUP BY 
    EXTRACT(MONTH FROM TO_DATE(issue_date, 'DD-MM_YYYY')),
    TO_CHAR(TO_DATE(issue_date, 'DD-MM_YYYY'), 'Month')
ORDER BY Month_Number;


--6. By State--
SELECT 
	address_state AS State, 
	COUNT(id) AS Total_Loan_Applications,
	SUM(loan_amount) AS Total_Funded_Amount,
	SUM(total_payment) AS Total_Amount_Received
FROM public.financial_loan
GROUP BY address_state
ORDER BY address_state


--7. By Term--
SELECT 
	term AS Term, 
	COUNT(id) AS Total_Loan_Applications,
	SUM(loan_amount) AS Total_Funded_Amount,
	SUM(total_payment) AS Total_Amount_Received
FROM public.financial_loan
GROUP BY term
ORDER BY term



--8. By Employee Length--
SELECT 
	emp_length AS Employee_Length, 
	COUNT(id) AS Total_Loan_Applications,
	SUM(loan_amount) AS Total_Funded_Amount,
	SUM(total_payment) AS Total_Amount_Received
FROM public.financial_loan
GROUP BY emp_length
ORDER BY emp_length


--9. By Purpose-- 
SELECT 
	purpose AS PURPOSE, 
	COUNT(id) AS Total_Loan_Applications,
	SUM(loan_amount) AS Total_Funded_Amount,
	SUM(total_payment) AS Total_Amount_Received
FROM public.financial_loan
GROUP BY purpose
ORDER BY purpose


--10. By Home Ownership--
SELECT 
	home_ownership AS Home_Ownership, 
	COUNT(id) AS Total_Loan_Applications,
	SUM(loan_amount) AS Total_Funded_Amount,
	SUM(total_payment) AS Total_Amount_Received
FROM public.financial_loan
GROUP BY home_ownership
ORDER BY home_ownership



