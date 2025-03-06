DROP TABLE IF EXISTS `auditor_report`;
CREATE TABLE `auditor_report` (
`location_id` VARCHAR(32),
`type_of_water_source` VARCHAR(64),
`true_water_source_score` int DEFAULT NULL,
`statements` VARCHAR(255)
);

SELECT
	*
FROM 
	auditor_report;
 
 /* we will have to compare the quality scores in the 
 water_quality table to the auditor's scores.*/
 
SELECT 
	location_id,
    true_water_source_score
FROM 
	auditor_report;
    
/* Now, we join the visits table to the auditor_report table. 
Make sure to grab subjective_quality_score, record_id and location_id. */

SELECT
auditor_report.location_id AS audit_location,
auditor_report.true_water_source_score AS auditor_score,
visits.record_id,
water_quality.subjective_quality_score AS surveyor_score
FROM
auditor_report
JOIN
	visits
ON auditor_report.location_id = visits.location_id
JOIN 
	water_quality
ON
	visits.record_id = water_quality.record_id
WHERE 
	auditor_report.true_water_source_score != water_quality.subjective_quality_score
AND 
	visits.visit_count = 1;
    
/* grab the type_of_water_source column from the water_source table and call it survey_source,
 using the source_id column to JOIN.
 Also select the type_of_water_source from the auditor_report table, and call it auditor_source. */
 
 SELECT
auditor_report.location_id AS audit_location,
auditor_report.true_water_source_score AS auditor_score,
visits.record_id,
water_quality.subjective_quality_score AS surveyor_score,
auditor_report.type_of_water_source AS auditor_source,
water_source.type_of_water_source AS survey_source
FROM
auditor_report
JOIN
	visits
ON auditor_report.location_id = visits.location_id
JOIN 
	water_quality
ON
	visits.record_id = water_quality.record_id
JOIN 
	water_source
ON
	water_source.source_id = visits.source_id
WHERE 
	auditor_report.true_water_source_score != water_quality.subjective_quality_score
AND 
	visits.visit_count = 1;
    
/* so let's JOIN the assigned_employee_id for all the people on our list from the visits
table to our query. */

 SELECT
auditor_report.location_id AS audit_location,
auditor_report.true_water_source_score AS auditor_score,
visits.record_id,
water_quality.subjective_quality_score AS surveyor_score,
auditor_report.type_of_water_source AS auditor_source,
water_source.type_of_water_source AS survey_source,
visits.assigned_employee_id
FROM
auditor_report
JOIN
	visits
ON auditor_report.location_id = visits.location_id
JOIN 
	water_quality
ON
	visits.record_id = water_quality.record_id
JOIN 
	water_source
ON
	water_source.source_id = visits.source_id
WHERE 
	auditor_report.true_water_source_score != water_quality.subjective_quality_score
AND 
	visits.visit_count = 1;
    
/* The ID's don't help us to identify them. We have employees' names
stored along with their IDs, so let's fetch their names from the employees table instead of the ID's. */
    
 SELECT
auditor_report.location_id AS audit_location,
auditor_report.true_water_source_score AS auditor_score,
visits.record_id,
water_quality.subjective_quality_score AS surveyor_score,
visits.assigned_employee_id,
employee.employee_name
FROM
auditor_report
JOIN
	visits
ON auditor_report.location_id = visits.location_id
JOIN 
	water_quality
ON
	visits.record_id = water_quality.record_id
JOIN 
	employee
ON
	employee.assigned_employee_id = visits.assigned_employee_id
WHERE 
	auditor_report.true_water_source_score != water_quality.subjective_quality_score
AND 
	visits.visit_count = 1;

/* maybe it is a good idea to save this as a CTE, so when we do more analysis, we can just call that CTE
like it was a table. Call it something like Incorrect_records. */

