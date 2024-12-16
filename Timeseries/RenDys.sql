COPY (
WITH lab_events AS (
    SELECT le.hadm_id, le.charttime, le.itemid, le.valuenum,
           ha.admittime, aki.earliest_aki_timepoint AS aki_time
    FROM mimiciv_hosp.labevents le
    INNER JOIN mimiciv_hosp.admissions ha ON le.hadm_id = ha.hadm_id
    INNER JOIN icu_aki aki ON ha.hadm_id = aki.hadm_id
    WHERE le.itemid IN (51006, 50912) -- 尿素氮(BUN) 和 肌酐(Creatinine)
      AND le.valuenum IS NOT NULL
      AND le.valuenum > 0
      AND le.charttime BETWEEN ha.admittime AND aki_time
),
hourly_averages AS (
    SELECT 
        hadm_id AS admission_id,
        FLOOR(EXTRACT(epoch FROM (charttime - admittime))/3600) + 1 AS hour,
        AVG(CASE WHEN itemid = 51006 THEN valuenum END) AS BUN,
        AVG(CASE WHEN itemid = 50912 THEN valuenum END) AS creatinine
    FROM lab_events
    GROUP BY admission_id, hour
)
SELECT admission_id, hour, BUN, creatinine
FROM hourly_averages
ORDER BY admission_id, hour
) TO '/home/hwxu/Projects/Dataset/PKU/AMIA/Input/raw/RenDys.csv' WITH CSV HEADER;
