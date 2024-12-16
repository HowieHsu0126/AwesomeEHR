-- Drop the table if it exists
DROP TABLE IF EXISTS sa_aki_cohorts.sa_aki;

-- Create the sa_aki table
CREATE TABLE sa_aki_cohorts.sa_aki AS
WITH
-- Define a common table expression (CTE) for AKI events
aki AS (
    SELECT
        subject_id,
        hadm_id,
        stay_id,
        MIN(charttime) AS aki_time -- Use the earliest aki_time
    FROM
        mimiciv_derived.kdigo_stages
    WHERE
        aki_stage IS NOT NULL -- Only consider rows with a defined AKI stage
        AND aki_stage != 0
    GROUP BY
        subject_id,
        hadm_id,
        stay_id
),
-- Define a CTE for sepsis events
sepsis AS (
    SELECT
        subject_id,
        stay_id,
        suspected_infection_time AS sepsis_time, -- Rename suspected_infection_time to sepsis_time for clarity
        sofa_time
    FROM
        mimiciv_derived.sepsis3
),
-- Combine AKI and sepsis data, identifying SA-AKI events
sa_aki AS (
    SELECT
        aki.subject_id,
        aki.hadm_id,
        aki.stay_id,
        sepsis.sepsis_time,
        aki.aki_time,
        CASE WHEN aki.aki_time <= sepsis.sepsis_time + INTERVAL '48 hours' THEN
            'early'
        WHEN aki.aki_time > sepsis.sepsis_time + INTERVAL '48 hours'
            AND aki.aki_time <= sepsis.sepsis_time + INTERVAL '7 days' THEN
            'late'
        END AS sa_aki_stage -- Determine if SA-AKI is early or late
    FROM
        aki
        JOIN sepsis ON aki.subject_id = sepsis.subject_id
            AND aki.stay_id = sepsis.stay_id
    WHERE
        aki.aki_time BETWEEN sepsis.sepsis_time AND sepsis.sepsis_time + INTERVAL '7 days' -- Consider AKI events within 7 days of sepsis
)
    -- Select and return the relevant fields from the sa_aki CTE
    SELECT
        subject_id,
        hadm_id,
        stay_id,
        sepsis_time,
        aki_time,
        sa_aki_stage
    FROM
        sa_aki
    WHERE
        sa_aki_stage IS NOT NULL -- Only include rows where SA-AKI stage is determined
    ORDER BY
        subject_id,
        hadm_id,
        stay_id,
        aki_time;

-- Order results for readability
