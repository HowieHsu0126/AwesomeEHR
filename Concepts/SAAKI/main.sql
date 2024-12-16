-- Description: Main SQL script for the PostgreSQL database
-- Create the schema for the MIMIC-IV database
-- DROP SCHEMA IF EXISTS sa_aki_cohorts;
-- CREATE SCHEMA sa_aki_cohorts;

-- Create the concepts table
\i '/home/hwxu/Projects/Dataset/PKU/KDD/Libs/data/pgsql/concepts.sql'
-- Create the demographics table
\i '/home/hwxu/Projects/Dataset/PKU/KDD/Libs/data/pgsql/demographics.sql'
-- Create the cohorts table
\i '/home/hwxu/Projects/Dataset/PKU/KDD/Libs/data/pgsql/cohorts.sql'
-- Create the measurements table
\i '/home/hwxu/Projects/Dataset/PKU/KDD/Libs/data/pgsql/measurements.sql'
-- Create the vital_signs table
\i '/home/hwxu/Projects/Dataset/PKU/KDD/Libs/data/pgsql/vital_signs.sql'
-- Create the medications table
\i '/home/hwxu/Projects/Dataset/PKU/KDD/Libs/data/pgsql/medications.sql'
-- Create the comorbidities table
\i '/home/hwxu/Projects/Dataset/PKU/KDD/Libs/data/pgsql/comorbidities.sql'
-- Create the outcomes table
\i '/home/hwxu/Projects/Dataset/PKU/KDD/Libs/data/pgsql/outcomes.sql'
-- Copy data from the MIMIC-IV database to the local file system
\COPY (SELECT * FROM sa_aki_cohorts.cohorts ) to '/home/hwxu/Projects/Dataset/PKU/KDD/Input/MIMICIV/raw/cohorts.csv' WITH csv header delimiter ',' encoding 'UTF8'
\COPY (SELECT * FROM sa_aki_cohorts.measurements ) to '/home/hwxu/Projects/Dataset/PKU/KDD/Input/MIMICIV/raw/measurements.csv' WITH csv header delimiter ',' encoding 'UTF8'
\COPY (SELECT * FROM sa_aki_cohorts.vital_signs ) to '/home/hwxu/Projects/Dataset/PKU/KDD/Input/MIMICIV/raw/vital_signs.csv' WITH csv header delimiter ',' encoding 'UTF8'
\COPY (SELECT * FROM sa_aki_cohorts.medications ) to '/home/hwxu/Projects/Dataset/PKU/KDD/Input/MIMICIV/raw/medications.csv' WITH csv header delimiter ',' encoding 'UTF8'
\COPY (SELECT * FROM sa_aki_cohorts.comorbidities ) to '/home/hwxu/Projects/Dataset/PKU/KDD/Input/MIMICIV/raw/comorbidities.csv' WITH csv header delimiter ',' encoding 'UTF8'
\COPY (SELECT * FROM sa_aki_cohorts.outcomes ) to '/home/hwxu/Projects/Dataset/PKU/KDD/Input/MIMICIV/raw/outcomes.csv' WITH csv header delimiter ',' encoding 'UTF8'
