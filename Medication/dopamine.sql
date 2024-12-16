SELECT
    ie.stay_id,
    -- ie.linkorderid,
    ie.rate as vaso_rate,
    ie.amount as vaso_amount
    -- ie.starttime,
    -- ie.endtime
FROM mimiciv_icu.inputevents ie
INNER JOIN icu_aki aki ON ie.stay_id = aki.stay_id
WHERE ie.itemid = 221662 -- dopamine
  AND ie.starttime >= aki.earliest_aki_timepoint
