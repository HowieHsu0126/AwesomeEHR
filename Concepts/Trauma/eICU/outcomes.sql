DROP TABLE IF EXISTS eicu_crd.trauma_outcomes;
-- 创建trauma患者预后表（每个患者唯一记录）
CREATE TABLE eicu_crd.trauma_outcomes AS
WITH last_stay AS (
    SELECT 
        uniquepid,
        MAX(patientunitstayid) as last_patientunitstayid
    FROM eicu_crd.patient
    GROUP BY uniquepid
)
SELECT 
    t.uniquepid,
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
FROM eicu_crd.trauma_patients t
LEFT JOIN last_stay ls 
    ON t.uniquepid = ls.uniquepid
LEFT JOIN eicu_crd.patient p 
    ON ls.last_patientunitstayid = p.patientunitstayid;
