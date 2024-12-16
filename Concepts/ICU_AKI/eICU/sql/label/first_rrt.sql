-- 目的: 确定患者首次接受替代性肾脏治疗（RRT）的时间点。
-- 操作: 查询treatment表，寻找涉及RRT的记录，并计算每个患者首次接受RRT的时间偏移量。
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
