use projectdb;
select count(*) from superstore;
select * from superstore limit 5;

-- 1. what are total sales and total profits of each year?
select year(`order date`) as year , round(sum(sales),2) as total_sales,round(sum(profit),2) as total_profit from superstore
group by year(`order date`)
order by year;

-- 2. what are the total profits and total sales per quarter?
select year (`order date`) as year,
case
    when month(`order date`) in (1,2,3) then 'Q1'
    when month(`order date`) in (4,5,6) then 'Q2'
      when month(`order date`) in (7,8,9) then 'Q3'
      else 'Q4'
      end as quarter,
round(sum(sales),2) as total_sales, round(sum(profit),2) as total_profit
from superstore
group by year, quarter
order by year,quarter;

-- 3. what region generates the highest sales and profits?
select region, round(sum(sales),2) as total_sales, round(sum(profit),2) as total_profit
from superstore
group by region
order by total_profit desc;

-- each region profit margins?
select region , round((sum(profit) / sum(sales)) * 100,2)as profit_margin
from superstore
group by region
order by profit_margin desc;

-- 4. what state and city brings in the highest sales and profits ?
select state,round(sum(sales),2) as total_sales,
round(sum(profit),2) as total_profit,
round((sum(profit) / sum(sales)) * 100,2)as profit_margin from superstore
group by state
order by total_profit desc limit 10;

-- 5. The relationship between discount and sales and total discount per category
select category, round(sum(discount),2) as total_discount
from superstore
group by category
order by total_discount desc;

-- discount vs avg sales
select discount,round(avg(sales),2) as avg_sales from superstore
group by discount order by discount;

-- Most discounted subcategories?
select category,`sub-category`,round(sum(discount),2) as total_discount
from superstore
group by category,`sub-category`
order by total_discount desc;

-- 6. what category generates the highest sale , profits and profit margin in each region and state?
select region,state,category, round(sum(sales),2) as total_sales,
round(sum(profit),2) as total_profit,
round(sum(profit)/sum(sales) * 100,2) as profit_margin
from superstore
group by region, state, category
order by region, state, total_sales desc;

-- 7. what subcategory generates the highest sales,profits, and profit margin in each region and state?
select region,state,`sub-category`, round(sum(sales),2) as total_sales,
round(sum(profit),2) as total_profit,
round(sum(profit)/sum(sales) * 100,2) as profit_margin
from superstore
group by region, state,`sub-category`
order by region, state, total_sales desc;

-- 8. what are the names of the products that are the most and least profitable to us?
select `product name`, round(sum(profit),2) as total_profit
from superstore
group by `product name` 
order by total_profit desc;

-- 9. what segments make most of our profits and sales?
select segment , round(sum(sales),2) as total_sales,
round(sum(profit),2) as total_profit
from superstore
group by segment
order by total_profit desc;

-- 10. how many unique customers do we have in total and how many per region and state?
select count(distinct `customer ID`) as unoique_customers
from superstore;
-- by region and state ?
select region, state ,count(distinct `customer ID`) as unoique_customers
from superstore
group by region ,state
order by region, state desc;

-- 11. customer rewards program - what customers spent most with us?
select `customer ID`, sum(sales) as total_sales from superstore
group by `customer ID`
order by total_sales desc limit 15;

-- 12. Average shipping timer per class in total?
select avg(`ship date` - `order date`) as avg_shipping_time from superstore;
-- shipping mode 
select `ship mode`, avg(datediff(`ship date` , `order date`))as avg_shipping_time from superstore
group by `ship mode`
order by avg_shipping_time;

-- 13. Which products sell above the average product-level sales?
SELECT
    `Product Name`,
    SUM(Sales) AS total_sales
FROM superstore
GROUP BY `Product Name`
HAVING SUM(Sales) > (
    SELECT AVG(product_sales)
    FROM (
        SELECT SUM(Sales) AS product_sales
        FROM superstore
        GROUP BY `Product Name`
    ) AS avg_sales
)
ORDER BY total_sales DESC;

-- 14. Which customers have bought from all three product categories?
SELECT
    `Customer ID`,
    `Customer Name`
FROM superstore
GROUP BY `Customer ID`, `Customer Name`
HAVING COUNT(DISTINCT Category) = 3;

-- 15. What is the year-over-year growth in sales and profit?
WITH yearly_totals AS (
    SELECT
        YEAR(`Order Date`) AS order_year,
        SUM(Sales) AS total_sales,
        SUM(Profit) AS total_profit
    FROM superstore
    GROUP BY YEAR(`Order Date`)
),
growth AS (
    SELECT
        order_year,
        total_sales,
        total_profit,
        LAG(total_sales) OVER (ORDER BY order_year) AS previous_sales,
        LAG(total_profit) OVER (ORDER BY order_year) AS previous_profit
    FROM yearly_totals
)
SELECT
    order_year,
    total_sales,
    total_profit,
    ROUND(
        (total_sales - previous_sales) / NULLIF(previous_sales, 0) * 100,
        2
    ) AS sales_growth_pct,
    ROUND(
        (total_profit - previous_profit) / NULLIF(previous_profit, 0) * 100,
        2
    ) AS profit_growth_pct
FROM growth
ORDER BY order_year;

-- 16. What are the top 3 most profitable products in each category?
WITH product_profits AS (
    SELECT
        Category,
        `Product Name`,
        SUsuperstoresuperstoreM(Profit) AS total_profit
    FROM superstore
    GROUP BY Category, `Product Name`
),
ranked_products AS (
    SELECT
        Category,
        `Product Name`,
        total_profit,
        DENSE_RANK() OVER (
            PARTITION BY Category
            ORDER BY total_profit DESC
        ) AS product_rank
    FROM product_profits
)
SELECT *
FROM ranked_products
WHERE product_rank <= 3
ORDER BY Category, product_rank;

-- 17. What is the running total of sales within each year, month by month?
WITH monthly_sales AS (
    SELECT
        YEAR(`Order Date`) AS order_year,
        MONTH(`Order Date`) AS order_month,
        SUM(Sales) AS total_sales
    FROM superstore
    GROUP BY
        YEAR(`Order Date`),
        MONTH(`Order Date`)
)
SELECT
    order_year,
    order_month,
    total_sales,
    SUM(total_sales) OVER (
        PARTITION BY order_year
        ORDER BY order_month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total_sales
FROM monthly_sales
ORDER BY order_year, order_month;