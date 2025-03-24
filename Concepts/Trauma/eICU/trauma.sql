-- 如果表存在则删除
DROP TABLE IF EXISTS eicu_crd.trauma_patients CASCADE;

-- 创建新表并插入数据
CREATE TABLE eicu_crd.trauma_patients AS
SELECT DISTINCT p.uniquepid
FROM eicu_crd.patient p
JOIN eicu_crd.admissiondx a ON p.patientunitstayid = a.patientunitstayid
WHERE p.unittype IN ('SICU', 'Med-Surg ICU')
AND (
    LOWER(a.admitdxname) LIKE '%trauma%'
    OR LOWER(a.admitdxname) LIKE '%burn%'
);