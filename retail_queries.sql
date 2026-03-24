-- ============================================================
-- RETAIL BUSINESS PERFORMANCE & PROFITABILITY ANALYSIS
-- SQL Queries File | Elevate Labs Internship Project
-- Author: [Your Name] | Tool: SQL (SQLite / MySQL / PostgreSQL)
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- STEP 1: Create Table Schema
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS retail_data (
    Order_ID        VARCHAR(20) PRIMARY KEY,
    Order_Date      DATE,
    Category        VARCHAR(50),
    Sub_Category    VARCHAR(50),
    Region          VARCHAR(30),
    Segment         VARCHAR(30),
    Season          VARCHAR(20),
    Sales           DECIMAL(10, 2),
    Profit          DECIMAL(10, 2),
    Discount        DECIMAL(4, 2),
    Quantity        INT,
    Inventory_Days  INT
);


-- ────────────────────────────────────────────────────────────
-- STEP 2: Data Cleaning — Find & Handle Nulls
-- ────────────────────────────────────────────────────────────

-- Check missing values per column
SELECT
    SUM(CASE WHEN Order_ID       IS NULL THEN 1 ELSE 0 END) AS missing_order_id,
    SUM(CASE WHEN Category       IS NULL THEN 1 ELSE 0 END) AS missing_category,
    SUM(CASE WHEN Sales           IS NULL THEN 1 ELSE 0 END) AS missing_sales,
    SUM(CASE WHEN Profit          IS NULL THEN 1 ELSE 0 END) AS missing_profit,
    SUM(CASE WHEN Inventory_Days  IS NULL THEN 1 ELSE 0 END) AS missing_inv_days,
    COUNT(*) AS total_rows
FROM retail_data;

-- Remove duplicate orders
DELETE FROM retail_data
WHERE Order_ID IN (
    SELECT Order_ID
    FROM retail_data
    GROUP BY Order_ID
    HAVING COUNT(*) > 1
);


-- ────────────────────────────────────────────────────────────
-- STEP 3: Profit Margin by Category
-- ────────────────────────────────────────────────────────────

SELECT
    Category,
    COUNT(Order_ID)                                   AS Total_Orders,
    ROUND(SUM(Sales), 2)                              AS Total_Sales,
    ROUND(SUM(Profit), 2)                             AS Total_Profit,
    ROUND(AVG(Profit / NULLIF(Sales, 0) * 100), 2)   AS Avg_Profit_Margin_Pct,
    ROUND(SUM(Profit) / NULLIF(SUM(Sales), 0) * 100, 2) AS Overall_Margin_Pct
FROM retail_data
GROUP BY Category
ORDER BY Avg_Profit_Margin_Pct DESC;


-- ────────────────────────────────────────────────────────────
-- STEP 4: Profit Margin by Sub-Category (Ranked)
-- ────────────────────────────────────────────────────────────

SELECT
    Category,
    Sub_Category,
    COUNT(Order_ID)                                        AS Orders,
    ROUND(SUM(Sales), 2)                                   AS Total_Sales,
    ROUND(SUM(Profit), 2)                                  AS Total_Profit,
    ROUND(AVG(Profit / NULLIF(Sales,0) * 100), 2)          AS Avg_Margin_Pct,
    RANK() OVER (ORDER BY AVG(Profit / NULLIF(Sales,0)) DESC) AS Margin_Rank
FROM retail_data
GROUP BY Category, Sub_Category
ORDER BY Avg_Margin_Pct DESC;


-- ────────────────────────────────────────────────────────────
-- STEP 5: Region-wise Sales & Profit Performance
-- ────────────────────────────────────────────────────────────

SELECT
    Region,
    ROUND(SUM(Sales), 2)                              AS Total_Sales,
    ROUND(SUM(Profit), 2)                             AS Total_Profit,
    ROUND(AVG(Profit / NULLIF(Sales, 0) * 100), 2)   AS Avg_Margin_Pct,
    COUNT(Order_ID)                                   AS Total_Orders,
    ROUND(SUM(Sales) / COUNT(Order_ID), 2)            AS Avg_Order_Value
FROM retail_data
GROUP BY Region
ORDER BY Total_Profit DESC;


-- ────────────────────────────────────────────────────────────
-- STEP 6: Seasonal Sales Analysis
-- ────────────────────────────────────────────────────────────

