
Create Database PizzaStore;									#Creating a Database 
USE PizzaStore;

#importing tables from dataset Files using "table data import Wizard"  
SELECT * FROM pizzas;
SELECT * FROM pizza_types;

#The orders table File is Big , so creating table structure First and then Uploading data using "table data import Wizard"
CREATE TABLE Orders (
Order_id INT PRIMARY KEY NOT NULL  ,
order_date DATE NOT NULL ,
order_time TIME NOT NULL );

#Uploaded data using "table data import Wizard"
SELECT * FROM orders;

# Similar for order_details 
CREATE TABLE Order_details(
order_detail_id INT PRIMARY KEY NOT NULL ,
order_id INT NOT NULL ,
Pizza_id TEXT NOT NULL ,
Quantity INT NOT NULL );

DESC order_details;

SELECT * FROM order_details;   #Checking the data 


#BASIC QUESTIONS : 
-- 1. Retrieve the total number of orders placed.
		SELECT COUNT(order_id) FROM orders;

-- 2. Calculate the total revenue generated from pizza sales.
SELECT ROUND(SUM(od.Quantity * p.Price),2) AS 'Total Revenue'
FROM Order_details AS od JOIN Pizzas as p
ON od.pizza_id = p.Pizza_id;

-- 3.Identify the highest-priced pizza.
SELECT pt.name, p.price
FROM pizza_types pt JOIN pizzas p 
ON pt.pizza_type_id = p.pizza_type_id
WHERE p.price = (SELECT MAX(price) FROM pizzas);

# OR 
SELECT pizza_types.name, pizzas.price
FROM pizza_types
JOIN pizzas ON pizza_types.pizza_type_id = pizzas.pizza_type_id
ORDER BY pizzas.price DESC
LIMIT 1;

-- 4.Identify the most common pizza size ordered
SELECT p.Size , COUNT(od.order_id) as Times_ordered
FROM pizzas p JOIN order_details od 
ON p.pizza_id = od.pizza_id 
GROUP BY p.Size ORDER BY Times_ordered DESC ;

-- 5.List the top 5 most ordered pizza types along with their quantities.
SELECT pt.name AS pizza_name, SUM(od.quantity) AS total_quantity 
FROM pizza_types pt JOIN pizzas p 
ON pt.pizza_type_id = p.pizza_type_id JOIN order_details od 
ON p.pizza_id = od.pizza_id
GROUP BY pt.name
ORDER BY total_quantity DESC
LIMIT 5;

 -- 6. Total Number of Pizzas Sold 

 SELECT SUM(quantity) as Total_no_pizzas_sold FROM order_details;
 
 -- 7. Find out which day of week makes the highest revenue 
 SELECT 
  DAYNAME(o.order_date) AS day_of_week,
  ROUND(SUM(od.quantity * p.price),2) AS total_revenue
FROM orders o
JOIN order_details od ON o.order_id = od.order_id  
JOIN pizzas p ON od.pizza_id = p.pizza_id
GROUP BY day_of_week
ORDER BY total_revenue DESC;

#Intermediate:
-- 1.Join the necessary tables to find the total quantity of each pizza category ordered.
SELECT pt.category , SUM(od.Quantity) as Total_quantity 
FROM  Pizza_types pt JOIN pizzas p 
ON pt.pizza_type_id = p.pizza_type_id JOIN Order_details od
ON p.pizza_id = od.pizza_id
GROUP BY pt.category;

-- 2. Determine the distribution of orders by hour of the day.
SELECT HOUR(order_time) AS hours,
       COUNT(order_id) AS orders
FROM orders
GROUP BY hours;

-- 3.Join relevant tables to find the category-wise distribution of pizzas.
SELECT pt.category , Count(p.pizza_id) as Total_Pizzas
 FROM  Pizza_types pt JOIN pizzas p 
 ON pt.pizza_type_id = p.pizza_type_id 
GROUP BY pt.category 
ORDER BY total_pizzas DESC;


-- 4.Group the orders by date and calculate the average number of pizzas ordered per day.

