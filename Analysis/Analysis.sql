


--                                                                                 I. Overall Business Performance & Financial Health

--     1. Revenue & Profit:
        
--     1.1.1	What is our total net revenue for the period of 2023-2024?

with Return_inc as (
select
	round(sum(si.Quantity * p.price),0) as Revenue
from sale_items si
join products p
on si.Product_ID = p.Product_ID
join sales as s
on si.Sale_ID = s.Sale_ID
where s.SaleDate BETWEEN "2023-01-01" and "2023-12-31"
)
select * from return_inc;




--     1.1.2   What is our total cost of goods sold (COGS) and our total gross profit for the same period?

with cte1 as (
select
	round(sum(si.Quantity * p.cost),0) as COGS,
	round(sum(si.Quantity * p.price),0) - round(sum(si.Quantity * p.cost),0) as Gross_Profit
from sale_items si
join products p
on si.Product_ID = p.Product_ID
join sales as s
on si.Sale_ID = s.Sale_ID
where s.SaleDate BETWEEN "2023-01-01" and "2023-12-31"
)
select * from cte1;




--     1.1.3     What is our overall gross profit margin (as a percentage)?

with profit_percentage as (
select
	round(((round(sum(si.Quantity * p.price),0) - round(sum(si.Quantity * p.cost),0))/(round(sum(si.Quantity * p.cost),0)))*100,2) as 'profit margin %'
from sale_items si
join products p
on si.Product_ID = p.Product_ID
join sales as s
on si.Sale_ID = s.Sale_ID
)
select * from profit_percentage;






--            1.2  Growth & Trends:

--      1.2.1      How has our net revenue trended month-over-month and quarter-over-quarter throughout 2023 and 2024? Are there any clear seasonal patterns or significant fluctuations?



--             MOM    


with cte1 as (
SELECT 
    DATE_FORMAT(s.SaleDate, '%y-%m') AS Date,
    monthname(s.SaleDate) as Month,
--     round(sum(s.TotalAmount),0) as Revenue1,
--     round(sum(r.ReturnAmount),0) as returned,
    round(sum(s.TotalAmount)-sum(r.ReturnAmount),0) as Revenue
FROM
    sales s
    left join returns r
    on s.Sale_ID = r.Sale_ID
group by date,Month),

cte2 as (
select 
	Date,
    Month,
    Revenue,
    Lag(Revenue) over(Order by Date asc) as Previous_month
from 
	cte1
)

SELECT 
	Date,
    Month,
    Revenue,
    Previous_month,
    round((revenue - Previous_month)/Previous_month * 100,1) as Growth
FROM
    cte2;



--             YOY


with cte1 as(
SELECT 
  --   DATE_FORMAT(s.SaleDate, '%y') AS year2,
    year(s.SaleDate) as year,
    ROUND(SUM(s.TotalAmount) - SUM(r.ReturnAmount),0) AS Revenue
FROM
    sales s
        LEFT JOIN
    returns r ON s.Sale_ID = r.Sale_ID
GROUP BY year),

cte2 as (
select 
	year,
    Revenue,
    lag(Revenue) over(order by year asc) as Previous_year
from cte1
)

SELECT 
    year,
    Revenue,
    Previous_year,
    round(( Revenue - Previous_year) / Previous_year * 100,1)  as Growth 
FROM
    cte2;  



-- My Opinion 

		-- December 2023 to January 2024 Drop (-29.5%)
		-- This is the most noticeable "fluctuation" in the data, showing a substantial decrease of 29.5% from December 2023 to January 2024.



--       1.2.2	What is the average sales transaction value over the entire period?


with cte1 as(
SELECT 
    COUNT(Sale_ID) AS Num_Completed_Sales, 
    SUM(TotalAmount) AS Revenue
FROM
    Sales
WHERE
    PaymentStatus = 'Completed')
    
SELECT 
    round(Revenue/Num_Completed_Sales,0) as Avg_sales_value
FROM
    cte1;








--                                                                                                 II. Product Performance


--         2.	Best Sellers

--        2.1.1  	Which are our top 10 products by quantity sold ?

SELECT 
    p.ProductName, SUM(si.Quantity) AS Quantity_sold
FROM
    sale_items si
        LEFT JOIN
    products p ON si.Product_ID = p.Product_ID
GROUP BY p.ProductName
ORDER BY Quantity_sold DESC
LIMIT 10;
    

    
--        2.1.2  	Which are our top 10 products by net revenue generated?

