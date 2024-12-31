-- Monday Coffee SCHEMAS

DROP TABLE IF EXISTS sales;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS city;

-- Import Rules
-- 1st import to city
-- 2nd import to products
-- 3rd import to customers
-- 4th import to sales


CREATE TABLE city
(
	city_id	INT PRIMARY KEY,
	city_name VARCHAR(15),	
	population	BIGINT,
	estimated_rent	FLOAT,
	city_rank INT
);

CREATE TABLE customers
(
	customer_id INT PRIMARY KEY,	
	customer_name VARCHAR(25),	
	city_id INT,
	CONSTRAINT fk_city FOREIGN KEY (city_id) REFERENCES city(city_id)
);


CREATE TABLE products
(
	product_id	INT PRIMARY KEY,
	product_name VARCHAR(35),	
	Price float
);


CREATE TABLE sales
(
	sale_id	INT PRIMARY KEY,
	sale_date	date,
	product_id	INT,
	customer_id	INT,
	total FLOAT,
	rating INT,
	CONSTRAINT fk_products FOREIGN KEY (product_id) REFERENCES products(product_id),
	CONSTRAINT fk_customers FOREIGN KEY (customer_id) REFERENCES customers(customer_id) 
);

-- END of SCHEMAS

-----MONDAY COFFEE ANALYSIS MINI PROJECT SQL---------

SELECT * FROM city;

SELECT * FROM customers;

SELECT * FROM products;

SELECT * FROM sales;

-------------------------------

--REPORTS AND DATA ANALYSIS ------

--Q1) Coffee Consumers Count
--How many people in each city are estimated to consume coffee, given that 25% of the population does?


SELECT
	city_name,
	ROUND(((population*0.25)/1000000),2) AS coffe_con_population_million,
	city_rank
FROM city	
	

--Q2) Total Revenue from Coffee Sales
--What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

SELECT c.city_name, SUM(total) as total_revenue
FROM city c
JOIN customers cus ON c.city_id = cus.city_id
JOIN sales s ON s.customer_id = cus.customer_id
WHERE EXTRACT(YEAR FROM s.sale_date) = 2023 AND EXTRACT(QUARTER FROM s.sale_date) = 4
GROUP BY c.city_name
ORDER BY total_revenue DESC


---Q3Sales Count for Each Product
--How many units of each coffee product have been sold?

SELECT p.product_name, COUNT(s.sale_id) as units_sold
FROM products p
LEFT JOIN sales s ON p.product_id = s.product_id
GROUP BY p.product_name
ORDER BY units_sold DESC



--Q4)Average Sales Amount per City
--What is the average sales amount per customer in each city?


SELECT c.city_name, SUM(total),COUNT(DISTINCT s.customer_id),
ROUND((SUM(total)/COUNT(DISTINCT s.customer_id))) as avg_per_person
FROM city c
JOIN customers cus ON cus.city_id = c.city_id
JOIN sales s ON s.customer_id = cus.customer_id
GROUP BY c.city_name
ORDER BY 4 DESC


--Q5)City Population and Coffee Consumers
--Provide a list of cities along with their populations and estimated coffee consumers.

WITH coffee_population AS (
SELECT city_name, ROUND((population*0.25/1000000),2) as coffee_consumers_in_million
FROM city
),
--finding current customers for each city
coffee_consumers AS (
SELECT c.city_name, count(distinct s.customer_id) as coffe_con
FROM sales s
JOIN customers cus ON s.customer_id = cus.customer_id
JOIN city c ON c.city_id = cus.city_id
GROUP BY c.city_name
)
SELECT cc.city_name, cc.coffe_con, cp.coffee_consumers_in_million
FROM coffee_population cp
JOIN coffee_consumers cc ON cc.city_name = cp.city_name




--Q6) Top Selling Products by City
--What are the top 3 selling products in each city based on sales volume?


SELECT x.city_name, x.product_name,x.cnt_product_sold,x.rnk
FROM (
SELECT c.city_name, p.product_name,COUNT(s.sale_id) as cnt_product_sold,
RANK() OVER(PARTITION BY city_name ORDER BY COUNT(s.sale_id) DESC) AS rnk
FROM city c
JOIN customers cus ON c.city_id = cus.city_id
JOIN sales s ON s.customer_id = cus.customer_id
JOIN products p ON p.product_id = s.product_id
group by c.city_name, p.product_name) x
WHERE x.rnk <= 3


