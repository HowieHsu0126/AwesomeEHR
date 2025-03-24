COPY (
WITH lab_events AS (
    SELECT 
        le.hadm_id, 
        a.admittime,
        aki.earliest_aki_timepoint AS aki_time,
        le.charttime, 
        le.itemid, 
        le.valuenum
    FROM mimiciv_hosp.labevents le
    INNER JOIN mimiciv_hosp.admissions a ON le.hadm_id = a.hadm_id
    INNER JOIN icu_aki aki ON a.hadm_id = aki.hadm_id
    WHERE le.itemid = 50862 -- Albumin
    AND le.valuenum IS NOT NULL
    AND le.valuenum > 0
    AND le.charttime BETWEEN a.admittime AND aki_time
),
hourly_averages AS (
    SELECT 
        hadm_id AS admission_id, 
        FLOOR(EXTRACT(epoch FROM (charttime - admittime))/3600) + 1 AS hour, -- 计算自入院以来的小时数，并使小时数从1开始
        AVG(valuenum) AS albumin
        -- MAX(CASE 
        --     WHEN itemid = 50862 AND valuenum < 3.3 THEN 1 ELSE 0 END) AS MalNut
    FROM lab_events
    GROUP BY admission_id, hour
)
SELECT
    admission_id,
    hour,
    albumin
FROM hourly_averages
ORDER BY admission_id, hour
) TO '/home/hwxu/Projects/Dataset/PKU/AMIA/Input/raw/MalNut.csv' WITH CSV HEADER;
