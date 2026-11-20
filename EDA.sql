#Exploratory Data Analysis
############################################################################################################################################################
#Restaurant Count by Borough
SELECT BORO
	  ,COUNT(DISTINCT CAMIS) AS `Restaurant Count`
      ,SUM(CASE WHEN `INSPECTION DATE` IS NOT NULL THEN 1 ELSE 0 END) AS `Inspection Count` 
FROM restaurant_health_inspection_data_analysis.insp
WHERE BORO IS NOT NULL AND YEAR(`INSPECTION DATE`) LIKE 2025
GROUP BY BORO
ORDER BY COUNT(DISTINCT CAMIS) DESC
;

##########################################################################################################################################################

#Restaurant and inspection counts over time
SELECT YEAR(`INSPECTION DATE`) AS Year
	  ,COUNT(DISTINCT CAMIS) AS `Restaurant Count`
      ,SUM(CASE WHEN `INSPECTION DATE` IS NOT NULL THEN 1 ELSE 0 END) AS `Inspection Count` 
FROM restaurant_health_inspection_data_analysis.insp
WHERE `INSPECTION DATE` IS NOT NULL
GROUP BY YEAR(`INSPECTION DATE`)
ORDER BY Year
;

###########################################################################################################################################################

#Total Restaurants in NYC in 2025? 
SELECT COUNT(DISTINCT CAMIS) AS `Restaurant Count`
FROM restaurant_health_inspection_data_analysis.insp
WHERE YEAR(`INSPECTION DATE`) = 2025
;

#############################################################################################################################################################

#Distribution of grades across NYC
SELECT BORO AS Borough
       ,GRADE AS Grade
       , CASE 
             WHEN GRADE = 'N' THEN 'Not Yet Graded'
             WHEN GRADE = 'P' THEN 'Grade Pending Issued on Reopening'
             WHEN GRADE = 'A' THEN 'Grade A'
             WHEN GRADE = 'B' THEN 'Grade B'
             WHEN GRADE = 'C' THEN 'Grade C'
             WHEN GRADE = 'Z' THEN 'Grade Pending'
             END AS Meaning
       ,COUNT(DISTINCT CAMIS,`INSPECTION DATE`,`INSPECTION TYPE`) AS `Inspection Count`
FROM restaurant_health_inspection_data_analysis.insp
WHERE GRADE IS NOT NULL
GROUP BY GRADE, BORO
ORDER BY Grade , `Inspection Count` DESC
;

##################################################################################################################################################################

#The most common inspection types
SELECT `INSPECTION TYPE` AS `Inspection Type`
       ,COUNT(DISTINCT CAMIS , `INSPECTION DATE`) AS `Inspection Count`
       ,ROUND(COUNT(DISTINCT CAMIS , `INSPECTION DATE`) * 100 /
		NULLIF(SUM(COUNT(DISTINCT CAMIS , `INSPECTION DATE`)) OVER(),0)  ,2) AS Percentage
FROM restaurant_health_inspection_data_analysis.insp
WHERE `INSPECTION TYPE` IS NOT NULL
   AND `INSPECTION DATE` IS NOT NULL 
GROUP BY `INSPECTION TYPE`
ORDER BY `Inspection Count` DESC
LIMIT 5
;


SELECT `INSPECTION TYPE` AS `Inspection Type`
	   , CASE WHEN `INSPECTION TYPE` LIKE 'Cycle Inspection%' 
				OR `INSPECTION TYPE` LIKE 'Pre-permit (Operational)%' THEN 'Gradable'
			  ELSE 'Non-Gradable'
		 END AS `Grade Eligibility`
       ,COUNT(DISTINCT CAMIS , `INSPECTION DATE`,`INSPECTION TYPE`) AS `Inspection Count`
	   ,ROUND(COUNT(DISTINCT CAMIS , `INSPECTION DATE`) * 100 /
		NULLIF(SUM(COUNT(DISTINCT CAMIS , `INSPECTION DATE`)) OVER(),0)  ,2) AS `Share %`
       ,SUM(CASE WHEN `CRITICAL FLAG` = 'Critical' THEN 1 ELSE 0 END ) * 100 /
        NULLIF(SUM(CASE WHEN `CRITICAL FLAG` IN ('Critical','Not Critical') THEN 1 ELSE 0 END),0) AS `Critical Violation %`
FROM restaurant_health_inspection_data_analysis.insp
WHERE `INSPECTION TYPE` IS NOT NULL
   AND `INSPECTION DATE` IS NOT NULL 
GROUP BY `INSPECTION TYPE`
ORDER BY `Inspection Count` DESC
LIMIT 5
;

##################################################################################################################################################################

#Top 10 most frequent violations, their  severity, citation count , share in the top 10 and how many unique restaurants affeected

