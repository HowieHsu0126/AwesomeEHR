-- 删除旧表（如果存在）
DROP TABLE IF EXISTS public.trauma_treatment CASCADE;

-- 创建新表
CREATE TABLE public.trauma_treatment AS
WITH treatment_flags AS (
  SELECT 
    COALESCE(t.patientunitstayid, p.patientunitstayid) AS patientunitstayid,

    -- 机械通气
    MAX(
      CASE 
        WHEN LOWER(t.treatmentstring) LIKE '%ventilator%' 
          OR LOWER(t.treatmentstring) LIKE '%ventilation%' 
          OR LOWER(t.treatmentstring) LIKE '%intubation%' 
        THEN 1 ELSE 0 
      END
    )::SMALLINT AS ventilation,

    -- 血管活性药物
    MAX(
      CASE 
        WHEN LOWER(t.treatmentstring) LIKE '%norepinephrine%'
          OR LOWER(t.treatmentstring) LIKE '%dopamine%'
          OR LOWER(t.treatmentstring) LIKE '%epinephrine%'
          OR LOWER(t.treatmentstring) LIKE '%phenylephrine%'
          OR LOWER(t.treatmentstring) LIKE '%vasopressin%'
        THEN 1 ELSE 0 
      END
    )::SMALLINT AS vasoactive_agents,

    -- 有创导管
    MAX(
      CASE 
        WHEN LOWER(t.treatmentstring) LIKE '%line%'
          OR LOWER(t.treatmentstring) LIKE '%catheter%'
          OR LOWER(t.treatmentstring) LIKE '%introducer%'
          OR LOWER(t.treatmentstring) LIKE '%iabp%'
          OR LOWER(t.treatmentstring) LIKE '%impella%'
          OR LOWER(t.treatmentstring) LIKE '%portacath%'
          OR LOWER(t.treatmentstring) LIKE '%picc%'
          OR LOWER(t.treatmentstring) LIKE '%sheath%'
        THEN 1 ELSE 0 
      END
    )::SMALLINT AS invasive_lines,

    -- 输血
    MAX(
      CASE 
        WHEN LOWER(t.treatmentstring) LIKE '%transfusion%'
          OR LOWER(t.treatmentstring) LIKE '%blood product%'
          OR LOWER(t.treatmentstring) LIKE '%packed red%'
          OR LOWER(t.treatmentstring) LIKE '%prbc%'
          OR LOWER(t.treatmentstring) LIKE '%ffp%'
          OR LOWER(t.treatmentstring) LIKE '%platelets%'
        THEN 1 ELSE 0 
      END
    )::SMALLINT AS blood_transfusion,

    -- 抗生素
    MAX(
      CASE 
        WHEN LOWER(t.treatmentstring) ~ 'adoxa|ala-tet|alodox|amikacin|amikin|amoxicill|amphotericin|anidulafungin|ancef|clavulanate|ampicillin|augmentin|avelox|azithromycin|aztreonam|cefazolin|ceftazidime|cefepime|ceftriaxone|cephalexin|ciprofloxacin|cipro|clindamycin|doxycycline|erythromycin|flagyl|gentamicin|levaquin|levofloxacin|linezolid|meropenem|metronidazole|minocycline|moxifloxacin|nafcillin|piperacillin|tazobactam|rifampin|rocephin|sulfamethoxazole|trimethoprim|tetracycline|tobramycin|vancomycin|zosyn|zyvox'
        THEN 1 ELSE 0 
      END
    )::SMALLINT AS antibiotic

  FROM public.trauma_patients p
  LEFT JOIN eicu.treatment t 
    ON t.patientunitstayid = p.patientunitstayid
  GROUP BY COALESCE(t.patientunitstayid, p.patientunitstayid)
)

SELECT 
  patientunitstayid,
  ventilation,
  vasoactive_agents,
  invasive_lines,
  blood_transfusion,
  antibiotic
FROM treatment_flags
ORDER BY patientunitstayid;
