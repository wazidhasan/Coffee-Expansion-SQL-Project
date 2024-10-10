create database coffee;
use coffee;
select *from city;
select*from customers;
select*from products;
select*from sales;
-------------------------------------------------------------------------------------------
#Q1 Coffee consumer count.
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?
select city_name,
round((population*.25)/1000000,2)  as 'coff_population_in_million',
city_rank from city
order by coff_population_in_million desc;
--------------------------------------------------------------------------------------------------
#Q2. Total Revenue from coffee sales.
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

select
	ci.city_name , 
	sum(s.total) as "Total_revenue_of_last_Quarter"
	from sales s
	join customers c on s.customer_id=c.customer_id
	join city ci on ci.city_id=c.city_id
	where extract(year from s.sale_date)=2023 and 
	extract(quarter from s.sale_date)=4
	group by ci.city_name 
	order by Total_revenue_of_last_Quarter desc;
----------------------------------------------------------------------------------------------------
-- Q3 Sales Count for Each Product
-- How many units of each coffee product have been sold?
select p.product_name,count(s.product_id) as 'Sold_qty' from 
sales s join products p on p.product_id =s.product_id
group by p.product_name order by Sold_qty desc;
------------------------------------------------------------------------------------------------------
-- Average Sales Amount per City
-- What is the average sales amount per customer in each city?
select ci.city_name,sum(s.total)/count(distinct(c.customer_id)) as 'Avg_sale_per_cx'
from sales s join customers c on s.customer_id=c.customer_id
join city ci on ci.city_id=c.city_id
group by ci.city_name order by Avg_sale_per_cx desc;
-----------------------------------------------------------------------------------------------------
-- City Population and Coffee Consumers
-- Provide a list of cities along with their populations and estimated coffee consumers.
with ct_tbl as (
select city_name,(population*0.25) as 'Coffee_consumers' from city
),
cx_tbl as (
		select ci.city_name,count(distinct(s.customer_id)) as 'Unique_customers'
		from city ci join customers c on ci.city_id =c.city_id 
		join sales s on s.customer_id=c.customer_id
		group by ci.city_name order by Unique_customers desc
)
	select cx_tbl.city_name,ct_tbl.Coffee_consumers,cx_tbl.Unique_customers
	from ct_tbl
	join cx_tbl
	on ct_tbl.city_name=cx_tbl.city_name
	order by cx_tbl.Unique_customers desc;
-----------------------------------------------------------------------------------------------------
-- Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?
select * from (
select ci.city_name,
		p.product_name,count(distinct(s.sale_id)) as 'Total_orders'
		,dense_rank() over(partition by ci.city_name order by count(distinct(s.sale_id)) desc ) as salrank
		from sales s 
		join products p 
		on s.product_id=p.product_id
		join customers c
		on c.customer_id=s.customer_id
		join city ci
		on ci.city_id=c.city_id
		group by ci.city_name,p.product_name
 ) as t
where salrank<=3;

-----------------------------------------------------------------------------------------------------
-- Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?
select ci.city_name,
		count(distinct(s.customer_id)) as 'Unique_customers'
		from city ci 
		join customers c
		on ci.city_id =c.city_id 
		join sales s 
		on s.customer_id=c.customer_id
		group by ci.city_name
		order by Unique_customers desc;
 --------------------------------------------------------------------------------------------------------
--  Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer

with ct_tbl
as(
		select ci.city_name,
		count(distinct(c.customer_id)) as 'Unique_cx',
		sum(s.total)/count(distinct(c.customer_id)) as 'Avg_sale_per_cx'
		from sales s
		join customers c 
		on s.customer_id=c.customer_id
		join city ci 
		on ci.city_id=c.city_id
		group by ci.city_name 
		order by Avg_sale_per_cx desc
	),
cr_rent as
(
	select city_name,
	estimated_rent
	from city
)
select ct.city_name,
cr.estimated_rent,
ct.Avg_sale_per_cx,
ct.Unique_cx,
 cr.estimated_rent/ct.unique_cx as 'Avg_rent'
 from cr_rent cr join ct_tbl ct
 on ct.city_name=cr.city_name
 order by avg_sale_per_cx desc ;
 ---------------------------------------------------------------------------------------------------------------
 
--  Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly).
with monthly_sale
 as (  
select
	ci.city_name,
    extract(month from s.sale_date) as months,
	extract(year from s.sale_date) as year_,
	sum(s.total) as 'Total_sale'
	from sales s 
    inner join customers c
    on s.customer_id =c.customer_id
	join city  ci
    on ci.city_id=c.city_id
	group by ci.city_name,months,year_ 
    order by ci.city_name,year_,months
),
growth as (
		select city_name,
		months,
		year_,
		Total_sale as 'current_month_sale',
		lag(total_sale,1) over(partition by city_name order by year_,months) as 'Previous_month_sale'
        
		from monthly_sale
)
select 
city_name,
months,
year_,
current_month_sale,
Previous_month_sale,
ROUND((current_month_sale - previous_month_sale) / previous_month_sale * 100, 2)as "growth_per_month"
from growth where previous_month_sale is not null;
----------------------------------------------------------------------------------------------------------
-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer.
with ct_tbl
as (
		select ci.city_name,
		count(distinct(c.customer_id)) as 'Unique_cx',
        sum(total) as "Total_revenue",
		round(sum(s.total)/count(distinct(c.customer_id)),2) as 'Avg_sale_per_cx'
		from sales s
		join customers c 
		on s.customer_id=c.customer_id
		join city ci 
		on ci.city_id=c.city_id
		group by ci.city_name 
		order by Avg_sale_per_cx desc
	),
cr_rent as(
		select city_name,
		estimated_rent,
        round((population*.25)/1000000,2) as 'Coffee_consumer'
        from city
			)
select ct.city_name,
ct.Total_revenue,
cr.estimated_rent as 'Total_rent',
ct.Unique_cx as "Total_cx",
cr.coffee_consumer as "Estimated_coffee_consumer_in_million",
ct.Avg_sale_per_cx,
 round(cr.estimated_rent/ct.unique_cx,2)as 'Avg_rent'
 from cr_rent cr join ct_tbl ct
 on ct.city_name=cr.city_name
 order by avg_sale_per_cx desc ;

#Recomendations---
-- We can go with these Top 3 cities
-- city1- Pune
		-- 	   1.Avg rent is very less
--             2.Highest Renvenue 
--             3.Good cx volume/amount and avg sale is also good 
-- city2-Delhi
--             1.Huge amount of coffee consumer 
--             2.Avg sales is good  
--             3. Avg rent less than 500 and cx count is 68 e.i good.
-- city3-Jaipur
--             1.Huge amount of cx and with good avg_sale amount
--             2.Lowest Avg rent  
--             3.Lowest Total_rent










































