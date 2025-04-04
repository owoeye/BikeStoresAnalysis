--Key Areas of Concern:
--1.Sales and Revenue Growth:
--How can bike stores optimize pricing strategies to maximize revenue?
	--o What are our most profitable stores?
	WITH customer_no AS (--o How many people are in each state?
							SELECT state, COUNT(customer_id) no_customers
							FROM customers
							GROUP BY state),
		store_totals AS (--o Totals sales and orders in store
							SELECT store_id, SUM(ot.order_total) AS store_total, COUNT(o.order_id) AS no_orders
							FROM orders o
							JOIN (SELECT order_id, SUM(quantity*list_price*(1-discount)) AS order_total
									FROM order_items
									GROUP BY order_id) ot
							ON o.order_id = ot.order_id
							WHERE o.shipped_date IS NOT NULL
							GROUP BY store_id)

    --o Summary of Store toals
	SELECT s.store_id, s.store_name, s.city, s.state, st.no_orders, cn.no_customers, st.store_total, st.store_total/st.no_orders AS total_per_order
	FROM stores s
	JOIN store_totals st
	ON s.store_id = st.store_id
	JOIN customer_no cn
	ON cn.state = s.state
	ORDER BY st.store_total DESC;

	--o What are our most popular products across all stores?
	SELECT p.product_id, p.product_name, sp.total_sales
	FROM (--o total sales per product
			SELECT product_id, SUM(quantity) AS total_sales
			FROM order_items
			GROUP BY product_id) sp
	JOIN products p
	ON p.product_id = sp.product_id
	ORDER BY sp.total_sales DESC;

	--o What are our most profitable/popular products per store?
	SELECT pp.store_id, pp.product_id, p.product_name, pp.no_sales, pp.rank, pp.total_sales, pp.rank2
	FROM (-- Rank of products profitability
			SELECT o.store_id, oi.product_id, SUM(oi.quantity) AS no_sales, RANK() OVER (PARTITION BY o.store_id ORDER BY SUM(oi.quantity) DESC) AS rank, SUM(oi.quantity*oi.list_price*(1-oi.discount)) AS total_sales, RANK() OVER (PARTITION BY o.store_id ORDER BY SUM(oi.quantity*oi.list_price*(1-oi.discount)) DESC) AS rank2
			FROM order_items oi
			JOIN orders o
			ON o.order_id = oi.order_id
			JOIN products p
			ON p.product_id = oi.product_id
			WHERE o.shipped_date IS NOT NULL
			GROUP BY o.store_id, oi.product_id) pp
	JOIN products p
	ON p.product_id = pp.product_id
	--WHERE pp.rank <= 3
	--ORDER BY pp.store_id, pp.no_sales DESC;
	WHERE pp.rank2 <= 3
	ORDER BY pp.store_id, pp.total_sales DESC;

	--o What are our most popular brands products?
	SELECT b.brand_id, b.brand_name, bt.no_sales, bt.total_sales
	FROM (-- total amount per brand
			SELECT b.brand_id, SUM(oi.quantity) AS no_sales, SUM(oi.quantity*oi.list_price*(1-oi.discount)) AS total_sales
			FROM brands b
			JOIN products p
			ON b.brand_id = p.brand_id
			JOIN order_items oi
			ON oi.product_id = p.product_id
			GROUP BY b.brand_id) bt
	JOIN brands b
	ON b.brand_id = bt.brand_id
	--ORDER BY bt.no_sales DESC
	ORDER BY bt.total_sales DESC;

	--o What are our most profitable brands per store?
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
	--ORDER BY store_id, stb.no_orders DESC;
	ORDER BY store_id, stb.total_sales DESC;

	--o What are the effects of discounting on Prices?

	--o Do the staffs affect productivity?
	--o How much did each staff sell?
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
	-- Some members did not have any sales. likely 1- He is the CEO, 4,10-New hire, 2,8-Manager with sales cause branch was under staffed, 5-Hired to be a manager not sales person

	--o Are the most popular products reflected in the inventory?
	--o How do seasonal trends impact sales, and how can we manage inventory effectively?
	SELECT *
	FROM orders o
	JOIN (-- order total
			SELECT order_id, SUM(quantity*list_price*(1-discount)) AS order_total
			FROM order_items
			GROUP BY order_id) ot
	ON o.order_id = ot.order_id
	WHERE YEAR(o.order_date)=2018
	ORDER BY MONTH(o.order_date);

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
	SELECT YEAR(order_date), COUNT(order_id)
	FROM orders
	WHERE shipped_date IS NOT NULL
	GROUP BY YEAR(order_date)
	ORDER BY YEAR(order_date);


--2.Operational Efficiency:
	--o How can supply chain management be optimized to reduce costs?
	--o What strategies can minimize inventory holding costs while meeting customer demand?
	--o Can partnerships with manufacturers or distributors improve pricing and availability?
--3.Marketing and Customer Engagement:
	--o What are the best digital marketing strategies to enhance store visibility? (SEO, social media, ads)
	--o How can customer engagement be improved to increase retention and loyalty?
	--o What role do online reviews, testimonials, and word-of-mouth play in attracting new customers?
--4.Customer Behavior and Preferences:
	--o What demographics are most likely to purchase from the store, and how can targeting be improved?
	--How do customer preferences (e.g., eco-friendly bikes, electric bikes) influence purchasing decisions?
	--o Is there a generally preferred brand?
	--o Is there a locally preferred brand per store?
	--o How can the in-store and online shopping experience be improved?


