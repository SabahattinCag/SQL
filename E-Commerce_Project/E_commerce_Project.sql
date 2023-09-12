
/*
E-Commerce Data and Customer Retention Analysis with SQL
_________________________________________________________
An e-commerce organization demands some analysis of sales and shipping
processes. Thus, the organization hopes to be able to predict more easily the
opportunities and threats for the future.
Acording to this scenario, You are asked to make the following analyzes consistant
with following the instructions given.
Introduction
- You have to create a database and import into the given csv file. (You should
research how to import a .csv file)
- During the import process, you will need to adjust the date columns. You need
to carefully observe the data types and how they should be.
- The data are not very clean and fully normalized. However, they don't prevent
you from performing the given tasks.
- Manually verify the accuracy of your analysis.
Analyze the data by finding the answers to the questions below:
*/

CREATE DATABASE Ecommerce
--- I have imported e_commerce_data.csv

-------------------QUESTIONS & SOLUTIONS----------------------------

--- 1. Find the top 3 customers who have the maximum count of orders.

SELECT TOP 3 Cust_ID, Customer_Name, COUNT(Cust_ID) order_count
FROM e_commerce
GROUP BY Cust_ID, Customer_Name
ORDER BY order_count DESC


--- 2. Find the customer whose order took the maximum time to get shipping.

SELECT TOP 1 Cust_ID, Customer_Name, DaysTakenForShipping
FROM e_commerce
ORDER BY DaysTakenForShipping DESC


--- 3. Count the total number of unique customers in January and how many of them
---    came back again in the each one months of 2011.

-- Count the total number of unique customers in January
SELECT COUNT(DISTINCT Cust_ID) AS Total_Cust_in_Jan
FROM e_commerce
WHERE MONTH(Order_Date) = 1


-- How many of them came back again in the each one months of 2011


SELECT DISTINCT Cust_ID, Customer_Name,  COUNT( DISTINCT MONTH(Order_Date) ) [Total Month]
FROM e_commerce
WHERE 
	YEAR(Order_Date) = 2011
	AND	Cust_ID IN (
					SELECT  Cust_ID 
					FROM	e_commerce
					WHERE	YEAR(Order_Date) = 2011
							AND MONTH(Order_Date) = 1)
GROUP BY Cust_ID, Customer_Name
HAVING COUNT( DISTINCT MONTH(Order_Date) ) > 1
ORDER BY [Total Month] DESC


--- 4. Write a query to return for each user the time elapsed between the first
---    purchasing and the third purchasing, in ascending order by Customer ID.


WITH T1 AS (
SELECT Cust_ID, Customer_Name, Order_Date,
		ROW_NUMBER() OVER (PARTITION BY Cust_ID ORDER BY Order_Date) order_number,
		LEAD(Order_Date,2, Order_Date) OVER (PARTITION BY Cust_ID ORDER BY Order_Date) next_third_order
FROM e_commerce
)
SELECT Cust_ID, Customer_Name, DATEDIFF(DAY, Order_Date, next_third_order) time_between_first_and_third_order
FROM T1
WHERE order_number = 1
ORDER BY Cust_ID ASC


--- 5. Write a query that returns customers who purchased both product 11 and
---    product 14, as well as the ratio of these products to the total number of
---    products purchased by the customer.


----The query that returns customers who purchased both product 11 and  product 14
SELECT  DISTINCT Cust_ID, Customer_Name
FROM	e_commerce
WHERE 
    Prod_ID = 'Prod_14' 
AND Cust_Id IN
				(SELECT Cust_ID
				 FROM e_commerce
				 WHERE Prod_ID = 'Prod_11')


-----The ratio of these products to the total number of products purchased by the customer

WITH T1 AS (
SELECT Cust_ID, Customer_Name,
		SUM(CASE WHEN Prod_ID = 'Prod_11' THEN Order_Quantity END) Purchased_11 ,
		SUM(CASE WHEN Prod_ID = 'Prod_14' THEN Order_Quantity END) Purchased_14,
		SUM(Order_Quantity) Total_Purchased
FROM e_commerce
WHERE Cust_ID IN
				(SELECT Cust_ID
				 FROM	e_commerce
				 WHERE	Prod_ID = 'Prod_14' 
				 AND Cust_Id IN
								(SELECT Cust_ID
								 FROM e_commerce
								 WHERE Prod_ID = 'Prod_11'))
GROUP BY Cust_ID, Customer_Name
)
SELECT  *, CAST(1.0*Purchased_11/Total_Purchased AS DECIMAL(5,2)) ratio_11, CAST(1.0*Purchased_14/Total_Purchased AS DECIMAL(5,2)) ratio_14
FROM T1


