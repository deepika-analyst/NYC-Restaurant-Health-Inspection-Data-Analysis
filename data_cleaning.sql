#DATA CLEANING
##########################################################################################################################################################################################################
#Duplicates
#Assigning the table row ids so that identifying and deleting duplicates is easy:
ALTER TABLE restaurant_health_inspection_data_analysis.insp
ADD COLUMN row_id INT AUTO_INCREMENT PRIMARY KEY FIRST;

#Identifying dupliactes using row number
SET sql_safe_updates = 0; 

DELETE FROM restaurant_health_inspection_data_analysis.insp
WHERE row_id IN 
   (SELECT row_id 
	FROM (
		SELECT row_id, ROW_NUMBER() OVER(PARTITION BY CAMIS, `INSPECTION DATE`,`VIOLATION CODE`,`INSPECTION TYPE`,`ACTION`,SCORE 
										ORDER BY row_id) AS rn
		FROM restaurant_health_inspection_data_analysis.insp) AS sub1
	WHERE rn > 1)
;
SET sql_safe_updates = 1;

#Verifying if duplicates got deleted
SELECT row_id 
FROM (
		SELECT row_id, ROW_NUMBER() OVER(PARTITION BY CAMIS, `INSPECTION DATE`,`VIOLATION CODE`,`INSPECTION TYPE`,`ACTION`,SCORE 
										ORDER BY row_id) AS rn
		FROM restaurant_health_inspection_data_analysis.insp ) AS sub1
WHERE rn > 1
;

####################################################################################################################################################################################################
#Handling missing values, blanks,spaces and converting them to null to avoid data type errors
UPDATE restaurant_health_inspection_data_analysis.insp
SET 
    BUILDING = NULLIF(TRIM(BUILDING),'')
    ,ZIPCODE = NULLIF(TRIM(ZIPCODE),'')
    ,PHONE = NULLIF(TRIM(PHONE),'')
    ,SCORE = NULLIF(TRIM(SCORE),'')
    ,`Council District` = NULLIF(TRIM(`Council District`),'')
    ,`Census Tract` = NULLIF(TRIM(`Census Tract`),'')
    ,BIN = NULLIF(TRIM(BIN),'')
    ,BBL = NULLIF(TRIM(BBL),'')
    ,DBA = NULLIF(TRIM(DBA),'')
    ,BORO = NULLIF(TRIM(BORO),'')
    ,STREET = NULLIF(TRIM(STREET),'')
    ,`CUISINE DESCRIPTION` = NULLIF(TRIM(`CUISINE DESCRIPTION`),'')
    ,`INSPECTION DATE` = NULLIF(TRIM(`INSPECTION DATE`),'')
    ,`ACTION` = NULLIF(TRIM(`ACTION`),'')
    ,`VIOLATION CODE` = NULLIF(TRIM(`VIOLATION CODE`),'')
    ,`VIOLATION DESCRIPTION` = NULLIF(TRIM(`VIOLATION DESCRIPTION`),'')
    ,`CRITICAL FLAG` = NULLIF(TRIM(`CRITICAL FLAG`),'')
    ,GRADE = NULLIF(TRIM(GRADE),'')
    ,`GRADE DATE` = NULLIF(TRIM(`GRADE DATE`),'')
    ,`RECORD DATE` = NULLIF(TRIM(`RECORD DATE`),'')
    ,`INSPECTION TYPE` = NULLIF(TRIM(`INSPECTION TYPE`),'')
    ,NTA = NULLIF(TRIM(NTA),'')
    ;

###############################################################################################################################################################################
#Changing data types after handling blank values, converting them to null so that when data type is being changed there are o errors thrown
#checking data types
DESCRIBE restaurant_health_inspection_data_analysis.insp;

ALTER TABLE restaurant_health_inspection_data_analysis.insp
MODIFY CAMIS INT
,MODIFY SCORE INT
,MODIFY `INSPECTION DATE` DATE 
,MODIFY `GRADE DATE` DATE 
,MODIFY `RECORD DATE` DATE 
,MODIFY BORO VARCHAR(50)
,MODIFY BUILDING VARCHAR(50)
,MODIFY ZIPCODE VARCHAR(50)
,MODIFY PHONE VARCHAR(25)
,MODIFY GRADE VARCHAR(50)
,MODIFY `CRITICAL FLAG` VARCHAR(30)
,MODIFY `VIOLATION CODE` VARCHAR(30)
,MODIFY BIN VARCHAR(20)
,MODIFY BBL VARCHAR(20)
, MODIFY `Community Board` VARCHAR(20)
,MODIFY `Council District` VARCHAR(20)
,MODIFY `Census Tract` VARCHAR(20)
,MODIFY NTA VARCHAR(20)
;