SELECT `VIOLATION CODE`
	   ,MAX(`VIOLATION DESCRIPTION`) AS `Violation Description`
       ,MAX(`CRITICAL FLAG`) AS Severity
	   ,COUNT(*) AS `Citation Count`
       ,ROUND(COUNT(*) * 100 / NULLIF(SUM(COUNT(*)) OVER () ,0),2) AS 'Share %'
       ,COUNT(DISTINCT CAMIS) AS 'Unique Restaurants Affected'
FROM restaurant_health_inspection_data_analysis.insp
WHERE `VIOLATION DESCRIPTION` IS NOT NULL
GROUP BY `VIOLATION DESCRIPTION`, `VIOLATION CODE`
ORDER BY `Citation Count` DESC , Severity 
LIMIT 10
;

##################################################################################################################################################################

#Top  cuisines with the lowest average scores
SELECT  `CUISINE DESCRIPTION`
        ,ROUND(AVG(SCORE),2) AS `Average Score`
FROM restaurant_health_inspection_data_analysis.insp
WHERE `CUISINE DESCRIPTION` IS NOT NULL
GROUP BY `CUISINE DESCRIPTION`
ORDER BY `Average Score` 
LIMIT 10
;

####################################################################################################################################################################

#Top 10 Cuisines by restaurant count in NYC
SELECT `CUISINE DESCRIPTION` , COUNT(DISTINCT CAMIS) AS `Restaurant Count`
FROM restaurant_health_inspection_data_analysis.insp
WHERE `CUISINE DESCRIPTION` IS NOT NULL 
GROUP BY `CUISINE DESCRIPTION`
ORDER BY `Restaurant Count` DESC
LIMIT 10
;  

#######################################################################################################################################################################

#Same name but different CAMIS, different owners and different location. Chain stores get one CAMIS though
SELECT DISTINCT DBA , COUNT(DISTINCT CAMIS)
FROM restaurant_health_inspection_data_analysis.insp
GROUP BY DBA
HAVING COUNT(DISTINCT CAMIS) > 1
ORDER BY COUNT(DISTINCT CAMIS) DESC;

########################################################################################################################################################################

#What % of critical, not critical and not applicable do each BORO hold?
SELECT * 
        , ROUND(`Violation Count` * 100 / SUM(`Violation Count`) OVER(PARTITION BY  `CRITICAL FLAG`),2) AS `% of Flag Total`
        ,RANK() OVER(PARTITION BY `CRITICAL FLAG` ORDER BY  `Violation Count` DESC) as `Borough Rank` 
FROM(	SELECT `CRITICAL FLAG`
               ,BORO
               ,COUNT(`CAMIS`) AS `Violation Count`
		FROM restaurant_health_inspection_data_analysis.insp
		WHERE BORO IS NOT NULL 
			  AND `CRITICAL FLAG` IS NOT NULL 
		GROUP BY `CRITICAL FLAG`,BORO
	) AS sub1
;

########################################################################################################################################################################

#Which borough has the highest proportion of critical vs non critical violations
WITH boro_flag_counts AS (
                  SELECT BORO
					  ,`CRITICAL FLAG`
					  ,COUNT(*) AS `Violation Count`
                      ,ROUND( COUNT(*) * 100 / SUM(COUNT(*)) OVER (PARTITION BY BORO) , 2) AS `% of BORO Total`  
                  FROM restaurant_health_inspection_data_analysis.insp
                  WHERE `CRITICAL FLAG` IN ('Critical','Not Critical') AND BORO IS NOT NULL
                  GROUP BY BORO, `CRITICAL FLAG`
                  ) 
SELECT *
       ,RANK() OVER(PARTITION BY `CRITICAL FLAG` ORDER BY `% of BORO Total` DESC) AS `Critical Rate Rank`
FROM boro_flag_counts
;
  
#########################################################################################################################################################################  
  
##Cuisines with the Highest Volume of Critical Violations
WITH ranking AS (
		SELECT `CUISINE DESCRIPTION` AS Cuisine
               ,SUM(CASE WHEN `CRITICAL FLAG` = "Critical" THEN 1 ELSE 0 END) AS `Critical Violations`
               ,COUNT(*) AS `Total Violations`
               ,ROUND(SUM(CASE WHEN `CRITICAL FLAG` = "Critical" THEN 1 ELSE 0 END) * 100 /
                 NULLIF(COUNT(*),0) , 2) AS `Critical Share %`
		FROM restaurant_health_inspection_data_analysis.insp
        WHERE `CRITICAL FLAG` IN ('Critical','Not Critical')
          AND `CUISINE DESCRIPTION` IS NOT NULL 
          AND `INSPECTION DATE` IS NOT NULL
		GROUP BY `CUISINE DESCRIPTION`
        HAVING COUNT(*) >= 100
        )
