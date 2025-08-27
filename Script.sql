-- Level 1 – Global Sales Overview
-- 1. Total Sales Value & Units Sold

SELECT 
    SUM(UnitPrice*Quantity) AS [TotalSalesUSD],
    SUM(Quantity) AS [TotalTrackUnits]
FROM InvoiceLine;

-- Cross-verifying from Invoice
SELECT SUM(Total) AS [TotalSalesUS)]
FROM Invoice;


--2. Level 2 – Geographic Breakdown
-- 2. Sales by Country – Top 5 
SELECT
    I.BillingCountry AS Top_5_Country,
    ROUND(SUM(IL.UnitPrice*IL.Quantity),2) AS [TotalSalesUSD]
    FROM Invoice I
    JOIN InvoiceLine IL ON I.InvoiceID = IL.InvoiceID
    GROUP BY I.BillingCountry
    ORDER BY [TotalSalesUSD] DESC
    LIMIT 5;
    
-- The above can be misleading if a country has fewer but big ticket sales.
-- Better approach
SELECT 
    I.BillingCountry AS Country,
    ROUND(SUM(IL.UnitPrice * IL.Quantity), 2) AS [TotalSalesUSD],
    SUM(IL.Quantity) AS UnitsSold,
    ROUND(SUM(IL.UnitPrice * IL.Quantity) / SUM(IL.Quantity), 2) AS [AvgSalesPerUnitUSD],
    ROUND(SUM(IL.UnitPrice * IL.Quantity) / COUNT(DISTINCT I.InvoiceId), 2) AS [AvgSalePerInvoiceUSD]
FROM Invoice I
JOIN InvoiceLine IL ON I.InvoiceID = IL.InvoiceID
GROUP BY I.BillingCountry
ORDER BY [TotalSalesUSD] DESC;
--LIMIT 5;

-- Ranking countries based on different parameters
WITH CountryStats AS (
    SELECT 
        I.BillingCountry AS Country,
        ROUND(SUM(IL.UnitPrice * IL.Quantity), 2) AS TotalSalesUSD,
        SUM(IL.Quantity) AS UnitsSold,
        ROUND(SUM(IL.UnitPrice * IL.Quantity) / SUM(IL.Quantity), 2) AS AvgSalePerUnitUSD,
        ROUND(SUM(IL.UnitPrice * IL.Quantity) / COUNT(DISTINCT I.InvoiceId), 2) AS AvgSalePerInvoiceUSD,
        COUNT(DISTINCT I.InvoiceId) AS InvoiceCount
    FROM Invoice I
    JOIN InvoiceLine IL ON I.InvoiceID = IL.InvoiceID
    GROUP BY I.BillingCountry
    HAVING COUNT(DISTINCT I.InvoiceId) >= 5
)
SELECT * FROM (
    SELECT 'Top by Total Sales' AS RankingType, *
    FROM CountryStats
    ORDER BY TotalSalesUSD DESC
    LIMIT 5
)
UNION ALL
SELECT * FROM (
    SELECT 'Top by Avg/Unit' AS RankingType, *
    FROM CountryStats
    ORDER BY AvgSalePerUnitUSD DESC
    LIMIT 5
)
UNION ALL
SELECT * FROM (
    SELECT 'Top by Avg/Invoice' AS RankingType, *
    FROM CountryStats
    ORDER BY AvgSalePerInvoiceUSD DESC
    LIMIT 5
);

-- 3. Sales by State
-- 3.1 Top 5 globally
WITH StateStats AS (
    SELECT 
        I.BillingCountry AS Country,
        I.BillingState AS State,
        ROUND(SUM(IL.UnitPrice * IL.Quantity), 2) AS TotalSalesUSD,
        SUM(IL.Quantity) AS UnitsSold,
        ROUND(SUM(IL.UnitPrice * IL.Quantity) / SUM(IL.Quantity), 2) AS AvgSalePerUnitUSD,
        ROUND(SUM(IL.UnitPrice * IL.Quantity) / COUNT(DISTINCT I.InvoiceId), 2) AS AvgSalePerInvoiceUSD,
        COUNT(DISTINCT I.InvoiceId) AS InvoiceCount
    FROM Invoice I
    JOIN InvoiceLine IL ON I.InvoiceID = IL.InvoiceID
    WHERE I.BillingState IS NOT NULL
    GROUP BY I.BillingCountry, I.BillingState
    HAVING COUNT(DISTINCT I.InvoiceId) >= 5
)
SELECT * FROM (
    SELECT 'Top by Total Sales' AS RankingType, *
    FROM StateStats
    ORDER BY TotalSalesUSD DESC
    LIMIT 5
)
UNION ALL
SELECT * FROM (
    SELECT 'Top by Avg/Unit' AS RankingType, *
    FROM StateStats
    ORDER BY AvgSalePerUnitUSD DESC
    LIMIT 5
)
UNION ALL
SELECT * FROM (
    SELECT 'Top by Avg/Invoice' AS RankingType, *
    FROM StateStats
    ORDER BY AvgSalePerInvoiceUSD DESC
    LIMIT 5
);

