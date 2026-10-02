CREATE DATABASE Olist_Analytics;
GO

USE Olist_Analytics;
GO

SELECT DB_NAME() AS CurrentDatabase;



SELECT 
    TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE';

USE Olist_Analytics;
GO

SELECT 
    COUNT(*) AS RowCnt
FROM order_analysis

UNION ALL

SELECT 
    COUNT(*)
FROM order_items_analysis;

SELECT TOP 5 *
FROM order_analysis;


/*SQL Business Analysis: Revenue & AOV

Now we start the actual SQL analytics layer. This will demonstrate SQL skills such as aggregation, CASE, date functions, and business KPI calculation.

Why are we doing this?

To answer:

- How much revenue did Olist generate?
- How many orders were placed?
- What is the Average Order Value (AOV)?
- How does revenue change over time? */

------------------- Overall Business KPIs --------------------
USE Olist_Analytics;
GO

SELECT
    COUNT(DISTINCT order_id) AS Total_Orders,
    COUNT(DISTINCT customer_unique_id) AS Unique_Customers,
    SUM(product_revenue) AS Total_Revenue,
    SUM(freight_value) AS Total_Freight,
    SUM(total_order_value) AS Total_Order_Value,
    AVG(total_order_value) AS Average_Order_Value,
    AVG(review_score) AS Average_Review_Score
FROM order_analysis
WHERE order_status = 'delivered';

------------------ Monthly Revenue Analysis ---------------------------------------------------
/*This lets us identify:

Revenue growth/decline
Monthly order volume
Changes in AOV
Seasonal patterns*/
-- This is an important SQL business-analysis query.

SELECT
    DATEFROMPARTS(
        YEAR(order_purchase_timestamp),
        MONTH(order_purchase_timestamp),
        1
    ) AS Order_Month,

    COUNT(DISTINCT order_id) AS Total_Orders,

    SUM(product_revenue) AS Revenue,

    SUM(total_order_value) AS Total_Order_Value,

    CAST(
        SUM(product_revenue) /
        NULLIF(COUNT(DISTINCT order_id), 0)
        AS DECIMAL(12,2)
    ) AS AOV

FROM order_analysis

WHERE order_status = 'delivered'

GROUP BY
    DATEFROMPARTS(
        YEAR(order_purchase_timestamp),
        MONTH(order_purchase_timestamp),
        1
    )

ORDER BY Order_Month;


---------------------- Category Performance Analysis -----------------------------------------

/* Now we move from overall sales to which product categories are driving the business.

Why are we doing this?

We want to identify:

- Top revenue-generating categories
- Order volume by category
- Average order value
- Freight burden
- Category ranking using a SQL window function */
-- Category Revenue + Ranking


WITH CategorySales AS
(
    SELECT
        oi.product_category,
        SUM(oi.price) AS Revenue,
        COUNT(DISTINCT oi.order_id) AS Total_Orders,
        SUM(oi.freight_value) AS Freight
    FROM order_items_analysis oi
    WHERE oi.order_status = 'delivered'
    GROUP BY oi.product_category
)

SELECT
    product_category,
    Revenue,
    Total_Orders,
    Freight,

    CAST(
        Revenue / NULLIF(Total_Orders, 0)
        AS DECIMAL(12,2)
    ) AS Revenue_Per_Order,

    CAST(
        Freight * 100.0 / NULLIF(Revenue, 0)
        AS DECIMAL(10,2)
    ) AS Freight_Ratio_Percent,

    RANK() OVER (
        ORDER BY Revenue DESC
    ) AS Revenue_Rank

FROM CategorySales

ORDER BY Revenue DESC;


--------------------- Top 10 Categories ------------------------------------------------------------------

-- Now create a cleaner output for visualization:

WITH CategorySales AS
(
    SELECT
        oi.product_category,
        SUM(oi.price) AS Revenue,
        COUNT(DISTINCT oi.order_id) AS Total_Orders,
        SUM(oi.freight_value) AS Freight
    FROM order_items_analysis oi
    WHERE oi.order_status = 'delivered'
    GROUP BY oi.product_category
),

RankedCategories AS
(
    SELECT
        *,
        RANK() OVER (
            ORDER BY Revenue DESC
        ) AS Revenue_Rank
    FROM CategorySales
)

SELECT
    product_category,
    Revenue,
    Total_Orders,
    Freight,
    CAST(
        Freight * 100.0 / NULLIF(Revenue, 0)
        AS DECIMAL(10,2)
    ) AS Freight_Ratio_Percent,
    Revenue_Rank