#Converting the inspection date column throws an error because there are dates '1900-01-00'  which sql doesn't recognise. So we must convert them to null
SELECT row_id , `INSPECTION DATE`
FROM restaurant_health_inspection_data_analysis.insp
WHERE  `INSPECTION DATE` LIKE '1900-%'  
;

UPDATE restaurant_health_inspection_data_analysis.insp
SET `INSPECTION DATE` = NULL 
WHERE `INSPECTION DATE` LIKE '1900-%'
;

#Checking whether similar issue persists with record and grade date.No it doesn't.
SELECT row_id , `RECORD DATE`
FROM restraunt_health_inspection_analysis.insp
WHERE  YEAR(`RECORD DATE`) LIKE '1900-%'  
;

#Chcking whether there are any empty or blank cells in score column . ----No
SELECT COUNT(*) AS invalid_scores
FROM restraunt_health_inspection_analysis.insp
WHERE SCORE IS NOT NULL 
  AND SCORE NOT REGEXP '^-?[0-9]+$';
  
###############################################################################################################################################################################################################
    
## Standardizing cuisine descriptions
SELECT DISTINCT `CUISINE DESCRIPTION`
FROM restaurant_health_inspection_data_analysis.insp
;

#Trial and error , Correction Before Updating
SELECT DISTINCT `CUISINE DESCRIPTION`
FROM		(SELECT 
				CASE 
				   WHEN `CUISINE DESCRIPTION` IN ('American', 'New American', 'Californian', 'Southwestern','Barbeque','Barbecue','Soul Food','Steakhouse') THEN 'American' 
                   WHEN `CUISINE DESCRIPTION` IN ('Mexican','Tex-Mex') THEN 'Mexican & Tex Mexican'
				   WHEN `CUISINE DESCRIPTION` IN ('French', 'New French', 'Haute Cuisine') THEN 'French' 
				   WHEN `CUISINE DESCRIPTION` IN ('Creole', 'Cajun', 'Creole/Cajun') THEN 'Creole/Cajun'
				   WHEN `CUISINE DESCRIPTION` IN ('Hotdogs', 'Hotdogs/Pretzels', 'Bagels/Pretzels','Chicken','Hamburgers') THEN 'Fast Food & Street Food'
				   WHEN `CUISINE DESCRIPTION` IN ('Sandwiches', 'Salads', 'Soups', 'Sandwiches/Salads/Mixed Buffet', 'Soups/Salads/Sandwiches') THEN 'Sandwiches/Soups/Salads'
				   WHEN `CUISINE DESCRIPTION` IN ('Bakery Products/Desserts','Donuts','Frozen Desserts','Nuts/Confectionary','Pancakes/Waffles') THEN 'Bakery & Desserts'
				   WHEN `CUISINE DESCRIPTION` IN ('Coffee/Tea','Juice','Smoothies','Fruit Salads','Bottled Beverages') THEN 'Beverages & Cafe'
				   WHEN `CUISINE DESCRIPTION` IN ('Vegan','Vegetarian','Fruits/Vegetables') THEN 'Vegetarian/Vegan'
				   WHEN `CUISINE DESCRIPTION` IN ('Not Listed/Not Applicable', 'Other') THEN 'Other/Unspecified'
                   WHEN `CUISINE DESCRIPTION` IN ('Chinese/Japanese','Chinese/Cuban','Fusion') THEN 'Fusion & Hybrid'
				   WHEN `CUISINE DESCRIPTION` IN ('Asian/Asian Fusion','Bangladeshi','Filipino','Indonesian','Pakistani','Southeast Asian','Hawaiian') THEN 'Asian Other'
				   WHEN `CUISINE DESCRIPTION` IN ('Brazilian','Chilean','Chimichurri','Latin American','Peruvian','Spanish') THEN 'Latin American & Spanish'
                   WHEN `CUISINE DESCRIPTION` IN ('Greek','Mediterranean') THEN 'Mediterranean & Greek'
				   WHEN `CUISINE DESCRIPTION` IN ('Armenian','Australian','Basque','Continental','Czech','Eastern European','English','German','Irish','Polish','Portuguese','Russian','Scandinavian','Tapas') THEN 'European (Other)'
				   WHEN `CUISINE DESCRIPTION` IN ('Afghan','African','Egyptian','Ethiopian','Iranian','Lebanese','Middle Eastern','Moroccan','Turkish') THEN 'Middle Eastern & African'
				   ELSE `CUISINE DESCRIPTION`
				   END AS `CUISINE DESCRIPTION`
		FROM restaurant_health_inspection_data_analysis.insp ) AS sub1