WITH Incorrect_records AS (
							SELECT
							auditor_report.location_id AS audit_location,
							auditor_report.true_water_source_score AS auditor_score,
							visits.record_id,
							water_quality.subjective_quality_score AS surveyor_score,
							visits.assigned_employee_id,
							employee.employee_name
							FROM
							auditor_report
							JOIN
								visits
							ON auditor_report.location_id = visits.location_id
							JOIN 
								water_quality
							ON
								visits.record_id = water_quality.record_id
							JOIN 
								employee
							ON
								employee.assigned_employee_id = visits.assigned_employee_id
							WHERE 
								auditor_report.true_water_source_score != water_quality.subjective_quality_score
							AND 
								visits.visit_count = 1
)
-- Now you can use the CTE for further analysis
SELECT *
FROM incorrect_records;


-- a unique list of employees from this table.

WITH Incorrect_records AS (
							SELECT
							auditor_report.location_id AS audit_location,
							auditor_report.true_water_source_score AS auditor_score,
							visits.record_id,
							water_quality.subjective_quality_score AS surveyor_score,
							visits.assigned_employee_id,
							employee.employee_name
							FROM
							auditor_report
							JOIN
								visits
							ON auditor_report.location_id = visits.location_id
							JOIN 
								water_quality
							ON
								visits.record_id = water_quality.record_id
							JOIN 
								employee
							ON
								employee.assigned_employee_id = visits.assigned_employee_id
							WHERE 
								auditor_report.true_water_source_score != water_quality.subjective_quality_score
							AND 
								visits.visit_count = 1
)
SELECT distinct
	employee_name
FROM
	incorrect_records;
    
/* Next, let's try to calculate how many mistakes each employee made. So basically we want to count how many times their name is in
Incorrect_records list, and then group them by name */

WITH Incorrect_records AS (
							SELECT
							auditor_report.location_id AS audit_location,
							auditor_report.true_water_source_score AS auditor_score,
							visits.record_id,
							water_quality.subjective_quality_score AS surveyor_score,
							visits.assigned_employee_id,
							employee.employee_name
							FROM
							auditor_report
							JOIN
								visits
							ON auditor_report.location_id = visits.location_id
							JOIN 
								water_quality
							ON
								visits.record_id = water_quality.record_id
							JOIN 
								employee
							ON
								employee.assigned_employee_id = visits.assigned_employee_id
							WHERE 
								auditor_report.true_water_source_score != water_quality.subjective_quality_score
							AND 
								visits.visit_count = 1
)
SELECT 
	employee_name,
    COUNT(*) AS number_of_mistakes
FROM incorrect_records
GROUP BY employee_name
ORDER BY number_of_mistakes DESC;

-- to find all of the employees who have an above-average number of mistakes.
/* 1. We have to first calculate the number of times someone's name comes up. (we just did that in the previous query). Let's call it error_count. */

WITH error_count AS (
	WITH incorrect_records AS (
							SELECT
							auditor_report.location_id AS audit_location,
							auditor_report.true_water_source_score AS auditor_score,
							visits.record_id,
							water_quality.subjective_quality_score AS surveyor_score,
							visits.assigned_employee_id,
							employee.employee_name
							FROM
							auditor_report
							JOIN
								visits
							ON auditor_report.location_id = visits.location_id
							JOIN 
								water_quality
							ON
								visits.record_id = water_quality.record_id
							JOIN 
								employee
							ON
								employee.assigned_employee_id = visits.assigned_employee_id
							WHERE 
								auditor_report.true_water_source_score != water_quality.subjective_quality_score
							AND 
								visits.visit_count = 1
)
SELECT 
	employee_name,
    COUNT(*) AS number_of_mistakes
FROM incorrect_records
GROUP BY employee_name
ORDER BY number_of_mistakes DESC
)
SELECT employee_name,
		number_of_mistakes
FROM error_count;