-- 3.2 Top 5 states in each country
WITH StateStats AS (
    SELECT 
        I.BillingCountry AS Country,
        I.BillingState AS State,
        ROUND(SUM(IL.UnitPrice * IL.Quantity), 2) AS TotalSalesUSD,
        SUM(IL.Quantity) AS UnitsSold,
        ROUND(SUM(IL.UnitPrice * IL.Quantity) / SUM(IL.Quantity), 2) AS AvgSalePerUnitUSD,
        ROUND(SUM(IL.UnitPrice * IL.Quantity) / COUNT(DISTINCT I.InvoiceId), 2) AS AvgSalePerInvoiceUSD,
        COUNT(DISTINCT I.InvoiceId) AS InvoiceCount
    FROM Invoice I
    JOIN InvoiceLine IL ON I.InvoiceID = IL.InvoiceID
    WHERE I.BillingState IS NOT NULL
    GROUP BY I.BillingCountry, I.BillingState
    HAVING COUNT(DISTINCT I.InvoiceId) >= 5
)
SELECT *
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY Country ORDER BY TotalSalesUSD DESC) AS SalesRank,
           ROW_NUMBER() OVER (PARTITION BY Country ORDER BY AvgSalePerUnitUSD DESC) AS UnitRank,
           ROW_NUMBER() OVER (PARTITION BY Country ORDER BY AvgSalePerInvoiceUSD DESC) AS InvoiceRank
    FROM StateStats
)
WHERE SalesRank <= 5
   OR UnitRank <= 5
   OR InvoiceRank <= 5
ORDER BY Country, SalesRank;

-- Co-relating the above with the invoice count in each country
SELECT 
    BillingCountry AS Country,
    COUNT(DISTINCT InvoiceID) AS InvoiceCount,
    COUNT (Distinct BillingState) AS StateCount
FROM Invoice
GROUP BY Country;

-- 4. Sales by city
-- 4.1 Top 5 cities globally
WITH CityStats AS (
    SELECT 
        I.BillingCountry AS Country,
        I.BillingState AS State,
        I.BillingCity AS City,
        ROUND(SUM(IL.UnitPrice * IL.Quantity), 2) AS TotalSalesUSD,
        SUM(IL.Quantity) AS UnitsSold,
        ROUND(SUM(IL.UnitPrice * IL.Quantity) / SUM(IL.Quantity), 2) AS AvgSalePerUnitUSD,
        ROUND(SUM(IL.UnitPrice * IL.Quantity) / COUNT(DISTINCT I.InvoiceId), 2) AS AvgSalePerInvoiceUSD,
        COUNT(DISTINCT I.InvoiceId) AS InvoiceCount
    FROM Invoice I
    JOIN InvoiceLine IL ON I.InvoiceID = IL.InvoiceID
    WHERE I.BillingCity IS NOT NULL
    GROUP BY I.BillingCountry, I.BillingState, I.BillingCity
    HAVING COUNT(DISTINCT I.InvoiceId) >= 3
)
SELECT * FROM (
    SELECT 'Top by Total Sales' AS RankingType, *
    FROM CityStats
    ORDER BY TotalSalesUSD DESC
    LIMIT 5
)
UNION ALL
SELECT * FROM (
    SELECT 'Top by Avg/Unit' AS RankingType, *
    FROM CityStats
    ORDER BY AvgSalePerUnitUSD DESC
    LIMIT 5
)
UNION ALL
SELECT * FROM (
    SELECT 'Top by Avg/Invoice' AS RankingType, *
    FROM CityStats
    ORDER BY AvgSalePerInvoiceUSD DESC
    LIMIT 5
);

