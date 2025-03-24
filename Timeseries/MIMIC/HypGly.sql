COPY (
WITH lab_events AS (
    SELECT 
        ce.subject_id, 
        ce.hadm_id, 
        ce.charttime, 
        ce.itemid, 
        ce.valuenum,
        ha.admittime,
        aki.earliest_aki_timepoint AS aki_time
    FROM mimiciv_icu.chartevents ce
    INNER JOIN mimiciv_hosp.admissions ha ON ce.hadm_id = ha.hadm_id
    INNER JOIN icu_aki aki ON ha.hadm_id = aki.hadm_id
    WHERE ce.itemid IN (226537)
      AND ce.valuenum IS NOT NULL
      AND ce.charttime BETWEEN ha.admittime AND aki_time
),
hourly_averages AS (
    SELECT
        subject_id,
        hadm_id,
        FLOOR(EXTRACT(epoch FROM (charttime - admittime))/3600) + 1 AS hour_interval,
        itemid,
        AVG(valuenum) AS average_valuenum
    FROM lab_events
    GROUP BY subject_id, hadm_id, itemid, hour_interval
)
SELECT
    hadm_id AS admission_id,
    hour_interval AS hour,
    AVG(CASE WHEN itemid = 226537 THEN average_valuenum ELSE NULL END) AS glucose
    -- MAX(CASE WHEN itemid = 226537 AND average_valuenum > 125 THEN 1 ELSE 0 END) AS HypGly
FROM hourly_averages
GROUP BY hadm_id, subject_id, hour_interval
ORDER BY hadm_id, subject_id, hour_interval
) TO '/home/hwxu/Projects/Dataset/PKU/AMIA/Input/raw/HypGly.csv' WITH CSV HEADER;
