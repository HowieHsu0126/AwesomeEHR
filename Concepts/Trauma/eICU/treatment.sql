-- 创建创伤患者治疗信息透视表
DROP TABLE IF EXISTS eicu_crd.trauma_treatment CASCADE;
CREATE TABLE eicu_crd.trauma_treatment AS
WITH tr AS
(
  SELECT t.patientunitstayid
    , t.treatmentoffset as chartoffset
    -- 机械通气
    , MAX(CASE WHEN LOWER(t.treatmentstring) LIKE '%ventilator%' 
            OR LOWER(t.treatmentstring) LIKE '%ventilation%'
            OR LOWER(t.treatmentstring) LIKE '%intubation%'
            THEN 1 ELSE 0 END)::SMALLINT as ventilation
    -- 血管活性药物
    , MAX(CASE WHEN 
        LOWER(t.treatmentstring) LIKE '%norepinephrine%'
        OR LOWER(t.treatmentstring) LIKE '%dopamine%'
        OR LOWER(t.treatmentstring) LIKE '%epinephrine%'
        OR LOWER(t.treatmentstring) LIKE '%phenylephrine%'
        OR LOWER(t.treatmentstring) LIKE '%vasopressin%'
        THEN 1 ELSE 0 END)::SMALLINT as vasoactive_agents
    -- 有创导管
    , MAX(CASE WHEN 
        LOWER(t.treatmentstring) LIKE '%line%'
        OR LOWER(t.treatmentstring) LIKE '%catheter%'
        OR LOWER(t.treatmentstring) LIKE '%introducer%'
        OR LOWER(t.treatmentstring) LIKE '%iabp%'
        OR LOWER(t.treatmentstring) LIKE '%impella%'
        OR LOWER(t.treatmentstring) LIKE '%portacath%'
        OR LOWER(t.treatmentstring) LIKE '%picc%'
        OR LOWER(t.treatmentstring) LIKE '%sheath%'
        THEN 1 ELSE 0 END)::SMALLINT as invasive_lines
    -- 输血
    , MAX(CASE WHEN 
        LOWER(t.treatmentstring) LIKE '%transfusion%'
        OR LOWER(t.treatmentstring) LIKE '%blood product%'
        OR LOWER(t.treatmentstring) LIKE '%packed red%'
        OR LOWER(t.treatmentstring) LIKE '%prbc%'
        OR LOWER(t.treatmentstring) LIKE '%ffp%'
        OR LOWER(t.treatmentstring) LIKE '%platelets%'
        THEN 1 ELSE 0 END)::SMALLINT as blood_transfusion
    -- 抗生素
    , MAX(CASE 
        WHEN LOWER(t.treatmentstring) LIKE '%adoxa%' 
        OR LOWER(t.treatmentstring) LIKE '%ala-tet%'
        OR LOWER(t.treatmentstring) LIKE '%alodox%'
        OR LOWER(t.treatmentstring) LIKE '%amikacin%'
        OR LOWER(t.treatmentstring) LIKE '%amikin%'
        OR LOWER(t.treatmentstring) LIKE '%amoxicill%'
        OR LOWER(t.treatmentstring) LIKE '%amphotericin%'
        OR LOWER(t.treatmentstring) LIKE '%anidulafungin%'
        OR LOWER(t.treatmentstring) LIKE '%ancef%'
        OR LOWER(t.treatmentstring) LIKE '%clavulanate%'
        OR LOWER(t.treatmentstring) LIKE '%ampicillin%'
        OR LOWER(t.treatmentstring) LIKE '%augmentin%'
        OR LOWER(t.treatmentstring) LIKE '%avelox%'
        OR LOWER(t.treatmentstring) LIKE '%azithromycin%'
        OR LOWER(t.treatmentstring) LIKE '%aztreonam%'
        OR LOWER(t.treatmentstring) LIKE '%cefazolin%'
        OR LOWER(t.treatmentstring) LIKE '%ceftazidime%'
        OR LOWER(t.treatmentstring) LIKE '%cefepime%'
        OR LOWER(t.treatmentstring) LIKE '%ceftriaxone%'
        OR LOWER(t.treatmentstring) LIKE '%cephalexin%'
        OR LOWER(t.treatmentstring) LIKE '%ciprofloxacin%'
        OR LOWER(t.treatmentstring) LIKE '%cipro%'
        OR LOWER(t.treatmentstring) LIKE '%clindamycin%'
        OR LOWER(t.treatmentstring) LIKE '%doxycycline%'
        OR LOWER(t.treatmentstring) LIKE '%erythromycin%'
        OR LOWER(t.treatmentstring) LIKE '%flagyl%'
        OR LOWER(t.treatmentstring) LIKE '%gentamicin%'
        OR LOWER(t.treatmentstring) LIKE '%levaquin%'
        OR LOWER(t.treatmentstring) LIKE '%levofloxacin%'
        OR LOWER(t.treatmentstring) LIKE '%linezolid%'
        OR LOWER(t.treatmentstring) LIKE '%meropenem%'
        OR LOWER(t.treatmentstring) LIKE '%metronidazole%'
        OR LOWER(t.treatmentstring) LIKE '%minocycline%'
        OR LOWER(t.treatmentstring) LIKE '%moxifloxacin%'
        OR LOWER(t.treatmentstring) LIKE '%nafcillin%'
        OR LOWER(t.treatmentstring) LIKE '%piperacillin%'
        OR LOWER(t.treatmentstring) LIKE '%tazobactam%'
        OR LOWER(t.treatmentstring) LIKE '%rifampin%'
        OR LOWER(t.treatmentstring) LIKE '%rocephin%'
        OR LOWER(t.treatmentstring) LIKE '%sulfamethoxazole%'
        OR LOWER(t.treatmentstring) LIKE '%trimethoprim%'
        OR LOWER(t.treatmentstring) LIKE '%tetracycline%'
        OR LOWER(t.treatmentstring) LIKE '%tobramycin%'
        OR LOWER(t.treatmentstring) LIKE '%vancomycin%'
        OR LOWER(t.treatmentstring) LIKE '%zosyn%'
        OR LOWER(t.treatmentstring) LIKE '%zyvox%'
        THEN 1 ELSE 0 END)::SMALLINT as antibiotic
  FROM eicu_crd.treatment t
  JOIN eicu_crd.patient p ON t.patientunitstayid = p.patientunitstayid
  JOIN eicu_crd.trauma_patients tp ON p.uniquepid = tp.uniquepid
  GROUP BY t.patientunitstayid, t.treatmentoffset
)
SELECT 
  patientunitstayid
  , chartoffset
  , ventilation
  , vasoactive_agents
  , invasive_lines
  , blood_transfusion
  , antibiotic
FROM tr
WHERE ventilation = 1 
   OR vasoactive_agents = 1 
   OR invasive_lines = 1 
   OR blood_transfusion = 1 
   OR antibiotic = 1
ORDER BY patientunitstayid, chartoffset;
