-- 删除已存在的最终结果表以避免重复
DROP TABLE IF EXISTS final_aki_status;

-- 创建最终AKI状态表，包含最早诊断时间以及各条件下的判断标志
CREATE TABLE final_aki_status AS
WITH combined AS (
    SELECT
        COALESCE(ac.patientunitstayid, uo.patientunitstayid) AS patientunitstayid,
        p.uniquepid,  -- 通过 eicu_crd.patient 表获取 uniquepid 唯一标识患者
        ac.aki_diagnosis_time AS cr_offset,
        uo.chartoffset AS uo_offset,
        -- 来自 aki_cr 表的判断（48小时与7天各自独立判断）
        CASE WHEN ac.aki_diagnosis_48hrs = 1 THEN TRUE ELSE FALSE END AS aki_cr_48h,
        CASE WHEN ac.aki_diagnosis_7days = 1 THEN TRUE ELSE FALSE END AS aki_cr_7d,
        -- 来自 aki_uo 表的判断（所有患者均为AKI）
        TRUE AS aki_uo
    FROM aki_cr ac
    FULL OUTER JOIN aki_uo uo
         ON ac.patientunitstayid = uo.patientunitstayid
    JOIN eicu_crd.patient p ON COALESCE(ac.patientunitstayid, uo.patientunitstayid) = p.patientunitstayid  -- 连接 patient 表获取 uniquepid
    WHERE (ac.aki_diagnosis_48hrs = 1 
           OR ac.aki_diagnosis_7days = 1
           OR uo.patientunitstayid IS NOT NULL)  -- 修改为检查 uo 表中是否存在记录
),
earliest_aki_record AS (
    SELECT
        patientunitstayid,
        uniquepid,  -- 使用 uniquepid 唯一标识患者
        cr_offset,
        uo_offset,
        aki_cr_48h,
        aki_cr_7d,
        aki_uo,
        ROW_NUMBER() OVER (PARTITION BY uniquepid ORDER BY LEAST(
            COALESCE(cr_offset, 99999999),
            COALESCE(uo_offset, 99999999)
        ) ASC) AS row_num  -- 选择最早的 AKI 诊断记录
    FROM combined
    WHERE COALESCE(cr_offset, 99999999) >= 0
      AND COALESCE(uo_offset, 99999999) >= 0  -- 过滤掉诊断时间为负的样本
)
SELECT
    uniquepid,  -- 返回 uniquepid 作为患者唯一标识
    CASE 
       WHEN MIN(LEAST(
          COALESCE(cr_offset, 99999999),
          COALESCE(uo_offset, 99999999)
       )) = 99999999 THEN NULL
       ELSE MIN(LEAST(
          COALESCE(cr_offset, 99999999),
          COALESCE(uo_offset, 99999999)
       ))
    END AS earliest_aki_diagnosis_time,
    -- 分别返回各条件下的判断标志
    bool_or(aki_cr_48h) AS aki_cr_48h,
    bool_or(aki_cr_7d) AS aki_cr_7d,
    bool_or(aki_uo) AS aki_uo
FROM
    earliest_aki_record
WHERE
    row_num = 1  -- 选择每个患者的最早记录
GROUP BY
    uniquepid  -- 按患者唯一标识符分组
ORDER BY
    uniquepid;  -- 按照 uniquepid 排序

-- 主要内容：综合肌酐值(cr)、尿量(uo)两个指标，
-- 确定患者的最终AKI状态，并记录最早的AKI诊断时间
