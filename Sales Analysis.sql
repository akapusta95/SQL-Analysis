-- Select sales and quantity by product and category; 
-- Get the profit, profit percantage and daily sales by date;

WITH Sales_cte
AS
(
SELECT
A.CATEGORY AS Category,
PRODUCT AS Product,
DATE AS Date,
QUANTITY AS Quantity,
A.[SELLING PRICE] AS Selling_Price,
A.[BUYING PRIZE] AS Buying_Price,
SUM(A.[SELLING PRICE]*B.Quantity*(1-B.[DISCOUNT %])) AS Total_Sales_Value,
SUM(A.[BUYING PRIZE]*B.Quantity) AS Total_Purchase_Value
FROM MasterSales A
JOIN Sales B
ON A.[PRODUCT ID] = B.[PRODUCT ID]
GROUP BY CATEGORY, PRODUCT, DATE, QUANTITY, [SELLING PRICE], [BUYING PRIZE]
)
SELECT *
	, FORMAT((Total_Sales_Value - Total_Purchase_Value), 'N2') AS Total_Profit
	, FORMAT(((Total_Sales_Value - Total_Purchase_Value)/Total_Purchase_Value), 'N2') AS Profit_Percentage
	, SUM(Quantity) OVER (PARTITION BY CATEGORY) AS Total_Orders_by_Category
	, SUM(Total_Sales_Value) OVER (PARTITION BY CATEGORY) AS Total_Sales_by_Category
	, SUM(Quantity) OVER (PARTITION BY PRODUCT) AS Total_Orders_by_Product
	, SUM(Total_Sales_Value) OVER (PARTITION BY PRODUCT) AS Total_Sales_by_Product
	, SUM(Selling_Price) OVER (PARTITION BY DATE) AS Daily_Sales

FROM Sales_cte
GROUP BY CATEGORY, PRODUCT, DATE, QUANTITY, Selling_Price, Buying_Price, Total_Sales_Value, Total_Purchase_Value
ORDER BY DATE



-- Select the best product with good returns for January 2021;

SELECT TOP 1 PRODUCT, SUM(A.[SELLING PRICE]*B.Quantity*(1-B.[DISCOUNT %])) AS Total_Sales_Value,
SUM(Quantity) AS Quantity
FROM MasterSales A
JOIN Sales B
ON A.[PRODUCT ID] = B.[PRODUCT ID]
WHERE MONTH(DATE) = 01
AND YEAR(DATE) = 2021
GROUP BY PRODUCT
ORDER BY Total_Sales_Value DESC



-- Select the best category with good returns;

SELECT TOP 1 CATEGORY, SUM(A.[SELLING PRICE]*B.Quantity*(1-B.[DISCOUNT %])) AS Total_Sales_Value
FROM MasterSales A
JOIN Sales B
ON A.[PRODUCT ID] = B.[PRODUCT ID]
GROUP BY CATEGORY
ORDER BY Total_Sales_Value DESC



-- Show WTD, MTD, QTD, YTD sales partition by product id;

SELECT A.[PRODUCT ID] AS Product_ID, DATE AS Date, SUM(A.[SELLING PRICE]*B.Quantity*(1-B.[DISCOUNT %])) AS Revenue,
SUM(A.[SELLING PRICE]*B.Quantity*(1-B.[DISCOUNT %])) OVER (Partition BY A.[PRODUCT ID], DATEPART(WEEK, DATE) ORDER BY DATE) AS WTD,
SUM(A.[SELLING PRICE]*B.Quantity*(1-B.[DISCOUNT %])) OVER (Partition BY A.[PRODUCT ID], MONTH(DATE) ORDER BY DATE) AS MTD,
SUM(A.[SELLING PRICE]*B.Quantity*(1-B.[DISCOUNT %])) OVER (Partition BY A.[PRODUCT ID], YEAR(DATE), DATEPART(QUARTER, DATE) ORDER BY DATE) AS QTD,
SUM(A.[SELLING PRICE]*B.Quantity*(1-B.[DISCOUNT %])) OVER (Partition BY A.[PRODUCT ID], YEAR(DATE) ORDER BY DATE) AS YTD
FROM MasterSales A
JOIN Sales B
ON A.[PRODUCT ID] = B.[PRODUCT ID]
GROUP BY A.[PRODUCT ID], DATE, A.[SELLING PRICE], B.Quantity, B.[DISCOUNT %]



