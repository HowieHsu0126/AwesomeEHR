COPY (
    WITH aki_timepoints AS (
    SELECT
        a.hadm_id,
        a.admittime,
        a.dischtime
        aki.earliest_aki_timepoint AS aki_time
    FROM mimiciv_hosp.admissions a
    INNER JOIN icu_aki aki ON a.hadm_id = aki.hadm_id
),
gcs_final AS (
    SELECT
        ie.hadm_id,
        gcs.stay_id,
        gcs.charttime,
        gcs.GCS,
        ROW_NUMBER() OVER (
            PARTITION BY gcs.stay_id
            ORDER BY gcs.GCS
        ) AS gcs_seq
    FROM mimiciv_derived.gcs gcs
    INNER JOIN mimiciv_icu.icustays ie ON gcs.stay_id = ie.stay_id
    INNER JOIN aki_timepoints at ON ie.hadm_id = at.hadm_id
    WHERE gcs.charttime BETWEEN at.admittime AND aki_time
),
min_gcs AS (
    SELECT
        ie.hadm_id,
        ie.subject_id,
        ie.stay_id,
        gs.charttime,
        gs.GCS
    FROM mimiciv_icu.icustays ie
    LEFT JOIN gcs_final gs ON ie.stay_id = gs.stay_id AND gs.gcs_seq = 1
    INNER JOIN aki_timepoints at ON ie.hadm_id = at.hadm_id
)
SELECT
    mg.hadm_id AS admission_id,
    FLOOR(EXTRACT(epoch FROM (mg.charttime - at.admittime)) / 3600) AS hour,
    -- CASE WHEN mg.GCS < 14 THEN 1 ELSE 0 END AS CNSDys
    mg.GCS
FROM min_gcs mg
INNER JOIN aki_timepoints at ON mg.hadm_id = at.hadm_id
ORDER BY mg.hadm_id, hour
) TO '/home/hwxu/Projects/Dataset/PKU/AMIA/Input/raw/CNSDys.csv' WITH CSV HEADER;