with cte1 as (
SELECT 
	p.Product_ID,
    p.ProductName,
    SUM(si.Quantity * p.Price) AS Revenue
FROM
    sale_items si
        LEFT JOIN
    products p ON si.Product_ID = p.Product_ID
GROUP BY p.Product_ID,p.ProductName
) ,

cte2 as (
select 
	r.Product_ID,
	sum(r.ReturnAmount) as retured_total
from returns r
group by Product_ID
)

SELECT 
    cte1.ProductName,
    ROUND(cte1.Revenue - coalesce(cte2.retured_total,0), 0) AS Net_Revenue
FROM
    cte1
        LEFT JOIN
    cte2 ON cte1.Product_ID = cte2.Product_ID
ORDER BY Net_Revenue DESC
LIMIT 10;
    


--                       2.1.3 Top Product Categories by Net Revenue      &      2.1.4 Bottom Product Categories by Net Revenue


with cte1 as(
SELECT 
	si.Product_ID,
	P.productname,
    p.category,
    sum(p.Price * si.Quantity) as revenue
FROM
    Products p
        RIGHT JOIN
    sale_items si ON p.product_ID = si.Product_ID
group by Product_ID , productname, category
order by productName asc),

cte2 as (
select
	r.Product_ID,
	sum(ReturnAmount) as returned
from returns r
group by Product_ID)

SELECT 
-- 	cte1.ProductName,
	cte1.category,
-- 	cte1.revenue,
-- 	cte2.returned,
--  cte1.category,
	sum(ROUND(cte1.revenue - COALESCE(cte2.returned, 0),0)) AS net_revenue
FROM
    cte1
        LEFT JOIN
    cte2 ON cte1.product_ID = cte2.Product_ID
group by category
order by net_revenue desc;



--                       2.1.5 Top Product Categories by Units Sold      &      2.1.6 Bottom Product Categories by Units Sold

with cte1 as(
SELECT 
    si.Product_ID, 
    p.ProductName, 
    p.category,
    SUM(si.Quantity) AS total_sold
FROM
    sale_items si
        LEFT JOIN
    Products p ON si.Product_ID = p.Product_ID
GROUP BY Product_ID , ProductName,category
),

cte2 as (
SELECT 
    r.Product_ID, SUM(r.QuantityReturned) AS returned
FROM
    returns r
GROUP BY Product_ID)

SELECT
    cte1.Category,
	sum(cte1.total_sold - coalesce(cte2.returned,0)) as Units_sold
FROM
    cte1
        LEFT JOIN
    cte2 ON cte1.product_ID = cte2.product_id
Group by Category
order by Units_sold desc ; 
    


--                                       2.1.7	Can you identify the top 5 brands by revenue     
WITH cte1 as(
SELECT 
	p.Product_ID,
    p.brand, 
    SUM(p.price * si.quantity) AS Revenue
FROM
    products p
        LEFT JOIN
    sale_items si ON p.Product_ID = si.Product_ID
GROUP BY p.Product_ID, p.brand
),

cte2 as(
SELECT 
    r.Product_ID,
    sum(r.ReturnAmount) as Returned
FROM
    returns r
GROUP BY r.Product_ID
)

SELECT 
    cte1.brand,
    round(sum(cte1.revenue - coalesce(cte2.returned,0)),0) as Net_revenue
FROM
    cte1
        LEFT JOIN
    cte2 ON cte1.product_ID = cte2.Product_ID
GROUP BY cte1.brand
ORDER BY Net_revenue desc
limit 5;


--                                       2.1.8    Can you identify the top 5 brands by gross profit?

-- 1st way (more efficient) --> because data size is small because of the ctes, they filter most columns and then join)

WITH cte1 as(
SELECT 
    Product_ID, SUM(Quantity) AS Sold_Quantity
FROM
    sale_items si
GROUP BY Product_ID
),

cte2 as(
SELECT 
    Product_ID, SUM(QuantityReturned) AS returned_Quantity
FROM
    returns r
GROUP BY Product_ID),

cte3 as(
select 
	cte1.Product_ID,
	--   Sold_Quantity,
	--   returned_Quantity,
    cte1.Sold_Quantity - coalesce(cte2.returned_Quantity,0) as remained_quantity
from cte1 
	left join cte2
    on cte1.product_ID = cte2.Product_ID
),
cte4 as (
SELECT 
    cte3.Product_ID,
    cte3.remained_quantity,
    p.brand,
    p.price - p.cost as Profit
FROM
    cte3 left join
    products p
    on cte3.product_ID = P.product_ID)
    
