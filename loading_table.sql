#Clearing the loaded 97 rows (partial rows)
TRUNCATE TABLE restaurant_health_inspection_data_analysis.insp;

#Enabling local file loading(one time setting)
SET GLOBAL local_infile = 1;

#Running the bulk import command
LOAD DATA LOCAL INFILE 'C:\\Users\\deepi\\OneDrive\\Desktop\\Restraunt Inspection Analysis NYC\\restr_insp_dt_cln.csv'
INTO TABLE restaurant_health_inspection_data_analysis.insp
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

#Verifying that all 2.88L rows loaded properly
SELECT COUNT(*)
FROM restaurant_health_inspection_data_analysis.insp;


#########################################################################################################################################
#Bulk loading the updated table too
#Clearing the loaded 97 rows (partial rows)
TRUNCATE TABLE restaurant_health_inspection_data_analysis.insp2;

#Enabling local file loading(one time setting)
SET GLOBAL local_infile = 1;

#Running the bulk import command 
LOAD DATA LOCAL INFILE "C:\\Users\\deepi\\OneDrive\\Desktop\\Restraunt Inspection Analysis NYC\\updated_restr_insp_dt_cln_csv.csv"
INTO TABLE restaurant_health_inspection_data_analysis.insp2
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;


#Verifying that all 1.07L rows loaded properly
SELECT COUNT(*)
FROM restaurant_health_inspection_data_analysis.insp2;
