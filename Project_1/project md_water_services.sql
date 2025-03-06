SHOW TABLES;

SELECT
	*
FROM
	md_water_services.location
LIMIT 5;

SELECT
	*
FROM
	md_water_services.visits
LIMIT 5;

SELECT
	*
FROM
	md_water_services.water_source
LIMIT 5;

SELECT DISTINCT
	type_of_water_source
FROM
	md_water_services.water_source;
    
SELECT
	*
FROM
	md_water_services.visits
WHERE 
	time_in_queue >500;
    
SELECT 
	*
FROM 
	md_water_services.water_source
WHERE	
	source_id 
IN(
    'Akki00881224',
	'SoRu37635224',
	'SoRu35083',
	'SoKo33124',
	'KiRu26095',
	'SoRu36096224'
);

SELECT
	*
FROM
	md_water_services.water_quality
LIMIT 5;

SELECT
	*
FROM
	md_water_services.water_quality
WHERE
	subjective_quality_score = 10 
AND	
	visit_count = 2;
    
SELECT
	*
FROM
	md_water_services.well_pollution
LIMIT 5;

SELECT
	*
FROM
	md_water_services.well_pollution
WHERE 
	results = 'Clean'
AND
	biological > 0.01;
    
SELECT
	*
FROM
	md_water_services.well_pollution
WHERE 
	results = 'Clean'
AND
	description LIKE 'clean%'
AND 	
	biological > 0.01;
    
CREATE TABLE 
	md_water_services.well_pollution_copy
AS(
SELECT 
    *
FROM
	md_water_services.well_pollution
);

-- This query is to make sure the copy_table was created.
SELECT
	* 
FROM
	md_water_services.well_pollution_copy
WHERE 
	description LIKE 'clean%';
    
SELECT
	* 
FROM
	md_water_services.well_pollution
WHERE 
	description LIKE 'clean%';

-- to filter out the description with clean%
SELECT
	* 
FROM
	md_water_services.well_pollution_copy
WHERE 
	description LIKE 'clean bacteria%';
    

UPDATE
well_pollution_copy
SET
description = 'Bacteria: E.coli'

WHERE
description = 'Clean Bacteria: E. coli';

UPDATE
well_pollution_copy
SET
description = 'Bacteria: Giardia Lamblia'

WHERE
description = 'Clean Bacteria: Giardia Lamblia';

UPDATE
well_pollution_copy
SET
results = 'Contaminated: Biological'

WHERE
biological > 0.01 AND results = 'Clean';

-- This is being run to give evidence if the changes applied above didn't take effect
SELECT
	* 
FROM
	md_water_services.well_pollution_copy
WHERE 
	description LIKE 'clean bacteria%';
    
    
    UPDATE
well_pollution
SET
description = 'Bacteria: E.coli'

WHERE
description = 'Clean Bacteria: E. coli';

UPDATE
well_pollution
SET
description = 'Bacteria: Giardia Lamblia'

WHERE
description = 'Clean Bacteria: Giardia Lamblia';

UPDATE
well_pollution
SET
results = 'Contaminated: Biological'

WHERE
biological > 0.01 AND results = 'Clean';

DROP TABLE
md_water_services.well_pollution_copy;

SELECT
	* 
FROM
	md_water_services.well_pollution
WHERE 
	description LIKE 'clean bacteria%';
    
SELECT *
FROM well_pollution
WHERE description LIKE 'Clean_%' OR results = 'Clean' AND biological < 0.01;

UPDATE employee
SET phone_number = '+99643864786'
WHERE employee_name = 'Bello Azibo';


SELECT * 
FROM well_pollution
WHERE description
IN ('Parasite: Cryptosporidium', 'biologically contaminated')
OR (results = 'Clean' AND biological > 0.01);