-- 4.2 Top 5 Cities within each Country
WITH CityStats AS (
    SELECT 
        I.BillingCountry AS Country,
        I.BillingState AS State,
        I.BillingCity AS City,
        ROUND(SUM(IL.UnitPrice * IL.Quantity), 2) AS TotalSalesUSD,
        SUM(IL.Quantity) AS UnitsSold,
        ROUND(SUM(IL.UnitPrice * IL.Quantity) / SUM(IL.Quantity), 2) AS AvgSalePerUnitUSD,
        ROUND(SUM(IL.UnitPrice * IL.Quantity) / COUNT(DISTINCT I.InvoiceId), 2) AS AvgSalePerInvoiceUSD,
        COUNT(DISTINCT I.InvoiceId) AS InvoiceCount
    FROM Invoice I
    JOIN InvoiceLine IL ON I.InvoiceID = IL.InvoiceID
    WHERE I.BillingCity IS NOT NULL
    GROUP BY I.BillingCountry, I.BillingState, I.BillingCity
    HAVING COUNT(DISTINCT I.InvoiceId) >= 3
)
SELECT *
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY Country ORDER BY TotalSalesUSD DESC) AS SalesRank,
           ROW_NUMBER() OVER (PARTITION BY Country ORDER BY AvgSalePerUnitUSD DESC) AS UnitRank,
           ROW_NUMBER() OVER (PARTITION BY Country ORDER BY AvgSalePerInvoiceUSD DESC) AS InvoiceRank
    FROM CityStats
)
WHERE SalesRank <= 5
   OR UnitRank <= 5
   OR InvoiceRank <= 5
ORDER BY Country, SalesRank;

-- Top 5 Cities within each State (only where multiple cities exist)
WITH CityStats AS (
    SELECT 
        I.BillingCountry AS Country,
        I.BillingState AS State,
        I.BillingCity AS City,
        ROUND(SUM(IL.UnitPrice * IL.Quantity), 2) AS TotalSalesUSD,
        SUM(IL.Quantity) AS UnitsSold,
        ROUND(SUM(IL.UnitPrice * IL.Quantity) / SUM(IL.Quantity), 2) AS AvgSalePerUnitUSD,
        ROUND(SUM(IL.UnitPrice * IL.Quantity) / COUNT(DISTINCT I.InvoiceId), 2) AS AvgSalePerInvoiceUSD,
        COUNT(DISTINCT I.InvoiceId) AS InvoiceCount
    FROM Invoice I
    JOIN InvoiceLine IL ON I.InvoiceID = IL.InvoiceID
    WHERE I.BillingCity IS NOT NULL
    GROUP BY I.BillingCountry, I.BillingState, I.BillingCity
    HAVING COUNT(DISTINCT I.InvoiceId) >= 3
)
SELECT *
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY Country, State ORDER BY TotalSalesUSD DESC) AS SalesRank,
           ROW_NUMBER() OVER (PARTITION BY Country, State ORDER BY AvgSalePerUnitUSD DESC) AS UnitRank,
           ROW_NUMBER() OVER (PARTITION BY Country, State ORDER BY AvgSalePerInvoiceUSD DESC) AS InvoiceRank
    FROM CityStats
)
WHERE SalesRank <= 5
   OR UnitRank <= 5
   OR InvoiceRank <= 5
ORDER BY Country, State, SalesRank;

-- Supporting context: Country → StateCount → CityCount
SELECT 
    BillingCountry AS Country,
    COUNT(DISTINCT InvoiceID) AS InvoiceCount,
    COUNT(DISTINCT BillingState) AS StateCount,
    COUNT(DISTINCT BillingCity) AS CityCount
FROM Invoice
GROUP BY BillingCountry
ORDER BY Country;

-- Level 3 – Time Trends
-- Yearly Sales Trend
WITH SalesTrend AS (
    SELECT
        strftime('%Y', I.InvoiceDate) AS SalesYear,
        SUM(IL.UnitPrice * IL.Quantity) AS [TotalSalesUSD],
        SUM(IL.Quantity) AS TotalUnitsSold
    FROM Invoice I
    JOIN InvoiceLine IL ON I.InvoiceID = IL.InvoiceID
    GROUP BY strftime('%Y', I.InvoiceDate)
)
SELECT *, 
    ROUND([TotalSalesUSD)] / TotalUnitsSold,2) AS "SalesUSDPerUnitSold"