/* Customer Segmentation
Categorize customers based on their frequency of visits. The following steps 
will guide you. If you want, you can track your own way. */


/*1. Create a “view” that keeps visit logs of customers on a monthly basis. (For 
each log, three field is kept: Cust_id, Year, Month)*/

CREATE VIEW montly_logs AS
SELECT DISTINCT Cust_ID, YEAR(Order_Date) [Year], MONTH(Order_Date) [Month]
FROM e_commerce


/*2. Create a “view” that keeps the number of monthly visits by users. (Show 
separately all months from the beginning business)*/

CREATE OR ALTER VIEW montly_visits AS
SELECT  DISTINCT Cust_ID, [Year], [Month],
		COUNT([Month]) montly_visit
FROM montly_logs
GROUP BY Cust_ID, [Year], [Month]


/*3. For each visit of customers, create the previous or next month of the visit as a 
separate column.*/

SELECT *,
		LEAD([Month],1,[Month]) OVER (PARTITION BY Cust_ID, [Year] ORDER BY [Month]) next_month_visit
FROM montly_visits


/*4. Calculate the monthly time gap between two consecutive visits by each 
customer.*/

WITH T1 AS(
SELECT *,
		LEAD([Month],1,[Month]) OVER (PARTITION BY Cust_ID, [Year] ORDER BY [Month]) next_month_visit
FROM montly_logs
)
SELECT *,
		DATEDIFF(DAY,[Month], next_month_visit) date_diff
FROM T1



/*5. Categorise customers using average time gaps. Choose the most fitted
labeling model for you.
For example: 
o Labeled as churn if the customer hasn't made another purchase in the 
months since they made their first purchase.
o Labeled as regular if the customer has made a purchase every month.
Etc.*/

CREATE VIEW T1 AS(
SELECT *,
		LEAD([Month],1,[Month]) OVER (PARTITION BY Cust_ID, [Year] ORDER BY [Month]) next_month_visit
FROM montly_logs
)
CREATE VIEW T2 AS (
SELECT *,
		DATEDIFF(DAY,[Month], next_month_visit) date_diff
FROM T1
)
CREATE VIEW TimeGap AS
SELECT Cust_ID, [Year], [Month], AVG(date_diff) avr_time_gap,
		CASE 
			WHEN AVG(date_diff) = 0 THEN 'Churn'
			WHEN AVG(date_diff) > 0 THEN 'Regular'
		END AS Category

FROM T2
GROUP BY Cust_ID, [Year], [Month]




/*      Month-Wise Retention Rate

Find month-by-month customer retention ratei since the start of the business.
There are many different variations in the calculation of Retention Rate. But we will 
try to calculate the month-wise retention rate in this project.
So, we will be interested in how many of the customers in the previous month could 
be retained in the next month.
Proceed step by step by creating “views”. You can use the view you got at the end of 
the Customer Segmentation section as a source.*/


--- 1. Find the number of customers retained month-wise. (You can use time gaps)

SELECT DISTINCT [Month], 
	COUNT( Cust_ID) OVER(PARTITION BY [Month]) retained_month_wise
FROM TimeGap
WHERE avr_time_gap > 0
ORDER BY [Month]



--- 2. Calculate the month-wise retention rate.
/* Month-Wise Retention Rate = 1.0 * Number of Customers Retained in The Current Month / Total 
Number of Customers in the Previous Month */

WITH T4 AS(
SELECT DISTINCT [Month], 
	COUNT( Cust_ID) OVER(PARTITION BY [Month]) retained_month_wise
FROM TimeGap
WHERE avr_time_gap > 0

)
SELECT *,
		CAST(1.0 * retained_month_wise / SUM(retained_month_wise) OVER()  AS DECIMAL(10,2)) retention_rate
FROM T4
ORDER BY [Month]
