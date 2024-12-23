-- Monday Coffee -- Data Analysis
SELECT * FROM city;
SELECT * FROM products;
SELECT * FROM customers;
SELECT * FROM sales;

-- Reports & Data Analysis

-- Q1 Coffee consumer count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?

select city_name,
round((population*0.25)/1000000,2) as coffee_consumers_in_millions,
city_rank
from city
order by population desc;

-- Q2 Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?
select sum(total) as revenue 
        from sales
        where Year(sale_date)=2023
        and Quarter(sale_date)=4 ;
              
-- Q3 Sales Count for Each Product
-- How many units of each coffee product have been sold?

Select p.product_name,
 COUNT(s.sale_id) as total_orders
from products p 
left join sales s on s.product_id = p.product_id
group by p.product_name
order by total_orders desc;

-- Q4 Average Sales Amount per City
-- What is the average sales amount per customer in each city?

select ct.city_name,
	   sum(s.total) as total_revenue,
       count(distinct s.customer_id) as total_customer,
       round(sum(s.total)/count(distinct s.customer_id),2)as avg_sale_pr_customer
from sales as s
join customers as c
on s.customer_id = c.customer_id
join city as ct
on ct.city_id = c.city_id
group by ct.city_name
order by total_revenue desc;

-- Q5 City Population and Coffee Consumers
-- Provide a list of cities along with their populations and estimated coffee consumers.

with city_table as 
( select 
        city_name,
        Round((population*0.25/1000000),2) as coffee_consumers
		from city 
),
customers_table as
( Select ci.city_name, 
         count(distinct(c.customer_id)) as unique_cx
from sales as s
join customers as c
on c.customer_id = s.customer_id
join city as ci
on ci.city_id=c.city_id
group by ci.city_name
)
select
      customers_table.city_name,
      city_table.coffee_consumers,
      customers_table.unique_cx
from city_table 
join
customers_table 
on customers_table.city_name = city_table.city_name ;
		
-- Q6 Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?

SELECT *
FROM (
    SELECT ct.city_name,
           p.product_name,
           COUNT(s.sale_id) AS total_orders,
           DENSE_RANK() OVER (
               PARTITION BY ct.city_name
               ORDER BY COUNT(s.sale_id) DESC  -- Use COUNT(s.sale_id) directly here
           ) AS Ranking
    FROM sales s
    JOIN products p ON s.product_id = p.product_id
    JOIN customers c ON s.customer_id = c.customer_id
    JOIN city ct ON c.city_id = ct.city_id
    GROUP BY ct.city_name, p.product_name
) AS ranked_products
WHERE Ranking <= 3;

-- Q7 Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?

-- sales(custid)  ...custmer( basedon custid cust name cityid )... city( based on cityid city name)

select  ct.city_name , 
count(distinct c.customer_id) as unique_customers_count
from sales s
join customers c 
on s.customer_id = c.customer_id
join city ct
on c.city_id = ct.city_id
where s.product_id between 1 And 14
group by ct.city_name;


-- Q8 Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer

With city_table
as 
(  select ct.city_name,
          sum(s.total) as total_sales,
          count(distinct s.customer_id) as total_customers,
          Round(sum(s.total)/count(distinct s.customer_id),2) as Avg_sale_per_cust
   from sales s
   Join customers c
   on s.customer_id = c.customer_id
   Join city as ct
   on ct.city_id = c.city_id
   group by ct.city_name
   order by sum(s.total) desc 
),
 city_rent as
( select city_name,
         estimated_rent
  from city
)
select cr.city_name,
       cr.estimated_rent,
       ctt.total_customers,
       ctt.Avg_sale_per_cust,
       round(cr.estimated_rent/ctt.total_customers,2) as Avg_rent_per_cust
from city_rent cr
join city_table as ctt
on cr.city_name = ctt.city_name ;

-- Q9 Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly).
-- by each city  

with monthly_sales
as
( select ct.city_name as city_name,
extract(month from sale_date) as Month,
extract(year from sale_date)   as Year ,
Sum(s.total) as total_sales
from sales as s
join customers as c
on s.customer_id = c.customer_id
join city as ct
on c.city_id = ct.city_id
group by ct.city_name, Month , Year
order by ct.city_name, Year , Month
),
growth_ratio
as
(  select city_name ,
          Month,
          Year,
          total_sales as cr_month_sale,
          LAG(total_sales, 1) Over(partition by city_name order by Year , Month ) as last_month_sale
	from monthly_sales
)

select
     city_name,
     Month,
     Year,
     cr_month_sale,
     last_month_sale,
     Round( ((cr_month_sale-last_month_sale)/last_month_sale)*100,2) as growth_ratio
from growth_ratio
where last_month_sale is not null;
  
-- Q10 Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, 
-- total sale, total rent, total customers, estimated coffee consumer
   
With city_table
as 
(  select ct.city_name,
          sum(s.total) as total_sales,
          count(distinct s.customer_id) as total_customers,
          Round(sum(s.total)/count(distinct s.customer_id),2) as Avg_sale_per_cust
   from sales s
   Join customers c
   on s.customer_id = c.customer_id
   Join city as ct
   on ct.city_id = c.city_id
   group by ct.city_name
   order by sum(s.total) desc 
),
 city_rent as
( select city_name,
         estimated_rent,
         (population * 0.25)/1000000 as est_coffee_consumer_in_million
  from city
)
select cr.city_name,
       total_sales,
       cr.estimated_rent as total_rent,
       ctt.total_customers,
       est_coffee_consumer_in_million,
       ctt.Avg_sale_per_cust,
       round(cr.estimated_rent/ctt.total_customers,2) as Avg_rent_per_cust
from city_rent cr
join city_table as ctt
on cr.city_name = ctt.city_name 
order by total_sales desc;

/*
--- Recommendation
After analyzing the data, the recommended top three cities for new store openings are:

City 1: Pune

Average rent per customer is very low.
Highest total revenue.
Average sales per customer is also high.
City 2: Delhi

Highest estimated coffee consumers at 7.7 million.
Highest total number of customers, which is 68.
Average rent per customer is 330 (still under 500).
City 3: Jaipur

Highest number of customers, which is 69.
Average rent per customer is very low at 156.
Average sales per customer is better at 11.6k.



