-- Create the database and switch to it
CREATE DATABASE pizza_db;
USE pizza_db;

-- 1. Retrieve the total number of orders placed
SELECT COUNT(order_id) AS total_orders 
FROM orders;

-- 2. Calculate the total revenue generated from pizza sales
SELECT ROUND(SUM(order_details.quantity * pizzas.price), 2) AS total_revenue
FROM order_details
JOIN pizzas ON pizzas.pizza_id = order_details.pizza_id;

-- 3. Identify the highest-priced pizza (shows all pizzas sorted by price)
SELECT pizza_id, price
FROM pizzas
ORDER BY price DESC;

-- 4. List the top 5 most ordered pizzas (by quantity sold)
SELECT p.pizza_id, SUM(od.quantity) AS total_quantity
FROM order_details od
JOIN pizzas p ON od.pizza_id = p.pizza_id
GROUP BY p.pizza_id
ORDER BY total_quantity DESC
LIMIT 5;

-- 5. Identify the most common pizza size ordered
-- (Counts how many pizzas exist of each size)
SELECT size, COUNT(*) AS total_orders
FROM pizzas
GROUP BY size
ORDER BY total_orders DESC;

-- 6. Total quantity of each pizza category ordered
SELECT pt.pizza_type_id, SUM(od.quantity) AS total_quantity
FROM order_details od
JOIN pizzas p ON od.pizza_id = p.pizza_id
JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.pizza_type_id;

-- 7. Distribution of orders by hour of the day
SELECT HOUR(time) AS order_hour, COUNT(*) AS total_orders
FROM orders
GROUP BY HOUR(time)
ORDER BY order_hour;

-- 8. Category-wise distribution of pizzas (menu composition)
SELECT pt.pizza_type_id, COUNT(p.pizza_id) AS total_pizzas
FROM pizzas p
JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.pizza_type_id;

-- 9. Average number of pizzas ordered per day
SELECT AVG(total_pizzas) AS avg_pizzas_per_day
FROM (
    SELECT o.date, SUM(od.quantity) AS total_pizzas
    FROM orders o
    JOIN order_details od ON o.order_id = od.order_id
    GROUP BY o.date
) daily_orders;

-- 10. Top 3 most ordered pizza types based on revenue
SELECT p.pizza_type_id, SUM(od.quantity * p.price) AS total_revenue
FROM order_details od
JOIN pizzas p ON od.pizza_id = p.pizza_id
GROUP BY p.pizza_type_id
ORDER BY total_revenue DESC
LIMIT 3;

-- 11. INNER JOIN: Get all orders with the pizzas they include
SELECT o.order_id, o.date, p.pizza_id AS pizza_name, od.quantity
FROM orders o
INNER JOIN order_details od ON o.order_id = od.order_id
INNER JOIN pizzas p ON od.pizza_id = p.pizza_id;

-- 12. LEFT JOIN: Show all pizzas and their total sold quantity
-- (even if some pizzas were never ordered)
SELECT p.pizza_id, p.pizza_type_id AS pizza_name, COALESCE(SUM(od.quantity), 0) AS total_sold
FROM pizzas p
LEFT JOIN order_details od ON p.pizza_id = od.pizza_id
GROUP BY p.pizza_id, p.pizza_type_id;

-- 13. RIGHT JOIN: Show all orders and their pizzas 
-- (even if some pizzas have no matching orders)
SELECT o.order_id, o.date, p.pizza_type_id AS pizza_name, od.quantity
FROM orders o
RIGHT JOIN order_details od ON o.order_id = od.order_id
RIGHT JOIN pizzas p ON od.pizza_id = p.pizza_id;

-- 14. Multiple JOINs: Combine orders, pizzas, and categories
SELECT o.order_id, o.date, p.pizza_type_id AS pizza_name, pt.category, od.quantity
FROM orders o
JOIN order_details od ON o.order_id = od.order_id
JOIN pizzas p ON od.pizza_id = p.pizza_id
JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id;

-- 15. Complex Query: Monthly top pizza (by revenue) in each category
WITH monthly_sales AS (
    SELECT 
        DATE_FORMAT(o.date, '%Y-%m') AS month,
        pt.category AS pizza_category,
        pt.name AS pizza_name,
        SUM(od.quantity * p.price) AS revenue
    FROM orders o
    JOIN order_details od ON o.order_id = od.order_id
    JOIN pizzas p ON od.pizza_id = p.pizza_id
    JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
    GROUP BY month, pt.category, pt.name
)
SELECT month, pizza_category, pizza_name, revenue
FROM (
    SELECT 
        month, 
        pizza_category, 
        pizza_name, 
        revenue,
        ROW_NUMBER() OVER (PARTITION BY month, pizza_category ORDER BY revenue DESC) AS rank_no
    FROM monthly_sales
) ranked
WHERE rank_no = 1;
