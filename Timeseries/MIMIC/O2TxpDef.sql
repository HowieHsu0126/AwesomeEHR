COPY (
WITH hospital_admissions AS (
    SELECT 
        ha.hadm_id, 
        ha.admittime, 
        ha.dischtime, 
        aki.earliest_aki_timepoint AS aki_time
    FROM mimiciv_hosp.admissions ha
    INNER JOIN icu_aki aki ON ha.hadm_id = aki.hadm_id
    WHERE aki.final_aki_status = 'ICU Acquired AKI'
),
lab_events AS (
    SELECT 
        le.hadm_id, 
        ha.admittime, 
        le.charttime, 
        le.itemid, 
        le.valuenum
    FROM mimiciv_hosp.labevents le
    INNER JOIN hospital_admissions ha ON le.hadm_id = ha.hadm_id
    WHERE le.itemid IN (50811) -- Hemoglobin
      AND le.valuenum IS NOT NULL
      AND le.charttime BETWEEN ha.admittime AND aki_time
      AND (le.valuenum > 0 OR le.itemid = 50811) -- 特殊处理Anion Gap
),
hourly_averages AS (
    SELECT 
        hadm_id AS admission_id,
        FLOOR(EXTRACT(epoch FROM (charttime - admittime))/3600) + 1 AS hour, -- 计算从入院开始的小时数
        AVG(CASE WHEN itemid = 50811 THEN valuenum ELSE NULL END) AS hemoglobin
        -- MAX(CASE WHEN itemid = 50811 AND valuenum < 12.0 THEN 1 ELSE 0 END) AS O2TxpDef
    FROM lab_events
    GROUP BY admission_id, hour
)
SELECT
    admission_id,
    hour,
    hemoglobin
FROM hourly_averages
ORDER BY admission_id, hour
) TO '/home/hwxu/Projects/Dataset/PKU/AMIA/Input/raw/O2TxpDef.csv' WITH CSV HEADER;
