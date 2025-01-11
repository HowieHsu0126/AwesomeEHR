-- 删除已存在的 patient_weight 表（如果存在）
DROP TABLE IF EXISTS patient_weight;

-- 创建新表 patient_weight
CREATE TABLE patient_weight AS

WITH htwt AS (
    SELECT
        patientunitstayid,
        hospitaladmitoffset AS chartoffset,
        admissionheight AS height,
        admissionweight AS weight,
        CASE
            -- 检查体重和身高是否互换
            WHEN admissionweight >= 100
                AND admissionheight >  25 AND admissionheight <= 100
                AND ABS(admissionheight - admissionweight) >= 20 THEN 'swap'
            END AS method
    FROM eicu_crd.patient
),
htwt_fixed AS (
    SELECT
        patientunitstayid,
        chartoffset,
        'admit' AS weight_type,
        CASE
            -- 如果体重和身高被互换，则进行交换
            WHEN method = 'swap' THEN weight
            WHEN height <= 0.30 THEN NULL  -- 过滤异常小的身高
            WHEN height <= 2.5 THEN height * 100  -- 将米转换为厘米
            WHEN height <= 10 THEN NULL  -- 过滤异常小的身高
            WHEN height <= 25 THEN height * 10  -- 将米转换为厘米
            -- 检查两列的值是否非常接近
            WHEN height <= 100 AND ABS(height - weight) < 20 THEN NULL
            WHEN height > 250 THEN NULL  -- 过滤异常大的身高
            ELSE height 
            END AS height_fixed,
        CASE
            -- 如果体重和身高被互换，则进行交换
            WHEN method = 'swap' THEN height
            WHEN weight <= 20 THEN NULL  -- 过滤异常小的体重
            WHEN weight > 300 THEN NULL  -- 过滤异常大的体重
            ELSE weight 
            END AS weight_fixed
    FROM htwt
)
-- 选择处理和纠正后的身高和体重数据
SELECT
    patientunitstayid,
    chartoffset,
    weight_type,
    height_fixed AS height,
    weight_fixed AS weight
FROM htwt_fixed
WHERE height_fixed IS NOT NULL AND weight_fixed IS NOT NULL
ORDER BY patientunitstayid, chartoffset;