SELECT 
	brand,
    round(sum(remained_quantity * Profit),0) as Gross_Profit
FROM
    cte4
    group by brand
Order by  Gross_Profit desc
limit 5;




  -- 2nd way (looks good but aa little less efficient )


WITH cte1 as( 
SELECT 
    si.Product_ID,
    SUM(si.Quantity) - COALESCE(SUM(r.QuantityReturned), 0) AS Remained_quantity
FROM
    sale_items si
        LEFT JOIN
    returns r ON si.Sale_ID = r.Sale_ID
        AND si.Product_ID = r.Product_ID
GROUP BY Product_ID
ORDER BY Product_ID ASC
),

cte2 as(
SELECT 
    Product_ID,
    Brand,
    price - cost as Profit
FROM
    products p
)

SELECT 
    cte2.brand,
    round(sum(cte1.Remained_quantity * coalesce(cte2.profit,0)),0) AS Gross_Profit
FROM
    cte1
        LEFT JOIN
    cte2 ON cte1.Product_Id = cte2.Product_Id
GROUP BY cte2.brand
ORDER BY Gross_Profit DESC
LIMIT 5;




--                                                                                          2.2	Profitability by Product


--                                 2.2.1              What is the average gross profit margin per product category?


WITH cte1 as(
SELECT 
    Product_ID, 
    SUM(Quantity) AS Sold_Quantity
FROM
    sale_items si
GROUP BY Product_ID
),

cte2 as(
SELECT 
    Product_ID, 
    SUM(QuantityReturned) AS returned_Quantity
FROM
    returns r
GROUP BY Product_ID),

cte3 as(
select 
	cte1.Product_ID,
	--   Sold_Quantity,
	--   returned_Quantity,
    cte1.Sold_Quantity - coalesce(cte2.returned_Quantity,0) as remained_quantity
from cte1 
	left join cte2
    on cte1.product_ID = cte2.Product_ID
),
cte4 as (
SELECT 
    cte3.Product_ID,
    cte3.remained_quantity,
    p.Category,
    p.Price,
    p.cost,
    p.price - p.cost as Profit
FROM
    cte3 left join
    products p
    on cte3.product_ID = P.product_ID),

cte5 as ( 
SELECT 
    Category,
    ROUND(SUM(remained_quantity * cost), 0) AS COGS,
    ROUND(SUM(remained_quantity * Profit), 0) AS Gross_Profit
FROM
    cte4
GROUP BY Category
)

SELECT 
    Category,
    COGS,
    Gross_Profit,
    round(Gross_Profit / COGS * 100,1) as 'Gross Margin %'
FROM
    cte5
GROUP BY Category;





--                 2.2.2  Are there any specific products that have significantly higher gross profit margins than the average?

WITH cte1 as(
SELECT 
    Product_ID, 
    SUM(Quantity) AS Sold_Quantity
FROM
    sale_items si
GROUP BY Product_ID
),

cte2 as(
SELECT 
    Product_ID, 
    SUM(QuantityReturned) AS returned_Quantity
FROM
    returns r
GROUP BY Product_ID),

cte3 as(
select 
	cte1.Product_ID,
	--   Sold_Quantity,
	--   returned_Quantity,
    cte1.Sold_Quantity - coalesce(cte2.returned_Quantity,0) as remained_quantity
from cte1 
	left join cte2
    on cte1.product_ID = cte2.Product_ID
),
cte4 as (
SELECT 
    cte3.Product_ID,
    p.ProductName,
    cte3.remained_quantity,
    p.Category,
    p.Price,
    p.cost,
    p.price - p.cost as Profit
FROM
    cte3 left join
    products p
    on cte3.product_ID = P.product_ID),

cte5 as ( 
SELECT 
    ProductName,
    ROUND(SUM(remained_quantity * cost), 0) AS COGS,
    ROUND(SUM(remained_quantity * Profit), 0) AS Gross_Profit
FROM
    cte4
GROUP BY ProductName
),

cte6 as (
SELECT 
    ProductName,
	COGS,
	Gross_Profit,
    round(Gross_Profit / COGS * 100,1) as Gross_Margin_Percent
FROM
    cte5
GROUP BY ProductName
),

