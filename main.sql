/*
WDI-Database

----------------------------------------------------
------------- Inspect initial database -------------
----------------------------------------------------

-- import
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

-- It looks like an attempt to combine two separate databases 

---------------------------------------------------------------------------------------
----------------------- Analyze current data ------------------------------------------
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




