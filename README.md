# World Bank Database and Population Analysis With PostgreSQL

<img src="Screenshots/World_Bank.jpeg.jpg" width="650" height="375" />

## Packages Used
PostgreSQL
- SQL

## ERD
<img src="Screenshots/Final ERD.PNG" width="650" height="375" />



## Cleansing





## Analysis
<img src="Screenshots/m7_view.png" width="650" height="375" />
<img src="Screenshots/m7_sql.png" width="650" height="375" />






## Maintenance

[Improved](Maintenance/wdi_db_maintenance.sql) the performance of retrieval queries while limiting any significant increases
to the database storage. 

Created a two-column index: "ix_country_data_country_code_indicator_code"
that boosted query performance by 7.5 seconds while only adding 194MB to the main "country_data" table.


## Notes
Data retrieved from https://data.worldbank.org/
