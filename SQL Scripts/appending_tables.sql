SELECT * FROM restaurant_health_inspection_data_analysis.insp;
ALTER TABLE restaurant_health_inspection_data_analysis.insp
RENAME COLUMN `ï»¿CAMIS` TO `CAMIS`;


#Checking column count from both tables before appending them
SELECT TABLE_NAME, COUNT(*) AS ColumnCount
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'restaurant_health_inspection_data_analysis'
  AND TABLE_NAME IN ('insp', 'insp2')
GROUP BY TABLE_NAME;

#Checking the name of the column that is extra in insp2
SELECT ORDINAL_POSITION, COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'restaurant_health_inspection_data_analysis'
  AND TABLE_NAME = 'insp2'
ORDER BY ORDINAL_POSITION DESC
LIMIT 3;

#Dropping that column to make it even in both tables
ALTER TABLE restaurant_health_inspection_data_analysis.insp2
DROP COLUMN `Location`;

#Apending both tables
START TRANSACTION;

INSERT INTO restaurant_health_inspection_data_analysis.insp
SELECT * 
FROM restaurant_health_inspection_data_analysis.insp2;

-- Verify all 12 months of 2025 are now populated
SELECT 
    MONTH(`INSPECTION DATE`) AS MonthNum, 
    COUNT(*) AS TotalRows
FROM restaurant_health_inspection_data_analysis.insp
WHERE YEAR(`INSPECTION DATE`) = 2025
GROUP BY MONTH(`INSPECTION DATE`)
ORDER BY MonthNum;

#Reversing as there was duplicates in row id ---> primary key created to delete duplicates
ROLLBACK;

#Dropping row id from insp2
ALTER TABLE restaurant_health_inspection_data_analysis.insp2
DROP COLUMN `row_id`;

SELECT GROUP_CONCAT(CONCAT('`', COLUMN_NAME, '`') ORDER BY ORDINAL_POSITION SEPARATOR ', ') AS ColList26
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'restaurant_health_inspection_data_analysis'
  AND TABLE_NAME = 'insp'
  AND COLUMN_NAME <> 'row_id';
  
#Appending both tables
START TRANSACTION;

INSERT INTO restaurant_health_inspection_data_analysis.insp (`CAMIS`, `DBA`, `BORO`, `BUILDING`, `STREET`, `ZIPCODE`, `PHONE`, `CUISINE DESCRIPTION`, `INSPECTION DATE`, `ACTION`, `VIOLATION CODE`, `VIOLATION DESCRIPTION`, `CRITICAL FLAG`, `SCORE`, `GRADE`, `GRADE DATE`, `RECORD DATE`, `INSPECTION TYPE`, `Latitude`,`Longitude`, `Community Board`, `Council District`, `Census Tract`, `BIN`, `BBL`, `NTA`)
SELECT `CAMIS`, `DBA`, `BORO`, `BUILDING`, `STREET`, `ZIPCODE`, `PHONE`, `CUISINE DESCRIPTION`, `INSPECTION DATE`, `ACTION`, `VIOLATION CODE`, `VIOLATION DESCRIPTION`, `CRITICAL FLAG`, `SCORE`, `GRADE`, `GRADE DATE`, `RECORD DATE`, `INSPECTION TYPE`, `Latitude`,`Longitude`, `Community Board`, `Council District`, `Census Tract`, `BIN`, `BBL`, `NTA`
FROM restaurant_health_inspection_data_analysis.insp2;

-- Verify all 12 months of 2025 are now populated
SELECT 
    MONTH(`INSPECTION DATE`) AS MonthNum, 
    COUNT(*) AS TotalRows
FROM restaurant_health_inspection_data_analysis.insp
WHERE YEAR(`INSPECTION DATE`) = 2025
GROUP BY MONTH(`INSPECTION DATE`)
ORDER BY MonthNum;

COMMIT;








