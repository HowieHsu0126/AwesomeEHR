-- Drop the table if it exists
DROP TABLE IF EXISTS sa_aki_cohorts.medications;

-- Create the sa_aki_cohorts.medications table
CREATE TABLE sa_aki_cohorts.medications AS
WITH abx AS (
    -- This query extracts antibiotics administered within 48 hours of AKI diagnosis
    SELECT
        co.subject_id,
        co.hadm_id,
        co.stay_id,
        COUNT(abx.antibiotic) > 0 AS received_antibiotic
    FROM
        mimiciv_derived.antibiotic abx
        LEFT JOIN sa_aki_cohorts.cohorts co ON abx.subject_id = co.subject_id
            AND abx.starttime >= co.aki_time
            AND abx.stoptime < co.aki_time + INTERVAL '48 hours'
    GROUP BY
        co.subject_id,
        co.hadm_id,
        co.stay_id
),
ie_med AS (
    -- This query extracts vasopressor doses and durations administered within 48 hours of AKI diagnosis
    SELECT
        co.subject_id,
        co.hadm_id,
        co.stay_id,
        MAX(
            CASE WHEN itemid = 221653 THEN
                1
            ELSE
                0
            END) AS received_dobutamine,
        MAX(
            CASE WHEN itemid = 221662 THEN
                1
            ELSE
                0
            END) AS received_dopamine,
        MAX(
            CASE WHEN itemid = 221289 THEN
                1
            ELSE
                0
            END) AS received_epinephrine,
        MAX(
            CASE WHEN itemid = 221906 THEN
                1
            ELSE
                0
            END) AS received_norepinephrine,
        MAX(
            CASE WHEN itemid = 221749 THEN
                1
            ELSE
                0
            END) AS received_phenylephrine,
        MAX(
            CASE WHEN itemid = 222315 THEN
                1
            ELSE
                0
            END) AS received_vasopressin
    FROM
        mimiciv_icu.inputevents ie
        LEFT JOIN sa_aki_cohorts.cohorts co ON ie.stay_id = co.stay_id
            AND ie.starttime >= co.aki_time
            AND ie.endtime < co.aki_time + INTERVAL '48 hours'
    WHERE
        itemid IN (221653, -- dobutamine
            221662, -- dopamine
            221289, -- epinephrine
            221906, -- norepinephrine
            221749, -- phenylephrine
            222315 -- vasopressin
)
    GROUP BY
        co.subject_id,
        co.hadm_id,
        co.stay_id
),
nmba AS (
    -- This query extracts dose and durations of neuromuscular blocking agents within 48 hours of AKI diagnosis
    SELECT
        co.subject_id,
        co.hadm_id,
        co.stay_id,
        MAX(
            CASE WHEN itemid = 222062 THEN
                1
            ELSE
                0
            END) AS received_vecuronium,
        MAX(
            CASE WHEN itemid = 221555 THEN
                1
            ELSE
                0
            END) AS received_cisatracurium
    FROM
        mimiciv_icu.inputevents ie
        LEFT JOIN sa_aki_cohorts.cohorts co ON ie.stay_id = co.stay_id
            AND ie.starttime >= co.aki_time
            AND ie.endtime < co.aki_time + INTERVAL '48 hours'
    WHERE
        itemid IN (222062, -- Vecuronium
            221555 -- Cisatracurium
)
        AND rate IS NOT NULL -- Only continuous infusions
    GROUP BY
        co.subject_id,
        co.hadm_id,
        co.stay_id)
    -- Combine results from all CTEs
    SELECT
        co.subject_id,
        co.hadm_id,
        co.stay_id,
        COALESCE(abx.received_antibiotic::int, 0) AS received_antibiotic,
    COALESCE(ie.received_dobutamine, 0) AS received_dobutamine,
    COALESCE(ie.received_dopamine, 0) AS received_dopamine,
    COALESCE(ie.received_epinephrine, 0) AS received_epinephrine,
    COALESCE(ie.received_norepinephrine, 0) AS received_norepinephrine,
    COALESCE(ie.received_phenylephrine, 0) AS received_phenylephrine,
    COALESCE(ie.received_vasopressin, 0) AS received_vasopressin,
    COALESCE(nmba.received_vecuronium, 0) AS received_vecuronium,
    COALESCE(nmba.received_cisatracurium, 0) AS received_cisatracurium
FROM
    sa_aki_cohorts.cohorts co
    LEFT JOIN abx ON co.subject_id = abx.subject_id
        AND co.hadm_id = abx.hadm_id
        AND co.stay_id = abx.stay_id
    LEFT JOIN ie_med ie ON co.subject_id = ie.subject_id
        AND co.hadm_id = ie.hadm_id
        AND co.stay_id = ie.stay_id
    LEFT JOIN nmba ON co.subject_id = nmba.subject_id
        AND co.hadm_id = nmba.hadm_id
        AND co.stay_id = nmba.stay_id;