SELECT ROUND(AVG(daily_pizzas.total_quantity), 2) AS avg_pizzas_per_day
FROM (
  SELECT o.order_date, SUM(od.quantity) AS total_quantity
  FROM orders o
  JOIN order_details od ON o.order_id = od.order_id
  GROUP BY o.order_date
) AS daily_pizzas;

-- 5.Determine the top 3 most ordered pizza types based on revenue.
SELECT pt.name AS pizza_name,
       SUM(od.quantity * p.price) AS total_revenue,
       SUM(od.quantity) AS total_quantity
FROM pizza_types pt
JOIN pizzas p ON pt.pizza_type_id = p.pizza_type_id
JOIN order_details od ON p.pizza_id = od.pizza_id
GROUP BY pt.name
ORDER BY total_revenue DESC
LIMIT 3;

-- Average Order value 
SELECT ROUND(AVG(order_total), 2) AS average_order_value
FROM (
  SELECT o.order_id,
         SUM(od.quantity * p.price) AS order_total
  FROM orders o
  JOIN order_details od ON o.order_id = od.order_id
  JOIN pizzas p ON od.pizza_id = p.pizza_id
  GROUP BY o.order_id
) AS order_summary;



-- Slow movers → pizzas with least sales (good for menu pruning) 
SELECT pt.name AS pizza_name,
       SUM(od.quantity ) AS total_quantity
FROM pizza_types pt
JOIN pizzas p ON pt.pizza_type_id = p.pizza_type_id
JOIN order_details od ON p.pizza_id = od.pizza_id
GROUP BY pt.name
ORDER BY total_quantity ASC
LIMIT 5;

#Advanced:
-- 1. Calculate the percentage contribution of each pizza type to total revenue.

SELECT ROUND(SUM(od.Quantity * p.price))
 FROM order_details od JOIN pizzas p 
 ON od.pizza_id = p.pizza_id; 						# Total revenue 

SELECT  
  pt.name AS pizza_name,
  ROUND(SUM(od.quantity * p.price), 2) AS pizza_revenue,       #revenue
  ROUND(
    (SUM(od.quantity * p.price) / 
     (SELECT SUM(od2.quantity * p2.price)
      FROM order_details od2
      JOIN pizzas p2 ON od2.pizza_id = p2.pizza_id)
    ) * 100, 2 													#percent revenue = (revenue / total_revenue) * 100
  ) AS revenue_percentage
FROM pizza_types pt
JOIN pizzas p ON pt.pizza_type_id = p.pizza_type_id
JOIN order_details od ON p.pizza_id = od.pizza_id
GROUP BY pt.name
ORDER BY revenue_percentage DESC;

-- 2.Analyze the cumulative revenue generated over time.

-- Select the order date to group revenue by day
SELECT 
  o.order_date,
  -- Calculate total revenue for each day by summing quantity × price
  ROUND(SUM(od.quantity * p.price), 2) AS daily_revenue,
  ROUND(
    SUM(SUM(od.quantity * p.price)) OVER (ORDER BY o.order_date), 
    2
  ) AS cumulative_revenue    				  -- Calculate cumulative revenue over time using a window function ,	-- This adds up daily revenues in chronological orde
FROM orders o								
JOIN order_details od ON o.order_id = od.order_id
JOIN pizzas p ON od.pizza_id = p.pizza_id
GROUP BY o.order_date
ORDER BY o.order_date;


-- Determine the top 3 most ordered pizza types based on revenue for each pizza category.
SELECT category, pizza_name, revenue , pizza_rank 
FROM (
  SELECT 
    pt.category,
    pt.name AS pizza_name,
    SUM(od.quantity * p.price) AS revenue,
    Rank() OVER (PARTITION BY pt.category ORDER BY SUM(od.quantity * p.price) DESC) AS pizza_rank
  FROM pizza_types pt
  JOIN pizzas p ON pt.pizza_type_id = p.pizza_type_id
  JOIN order_details od ON p.pizza_id = od.pizza_id
  GROUP BY pt.category, pt.name
) AS ranked_pizzas
WHERE pizza_rank <= 3
ORDER BY category, revenue DESC;