cte7 as(
SELECT 
    ROUND((SUM(Gross_Profit) / SUM(COGS)) * 100, 1) as Avg_Gross_Margin_Percent
FROM
    cte6
)

SELECT 
    cte6.ProductName,
    cte6.Gross_Margin_Percent,
    cte7.Avg_Gross_Margin_Percent,
    ROUND(Gross_Margin_Percent - Avg_Gross_Margin_Percent,
            1) AS Difference_of_Gross_Margin_percent
FROM
    cte6
        CROSS JOIN
    cte7
WHERE
    ROUND(Gross_Margin_Percent - Avg_Gross_Margin_Percent,
            1) >= 25
ORDER BY Difference_of_Gross_Margin_percent DESC;



--                                        2.2.3  Are there any specific products that have significantly lower gross profit margins than the average?

WITH cte1 as(
SELECT 
    Product_ID, 
    SUM(Quantity) AS Sold_Quantity
FROM
    sale_items si
GROUP BY Product_ID
),

cte2 as(
SELECT 
    Product_ID, 
    SUM(QuantityReturned) AS returned_Quantity
FROM
    returns r
GROUP BY Product_ID),

cte3 as(
select 
	cte1.Product_ID,
	--   Sold_Quantity,
	--   returned_Quantity,
    cte1.Sold_Quantity - coalesce(cte2.returned_Quantity,0) as remained_quantity
from cte1 
	left join cte2
    on cte1.product_ID = cte2.Product_ID
),
cte4 as (
SELECT 
    cte3.Product_ID,
    p.ProductName,
    cte3.remained_quantity,
    p.Category,
    p.Price,
    p.cost,
    p.price - p.cost as Profit
FROM
    cte3 left join
    products p
    on cte3.product_ID = P.product_ID),

cte5 as ( 
SELECT 
    ProductName,
    ROUND(SUM(remained_quantity * cost), 0) AS COGS,
    ROUND(SUM(remained_quantity * Profit), 0) AS Gross_Profit
FROM
    cte4
GROUP BY ProductName
),

cte6 as (
SELECT 
    ProductName,
	COGS,
	Gross_Profit,
    round(Gross_Profit / COGS * 100,1) as Gross_Margin_Percent
FROM
    cte5
GROUP BY ProductName
),

cte7 as(
SELECT 
    ROUND((SUM(Gross_Profit) / SUM(COGS)) * 100, 1) as Avg_Gross_Margin_Percent
FROM
    cte6
)

SELECT 
    cte6.ProductName,
    cte6.Gross_Margin_Percent,
    cte7.Avg_Gross_Margin_Percent,
    ROUND(Gross_Margin_Percent - Avg_Gross_Margin_Percent,
            1) AS Difference_of_Gross_Margin_percent
FROM
    cte6
        CROSS JOIN
    cte7
WHERE
    ROUND(Gross_Margin_Percent - Avg_Gross_Margin_Percent,
            1) <= - 20
ORDER BY Difference_of_Gross_Margin_percent ASC;



--                                        2.2.4  Are there any specific Brand that have significantly Higher gross profit margins than the average?

WITH cte1 as(
SELECT 
    Product_ID, 
    
    SUM(Quantity) AS Sold_Quantity
FROM
    sale_items si
GROUP BY Product_ID
),

cte2 as(
SELECT 
    Product_ID, 
    SUM(QuantityReturned) AS returned_Quantity
FROM
    returns r
GROUP BY Product_ID),

cte3 as(
select 
	cte1.Product_ID,
	--   Sold_Quantity,
	--   returned_Quantity,
    cte1.Sold_Quantity - coalesce(cte2.returned_Quantity,0) as remained_quantity
from cte1 
	left join cte2
    on cte1.product_ID = cte2.Product_ID
),
cte4 as (
SELECT 
    cte3.Product_ID,
    p.ProductName,
    p.Brand,
    cte3.remained_quantity,
    p.Category,
    p.Price,
    p.cost,
    p.price - p.cost as Profit
FROM
    cte3 left join
    products p
    on cte3.product_ID = P.product_ID),

cte5 as ( 
SELECT 
    Brand,
    ROUND(SUM(remained_quantity * cost), 0) AS COGS,
    ROUND(SUM(remained_quantity * Profit), 0) AS Gross_Profit
FROM
    cte4
GROUP BY Brand
),

