


/*
WDI-Database
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


