-- 删除旧表
DROP TABLE IF EXISTS public.trauma_lab;

-- 创建新表并插入数据（确保所有创伤患者保留）
CREATE TABLE public.trauma_lab AS
WITH filtered_labs AS (
  SELECT 
    lab.patientunitstayid,
    LOWER(lab.labname) AS labname,
    lab.labresult
  FROM eicu_crd.lab lab
  WHERE lab.labresultoffset BETWEEN 0 AND 1440
    AND LOWER(lab.labname) IN (
      'lactate',
      'paco2',
      'ph',
      'absolute monocyte count',
      'alkaline phos.',
      'bun',
      'calcium',
      'fibrinogen',
      'platelets x 1000',
      'wbc x 1000'
    )
)

SELECT
  tp.patientunitstayid,

  -- Lactate
  MIN(CASE WHEN fl.labname = 'lactate' THEN fl.labresult END) AS lactate_min,
  MAX(CASE WHEN fl.labname = 'lactate' THEN fl.labresult END) AS lactate_max,

  -- PCO₂
  MIN(CASE WHEN fl.labname = 'pco2' THEN fl.labresult END) AS pco2_min,
  MAX(CASE WHEN fl.labname = 'pco2' THEN fl.labresult END) AS pco2_max,

  -- pH
  MIN(CASE WHEN fl.labname = 'ph' THEN fl.labresult END) AS ph_min,
  MAX(CASE WHEN fl.labname = 'ph' THEN fl.labresult END) AS ph_max,

  -- Absolute Monocyte Count
  MIN(CASE WHEN fl.labname = 'absolute monocyte count' THEN fl.labresult END) AS abs_monocyte_min,
  MAX(CASE WHEN fl.labname = 'absolute monocyte count' THEN fl.labresult END) AS abs_monocyte_max,

  -- ALP
  MIN(CASE WHEN fl.labname = 'alkaline phos.' THEN fl.labresult END) AS alp_min,
  MAX(CASE WHEN fl.labname = 'alkaline phos.' THEN fl.labresult END) AS alp_max,

  -- BUN
  MIN(CASE WHEN fl.labname = 'bun' THEN fl.labresult END) AS bun_min,
  MAX(CASE WHEN fl.labname = 'bun' THEN fl.labresult END) AS bun_max,

  -- Calcium
  MIN(CASE WHEN fl.labname = 'calcium' THEN fl.labresult END) AS calcium_min,
  MAX(CASE WHEN fl.labname = 'calcium' THEN fl.labresult END) AS calcium_max,

  -- Fibrinogen
  MIN(CASE WHEN fl.labname = 'fibrinogen' THEN fl.labresult END) AS fibrinogen_min,
  MAX(CASE WHEN fl.labname = 'fibrinogen' THEN fl.labresult END) AS fibrinogen_max,

  -- Platelets
  MIN(CASE WHEN fl.labname = 'platelets x 1000' THEN fl.labresult END) AS platelet_min,
  MAX(CASE WHEN fl.labname = 'platelets x 1000' THEN fl.labresult END) AS platelet_max,

  -- WBC
  MIN(CASE WHEN fl.labname = 'wbc x 1000' THEN fl.labresult END) AS wbc_min,
  MAX(CASE WHEN fl.labname = 'wbc x 1000' THEN fl.labresult END) AS wbc_max

FROM public.trauma_patients tp
LEFT JOIN filtered_labs fl ON tp.patientunitstayid = fl.patientunitstayid
GROUP BY tp.patientunitstayid
ORDER BY tp.patientunitstayid;
