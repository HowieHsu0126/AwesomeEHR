-- Assumption: The 'aki_cr' and 'aki_uo' tables have been defined earlier as per the provided scripts
-- and include the AKI occurrence time points.

CREATE OR REPLACE FUNCTION DATETIME_SUB(datetime_val TIMESTAMP(3), intvl INTERVAL) RETURNS TIMESTAMP(3) AS $$
BEGIN
    RETURN datetime_val - intvl;
END; $$
LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION DATETIME_DIFF(endtime TIMESTAMP(3), starttime TIMESTAMP(3), datepart TEXT) RETURNS NUMERIC AS $$
BEGIN
    RETURN 
        EXTRACT(EPOCH FROM endtime - starttime) /
        CASE
            WHEN datepart = 'SECOND' THEN 1.0
            WHEN datepart = 'MINUTE' THEN 60.0
            WHEN datepart = 'HOUR' THEN 3600.0
            WHEN datepart = 'DAY' THEN 24*3600.0
            WHEN datepart = 'YEAR' THEN 365.242*24*3600.0
        ELSE NULL END;
END; $$
LANGUAGE PLPGSQL;

DROP TABLE IF EXISTS aki_final;
CREATE TABLE aki_final AS
-- Identify patients who started RRT before ICU admission
WITH pre_icu_rrt AS (
    SELECT
        crrt.stay_id
        , MIN(crrt.charttime) AS first_crrt_time
    FROM mimiciv_derived.crrt crrt
    WHERE crrt.crrt_mode IS NOT NULL
    GROUP BY crrt.stay_id
)

-- Combine AKI status and time points based on creatinine, urine output, and RRT
, combined_aki AS (
    SELECT
        cr.stay_id
        , MAX(cr.aki_status) AS aki_status_cr -- Using MAX to ensure one record per stay_id
        , MAX(cr.aki_timepoint) AS aki_timepoint_cr -- Assumed aki_timepoint column from aki_cr
        , MAX(uo.aki_status) AS aki_status_uo -- Using MAX for the same reason
        , MAX(uo.aki_timepoint) AS aki_timepoint_uo -- Assumed aki_timepoint column from aki_uo
        , MAX(rrt.first_crrt_time) AS rrt_timepoint -- RRT timepoint
    FROM aki_cr cr
    LEFT JOIN aki_uo uo ON cr.stay_id = uo.stay_id
    LEFT JOIN pre_icu_rrt rrt ON cr.stay_id = rrt.stay_id
    GROUP BY cr.stay_id -- Ensuring one record per stay_id
)

SELECT
    stay_id
    , CASE 
        WHEN (aki_status_cr = 'AKI' OR aki_status_uo = 'AKI') AND rrt_timepoint IS NULL
        THEN 'ICU Acquired AKI'
        ELSE 'No ICU Acquired AKI'
      END AS final_aki_status
    , LEAST(
        COALESCE(aki_timepoint_cr, '9999-12-31'), 
        COALESCE(aki_timepoint_uo, '9999-12-31'), 
        COALESCE(rrt_timepoint, '9999-12-31')
      ) AS earliest_aki_timepoint -- Selects the earliest AKI timepoint
FROM combined_aki;