cte6 as (
SELECT 
    Brand,
	COGS,
	Gross_Profit,
    round(Gross_Profit / COGS * 100,1) as Gross_Margin_Percent
FROM
    cte5
GROUP BY Brand
),

cte7 as(
SELECT 
    ROUND((SUM(Gross_Profit) / SUM(COGS)) * 100, 1) as Avg_Gross_Margin_Percent
FROM
    cte6
)

SELECT 
    cte6.Brand,
    cte6.Gross_Margin_Percent,
    cte7.Avg_Gross_Margin_Percent,
    ROUND(Gross_Margin_Percent - Avg_Gross_Margin_Percent,
            1) AS Difference_of_Gross_Margin_percent
FROM
    cte6
        CROSS JOIN
    cte7
WHERE
    ROUND(Gross_Margin_Percent - Avg_Gross_Margin_Percent,
            1) >= 25
ORDER BY Difference_of_Gross_Margin_percent desc;



--                                        2.2.5  Are there any specific Brand that have significantly lower gross profit margins than the average?

WITH cte1 as(
SELECT 
    Product_ID, 
    SUM(Quantity) AS Sold_Quantity
FROM
    sale_items si
GROUP BY Product_ID
),

cte2 as(
SELECT 
    Product_ID, 
    SUM(QuantityReturned) AS returned_Quantity
FROM
    returns r
GROUP BY Product_ID),

cte3 as(
select 
	cte1.Product_ID,
	--   Sold_Quantity,
	--   returned_Quantity,
    cte1.Sold_Quantity - coalesce(cte2.returned_Quantity,0) as remained_quantity
from cte1 
	left join cte2
    on cte1.product_ID = cte2.Product_ID
),

cte4 as (
SELECT 
    cte3.Product_ID,
    p.ProductName,
    p.Brand,
    cte3.remained_quantity,
    p.Category,
    p.Price,
    p.cost,
    p.price - p.cost as Profit
FROM
    cte3 left join
    products p
    on cte3.product_ID = P.product_ID),

cte5 as ( 
SELECT 
    Brand,
    ROUND(SUM(remained_quantity * cost), 0) AS COGS,
    ROUND(SUM(remained_quantity * Profit), 0) AS Gross_Profit
FROM
    cte4
GROUP BY Brand
),

cte6 as (
SELECT 
    Brand,
	COGS,
	Gross_Profit,
    round(Gross_Profit / COGS * 100,1) as Gross_Margin_Percent
FROM
    cte5
GROUP BY Brand
),

cte7 as(
SELECT 
    ROUND((SUM(Gross_Profit) / SUM(COGS)) * 100, 1) as Avg_Gross_Margin_Percent
FROM
    cte6
)

SELECT 
    cte6.Brand,
    cte6.Gross_Margin_Percent,
    cte7.Avg_Gross_Margin_Percent,
    ROUND(Gross_Margin_Percent - Avg_Gross_Margin_Percent,
            1) AS Difference_of_Gross_Margin_percent
FROM
    cte6
        CROSS JOIN
    cte7
WHERE
    ROUND(Gross_Margin_Percent - Avg_Gross_Margin_Percent,
            1) <= - 20
ORDER BY Difference_of_Gross_Margin_percent ASC;




--                                                            2.3    Size & Material Analysis


--                 2.3.1       For our top-selling products, what are the most popular sizes? Does this vary by gender category?


--  	 applying a WHERE clause in the final SELECT statement to filter by CustomerGender (e.g., 'Male' or 'Female'), you achieve a segmented view of the data.


WITH cte1 as(
SELECT 
    si.Product_ID,
    p.ProductName,
    sum(si.Quantity) as total_sold
FROM
    sale_items si
        LEFT JOIN
    products p ON si.Product_ID = p.Product_ID
GROUP BY si.Product_ID, p.ProductName
),

cte2 as(
SELECT 
    Product_ID,
    sum(QuantityReturned) as total_returned
FROM
    returns r
GROUP BY Product_ID
),

cte3 as(    
SELECT 
    cte1.product_ID, 
    cte1.ProductName,
    cte1.total_sold - coalesce(cte2.total_returned,0) as net_sold
FROM
    cte1
        LEFT JOIN
    cte2 ON cte1.Product_ID = cte2.Product_ID
),

cte_added as (
select
	product_ID,
    productname,
    net_sold,
    rank() over(order by net_sold desc) as top_rank
from cte3
),

