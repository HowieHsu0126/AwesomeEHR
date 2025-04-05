-- 删除已存在的最终结果表以避免重复
DROP TABLE IF EXISTS final_aki_status;

-- 创建最终AKI状态表，包含最早诊断时间以及各条件下的判断标志
CREATE TABLE final_aki_status AS
WITH uo_with_hadm AS (
    -- 为 aki_uo 添加 hadm_id
    SELECT
        uo.subject_id,
        uo.stay_id,
        ie.hadm_id,
        uo.aki_timepoint
    FROM aki_uo uo
    JOIN mimiciv_icu.icustays ie
        ON uo.stay_id = ie.stay_id
),
combined AS (
    SELECT
        COALESCE(cr.subject_id, uo.subject_id) AS subject_id,
        COALESCE(cr.hadm_id, uo.hadm_id) AS hadm_id,
        COALESCE(cr.stay_id, uo.stay_id) AS stay_id,
        cr.charttime AS cr_timepoint,
        uo.aki_timepoint AS uo_timepoint,
        -- 来自 aki_cr 表的判断
        CASE WHEN cr.aki_status != 'No AKI' THEN TRUE ELSE FALSE END AS aki_cr,
        -- 来自 aki_uo 表的判断
        CASE WHEN uo.aki_timepoint IS NOT NULL THEN TRUE ELSE FALSE END AS aki_uo
    FROM aki_cr cr
    FULL OUTER JOIN uo_with_hadm uo
        ON cr.subject_id = uo.subject_id
        AND cr.hadm_id = uo.hadm_id
        AND cr.stay_id = uo.stay_id
),
earliest_aki_record AS (
    SELECT
        subject_id,
        hadm_id,
        stay_id,
        cr_timepoint,
        uo_timepoint,
        aki_cr,
        aki_uo,
        ROW_NUMBER() OVER (
            PARTITION BY subject_id 
            ORDER BY LEAST(
                COALESCE(cr_timepoint, '9999-12-31'::timestamp),
                COALESCE(uo_timepoint, '9999-12-31'::timestamp)
            ) ASC
        ) AS row_num  -- 选择最早的 AKI 诊断记录
    FROM combined
    WHERE aki_cr = TRUE OR aki_uo = TRUE  -- 只选择有 AKI 的记录
)
SELECT
    subject_id,
    hadm_id,
    stay_id,
    CASE 
        WHEN MIN(LEAST(
            COALESCE(cr_timepoint, '9999-12-31'::timestamp),
            COALESCE(uo_timepoint, '9999-12-31'::timestamp)
        )) = '9999-12-31'::timestamp THEN NULL
        ELSE MIN(LEAST(
            COALESCE(cr_timepoint, '9999-12-31'::timestamp),
            COALESCE(uo_timepoint, '9999-12-31'::timestamp)
        ))
    END AS earliest_aki_diagnosis_time,
    -- 分别返回各条件下的判断标志
    bool_or(aki_cr) AS aki_cr,
    bool_or(aki_uo) AS aki_uo
FROM
    earliest_aki_record
WHERE
    row_num = 1  -- 选择每个患者的最早记录
GROUP BY
    subject_id,
    hadm_id,
    stay_id
ORDER BY
    subject_id;

-- 主要内容：综合肌酐值(cr)、尿量(uo)两个指标，
-- 确定患者的最终AKI状态，并记录最早的AKI诊断时间