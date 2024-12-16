-- -- 1. 创建临时表存储ICU住院信息及最大SOFA分数
-- DROP TABLE IF EXISTS temp_icu_sofa;
-- CREATE TEMP TABLE temp_icu_sofa AS
-- SELECT
--     icu.subject_id,
--     icu.stay_id,
--     icu.hadm_id,
--     icu.intime,
--     icu.outtime
--     -- icu.los AS los_icu
--     -- MAX(sofa.sofa_24hours) AS sofamax
-- FROM
--     mimiciv_icu.icustays icu
--     -- INNER JOIN mimiciv_derived.sofa sofa ON icu.stay_id = sofa.stay_id -- 确保使用正确的schema
--     INNER JOIN icu_aki aki ON aki.stay_id = icu.stay_id -- 确保使用正确的schema
-- GROUP BY icu.subject_id, icu.stay_id, icu.hadm_id, icu.intime, icu.outtime, icu.los;

-- -- -- 2. 创建临时表存储病人基本信息
-- -- DROP TABLE IF EXISTS temp_patient_info;
-- -- CREATE TEMP TABLE temp_patient_info AS
-- -- SELECT
-- --     pa.subject_id,
-- --     pa.gender,
-- --     DATE_PART('year', age(ad.admittime, TO_DATE(pa.anchor_year::text, 'YYYY'))) + pa.anchor_age AS admission_age,
-- --     ad.race,
-- --     ad.admittime,
-- --     ad.dischtime,
-- --     pa.dod,
-- --     ad.hospital_expire_flag,
-- --     pa.anchor_year_group
-- -- FROM
-- --     mimiciv_hosp.admissions ad
-- --     INNER JOIN mimiciv_hosp.patients pa ON ad.subject_id = pa.subject_id;

-- -- 3. 创建临时表存储AKI患者的生命体征和实验室结果
-- DROP TABLE IF EXISTS temp_aki_vitals;
-- CREATE TEMP TABLE temp_aki_vitals AS
-- SELECT
--     icu.hadm_id,
--     vs.subject_id,
--     vs.stay_id,
--     vs.charttime,
--     -- vs.heart_rate,
--     -- vs.mbp,
--     -- vs.resp_rate,
--     -- vs.temperature,
--     -- vs.spo2,
--     cr.creat AS creatinine,
--     uo.urineoutput AS urine_output
-- FROM
--     vitalsign vs
--     INNER JOIN creatinine cr ON cr.stay_id = vs.stay_id
--     INNER JOIN mimiciv_derived.urine_output uo ON uo.stay_id = vs.stay_id
--     INNER JOIN temp_icu_sofa icu ON icu.stay_id = vs.stay_id
-- WHERE
--     uo.charttime BETWEEN icu.intime AND icu.outtime
--     AND cr.charttime BETWEEN icu.intime AND icu.outtime;

-- -- 最终查询，结合临时表提取所需信息
-- -- COPY (
-- --     SELECT
-- --         p.*,
-- --         i.*,
-- --         v.*
-- --     FROM
-- --         temp_patient_info p
-- --         INNER JOIN temp_icu_sofa i ON p.subject_id = i.subject_id
-- --         INNER JOIN temp_aki_vitals v ON i.stay_id = v.stay_id
-- -- ) TO '/data/hwxu/GLKong/aki_uo_cr.csv' WITH CSV HEADER;
-- COPY (
--     SELECT
--         v.*
--     FROM temp_aki_vitals v
-- ) TO '/data/hwxu/GLKong/aki_uo_cr.csv' WITH CSV HEADER;
-- 1. 创建临时表存储ICU住院信息
DROP TABLE IF EXISTS temp_icu_sofa;
CREATE TEMP TABLE temp_icu_sofa AS
SELECT
    icu.subject_id,
    icu.stay_id,
    icu.hadm_id,
    icu.intime,
    icu.outtime
FROM
    mimiciv_icu.icustays icu
    INNER JOIN icu_aki aki ON aki.stay_id = icu.stay_id
GROUP BY icu.subject_id, icu.stay_id, icu.hadm_id, icu.intime, icu.outtime;

-- 2. 创建临时表存储AKI患者在ICU期间的肌酐和尿量数据
DROP TABLE IF EXISTS temp_aki_vitals;
CREATE TEMP TABLE temp_aki_vitals AS
SELECT
    icu.hadm_id,
    vs.subject_id,
    vs.stay_id,
    vs.charttime,
    -- cr.creat,
    uo.urineoutput
FROM
    vitalsign vs
    -- INNER JOIN creatinine cr ON cr.stay_id = vs.stay_id
    INNER JOIN mimiciv_derived.urine_output uo ON uo.stay_id = vs.stay_id
    INNER JOIN temp_icu_sofa icu ON icu.stay_id = vs.stay_id
WHERE
    -- uo.charttime BETWEEN icu.intime AND icu.outtime
    -- AND cr.charttime BETWEEN icu.intime AND icu.outtime;
    uo.stay_id = '33897341'
    uo.charttime BETWEEN icu.intime AND icu.outtime;


    

-- 最终导出所需的AKI患者肌酐和尿量数据到CSV文件
COPY (
    SELECT
        v.*
    FROM temp_aki_vitals v
) TO '/data/hwxu/GLKong/aki_uo_cr.csv' WITH CSV HEADER;
