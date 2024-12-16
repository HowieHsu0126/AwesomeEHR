COPY (
WITH lab_events AS (
    SELECT 
        ie.subject_id
        , ie.hadm_id
        , ie.starttime
        , ie.itemid
        , amount as vaso_amount
        , ha.admittime
        , aki.earliest_aki_timepoint AS aki_time
    FROM mimiciv_icu.inputevents ie
    INNER JOIN mimiciv_hosp.admissions ha ON ie.hadm_id = ha.hadm_id
    INNER JOIN icu_aki aki ON ha.hadm_id = aki.hadm_id
    WHERE ie.itemid IN (
      221653, -- dobutamine
      221289, -- epinephrine
      221906, -- norepinephrine
      221749, -- phenylephrine
      222315 -- vasopressin
      )
      AND ie.starttime BETWEEN ha.admittime AND ha.dischtime
),
hourly_averages AS (
    SELECT
        subject_id,
        hadm_id,
        FLOOR(EXTRACT(epoch FROM (starttime - admittime))/3600) + 1 AS hour_interval,
        itemid,
        AVG(vaso_amount) AS vaso_amount
    FROM lab_events
    GROUP BY subject_id, hadm_id, itemid, hour_interval
)
SELECT
    hadm_id AS admission_id,
    hour_interval AS hour,
    AVG(CASE WHEN itemid = 221653 THEN vaso_amount ELSE NULL END) AS dobutamine,
    AVG(CASE WHEN itemid = 221289 THEN vaso_amount ELSE NULL END) AS epinephrine,
    AVG(CASE WHEN itemid = 221906 THEN vaso_amount ELSE NULL END) AS norepinephrine,
    AVG(CASE WHEN itemid = 221749 THEN vaso_amount ELSE NULL END) AS phenylephrine,
    AVG(CASE WHEN itemid = 222315 THEN vaso_amount ELSE NULL END) AS vasopressin

FROM hourly_averages
GROUP BY hadm_id, subject_id, hour_interval
ORDER BY hadm_id, subject_id, hour_interval
) TO '/home/hwxu/Projects/Dataset/PKU/AMIA/Input/raw/Medication.csv' WITH CSV HEADER;
