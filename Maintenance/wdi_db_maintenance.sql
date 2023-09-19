/*
ISDS 555 - Business Database Design
Module 02 - Creating and Populating Tables

==================================================================================
NOTE: Never use the posgres database to import or create tables (or other objects)
      ALWAYS create a new database before importing or creating tables 
==================================================================================

NOTE: If you accidentally change the layout of the interface use File->Reset Layout
	  You can prevent layout mishaps by choosing File->Lock Layout->Full Lock
*/


-- Continue only if you have created electricitygeneration database and this editor is connected to it

-- You will find this code and data files in the course DropBox folder

-- First, let's spend some time exploring the raw data file: generation_monthly.csv 
-- (prepared by me based on: https://www.eia.gov/electricity/data/state/)

-- The following are the attributes: 
-- year (integer)
-- month (integer)
-- state (string no longer than 10 characters)
-- type_of_producer (string no longer than 50 characters)
-- energy_source (string no longer than 50 characters)
-- generation_mwhrs (real number)
-- PK: the first five columns

-- We will be using CREATE TABLE (scroll down to examples at https://www.postgresql.org/docs/current/sql-createtable.html)
-- To learn more about PostgreSQL data types: https://www.postgresql.org/docs/current/datatype.html

-- NOTE if you name a table "MonthlyGeneration" you will have to use double quotes while referring to it.
CREATE TABLE public.generation
(
    year integer NOT NULL,
    month integer NOT NULL,
    state character varying(10) NOT NULL,
    type_of_producer character varying(50)  NOT NULL,
    energy_source character varying(50) NOT NULL,
    generation_mwhrs int, -- this is intentional (we will change it later)
	CONSTRAINT GenerationMonthly_year_con CHECK (year>=1900),
	CONSTRAINT GenerationMonthly_month_con CHECK (month>=1 AND month<=12),
    CONSTRAINT "GenerationMonthly_pkey" PRIMARY KEY (year, month, state, type_of_producer, energy_source)
) TABLESPACE pg_default;

-- ALTER TABLE allows changing the existing table without the need of dropping it first
-- https://www.postgresql.org/docs/current/sql-altertable.html

ALTER TABLE public.generation
	ALTER COLUMN generation_mwhrs TYPE real; -- better use: double precision

COMMENT ON TABLE public.generation IS 'Monthly U.S. electricity generation by state by source type downloaded from https://www.eia.gov/electricity/data/state/';

-- DROP TABLE public.generation; -- Commented to prevent accidental execution
-- https://www.postgresql.org/docs/current/sql-droptable.html

-- Now, let's import data from generation_monthly.csv using the import tool
-- NOTE: the import tool will only work to a certain file size, if it fails use the SQL Shell (psql)

-- NOTE: If you need to redo the import (delete all rows and restart) use TRUNCATE TABLE public.generation 

-- Check how many rows we have:
SELECT COUNT(*) FROM public.generation;

-- View the first 10 rows
SELECT * FROM generation LIMIT 10;

-- Updating your table
-- [D]elete, [U]pdate, [I]nsert

-- Before we begin, lets quickly review the basic Boolean operators
-- True, False (e.g. state='CA', generation_mwhrs<0)
-- NOT: flips the value, e.g.: NOT True -> False
-- AND: returns True if both values are True, e.g.: True AND True -> True; False AND True -> False
-- OR: returns True if one of the values is True, e.g.: True OR False -> True; False OR False -> False
-- Use parentheses to ensure precendence for complex statements


-- DELETE FROM (https://www.postgresql.org/docs/current/sql-delete.html)
-- Let's analyze the monthly_generation_delete.csv file.
-- Let's use Excel to generate the DELETE FROM generation WHERE ... statements

-- UPDATE (https://www.postgresql.org/docs/current/sql-update.html)
-- Let's analyze the monthly_generation_update.csv file.
-- Let's use Excel to generate the UPDATE generation SET ... WHERE ... statements

-- INSERT (https://www.postgresql.org/docs/current/sql-insert.html)
-- Let's analyze the monthly_generation_insert.csv file.
-- Let's use Excel to generate the INSERT INTO generation VALUES(...) statements

-- In this module you have learned to
-- - create a PostgreSQL database (DDL)
-- - create a table and enforce the entity integrity constraints (DDL)
-- - import data from a csv file
-- - delete, update, and insert data (DML)

-- =============================================================================================

-- It is your turn now. 
-- Please complete the analogous set of steps for the US national and state-level employment and unemployment statistics, published by the Bureau of Labor Statistics.
-- Database Name: employment
-- Main file: blse.csv
-- Table Name (in the default space): blse
-- Special constraints: employment_1000s>=0
-- Files to process: blse_delete.csv, blse_update.csv, blse_insert.csv
-- HINT: Dates in Excel/CSV should be wrapped in TEXT([date_cell],"YYYY-MM-DD"), e.g. TEXT(A2,"YYYY-MM-DD")

-- Checks to perform after all delete, update, and insert operations are completed 
SELECT COUNT(*) FROM blse; -- 85920
SELECT COUNT(*) FROM blse WHERE employment_1000s=0; -- 0
SELECT round(AVG(employment_1000s)*100)/100 FROM blse WHERE date BETWEEN '2019-01-01' AND '2019-12-31'; -- 987.29
SELECT COUNT(*) FROM blse WHERE date>='2020-01-1'; -- 2964


/*
ISDS 555 - Business Database Design
Module 03 - Querying, Manipulating and Filtering Tables

==================================================================================
NOTE: Never use the postgres database to import or create tables (or other objects)
      ALWAYS create a new database before importing or creating tables 
==================================================================================

NOTE: You will need the complete generation table from Module 2. If you would like to start 
	  with a clean database, please delete the electricitygeneration database, create it from scratch
	  and restore it from the backup file provided.

*/

-- Continue only if you are in the electricitygeneration database and this editor is connected to it

-- You will find this code and data files in the course DropBox folder

-- First let's take a look at the SELECT statement https://www.postgresql.org/docs/current/sql-select.html

-- The simplest select (no table)
SELECT 2+2;
SELECT now();

-- Add the name
SELECT 2+2 AS val1,3+3 AS val2;
SELECT 2+2 val1, 3+3 val2; -- 'AS' can be omited

-- Extract date/time components https://www.postgresql.org/docs/current/functions-datetime.html
SELECT EXTRACT(YEAR FROM now()) y,EXTRACT(MONTH FROM now()) m, EXTRACT(DAY FROM now()) d,
EXTRACT(HOUR FROM now()) hh,EXTRACT(MINUTE FROM now()) mm,EXTRACT(SECOND FROM now()) ss ;

-- Random numbers
SELECT random() as rnd;

---------------------------------------------------------
-- Now, let's use a table to do quyering and manipulation
---------------------------------------------------------

SELECT * FROM generation LIMIT 10; -- * here means 'all columns'

SELECT COUNT(*) FROM generation; -- * here means 'all rows'

-- Subset, reorder and rename columns; rename table
SELECT gen.type_of_producer producer, 
	gen.energy_source source, 
	gen.state, gen.year, 
	gen.month,  
	gen.generation_mwhrs mwhrs 
FROM generation gen LIMIT 10;

-- DISTINCT
SELECT DISTINCT energy_source FROM generation;

SELECT DISTINCT energy_source, state FROM generation; -- all distinct combinations of values
SELECT DISTINCT ON (energy_source) energy_source, state FROM generation; -- just the first row

-- Ordering
SELECT DISTINCT state FROM generation ORDER BY state; -- ASC is default
SELECT DISTINCT month FROM generation ORDER BY month DESC;
SELECT DISTINCT year,month  FROM generation ORDER BY year,month; -- first by year THEN by month

-- Statistics
SELECT MIN(generation_mwhrs) min_gen,AVG(generation_mwhrs) avg_gen,MAX(generation_mwhrs) max_gen FROM generation;

-- Concatenate text
SELECT DISTINCT 'State of ' || state as descr FROM generation ORDER BY descr; 

-- Change type
SELECT DISTINCT year::varchar as y, month::varchar as m FROM generation order by y,m; -- now sorted as text!

-- Conditional statement on columns
SELECT DISTINCT month, 
	CASE WHEN month<10 THEN '0' || month::varchar ELSE month::varchar END AS m 
FROM generation ORDER BY m;

SELECT DISTINCT year, 
	CASE WHEN month<=3 THEN 'Qtr1' WHEN month<=6 THEN 'Qtr2' WHEN month<=9 THEN 'Qtr3' ELSE 'Qtr4' END q
FROM generation ORDER BY year,q;

-- Selecting into a new table
SELECT DISTINCT year, 
	CASE WHEN month<=3 THEN 'Qtr1' WHEN month<=6 THEN 'Qtr2' WHEN month<=9 THEN 'Qtr3' ELSE 'Qtr4' END q
INTO quarters -- new table created and populated
FROM generation ORDER BY year,q;

-- Check it and drop it
SELECT * FROM quarters LIMIT 10;
DROP TABLE quarters;

----------------------------------------------------
-- Now, let's do some filtering using the same table
----------------------------------------------------

-- Simple use of WHERE (=,<,>,<=,>=,<>,!=)
SELECT * FROM generation WHERE year=2020;
SELECT * FROM generation WHERE generation_mwhrs<0;

-- IMPORTANT: WHERE conditions are executed before the selection of column is made, ordering is last

-- Logical operators (AND, OR, NOT) and WHERE
SELECT * FROM generation 
WHERE year=2020 AND (month=1 OR month=2) AND state='CA' AND energy_source='Coal';

SELECT * FROM generation 
WHERE year=2020 AND month<=2 AND state='CA' AND energy_source='Wind'
AND type_of_producer<>'Total Electric Power Industry'
AND NOT ( 
 type_of_producer='Combined Heat and Power, Commercial Power'
 OR type_of_producer='Combined Heat and Power, Industrial Power'
 );

-- IN
SELECT * FROM generation 
WHERE year=2020 AND month IN (1,3,5) AND state='CA' 
AND type_of_producer='Total Electric Power Industry'
AND energy_source IN ('Natural Gas','Coal')
ORDER BY month;

-- BETWEEN
SELECT * FROM generation
WHERE state='CA'  AND type_of_producer='Total Electric Power Industry'
AND energy_source IN ('Natural Gas','Coal')
AND year=2020 AND month BETWEEN 1 AND 3;

-- Filtering strings using LIKE with % and _
-- Note: PostreSQL has ILIKE operator which is case-insensitive
SELECT DISTINCT state FROM generation ORDER BY state; -- all values
SELECT DISTINCT state FROM generation WHERE state!='DC' AND state NOT LIKE 'US%' ORDER BY state; -- just the states

SELECT DISTINCT energy_source FROM generation WHERE energy_source LIKE '%Gas%';

SELECT DISTINCT state FROM generation WHERE state!='DC' AND state NOT LIKE 'US%' 
AND state LIKE 'C_'
ORDER BY state; -- just the states beginning with a 'C'

------------------------------------------------------------------------
-- Now, let's ask some business questions and let's answer them with SQL
------------------------------------------------------------------------

-- Q1. What was the total amount of electricity in GWHrs (1000s of MWHrs) generated in California 
--- from all sources in each month of 2019?

SELECT DISTINCT type_of_producer FROM generation; -- list of types of producers to copy from
SELECT DISTINCT energy_source FROM generation; -- list of sources to copy from

SELECT state,year,month,generation_mwhrs/1000 total_gen_gwhrs FROM generation 
WHERE year=2019 AND state='CA' AND type_of_producer='Total Electric Power Industry' AND energy_source='Total'
ORDER BY month;
-- Note: you can export the results to a csv file

-- Q2. Which of the U.S. states/territories generated electricity from wind or sun in 2020?
SELECT DISTINCT energy_source FROM generation; -- list of sources to copy from

SELECT DISTINCT state FROM generation 
WHERE year=2020 AND energy_source IN ('Wind','Solar Thermal and Photovoltaic')
AND generation_mwhrs>0 AND state NOT LIKE 'US%'
ORDER BY state;

-- Q3. What is the average monthly amount of electricity (in GWHrs) generated from the Sun in California
-- between 2018 and 2019 by all producers?
SELECT AVG(generation_mwhrs)/1000 avg_gen_gwhrs FROM generation 
WHERE state='CA' AND year BETWEEN 2018 AND 2019 AND energy_source='Solar Thermal and Photovoltaic'
AND type_of_producer='Total Electric Power Industry';

-- Q4. What were the top 10 states/territories in terms of the total electricity generation 
--- from all sources in May 2020?
SELECT year,month,state, generation_mwhrs/1000 total_gen_gwhrs FROM generation 
WHERE state NOT LIKE 'US%' AND energy_source='Total' AND type_of_producer='Total Electric Power Industry'
AND year=2020 AND month=5
ORDER BY generation_mwhrs DESC LIMIT 10;

-- In this module you have learned to
-- - Query data tables with SQL
-- - Manipulate data tables with SQL
-- - Filter data tables with SQL

-- =============================================================================================

-- It is your turn now. 
-- Please switch to the employment database and the blse table which you created in Module 2.
-- Note: I am assuming that you processed the deletes, updates,  and insertions.
-- Please answer the following business questions with SQL queries:
-- Q1: What was the average employment (in millions) in California in government between 2017 and 2019?
-- Check: The result is a number between 2.5 and 2.6

-- Q2: What were the top 5 industries in terms of employment in California on '2020-06-30' (exclude totals)?
-- Check: The first is Service-Providing and the last is Durable Goods 

-- Q3: How many employees total (in millions) were employed in mining and logging in the U.S. at the end of 2019?
-- Check: The result is a number between 0.6 and 0.7 

-- Q4: What was the employment (in millions) in manufacturing in Texas in each month of 2019?
-- Check: There are 12 rows in the result. The employment in millions for 2019-01-31 is approx. 0.9005, and for 2019-12-31, it is approx. 0.9101


/*
ISDS 555 - Business Database Design
Module 04 - Grouping and Set Operations

==================================================================================
NOTE: Never use the postgres database to import or create tables (or other objects)
      ALWAYS create a new database before importing or creating tables 
==================================================================================

NOTE: You will need the complete generation table from Module 2. If you would like to start 
	  with a clean database, please delete the electricitygeneration database, create it from scratch
	  and restore it from the backup file provided.

*/

-- Continue only if you are in the electricitygeneration database and this editor is connected to it

-- You will find this code and data files in the course DropBox folder

-- First let's take another a look at the SELECT statement https://www.postgresql.org/docs/current/sql-select.html

----------------------------------------------
-- First, lets learn about GROUP BY and HAVING
----------------------------------------------

-- GROUP BY clause groups the results by the specified grouping sets 

-- grouping by the empty set (GROUP BY clause is ommitted) - we have already done that
SELECT COUNT(*) FROM generation;

-- grouping by a single column
SELECT year, COUNT(*) AS record_count FROM generation GROUP BY year;
-- NOTE: must list columns used in GROUP BY after SELECT, you may add the aggregation (e.g. counting)

-- grouping by multiple columns
SELECT year,month, COUNT(*) as record_count FROM generation GROUP BY year,month;

-- combine with other clauses
SELECT energy_source, SUM(generation_mwhrs)/1000000 gen_twhrs
FROM generation
WHERE type_of_producer='Total Electric Power Industry' AND energy_source!='Total' AND state='CA' AND year=2019
GROUP BY energy_source
ORDER BY gen_twhrs DESC;

-- Check totals
SELECT state, SUM(generation_mwhrs)/1000000 gen_twhrs, COUNT(*) as record_count
FROM generation
WHERE type_of_producer='Total Electric Power Industry' AND energy_source!='Total' AND year=2019 AND state NOT LIKE 'US%'
GROUP BY state
ORDER BY state;

SELECT state, SUM(generation_mwhrs)/1000000 gen_twhrs, COUNT(*) as record_count
FROM generation
WHERE type_of_producer='Total Electric Power Industry' AND energy_source='Total' AND year=2019 AND state NOT LIKE 'US%'
GROUP BY state
ORDER BY state;

-- Check Totals for the U.S. by year
SELECT year, SUM(generation_mwhrs)/1000000 gen_twhrs, COUNT(*) AS record_count
FROM generation
WHERE type_of_producer='Total Electric Power Industry' AND energy_source!='Total' AND state NOT LIKE 'US%'
GROUP BY year
ORDER BY year;

-- Use Excel to compare with:
SELECT year,SUM(generation_mwhrs)/1000000 gen_twhrs, COUNT(*) as record_count
FROM generation
WHERE type_of_producer='Total Electric Power Industry' AND energy_source='Total' AND state LIKE 'US%'
GROUP BY year
ORDER BY year;

-- Now that we know how to calculate totals for any group, let's remove the ALL totals from our database
-- This way our database will contain only detailed monthly data without any totals or subtotals
SELECT DISTINCT state FROM generation ORDER BY state;
SELECT DISTINCT type_of_producer FROM generation;
SELECT DISTINCT energy_source FROM generation;

-- How many records will be deleted?
SELECT COUNT(*)
FROM generation
WHERE state LIKE 'US%' OR type_of_producer='Total Electric Power Industry' OR energy_source='Total';

-- Let's delete them
DELETE FROM generation WHERE state LIKE 'US%' OR type_of_producer='Total Electric Power Industry' OR energy_source='Total';
-- Now we will not have to worry about filtering out totals anymore

-- Let's discuss constraining grouped query results (HAVING) which acts like a WHERE clause but on aggregates
SELECT state,SUM(generation_mwhrs)/1000000 as gen_twhrs 
FROM generation
WHERE energy_source='Wind' AND year=2019
GROUP BY state
HAVING SUM(generation_mwhrs)/1000000>=1.0 -- at least 1TWHr produced
ORDER BY gen_twhrs DESC;
-- NOTE: Use HAVING only on aggregates which you can't restrict using WHERE; 
-- using HAVING for all filtering slows down your query

-- THE FULL EXECUTION ORDER
-- FROM -> WHERE -> GROUP BY -> HAVING -> SELECT -> DISTINCT -> ORDER BY -> LIMIT

-------------------------------------------
-- Now, let's take a look at set operations
-------------------------------------------

-- First, a quick refresher from the set theory:
-- S1={A,B,C,D}, S2={C,D,E,F}, S3={C,D}
-- UNION(S1,S2)= {A,B,C,D,E,F}
-- UNION(S1,S2,S3) = {A,B,C,D,E,F}
-- INTERSECTION(S1,S2,S3) = {C,D}
-- SETDIFFERENCE(S1,S2) = {A,B}
-- SETDIFFERENCE(S2,S1) = {E,F}
-- INTERSECTION(SETDIFFERENCE(S1,S2),S3)={}

-- In PostgreSQL we have UNION, INTERSECT, and EXCEPT operators which work on the results of the SELECT statement

-- UNION
SELECT DISTINCT energy_source FROM generation WHERE state='CA' AND year=2001;
SELECT DISTINCT energy_source FROM generation WHERE state='TX' AND year=2001;

SELECT DISTINCT energy_source FROM generation WHERE state='CA' AND year=2001
UNION
SELECT DISTINCT energy_source FROM generation WHERE state='TX' AND year=2001
ORDER BY energy_source;

SELECT DISTINCT energy_source FROM generation WHERE state='CA' AND year=2001
UNION ALL -- this is NOT a set operator (it appends two tables)
SELECT DISTINCT energy_source FROM generation WHERE state='TX' AND year=2001
ORDER BY energy_source;

SELECT DISTINCT energy_source FROM generation WHERE state='CA' AND year=2001
INTERSECT
SELECT DISTINCT energy_source FROM generation WHERE state='TX' AND year=2001
ORDER BY energy_source;

SELECT DISTINCT energy_source FROM generation WHERE state='CA' AND year=2001
EXCEPT
SELECT DISTINCT energy_source FROM generation WHERE state='TX' AND year=2001
ORDER BY energy_source;

SELECT DISTINCT energy_source FROM generation WHERE state='TX' AND year=2001
EXCEPT
SELECT DISTINCT energy_source FROM generation WHERE state='CA' AND year=2001
ORDER BY energy_source;

-- The sets must have identical structures and order of columns
SELECT type_of_producer,energy_source 
FROM generation 
WHERE state='CA' AND year=2001 
GROUP BY type_of_producer,energy_source
UNION
SELECT type_of_producer,energy_source
FROM generation 
WHERE state='TX' AND year=2001 
GROUP BY type_of_producer,energy_source
ORDER BY type_of_producer,energy_source;

SELECT type_of_producer,energy_source 
FROM generation 
WHERE state='CA' AND year=2001 
GROUP BY type_of_producer,energy_source
INTERSECT
SELECT type_of_producer,energy_source
FROM generation 
WHERE state='TX' AND year=2001 
GROUP BY type_of_producer,energy_source
ORDER BY type_of_producer,energy_source;

------------------------------------------------------------------------
-- Now, let's ask some business questions and let's answer them with SQL
------------------------------------------------------------------------

-- Q1: What was the total electricity generation from fossil fuels (Coal, Natural Gas, Petroleum)
-- in CA for each quarter between 2001 and 2019? Show generation in TWHrs as a whole number.
SELECT year || CASE WHEN month<=3 THEN '-Q1' WHEN month<=6 THEN '-Q2' WHEN month<=9 THEN '-Q3' ELSE '-Q4' END yq, 
(SUM(generation_mwhrs)/1000000)::int generation_twhrs
FROM generation
WHERE state='CA' AND energy_source IN('Coal','Natural Gas','Petroleum') AND year BETWEEN 2001 AND 2019
GROUP BY year || CASE WHEN month<=3 THEN '-Q1' WHEN month<=6 THEN '-Q2' WHEN month<=9 THEN '-Q3' ELSE '-Q4' END
ORDER BY yq;

-- Q2: What are the years between 2001 and 2019 in which the U.S. produced at least 100TWhr of electricity from Wind and Sun? 
-- Round the production to two digits after the decimal point, order the results by decreasing generation 
SELECT year, round(100*SUM(generation_mwhrs/1000000))/100 generation_twhrs 
FROM generation
WHERE year BETWEEN 2001 AND 2019 AND energy_source IN('Wind','Solar Thermal and Photovoltaic')
GROUP BY year
HAVING SUM(generation_mwhrs/1000000)>=100.0
ORDER BY generation_twhrs DESC;

-- Q3: What are the energy sources used by both the independent power producers and utilities in 2020 in California? 
SELECT DISTINCT energy_source FROM generation WHERE type_of_producer LIKE '%Utilities%' AND year=2020 AND state='CA'
INTERSECT
SELECT DISTINCT energy_source FROM generation WHERE type_of_producer LIKE '%Independent Power Producers%' AND year=2020 AND state='CA'

-- Q4: What are the energy sources used by utilities but not the independent power producers in 2020 in California? 
SELECT DISTINCT energy_source FROM generation WHERE type_of_producer LIKE '%Utilities%' AND year=2020 AND state='CA'
EXCEPT
SELECT DISTINCT energy_source FROM generation WHERE type_of_producer LIKE '%Independent Power Producers%' AND year=2020 AND state='CA'

-- In this module you have learned to
-- - Group data by grouping sets (GROUP BY)
-- - add constraints on aggregates (HAVING)
-- - use SQL set operators: UNION, INTERSECT, and EXCEPT
-- =============================================================================================

-- It is your turn now. 
-- Please switch to the employment database and the blse table which you created in Module 2.
-- Note: I am assuming that you processed the deletes, updates,  and insertions.
-- Please complete the following:
-- Remove all records with the 'Total Nonfarm' industry
-- Please answer the following business questions with SQL queries:

-- Q1: What was the total employment in government in the U.S. in each month between 2006 and 2019?
-- Show the employment in millions as whole numbers.
-- Check: There are 168 rows in the result. The number for 2006-01 is 22, and the number for 2019-12 is 23.

-- Q2: Which states had the average employment in mining and logging in 2019 greater than 20000
-- Round the average employment to one digit after the decimal point order by decreasing employment.
-- Check: There are 10 rows in the result. Texas has the highest number, and it is close to 250.

-- Q3: Which industries had California, Florida, and South Dakota in common in 2019
-- NOTE: Exclude 'Goods Producing', 'Service-Providing', 'Total Private','Government' from consideration
-- Check: There are three distinct rows in the result (assuming that you have deleted the 'Total Nonfarm'). If you have not deleted it, there will be four.
ABORT




/*
ISDS 555 - Business Database Design
Module 07 - Enforcing Referential Integrity with SQL

==================================================================================
NOTE: Never use the postgres database to import or create tables (or other objects)
      ALWAYS create a new database before importing or creating tables 
==================================================================================

NOTE: You need to restore the complete wwdi database from the backup provided in the DropBox folder.

*/

-- Continue only if you are in the wwdi database and this editor is connected to it

-- You will find this code and data files in the course DropBox folder

----------------------------------------------------
-- First, lets explore what we have in this database
----------------------------------------------------
SELECT COUNT(*) FROM country2;
SELECT * FROM country2 LIMIT 10;

SELECT COUNT(*) FROM continent_country;
SELECT * FROM continent_country LIMIT 10;

SELECT COUNT(*) FROM country;
SELECT * FROM country LIMIT 10;

SELECT COUNT(*) FROM indicator;
SELECT * FROM indicator LIMIT 10;

SELECT COUNT(*) FROM country_data; 
SELECT * FROM country_data LIMIT 10;

-- It will be much easier if we look at the ERD
-- Highest conceptual level: https://www.dropbox.com/s/xz8chs9oc2d7ez8/Module%2007%20ERD%20conceptual%201.png?dl=0
-- More details: https://www.dropbox.com/s/kk9tlevqzhyi3k1/Module%2007%20ERD%20conceptual%202.png?dl=0

-- It looks like an attempt to combine two separate databases (it actually is...)

---------------------------------------------------------------------------------------
-- Now, let's analyze the data we already have in detail to better understand the model
---------------------------------------------------------------------------------------

-- Tables already exist so we will have to add referential integrity (FK) constraints

-- Potential issue 1: the database may not be normalized (we should normalize IF we can)
-- Potential issue 2: data violating FK constraints may already exist in these tables

--- *** Relationship between continent and continent_country
-- How many continent codes we have? 
-- NOTE: Nulls will also show if present!
SELECT DISTINCT continent_code FROM continent_country;

-- Let's create a table with continents so that we can store their codes and corresponding names
SELECT DISTINCT continent_code code
INTO continent
FROM continent_country;
-- enforce PK, add the name::varchar(25) by hand and populate names by hand (view/edit data ->all records->enter data->F6)
-- or you can use seven UPDATE statements...

-- *** Relationship between country2 and continent_country
-- Are the codes in country2 unique?
-- Yes, because it is a single-column PK. They also have no nulls. No analysis is needed.

-- Are there any country_code_a2 values in continent_country which do not exist in country2?
-- If yes, we have a problem (except if it is Null)
SELECT DISTINCT country_code_a2 FROM continent_country
EXCEPT
SELECT DISTINCT code FROM country2;

-- *** Relationship between continent and country2 (n:m)
-- Is continent_country an associative table?
-- A. Which countries (codes) are on more than one continent?
SELECT country_code_a2, count(*)
FROM continent_country
GROUP BY country_code_a2
HAVING COUNT(*)>1
ORDER BY country_code_a2;

-- B. Which continents (codes) have more than one country?
SELECT continent_code, count(*)
FROM continent_country
GROUP BY continent_code
HAVING COUNT(*)>1
ORDER BY continent_code;
-- So continent_country is an associative table.

-- *** Relationship between country and country_data
-- Are there any country_code values in country_data which do not exist in country?
-- If yes, we have a problem (except if it is Null)
SELECT DISTINCT country_code FROM country_data
EXCEPT
SELECT DISTINCT code FROM country;

-- *** Relationship between indicator and country_data
-- Are there any indicator_code values in country_data which do not exist in indicator?
-- If yes, we have a problem (except if it is Null)
SELECT DISTINCT indicator_code FROM country_data
EXCEPT
SELECT DISTINCT code FROM indicator;

-- *** Relationship between country and continent_country
-- Are there any country_code_a3 values in continent_country which do not exist in country?
-- If yes, we have a problem (except if it is Null)
SELECT DISTINCT country_code_a3 FROM continent_country
EXCEPT
SELECT DISTINCT code FROM country;
-- There are MANY so we will not be able to enforce referential integrity constraits unless we fix this
-- It would also be nice (and in compliance with the 3NF) to have all countries in one table 
-- that is one-to-many-related with continent_country and country_data

-- To do this we would have to change the PK in either continent_country or country_data
-- Let's check for potential issues:

-- Does each country_code_a2 in continent_country have a corresponding country_code_a3?
-- If yes, it is a good thing.
SELECT * FROM continent_country
WHERE country_code_a3 IS NULL;

-- Are there any country codes which exist in country but do not exist in continent_country?
-- Note: We already know that a PK value exist for each country_code_a2  
-- If yes, what are they?
SELECT code FROM country 
EXCEPT
SELECT country_code_a3 
FROM continent_country
ORDER BY code;

-- Are there any country codes in continent_country which do not exist in country?
-- If yes, what are they?
SELECT country_code_a3 FROM continent_country
EXCEPT
SELECT code FROM country
ORDER BY country_code_a3;

-- So this is an issue which we are going to address later in this course.
-- We need to attempt to reconcile country and country2 without losing any data.

-- At this time let's focus on enforcing the other FK constraints.
-- NOTE: We will be able to setup but not validate this constraint
-- Let's take a look at the "logical" ERD for our non-normalized model
-- https://www.dropbox.com/s/66664cd7i3kq8un/Module%2007%20ERD%20logical.png?dl=0

---------------------------------------------------------
-- Let's now learn about enforcing referential integrity
---------------------------------------------------------

-- Let's take a look at the syntax: https://www.postgresql.org/docs/current/ddl-constraints.html#DDL-CONSTRAINTS-FK

-- Before we set the constraints, we need to make a decision what to do
--- ON UPDATE (of the PK)
--- ON DELETE (of the PK)

-- The following options are available when deleting or updating references PKs
--- NO ACTION (default, prevents deletion and raises an error)
--- RESTRICT (prevents deletion)
--- CASCADE (deletes or updates referenced values for the entire chain of 1:1 and 1:n relationships)
--- SET NULL (sets the values of FK to NULL)
--- SET DEFAULT (sets the values of FK to the specified default value)

-- What about mandatory and optional?
-- You make the PK value mandatory for the FK by (1) enforcing the FK constraints as above and (2) preventing FK fields from accepting NULL
-- To enforce the minimum cardinalty in the other direction you need to use a database trigger (outside of the scope of this module)

----------------------------------------------------------------
-- Then, let's begin enforcing referential integrity constraints
----------------------------------------------------------------

-- Begin with the continent and continent_country (NO ACTION,NO ACTION)
-- Let's do it by hand first before we use SQL

-- Then, let's enforce country2 and continent_country (CASCADE, CASCADE)
-- This time by SQL:
ALTER TABLE public.continent_country
    ADD CONSTRAINT continent_country_fk2 FOREIGN KEY (country_code_a2)
        REFERENCES public.country2 (code) MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE CASCADE;
-- NOTE: PostgreSQL validated this constraint automatically

-- Next, let's enforce indicator and country_data (CASCADE, CASCADE)
ALTER TABLE public.country_data
    ADD CONSTRAINT country_data_fk2 FOREIGN KEY (indicator_code)
        REFERENCES public.indicator (code) MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE CASCADE
		NOT VALID;	
-- NOTE: PostgreSQL did not validate this one automatically - we need to do it by hand;
-- Let's do it later as it may take some time

-- Then, let's enforce country and country_data (CASCADE, CASCADE)
ALTER TABLE public.country_data
    ADD CONSTRAINT country_data_fk1 FOREIGN KEY (country_code)
        REFERENCES public.country (code) MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE CASCADE
		NOT VALID;	
-- NOTE: PostgreSQL did not validate this one automatically - we need to do it by hand
-- Let's do it later as it may take some time

-- Finally, let's try to enforce country and continent_country (RESTRICT, RESTRICT)
ALTER TABLE public.continent_country
    ADD CONSTRAINT continent_country_fk3 FOREIGN KEY (country_code_a3)
        REFERENCES public.country (code) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE RESTRICT
		NOT VALID;
-- Added, but try to validate this one - it will fail (to be dealt with later in this course)

-----------------------------------
-- Take a look at the desired model
-----------------------------------

-- Link: https://www.dropbox.com/s/ran7v2qbwr4a2sn/Module%2007%20ERD%20desired.png?dl=0

---------------------------------
-- List all PK and FK constraints
---------------------------------
-- For now for all databases on the server (later we will make it more specific)
SELECT * FROM pg_catalog.pg_constraint con WHERE contype IN ('p','f');

-- Which of them are not validated?
SELECT * FROM pg_catalog.pg_constraint con WHERE contype IN ('p','f') AND convalidated=false;

-- Use DROP CONSTRAINT [name] to remove a constraint

-- If you can leave the machine running for some time, 
-- you may try to manually validate the FK1 and FK2 constraints for country data


-- In this module you have learned to:
-- analyze the existing data model
-- analyze the existing data for potential FK constraint violations
-- enforce referential integrity (FK) constraints of different types with SQL

-- =============================================================================================

-- It is your turn now. 
-- Please switch to the employment database and the blse table which you created in Module 2 
-- and updated in Module 4. Note: I am assuming that you have:
-- - processed the deletes, updates,  and insertions.
-- - removed all records with the 'Total Nonfarm' industry.

-- You may need to take a look at the U.S. Census Bureau materials or Wikipedia to complete this: https://en.wikipedia.org/wiki/List_of_regions_of_the_United_States
-- Also, before you start please take a look at this physical ERD I prepared: https://www.dropbox.com/s/28ee62q0aii0bqs/Module%2007%20Your%20Turn%20ERDs.png?dl=0

-- Create a table with the current four statistical regions defined by USCB and add the fifth: "Other"
-- Create a table with the current nine UCSCB divisions and add the 10th: "Other"
-- Create a table with all states and territories used in the state field of the blse table 
-- (you should have 53 of them) and a column referencing the division.
-- Note: Puerto Rico and other US territories must be assigned to the "Other" division.

-- Take another look at the ERD: ERD: https://www.dropbox.com/s/28ee62q0aii0bqs/Module%2007%20Your%20Turn%20ERDs.png?dl=0
-- Enforce and validate all the referential integrity constraints with the following settings for each:
-- NO ACTION on delete
-- CASCADE on update

-- CHECKS: I created the following tables (columns): region (number, name), division (number, region_number, name), state (name, division_number)
SELECT COUNT(*) FROM region; -- 5 rows
SELECT COUNT(*) FROM division; -- 10 rows
SELECT * FROM region INNER JOIN division ON region.number = division.region_number; -- 10 rows (joins will be covered in the next module - this is just a check)
SELECT COUNT(*) FROM state; -- 53 rows because territories are also included
SELECT * FROM region INNER JOIN division ON region.number = division.region_number INNER JOIN state ON division.number = state.division_number; -- 53 rows


-- 


/*
ISDS 555 - Business Database Design
Module 08 - Joining Tables

==================================================================================
NOTE: Never use the postgres database to import or create tables (or other objects)
      ALWAYS create a new database before importing or creating tables 
==================================================================================

NOTE: You need to restore the wwdi database from the backup for the previous module provided in the DropBox folder.

*/

-- Continue only if you are in the wwdi database and this editor is connected to it

-- You will find this code and data files in the course DropBox folder

----------------------------------------
-- Let's learn about joining tables now
----------------------------------------

-- Cross Join (Carthesian Product)
-- All unique combinations of rows in each table
SELECT * FROM country, indicator;
SELECT * FROM country CROSS JOIN indicator;

-- Duplicate Column Names? Use qualified names and/or aliases
SELECT country.code country_code, indicator.code indicator_code FROM country, indicator;
SELECT tbl1.code country_code, tbl2.code indicator_code FROM country tbl1, indicator tbl2;

-- Inner Join
-- The most common type of join, used with 1:1 and 1:n relationships
-- Returns rows with matching values
SELECT * FROM country INNER JOIN country_data ON code = country_code;
SELECT name, indicator_code, date, value FROM country INNER JOIN country_data ON code = country_code;

-- You can join multiple tables
SELECT name, description, date, value 
FROM country INNER JOIN country_data ON country.code = country_code 
INNER JOIN indicator ON indicator.code=indicator_code;

-- You can even join a table with itself (self-join)
SELECT * FROM country_data cd1 
INNER JOIN country_data cd2 ON cd1.date=cd2.date AND cd1.indicator_code=cd2.indicator_code
WHERE cd1.date='2018-12-31' 
ORDER BY cd1.country_code,cd2.country_code;

-- Left Outer Join
-- Extends the inner join results with non-matching rows from the table listed on the left

SELECT * FROM country LEFT JOIN country2 ON name=country;

SELECT name, country.code code3, country2.code code2 
FROM country LEFT JOIN country2 ON name=country
WHERE country2.code IS NULL;
-- Matching based on non-key columns is not necessarily a good idea

-- Right Outer Join
-- Extends the inner join results with non-matching rows from the table listed on the right
SELECT country, country2.code code2, country.code code3
FROM country RIGHT JOIN country2 ON name=country
WHERE country.code IS NULL
ORDER BY country;
-- Matching based on non-key columns is not necessarily a good idea - now we can clearly see why...

-- Full Outer Join
-- Extends the inner join results with non-matching rows from both tables
SELECT country, country2.code code2, name,country.code code3
FROM country FULL OUTER JOIN country2 ON name=country
WHERE country.code IS NULL OR country2.code IS NULL;
-- Again, matching based on non-key columns does not work

-- Natural Joins
-- PostgeSQL will try to match tables based on the same column names (the default natural join is INNER JOIN)
-- NOTE: There are NO MATCHING COLUMN NAMES in continent and country
SELECT * FROM continent NATURAL JOIN country; 
SELECT * FROM continent NATURAL LEFT JOIN country; 
SELECT * FROM continent NATURAL RIGHT JOIN country; 

-------------------------------------------------------
-- Let's now use what we learned to normalize the model
-------------------------------------------------------

-- Recall the desired model: https://www.dropbox.com/s/ran7v2qbwr4a2sn/Module%2007%20ERD%20desired.png?dl=0
-- This database attempts to combine World Bank indicators with continents
-- We will try to merge country with country2 but country is our primary table
-- So we want to preserve ALL rows in the country table which actually represent countries

-- Let's take another look at the tables

SELECT * FROM country; --255 rows but some are NOT countries (e.g. Africa)

-- Which countries (names) from our primary table do not have a match in the continent_code?
SELECT DISTINCT name, code, country_code_a2 code2
FROM country LEFT JOIN continent_country ON code=country_code_a3
WHERE country_code_a2 IS NULL 
ORDER BY code;
-- Lets export to CSV to take a closer look

-- Only one of these rows is an actual country and it is located in Europe
-- Does this country exist is country2?
SELECT * FROM country2 WHERE country LIKE 'Kos%';
-- It actually DOES, so what code does it have in continent_country?
SELECT * FROM continent_country WHERE country_code_a2 = 'XK';

-- What about the three-character codes in continent_country which do not have a matching code in country?
-- What are these?
SELECT DISTINCT country_code_a2,country_code_a3,country 
FROM country RIGHT JOIN continent_country ON country.code=country_code_a3 INNER JOIN country2 on country2.code=country_code_a2
WHERE country.code IS NULL;

-- So we need to: 
-- (a) update the three-character code to KSV for all rows in continent_country
-- (b) delete (or nullify) all entries in continent_country which do not have a three-character match country 
-- (c) remove all non-countries from country - this will cause cascade-deletion of matching country_data rows
-- (d) rename the three-character column in continent_country
-- (e) enforce referential integrity constraints between country and continent_country
-- (f) drop country2 table and country_code_a2 column in continent_country
-- So, let's get to work...

-- (a) update the three-character code to KSV for all rows in continent_country
UPDATE continent_country SET country_code_a3='KSV' WHERE country_code_a2='XK';

-- (b) delete all entries in continent_country which do not have a three-character match country 
-- Lets use a temporary table (so we do not use the nested queries before we actually cover them)
SELECT DISTINCT country_code_a2,country_code_a3,country 
INTO temptable -- Added
FROM country RIGHT JOIN continent_country ON country.code=country_code_a3 INNER JOIN country2 on country2.code=country_code_a2
WHERE country.code IS NULL;

DELETE FROM continent_country
USING temptable
WHERE continent_country.country_code_a3 = temptable.country_code_a3;

DROP TABLE temptable;

-- (c) remove all non-countries from country - this will cause cascade-deletion of matching country_data rows
-- Also using a temporary table
SELECT DISTINCT name, code, country_code_a2 code2
INTO temptable
FROM country LEFT JOIN continent_country ON code=country_code_a3
WHERE country_code_a2 IS NULL;

DELETE FROM country
USING temptable
WHERE country.code = temptable.code;

DROP TABLE temptable;

-- Check how many countries we have now. NOTE: referential integrity between country and country_data is preserved.
SELECT COUNT(*) FROM country;
SELECT DISTINCT country_code FROM country_data;

-- (d) rename the three-character column in continent_country
ALTER TABLE public.continent_country
    RENAME country_code_a3 TO country_code;
	
-- (e) enforce referential integrity constraints between country and continent_country
-- The constraint is already set, we just need to validate it.
-- Which of the constraints are not validated?
SELECT * FROM pg_catalog.pg_constraint con WHERE contype IN ('p','f') AND convalidated=false;
-- Let's validate it
ALTER TABLE continent_country
    VALIDATE CONSTRAINT continent_country_fk3;

-- (f) drop country2 table and country_code_a2 column in continent_country
-- Must drop FK constraint between country2 and continent_country (continent_country_fk2) first
ALTER TABLE continent_country
	DROP CONSTRAINT continent_country_fk2;
-- For consistency with the ERD, rename continent_country_fk3 to continent_country_fk2
ALTER TABLE continent_country RENAME CONSTRAINT continent_country_fk3 TO continent_country_fk2;
-- remove country_code_a2 column
ALTER TABLE continent_country DROP COLUMN country_code_a2;
-- remove country2 table
DROP TABLE country2;

---------------------------------------------------------------
-- Let's now use the normalized model to answer a few questions
---------------------------------------------------------------

-- How many countries do we have per continent? 
-- List continents and corresponding counts alphabetically (by name).
SELECT name, COUNT(*) as countries
FROM continent INNER JOIN continent_country ON code=continent_code
GROUP BY name
ORDER BY name;

-- Which 10 countries (use names) on what continents (use names) had the lowest access to electricity in 2018? 
-- Order by the value of the indicator.
SELECT continent.name as continent,country.name as country,value as access_to_electricity
FROM country INNER JOIN country_data ON country.code=country_code 
INNER JOIN continent_country ON country.code= continent_country.country_code 
INNER JOIN continent ON continent.code=continent_country.continent_code
WHERE indicator_code='EG_ELC_ACCS_ZS' AND EXTRACT (YEAR FROM date)=2018
ORDER BY value
LIMIT 10;
-- NOTE: countries which are on two continents will be listed twice (remove the limit and check, e.g., Turkey)

-- What was the average access to electricity in 2018 per continent (use names)? Order by average access.
SELECT continent.name, AVG(value) as avg_access_to_electricity
FROM continent INNER JOIN continent_country ON  continent.code= continent_country.continent_code
INNER JOIN country_data ON  continent_country.country_code = country_data.country_code
WHERE indicator_code='EG_ELC_ACCS_ZS' AND EXTRACT (YEAR FROM date)=2018
GROUP BY continent.name
ORDER BY avg_access_to_electricity;
-- NOTE: countries which are on two continents will be averaged twice

-- In this module you have learned to:
-- apply cross joins
-- join two tables using inner, left, right and full joins
-- apply joins to more than two tables

-- =============================================================================================

/*
ISDS 555 - Business Database Design
Module 09 - Views and Materialized Views

==================================================================================
NOTE: Never use the postgres database to import or create tables (or other objects)
      ALWAYS create a new database before importing or creating tables 
==================================================================================

NOTE: You need to restore the wwdi database from the backup for the previous module provided in the DropBox folder.

*/

-- Continue only if you are in the wwdi database and this editor is connected to it

-- You will find this code and data files in the course DropBox folder

---------------------------------------------
----------- What is a view? -----------------
---------------------------------------------

-- A named SQL "SELECT" statement
-- Does not store any data - only SQL code (unless it is a materialized view)
-- "Behaves" like a (generally) read-only table which is derived from other tables and views
-- Commonly used for wrapping complex SQL statements 

-------------------------------------------
----------- Regular Views -----------------
-------------------------------------------

-- First, let's create a view v_country_data manually (with GUI)
SELECT name, description, date, value 
FROM country INNER JOIN country_data ON country.code = country_code 
INNER JOIN indicator ON indicator.code=indicator_code;

SELECT * FROM v_country_data;

-- Next, let's use SQL
CREATE VIEW v_country_data_export AS
	SELECT name, description, date, value 
	FROM country INNER JOIN country_data ON country.code = country_code 
	INNER JOIN indicator ON indicator.code=indicator_code;

-- Updating and dropping views
ALTER VIEW v_country_data_export RENAME TO v_country_indicator_data_export;

CREATE OR REPLACE VIEW  v_country_data AS
 SELECT name, description, date, value 
 FROM country INNER JOIN country_data ON country.code = country_code 
 INNER JOIN indicator ON indicator.code=indicator_code
 ORDER BY name,description,date;

DROP VIEW IF EXISTS v_country_data_export;
DROP VIEW IF EXISTS v_country_indicator_data_export;

-------------------------------------------
----------- Updateable Views -----------------
-------------------------------------------

-- Let's check the documentation: https://www.postgresql.org/docs/current/sql-createview.html
-- So, basically only "simple" views can be updateable

CREATE VIEW v_updateable AS
 SELECT * FROM continent INNER JOIN continent_country ON continent.code = continent_code;

SELECT * FROM v_updateable;

-- THIS WILL RESULT IN AN ERROR 
UPDATE v_updateable SET name='Australia' WHERE code='OC';

DROP VIEW v_updateable;

CREATE OR REPLACE VIEW v_updateable AS
 SELECT * 
 FROM continent
 WHERE name LIKE 'Au%'
 ORDER BY name;

SELECT * FROM v_updateable;
UPDATE v_updateable SET name='Australia'; -- Note: No WHERE!
SELECT * FROM v_updateable;
SELECT * FROM continent;

-- restore
UPDATE v_updateable SET name='Australia and Oceania'; -- Note: No WHERE!
DROP VIEW v_updateable;

------------------------------------------------
----------- Materialized Views -----------------
------------------------------------------------

-- Just like a regular view but stores (caches) data to improve performance of complex queries
-- MUST BE EXPLICITLY REFRESHED
-- Used when some latency is allowed (e.g. hourly, daily, or weekly reports)
-- Why not use multiple helper tables then? Because this would make the code more complex.

-- Creating a materialized view with no data
CREATE MATERIALIZED VIEW mv_country_data AS
 SELECT name country_name,description indicator_name, date, value 
 FROM country_data INNER JOIN country ON country_code = country.code 
 INNER JOIN indicator ON indicator_code = indicator.code
WITH NO DATA;

-- THIS WILL RESULT IN AN ERROR 
SELECT * FROM mv_country_data;

-- Refreshing
REFRESH MATERIALIZED VIEW mv_country_data;
SELECT * FROM mv_country_data;

-- Can we see the difference in performance? 
-- Not really for such a simple query and small dataset

-- Dropping materialized views
DROP MATERIALIZED VIEW mv_country_data;

-- Creating a materialized view with data (refreshed)
CREATE MATERIALIZED VIEW mv_country_data AS
 SELECT name country_name,description indicator_name, date, value 
 FROM country_data INNER JOIN country ON country_code = country.code 
 INNER JOIN indicator ON indicator_code = indicator.code
WITH DATA; -- the only difference

SELECT * FROM mv_country_data;

-----------------------------------------
----------- Using Views -----------------
-----------------------------------------

SELECT DISTINCT indicator_code FROM country_data;

-- Let's create (regular) views for each indicator in our database
CREATE VIEW v_access_to_electricity AS
 SELECT name country_name,description indicator_name, date, value 
 FROM country_data INNER JOIN country ON country_code = country.code 
 INNER JOIN indicator ON indicator_code = indicator.code
 WHERE indicator_code='EG_ELC_ACCS_ZS';

CREATE VIEW v_adj_net_national_income AS
 SELECT name country_name,description indicator_name, date, value 
 FROM country_data INNER JOIN country ON country_code = country.code 
 INNER JOIN indicator ON indicator_code = indicator.code
 WHERE indicator_code='NY_ADJ_NNTY_KD';

CREATE VIEW v_adj_net_national_income_growth AS
 SELECT name country_name,description indicator_name, date, value 
 FROM country_data INNER JOIN country ON country_code = country.code 
 INNER JOIN indicator ON indicator_code = indicator.code
 WHERE indicator_code='NY_ADJ_NNTY_KD_ZG';

-- Next, let's create a materialized view based on these views
CREATE MATERIALIZED VIEW mv_three_indicators AS
 SELECT AEL.country_name,AEL.date, AEL.value access_to_electricity,
 ANI.value adj_net_national_income, ANG.value adj_net_national_income_growth 
 FROM v_access_to_electricity AEL 
 INNER JOIN v_adj_net_national_income ANI ON AEL.country_name = ANI.country_name AND AEL.date = ANI.date
 INNER JOIN v_adj_net_national_income_growth ANG ON AEL.country_name = ANG.country_name AND AEL.date = ANG.date
 ORDER BY country_name ASC, date DESC
WITH DATA;
-- Note: there is a better way to pivot data in PostgreSQL (for a limited number of columns)

SELECT * FROM mv_three_indicators;

-- How many years of complete data do we have for each of these three indicators for each country?
SELECT country_name, COUNT(*) years
FROM mv_three_indicators
GROUP BY country_name
ORDER BY years;


---------------------------------------------------------------------------------------------

-- In this module you have learned to:
-- Create an use views
-- Use updateable views
-- Create and use materialized views

-- Interested in learning more? I suggest recursive views (optional) and "check option" (optional): 
-- https://www.postgresqltutorial.com/postgresql-recursive-view/
-- https://www.postgresqltutorial.com/postgresql-views-with-check-option/

-- =============================================================================================

-- It is your turn now. 
-- Please switch to the employment database and the blse table which you created in Module 2 
-- and updated in Modules 4 and 7. Note: I am assuming that you have:
-- - processed the deletes, updates,  and insertions.
-- - removed all records with the 'Total Nonfarm' industry.
-- - added the region, division and state tables, populated these tables with data, and 
--   enforced entity and referential integrity constraints.

--- Create the following views:

-- vQ1: How many states does each region have? List regions and counts. Order alphabetically by region name.
-- (5 rows, the total count should be 53)

CREATE VIEW v_Q1 AS
	SELECT region.name, COUNT (*) as counts
	FROM region INNER JOIN division ON division.region_number = region.number
	INNER JOIN state ON state.division_number = division.number
	GROUP BY region.name
	ORDER BY region.name;


-- vQ2: Which divisions (use names) had the highest average employment in Government in June 2019? 
-- Round to two digits after the decimal point.
-- Order by the decreasing values of the average, show record count (10 rows, the total count should be 53)





-- mvQ3: Which regions (use names) did not have any employment in 'Mining and Logging'?

/*
ISDS 555 - Business Database Design
Module 10 - Nested Queries (Subqueries)

==================================================================================
NOTE: Never use the postgres database to import or create tables (or other objects)
      ALWAYS create a new database before importing or creating tables 
================================
=================================================

NOTE: You need to restore the wwdi database from the backup for the previous module provided in the DropBox folder.

*/

-- Continue only if you are in the wwdi database and this editor is connected to it

-- You will find this code and data files in the course DropBox folder

-------------------------------------
-- Simple nested queries (Type I) ---
-------------------------------------
-- Executed independently of the outer query/queries
-- Executed before the outer query and the results are "fed" into the outer query
-- Relatively simple and can be thought of as "one-time views"

-----------------------------------------------
-- Nested Type I Queries in the FROM clause ---
-----------------------------------------------

-- How many countries per continent (use continent names)?
SELECT name, COUNT(*) countries 
FROM continent_country INNER JOIN continent ON  code = continent_code
GROUP BY name;

-- Check the total number of countries 
SELECT SUM(countries) FROM
 (
 SELECT name, COUNT(*) countries 
 FROM continent_country INNER JOIN continent ON  code = continent_code
 GROUP BY name
 ) CC;
-- Note: duplicates are counted here (we will revisit this)

-- How many distinct countries are assigned to continents?
SELECT COUNT(*) countries FROM (SELECT DISTINCT country_code FROM continent_country) DC;

-- How many countries have (at least one record of) data for each indicator?
SELECT indicator_code, COUNT(*) countries FROM
(SELECT DISTINCT indicator_code,country_code FROM country_data) IC
GROUP BY indicator_code;

------------------------------------------------
-- Nested Type I Queries in the WHERE clause ---
------------------------------------------------
-- Nested Type I queries and the IN operator
-- Can be thought of as of "simplified joins," i.e., joins based on a single column

-- Which indicators (use names) have data in the country_data table?
SELECT description FROM indicator WHERE code IN (SELECT DISTINCT indicator_code FROM country_data);

-- Which indicators (use names) have data for 1970 in the country_data table?
SELECT description FROM indicator 
WHERE code IN (SELECT DISTINCT indicator_code FROM country_data WHERE EXTRACT(YEAR FROM date)=1970);

--------------------------------------------------
-- Nested Type I Queries in the SELECT clause ---
--------------------------------------------------
-- Let's revise the previous check by removing duplicates from the total
-- First, find the duplicates
SELECT country_code FROM continent_country GROUP BY country_code HAVING COUNT(*)>1;
-- Next, count them
SELECT COUNT(*) 
FROM (SELECT country_code FROM continent_country GROUP BY country_code HAVING COUNT(*)>1) DUPS;
-- Finally, nest the query
SELECT SUM(countries) - (SELECT COUNT(*) FROM (SELECT country_code FROM continent_country GROUP BY country_code HAVING COUNT(*)>1) DUPS) DUPSCOUNT
FROM
 (
 SELECT name, COUNT(*) countries 
 FROM continent_country INNER JOIN continent ON  code = continent_code
 GROUP BY name
 ) CC;
-- Now the total is correct
-- Notice the nested queries in the SELECT and FROM clauses

------------------------------------------
-- Advanced Nested Queries (Type II) -----
------------------------------------------
-- Also known as "Correlated Subqueries"

-- Nested Type II queries and the EXISTS operator
-- The EXISTS operator returns true if a single record exists in the following query

-- Show countries (names) which have at least one record for NY_ADJ_NNTY_KD_ZG.

SELECT name 
FROM country cc WHERE 
EXISTS 
 (SELECT * FROM country_data cd 
  WHERE cc.code=cd.country_code AND indicator_code='NY_ADJ_NNTY_KD_ZG');
-- Can this be done in other ways? Yes (e.g., set operators,joins)
-- Note how the nested query is linked with the outer query in the where clause
-- It opens up many possibilities. You can actually nest a Type II query in the FROM or SELECT clauses

-- Nested Type II Queries in the SELECT clause

-- For each record with 'EG_ELC_ACCS_ZS' (access to electricity)
-- in 'POL' (Poland) in country_data identify the previous date
SELECT *, 
 (SELECT MAX(CD.date) 
  FROM country_data CD 
  WHERE CD.country_code=country_data.country_code AND CD.indicator_code=country_data.indicator_code 
  AND CD.date<country_data.date
 ) prev_date
FROM country_data
WHERE country_code = 'POL' and indicator_code='EG_ELC_ACCS_ZS';


----------------------------------------------------------------
-- Let's now use what we learned to answer complex questions ---
----------------------------------------------------------------

-- What was the average annual growth percentage in access to electricity for each country between 1991 and 2000
-- Exclude countries with incomplete data, order by the average annual growth percentage descending

SELECT name, AVG(GROWTH.pct_growth) avg_pct_growth 
FROM
(
SELECT *,CD1.value/CD0.value-1.0 pct_growth, CD1.country_code cc FROM
(SELECT *, 
 (SELECT MAX(CD.date) 
  FROM country_data CD 
  WHERE CD.country_code=country_data.country_code AND CD.indicator_code=country_data.indicator_code AND CD.date<country_data.date
 ) prev_date
FROM country_data) CD1 
INNER JOIN country_data CD0 ON
CD0.country_code=CD1.country_code AND CD0.indicator_code=CD1.indicator_code 
AND CD0.date=CD1.prev_date
WHERE CD0.indicator_code='EG_ELC_ACCS_ZS'
-- countries with complete 1991-2000 data
AND CD1.country_code IN
 (SELECT country_code
  FROM country_data WHERE indicator_code='EG_ELC_ACCS_ZS'
  AND date BETWEEN '1990-12-31' AND '2000-12-31'  -- Note:  we need 1990 data to calculate 1991 growth
 GROUP BY country_code HAVING COUNT(*)=11 
 )
 AND CD1.date BETWEEN '1991-12-31' AND '2000-12-31'; -- this is necessary
) GROWTH INNER JOIN country ON code=GROWTH.cc
GROUP BY name
ORDER BY avg_pct_growth DESC;

-- How can we make this query easier to understand and manage? 
-- Use views and helper views to store Type I nested queries
-- They are easy to determine: run a nested query if it runs - it is a Type I
-- Let's redo the complex query above with helper views

CREATE VIEW v_countries_1991_2000 AS
 SELECT country_code
 FROM country_data WHERE indicator_code='EG_ELC_ACCS_ZS'
 AND date BETWEEN '1990-12-31' AND '2000-12-31'  -- Note:  we need 1990 data to calculate 1991 growth
 GROUP BY country_code HAVING COUNT(*)=11;

CREATE VIEW v_cd1 AS
 SELECT *, 
 (SELECT MAX(CD.date) 
  FROM country_data CD 
  WHERE CD.country_code=country_data.country_code AND CD.indicator_code=country_data.indicator_code AND CD.date<country_data.date
 ) prev_date
 FROM country_data;

CREATE VIEW v_growth AS
 -- we need to adjust column names or remove duplicate names - I removed "*," from SELECT and added CD1.date
 SELECT CD1.value/CD0.value-1.0 pct_growth, CD1.country_code cc, CD1.date FROM v_cd1 CD1
 INNER JOIN country_data CD0 ON
 CD0.country_code=CD1.country_code AND CD0.indicator_code=CD1.indicator_code 
 AND CD0.date=CD1.prev_date
 WHERE CD0.indicator_code='EG_ELC_ACCS_ZS'
 -- countries with complete 1991-2000 data
 AND CD1.country_code IN (SELECT country_code FROM v_countries_1991_2000)
 AND CD1.date BETWEEN '1991-12-13' AND '2000-12-31'; -- this is necessary
 
-- Our query looks much simpler now
SELECT name, AVG(pct_growth) avg_pct_growth, COUNT(*) years 
FROM v_growth INNER JOIN country ON code=cc
GROUP BY name
ORDER BY avg_pct_growth DESC;

-- =============================================================================================

-- In this module you have learned to:
-- Use Type I nested queries
-- Use Type II nested queries
-- Build complex queries using Type I, Type II nested queries
-- Use "helper" views for Type I subqueries

-- =============================================================================================

-- It is your turn now. 
-- Please switch to the employment database and the blse table which you created in Module 2 
-- and updated in Modules 4 and 7. Note: I am assuming that you have:
-- - processed the deletes, updates,  and insertions.
-- - removed all records with the 'Total Nonfarm' industry.
-- - added the region, division and state tables, populated these tables with data, and 
--   enforced entity and referential integrity constraints.
-- - created views and materialized views

-- Q1: Use EXISTS to find all states/territories which do *not* have a single record of employment in 'Mining and Logging'
-- There are 11 such states/territories

-- Q2: Find all divisions with states which employed in less than 9 industries in June 2019
-- (there are 7 such divisions)

-- Q3: What was the average (for each state/territory) monthly growth in employment in Government between 2008 and 2016?
-- Assume (do not enforce) that complete record exisits for all states.
-- Round average growth in each state  to 4 digits. 
-- Order the results in the decreasing order of the average monthly growth.
-- Hints: use "helper" views; the average for the third row (West Virginia) should be 0.0009


/*
ISDS 555 - Business Database Design
Module 11 - Indexes and Maintenance

==================================================================================
NOTE: Never use the postgres database to import or create tables (or other objects)
      ALWAYS create a new database before importing or creating tables 
==================================================================================

NOTE: You need to restore the wwdi database from the backup for the previous module provided in the DropBox folder.

*/

-- Continue only if you are in the wwdi database and this editor is connected to it

-- You will find this code and data files in the course DropBox folder

---------------------------------------
-- Introduction to Database Indexes ---
---------------------------------------
-- Yes, INDEXES not "indices" as in "economic indices."
-- Database indexes are auxiliary structures which improve performance of retrieval queries
-- However, they (generally) deteriorate performance of insert/update/delete queries
-- They also increase the size of the database

-- First, let's upsert some more data so we can see changes in performance
-- Currently, we only have the following indices: NY_ADJ_NNTY_KD_ZG, "NY_ADJ_NNTY_KD, EG_ELC_ACCS_ZS
-- Please import wwdi_country_data_mod11.csv (it may take a while) which is in the Data folder
-- Use header, comma as delimiter and double quote

-- Create a temporary table (no integrity constraints)
SELECT * 
INTO tmp_country_data 
FROM country_data 
WHERE indicator_code = 'BLAH'; -- this is intentional so the tmp table has no data

-- Manually import the CSV file (it took 16 seconds on my laptop)
SELECT COUNT(*) FROM tmp_country_data;
SELECT COUNT(*) FROM country_data;

-- Upsert (insert if possible) data to country_data
-- This tool almost 5 minutes on my laptop
-- NOTE: WRITE DOWN HOW LONG IT TOOK ON YOUR MACHINE.
INSERT INTO country_data
SELECT * FROM tmp_country_data
ON CONFLICT DO NOTHING;

-- Now drop the temporary table
DROP TABLE tmp_country_data;

-- Let's run this query without any index
-- It takes about 10 seconds on my laptop.
SELECT country_code, indicator_code, COUNT(*) as years
FROM country_data
GROUP BY country_code, indicator_code;

-- So, what is the size of the data in the table?
SELECT pg_relation_size('country_data'); -- hard to read quickly
SELECT pg_size_pretty(pg_relation_size('country_data'));
-- What is the size of the table with all auxiliary structures?
SELECT pg_size_pretty(pg_total_relation_size('country_data'));
-- On my laptop it shows 615MB

-- Let's add a simple, two column index: ix_country_data_country_code_indicator_code
-- It takes about 17 seconds on my laptop.
CREATE INDEX ix_country_data_country_code_indicator_code 
ON country_data(country_code, indicator_code);
-- What is the size of the table with all auxiliary structures now?
SELECT pg_size_pretty(pg_total_relation_size('country_data'));
-- On my laptop it shows 809MB
-- So, this index required 194MB (809-615) or 31.5% of additional storage

-- Let's use GUI to explore this index

-- Let's re-run the query which took 10 seconds without any index
-- It now takes about 2.5 seconds on my laptop.
SELECT country_code, indicator_code, COUNT(*) as years
FROM country_data
GROUP BY country_code, indicator_code;
-- Therefore my performance gain was 7.5 (10-2.5) seconds or 75% (7.5/10*100%)

-- What is the size of ALL indexes on country_data?
SELECT pg_size_pretty(pg_indexes_size('country_data'));
-- But our index added only 194MB! Are there any other indexes?

-- List indexes (similar to listing keys)
SELECT tablename,indexname,*
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename,indexname;
-- PK constraints come with a default UNIQUE index

-- You can add indexes to materialized views.

-- There are different types of indexes and index-tuning is art/science
-- Not enough indexes - retrieval too slow
-- Too many indexes - insert/update/delete too slow
-- Learn more: https://www.postgresqltutorial.com/postgresql-indexes/postgresql-index-types/

-------------------------------------------
-- Introduction to Database Maintenance ---
-------------------------------------------
-- Maintenance helps improve performance and minimize storage requirements 
-- Typically done periodically and "off-peak" (nights, weekends, holidays)

-- Basic database maintenance involves: vacuuming, analyzing, reindexing, and clustering

/*
VACUUM:  reclaim storage used by dead tuples.
FULL: compact tables by writing a completely new version of the table file without dead space. 
FREEZE: freeze data in a table when it will have no further updates.
ANALYZE: update the stored statistics used by the query planner for optimal performance. 
REINDEX: rebuild an index.
CLUSTER: cluster the selected table.
*/

-- To learn more about maintenance: https://www.postgresql.org/docs/current/maintenance.html

-- =============================================================================================

-- In this module you have learned to:
-- Create multi-column indexes of the default type
-- Check the index size and list indexes in your database
-- Perform basic maintenance on your PostgreSQL database
-- =============================================================================================

-- It is your turn now. 
-- Please switch to the employment database and the blse table which you created in Module 2 
-- and updated in Modules 4 and 7. Note: I am assuming that you have:
-- - processed the deletes, updates,  and insertions.
-- - removed all records with the 'Total Nonfarm' industry.
-- - added the region, division and state tables, populated these tables with data, and 
--   enforced entity and referential integrity constraints.
-- - created views and materialized views

-- Step 1. Check the performance of your views to identify the slowest (write down the execution time, t0, in seconds).

-- Step 2. Add or modify indexes which will speed up the execution of the slowest view. 
-- 			You may consider adding intermediate materialized views

-- Step 3. Run the view now (write down the execution time, t1, in seconds)

-- What is your performance gain? What is the additional storage requirement?

-- Also, perform a full vacuum on the employment database.