cte4 as (
SELECT 
    cte_added.Product_ID,
    cte_added.productName,
    c.Gender as CustomerGender,
    si.Size_ID,
	sum(si.Quantity) AS cc,
	top_rank
FROM
    cte_added
        JOIN
    sale_items si ON cte_added.product_ID = si.Product_ID
		INNER JOIN
	Sales s on si.Sale_ID = s.Sale_ID
		INNER JOIN
	customers c on s.Customer_ID = c.Customer_ID
where top_rank <= 2
GROUP BY cte_added.Product_ID , cte_added.productName , si.Size_ID, c.Gender
ORDER BY cte_added.productName ASC , cc DESC
),

cte5 as (
SELECT 
    Product_ID,
    productName,
    CustomerGender,
    Size_ID,
    cc,
    DENSE_RANK() over(PARTITION BY productname,CustomerGender order by cc desc) as rnk,
    top_rank
FROM
    cte4
),

final as (
SELECT 
    ProductName, CustomerGender, Size_ID, cc, rnk, top_rank
FROM
    cte5
WHERE
    rnk <= 5
)

SELECT
	CustomerGender,
    ProductName, 
    Size_ID, 
    cc AS pair_sold, 
    rnk
FROM
    final
WHERE
    CustomerGender = 'Male' or CustomerGender = 'Female'
ORDER BY top_rank ASC;



--                            2.3.2          Which materials (e.g., Leather, Synthetic, Canvas) are most popular ?


with cte1 as (
SELECT 
    p.material, 
    SUM(si.quantity) AS total_Sold
FROM
    Products p
        RIGHT JOIN
    sale_items si ON p.Product_ID = si.Product_ID
GROUP BY p.material
),

cte2 as(
SELECT 
    p.Material, SUM(QuantityReturned) AS Quantity_Returned
FROM
    returns r
        LEFT JOIN
    products p ON r.Product_ID = p.Product_ID
GROUP BY p.material
)

SELECT 
    cte1.Material,
    SUM(cte1.total_sold - cte2.Quantity_Returned) AS Sold
FROM
    cte1
        LEFT JOIN
    cte2 ON cte1.Material = cte2.Material
GROUP BY material
ORDER BY sold DESC;



--                                 2.3.3 Which materials contribute how much to overall revenue and profit?

with cte1 as(
SELECT 
    si.Product_ID, SUM(Quantity) AS total_sold
FROM
    sale_items si
GROUP BY si.Product_ID
),

cte2 as(
SELECT 
    Product_ID, SUM(QuantityReturned) AS quantity_returned
FROM
    returns r
GROUP BY Product_ID
),

cte3 as(
SELECT 
    cte1.Product_ID,
    cte1.total_sold - coalesce(cte2.quantity_returned,0) AS sold
FROM
    cte1
        LEFT JOIN
    cte2 ON cte1.Product_Id = cte2.Product_Id
),

cte4 as(
SELECT 
    p.Price, p.cost, cte3.sold, p.Material
FROM
    cte3
        JOIN
    products p ON cte3.Product_ID = p.Product_ID
),

cte5 as(
SELECT 
    material,
    round(SUM(Price * sold),0) AS revenue,
    round(SUM(Cost * sold),0) AS COGS,
    round(SUM(Price * sold) - SUM(Cost * sold) ,0) as Profit
FROM
    cte4
GROUP BY material
)

SELECT 
    material,
    revenue,
    COGS,
    profit,
    round((revenue / SUM(revenue) over()) * 100,1) AS revenue_contribution,
    round((profit / SUM(profit) over())* 100,1) AS Profit_contribution
FROM
    cte5
ORDER BY revenue_contribution desc;








--                                                                     III. Customer Insights


--                      3.1        Demographics & Spending

--                      3.1.1      What is the distribution of our customer base by gender and city?


SELECT 
    Gender,
    City,
    COUNT(DISTINCT (Customer_ID)) AS Number_of_Customers
FROM
    customers c
GROUP BY city , Gender
ORDER BY Number_of_Customers DESC;


--                      3.1.2      How does average spending (average transaction value) differ between male and female customers? 

SELECT 
    DISTINCT(c.gender) as gender,
    round(avg(TotalAmount) over(partition by gender),0) as  Avg_spending
FROM
    sales s 
		left join
	Customers c
		on s.Customer_ID = c.Customer_ID
where PaymentStatus= "completed";




--                      3.1.3      Which cities are generating the most customer traffic and revenue? 

