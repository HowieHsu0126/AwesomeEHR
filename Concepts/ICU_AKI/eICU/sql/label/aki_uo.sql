-- 删除旧的 UO 结果表
DROP TABLE IF EXISTS aki_uo;

-- 创建一个视图，以识别尿量低于标准的 AKI 患者
CREATE TABLE aki_uo AS
WITH weight_data AS (
    -- 获取每个患者的平均体重
    SELECT
        p.patientunitstayid,
        p.uniquepid,
        p.unitdischargeoffset,
        AVG(w.weight) AS avg_weight
    FROM
        patient_weight w
    JOIN
        eicu_crd.patient p ON w.patientunitstayid = p.patientunitstayid
    GROUP BY
        p.patientunitstayid, p.uniquepid, p.unitdischargeoffset
), urine_output_stg1 AS (
    -- 计算相邻两次尿量测量之间的时间间隔
    -- 用于后续计算6小时窗口内的尿量输出率
    SELECT
        uo.patientunitstayid,
        uo.chartoffset,
        uo.urineoutput,
        wd.avg_weight,
        wd.unitdischargeoffset,
        -- 计算相邻两次测量之间的时间间隔（小时）
        NULLIF((uo.chartoffset - LAG(uo.chartoffset) 
            OVER (PARTITION BY uo.patientunitstayid ORDER BY uo.chartoffset)), 0) / 60.0 as hours_since_last_measurement
    FROM
        pivoted_uo uo
    INNER JOIN weight_data wd ON uo.patientunitstayid = wd.patientunitstayid
    WHERE 
        uo.chartoffset >= 0
        AND uo.chartoffset <= wd.unitdischargeoffset
), urine_output_stg2 AS (
    -- 计算6小时窗口内的尿量统计
    -- 使用滑动窗口计算6小时内的总尿量和总时间
    SELECT
        patientunitstayid,
        chartoffset,
        urineoutput,
        avg_weight,
        unitdischargeoffset,
        -- 计算6小时窗口内的总尿量（360分钟 = 6小时）
        SUM(urineoutput) OVER (
            PARTITION BY patientunitstayid 
            ORDER BY chartoffset 
            RANGE BETWEEN 360 PRECEDING AND CURRENT ROW
        ) AS urineoutput_6hr,
        -- 计算6小时窗口内的总时间
        SUM(hours_since_last_measurement) OVER (
            PARTITION BY patientunitstayid 
            ORDER BY chartoffset 
            RANGE BETWEEN 360 PRECEDING AND CURRENT ROW
        ) AS uo_tm_6hr
    FROM
        urine_output_stg1
), aki_criteria AS (
    -- 根据KDIGO标准判断AKI
    -- 当6小时窗口内尿量<0.5ml/kg/h时判定为AKI
    SELECT
        uo.patientunitstayid,
        uo.chartoffset,
        uo.unitdischargeoffset,
        uo.avg_weight,
        uo.urineoutput_6hr,
        uo.uo_tm_6hr,
        -- 计算6小时窗口内的尿量输出率（ml/kg/h）
        -- 只有当时间窗口>=6小时时才计算
        CASE 
            WHEN uo.uo_tm_6hr >= 6 THEN
                (uo.urineoutput_6hr / uo.avg_weight / uo.uo_tm_6hr)
            ELSE NULL
        END AS urine_output_ml_per_kg_per_hr,
        -- 根据KDIGO标准判断AKI状态
        CASE
            WHEN uo.uo_tm_6hr >= 6 
                AND (uo.urineoutput_6hr / uo.avg_weight / uo.uo_tm_6hr) < 0.5 
            THEN 'AKI'
            ELSE 'Non-AKI'
        END AS aki_status
    FROM
        urine_output_stg2 uo
), earliest_aki_record AS (
    -- 为每个患者选择最早的AKI记录
    -- 使用uniquepid作为患者唯一标识
    SELECT
        ac.patientunitstayid,
        p.uniquepid,
        ac.chartoffset,
        ac.urineoutput_6hr,
        ac.avg_weight,
        ac.urine_output_ml_per_kg_per_hr,
        ac.aki_status,
        ac.unitdischargeoffset,
        -- 按uniquepid分组，选择最早的记录
        ROW_NUMBER() OVER (PARTITION BY p.uniquepid ORDER BY ac.chartoffset ASC) AS row_num
    FROM
        aki_criteria ac
    JOIN
        eicu_crd.patient p ON ac.patientunitstayid = p.patientunitstayid
    WHERE
        ac.aki_status = 'AKI'
)

-- 最终结果：每个患者的最早AKI记录
SELECT
    uniquepid,
    patientunitstayid,
    chartoffset,
    urineoutput_6hr,
    avg_weight,
    urine_output_ml_per_kg_per_hr,
    aki_status
FROM
    earliest_aki_record
WHERE
    row_num = 1  -- 选择每个患者的第一条记录
    AND chartoffset >= 0  -- 确保在入ICU后
    AND chartoffset <= unitdischargeoffset  -- 确保在出ICU前
ORDER BY
    uniquepid;

-- 主要内容：基于尿量判断AKI，使用6小时窗口计算尿量输出率，
-- 当时间>=6小时且尿量<0.5ml/kg/h时判定为AKI
