
/*
Discount Effects

Using SampleRetail database generate a report, including product IDs and discount effects on whether the increase in the discount rate positively impacts the number of orders for the products.

For this, statistical analysis methods can be used. However, this is not expected.

In this assignment, you are expected to generate a solution using SQL with a logical approach. 

Sample Result:
Product_id	Discount Effect
	1		Positive
	2		Negative
	3		Negative
	4		Neutral
*/

WITH T1 AS (
SELECT product_id, discount,COUNT(order_id) num_of_order,
		FIRST_VALUE(COUNT(order_id)) OVER (PARTITION BY product_id ORDER BY product_id, discount) first_val,
		LAST_VALUE(COUNT(order_id)) OVER (PARTITION BY product_id ORDER BY product_id, discount ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) last_val
FROM sale.order_item 
GROUP BY product_id, discount
)
SELECT DISTINCT product_id,
		(CASE
			WHEN last_val-first_val > 0 THEN 'Postive'
			WHEN last_val-first_val < 0 THEN 'Negative'
			WHEN last_val-first_val = 0 THEN 'Neutral'
		END) AS 'Discount Effect'
FROM T1