WITH city as(
SELECT 
    Customer_ID,
    city
FROM
    customers c
),

customer as (    
SELECT 
    Customer_ID,
    SUM(TotalAmount) as Revenue
FROM
    sales
WHERE PaymentStatus="Completed"
GROUP BY Customer_ID
)

SELECT DISTINCT
    City,
    COUNT(customer.customer_Id) AS Number_of_Customer,
    ROUND(SUM(Revenue), 0) AS Revenue
FROM
    City
        RIGHT JOIN
    customer ON city.customer_ID = customer.customer_ID
GROUP BY City
ORDER BY Revenue DESC;



--                      3.2.1      What is the average number of distinct items a customer buys in a single sale?


WITH Item_unique AS(
SELECT 
    Sale_ID,
    count(DISTINCT(Product_ID)) as Unique_item
FROM
    sale_items si
GROUP BY Sale_ID
)

SELECT 
    ROUND(AVG(Unique_item), 2) AS Avg_item_number
FROM
    Item_unique;
    
    
    




--                                                                     IV. Store & Employee Performance


--                      4.1        Store Performance

--                      4.1.1      Which are our top 3 performing stores in terms of net revenue for the entire period?
With sale as(
SELECT 
    Store_ID, TotalAmount
FROM
    sales
WHERE
    PaymentStatus = "Completed"
),

Store as(
SELECT 
    StoreID, Address
FROM
    stores
)

SELECT 
    sale.Store_ID,
    round(sum(TotalAmount),0) as Revenue,
    store.Address
FROM
    sale
        LEFT JOIN
    Store ON sale.Store_ID = store.StoreID
GROUP BY  sale.Store_ID
ORDER BY Revenue DESC 
limit 3;




--                      4.1.2      Which are our bottom 3 performing stores in terms of net revenue for the entire period?

With sale as(
SELECT 
    Store_ID, TotalAmount
FROM
    sales
WHERE
    PaymentStatus = "Completed"
),

Store as(
SELECT 
    StoreID, Address
FROM
    stores
)

SELECT 
    sale.Store_ID,
    round(sum(TotalAmount),0) as Revenue,
    store.Address
FROM
    sale
        LEFT JOIN
    Store ON sale.Store_ID = store.StoreID
GROUP BY  sale.Store_ID
ORDER BY Revenue ASC 
limit 3;



--                      4.1.3      How does the average transaction value compare across our different stores?

SELECT 
    sa.Store_ID,
    st.address,
    ROUND(AVG(sa.TotalAmount), 0) AS avg_transaction_value
FROM
    sales sa
        LEFT JOIN
    Stores st ON sa.Store_ID = st.StoreID
GROUP BY Store_ID, st.address
ORDER BY avg_transaction_value DESC;




--                      4.2        Employee Contribution

--                      4.2.1      Who are our top 5 sales associates by total sales amount?

SELECT 
    Employee_ID,
    ROUND(SUM(TotalAmount), 0) AS Total_sold,
    CONCAT(e.firstname, ' ', lastName) AS Name
FROM
    sales s
        LEFT JOIN
    employees e ON s.Employee_ID = e.EmployeeID
WHERE
    PaymentStatus = 'Completed'
GROUP BY Employee_ID
ORDER BY Total_sold DESC
LIMIT 5;



--                      4.2.2      How does the average sales amount per transaction differ between transactions handled by a 'Cashier' versus a 'Sales Associate'?

SELECT 
    e.role,
    ROUND(AVG(TotalAmount), 0) AS Total_sold
FROM
    sales s
        LEFT JOIN
    employees e ON s.Employee_ID = e.EmployeeID
WHERE
    PaymentStatus = 'Completed'
GROUP BY e.role;






--                                                                   V. Operational Efficiency & Returns


--                      5.1        Returns Analysis

--                      5.1.1      What is our overall return rate (total return amount as a percentage of total sales amount)?

with Total as (
SELECT 
    round(sum(case when s.PaymentStatus="completed" then s.TotalAmount else 0 end),0) as Revenue 
FROM
    sales s
),

returned as(
SELECT 
    ROUND(SUM(ReturnAmount), 0) AS Returned_amount
FROM
    returns r
)

SELECT 
    Revenue,
    Returned_amount,
    ROUND(Returned_amount / Revenue * 100, 1) AS Percentage_of_total_sales_amount
FROM
    Total
        CROSS JOIN
    returned;


