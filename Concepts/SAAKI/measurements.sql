-- Drop the table if it exists
DROP TABLE IF EXISTS sa_aki_cohorts.measurements;

-- Create the sa_aki_cohorts.measurements table
CREATE TABLE sa_aki_cohorts.measurements AS
WITH lab_events AS (
    -- Select relevant lab events within 48 hours of AKI diagnosis
    SELECT
        le.subject_id,
        le.hadm_id,
        co.stay_id,
        le.charttime,
        le.itemid,
        le.valuenum,
        co.aki_time
    FROM
        mimiciv_hosp.labevents le
        INNER JOIN sa_aki_cohorts.cohorts co ON le.subject_id = co.subject_id
    WHERE
        le.itemid IN (51301, 51144, 50889, 51006, 50912, 51265, 50862, 50930, 50868, 50802, 50803, 50808, 50806, 50809, 50822, 50824, 50818, 50816, 50813, 51221, 51222, 51275, 51237) -- List of item IDs to include
        AND le.valuenum IS NOT NULL -- Exclude rows with null values
        AND le.charttime BETWEEN co.aki_time AND co.aki_time + INTERVAL '48 hours'
),
gcs AS (
    -- Calculate Glasgow Coma Scale (GCS) score
    SELECT
        gcs.subject_id,
        co.hadm_id,
        gcs.stay_id,
        gcs.charttime,
        gcs.gcs,
        co.aki_time
    FROM
        mimiciv_derived.gcs gcs
        INNER JOIN sa_aki_cohorts.cohorts co ON gcs.subject_id = co.subject_id
    WHERE
        gcs.gcs IS NOT NULL -- Exclude rows with null values
        AND gcs.charttime BETWEEN co.aki_time AND co.aki_time + INTERVAL '48 hours'
),
uo AS (
    -- Calculate Urine Output (UO) measurements
    SELECT
        co.subject_id,
        co.hadm_id,
        uo.stay_id,
        uo.charttime,
        uo.urineoutput,
        co.aki_time
    FROM
        mimiciv_derived.urine_output uo
        INNER JOIN sa_aki_cohorts.cohorts co ON uo.stay_id = co.stay_id
    WHERE
        uo.urineoutput IS NOT NULL -- Exclude rows with null values
        AND uo.charttime BETWEEN co.aki_time AND co.aki_time + INTERVAL '48 hours'
),
hourly_averages AS (
    -- Calculate hourly averages of lab values
    SELECT
        le.subject_id,
        le.hadm_id,
        le.stay_id,
        le.itemid,
        FLOOR(EXTRACT(epoch FROM (le.charttime - le.aki_time)) / 3600) + 1 AS hour_interval, -- Calculate hour interval since AKI diagnosis
        AVG(le.valuenum) AS average_valuenum -- Average lab value for each hour interval
    FROM
        lab_events le
    GROUP BY
        le.subject_id,
        le.hadm_id,
        le.stay_id,
        le.itemid,
        hour_interval
),
pivoted_data AS (
    -- Pivot the data to have separate columns for each itemid
    SELECT
        ha.subject_id,
        ha.hadm_id,
        ha.stay_id,
        ha.hour_interval AS hour,
        MAX(
            CASE WHEN ha.itemid = 51301 THEN
                ha.average_valuenum
            END) AS wbc, -- WBC count
        MAX(
            CASE WHEN ha.itemid = 51144 THEN
                ha.average_valuenum
            END) AS bands_percent, -- Bands percent
        MAX(
            CASE WHEN ha.itemid = 50889 THEN
                ha.average_valuenum
            END) AS c_reactive, -- C-reactive protein
        MAX(
            CASE WHEN ha.itemid = 51006 THEN
                ha.average_valuenum
            END) AS bun, -- Urea nitrogen
        MAX(
            CASE WHEN ha.itemid = 50912 THEN
                ha.average_valuenum
            END) AS cr, -- Creatinine
        MAX(
            CASE WHEN ha.itemid = 51265 THEN
                ha.average_valuenum
            END) AS platelets, -- Platelets
        MAX(
            CASE WHEN ha.itemid = 50862 THEN
                ha.average_valuenum
            END) AS albumin, -- Albumin
        MAX(
            CASE WHEN ha.itemid = 50930 THEN
                ha.average_valuenum
            END) AS globulin, -- Globulin
        MAX(
            CASE WHEN ha.itemid = 50868 THEN
                ha.average_valuenum
            END) AS anion_gap, -- Anion Gap
        MAX(
            CASE WHEN ha.itemid = 50802 THEN
                ha.average_valuenum
            END) AS base_excess, -- Base Excess
        MAX(
            CASE WHEN ha.itemid = 50803 THEN
                ha.average_valuenum
            END) AS bicarb, -- Bicarb
        MAX(
            CASE WHEN ha.itemid = 50808 THEN
                ha.average_valuenum
            END) AS free_calcium, -- Free Calcium
        MAX(
            CASE WHEN ha.itemid = 50806 THEN
                ha.average_valuenum
            END) AS chloride, -- Chloride
        MAX(
            CASE WHEN ha.itemid = 50809 THEN
                ha.average_valuenum
            END) AS glucose, -- Glucose
        MAX(
            CASE WHEN ha.itemid = 50822 THEN
                ha.average_valuenum
            END) AS potassium, -- Potassium
        MAX(
            CASE WHEN ha.itemid = 50824 THEN
                ha.average_valuenum
            END) AS sodium, -- Sodium
        MAX(
            CASE WHEN ha.itemid = 50818 THEN
                ha.average_valuenum
            END) AS pco2, -- pCO2
        MAX(
            CASE WHEN ha.itemid = 50816 THEN
                ha.average_valuenum
            END) AS fio2, -- FiO2
        MAX(
            CASE WHEN ha.itemid = 50813 THEN
                ha.average_valuenum
            END) AS lactate, -- Lactate
        MAX(
            CASE WHEN ha.itemid = 51221 THEN
                ha.average_valuenum
            END) AS hematocrit, -- Hematocrit
        MAX(
            CASE WHEN ha.itemid = 51222 THEN
                ha.average_valuenum
            END) AS hemoglobin, -- Hemoglobin
        MAX(
            CASE WHEN ha.itemid = 51275 THEN
                ha.average_valuenum
            END) AS ptt, -- PTT
        MAX(
            CASE WHEN ha.itemid = 51237 THEN
                ha.average_valuenum
            END) AS inr, -- INR
        MAX(gcs.gcs) AS gcs_score, -- GCS score
        SUM(uo.urineoutput) AS total_urine_output -- Total urine output
    FROM
        hourly_averages ha
        LEFT JOIN gcs ON ha.subject_id = gcs.subject_id
            AND ha.hour_interval = FLOOR(EXTRACT(epoch FROM (gcs.charttime - gcs.aki_time)) / 3600) + 1
        LEFT JOIN uo ON ha.subject_id = uo.subject_id
            AND ha.hour_interval = FLOOR(EXTRACT(epoch FROM (uo.charttime - uo.aki_time)) / 3600) + 1
    GROUP BY
        ha.subject_id,
        ha.hadm_id,
        ha.stay_id,
        ha.hour_interval)
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

-- Order the results by admission_id and hour interval
