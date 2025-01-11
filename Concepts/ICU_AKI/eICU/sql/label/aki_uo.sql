-- 根据KDIGO标准，尿量少于0.5毫升/千克/小时持续6小时以上被认为是AKI。
-- 首先计算每个患者的平均体重，然后基于此计算每小时每公斤体重的尿量。之后，通过检查6小时内的最低尿量是否满足AKI的标准，来为每个患者分类AKI状态。最后，它将每个患者的尿量数据和AKI状态结合在一起进行输出。
DROP TABLE IF EXISTS aki_uo;
CREATE TABLE aki_uo AS
WITH weight_data AS (
    SELECT
        patientunitstayid,
        AVG(weight) as avg_weight  -- 假设体重在短时间内不会有大变化，取平均值
    FROM
        patient_weight
    GROUP BY patientunitstayid
), urine_output_per_hour AS (
    SELECT
        uo.patientunitstayid,
        uo.chartoffset,
        uo.urineoutput,
        wd.avg_weight,
        (uo.urineoutput / (6 * wd.avg_weight)) AS urine_output_ml_per_kg_per_hr  -- 计算每小时每公斤体重的尿量
    FROM
        pivoted_uo uo
    INNER JOIN weight_data wd ON uo.patientunitstayid = wd.patientunitstayid
), aki_status AS (
    SELECT
        uph.patientunitstayid,
        CASE
            WHEN MIN(uph.urine_output_ml_per_kg_per_hr) < 0.5 THEN 'AKI'  -- 如果连续6小时内的尿量小于0.5毫升/千克/小时
            ELSE 'Non-AKI'
        END AS aki_status
    FROM
        urine_output_per_hour uph
    GROUP BY uph.patientunitstayid
)

SELECT
    uph.patientunitstayid,
    uph.chartoffset,
    uph.urineoutput,
    uph.avg_weight,
    uph.urine_output_ml_per_kg_per_hr,
    ak.aki_status
FROM
    urine_output_per_hour uph
JOIN
    aki_status ak ON uph.patientunitstayid = ak.patientunitstayid
ORDER BY
    uph.patientunitstayid, uph.chartoffset;