--                      5.1.2      What are the top 5 most common reasons for returns?

SELECT 
	Reason, COUNT(Reason) AS Count
FROM
    returns
GROUP BY Reason
ORDER BY Count DESC
limit 5;


--                      5.1.3      Are there specific products that have a disproportionately high return rate?


WITH Returned as(
SELECT 
    Product_ID,
    sum(QuantityReturned) as returned_amount
FROM
    returns
GROUP BY Product_ID
),

Total as(
SELECT 
    Product_ID,
    sum(Quantity) as Sold
FROM
    sale_items si
GROUP BY Product_ID
),

Test as(
SELECT 
    t.Product_ID,
    t.sold,
    r.returned_amount,
    ROUND(r.returned_amount / nullif(t.sold,0) * 100, 1) Return_Percentage
FROM
    Returned r
        RIGHT JOIN
    Total t ON r.Product_ID = t.Product_ID
ORDER BY Return_Percentage DESC
),

final as(
SELECT 
	t.Product_ID,
    p.ProductName,
    t.sold,
	t.returned_amount,
    t.Return_Percentage,
    DENSE_RANK() over(ORDER BY Return_Percentage desc) as rnk
from test t
	left join products p 
on t.Product_ID = p.Product_ID
)
SELECT 
    *
FROM
    final
WHERE
    rnk <= 3;



--                      5.1.4      Are there specific categories that have a disproportionately high return rate?
WITH Total as(
SELECT 
    Product_ID,
    sum(Quantity) as Quantity
FROM
    sale_items
GROUP BY Product_ID
),

total_sold as(
SELECT 
    p.Category,
    sum(t.Quantity) as Quantity
    
FROM
    total t
        JOIN
    products p ON t.product_ID = p.Product_ID
GROUP BY p.Category
),

returned as(
SELECT 
    Product_ID,
    sum(QuantityReturned) as returned
FROM
    returns r
GROUP BY Product_ID
),

total_returned as(
SELECT 
    p.Category,
    sum(r.returned) as returned_Quantity
    
FROM
    returned r
        JOIN
    products p ON r.product_ID = p.Product_ID
GROUP BY p.Category
)

SELECT 
    ts.Category,
    ts.Quantity,
    tr.returned_Quantity,
    ROUND(coalesce(tr.returned_Quantity,0) /nullif(ts.Quantity,0) * 100,
            2) AS Percentage
FROM
    total_sold ts
        LEFT JOIN
    total_returned tr ON ts.Category = tr.Category
ORDER BY Percentage DESC;



--                      5.2        Payment Methods

--                      5.2.1      What are the most frequently used payment methods (Cash, Credit Card, etc.)?

SELECT 
    PaymentMethod, COUNT(Payment_ID) AS Count
FROM
    payments
GROUP BY PaymentMethod
ORDER BY Count DESC;


--                      5.2.2      what percentage of total payments does each payment methods account for?

WITH Payment_methods as(
SELECT 
    p.PaymentMethod,
    round(sum(p.PaymentAmount),0) as Amount
FROM
    sales s
    left join payments p 
    on s.Payment_ID = p.Payment_ID
WHERE
    PaymentStatus = 'Completed'
GROUP BY p.PaymentMethod
),

Total as(
SELECT 
    round(sum(TotalAmount),0) as Total
FROM
    sales
WHERE
    PaymentStatus = 'Completed'
)

SELECT 
    pm.PaymentMethod,
    pm.Amount,
    t.Total,
    round(coalesce(pm.Amount,0) /  nullif(t.Total,0) * 100,2) as Percentage
FROM
    Payment_methods pm
        CROSS JOIN
    Total t
ORDER BY Percentage DESC;



--                      5.2.3      What percentage of our sales involve multiple payment tenders?

WITH Total_sale as(
SELECT 
    count(Sale_ID) as toal
FROM
    sales
),

cte2 as(
SELECT 
    DISTINCT (sale_ID) as sale_id,
    count(Payment_ID) as number_of_payment
FROM
    payments
GROUP BY Sale_ID
),

multiple as(
SELECT 
    count(sale_id) as multiple_payment
FROM
    cte2
where number_of_payment>1
)

SELECT 
    ts.toal,
    m.multiple_payment,
    round(coalesce(m.multiple_payment,0) / nullif(ts.toal,0) * 100 ,2) as Percentage
FROM
    Total_sale ts
        CROSS JOIN
    multiple m;