;

#Updating Table
UPDATE restaurant_health_inspection_data_analysis.insp
SET `CUISINE DESCRIPTION` = CASE 
				   WHEN `CUISINE DESCRIPTION` IN ('American', 'New American', 'Californian', 'Southwestern','Barbeque','Barbecue','Soul Food','Steakhouse') THEN 'American' 
                   WHEN `CUISINE DESCRIPTION` IN ('Mexican','Tex-Mex') THEN 'Mexican & Tex Mexican'
				   WHEN `CUISINE DESCRIPTION` IN ('French', 'New French', 'Haute Cuisine') THEN 'French' 
				   WHEN `CUISINE DESCRIPTION` IN ('Creole', 'Cajun', 'Creole/Cajun') THEN 'Creole/Cajun'
				   WHEN `CUISINE DESCRIPTION` IN ('Hotdogs', 'Hotdogs/Pretzels', 'Bagels/Pretzels','Chicken','Hamburgers') THEN 'Fast Food & Street Food'
				   WHEN `CUISINE DESCRIPTION` IN ('Sandwiches', 'Salads', 'Soups', 'Sandwiches/Salads/Mixed Buffet', 'Soups/Salads/Sandwiches') THEN 'Sandwiches/Soups/Salads'
				   WHEN `CUISINE DESCRIPTION` IN ('Bakery Products/Desserts','Donuts','Frozen Desserts','Nuts/Confectionary','Pancakes/Waffles') THEN 'Bakery & Desserts'
				   WHEN `CUISINE DESCRIPTION` IN ('Coffee/Tea','Juice','Smoothies','Fruit Salads','Bottled Beverages') THEN 'Beverages & Cafe'
				   WHEN `CUISINE DESCRIPTION` IN ('Vegan','Vegetarian','Fruits/Vegetables') THEN 'Vegetarian/Vegan'
				   WHEN `CUISINE DESCRIPTION` IN ('Not Listed/Not Applicable', 'Other') THEN 'Other/Unspecified'
                   WHEN `CUISINE DESCRIPTION` IN ('Chinese/Japanese','Chinese/Cuban','Fusion') THEN 'Fusion & Hybrid'
				   WHEN `CUISINE DESCRIPTION` IN ('Asian/Asian Fusion','Bangladeshi','Filipino','Indonesian','Pakistani','Southeast Asian','Hawaiian') THEN 'Asian Other'
				   WHEN `CUISINE DESCRIPTION` IN ('Brazilian','Chilean','Chimichurri','Latin American','Peruvian','Spanish') THEN 'Latin American & Spanish'
                   WHEN `CUISINE DESCRIPTION` IN ('Greek','Mediterranean') THEN 'Mediterranean & Greek'
				   WHEN `CUISINE DESCRIPTION` IN ('Armenian','Australian','Basque','Continental','Czech','Eastern European','English','German','Irish','Polish','Portuguese','Russian','Scandinavian','Tapas') THEN 'European (Other)'
				   WHEN `CUISINE DESCRIPTION` IN ('Afghan','African','Egyptian','Ethiopian','Iranian','Lebanese','Middle Eastern','Moroccan','Turkish') THEN 'Middle Eastern & African'
				   ELSE `CUISINE DESCRIPTION`
				   END
;

#############################################################################################################################################################################
    
    #inspeecting phone numbers with more than 10 numbers
SELECT *, CHAR_LENGTH(PHONE)
FROM restaurant_health_inspection_data_analysis.insp
WHERE CHAR_LENGTH(PHONE) > 10;

