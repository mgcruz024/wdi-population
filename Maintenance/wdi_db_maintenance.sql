/*
WDI-Database

-----------------------------------------------------------
-- Creating indexes to boost query retrieval performance ---
------------------------------------------------------------

-- Create a temporary table 
SELECT * 
INTO tmp_country_data 
FROM country_data 
WHERE indicator_code = 'MEH'; -- no data!

-- Import the country data CSV file
SELECT COUNT(*) FROM tmp_country_data;
SELECT COUNT(*) FROM country_data;

-- Upsert data to country_data
-- Took 5 minutes on my laptop
INSERT INTO country_data
SELECT * FROM tmp_country_data
ON CONFLICT DO NOTHING;

-- Drop the temporary table
DROP TABLE tmp_country_data;

-- Run this query without any index
-- Took about 10 seconds on my laptop.
SELECT country_code, indicator_code, COUNT(*) as years
FROM country_data
GROUP BY country_code, indicator_code;


-- What is the size of the table with all auxiliary structures?
SELECT pg_size_pretty(pg_total_relation_size('country_data'));
-- Shows 615MB

-- Add a two-column index: ix_country_data_country_code_indicator_code
-- Took about 17 seconds on my laptop.
CREATE INDEX ix_country_data_country_code_indicator_code 
ON country_data(country_code, indicator_code);
-- What is the size of the table with all auxiliary structures now?
SELECT pg_size_pretty(pg_total_relation_size('country_data'));
-- Shows 809MB
-- FINDING: this index required 194MB (809-615) or 31.5% of additional storage


-- Re-run the query with the new index
-- Took about 2.5 seconds on my laptop.
SELECT country_code, indicator_code, COUNT(*) as years
FROM country_data
GROUP BY country_code, indicator_code;
-- FINDING: performance gain was 7.5 (10-2.5) seconds or 75% (7.5/10*100%)

-- What is the size of ALL indexes on country_data?
SELECT pg_size_pretty(pg_indexes_size('country_data'));
-- FINDING: index added only 194MB

-- List indexes 
SELECT tablename,indexname,*
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename,indexname;





