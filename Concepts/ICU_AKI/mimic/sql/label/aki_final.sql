-- aki_final.sql
-- 删除旧的结果表
DROP TABLE IF EXISTS aki_final;

-- 创建新的结果表
CREATE TABLE aki_final AS
WITH combined_aki AS (
    -- 使用 UNION 合并所有来源的 AKI 记录
    SELECT 
        subject_id,
        stay_id,
        'Cr' as aki_method,
        charttime as aki_timepoint
    FROM aki_cr
    WHERE aki_status IN ('AKI-Cr within 48hr', 'AKI-Cr within 7day')
    
    UNION
    
    SELECT 
        subject_id,
        stay_id,
        'UO' as aki_method,
        charttime as aki_timepoint
    FROM aki_uo
    WHERE aki_status = 'AKI-UO'
    
    UNION
    
    SELECT 
        subject_id,
        stay_id,
        'RRT' as aki_method,
        charttime as aki_timepoint
    FROM icu_crrt
    WHERE rrt_in_icu = TRUE
),
-- 选择每个患者最早的 AKI 发生时间
earliest_aki AS (
    SELECT 
        subject_id,
        MIN(aki_timepoint) as aki_timepoint
    FROM combined_aki
    GROUP BY subject_id
)
-- 最终输出
SELECT DISTINCT
    subject_id,
    aki_timepoint
FROM earliest_aki
ORDER BY subject_id;
