select * from amazon_delivery1
SELECT * INTO amazon_delivery_backup FROM amazon_delivery1;

SELECT
  COUNT(*) - COUNT(Order_ID)       AS null_Order_ID,
  COUNT(*) - COUNT(Agent_Age)      AS null_Agent_Age,
  COUNT(*) - COUNT(Agent_Rating)   AS null_Agent_Rating,
  COUNT(*) - COUNT(Weather)        AS null_Weather,
  COUNT(*) - COUNT(Traffic)        AS null_Traffic,
  COUNT(*) - COUNT(Delivery_Time)  AS null_Delivery_Time,
  COUNT(*) - COUNT(Vehicle)        AS null_Vehicle
FROM amazon_delivery1

--CTE To Calculate Median for Agent Rating--
;WITH med AS (
  SELECT
    PERCENTILE_CONT(0.5)
      WITHIN GROUP (ORDER BY TRY_CONVERT(FLOAT, Agent_Rating))
      OVER () AS median_val
  FROM amazon_delivery1
  WHERE TRY_CONVERT(FLOAT, Agent_Rating) IS NOT NULL
)
UPDATE amazon_delivery1
SET Agent_Rating = (
    SELECT TOP 1 median_val FROM med
)
WHERE Agent_Rating IS NULL 
   OR TRY_CONVERT(FLOAT, Agent_Rating) IS NULL;


SELECT * FROM amazon_delivery1
WHERE Traffic = 'high'

--Delete all raws = 0--
DELETE FROM amazon_delivery1
 WHERE  TRY_CAST(Store_Latitude AS int) = 0

  -- Impute Weather with mode (most frequent) --
UPDATE amazon_delivery1
SET Weather = (
  SELECT TOP 1 Weather
  FROM   amazon_delivery1
  WHERE  Weather IS NOT NULL
  GROUP BY Weather
  ORDER BY COUNT(*) DESC
)
WHERE Weather = 'NaN';

-- Impute Traffic with mode (most frequent) --
UPDATE amazon_delivery1
SET Traffic = (
  SELECT TOP 1 Traffic
  FROM   amazon_delivery1
  WHERE  Traffic IS NOT NULL
  GROUP BY Traffic
  ORDER BY COUNT(*) DESC
)
WHERE Traffic = 'NaN';

--ADD New Column Preparation Time Minutes--
ALTER TABLE amazon_delivery1
ADD Preparation_Time_Minutes AS
    DATEDIFF (MINUTE, 
             TRY_CAST(Order_Time AS DATETIME), 
             TRY_CAST(Pickup_Time AS DATETIME)
    )
--Order_ID Duplicates Detection--
    SELECT DISTINCT Order_ID from amazon_delivery1
    SELECT 
    Order_ID, 
    COUNT(*) AS Repeated_Count
FROM amazon_delivery1
GROUP BY Order_ID

SELECT * FROM amazon_delivery1

ALTER TABLE amazon_delivery1
ADD PrepTime_Min AS (
    CASE 
        WHEN TRY_CAST(Pickup_Time AS datetime) < TRY_CAST(Order_Time AS datetime) 
        THEN DATEDIFF(MINUTE, TRY_CAST(Order_Time AS datetime), TRY_CAST(Pickup_Time AS datetime)) + 1440
        ELSE DATEDIFF(MINUTE, TRY_CAST(Order_Time AS datetime), TRY_CAST(Pickup_Time AS datetime))
    END
)

SELECT DISTINCT
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY PrepTime_Min) OVER () AS Overall_Median
FROM amazon_delivery1;

ALTER TABLE amazon_delivery1
ADD PrepTime_Min_Real INT; 


select * from amazon_delivery1

ALTER TABLE amazon_delivery1 DROP COLUMN PrepTime_Min_Real

select * from amazon_delivery1

ALTER TABLE amazon_delivery1 DROP COLUMN Preparation_Time_Minutes


SELECT * FROM amazon_delivery1


--Fill Nulls Cell in Order_Time Column--
UPDATE amazon_delivery1
SET [Order_Time] = CAST(DATEADD(minute, -10, TRY_CAST(Pickup_Time AS datetime)) AS time(0))
WHERE TRY_CAST(Pickup_Time AS datetime) = 'Null';

--Check if there's any Nulls--
SELECT * FROM amazon_delivery1
WHERE Traffic = 'NULL' or Weather = 'NULL' or Order_Time = 'NULL'

select * from amazon_delivery1

UPDATE a
SET a.Order_Time = b.Order_Time
FROM amazon_delivery1 a
JOIN amazon_delivery_backup b
ON a.Order_ID = b.Order_ID;

SELECT 
    Order_Time,
    Pickup_Time,
    DATEADD(minute, -10, TRY_CAST(Pickup_Time AS datetime)) AS New_Order_Time
FROM amazon_delivery1
WHERE Order_Time = 'NaN'; 

SELECT 
    Order_Time AS Old_Order_Time,
    Pickup_Time,
    CAST(DATEADD(minute, -10, TRY_CAST(Pickup_Time AS datetime)) AS time(0)) AS New_Order_Time
FROM amazon_delivery1
WHERE Order_Time = 'NaN' 
AND TRY_CAST(Pickup_Time AS datetime) IS NOT NULL;

--Fill Nulls Cell in Order_Time Column--
BEGIN TRANSACTION

UPDATE amazon_delivery1
SET Order_Time = CAST(DATEADD(minute, -10, TRY_CAST(Pickup_Time AS datetime)) AS time(0))
WHERE Order_Time = 'NaN'
AND TRY_CAST(Pickup_Time AS datetime) IS NOT NULL;

COMMIT

SELECT Pickup_Time, Order_Time FROM amazon_delivery1
WHERE Order_Time IS NOT NULL

select * from amazon_delivery1

SELECT *
FROM amazon_delivery1
WHERE Order_ID = 'Order_ID'

DELETE FROM amazon_delivery1
WHERE Order_ID = 'Order_ID'


SELECT 
    Store_Latitude, Store_Longitude,
    Drop_Latitude, Drop_Longitude,
    geography::Point(Store_Latitude, Store_Longitude, 4326).STDistance(
    geography::Point(Drop_Latitude, Drop_Longitude, 4326)) / 1000 AS Distance_KM
FROM amazon_delivery1


ALTER TABLE amazon_delivery1
ADD Distance_KM AS (
    geography::Point(Store_Latitude, Store_Longitude, 4326).STDistance(
    geography::Point(Drop_Latitude, Drop_Longitude, 4326)) / 1000
) PERSISTED

