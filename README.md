# ChinookDB Sales Analysis

This project contains SQL scripts and insights generated from the **Chinook** sample database (music store data).  
The goal of the analysis is to explore sales performance across geographies and time, highlighting both volume-driven (workhorse) and premium markets.

## Environment
- **Database:** SQLite3 (Chinook demo DB)  
- **IDE:** SQLStudio v3.4.17  

## Contents
- SQL scripts for sales aggregation, rankings, and trends  
- Insights covering yearly, country, state, and city-level performance  
- Business interpretation of results  

## Notes
- All values are assumed in USD (Chinook DB does not provide currency codes).  
- State-level analysis is limited since many records have null states.  
- Queries are optimized for SQLite syntax (e.g., `strftime` for dates).

## Credits
- The Chinook sample database was originally created by Lynn Henning.  
- It is widely used in the data community as a demo database for SQL practice and educational purposes.  
- Reference: [Chinook Database on GitHub](https://github.com/lerocha/chinook-database)

