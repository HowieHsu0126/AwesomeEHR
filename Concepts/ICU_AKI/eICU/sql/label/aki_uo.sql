-- 删除旧的 UO 结果表
DROP TABLE IF EXISTS aki_uo;

-- 创建一个视图，以识别尿量低于标准的 AKI 患者
CREATE TABLE aki_uo AS
WITH weight_data AS (
    SELECT
        p.patientunitstayid,
        p.uniquepid,  -- 通过 eicu_crd.patient 表获取 uniquepid 唯一标识患者
        AVG(w.weight) AS avg_weight  -- 假设体重在短时间内不会有大变化，取平均值
    FROM
        patient_weight w
    JOIN
        eicu_crd.patient p ON w.patientunitstayid = p.patientunitstayid  -- 连接 patient 表获取 uniquepid
    GROUP BY
        p.patientunitstayid, p.uniquepid
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
), aki_criteria AS (
    SELECT
        uph.patientunitstayid,
        uph.chartoffset,
        uph.urine_output_ml_per_kg_per_hr,
        CASE
            WHEN uph.urine_output_ml_per_kg_per_hr < 0.5 THEN 1  -- 如果尿量小于0.5毫升/千克/小时
            ELSE 0
        END AS is_aki
    FROM
        urine_output_per_hour uph
), consecutive_aki AS (
    SELECT
        patientunitstayid,
        chartoffset,
        is_aki,
        ROW_NUMBER() OVER (PARTITION BY patientunitstayid ORDER BY chartoffset) AS rn
    FROM
        aki_criteria
    WHERE
        is_aki = 1  -- 只考虑尿量低于标准的记录
), aki_status AS (
    SELECT
        patientunitstayid,
        CASE
            WHEN COUNT(*) >= 6 THEN 'AKI'  -- 连续6小时尿量低于0.5毫升/千克/小时，视为AKI
            ELSE 'Non-AKI'
        END AS aki_status
    FROM
        consecutive_aki
    GROUP BY
        patientunitstayid
), earliest_aki_record AS (
    SELECT
        uph.patientunitstayid,
        p.uniquepid,  -- 使用 uniquepid 唯一标识患者，确保连接 patient 表
        uph.chartoffset,
        uph.urineoutput,
        uph.avg_weight,
        uph.urine_output_ml_per_kg_per_hr,
        ak.aki_status,
        ROW_NUMBER() OVER (PARTITION BY uph.patientunitstayid ORDER BY uph.chartoffset ASC) AS row_num  -- 每个患者的最早记录
    FROM
        urine_output_per_hour uph
    JOIN
        aki_status ak ON uph.patientunitstayid = ak.patientunitstayid
    JOIN
        eicu_crd.patient p ON uph.patientunitstayid = p.patientunitstayid  -- 连接 patient 表获取 uniquepid
    WHERE
        ak.aki_status = 'AKI'  -- 只筛选出AKI患者
)

SELECT
    uniquepid,  -- 返回 uniquepid 作为患者唯一标识
    patientunitstayid,
    chartoffset,
    urineoutput,
    avg_weight,
    urine_output_ml_per_kg_per_hr,
    aki_status
FROM
    earliest_aki_record
WHERE
    row_num = 1  -- 选择每个患者的最早记录
    -- 过滤掉诊断时间为负的样本
    AND chartoffset >= 0
ORDER BY
    uniquepid;  -- 按照 uniquepid 排序

-- 主要内容：基于尿量判断AKI，标准为连续6小时尿量低于0.5ml/kg/h
