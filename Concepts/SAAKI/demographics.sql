-- Drop the table if it exists
DROP TABLE IF EXISTS sa_aki_cohorts.demographics;

-- Create the sa_aki_cohorts.demographics table
CREATE TABLE sa_aki_cohorts.demographics AS
WITH calculated_age AS (
    SELECT
        pa.subject_id,
        pa.anchor_year,
        pa.anchor_age,
        EXTRACT(EPOCH FROM (ad.admittime - MAKE_TIMESTAMP(pa.anchor_year, 1, 1, 0, 0, 0))) / 31557600 + pa.anchor_age AS age_in_years
    FROM
        mimiciv_hosp.patients pa
        INNER JOIN mimiciv_hosp.admissions ad ON pa.subject_id = ad.subject_id
)
SELECT DISTINCT
    sa.subject_id,
    sa.hadm_id,
    sa.stay_id,
    FLOOR(ca.age_in_years) AS age, -- Calculate age in years
    pa.gender, -- Get gender
    ad.race, -- Get race
    ad.admission_type -- Get admission type
FROM
    sa_aki_cohorts.sa_aki sa
    INNER JOIN calculated_age ca ON sa.subject_id = ca.subject_id
    INNER JOIN mimiciv_hosp.admissions ad ON sa.subject_id = ad.subject_id
    INNER JOIN mimiciv_hosp.patients pa ON sa.subject_id = pa.subject_id
ORDER BY
    sa.subject_id,
    sa.hadm_id,
    sa.stay_id;