#Cleaning the phone format to nnn-nnn-nnnn
UPDATE restaurant_health_inspection_data_analysis.insp
SET PHONE = CONCAT(LEFT(PHONE,3),'-',RIGHT(LEFT(PHONE,6),3),'-',RIGHT(PHONE,4))
WHERE PHONE IS NOT NULL 
AND PHONE != '%-%' 
AND char_length(PHONE) = 10 
;

#stripping off the country code 1 from the 11 digit phone numbers
UPDATE restaurant_health_inspection_data_analysis.insp
SET PHONE = CONCAT(SUBSTRING(PHONE,2,3),'-',SUBSTRING(PHONE,5,3),'-',RIGHT(PHONE,4))
WHERE CHAR_LENGTH(PHONE) = 11 
AND LEFT(PHONE,1) = 1
;

#Verifying whether they got cleant
SELECT COUNT(PHONE)
FROM restaurant_health_inspection_data_analysis.insp
WHERE PHONE NOT LIKE '%-%';

############################################################################################################################################################################
#Checking whether BORO has 5 distinct values and no extra, no less
SELECT BORO, COUNT(BORO)
FROM restaurant_health_inspection_data_analysis.insp
WHERE BORO LIKE '0'
GROUP BY BORO
;

#Setting the BORO = 0 to NULL 
UPDATE restaurant_health_inspection_data_analysis.insp
SET BORO = NULL 
WHERE BORO LIKE '0'
; 

##############################################################################################################################################################################
#Checking for negative scores
SELECT SCORE
FROM restaurant_health_inspection_data_analysis.insp
WHERE SCORE < 0
;
#Not there. All clean
###########################################################################################################################
#Adding indexes to speeden up performance

ALTER TABLE restaurant_health_inspection_data_analysis.insp
       ADD INDEX indx_cuisine_description (`CUISINE DESCRIPTION`(100))
      ,ADD INDEX indx_insp (`INSPECTION DATE`)
      ,ADD INDEX indx_vc (`VIOLATION CODE`)
;

SHOW INDEX FROM restaurant_health_inspection_data_analysis.insp;

############################################################################################################################

######################################################################################################################################
#DATA CLEANING FOR NEW DATA SET 
#Duplicates
#Assigning the table row ids so that identifying and deleting duplicates is easy:
ALTER TABLE restaurant_health_inspection_data_analysis.insp2
ADD COLUMN row_id INT AUTO_INCREMENT PRIMARY KEY FIRST;

#Identifying dupliactes using row number
SET sql_safe_updates = 0; 

DELETE FROM restaurant_health_inspection_data_analysis.insp2
WHERE row_id IN 
   (SELECT row_id 
	FROM (
		SELECT row_id, ROW_NUMBER() OVER(PARTITION BY CAMIS, `INSPECTION DATE`,`VIOLATION CODE`,`INSPECTION TYPE`,`ACTION`,SCORE 
										ORDER BY row_id) AS rn
		FROM restaurant_health_inspection_data_analysis.insp2) AS sub1
	WHERE rn > 1)
;
SET sql_safe_updates = 1;

#Verifying if duplicates got deleted
SELECT row_id 
FROM (
		SELECT row_id, ROW_NUMBER() OVER(PARTITION BY CAMIS, `INSPECTION DATE`,`VIOLATION CODE`,`INSPECTION TYPE`,`ACTION`,SCORE 
										ORDER BY row_id) AS rn
		FROM restaurant_health_inspection_data_analysis.insp2 ) AS sub1
WHERE rn > 1
;

