-- 如果表存在则删除
DROP TABLE IF EXISTS eicu_crd.trauma_vital_signs;

-- 创建生命体征表
CREATE TABLE eicu_crd.trauma_vital_signs AS
WITH vital_signs AS (
    SELECT 
        p.uniquepid,
        n.patientunitstayid,
        n.nursingchartoffset,
        -- 心率
        CASE
            WHEN nursingchartcelltypevallabel = 'Heart Rate'
            AND nursingchartcelltypevalname = 'Heart Rate'
            AND nursingchartvalue ~ '^[-]?[0-9]+[.]?[0-9]*$'
            AND nursingchartvalue NOT IN ('-','.')
            THEN CAST(nursingchartvalue AS numeric)
        ELSE NULL END AS heartrate,
        -- 呼吸频率
        CASE
            WHEN nursingchartcelltypevallabel = 'Respiratory Rate'
            AND nursingchartcelltypevalname = 'Respiratory Rate'
            AND nursingchartvalue ~ '^[-]?[0-9]+[.]?[0-9]*$'
            AND nursingchartvalue NOT IN ('-','.')
            THEN CAST(nursingchartvalue AS numeric)
        ELSE NULL END AS respiratoryrate,
        -- 血氧饱和度
        CASE
            WHEN nursingchartcelltypevallabel = 'O2 Saturation'
            AND nursingchartcelltypevalname = 'O2 Saturation'
            AND nursingchartvalue ~ '^[-]?[0-9]+[.]?[0-9]*$'
            AND nursingchartvalue NOT IN ('-','.')
            THEN CAST(nursingchartvalue AS numeric)
        ELSE NULL END AS o2saturation,
        -- 平均动脉压
        CASE
            WHEN nursingchartcelltypevallabel = 'Non-Invasive BP'
            AND nursingchartcelltypevalname = 'Non-Invasive BP Mean'
            AND nursingchartvalue ~ '^[-]?[0-9]+[.]?[0-9]*$'
            AND nursingchartvalue NOT IN ('-','.')
            THEN CAST(nursingchartvalue AS numeric)
        ELSE NULL END AS mean_bp,
        -- 体温
        CASE
            WHEN nursingchartcelltypevallabel = 'Temperature'
            AND nursingchartcelltypevalname = 'Temperature (C)'
            AND nursingchartvalue ~ '^[-]?[0-9]+[.]?[0-9]*$'
            AND nursingchartvalue NOT IN ('-','.')
            THEN CAST(nursingchartvalue AS numeric)
        ELSE NULL END AS temperature
    FROM eicu_crd.trauma_patients tp
    JOIN eicu_crd.patient p ON tp.uniquepid = p.uniquepid
    JOIN eicu_crd.nursecharting n ON p.patientunitstayid = n.patientunitstayid
    WHERE n.nursingchartcelltypecat = 'Vital Signs'
    AND n.nursingchartoffset >= 0 
    AND n.nursingchartoffset <= 480 -- 8小时
)
SELECT 
    uniquepid,
    -- 0-1小时
    AVG(CASE WHEN nursingchartoffset BETWEEN 0 AND 60 THEN heartrate END) as hr_0_1,
    AVG(CASE WHEN nursingchartoffset BETWEEN 0 AND 60 THEN o2saturation END) as spo2_0_1,
    AVG(CASE WHEN nursingchartoffset BETWEEN 0 AND 60 THEN mean_bp END) as mbp_0_1,
    AVG(CASE WHEN nursingchartoffset BETWEEN 0 AND 60 THEN respiratoryrate END) as rr_0_1,
    AVG(CASE WHEN nursingchartoffset BETWEEN 0 AND 60 THEN temperature END) as temp_0_1,
    -- 1-2小时
    AVG(CASE WHEN nursingchartoffset BETWEEN 61 AND 120 THEN heartrate END) as hr_1_2,
    AVG(CASE WHEN nursingchartoffset BETWEEN 61 AND 120 THEN o2saturation END) as spo2_1_2,
    AVG(CASE WHEN nursingchartoffset BETWEEN 61 AND 120 THEN mean_bp END) as mbp_1_2,
    AVG(CASE WHEN nursingchartoffset BETWEEN 61 AND 120 THEN respiratoryrate END) as rr_1_2,
    AVG(CASE WHEN nursingchartoffset BETWEEN 61 AND 120 THEN temperature END) as temp_1_2,
    -- 2-3小时
    AVG(CASE WHEN nursingchartoffset BETWEEN 121 AND 180 THEN heartrate END) as hr_2_3,
    AVG(CASE WHEN nursingchartoffset BETWEEN 121 AND 180 THEN o2saturation END) as spo2_2_3,
    AVG(CASE WHEN nursingchartoffset BETWEEN 121 AND 180 THEN mean_bp END) as mbp_2_3,
    AVG(CASE WHEN nursingchartoffset BETWEEN 121 AND 180 THEN respiratoryrate END) as rr_2_3,
    AVG(CASE WHEN nursingchartoffset BETWEEN 121 AND 180 THEN temperature END) as temp_2_3,
    -- 3-4小时
    AVG(CASE WHEN nursingchartoffset BETWEEN 181 AND 240 THEN heartrate END) as hr_3_4,
    AVG(CASE WHEN nursingchartoffset BETWEEN 181 AND 240 THEN o2saturation END) as spo2_3_4,
    AVG(CASE WHEN nursingchartoffset BETWEEN 181 AND 240 THEN mean_bp END) as mbp_3_4,
    AVG(CASE WHEN nursingchartoffset BETWEEN 181 AND 240 THEN respiratoryrate END) as rr_3_4,
    AVG(CASE WHEN nursingchartoffset BETWEEN 181 AND 240 THEN temperature END) as temp_3_4,
    -- 4-5小时
    AVG(CASE WHEN nursingchartoffset BETWEEN 241 AND 300 THEN heartrate END) as hr_4_5,
    AVG(CASE WHEN nursingchartoffset BETWEEN 241 AND 300 THEN o2saturation END) as spo2_4_5,
    AVG(CASE WHEN nursingchartoffset BETWEEN 241 AND 300 THEN mean_bp END) as mbp_4_5,
    AVG(CASE WHEN nursingchartoffset BETWEEN 241 AND 300 THEN respiratoryrate END) as rr_4_5,
    AVG(CASE WHEN nursingchartoffset BETWEEN 241 AND 300 THEN temperature END) as temp_4_5,
    -- 5-6小时
    AVG(CASE WHEN nursingchartoffset BETWEEN 301 AND 360 THEN heartrate END) as hr_5_6,
    AVG(CASE WHEN nursingchartoffset BETWEEN 301 AND 360 THEN o2saturation END) as spo2_5_6,
    AVG(CASE WHEN nursingchartoffset BETWEEN 301 AND 360 THEN mean_bp END) as mbp_5_6,
    AVG(CASE WHEN nursingchartoffset BETWEEN 301 AND 360 THEN respiratoryrate END) as rr_5_6,
    AVG(CASE WHEN nursingchartoffset BETWEEN 301 AND 360 THEN temperature END) as temp_5_6,
    -- 6-7小时
    AVG(CASE WHEN nursingchartoffset BETWEEN 361 AND 420 THEN heartrate END) as hr_6_7,
    AVG(CASE WHEN nursingchartoffset BETWEEN 361 AND 420 THEN o2saturation END) as spo2_6_7,
    AVG(CASE WHEN nursingchartoffset BETWEEN 361 AND 420 THEN mean_bp END) as mbp_6_7,
    AVG(CASE WHEN nursingchartoffset BETWEEN 361 AND 420 THEN respiratoryrate END) as rr_6_7,
    AVG(CASE WHEN nursingchartoffset BETWEEN 361 AND 420 THEN temperature END) as temp_6_7,
    -- 7-8小时
    AVG(CASE WHEN nursingchartoffset BETWEEN 421 AND 480 THEN heartrate END) as hr_7_8,
    AVG(CASE WHEN nursingchartoffset BETWEEN 421 AND 480 THEN o2saturation END) as spo2_7_8,
    AVG(CASE WHEN nursingchartoffset BETWEEN 421 AND 480 THEN mean_bp END) as mbp_7_8,
    AVG(CASE WHEN nursingchartoffset BETWEEN 421 AND 480 THEN respiratoryrate END) as rr_7_8,
    AVG(CASE WHEN nursingchartoffset BETWEEN 421 AND 480 THEN temperature END) as temp_7_8
FROM vital_signs
WHERE heartrate IS NOT NULL
   OR respiratoryrate IS NOT NULL
   OR o2saturation IS NOT NULL
   OR mean_bp IS NOT NULL
   OR temperature IS NOT NULL
GROUP BY uniquepid;