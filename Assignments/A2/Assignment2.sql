


------1. Product Sales

SELECT A.customer_id, A.first_name, A.last_name,
		CASE
			WHEN D.product_name = 'Polk Audio - 50 W Woofer - Black' THEN 'Yes'
			ELSE 'No'
		END AS Other_Product
FROM sale.customer A, sale.orders B, sale.order_item C, product.product D
WHERE D.product_name = '2TB Red 5400 rpm SATA III 3.5 Internal NAS HDD'
AND	  A.customer_id = B.customer_id
AND   B.order_id = C.order_id
AND   C.product_id = D.product_id
ORDER BY A.customer_id

------2. Conversion Rate

--Create above table (Actions) and insert values

CREATE TABLE Actions (
Visitor_ID INT IDENTITY(1,1) PRIMARY KEY,
Adv_Type VARCHAR(1) NOT NULL,
[Action] VARCHAR(6) NOT NULL
)


INSERT Actions
VALUES 
	('A', 'Left'),
	('A', 'Order'),
	('B', 'Left'),
	('A', 'Order'),
	('A', 'Review'),
	('A', 'Left'),
	('B', 'Left'),
	('B', 'Order'),
	('B', 'Review'),
	('A', 'Review')

----- Retrieve count of total Actions and Orders for each Advertisement Type

SELECT
    Adv_Type,
    COUNT(*) AS Total_Actions,
    SUM(CASE WHEN Action = 'Order' THEN 1 ELSE 0 END) AS Total_Orders
FROM Actions
GROUP BY Adv_Type;

---- Calculate Orders (Conversion) rates for each Advertisement Type by dividing by total count of actions casting as float by multiplying by 1.0.

SELECT
    Adv_Type,
    CAST(SUM(CASE WHEN [Action] = 'Order' THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS DECIMAL(10, 2)) AS Conversion_Rate
FROM Actions
GROUP BY Adv_Type;