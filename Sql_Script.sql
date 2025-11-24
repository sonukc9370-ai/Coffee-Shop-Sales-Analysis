
DROP TABLE IF EXISTS sales;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS city;

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

-- Data Imported using Mysql Import Wizard from CSV files


-- Que:1) Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?
SELECT
	ci.city_name,
    ROUND(((ci.population*0.25)/1000000),2) As Coffee_Consumers_in_millions
FROM city ci;


-- Que 2) Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?
SELECT 
	ci.city_name,
	sum(s.total) as Total_revenue_generated,
    ROUND((sum(s.total)/sum(sum(total)) over())*100,2) as "%age Contribution"
FROM city ci JOIN customers c ON ci.city_id=c.city_id JOIN
Sales s ON c.customer_id=s.customer_id
WHERE sale_date>='2023-10-01' AND  Sale_date <='2023-12-31'
GROUP BY ci.city_name
ORDER BY Total_revenue_generated DESC;


-- Que: 3) Sales Count for Each Product
-- How many units of each coffee product have been sold?
SELECT
	p.product_name,
    count(distinct s.sale_id) as Total_Orders,
    sum(s.total) as Total_revenue_generated,
    ROUND((sum(s.total)/sum(sum(s.total)) over())*100,2) As "%age contribution"
FROM products p JOIN Sales s 
ON p.product_id=s.product_id
GROUP BY p.product_name
ORDER BY Total_revenue_Generated DESC;

-- 	Que: 4)Average Sales Amount per City
-- What is the average sales amount per customer in each city?
SELECT
	ci.city_name,
    ROUND(sum(s.total)/count(distinct c.customer_id),2) As Avg_Sale
FROM city ci JOIN customers c ON ci.city_id=c.city_id 
JOIN Sales s ON c.customer_id=s.customer_id
GROUP BY ci.city_name
ORDER BY Avg_Sale DESC;


-- 	Que: 5) City Population and Coffee Consumers
-- Provide a list of cities along with their populations and estimated coffee consumers.
SELECT
	ci.city_name,
    ROUND((ci.population)/1000000,2) As population_in_millions,
    ROUND(((ci.population*0.25)/1000000),2)	 As Estimated_Coffee_consumers_in_millions
FROM City ci;


-- Que:6) Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?
WITH 
	Ranked_City As (
SELECT
	ci.city_name,
    p.product_name,
    sum(s.total) as Total_Sale,
    dense_rank() over(partition by ci.city_name order by sum(s.total) DESC) as drnk
 FROM City ci
JOIN Customers c ON ci.city_id = c.city_id
JOIN Sales s ON c.customer_id = s.customer_id
JOIN Products p ON s.product_id = p.product_id
GROUP BY 1,2
)
SELECT
	city_name,
    product_name,
    Total_Sale
FROM Ranked_City
WHERE drnk<=3;



-- Que 7) Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?
SELECT
	ci.city_name,
    count(distinct s.customer_id) as Unique_Customers
FROM City ci LEFT JOIN Customers c
ON ci.city_id=c.city_id JOIN Sales s 
ON c.customer_id=s.customer_id
GROUP BY ci.city_name;


-- Que 8) Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer
SELECT
	ci.city_name,
    ROUND(sum(s.total)/count(distinct s.customer_id),2) as Avg_Sale,
    ci.estimated_rent
FROM City ci JOIN Customers c 
ON ci.city_id=c.city_id JOIN
Sales s ON c.customer_id=s.customer_id
GROUP BY
	ci.city_name,
    ci.estimated_rent;
    
    
  -- Que 9) Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly)
WITH
	Monthly_Sales as (
		SELECT 
			DATE_FORMAT(sale_date,"%b %Y") as Date,
            Sum(total) as Total_Sale
		FROM Sales
        GROUP BY 1
    ),
	Prev_Month_Sales as (
		SELECT 
			Date,
			Total_Sale,
			LAG(Total_Sale) over(order by STR_TO_DATE(Date,"%b %Y")) As Prev_Month_Sale
		FROM Monthly_Sales
        )

SELECT
	Date,
    Total_Sale,
	ROUND(((Total_Sale-Prev_Month_Sale)/Prev_Month_Sale)*100,2) as Percentage_Growth
FROM Prev_Month_Sales;
        
  

-- Que:10) Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer
WITH
	City_sales_summary as (
    SELECT
		c.city_id,
        sum(s.total) as Total_Sale,
        count(distinct s.customer_id) as unique_customers
	FROM Customers c JOIN Sales s 
    on c.customer_id=s.customer_id
    GROUP BY C.city_id
    )
    SELECT
		ci.city_name,
        Total_Sale,
        unique_customers,
        ci.estimated_rent,
        ROUND(((ci.population*0.25)/1000000),2) As Estimated_Population
    FROM City ci JOIN city_sales_summary css
    ON ci.city_id=css.city_id
    ORDER BY css.Total_Sale DESC
    LIMIT 3;
    
    
    
    
    
    
    
    
    
    
