-- 如果表存在则删除
DROP TABLE IF EXISTS eicu_crd.trauma_demographics;

-- 创建人口统计学特征表
CREATE TABLE eicu_crd.trauma_demographics AS
SELECT DISTINCT 
    tp.uniquepid,
    pt.age,
    CASE WHEN pt.gender = 'Male' THEN 1
         WHEN pt.gender = 'Female' THEN 2
         ELSE NULL END AS gender,
    pt.ethnicity as race
FROM eicu_crd.trauma_patients tp
JOIN eicu_crd.patient pt ON tp.uniquepid = pt.uniquepid;
