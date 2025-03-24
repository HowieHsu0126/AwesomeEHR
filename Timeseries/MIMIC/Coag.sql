COPY (
WITH lab_events AS (
    SELECT 
        le.subject_id, 
        le.hadm_id, 
        le.charttime, 
        le.itemid, 
        le.valuenum,
        ha.admittime,
        aki.earliest_aki_timepoint AS aki_time
    FROM mimiciv_hosp.labevents le
    INNER JOIN mimiciv_hosp.admissions ha ON le.hadm_id = ha.hadm_id
    INNER JOIN icu_aki aki ON ha.hadm_id = aki.hadm_id
    WHERE le.itemid IN (51196, 51214, 51297, 51237, 51274, 51275)
      AND le.valuenum IS NOT NULL
      AND le.charttime BETWEEN ha.admittime AND aki_time
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
    AVG(CASE WHEN itemid = 51196 THEN average_valuenum ELSE NULL END) AS d_dimer,
    AVG(CASE WHEN itemid = 51214 THEN average_valuenum ELSE NULL END) AS fibrinogen,
    AVG(CASE WHEN itemid = 51297 THEN average_valuenum ELSE NULL END) AS thrombin,
    AVG(CASE WHEN itemid = 51237 THEN average_valuenum ELSE NULL END) AS inr,
    AVG(CASE WHEN itemid = 51274 THEN average_valuenum ELSE NULL END) AS pt,
    AVG(CASE WHEN itemid = 51275 THEN average_valuenum ELSE NULL END) AS ptt
    -- MAX(CASE 
    --         WHEN itemid = 51196 AND average_valuenum > 0.5 THEN 1
    --         WHEN itemid = 51214 AND average_valuenum < 233 THEN 1
    --         WHEN itemid = 51297 AND average_valuenum > 20 THEN 1
    --         WHEN itemid = 51237 AND average_valuenum > 1.5 THEN 1
    --         WHEN itemid = 51274 AND average_valuenum > 13 THEN 1
    --         WHEN itemid = 51275 AND average_valuenum > 35 THEN 1
    --         ELSE 0 END) AS Coag
FROM hourly_averages
GROUP BY hadm_id, subject_id, hour_interval
ORDER BY hadm_id, subject_id, hour_interval
) TO '/home/hwxu/Projects/Dataset/PKU/AMIA/Input/raw/Coag.csv' WITH CSV HEADER;
