-- 目的: 计算患者在ICU入住后7天内的最高肌酐值。
-- 操作: 类似于48小时查询，但此次是在7天的时间范围内进行。最后还计算了最高肌酐值与患者出院时间的时间差。

DROP TABLE IF EXISTS peakcreat7h;
CREATE TABLE peakcreat7h AS
WITH peakcr AS (
  SELECT
    patientunitstayid,
    labresultoffset AS peakcreat7d_offset,
    labresult AS peakcreat7d,
    ROW_NUMBER() OVER (
      PARTITION BY patientunitstayid
      ORDER BY labresult DESC
    ) AS position
  FROM eicu_crd.lab
  WHERE labname LIKE 'creatinine%'
    AND labresultoffset >= 0
    AND labresultoffset <= 10080  -- Within 7 days
  -- Removed GROUP BY as it's not necessary with ROW_NUMBER in this context
)
SELECT
  p.patientunitstayid,
  peakcr.peakcreat7d,
  peakcr.peakcreat7d_offset,
  (p.unitdischargeoffset - peakcr.peakcreat7d_offset) AS peakcreat7d_to_discharge_offsetgap
FROM eicu_crd.patient p
LEFT JOIN peakcr ON p.patientunitstayid = peakcr.patientunitstayid
WHERE peakcr.position = 1  -- Ensuring we're only looking at the first position (highest creatinine)
ORDER BY p.patientunitstayid;
