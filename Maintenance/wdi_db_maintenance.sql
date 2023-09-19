/*
WDI-Database

-----------------------------------------------------------
-- Creating indexes to boost query retrieval performance ---
------------------------------------------------------------


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





