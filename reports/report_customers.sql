/*
===============================================================================================
Customer Report
===============================================================================================
Purpose:
	- This report consolidates key customer metrics and behaviours

Highlights:
	1. Gathers essential fields such as names, ages, and transaction details.
	2. Segments customers into categories (VIP, Regular, New) and age groups.
	3. Aggregates customer-level metrics:
		- total orders
		- total sales
		- total quantity purchased
		- total products
		- lifespan (in months)
	4. Calculating valuable KPIs:
		- recency (month since last order)
		- average order value
		- average monthly spend
===================================================================================================
*/
CREATE VIEW gold.report_customers AS
WITH base_query AS (
/* ------------------------------------------------------------------------------------------------
1) Base Query: Retrieve core columns from the tables
-------------------------------------------------------------------------------------------------*/
SELECT
f.order_number,
f.product_key,
f.order_date,
f.sales_amount,
f.quantity,
c.customer_key,
c.customer_number,
CONCAT_WS(' ', c.first_name, c.last_name) AS customer,
DATEDIFF(YEAR, c.birthdate, GETDATE()) AS age
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
	ON f.customer_key = c.customer_key
WHERE f.order_date IS NOT NULL
),
customer_aggregations AS (
/*-------------------------------------------------------------------------------------------------------
2) Customer Aggregations: Summarizes key metrics at the customer level
-------------------------------------------------------------------------------------------------------*/
SELECT
	customer_key,
	customer_number,
	customer,
	age,
	COUNT(DISTINCT order_number) AS nr_of_orders,
	SUM(sales_amount) AS total_sales,
	SUM(quantity) AS total_quantity,
	COUNT(DISTINCT product_key) AS nr_of_products,
	MAX(order_date) AS last_order_date,
	DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan
FROM base_query
GROUP BY
customer_key,
customer_number,
customer,
age
)
SELECT
customer_key,
customer_number,
customer,
age,
CASE WHEN age < 20 THEN 'Under 20'
	 WHEN age BETWEEN 20 AND 29 THEN '20-29'
	 WHEN age BETWEEN 30 AND 39 THEN '30-39'
	 WHEN age BETWEEN 30 AND 39 THEN '30-39'
	 WHEN age BETWEEN 40 AND 49 THEN '30-39'
	 ELSE '50 and above'
END AS age_group,
CASE
	WHEN lifespan >= 12 AND total_sales > 5000 THEN 'VIP'
	WHEN lifespan >= 12 AND total_sales <= 5000 THEN 'Regular'
	ELSE 'New'
END AS customer_segment,
DATEDIFF(MONTH, last_order_date, GETDATE()) AS recency,
nr_of_orders,
total_sales,
total_quantity,
nr_of_products,
last_order_date,
lifespan,
-- Compute average order value (AVO)
CASE WHEN nr_of_orders = 0 THEN 0
	 ELSE total_sales / nr_of_orders
END AS avg_order_value,
-- Compute average monthly spend
CASE WHEN lifespan = 0 THEN total_sales
	 ELSE total_sales / lifespan
END AS avg_monthly_spend
FROM customer_aggregations;
