COPY (
WITH lab_events AS (
    SELECT 
        le.hadm_id,
        le.charttime, 
        le.itemid, 
        le.valuenum,
        ha.admittime,
        aki.earliest_aki_timepoint AS aki_time
    FROM mimiciv_hosp.labevents le
    INNER JOIN mimiciv_hosp.admissions ha ON le.hadm_id = ha.hadm_id
    INNER JOIN icu_aki aki ON ha.hadm_id = aki.hadm_id
    AND le.itemid IN (50822, 50893, 50902) -- Potassium, Calcium, Chloride
    AND le.valuenum IS NOT NULL
    AND le.valuenum > 0
    AND le.charttime BETWEEN ha.admittime AND aki_time
),
hourly_averages AS (
    SELECT 
        hadm_id, 
        FLOOR(EXTRACT(epoch FROM (charttime - admittime))/3600) + 1 AS hour,
        AVG(CASE WHEN itemid = 50822 THEN valuenum ELSE NULL END) AS potassium,
        AVG(CASE WHEN itemid = 50893 THEN valuenum ELSE NULL END) AS calcium,
        AVG(CASE WHEN itemid = 50902 THEN valuenum ELSE NULL END) AS chloride
        -- MAX(CASE 
        --     WHEN itemid = 50822 AND valuenum > 5.0 THEN 1
        --     WHEN itemid = 50893 AND valuenum > 10.5 THEN 1
        --     WHEN itemid = 50902 AND (valuenum < 98 OR valuenum > 106) THEN 1
        --     ELSE 0 END) AS LyteImbal
    FROM lab_events
    GROUP BY hadm_id, hour
)
SELECT 
    hadm_id AS admission_id,
    hour,
    potassium,
    calcium,
    chloride
FROM hourly_averages
ORDER BY admission_id, hour
) TO '/home/hwxu/Projects/Dataset/PKU/AMIA/Input/raw/LyteImbal.csv' WITH CSV HEADER;