WITH antibiotic_prescriptions AS (
  SELECT
    pr.subject_id,
    pr.hadm_id,
    ie.stay_id,
    pr.drug AS antibiotic,
    pr.route,
    pr.starttime,
    pr.stoptime,
    aki.earliest_aki_timepoint
  FROM mimiciv_hosp.prescriptions pr
  LEFT JOIN mimiciv_icu.icustays ie ON pr.hadm_id = ie.hadm_id
  INNER JOIN icu_aki aki ON pr.hadm_id = aki.hadm_id
  WHERE pr.drug_type NOT IN ('BASE')
    AND pr.route NOT IN ('OU', 'OS', 'OD', 'AU', 'AS', 'AD', 'TP')
    AND LOWER(pr.route) NOT LIKE '%ear%'
    AND LOWER(pr.route) NOT LIKE '%eye%'
    AND LOWER(pr.drug) NOT LIKE '%cream%'
    AND LOWER(pr.drug) NOT LIKE '%desensitization%'
    AND LOWER(pr.drug) NOT LIKE '%ophth oint%'
    AND LOWER(pr.drug) NOT LIKE '%gel%'
    AND (
      LOWER(pr.drug) LIKE '%adoxa%' OR
      LOWER(pr.drug) LIKE '%ala-tet%'
      -- Add more drugs here following the same pattern
    )
    -- AND pr.starttime >= ie.intime
    -- AND pr.starttime <= aki.earliest_aki_timepoint
)
SELECT
    -- subject_id,
    -- hadm_id,
    stay_id,
    antibiotic,
    route
    -- starttime,
    -- stoptime
FROM antibiotic_prescriptions
ORDER BY subject_id, hadm_id, stay_id, starttime;
