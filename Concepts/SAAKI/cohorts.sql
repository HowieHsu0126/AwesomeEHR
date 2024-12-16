-- Drop the table if it exists
DROP TABLE IF EXISTS sa_aki_cohorts.cohorts;

-- Create the cohorts table
CREATE TABLE sa_aki_cohorts.cohorts AS
WITH eligible_patients AS (
    SELECT
        sa.subject_id,
        sa.hadm_id,
        sa.stay_id,
        sa.sepsis_time,
        sa.aki_time,
        sa.sa_aki_stage,
        d.age,
        d.gender,
        d.race,
        d.admission_type,
        ad.admittime,
        ad.dischtime
    FROM
        sa_aki_cohorts.sa_aki sa
        JOIN sa_aki_cohorts.demographics d ON sa.subject_id = d.subject_id
        JOIN mimiciv_hosp.admissions ad ON sa.subject_id = ad.subject_id
    WHERE
        d.age BETWEEN 18 AND 89 -- Age filter
        AND EXTRACT(EPOCH FROM (ad.dischtime - ad.admittime)) >= 86400 -- Stay duration filter (at least 24 hours)
),
-- Filter out patients with ESKD
non_eskd_patients AS (
    SELECT
        ep.subject_id,
        ep.hadm_id,
        ep.stay_id,
        ep.sepsis_time,
        ep.aki_time,
        ep.sa_aki_stage,
        ep.age,
        ep.gender,
        ep.race,
        ep.admission_type
    FROM
        eligible_patients ep
        LEFT JOIN ( SELECT DISTINCT
                subject_id,
                hadm_id
            FROM
                mimiciv_hosp.diagnoses_icd
            WHERE
                icd_code IN ('N18.6', '585.6') -- ICD codes for ESKD
) eskd ON ep.subject_id = eskd.subject_id
        WHERE
            eskd.subject_id IS NULL -- Exclude patients with ESKD
),
-- Add row numbers to each patient's records
numbered_patients AS (
    SELECT
        nesp.subject_id,
        nesp.hadm_id,
        nesp.stay_id,
        nesp.sepsis_time,
        nesp.aki_time,
        nesp.sa_aki_stage,
        nesp.age,
        nesp.gender,
        nesp.race,
        nesp.admission_type,
        ROW_NUMBER() OVER (PARTITION BY nesp.subject_id ORDER BY nesp.aki_time) AS rn
FROM
    non_eskd_patients nesp)
-- Select the first row for each patient
SELECT
    np.subject_id,
    np.hadm_id,
    np.stay_id,
    np.sepsis_time,
    np.aki_time,
    np.sa_aki_stage,
    np.age,
    np.gender,
    np.race,
    np.admission_type
FROM
    numbered_patients np
WHERE
    np.rn = 1
ORDER BY
    np.subject_id,
    np.hadm_id,
    np.stay_id,
    np.aki_time;

