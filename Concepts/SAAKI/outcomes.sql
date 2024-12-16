-- Drop the table if it exists
DROP TABLE IF EXISTS sa_aki_cohorts.outcomes;

-- Create the sa_aki_cohorts.outcomes table
CREATE TABLE sa_aki_cohorts.outcomes AS
-- Calculate outcomes for SA-AKI patients
WITH readmissions AS (
    SELECT
        ad.subject_id,
        ad.hadm_id,
        LEAD(ad.admittime, 1) OVER (PARTITION BY ad.subject_id ORDER BY ad.admittime
) AS next_admittime
    FROM
        mimiciv_hosp.admissions ad
),
icu_stays AS (
SELECT
    icu.subject_id,
    icu.hadm_id,
    SUM(EXTRACT(EPOCH FROM (icu.outtime - icu.intime)) / 86400
) AS los_icu, -- Calculate ICU length of stay in days
    MAX(
    CASE WHEN pa.dod BETWEEN icu.intime AND icu.outtime THEN
        1
    ELSE
        0
    END
) AS is_deceased_icu -- Check if died in ICU
FROM
    mimiciv_icu.icustays icu
    LEFT JOIN mimiciv_hosp.patients pa ON icu.subject_id = pa.subject_id
GROUP BY
    icu.subject_id,
    icu.hadm_id
),
outcomes AS (
SELECT
    co.subject_id,
    co.hadm_id,
    co.stay_id,
    ad.admittime,
    ad.dischtime,
(pa.dod IS NOT NULL AND pa.dod BETWEEN ad.admittime AND ad.dischtime
) AS is_deceased_hosp, -- Check if the patient died during this admission
    EXTRACT(EPOCH FROM (ad.dischtime - ad.admittime)) / 86400 AS los_hosp, -- Calculate hospital length of stay in days
(r.next_admittime IS NOT NULL AND r.next_admittime <= ad.dischtime + interval '30 days'
) AS readmitted_30d, -- Check if readmitted within 30 days
    icu.los_icu, -- Include ICU length of stay
    icu.is_deceased_icu -- Include ICU death status
FROM
    sa_aki_cohorts.cohorts co
    INNER JOIN mimiciv_hosp.admissions ad ON co.subject_id = ad.subject_id AND co.hadm_id = ad.hadm_id
    LEFT JOIN readmissions r ON ad.subject_id = r.subject_id AND ad.hadm_id = r.hadm_id
    LEFT JOIN mimiciv_hosp.patients pa ON co.subject_id = pa.subject_id
        LEFT JOIN icu_stays icu ON co.subject_id = icu.subject_id AND co.hadm_id = icu.hadm_id)
            -- Select the final outcomes
            SELECT
                subject_id, hadm_id, stay_id, is_deceased_hosp, is_deceased_icu, los_hosp, los_icu, readmitted_30d
            FROM
                outcomes
            ORDER BY
                subject_id, hadm_id, stay_id;

-- Order results for readability