SELECT RANK() OVER(ORDER BY `Critical Violations` DESC) AS `Violation Rank`
	   , Cuisine 
       ,`Critical Violations`
       ,`Total Violations`
       ,`Critical Share %`
FROM ranking     
ORDER BY `Critical Violations` DESC
LIMIT 10
;

##########################################################################################################################################################################

#Overall Score Yearly Trend
 WITH flag_count AS (
		SELECT YEAR(`INSPECTION DATE`) AS `Inspection Year` 
			  ,ROUND(AVG(SCORE),2) AS  `Average Score`
		FROM restaurant_health_inspection_data_analysis.insp
		WHERE YEAR(`INSPECTION DATE`) IS NOT NULL
		GROUP BY  YEAR(`INSPECTION DATE`)
        )
SELECT `Inspection Year` 
       ,`Average Score`
       ,LAG(`Average Score`) OVER(ORDER BY `Inspection Year` ) AS `Previous Year Average`
       ,`Average Score` - LAG(`Average Score`) OVER(ORDER BY `Inspection Year` ) AS Difference
       ,ROUND(((`Average Score` - LAG(`Average Score`) OVER(ORDER BY `Inspection Year` )) * 100)
                 / NULLIF(LAG(`Average Score`) OVER(ORDER BY `Inspection Year` ),0) ,2)                          
                 AS `% Increase in Average Score`
FROM flag_count
ORDER BY `Inspection Year` 
;

################################################################################################################################################
 
 #Total Critical Violations Yearly Trend
 WITH flag_count AS (
		SELECT YEAR(`INSPECTION DATE`) AS `Inspection Year` 
			  ,SUM(CASE WHEN `CRITICAL FLAG` LIKE 'Critical' THEN 1 ELSE 0 END) AS `Critical Violations Count`
			  ,COUNT(DISTINCT CAMIS,`INSPECTION DATE`,`INSPECTION TYPE`) AS `Total Inspections`
              ,ROUND(
            SUM(CASE WHEN `CRITICAL FLAG` = 'Critical' THEN 1 ELSE 0 END) * 100.0 /
            NULLIF(SUM(CASE WHEN `CRITICAL FLAG` IN ('Critical', 'Not Critical') THEN 1 ELSE 0 END), 0),
            2
        ) AS `Critical Share %`
		FROM restaurant_health_inspection_data_analysis.insp
		WHERE YEAR(`INSPECTION DATE`) IS NOT NULL
		GROUP BY  YEAR(`INSPECTION DATE`)
        )
SELECT `Inspection Year` 
       ,`Total Inspections`
       ,`Critical Violations Count`
       ,`Critical Share %`
       ,LAG(`Critical Violations Count`) OVER(ORDER BY `Inspection Year` ) AS `Previous Year Count`
       ,`Critical Violations Count` - LAG(`Critical Violations Count`) OVER(ORDER BY `Inspection Year` ) AS Difference
       ,ROUND(((`Critical Violations Count` - LAG(`Critical Violations Count`) OVER(ORDER BY `Inspection Year` )) * 100)
                 / NULLIF(LAG(`Critical Violations Count`) OVER(ORDER BY `Inspection Year` ),0) ,2)                          
                 AS `% Increase in Critical Violations`
FROM flag_count
ORDER BY `Inspection Year` 
;

 ###############################################################################################################################################################
 
 #How has Manhattann performed over the years?
 #Overall Score Trend across Years
 WITH flag_count AS (
		SELECT YEAR(`INSPECTION DATE`) AS `Inspection Year` 
			  ,ROUND(AVG(SCORE),2) AS  `Average Score`
		FROM restaurant_health_inspection_data_analysis.insp
		WHERE YEAR(`INSPECTION DATE`) IS NOT NULL AND BORO =  'Manhattan'
		GROUP BY  YEAR(`INSPECTION DATE`)
        )
SELECT `Inspection Year` 
       ,`Average Score`
       ,LAG(`Average Score`) OVER(ORDER BY `Inspection Year` ) AS `Previous Year Average`
       ,`Average Score` - LAG(`Average Score`) OVER(ORDER BY `Inspection Year` ) AS Difference
       ,ROUND(((`Average Score` - LAG(`Average Score`) OVER(ORDER BY `Inspection Year` )) * 100)
                 / NULLIF(LAG(`Average Score`) OVER(ORDER BY `Inspection Year` ),0) ,2)                          
                 AS `% Increase in Average Scores`
FROM flag_count
ORDER BY `Inspection Year` 
;

#######################################################################################################################################################################3
      
SELECT *
FROM restaurant_health_inspection_data_analysis.insp
;

     