####################################################################################################################################################################################################
#Handling missing values, blanks,spaces and converting them to null to avoid data type errors
UPDATE restaurant_health_inspection_data_analysis.insp2
SET 
    BUILDING = NULLIF(TRIM(BUILDING),'')
    ,ZIPCODE = NULLIF(TRIM(ZIPCODE),'')
    ,PHONE = NULLIF(TRIM(PHONE),'')
    ,SCORE = NULLIF(TRIM(SCORE),'')
    ,`Council District` = NULLIF(TRIM(`Council District`),'')
    ,`Census Tract` = NULLIF(TRIM(`Census Tract`),'')
    ,BIN = NULLIF(TRIM(BIN),'')
    ,BBL = NULLIF(TRIM(BBL),'')
    ,DBA = NULLIF(TRIM(DBA),'')
    ,BORO = NULLIF(TRIM(BORO),'')
    ,STREET = NULLIF(TRIM(STREET),'')
    ,`CUISINE DESCRIPTION` = NULLIF(TRIM(`CUISINE DESCRIPTION`),'')
    ,`INSPECTION DATE` = NULLIF(TRIM(`INSPECTION DATE`),'')
    ,`ACTION` = NULLIF(TRIM(`ACTION`),'')
    ,`VIOLATION CODE` = NULLIF(TRIM(`VIOLATION CODE`),'')
    ,`VIOLATION DESCRIPTION` = NULLIF(TRIM(`VIOLATION DESCRIPTION`),'')
    ,`CRITICAL FLAG` = NULLIF(TRIM(`CRITICAL FLAG`),'')
    ,GRADE = NULLIF(TRIM(GRADE),'')
    ,`GRADE DATE` = NULLIF(TRIM(`GRADE DATE`),'')
    ,`RECORD DATE` = NULLIF(TRIM(`RECORD DATE`),'')
    ,`INSPECTION TYPE` = NULLIF(TRIM(`INSPECTION TYPE`),'')
    ,NTA = NULLIF(TRIM(NTA),'')
    ;

###############################################################################################################################################################################
#Changing data types after handling blank values, converting them to null so that when data type is being changed there are o errors thrown
#checking data types
DESCRIBE restaurant_health_inspection_data_analysis.insp2;

ALTER TABLE restaurant_health_inspection_data_analysis.insp2
MODIFY CAMIS INT
,MODIFY SCORE INT
,MODIFY `INSPECTION DATE` DATE 
,MODIFY `GRADE DATE` DATE 
,MODIFY `RECORD DATE` DATE 
,MODIFY BORO VARCHAR(50)
,MODIFY BUILDING VARCHAR(50)
,MODIFY ZIPCODE VARCHAR(50)
,MODIFY PHONE VARCHAR(25)
,MODIFY GRADE VARCHAR(50)
,MODIFY `CRITICAL FLAG` VARCHAR(30)
,MODIFY `VIOLATION CODE` VARCHAR(30)
,MODIFY BIN VARCHAR(20)
,MODIFY BBL VARCHAR(20)
, MODIFY `Community Board` VARCHAR(20)
,MODIFY `Council District` VARCHAR(20)
,MODIFY `Census Tract` VARCHAR(20)
,MODIFY NTA VARCHAR(20)
;

#Converting the inspection date column throws an error because there are dates '1900-01-00'  which sql doesn't recognise. So we must convert them to null
SELECT row_id , `INSPECTION DATE`
FROM restaurant_health_inspection_data_analysis.insp2
WHERE  `INSPECTION DATE` LIKE '1900-%'  
;

UPDATE restaurant_health_inspection_data_analysis.insp2
SET `INSPECTION DATE` = NULL 
WHERE `INSPECTION DATE` LIKE '1900-%'
;

#Checking whether similar issue persists with record and grade date.No it doesn't.
SELECT row_id , `RECORD DATE`
FROM restaurant_health_inspection_data_analysis.insp2
WHERE  YEAR(`RECORD DATE`) LIKE '1900-%'  
;

#Chcking whether there are any empty or blank cells in score column . ----No
SELECT COUNT(*) AS invalid_scores
FROM restaurant_health_inspection_data_analysis.insp2
WHERE SCORE IS NOT NULL 
  AND SCORE NOT REGEXP '^-?[0-9]+$';
  
###############################################################################################################################################################################################################
    
## Standardizing cuisine descriptions
SELECT DISTINCT `CUISINE DESCRIPTION`
FROM restaurant_health_inspection_data_analysis.insp2
;

