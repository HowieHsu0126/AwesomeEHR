-- 主要内容：确定患者首次接受肾脏替代治疗(RRT)的时间点
SELECT
  patientunitstayid,
  MIN(treatmentoffset) as first_rrt_offset
FROM
  eicu_crd.treatment
WHERE
  LOWER(treatmentstring) LIKE '%rrt%'
  OR LOWER(treatmentstring) LIKE '%dialysis%'
  OR LOWER(treatmentstring) LIKE '%ultrafiltration%'
  -- Additional conditions for other RRT treatments...
GROUP BY patientunitstayid
