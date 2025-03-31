DROP TABLE IF EXISTS public.trauma_outcomes;
-- 创建trauma患者预后表（每个患者唯一记录）
CREATE TABLE public.trauma_outcomes AS

SELECT 
    t.patientunitstayid,
    -- ICU内死亡
    CASE 
        WHEN p.unitdischargestatus = 'Expired' THEN 1
        ELSE 0
    END AS icu_mortality,
    -- 院内死亡
    CASE 
        WHEN p.hospitaldischargestatus = 'Expired' THEN 1
        ELSE 0
    END AS hospital_mortality
FROM public.trauma_patients t
LEFT JOIN eicu.patient p 
    ON t.patientunitstayid = p.patientunitstayid;
