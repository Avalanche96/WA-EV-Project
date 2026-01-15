/*Table #1 Setup
CREATE Table electric_vehicle_population.info
("VIN" as varchar,
"County" as varchar,
"City" as varchar,
"State" as varchar,
"Postal Code" as integer,
"Model Year" as integer,
"Make" as varchar,
"Model" as varchar,
"Electric Vehicle Type" as varchar,
"Clean Alternative Fuel Vehicle (CAFV) Eligibility" as varchar,
"Electric Range" as integer,
"Base MSRP" as integer,
"Legislative District" as integer,
"DOL Vehicle ID" as bigint,
"Vehicle Location" as varchar,
"Electric Utility" as varchar,
"2020 Census Tract" as bigint,
);

ALTER TABLE IF EXISTS electric_vehicle_population.info
    OWNER to postgres;


COPY electric_vehicle_population.info ("VIN", "County", "City", "State", "Postal Code", "Model Year", "Make", "Model", "Electric Vehicle Type",
"Clean Alternative Fuel Vehicle (CAFV) Eligibility", "Electric Range", "Base MSRP", "Legislative District", "DOL Vehicle ID", "Vehicle Location",
"Electric Utility", "2020 Census Tract")
FROM 'E:\Microsoft Office\WIP_Electric_Vehicle_Population_Data.csv'
DELIMITER ','
CSV HEADER;
*/
--------------------------------------------------------------------------------------------------------------
/* Checking the result of the newly imported dataset for Table #1
SELECT *
FROM
electric_vehicle_population.info;
*/
--------------------------------------------------------------------------------------------------------------
/*Filtering by one condition
SELECT * FROM
electric_vehicle_population.info
WHERE "State" = 'WA'
;
--------------------------------------------------------------------------------------------------------------
/* Table #2 Setup
CREATE Table electric_vehicle_population.counties
("Date" as date,
"County Of Residence" as varchar,
"State Of Residence" as varchar,
"Vehicle Primary Use" as varchar,
"Battery Electric Vehicles (BEVs)" as integer,
"Plug-In Hybrid Electric Vehicles (PHEVs)" as integer,
"Electric Vehicle (EV) Total" as integer,
"Non-Electric Vehicle Total" as bigint,
"Total Vehicles" as bigint,
"Percent Electric Vehicles" as numeric (5, 2)
);

ALTER TABLE IF EXISTS electric_vehicle_population.counties
    OWNER to postgres;

COPY electric_vehicle_population.counties("Date", "County Of Residence", "State Of Residence", "Vehicle Primary Use", "Battery Electric Vehicles (BEVs)",
"Plug-In Hybrid Electric Vehicles (PHEVs)", "Electric Vehicle (EV) Total", "Non-Electric Vehicle Total", "Total Vehicles",
"Percent Electric Vehicles")
FROM 'E:\Microsoft Office\WIP_Electric_Vehicle_Population_Size_History_By_County.csv'
DELIMITER ','
CSV HEADER;
-----------------------------------------------------------------------------------------------------------------------------------
/*Checking the result of the newly imported dataset for Table #2
SELECT *
FROM
electric_vehicle_population.counties;
-----------------------------------------------------------------------------------------------------------------------------------
Preliminary Filtering for Table #1
SELECT
"VIN", "County", "City", "State", "Postal Code", "Model Year", "Make", "Model", "Electric Vehicle Type", "Clean Alternative Fuel Vehicle (CAFV) Eligibility",
"Electric Range", "Base MSRP", "Legislative District", "DOL Vehicle ID", "Vehicle Location", "Electric Utility"
FROM electric_vehicle_population.info 
WHERE "State" = 'WA';
-----------------------------------------------------------------------------------------------------------------------------------
Preliminary Filtering for Table #2
SELECT
*
FROM electric_vehicle_population.counties 
WHERE "State Of Residence" = 'WA'
ORDER BY "Date";
-----------------------------------------------------------------------------------------------------------------------------------
Determining the most popular make & model of electric vehicle  (Table #1)
Make query:

SELECT "Make", COUNT ("Model") AS total_num_of_make
FROM electric_vehicle_population.info
WHERE
	"State" = 'WA'
GROUP BY "Make"
ORDER BY total_num_of_make DESC;

Model query:
SELECT "Model", COUNT ("Make") AS most_popular_model
FROM electric_vehicle_population.info
WHERE
	"State" = 'WA'
GROUP BY "Model"
ORDER BY most_popular_model DESC;
-----------------------------------------------------------------------------------------------------------------------------------
Determining total tax credit eligibility (Table #1)

SELECT "Clean Alternative Fuel Vehicle (CAFV) Eligibility", COUNT (*) AS total_population_eligibility
FROM electric_vehicle_population.info
WHERE
	"State" = 'WA' 
GROUP BY "Clean Alternative Fuel Vehicle (CAFV) Eligibility";
-----------------------------------------------------------------------------------------------------------------------------------
Determining which counties have the highest # of electric vehicles still to be researched for tax credit eligibility (Table #1)

SELECT "County", COUNT (*) AS total_eligibility_unknown
FROM electric_vehicle_population.info
WHERE
	"State" = 'WA'
	AND "Clean Alternative Fuel Vehicle (CAFV) Eligibility" = 'Eligibility unknown as battery range has not been researched'
GROUP BY "County"
ORDER BY total_eligibility_unknown DESC;
-----------------------------------------------------------------------------------------------------------------------------------
Determining which counties have the highest # of electric vehicles that are not eligibile for the tax credit (Table #1)

SELECT "County", COUNT (*) AS total_eligibility_failed
FROM electric_vehicle_population.info
WHERE
	"State" = 'WA'
	AND "Clean Alternative Fuel Vehicle (CAFV) Eligibility" = 'Not eligible due to low battery range'
GROUP BY "County"
ORDER BY total_eligibility_failed DESC;
-----------------------------------------------------------------------------------------------------------------------------------
Which make, model, & model year combos need to be researched to determine tax credit eligibility (Table #1)

SELECT "Make", "Model", "Model Year", COUNT(*) AS total_eligibility_unknown
FROM electric_vehicle_population.info
WHERE
	"State" = 'WA'
	AND "Clean Alternative Fuel Vehicle (CAFV) Eligibility" = 'Eligibility unknown as battery range has not been researched'
GROUP BY "Make", "Model", "Model Year"
ORDER BY total_eligibility_unknown DESC;
-----------------------------------------------------------------------------------------------------------------------------------
Tweaking the date column for better readability (Table #2)

SELECT TO_CHAR(DATE_TRUNC('month', "Date"), 'YYYY-MM') AS month
FROM
electric_vehicle_population.counties
-----------------------------------------------------------------------------------------------------------------------------------
Filtering by the "Vehicle Primary Use" column in order to reduce duplicate entries (Table #2)

SELECT *
FROM electric_vehicle_population.info
WHERE "Vehicle Primary Use" <> 'Truck'
-----------------------------------------------------------------------------------------------------------------------------------
Determining the average percentage of electric vehicles in WA (Table #2)

SELECT AVG("Percent Electric Vehicles")
FROM electric_vehicle_population.counties
WHERE "State Of Residence" = 'WA'
AND "Vehicle Primary Use" <> 'Truck';
-----------------------------------------------------------------------------------------------------------------------------------
How many EV population surveys have been conducted? (Table #2)

SELECT "County Of Residence", COUNT(*) AS total_num_of_surveys
FROM electric_vehicle_population.counties
WHERE "State Of Residence" = 'WA'
AND "Vehicle Primary Use" <> 'Truck'
-----------------------------------------------------------------------------------------------------------------------------------
What is the average percentage of electric vehicles in WA and which counties are above that average and which counties are below that average? (Table #2)

WITH wa_avg_ev_percentage AS (
	SELECT AVG("Percent Electric Vehicles") AS average_percent_of_evs 
	FROM
	electric_vehicle_population.counties
	WHERE "State Of Residence" = 'WA'
	AND "Vehicle Primary Use" <> 'Truck'
)
SELECT i.*, wa.average_percent_of_evs,
ROUND(
	(i."Percent Electric Vehicles" - wa.average_percent_of_evs) * 100,
	2
) AS percent_away_from_avg
FROM (
    SELECT
        "Date",
        "County Of Residence",
        "Battery Electric Vehicles (BEVs)",
		"Plug-In Hybrid Electric Vehicles (PHEVs)",
		"Electric Vehicle (EV) Total",
		"Non-Electric Vehicle Total",
		"Total Vehicles",
        "Percent Electric Vehicles"
    FROM electric_vehicle_population.counties 
    WHERE "State Of Residence" = 'WA'
      AND "Vehicle Primary Use" <> 'Truck'

) i
CROSS JOIN wa_avg_ev_percentage wa
ORDER BY "Percent Electric Vehicles" DESC;
-----------------------------------------------------------------------------------------------------------------------------------
What is the known average electric range of EVS in Washington according to the dataset? (Table #1)

SELECT AVG("Electric Range")
FROM
electric_vehicle_population.info
WHERE "State" = 'WA'
AND "Clean Alternative Fuel Vehicle (CAFV) Eligibility" <> 'Eligibility Unknown as battery capacity has not been researched'
------------------------------------------------------------------------------------------------------------------------------------
Which utility companies see the most usage from EVs in Washington? (Table #1)

SELECT "Electric Utility", COUNT (*) AS most_used_utility
FROM
electric_vehicle_population.info
WHERE "State" = 'WA'
GROUP BY "Electric Utility"
ORDER BY most_used_utility DESC;
-----------------------------------------------------------------------------------------------------------------------------------
Adding the most_used_utility column, the percent difference from the WA average electric range column to the original dataset and exporting (Table #1)

WITH utility_count AS (
	SELECT "Electric Utility", COUNT (*) AS most_used_utility
	FROM electric_vehicle_population.info
	WHERE "State" = 'WA'
	GROUP BY "Electric Utility"	
),

wa_avg AS (
SELECT AVG("Electric Range") AS avg_wa_range
FROM
electric_vehicle_population.info
WHERE "State" = 'WA'
AND "Clean Alternative Fuel Vehicle (CAFV) Eligibility" <> 'Eligibility Unknown as battery capacity has not been researched'
)
SELECT i."County", i."City", i."State", i."Postal Code", i."Model Year", i."Make", i."Model", i."Electric Vehicle Type", 
i."Clean Alternative Fuel Vehicle (CAFV) Eligibility", i."Electric Range", i."Base MSRP", i."Legislative District", i."DOL Vehicle ID", 
i."Vehicle Location", i."Electric Utility", u.most_used_utility,
CASE
	WHEN "Electric Range" = 0 THEN NULL
	ELSE ROUND(
(i."Electric Range" - wa.avg_wa_range) / wa.avg_wa_range * 100,
2
) END AS pct_diff_from_avg_wa_range
FROM electric_vehicle_population.info i
LEFT JOIN utility_count u
	ON i."Electric Utility" = u."Electric Utility"
CROSS JOIN wa_avg wa
WHERE i."State" = 'WA'
AND i."Base MSRP" <> 0;
-----------------------------------------------------------------------------------------------------------------------------------
Exporting Table #2

WITH total_dates AS (
    SELECT COUNT(DISTINCT "Date") AS total_num_of_dates
    FROM electric_vehicle_population.counties
    WHERE "State Of Residence" = 'WA'
      AND "Vehicle Primary Use" <> 'Truck'
)
SELECT *,
    ROUND(
        (below_avg_ev_concentration::numeric / total_num_of_dates) * 100,
        2
    ) AS percent_of_dates_below_avg
FROM (
    SELECT
        "Date",
        "County Of Residence",
        "Battery Electric Vehicles (BEVs)",
		"Plug-In Hybrid Electric Vehicles (PHEVs)",
		"Electric Vehicle (EV) Total",
		"Non-Electric Vehicle Total",
		"Total Vehicles",
        "Percent Electric Vehicles",
        COUNT(*) OVER (PARTITION BY "Date") AS below_avg_ev_concentration
    FROM electric_vehicle_population.counties
    WHERE "State Of Residence" = 'WA'
      AND "Vehicle Primary Use" <> 'Truck'
      AND "Percent Electric Vehicles" < (
          SELECT AVG("Percent Electric Vehicles")
          FROM electric_vehicle_population.counties
          WHERE "State Of Residence" = 'WA'
            AND "Vehicle Primary Use" <> 'Truck'
      )
) x
CROSS JOIN total_dates;