-- Show WTD, MTD, QTD, YTD sales partition by each part of the date;

SELECT DATE AS Date, SUM(A.[SELLING PRICE]*B.Quantity*(1-B.[DISCOUNT %])) AS Revenue,
SUM(A.[SELLING PRICE]*B.Quantity*(1-B.[DISCOUNT %])) OVER (Partition BY DATEPART(WEEK, DATE) ORDER BY DATE) AS WTD,
SUM(A.[SELLING PRICE]*B.Quantity*(1-B.[DISCOUNT %])) OVER (Partition BY MONTH(DATE) ORDER BY DATE) AS MTD,
SUM(A.[SELLING PRICE]*B.Quantity*(1-B.[DISCOUNT %])) OVER (Partition BY YEAR(DATE), DATEPART(QUARTER, DATE) ORDER BY DATE) AS QTD,
SUM(A.[SELLING PRICE]*B.Quantity*(1-B.[DISCOUNT %])) OVER (Partition BY YEAR(DATE) ORDER BY DATE) AS YTD
FROM MasterSales A
JOIN Sales B
ON A.[PRODUCT ID] = B.[PRODUCT ID]
GROUP BY DATE, A.[SELLING PRICE], B.Quantity, B.[DISCOUNT %]



-- Annual Analysis;
-- Show Annual Revenue;
-- Get next and previous year revenue;
-- Calculate Year over Year growth and the % growth;

WITH Annual_cte
AS
(
SELECT
YEAR(DATE) AS Year,
SUM(A.[SELLING PRICE]*B.Quantity*(1-B.[DISCOUNT %])) AS Annual_Revenue
FROM MasterSales A
JOIN Sales B
ON A.[PRODUCT ID] = B.[PRODUCT ID]
GROUP BY YEAR(DATE)
)
SELECT *
	, LAG(Annual_Revenue) OVER (ORDER BY Year ASC) AS Revenue_Previous_Year
	, LEAD(Annual_Revenue) OVER (ORDER BY Year ASC) AS Next_Year_Revenue
	, Annual_Revenue - LAG(Annual_Revenue) OVER (ORDER BY Year ASC) AS Revenue_Growth
	, FORMAT((Annual_Revenue-LAG(Annual_Revenue) OVER (ORDER BY Year ASC))/LAG(Annual_Revenue) OVER (ORDER BY Year ASC)*100, 'N2') + '%' AS Revenue_Percentage_Growth	
FROM Annual_cte
GROUP BY Year, Annual_Revenue



-- Monthly Analysis;
-- Show Monthly Revenue;
-- Get previous month, 12 months ago and next year by month revenue;
-- Calculate Month over Month growth and the % growth;

WITH Monthly_cte
AS
(
SELECT
YEAR(DATE) AS Year,
MONTH(DATE) AS Month,
SUM(A.[SELLING PRICE]*B.Quantity*(1-B.[DISCOUNT %])) AS Monthly_Revenue
FROM MasterSales A
JOIN Sales B
ON A.[PRODUCT ID] = B.[PRODUCT ID]
GROUP BY YEAR(DATE), MONTH(DATE)
)
SELECT *
	, LAG(Monthly_Revenue) OVER (ORDER BY Year, Month ASC) AS Revenue_Previous_Month
	, LAG(Monthly_Revenue, 12) OVER (ORDER BY Year, Month ASC) AS Revenue_12_Months_Ago
	, LEAD(Monthly_Revenue, 12) OVER (ORDER BY Year, Month ASC) AS Next_Year_Monthly_Revenue
	, FORMAT(Monthly_Revenue - LAG(Monthly_Revenue) OVER (ORDER BY Year, Month ASC), 'N2') AS Revenue_Growth
	, FORMAT((Monthly_Revenue-LAG(Monthly_Revenue) OVER (ORDER BY Year, Month ASC))/LAG(Monthly_Revenue) OVER (ORDER BY Year, Month ASC)*100, 'N2') + '%' AS Revenue_Percentage_Growth	
