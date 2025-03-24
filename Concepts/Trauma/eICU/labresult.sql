-- 如果表存在则删除
DROP TABLE IF EXISTS eicu_crd.trauma_lab;

-- 创建新表并插入数据
CREATE TABLE eicu_crd.trauma_lab AS
WITH first_icu_stay AS (
  -- 获取每个患者最早的ICU住院记录
  SELECT 
    uniquepid,
    patientunitstayid,
    ROW_NUMBER() OVER (
      PARTITION BY uniquepid 
      ORDER BY hospitaladmitoffset, patientunitstayid
    ) as icu_order
  FROM eicu_crd.patient
),
valid_labs AS (
  SELECT 
    lab.patientunitstayid,
    lab.labname,
    lab.labresultoffset,
    lab.labresult,
    ROW_NUMBER() OVER (
      PARTITION BY lab.patientunitstayid, lab.labname, lab.labresultoffset
      ORDER BY lab.labresultrevisedoffset DESC
    ) as rn
  FROM eicu_crd.lab lab
  INNER JOIN first_icu_stay fis
    ON lab.patientunitstayid = fis.patientunitstayid
  INNER JOIN eicu_crd.trauma_patients t 
    ON fis.uniquepid = t.uniquepid
  WHERE 
    fis.icu_order = 1  -- 只选择每个患者最早的ICU记录
    AND lab.labresultoffset <= 1440 AND lab.labresultoffset >= 0
    AND (
      (lab.labname = 'lactate' and lab.labresult >= 0.1 and lab.labresult <= 30)
      OR (lab.labname = 'alkaline phos.' and lab.labresult > 0)
      OR (lab.labname = 'BUN' and lab.labresult >= 1 and lab.labresult <= 280)
      OR (lab.labname = 'calcium' and lab.labresult > 0 and lab.labresult <= 9999)
      OR (lab.labname = 'platelets x 1000' and lab.labresult > 0 and lab.labresult <= 9999)
      OR (lab.labname = 'WBC x 1000' and lab.labresult > 0 and lab.labresult <= 100)
    )
)
SELECT 
  p.uniquepid,
  vl.patientunitstayid,
  MIN(CASE WHEN labname = 'lactate' THEN labresult ELSE NULL END) as lactate_min,
  MAX(CASE WHEN labname = 'lactate' THEN labresult ELSE NULL END) as lactate_max,
  MIN(CASE WHEN labname = 'alkaline phos.' THEN labresult ELSE NULL END) as alp_min,
  MAX(CASE WHEN labname = 'alkaline phos.' THEN labresult ELSE NULL END) as alp_max,
  MIN(CASE WHEN labname = 'BUN' THEN labresult ELSE NULL END) as bun_min,
  MAX(CASE WHEN labname = 'BUN' THEN labresult ELSE NULL END) as bun_max,
  MIN(CASE WHEN labname = 'calcium' THEN labresult ELSE NULL END) as calcium_min,
  MAX(CASE WHEN labname = 'calcium' THEN labresult ELSE NULL END) as calcium_max,
  MIN(CASE WHEN labname = 'platelets x 1000' THEN labresult ELSE NULL END) as platelet_count_min,
  MAX(CASE WHEN labname = 'platelets x 1000' THEN labresult ELSE NULL END) as platelet_count_max,
  MIN(CASE WHEN labname = 'WBC x 1000' THEN labresult ELSE NULL END) as wbc_min,
  MAX(CASE WHEN labname = 'WBC x 1000' THEN labresult ELSE NULL END) as wbc_max
FROM valid_labs vl
JOIN eicu_crd.patient p 
  ON vl.patientunitstayid = p.patientunitstayid
WHERE vl.rn = 1
GROUP BY p.uniquepid, vl.patientunitstayid
ORDER BY p.uniquepid, vl.patientunitstayid;