#Trial and error , Correction Before Updating
SELECT DISTINCT `CUISINE DESCRIPTION`
FROM		(SELECT 
				CASE 
				   WHEN `CUISINE DESCRIPTION` IN ('American', 'New American', 'Californian', 'Southwestern','Barbeque','Barbecue','Soul Food','Steakhouse') THEN 'American' 
                   WHEN `CUISINE DESCRIPTION` IN ('Mexican','Tex-Mex') THEN 'Mexican & Tex Mexican'
				   WHEN `CUISINE DESCRIPTION` IN ('French', 'New French', 'Haute Cuisine') THEN 'French' 
				   WHEN `CUISINE DESCRIPTION` IN ('Creole', 'Cajun', 'Creole/Cajun') THEN 'Creole/Cajun'
				   WHEN `CUISINE DESCRIPTION` IN ('Hotdogs', 'Hotdogs/Pretzels', 'Bagels/Pretzels','Chicken','Hamburgers') THEN 'Fast Food & Street Food'
				   WHEN `CUISINE DESCRIPTION` IN ('Sandwiches', 'Salads', 'Soups', 'Sandwiches/Salads/Mixed Buffet', 'Soups/Salads/Sandwiches') THEN 'Sandwiches/Soups/Salads'
				   WHEN `CUISINE DESCRIPTION` IN ('Bakery Products/Desserts','Donuts','Frozen Desserts','Nuts/Confectionary','Pancakes/Waffles') THEN 'Bakery & Desserts'
				   WHEN `CUISINE DESCRIPTION` IN ('Coffee/Tea','Juice','Smoothies','Fruit Salads','Bottled Beverages') THEN 'Beverages & Cafe'
				   WHEN `CUISINE DESCRIPTION` IN ('Vegan','Vegetarian','Fruits/Vegetables') THEN 'Vegetarian/Vegan'
				   WHEN `CUISINE DESCRIPTION` IN ('Not Listed/Not Applicable', 'Other') THEN 'Other/Unspecified'
                   WHEN `CUISINE DESCRIPTION` IN ('Chinese/Japanese','Chinese/Cuban','Fusion') THEN 'Fusion & Hybrid'
				   WHEN `CUISINE DESCRIPTION` IN ('Asian/Asian Fusion','Bangladeshi','Filipino','Indonesian','Pakistani','Southeast Asian','Hawaiian') THEN 'Asian Other'
				   WHEN `CUISINE DESCRIPTION` IN ('Brazilian','Chilean','Chimichurri','Latin American','Peruvian','Spanish') THEN 'Latin American & Spanish'
                   WHEN `CUISINE DESCRIPTION` IN ('Greek','Mediterranean') THEN 'Mediterranean & Greek'
				   WHEN `CUISINE DESCRIPTION` IN ('Armenian','Australian','Basque','Continental','Czech','Eastern European','English','German','Irish','Polish','Portuguese','Russian','Scandinavian','Tapas') THEN 'European (Other)'
				   WHEN `CUISINE DESCRIPTION` IN ('Afghan','African','Egyptian','Ethiopian','Iranian','Lebanese','Middle Eastern','Moroccan','Turkish') THEN 'Middle Eastern & African'
				   ELSE `CUISINE DESCRIPTION`
				   END AS `CUISINE DESCRIPTION`
		FROM restaurant_health_inspection_data_analysis.insp2 ) AS sub1
;