/* 2. Then, we need to calculate the average number of mistakes employees made. We can do that by taking the average of the previous query's
results. */
WITH error_count AS (
	WITH incorrect_records AS (
							SELECT
							auditor_report.location_id AS audit_location,
							auditor_report.true_water_source_score AS auditor_score,
							visits.record_id,
							water_quality.subjective_quality_score AS surveyor_score,
							visits.assigned_employee_id,
							employee.employee_name
							FROM
							auditor_report
							JOIN
								visits
							ON auditor_report.location_id = visits.location_id
							JOIN 
								water_quality
							ON
								visits.record_id = water_quality.record_id
							JOIN 
								employee
							ON
								employee.assigned_employee_id = visits.assigned_employee_id
							WHERE 
								auditor_report.true_water_source_score != water_quality.subjective_quality_score
							AND 
								visits.visit_count = 1
)
SELECT 
	employee_name,
    COUNT(*) AS number_of_mistakes
FROM incorrect_records
GROUP BY employee_name
ORDER BY number_of_mistakes DESC
)
SELECT 
AVG(number_of_mistakes)
FROM error_count;

/* Finaly we have to compare each employee's error_count with avg_error_count_per_empl. */

WITH error_count AS (
	WITH incorrect_records AS (
							SELECT
							auditor_report.location_id AS audit_location,
							auditor_report.true_water_source_score AS auditor_score,
							visits.record_id,
							water_quality.subjective_quality_score AS surveyor_score,
							visits.assigned_employee_id,
							employee.employee_name
							FROM
							auditor_report
							JOIN
								visits
							ON auditor_report.location_id = visits.location_id
							JOIN 
								water_quality
							ON
								visits.record_id = water_quality.record_id
							JOIN 
								employee
							ON
								employee.assigned_employee_id = visits.assigned_employee_id
							WHERE 
								auditor_report.true_water_source_score != water_quality.subjective_quality_score
							AND 
								visits.visit_count = 1
)
SELECT 
	employee_name,
    COUNT(*) AS number_of_mistakes
FROM incorrect_records
GROUP BY employee_name
ORDER BY number_of_mistakes DESC
)
SELECT 
	employee_name,
    number_of_mistakes
FROM error_count
WHERE number_of_mistakes > (SELECT
								AVG(number_of_mistakes)
								FROM error_count);
                                
                                
/* Let's start by cleaning up our code a bit. First, Incorrect_records is a result we'll be using for the rest of the analysis, but it makes the
query a bit less readable. So, let's convert it to a VIEW. We can then use it as if it was a table. It will make our code much simpler to read, but, it
comes at a cost. We can add comments to CTEs in our code, so if we return to that query a year later, we can read those comments and quickly
understand what Incorrect_records represents. If we save it as a VIEW, it is not as obvious. So we should add comments in places where we
use Incorrect_records. */

CREATE VIEW incorrect_records AS (
							SELECT
							auditor_report.location_id AS audit_location,
							auditor_report.true_water_source_score AS auditor_score,
							visits.record_id,
							water_quality.subjective_quality_score AS surveyor_score,
							visits.assigned_employee_id,
							employee.employee_name
							FROM
							auditor_report
							JOIN
								visits
							ON auditor_report.location_id = visits.location_id
							JOIN 
								water_quality
							ON
								visits.record_id = water_quality.record_id
							JOIN 
								employee
							ON
								employee.assigned_employee_id = visits.assigned_employee_id
							WHERE 
								auditor_report.true_water_source_score != water_quality.subjective_quality_score
							AND 
								visits.visit_count = 1
);

-- Next, we convert the query error_count, we made earlier, into a CTE.

WITH error_count AS ( -- This CTE calculates the number of mistakes each employee made
SELECT
employee_name,
COUNT(employee_name) AS number_of_mistakes
FROM
Incorrect_records
/*Incorrect_records is a view that joins the audit report to the database
for records where the auditor and
	employees scores are different*/

GROUP BY
employee_name)
-- Query
SELECT * FROM error_count;

-- Now calculate the average of the number_of_mistakes in error_count.
WITH error_count AS ( 
						SELECT
						employee_name,
						COUNT(employee_name) AS number_of_mistakes
						FROM
						Incorrect_records
						GROUP BY
						employee_name)