---Q7 Customer Segmentation by City
--How many unique customers are there in each city who have purchased coffee products?

SELECT c.city_name, COUNT(DISTINCT s.customer_id)
FROM city c
JOIN customers cus ON c.city_id = cus.city_id
JOIN sales s ON s.customer_id = cus.customer_id
JOIN products p ON p.product_id = s.product_id
WHERE s.product_id IN (SELECT product_id from products where product_id between 1 and 14)
GROUP BY c.city_name
ORDER BY 2 DESC



--Q8)Average Sale vs Rent
--Find each city and their average sale per customer and avg rent per customer


WITH city_table as(
SELECT c.city_name, SUM(s.total), COUNT(DISTINCT s.customer_id) as cnt_cx,
ROUND(SUM(s.total)/COUNT(DISTINCT s.customer_id)) as avg_sale_per_customer
FROM city c
JOIN customers cus ON c.city_id = cus.city_id
JOIN sales s ON s.customer_id = cus.customer_id
GROUP BY c.city_name
),
city_rent as(
SELECT city_name, estimated_rent
FROM city
)
SELECT ct.city_name, ct.cnt_cx, ct.avg_sale_per_customer, ROUND((cr.estimated_rent::numeric/ct.cnt_cx::numeric),2) as avg_rent_per_cx
FROM city_table ct
JOIN city_rent cr ON ct.city_name = cr.city_name
ORDER BY avg_rent_per_cx ASC





--Q9)Monthly Sales Growth
--Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly).

WITH monthly_sale AS (
SELECT 	
	ci.city_name AS cityName,
	EXTRACT(MONTH FROM sale_date) as month,
	EXTRACT (YEAR FROM sale_date) as year,
	SUM(s.total) as total_sales
FROM sales s
JOIN customers as c ON c.customer_id = s.customer_id
JOIN city as ci ON ci.city_id = c.city_id
GROUP BY 1, 2, 3
ORDER BY 1, 3, 2
),
growth_ration AS (
SELECT cityName, month, year, total_sales, 
LAG(total_sales) OVER(PARTITION BY cityName ORDER BY year,month) as pre_sales
FROM monthly_sale
)
SELECT cityName,month, year,total_sales, pre_sales,
	ROUND((total_sales - pre_sales)::numeric/pre_sales::numeric *100 ,2) as growth_rate
FROM growth_ration	


--Q10) Market Potential Analysis
--Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer	


WITH city_table as(
SELECT 
	c.city_name,
	SUM(s.total) as total_revenue,
	COUNT(DISTINCT s.customer_id) as cnt_cx,
	ROUND(SUM(s.total)/COUNT(DISTINCT s.customer_id)) as avg_sale_per_customer
FROM city c
JOIN customers cus ON c.city_id = cus.city_id
JOIN sales s ON s.customer_id = cus.customer_id
GROUP BY c.city_name
ORDER BY 2 DESC
),
city_rent as(
SELECT 
	city_name, 
	estimated_rent,
	ROUND((population*0.25/1000000),3) AS coffee_consumer_population_in_million
FROM city
)
SELECT 
	ct.city_name,
	ct.total_revenue,
	cr.estimated_rent AS total_rent,
	ct.cnt_cx,
	cr.coffee_consumer_population_in_million,
	ct.avg_sale_per_customer,
	ROUND((cr.estimated_rent::numeric/ct.cnt_cx::numeric),2) as avg_rent_per_cx
FROM city_table ct
JOIN city_rent cr ON ct.city_name = cr.city_name
ORDER BY 2 DESC


---END

--RECOMMENDATION
/*

CITY 1 : PUNE
	1.Avaerage rent per customer is very less,
	2. highest total revenue,
	3. avg_sale per customer is also high

CITY 2 : Delhi
	1.Highest estimated coffee customer which is 7.7M
	2.Highest total customer which is 68
	3. avg rent per customer 330 (still under 560)

CITY 3: Jaipur
	1.Highest customer no which is 69
	2.Avg rent per customer is very less 156
	3.avg sale per customer is better which ata 11.6k

	*/





