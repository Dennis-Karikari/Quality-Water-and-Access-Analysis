USE md_water_services;

-- Are there any specific provinces, or towns where some sources are more abundant?
/* we will need province_name and town_name from the location table.
 We also need to know type_of_water_source and
number_of_people_served from the water_source table. */
SELECT 
	location.province_name,
    location.town_name,
    visits.visit_count,
    location.location_id,
    water_source.type_of_water_source,
    water_source.number_of_people_served
FROM 
	visits
JOIN location
ON visits.location_id = location.location_id
JOIN water_source
ON visits.source_id = water_source.source_id;

/* filter rows where visit_count > 1. 
These were the sites our surveyors collected additional information for
 but they happened at the
same source/location. */

SELECT
	visits.location_id,
    visits.source_id,
    location.province_name,
    location.town_name,
    visits.visit_count,
    water_source.type_of_water_source,
    water_source.number_of_people_served
FROM
	visits
JOIN
	location
ON visits.location_id = location.location_id
JOIN
	water_source
ON visits.source_id = water_source.source_id
WHERE 
	visits.location_id = 'AkHa00103';
	
-- now that we verified that the table is joined correctly, we can remove the location_id and visit_count columns.
-- Add the location_type column from location and time_in_queue from visits to our results set.
SELECT
	visits.location_id,
    visits.source_id,
    location.province_name,
    location.town_name,
    visits.visit_count,
    water_source.type_of_water_source,
    water_source.number_of_people_served
FROM
	visits
JOIN
	location
ON visits.location_id = location.location_id
JOIN
	water_source
ON visits.source_id = water_source.source_id
WHERE 
	visits.visit_count = 1;    
    
-- Add the location_type column from location and time_in_queue from visits to our results set.
SELECT
    location.province_name,
    location.town_name,
    water_source.type_of_water_source,
    water_source.number_of_people_served,
    location.location_type,
    visits.time_in_queue
FROM
	visits
JOIN
	location
ON visits.location_id = location.location_id
JOIN
	water_source
ON visits.source_id = water_source.source_id
WHERE
visits.visit_count = 1;

-- Now we need to grab the results from the well_pollution table.
SELECT
water_source.type_of_water_source,
location.town_name,
location.province_name,
location.location_type,
water_source.number_of_people_served,
visits.time_in_queue,
well_pollution.results
FROM
visits
LEFT JOIN
well_pollution
ON well_pollution.source_id = visits.source_id
INNER JOIN
location
ON location.location_id = visits.location_id
INNER JOIN
water_source
ON water_source.source_id = visits.source_id
WHERE
visits.visit_count = 1;

/* So this table contains the data we need for this analysis.
 Now we want to analyse the data in the results set.
 We can either create a CTE, and then query it, or in my case, 
 I'll make it a VIEW so it is easier to share with you. I'll call it the combined_analysis_table. */
CREATE VIEW combined_analysis_table AS 
-- This view assembles data from different tables into one to simplify analysis
SELECT
water_source.type_of_water_source AS source_type,
location.town_name,
location.province_name,
location.location_type,
water_source.number_of_people_served AS people_served,
visits.time_in_queue,
well_pollution.results
FROM
visits
LEFT JOIN
well_pollution
ON well_pollution.source_id = visits.source_id
INNER JOIN
location
ON location.location_id = visits.location_id
INNER JOIN
water_source
ON water_source.source_id = visits.source_id
WHERE
visits.visit_count = 1;

/* we want to break down our data into provinces or towns and source types. If we understand where
the problems are, and what we need to improve at those locations, 
we can make an informed decision on where to send our repair teams. */

SELECT
province_name,
SUM(people_served) AS total_ppl_serv
FROM
combined_analysis_table
GROUP BY
province_name;

