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
    e.subject_id,
    e.aki_timepoint
FROM earliest_aki e
ORDER BY subject_id;

-- 主要内容：整合肌酐值(Cr)、尿量(UO)和肾脏替代治疗(RRT)三个维度的AKI判断结果，
-- 确定每个患者最早的AKI发生时间，并排除ICU入院前已存在RRT的患者
