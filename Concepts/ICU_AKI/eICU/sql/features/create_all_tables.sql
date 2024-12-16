-- creates all the tables and produces csv files
-- takes a few minutes to run

\i '/home/hwxu/Projects/Dataset/PKU/eICU/sql/release/features/labels.sql'
\i '/home/hwxu/Projects/Dataset/PKU/eICU/sql/release/features/diagnoses.sql'
\i '/home/hwxu/Projects/Dataset/PKU/eICU/sql/release/features/flat_features.sql'
\i '/home/hwxu/Projects/Dataset/PKU/eICU/sql/release/features/timeseries.sql'

-- we need to make sure that we have at least some form of time series for every patient in diagnoses, flat and labels
drop materialized view if exists timeseries_patients cascade;
create materialized view timeseries_patients as
  with repeats as (
    select distinct patientunitstayid
      from timeserieslab
    union
    select distinct patientunitstayid
      from timeseriesresp
    union
    select distinct patientunitstayid
      from timeseriesperiodic
    union
    select distinct patientunitstayid
      from timeseriesaperiodic)
  select distinct patientunitstayid
    from repeats;

\copy (select * from labels as l where l.patientunitstayid in (select * from timeseries_patients)) to '/home/hwxu/Projects/Dataset/PKU/eICU/csv/labels.csv' with csv header
\copy (select * from diagnoses as d where d.patientunitstayid in (select * from timeseries_patients)) to '/home/hwxu/Projects/Dataset/PKU/eICU/csv/diagnoses.csv' with csv header
\copy (select * from flat as f where f.patientunitstayid in (select * from timeseries_patients)) to '/home/hwxu/Projects/Dataset/PKU/eICU/csv/flat_features.csv' with csv header
\copy (select * from timeserieslab) to '/home/hwxu/Projects/Dataset/PKU/eICU/csv/timeserieslab.csv' with csv header
\copy (select * from timeseriesresp) to '/home/hwxu/Projects/Dataset/PKU/eICU/csv/timeseriesresp.csv' with csv header
\copy (select * from timeseriesperiodic) to '/home/hwxu/Projects/Dataset/PKU/eICU/csv/timeseriesperiodic.csv' with csv header
\copy (select * from timeseriesaperiodic) to '/home/hwxu/Projects/Dataset/PKU/eICU/csv/timeseriesaperiodic.csv' with csv header