FROM SalesTrend
GROUP BY SalesYear
ORDER BY SalesYear ASC;

-- YoY growth
WITH SalesTrend AS (
    SELECT
        strftime('%Y', I.InvoiceDate) AS SalesYear,
        SUM(IL.UnitPrice * IL.Quantity) AS TotalSalesUSD,
        SUM(IL.Quantity) AS TotalUnitsSold,
        COUNT(DISTINCT I.InvoiceId) AS InvoiceCount
    FROM Invoice I
    JOIN InvoiceLine IL ON I.InvoiceID = IL.InvoiceID
    GROUP BY strftime('%Y', I.InvoiceDate)
)
SELECT
  SalesYear,
  TotalSalesUSD,
  TotalUnitsSold,
  InvoiceCount,
  ROUND(1.0 * TotalSalesUSD / NULLIF(TotalUnitsSold, 0), 2) AS SalesPerUnit,
  ROUND(1.0 * TotalSalesUSD / NULLIF(InvoiceCount, 0), 2) AS SalesPerInvoice,
  PrevSales AS TotalSalesPrevYear,
  ROUND(
    (TotalSalesUSD - PrevSales) * 100.0 / NULLIF(PrevSales, 0),
    2
  ) AS GrowthRatePrcnt
FROM (
  SELECT
    SalesYear,
    TotalSalesUSD,
    TotalUnitsSold,
    InvoiceCount,
    LAG(TotalSalesUSD) OVER (ORDER BY SalesYear) AS PrevSales
  FROM SalesTrend
) s
ORDER BY SalesYear;

-- Quarterly sales trend
WITH QuarterSales AS (
    SELECT
        strftime('%Y', I.InvoiceDate) AS SalesYear,
        (CAST(strftime('%m', I.InvoiceDate) AS INTEGER) - 1) / 3 + 1 AS Quarter,
        ROUND(SUM(IL.UnitPrice * IL.Quantity),2) AS TotalSalesUSD,
        SUM(IL.Quantity) AS TotalUnits,
        COUNT(DISTINCT I.InvoiceId) AS InvoiceCount
    FROM Invoice I
    JOIN InvoiceLine IL ON I.InvoiceId = IL.InvoiceId
    -- WHERE strftime('%Y', I.InvoiceDate) = '2013'
    GROUP BY SalesYear, Quarter
)
SELECT
    SalesYear,
    Quarter,
    TotalSalesUSD,
    TotalUnits,
    InvoiceCount,
    ROUND(TotalSalesUSD * 1.0 / TotalUnits, 2) AS SalesPerUnit,
    ROUND(TotalSalesUSD * 1.0 / InvoiceCount, 2) AS SalesPerInvoice
FROM QuarterSales
ORDER BY SalesYear, Quarter;

-- Level 4. Geography + Timely analysis
-- Yearly trend across countries
-- Year × Country metrics
WITH YearCountry AS (
  SELECT
    strftime('%Y', i.InvoiceDate) AS SalesYear,
    i.BillingCountry AS Country,
    SUM(il.UnitPrice * il.Quantity) AS TotalSalesUSD,
    COUNT(DISTINCT i.InvoiceId) AS InvoiceCount,
    SUM(il.Quantity) AS TotalUnits,
    ROUND(SUM(il.UnitPrice * il.Quantity) * 1.0 / SUM(il.Quantity), 2) AS SalesPerUnit,
    ROUND(SUM(il.UnitPrice * il.Quantity) * 1.0 / COUNT(DISTINCT i.InvoiceId), 2) AS SalesPerInvoice
  FROM Invoice i
  JOIN InvoiceLine il ON i.InvoiceId = il.InvoiceId
  GROUP BY strftime('%Y', i.InvoiceDate), i.BillingCountry
  HAVING COUNT(DISTINCT i.InvoiceId) >= 3
),
Cohorted AS (
  SELECT
    *,
    CASE
      WHEN Country IN ('USA','Canada','Brazil','France','Germany') THEN 'Workhorse'
      WHEN Country IN ('Czech Republic','Ireland','Hungary','Chile','Austria') THEN 'Premium'
      ELSE 'Other'
    END AS Cohort
  FROM YearCountry
)
SELECT *
FROM Cohorted
WHERE Cohort IN ('Workhorse','Premium')
ORDER BY SalesYear, Cohort, TotalSalesUSD DESC;