SELECT 
AVG(number_of_mistakes)
FROM error_count;


/* To find the employees who made more mistakes than the average person, we need the employee's names,
 the number of mistakes each one made, and filter the employees with an above-average number of mistakes. */

WITH error_count AS (
    SELECT 
	employee_name,
    COUNT(*) AS number_of_mistakes
FROM incorrect_records
GROUP BY employee_name
ORDER BY number_of_mistakes DESC
)
SELECT 
	employee_name,
    number_of_mistakes
FROM error_count
WHERE number_of_mistakes > (SELECT AVG(number_of_mistakes) FROM error_count);

/* look at the Incorrect_records table again, and isolate all of the records these four employees gathered.
 We should also look at the statements for these records to look for patterns. */

-- First, convert the suspect_list to a CTE, so we can use it to filter the records from these four employees.
 WITH suspect_list AS (
		 WITH error_count AS (
			SELECT 
			employee_name,
			COUNT(*) AS number_of_mistakes
		FROM incorrect_records
		GROUP BY employee_name
		ORDER BY number_of_mistakes DESC
)
SELECT 
	employee_name,
    number_of_mistakes
FROM error_count
WHERE number_of_mistakes > (SELECT AVG(number_of_mistakes) FROM error_count)
)
SELECT * FROM suspect_list;

-- Firstly, let's add the statements column to the Incorrect_records view.
DROP VIEW incorrect_records;
CREATE VIEW incorrect_records AS (
							SELECT
							auditor_report.location_id AS audit_location,
							auditor_report.true_water_source_score AS auditor_score,
							visits.record_id,
							water_quality.subjective_quality_score AS surveyor_score,
							visits.assigned_employee_id,
							employee.employee_name,
                            auditor_report.statements
							FROM
							auditor_report
							JOIN
								visits
							ON auditor_report.location_id = visits.location_id
							JOIN 
								water_quality
							ON
								visits.record_id = water_quality.record_id
							JOIN 
								employee
							ON
								employee.assigned_employee_id = visits.assigned_employee_id
							WHERE 
								auditor_report.true_water_source_score != water_quality.subjective_quality_score
							AND 
								visits.visit_count = 1
);

WITH error_count AS ( -- This CTE calculates the number of mistakes each employee made
SELECT
employee_name,
COUNT(employee_name) AS number_of_mistakes
FROM
Incorrect_records
/*
Incorrect_records is a view that joins the audit report to the database
for records where the auditor and
employees scores are different */

GROUP BY
employee_name),
suspect_list AS (-- This CTE SELECTS the employees with above−average mistakes
SELECT
employee_name,
number_of_mistakes
FROM
error_count
WHERE
number_of_mistakes > (SELECT AVG(number_of_mistakes) FROM error_count))
-- This query filters all of the records where the "corrupt" employees gathered data.
SELECT
employee_name,
audit_location,
statements
FROM
Incorrect_records
WHERE
employee_name in (SELECT employee_name FROM suspect_list)
AND statements LIKE '%cash%';
    
/* Check if there are any employees in the Incorrect_records table with statements mentioning "cash" 
that are not in our suspect list. */

WITH error_count AS ( -- This CTE calculates the number of mistakes each employee made
SELECT
employee_name,
COUNT(employee_name) AS number_of_mistakes
FROM
Incorrect_records
/*
Incorrect_records is a view that joins the audit report to the database
for records where the auditor and
employees scores are different */

GROUP BY
employee_name),
suspect_list AS (-- This CTE SELECTS the employees with above−average mistakes
SELECT
employee_name,
number_of_mistakes
FROM
error_count
WHERE
number_of_mistakes > (SELECT AVG(number_of_mistakes) FROM error_count))
-- This query filters all of the records where the "corrupt" employees gathered data.
SELECT
employee_name,
audit_location,
statements
FROM
Incorrect_records
WHERE
employee_name IN (SELECT employee_name FROM suspect_list)
AND statements LIKE '%cash%';