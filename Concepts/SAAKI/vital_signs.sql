-- Extract lab events related to SA-AKI diagnosis
-- Drop the table if it exists
DROP TABLE IF EXISTS sa_aki_cohorts.vital_signs;

-- Create the vital_signs table
CREATE TABLE sa_aki_cohorts.vital_signs AS
WITH lab_events AS (
    SELECT
        ce.subject_id,
        ce.hadm_id,
        ce.stay_id,
        ce.charttime,
        ce.itemid,
        ce.valuenum,
        co.aki_time
    FROM
        mimiciv_icu.chartevents ce
        INNER JOIN sa_aki_cohorts.cohorts co ON ce.subject_id = co.subject_id
        INNER JOIN mimiciv_hosp.admissions ha ON ce.hadm_id = ha.hadm_id
    WHERE
        ce.itemid IN (223762, 220045, 220210, 225309, 225310, 225312, 220050, 220051, 220052, 220179, 220180, 220181, 220277, 226537) -- List of item IDs
        AND ce.valuenum IS NOT NULL
        AND ce.charttime BETWEEN co.aki_time AND co.aki_time + INTERVAL '48 hours'
),
-- Calculate hourly averages of lab values
hourly_averages AS (
    SELECT
        subject_id,
        hadm_id,
        stay_id,
        itemid,
        FLOOR(EXTRACT(epoch FROM (charttime - aki_time)) / 3600) + 1 AS hour_interval,
        AVG(valuenum) AS average_valuenum
FROM
    lab_events
GROUP BY
    subject_id,
    hadm_id,
    stay_id,
    itemid,
    hour_interval
),
-- Pivot the data to have separate columns for each itemid
pivoted_data AS (
    SELECT
        subject_id,
        hadm_id,
        stay_id,
        hour_interval AS hour,
        MAX(
            CASE WHEN itemid = 223762 THEN
                average_valuenum
            END) AS temperature, -- Temperature
    MAX(
        CASE WHEN itemid = 220045 THEN
            average_valuenum
        END) AS heart_rate, -- Heart rate
    MAX(
        CASE WHEN itemid = 220210 THEN
            average_valuenum
        END) AS respiratory_rate, -- Respiratory rate
    MAX(
        CASE WHEN itemid = 220050 THEN
            average_valuenum
        END) AS arterial_bp_systolic, -- Arterial blood pressure
    MAX(
        CASE WHEN itemid = 220051 THEN
            average_valuenum
        END) AS arterial_bp_diastolic, -- Arterial blood pressure
    MAX(
        CASE WHEN itemid = 220052 THEN
            average_valuenum
        END) AS arterial_bp_mean, -- Arterial blood pressure
    MAX(
        CASE WHEN itemid = 220179 THEN
            average_valuenum
        END) AS non_invasive_bp_systolic, -- Non-invasive blood pressure
    MAX(
        CASE WHEN itemid = 220180 THEN
            average_valuenum
        END) AS non_invasive_bp_diastolic, -- Non-invasive blood pressure
    MAX(
        CASE WHEN itemid = 220181 THEN
            average_valuenum
        END) AS non_invasive_bp_mean, -- Non-invasive blood pressure
    MAX(
        CASE WHEN itemid = 220277 THEN
            average_valuenum
        END) AS spo2_peripheral -- Peripheral oxygen saturation
FROM
    hourly_averages
GROUP BY
    subject_id,
    hadm_id,
    stay_id,
    hour_interval)
-- Select and format the results
SELECT
    *
FROM
    pivoted_data
ORDER BY
    subject_id,
    hadm_id,
    stay_id,
    hour;

