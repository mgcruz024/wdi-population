/*
WDI-Database

----------------------------------------------------
------------- Inspect initial database -------------
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

-- It looks like an attempt to combine two separate databases 

---------------------------------------------------------------------------------------
----------------------- Analyze current data ------------------------------------------
---------------------------------------------------------------------------------------

-- Potential issue 1: the database may not be normalized 
-- Potential issue 2: data violating FK constraints may already exist in these tables

--- *** Relationship between continent and continent_country
-- How many continent codes we have? 
SELECT DISTINCT continent_code FROM continent_country;

-- Create a table with continents to store their codes and corresponding names
SELECT DISTINCT continent_code code
INTO continent
FROM continent_country;

-- *** Relationship between country2 and continent_country
-- Are the codes in country2 unique? YES

-- Are there any country_code_a2 values in continent_country which do not exist in country2?
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
-- FINDING: continent_country is an associative table.

-- *** Relationship between country and country_data
-- Are there any country_code values in country_data which do not exist in country?
SELECT DISTINCT country_code FROM country_data
EXCEPT
SELECT DISTINCT code FROM country;

-- *** Relationship between indicator and country_data
-- Are there any indicator_code values in country_data which do not exist in indicator?
SELECT DISTINCT indicator_code FROM country_data
EXCEPT
SELECT DISTINCT code FROM indicator;

-- *** Relationship between country and continent_country
-- Are there any country_code_a3 values in continent_country which do not exist in country?
SELECT DISTINCT country_code_a3 FROM continent_country
EXCEPT
SELECT DISTINCT code FROM country;
-- There are MANY. Will not be able to enforce referential integrity constraits unless this is fixed.

-- Change the PK in either continent_country or country_data
-- Check for potential issues:

-- Does each country_code_a2 in continent_country have a corresponding country_code_a3?
SELECT * FROM continent_country
WHERE country_code_a3 IS NULL;

-- Are there any country codes which exist in country but do not exist in continent_country?
SELECT code FROM country 
EXCEPT
SELECT country_code_a3 
FROM continent_country
ORDER BY code;

-- Are there any country codes in continent_country which do not exist in country?
SELECT country_code_a3 FROM continent_country
EXCEPT
SELECT code FROM country
ORDER BY country_code_a3;

-- Attempt to reconcile country and country2 without losing any data.

----------------------------------------------------------------
------------ Enforcing referential integrity constraints -------
----------------------------------------------------------------

-- Enforce continent and continent_country (NO ACTION,NO ACTION)

-- Enforce country2 and continent_country (CASCADE, CASCADE)
ALTER TABLE public.continent_country
    ADD CONSTRAINT continent_country_fk2 FOREIGN KEY (country_code_a2)
        REFERENCES public.country2 (code) MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE CASCADE;

-- Enforce indicator and country_data (CASCADE, CASCADE)
ALTER TABLE public.country_data
    ADD CONSTRAINT country_data_fk2 FOREIGN KEY (indicator_code)
        REFERENCES public.indicator (code) MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE CASCADE
		NOT VALID;	

-- Enforce country and country_data (CASCADE, CASCADE)
ALTER TABLE public.country_data
    ADD CONSTRAINT country_data_fk1 FOREIGN KEY (country_code)
        REFERENCES public.country (code) MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE CASCADE
		NOT VALID;	

-- Enforce country and continent_country (RESTRICT, RESTRICT)
ALTER TABLE public.continent_country
    ADD CONSTRAINT continent_country_fk3 FOREIGN KEY (country_code_a3)
        REFERENCES public.country (code) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE RESTRICT
		NOT VALID;

-------------------------------------------------------
---------- Normalize the model ------------------------
-------------------------------------------------------

-- Preserve ALL rows in the country table which actually represent countries

SELECT * FROM country; --255 rows but some are NOT countries (e.g. Africa)

-- Which countries (names) from the primary table do not have a match in the continent_code?
SELECT DISTINCT name, code, country_code_a2 code2
FROM country LEFT JOIN continent_country ON code=country_code_a3
WHERE country_code_a2 IS NULL 
ORDER BY code;

-- Only one of these rows is an actual country and it is located in Europe

-- Does this country exist in country2?
SELECT * FROM country2 WHERE country LIKE 'Kos%';
-- It does
SELECT * FROM continent_country WHERE country_code_a2 = 'XK';

-- Three-character codes in continent_country which do not have a matching code in country
SELECT DISTINCT country_code_a2,country_code_a3,country 
FROM country RIGHT JOIN continent_country ON country.code=country_code_a3 INNER JOIN country2 on country2.code=country_code_a2
WHERE country.code IS NULL;

-- (a) update the three-character code to KSV for all rows in continent_country
UPDATE continent_country SET country_code_a3='KSV' WHERE country_code_a2='XK';

-- (b) delete all entries in continent_country which do not have a three-character match country 
SELECT DISTINCT country_code_a2,country_code_a3,country 
INTO temptable -- Added
FROM country RIGHT JOIN continent_country ON country.code=country_code_a3 INNER JOIN country2 on country2.code=country_code_a2
WHERE country.code IS NULL;

DELETE FROM continent_country
USING temptable
WHERE continent_country.country_code_a3 = temptable.country_code_a3;

DROP TABLE temptable;

-- (c) remove all non-countries from country 
SELECT DISTINCT name, code, country_code_a2 code2
INTO temptable
FROM country LEFT JOIN continent_country ON code=country_code_a3
WHERE country_code_a2 IS NULL;

DELETE FROM country
USING temptable
WHERE country.code = temptable.code;

DROP TABLE temptable;

-- Check how many countries there are now
SELECT COUNT(*) FROM country;
SELECT DISTINCT country_code FROM country_data;

-- (d) rename the three-character column in continent_country
ALTER TABLE public.continent_country
    RENAME country_code_a3 TO country_code;
	
-- (e) drop country2 table and country_code_a2 column in continent_country
-- Must drop FK constraint between country2 and continent_country (continent_country_fk2) first
ALTER TABLE continent_country
	DROP CONSTRAINT continent_country_fk2;
-- Rename continent_country_fk3 to continent_country_fk2 (consistent w/ ERD)
ALTER TABLE continent_country RENAME CONSTRAINT continent_country_fk3 TO continent_country_fk2;
-- remove country_code_a2 column
ALTER TABLE continent_country DROP COLUMN country_code_a2;
-- remove country2 table
DROP TABLE country2;
