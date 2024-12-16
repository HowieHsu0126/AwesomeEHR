-- Drop the table if it exists
-- If the table 'comorbidities' already exists in the 'sa_aki_cohorts' schema, drop it to avoid conflicts when creating a new one.
DROP TABLE IF EXISTS sa_aki_cohorts.comorbidities;

-- Create the comorbidities table
-- Create a new table 'comorbidities' in the 'sa_aki_cohorts' schema to store the comorbidity information for SA-AKI patients.
CREATE TABLE sa_aki_cohorts.comorbidities AS
SELECT
    -- Select the subject ID, hospital admission ID, and stay ID from the cohorts table
    co.subject_id,
    co.hadm_id,
    co.stay_id,
    -- Select the required comorbidity indicators from the Charlson table
    ch.myocardial_infarct,
    ch.congestive_heart_failure,
    ch.peripheral_vascular_disease,
    ch.cerebrovascular_disease,
    ch.dementia,
    ch.chronic_pulmonary_disease,
    ch.rheumatic_disease,
    ch.peptic_ulcer_disease,
    ch.mild_liver_disease,
    ch.diabetes_without_cc,
    ch.diabetes_with_cc,
    ch.paraplegia,
    ch.renal_disease,
    ch.malignant_cancer,
    ch.severe_liver_disease,
    ch.metastatic_solid_tumor,
    ch.aids
    -- Select the SAPS II score from the SAPSII table
    -- , sap.sapsii
    -- Join the 'cohorts' and 'charlson' tables on subject ID and hospital admission ID
FROM
    sa_aki_cohorts.cohorts co
    LEFT JOIN mimiciv_derived.charlson ch ON co.subject_id = ch.subject_id
        AND co.hadm_id = ch.hadm_id
        -- Join the 'cohorts' and 'sapsii' tables on subject ID and hospital admission ID
        -- LEFT JOIN mimiciv_derived.sapsii sap
        -- ON co.subject_id = sap.subject_id
        -- AND co.hadm_id = sap.hadm_id
        -- WHERE sap.starttime > co.aki_time AND sap.endtime < co.aki_time + interval '48 hours'
;

