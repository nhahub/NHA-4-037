--Backup--
SELECT * INTO amazon_final_backup FROM amazon_final

SELECT * FROM amazon_final

SELECT 
    Store_Latitude, Store_Longitude,
    Drop_Latitude, Drop_Longitude,
    geography::Point(Store_Latitude, Store_Longitude, 4326).STDistance(
    geography::Point(Drop_Latitude, Drop_Longitude, 4326)) / 1000 AS Distance_KM
FROM amazon_final


ALTER TABLE amazon_final 
ADD Distance_KM AS (
    geography::Point(Store_Latitude, Store_Longitude, 4326).STDistance(
    geography::Point(Drop_Latitude, Drop_Longitude, 4326)) / 1000
) PERSISTED

SELECT AVG(Distance_KM) AS AVG_Distance
FROM amazon_final

SELECT *
FROM amazon_final
WHERE Distance_KM > (SELECT AVG(Distance_KM) FROM amazon_final)

SELECT * FROM amazon_final
WHERE Store_Latitude = 0 OR Store_Longitude = 0 OR Drop_Latitude = 0 OR Drop_Longitude = 0

DELETE FROM amazon_final
WHERE Distance_KM > 500

