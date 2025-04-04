--Key Areas of Concern:
--1.Sales and Revenue Growth:
--How can bike stores optimize pricing strategies to maximize revenue?
	-- What are our most profitable stores?
	WITH customer_no AS (-- How many people are in each state?
							SELECT state, COUNT(customer_id) no_customers
							FROM customers
							GROUP BY state),
		store_totals AS (-- Totals sales and orders in store
							SELECT store_id, SUM(ot.order_total) AS store_total, COUNT(o.order_id) AS no_orders
							FROM orders o
							JOIN (SELECT order_id, SUM(quantity*list_price*(1-discount)) AS order_total
									FROM order_items
									GROUP BY order_id) ot
							ON o.order_id = ot.order_id
							WHERE o.shipped_date IS NOT NULL
							GROUP BY store_id)

    -- Summary of Store toals
	SELECT s.store_id, s.store_name, s.city, s.state, st.no_orders, cn.no_customers, st.store_total, st.store_total/st.no_orders AS total_per_order
	FROM stores s
	JOIN store_totals st
	ON s.store_id = st.store_id
	JOIN customer_no cn
	ON cn.state = s.state
	ORDER BY st.store_total DESC;
	--The Store at New York is the most profitable. 
	--Why? When customers purchasing power seems to be the same in every state.
	--We can therefore say that because NY has more customers, that is why it produces more profit. 
	--At such high prices per order our customers must be the upper middle class and middle class.



	-- What are our most profitable brands per store?
	SELECT stb.store_id, stb.brand_id, b.brand_name, stb.no_orders, stb.total_sales
	FROM (-- total sales per brand per store
			SELECT o.store_id, b.brand_id, SUM(oi.quantity) AS no_orders, SUM(oi.quantity*oi.list_price*(1-oi.discount)) AS total_sales
			FROM brands b
			JOIN products p
			ON b.brand_id = p.brand_id
			JOIN order_items oi
			ON oi.product_id = p.product_id
			JOIN orders o
			ON o.order_id = oi.order_id
			WHERE o.shipped_date IS NOT NULL
			GROUP BY store_id, b.brand_id) stb
	JOIN brands b
	ON b.brand_id = stb.brand_id
	ORDER BY store_id, stb.no_orders DESC;
	--ORDER BY store_id, stb.total_sales DESC;

	--It seems that the Trek brand is the most profitable across all stores
	--but the electra brand is the most popular



	-- Do the staffs affect productivity?
	-- How much did each staff sell?
	SELECT s.staff_id, s.first_name, s.last_name, s.store_id, es.total_sales, CASE 
																				WHEN s.manager_id = 1 
																					THEN 1 
																				ELSE 0 
																				END AS is_manager
	FROM staffs s
	JOIN (-- employee total sales
			SELECT s.staff_id, SUM(oi.quantity*oi.list_price*(1-oi.discount)) AS total_sales
			FROM staffs s
			JOIN orders o
			ON o.staff_id = s.staff_id
			JOIN order_items oi
			ON oi.order_id = o.order_id
			WHERE o.shipped_date IS NOT NULL
			GROUP BY s.staff_id) es
	ON es.staff_id = s.staff_id
	ORDER BY es.total_sales DESC;
	-- Some members did not have any sales. 1 - He is the CEO, 4&10 - are new hires, 2&8 - Managers with sales because the branch was understaffed, 
	-- 5 - Hired to be a manager not sales person hence, no sales

	-- Are the most popular products reflected in the inventory?
	-- How do seasonal trends impact sales, and how can we manage inventory effectively?

	SELECT * 
	FROM (
		SELECT YEAR(o.order_date) AS year, MONTH(o.order_date) AS month, ot.order_total
		FROM orders o
		JOIN (-- order total
				SELECT order_id, SUM(quantity*list_price*(1-discount)) AS order_total
				FROM order_items
				GROUP BY order_id) ot
		ON o.order_id = ot.order_id
		WHERE o.shipped_date IS NOT NULL
	) AS SourceTable
	PIVOT (
		SUM(order_total) 
		FOR month IN ([1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12])
	) AS PivotTable;

	--no orders yearly
	SELECT * 
	FROM (
		SELECT YEAR(o.order_date) AS year, MONTH(o.order_date) AS month, o.order_id
		FROM orders o
		--WHERE YEAR(order_date) = 2018
		--WHERE o.shipped_date IS NOT NULL
	) AS SourceTable
	PIVOT (
		COUNT(order_id) 
		FOR month IN ([1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12])
	) AS PivotTable;

	-- notice no sales  after the 3rd month in 2018 but there are still orders. 
	--Why? The branches still took orders but they all failed to ship.
	--Why? There was such a high demand in the fourth month which leads me to believe that there was a shortage of supply which caused such a massive spike in demand 
	--but the retailer waas unale to get new bicyles after the 3rd month

	-- Was it a particular brand or bicycle that customers were looking for?
	--number of bicycles yearly
	SELECT * 
	FROM (
		SELECT YEAR(o.order_date) AS year, MONTH(o.order_date) AS month, oi.quantity
		FROM orders o
		JOIN order_items oi
		ON o.order_id = oi.order_id	
		WHERE o.shipped_date IS NOT NULL
	) AS SourceTable
	PIVOT (
		COUNT(quantity) 
		FOR month IN ([1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12])
	) AS PivotTable;

	-- Taking a deeper look at the 4th month
		SELECT p.product_name, COUNT(p.product_id)
	FROM products p
	JOIN (--unique product
			SELECT product_id
			FROM orders o
			JOIN order_items oi
			ON oi.order_id = o.order_id
			WHERE YEAR(o.order_date)=2018 AND MONTH(o.order_date)=4) up
	ON up.product_id=p.product_id
	GROUP BY p.product_name
	ORDER BY COUNT(p.product_id) DESC;

	-- No it was not a shortage on a particular brand but a general lack of supply.
	--We see the issue lies in the supply of these bicycles either from a faliure on the part of the supplier or a breach in contract on the side of the retailer
	--or loss of supply from the manufacturer