SELECT
    Season,
    Category,
    ROUND(SUM(Sales), 2)                   AS Total_Sales,
    ROUND(SUM(Profit), 2)                  AS Total_Profit,
    COUNT(Order_ID)                        AS Orders
FROM retail_data
GROUP BY Season, Category
ORDER BY Season, Total_Sales DESC;


-- ────────────────────────────────────────────────────────────
-- STEP 7: Inventory Turnover — Identify Slow-Moving Items
-- ────────────────────────────────────────────────────────────

SELECT
    Sub_Category,
    Category,
    ROUND(AVG(Inventory_Days), 1)          AS Avg_Inventory_Days,
    ROUND(AVG(Profit / NULLIF(Sales,0) * 100), 2) AS Avg_Margin_Pct,
    COUNT(Order_ID)                        AS Orders,
    CASE
        WHEN AVG(Inventory_Days) <= 20 THEN 'Fast Moving'
        WHEN AVG(Inventory_Days) <= 40 THEN 'Normal'
        WHEN AVG(Inventory_Days) <= 60 THEN 'Slow Moving'
        ELSE 'Dead Stock — Action Needed'
    END AS Inventory_Status
FROM retail_data
GROUP BY Sub_Category, Category
ORDER BY Avg_Inventory_Days DESC;


-- ────────────────────────────────────────────────────────────
-- STEP 8: Discount Impact on Profitability
-- ────────────────────────────────────────────────────────────

SELECT
    CONCAT(CAST(Discount * 100 AS INT), '%')          AS Discount_Level,
    COUNT(Order_ID)                                   AS Orders,
    ROUND(AVG(Profit / NULLIF(Sales, 0) * 100), 2)   AS Avg_Margin_Pct,
    SUM(CASE WHEN Profit < 0 THEN 1 ELSE 0 END)      AS Loss_Orders,
    ROUND(SUM(CASE WHEN Profit < 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS Loss_Rate_Pct
FROM retail_data
GROUP BY Discount_Level
ORDER BY Discount;


-- ────────────────────────────────────────────────────────────
-- STEP 9: Monthly Revenue Trend (Year-over-Year)
-- ────────────────────────────────────────────────────────────

SELECT
    YEAR(Order_Date)   AS Year,
    MONTH(Order_Date)  AS Month,
    ROUND(SUM(Sales), 2)   AS Monthly_Sales,
    ROUND(SUM(Profit), 2)  AS Monthly_Profit,
    COUNT(Order_ID)        AS Orders
FROM retail_data
GROUP BY YEAR(Order_Date), MONTH(Order_Date)
ORDER BY Year, Month;


-- ────────────────────────────────────────────────────────────
-- STEP 10: Top 10 Most Profitable Sub-Categories
-- ────────────────────────────────────────────────────────────

SELECT
    Sub_Category,
    Category,
    ROUND(SUM(Profit), 2)                             AS Total_Profit,
    ROUND(AVG(Profit / NULLIF(Sales, 0) * 100), 2)   AS Avg_Margin_Pct
FROM retail_data
GROUP BY Sub_Category, Category
ORDER BY Total_Profit DESC
LIMIT 10;


-- ────────────────────────────────────────────────────────────
-- STEP 11: Loss-Making Orders (Profit < 0)
-- ────────────────────────────────────────────────────────────

SELECT
    Order_ID, Category, Sub_Category, Region,
    Sales, Profit, Discount,
    ROUND(Profit / NULLIF(Sales, 0) * 100, 2) AS Margin_Pct
FROM retail_data
WHERE Profit < 0
ORDER BY Profit ASC
LIMIT 20;


-- ────────────────────────────────────────────────────────────
-- STEP 12: Customer Segment Performance
-- ────────────────────────────────────────────────────────────

SELECT
    Segment,
    COUNT(Order_ID)                                   AS Orders,
    ROUND(SUM(Sales), 2)                              AS Total_Sales,
    ROUND(SUM(Profit), 2)                             AS Total_Profit,
    ROUND(AVG(Profit / NULLIF(Sales, 0) * 100), 2)   AS Avg_Margin_Pct,
    ROUND(SUM(Sales) / COUNT(Order_ID), 2)            AS Avg_Order_Value
FROM retail_data
GROUP BY Segment
ORDER BY Total_Profit DESC;

-- ============================================================
-- END OF SQL QUERIES FILE
-- Note: Replace YEAR() / MONTH() with strftime() for SQLite
--       e.g.: strftime('%Y', Order_Date) for Year
-- ============================================================