FROM RankedCategories
WHERE Revenue_Rank <= 10
ORDER BY Revenue_Rank;


--------------------- Geographic / State Performance ---------------------------------------------------------------
/* Why are we doing this?

We want to understand where the business is generating revenue and compare:

- Revenue by state
- Number of orders
- Unique customers
- Average Order Value (AOV)
- Revenue ranking

This demonstrates GROUP BY + JOIN + CTE + window functions. */

WITH StateSales AS
(
    SELECT
        customer_state,
        COUNT(DISTINCT order_id) AS Total_Orders,
        COUNT(DISTINCT customer_unique_id) AS Unique_Customers,
        SUM(product_revenue) AS Revenue,
        SUM(total_order_value) AS Total_Order_Value
    FROM order_analysis
    WHERE order_status = 'delivered'
    GROUP BY customer_state
),

RankedStates AS
(
    SELECT
        *,
        RANK() OVER (
            ORDER BY Revenue DESC
        ) AS Revenue_Rank
    FROM StateSales
)

SELECT
    customer_state AS State,
    Total_Orders,
    Unique_Customers,
    Revenue,
    CAST(
        Revenue / NULLIF(Total_Orders, 0)
        AS DECIMAL(12,2)
    ) AS AOV,
    Revenue_Rank
FROM RankedStates
ORDER BY Revenue_Rank;

 ------ State Performance ------

 WITH StateSales AS
(
    SELECT
        customer_state,
        COUNT(DISTINCT order_id) AS Total_Orders,
        SUM(product_revenue) AS Revenue
    FROM order_analysis
    WHERE order_status = 'delivered'
    GROUP BY customer_state
)

SELECT TOP 10
    customer_state AS State,
    Total_Orders,
    Revenue,
    CAST(
        Revenue / NULLIF(Total_Orders, 0)
        AS DECIMAL(12,2)
    ) AS AOV
FROM StateSales
ORDER BY Revenue DESC;


-------------- Delivery & Logistics Performance ---------------------------------------------------
/* Why are we doing this?

Delivery is a major operational KPI. We want to measure:

- Average delivery time
- On-time vs late deliveries
- Average delivery delay
- Late-delivery percentage
- Delivery performance by state

This also demonstrates CASE + aggregation + date calculations in SQL Server. */

----------- Overall Delivery Performance -------------------------------------------
SELECT
    COUNT(DISTINCT order_id) AS Delivered_Orders,

    CAST(
        AVG(delivery_days)
        AS DECIMAL(10,2)
    ) AS Avg_Delivery_Days,

    CAST(
        AVG(delivery_delay_days)
        AS DECIMAL(10,2)
    ) AS Avg_Delivery_Delay_Days,

    SUM(
        CASE
            WHEN delivery_delay_days <= 0 THEN 1
            ELSE 0
        END
    ) AS On_Time_Orders,

    SUM(
        CASE
            WHEN delivery_delay_days > 0 THEN 1
            ELSE 0
        END
    ) AS Late_Orders,

    CAST(
        SUM(
            CASE
                WHEN delivery_delay_days <= 0 THEN 1
                ELSE 0
            END
        ) * 100.0
        / NULLIF(COUNT(DISTINCT order_id), 0)
        AS DECIMAL(10,2)
    ) AS On_Time_Percent,

    CAST(
        SUM(
            CASE
                WHEN delivery_delay_days > 0 THEN 1
                ELSE 0
            END
        ) * 100.0
        / NULLIF(COUNT(DISTINCT order_id), 0)
        AS DECIMAL(10,2)
    ) AS Late_Percent

FROM order_analysis
WHERE order_status = 'delivered'
  AND delivery_days IS NOT NULL;


-------------  Create a Business Classification ------------------------------

-- This adds a more realistic business-analytics operation:

SELECT
    order_id,
    customer_state,
    delivery_days,
    delivery_delay_days,

    CASE
        WHEN delivery_delay_days <= 0
            THEN 'On Time / Early'

        WHEN delivery_delay_days <= 7
            THEN 'Late: 1-7 Days'

        WHEN delivery_delay_days <= 15
            THEN 'Late: 8-15 Days'

        ELSE 'Severely Late'
    END AS Delivery_Category

FROM order_analysis

WHERE order_status = 'delivered'
  AND delivery_delay_days IS NOT NULL;