#Updating Table
UPDATE restaurant_health_inspection_data_analysis.insp2
SET `CUISINE DESCRIPTION` = CASE 
				   WHEN `CUISINE DESCRIPTION` IN ('American', 'New American', 'Californian', 'Southwestern','Barbeque','Barbecue','Soul Food','Steakhouse') THEN 'American' 
                   WHEN `CUISINE DESCRIPTION` IN ('Mexican','Tex-Mex') THEN 'Mexican & Tex Mexican'
				   WHEN `CUISINE DESCRIPTION` IN ('French', 'New French', 'Haute Cuisine') THEN 'French' 
				   WHEN `CUISINE DESCRIPTION` IN ('Creole', 'Cajun', 'Creole/Cajun') THEN 'Creole/Cajun'
				   WHEN `CUISINE DESCRIPTION` IN ('Hotdogs', 'Hotdogs/Pretzels', 'Bagels/Pretzels','Chicken','Hamburgers') THEN 'Fast Food & Street Food'
				   WHEN `CUISINE DESCRIPTION` IN ('Sandwiches', 'Salads', 'Soups', 'Sandwiches/Salads/Mixed Buffet', 'Soups/Salads/Sandwiches') THEN 'Sandwiches/Soups/Salads'
				   WHEN `CUISINE DESCRIPTION` IN ('Bakery Products/Desserts','Donuts','Frozen Desserts','Nuts/Confectionary','Pancakes/Waffles') THEN 'Bakery & Desserts'
				   WHEN `CUISINE DESCRIPTION` IN ('Coffee/Tea','Juice','Smoothies','Fruit Salads','Bottled Beverages') THEN 'Beverages & Cafe'
				   WHEN `CUISINE DESCRIPTION` IN ('Vegan','Vegetarian','Fruits/Vegetables') THEN 'Vegetarian/Vegan'
				   WHEN `CUISINE DESCRIPTION` IN ('Not Listed/Not Applicable', 'Other') THEN 'Other/Unspecified'
                   WHEN `CUISINE DESCRIPTION` IN ('Chinese/Japanese','Chinese/Cuban','Fusion') THEN 'Fusion & Hybrid'
				   WHEN `CUISINE DESCRIPTION` IN ('Asian/Asian Fusion','Bangladeshi','Filipino','Indonesian','Pakistani','Southeast Asian','Hawaiian') THEN 'Asian Other'
				   WHEN `CUISINE DESCRIPTION` IN ('Brazilian','Chilean','Chimichurri','Latin American','Peruvian','Spanish') THEN 'Latin American & Spanish'
                   WHEN `CUISINE DESCRIPTION` IN ('Greek','Mediterranean') THEN 'Mediterranean & Greek'
				   WHEN `CUISINE DESCRIPTION` IN ('Armenian','Australian','Basque','Continental','Czech','Eastern European','English','German','Irish','Polish','Portuguese','Russian','Scandinavian','Tapas') THEN 'European (Other)'
				   WHEN `CUISINE DESCRIPTION` IN ('Afghan','African','Egyptian','Ethiopian','Iranian','Lebanese','Middle Eastern','Moroccan','Turkish') THEN 'Middle Eastern & African'
				   ELSE `CUISINE DESCRIPTION`
				   END
;

#############################################################################################################################################################################
    
    #inspeecting phone numbers with more than 10 numbers
SELECT *, CHAR_LENGTH(PHONE)
FROM restaurant_health_inspection_data_analysis.insp2
WHERE CHAR_LENGTH(PHONE) > 10;

#Cleaning the phone format to nnn-nnn-nnnn
UPDATE restaurant_health_inspection_data_analysis.insp2
SET PHONE = CONCAT(LEFT(PHONE,3),'-',RIGHT(LEFT(PHONE,6),3),'-',RIGHT(PHONE,4))
WHERE PHONE IS NOT NULL 
AND PHONE != '%-%' 
AND char_length(PHONE) = 10 
;

#stripping off the country code 1 from the 11 digit phone numbers
UPDATE restaurant_health_inspection_data_analysis.insp2
SET PHONE = CONCAT(SUBSTRING(PHONE,2,3),'-',SUBSTRING(PHONE,5,3),'-',RIGHT(PHONE,4))
WHERE CHAR_LENGTH(PHONE) = 11 
AND LEFT(PHONE,1) = 1
;

#Verifying whether they got cleant
SELECT COUNT(PHONE)
FROM restaurant_health_inspection_data_analysis.insp2
WHERE PHONE NOT LIKE '%-%';

############################################################################################################################################################################
#Checking whether BORO has 5 distinct values and no extra, no less
SELECT BORO, COUNT(BORO)
FROM restaurant_health_inspection_data_analysis.insp
WHERE BORO LIKE '0'
GROUP BY BORO
;

#Setting the BORO = 0 to NULL 
UPDATE restaurant_health_inspection_data_analysis.insp2
SET BORO = NULL 
WHERE BORO LIKE '0'
; 

##############################################################################################################################################################################
#Checking for negative scores
SELECT SCORE
FROM restaurant_health_inspection_data_analysis.insp
WHERE SCORE < 0
;
#Not there. All clean
###########################################################################################################################
#Adding indexes to speeden up performance

ALTER TABLE restaurant_health_inspection_data_analysis.insp2
       ADD INDEX indx_cuisine_description (`CUISINE DESCRIPTION`(100))
      ,ADD INDEX indx_insp (`INSPECTION DATE`)
      ,ADD INDEX indx_vc (`VIOLATION CODE`)
;

SHOW INDEX FROM restaurant_health_inspection_data_analysis.insp;

############################################################################################################################