WITH province_totals AS (-- This CTE calculates the population of each province
SELECT
province_name,
SUM(people_served) AS total_ppl_serv
FROM
combined_analysis_table AS ct
GROUP BY
province_name
)
SELECT
ct.province_name,
-- These case statements create columns for each type of source.
-- The results are aggregated and percentages are calculated
ROUND((SUM(CASE WHEN source_type = 'river'
THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS river,
ROUND((SUM(CASE WHEN source_type = 'shared_tap'
THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS shared_tap,
ROUND((SUM(CASE WHEN source_type = 'tap_in_home'
THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS tap_in_home,
ROUND((SUM(CASE WHEN source_type = 'tap_in_home_broken'
THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS tap_in_home_broken,
ROUND((SUM(CASE WHEN source_type = 'well'
THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS well
FROM
combined_analysis_table ct
JOIN
province_totals pt ON ct.province_name = pt.province_name
GROUP BY
ct.province_name
ORDER BY
ct.province_name;

-- Let's aggregate the data per town now.
WITH town_totals AS (-- This CTE calculates the population of each town
-- Since there are two Harare towns, we have to group by province_name and town_name
SELECT province_name, town_name, SUM(people_served) AS total_ppl_serv
FROM combined_analysis_table
GROUP BY province_name,town_name
)
SELECT
ct.province_name,
ct.town_name,
ROUND((SUM(CASE WHEN source_type = 'river'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS river,
ROUND((SUM(CASE WHEN source_type = 'shared_tap'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS shared_tap,
ROUND((SUM(CASE WHEN source_type = 'tap_in_home'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home,
ROUND((SUM(CASE WHEN source_type = 'tap_in_home_broken'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home_broken,
ROUND((SUM(CASE WHEN source_type = 'well'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS well
FROM
combined_analysis_table ct
JOIN -- Since the town names are not unique, we have to join on a composite key
town_totals tt ON ct.province_name = tt.province_name AND ct.town_name = tt.town_name
GROUP BY -- We group by province first, then by town.
ct.province_name,
ct.town_name
ORDER BY
ct.town_name;

-- Before we jump into the data, let's store it as a temporary table first, so it is quicker to access.
CREATE TEMPORARY TABLE town_aggregated_water_access
WITH town_totals AS(
SELECT province_name, town_name, SUM(people_served) AS total_ppl_serv
FROM combined_analysis_table
GROUP BY province_name,town_name
)
SELECT
ct.province_name,
ct.town_name,
ROUND((SUM(CASE WHEN source_type = 'river'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS river,
ROUND((SUM(CASE WHEN source_type = 'shared_tap'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS shared_tap,
ROUND((SUM(CASE WHEN source_type = 'tap_in_home'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home,
ROUND((SUM(CASE WHEN source_type = 'tap_in_home_broken'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home_broken,
ROUND((SUM(CASE WHEN source_type = 'well'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS well
FROM
combined_analysis_table ct
JOIN -- Since the town names are not unique, we have to join on a composite key
town_totals tt ON ct.province_name = tt.province_name AND ct.town_name = tt.town_name
GROUP BY -- We group by province first, then by town.
ct.province_name,
ct.town_name
ORDER BY
ct.town_name;

-- IF YOU CLOSE SQL, this temp table deletes, but run again to restore query.
SELECT
	*
FROM town_aggregated_water_access;

-- which town has the highest ratio of people who have taps, but have no running water?
SELECT
province_name,
town_name,
ROUND(tap_in_home_broken / (tap_in_home_broken + tap_in_home) *

100,0) AS Pct_broken_taps

FROM
town_aggregated_water_access;

-- PRATICAL PLAN
/* We need to know if the repair is complete, and the date it was
completed, and give them space to upgrade the sources.*/

CREATE TABLE Project_progress (
Project_id SERIAL PRIMARY KEY,
/* Project_id −− Unique key for sources in case we visit the same
source more than once in the future. 
*/
source_id VARCHAR(20) NOT NULL REFERENCES water_source(source_id) ON DELETE CASCADE ON UPDATE CASCADE,
/* source_id −− Each of the sources we want to improve should exist,
and should refer to the source table. This ensures data integrity.
*/
Address VARCHAR(50), -- Street address
Town VARCHAR(30),
Province VARCHAR(30),
Source_type VARCHAR(50),
Improvement VARCHAR(50), -- What the engineers should do at that place
Source_status VARCHAR(50) DEFAULT 'Backlog' CHECK (Source_status IN ('Backlog', 'In progress', 'Complete')),
/* Source_status −− We want to limit the type of information engineers can give us, so we
limit Source_status.
− By DEFAULT all projects are in the "Backlog" which is like a TODO list.
− CHECK() ensures only those three options will be accepted. This helps to maintain clean data. */
/*Date_of_completion DATE, -- Engineers will add this the day the source has been upgraded
Comments TEXT −− Engineers can leave comments. We use a TEXT type that has no limit on char length
);

-- THE REAAL QUERY IS BELOW
CREATE TABLE Project_progress (
Project_id SERIAL PRIMARY KEY,
source_id VARCHAR(20) NOT NULL REFERENCES water_source(source_id) ON DELETE CASCADE ON UPDATE CASCADE,
Address VARCHAR(50),
Town VARCHAR(30),
Province VARCHAR(30),
Source_type VARCHAR(50),
Improvement VARCHAR(50),
Source_status VARCHAR(50) DEFAULT 'Backlog' CHECK (Source_status IN ('Backlog', 'In progress', 'Complete')),
Date_of_completion DATE,
Comments TEXT
);

-- A PRATICAL PLAN
-- Project_progress_query
SELECT
location.address,
location.town_name,
location.province_name,
water_source.source_id,
water_source.type_of_water_source,
well_pollution.results
FROM
water_source
LEFT JOIN
well_pollution ON water_source.source_id = well_pollution.source_id
INNER JOIN
visits ON water_source.source_id = visits.source_id
INNER JOIN
location ON location.location_id = visits.location_id;


/* WHERE
visits.visit_count = 1 -- This must always be true
AND ( -- AND one of the following (OR) options must be true as well.
... != 'Clean'
OR ... IN ('tap_in_home_broken','...')
OR (... = 'shared_tap' AND ...)
) */

SELECT
location.address,
location.town_name,
location.province_name,
water_source.source_id,
water_source.type_of_water_source,
well_pollution.results
FROM
water_source
LEFT JOIN
well_pollution ON water_source.source_id = well_pollution.source_id
INNER JOIN
visits ON water_source.source_id = visits.source_id
INNER JOIN
location ON location.location_id = visits.location_id
WHERE
visits.visit_count = 1 
AND ( well_pollution.results != 'Clean'
OR water_source.type_of_water_source IN ('tap_in_home_broken','river')
OR (water_source.type_of_water_source = 'shared_tap' AND visits.time_in_queue >= 30)
);


SELECT
location.address,
location.town_name,
location.province_name,
water_source.source_id,
water_source.type_of_water_source,
well_pollution.results,
CASE
        WHEN well_pollution.results = 'Contaminated: Chemical'
        THEN 'Install RO filter' 
        WHEN well_pollution.results = 'Contaminated: Biological'
        THEN 'Install UV filter'
        WHEN water_source.type_of_water_source = 'river'
        THEN 'Drill well'
        WHEN water_source.type_of_water_source = 'shared_tap'
             AND visits.time_in_queue >= 30
        THEN CONCAT('Install ', FLOOR(visits.time_in_queue / 30), ' taps nearby')
        WHEN water_source.type_of_water_source = 'tap_in_home_broken' 
        THEN 'Diagnose local infrastructure'
        ELSE NULL
    END AS Improvement
FROM
    water_source
LEFT JOIN
    well_pollution ON water_source.source_id = well_pollution.source_id
INNER JOIN
    visits ON water_source.source_id = visits.source_id
INNER JOIN
    location ON location.location_id = visits.location_id
WHERE
    visits.visit_count = 1 
    AND (well_pollution.results != 'Clean'
    OR water_source.type_of_water_source IN ('tap_in_home_broken', 'river')
    OR (water_source.type_of_water_source = 'shared_tap' AND visits.time_in_queue >= 30));

-- inserting our info into Project_progress
INSERT INTO Project_progress (
    source_id,
    Address,
    Town,
    Province,
    Source_type,
    Improvement
)
SELECT
    water_source.source_id,
    location.address,
    location.town_name,
    location.province_name,
    water_source.type_of_water_source,
    CASE
        WHEN well_pollution.results = 'Contaminated: Chemical'
        THEN 'Install RO filter' 
        WHEN well_pollution.results = 'Contaminated: Biological'
        THEN 'Install UV filter'
        WHEN water_source.type_of_water_source = 'river'
        THEN 'Drill well'
        WHEN water_source.type_of_water_source = 'shared_tap'
             AND visits.time_in_queue >= 30
        THEN CONCAT('Install ', FLOOR(visits.time_in_queue / 30), ' taps nearby')
        WHEN water_source.type_of_water_source = 'tap_in_home_broken' 
        THEN 'Diagnose local infrastructure'
        ELSE NULL
    END AS Improvement
FROM
    water_source
LEFT JOIN
    well_pollution ON water_source.source_id = well_pollution.source_id
INNER JOIN
    visits ON water_source.source_id = visits.source_id
INNER JOIN
    location ON location.location_id = visits.location_id
WHERE
    visits.visit_count = 1 
    AND (well_pollution.results != 'Clean'
    OR water_source.type_of_water_source IN ('tap_in_home_broken', 'river')
    OR (water_source.type_of_water_source = 'shared_tap' AND visits.time_in_queue >= 30));
    
SELECT * FROM Project_progress
LIMIT 500;