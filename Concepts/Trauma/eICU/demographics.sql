-- 如果表存在则删除
DROP TABLE IF EXISTS public.trauma_patients CASCADE;

-- 创建新表并插入数据
CREATE TABLE public.trauma_patients AS
-- SELECT DISTINCT p.uniquepid
-- FROM eicu.patient p
-- JOIN eicu.admissiondx a ON p.patientunitstayid = a.patientunitstayid
-- WHERE p.unittype IN ('SICU', 'Med-Surg ICU')
-- AND (
--     LOWER(a.admitdxname) LIKE '%trauma%'
--     OR LOWER(a.admitdxname) LIKE '%burn%'
-- );
SELECT DISTINCT p.patientunitstayid
FROM eicu.patient p
JOIN eicu.admissiondx a ON p.patientunitstayid = a.patientunitstayid
WHERE p.unittype IN ('SICU', 'Med-Surg ICU')
AND (
    LOWER(a.admitdxname) LIKE '%trauma%'
    OR LOWER(a.admitdxname) LIKE '%burn%'
)
AND p.unitvisitnumber = 1;




-- 如果表存在则删除
DROP TABLE IF EXISTS public.trauma_demographics;

-- 创建人口统计学特征表
CREATE TABLE public.trauma_demographics AS
SELECT DISTINCT 
    tp.patientunitstayid,
    pt.age,
    CASE WHEN pt.gender = 'Male' THEN 1
         WHEN pt.gender = 'Female' THEN 0
         ELSE NULL END AS gender,
    pt.ethnicity as race
FROM public.trauma_patients tp
JOIN eicu.patient pt ON tp.patientunitstayid = pt.patientunitstayid;