FROM Monthly_cte
GROUP BY Year, Month, Monthly_Revenue
	


--Get all orders from 2021;

SELECT DATE, COUNT(QUANTITY) AS Daily_orders
FROM MasterSales A
JOIN Sales B
ON A.[PRODUCT ID] = B.[PRODUCT ID]
WHERE DATE >= '2021-01-01'
AND DATE <= '2021-12-31'
GROUP BY DATE



-- Select products sold in 2022, that were more than ten thousand in Total sales;

SELECT	YEAR(DATE) AS Year, A.CATEGORY AS Category
	, SUM(A.[SELLING PRICE]*B.Quantity*(1-B.[DISCOUNT %])) AS Sales
	, FORMAT(AVG(A.[SELLING PRICE]*B.Quantity*(1-B.[DISCOUNT %])), 'N2') AS Avg_SalesAmount
	, MIN(A.[SELLING PRICE]*B.Quantity*(1-B.[DISCOUNT %])) AS Min_SalesAmount
	, MAX(A.[SELLING PRICE]*B.Quantity*(1-B.[DISCOUNT %])) AS Max_SalesAmount
FROM MasterSales A
JOIN Sales B
ON A.[PRODUCT ID] = B.[PRODUCT ID]
WHERE YEAR(DATE) = 2022
GROUP BY YEAR(DATE), A.CATEGORY
HAVING SUM(A.[SELLING PRICE]*B.Quantity*(1-B.[DISCOUNT %])) > 10000
ORDER BY YEAR(DATE), A.CATEGORY



-- Get sales avarage for each product in 2021;

SELECT DISTINCT	Product, AVG(A.[SELLING PRICE]*B.Quantity*(1-B.[DISCOUNT %])) OVER(PARTITION BY PRODUCT) AS Product_Avg_Sales
FROM MasterSales A
JOIN Sales B
ON A.[PRODUCT ID] = B.[PRODUCT ID]
WHERE YEAR(DATE) = 2021
ORDER BY 1



-- Get Sales Amount by Year using sub-query;

SELECT *
FROM (
		SELECT SUM(A.[SELLING PRICE]*B.Quantity*(1-B.[DISCOUNT %])) AS Sales, YEAR(DATE) AS Year
		FROM MasterSales A
		JOIN Sales B
		ON A.[PRODUCT ID] = B.[PRODUCT ID]
		GROUP BY YEAR(DATE)
) Annual_Sales



-- Get Total Sales Amount using sub-query;

SELECT SUM(Sales) as Total_Sales
FROM (
		SELECT SUM(A.[SELLING PRICE]*B.Quantity*(1-B.[DISCOUNT %])) AS 'Sales', YEAR(DATE) AS Year
		FROM MasterSales A
		JOIN Sales B
		ON A.[PRODUCT ID] = B.[PRODUCT ID]
		GROUP BY YEAR(DATE)
) Annual_Sales



-- Get the category and the purchase price where Product ID = P0024 in another table;

SELECT CATEGORY, [BUYING PRIZE] AS Purchase_Price
FROM MasterSales A
WHERE A.[PRODUCT ID] IN
	(SELECT B.[PRODUCT ID]
	FROM Sales B
	WHERE B.[PRODUCT ID] = 'P0024')



--Get Total Sales by Sales type;

SELECT [SALE TYPE] AS 'Sales Type', SUM(A.[SELLING PRICE]*B.Quantity*(1-B.[DISCOUNT %])) AS Sales
FROM MasterSales A
JOIN Sales B
ON A.[PRODUCT ID] = B.[PRODUCT ID]
GROUP BY [SALE TYPE]



--Get Total Sales by Payment mode;
	
SELECT [PAYMENT MODE] AS 'Payment mode', SUM(A.[SELLING PRICE]*B.Quantity*(1-B.[DISCOUNT %])) AS Sales
FROM MasterSales A
JOIN Sales B
ON A.[PRODUCT ID] = B.[PRODUCT ID]
GROUP BY [PAYMENT MODE]