-- 删除旧的 RRT 结果表
DROP TABLE IF EXISTS icu_crrt;

-- 创建新的 RRT 结果表
CREATE TABLE icu_crrt AS
WITH crrt_stg AS (
    SELECT 
        ie.subject_id,  -- 使用 subject_id 而不是 stay_id
        crrt.stay_id,
        crrt.charttime,
        TRUE AS rrt_in_icu,
        ROW_NUMBER() OVER (PARTITION BY ie.subject_id ORDER BY crrt.charttime ASC) AS row_num  -- 按照charttime排序，确保每个患者只保留最早的记录
    FROM
        mimiciv_derived.crrt crrt
        JOIN mimiciv_icu.icustays ie ON crrt.stay_id = ie.stay_id
    WHERE
        crrt.crrt_mode IS NOT NULL
        AND crrt.charttime >= ie.intime  -- 只考虑 ICU 期间的 RRT 治疗
)
SELECT 
    subject_id,  -- 使用 subject_id
    stay_id,
    charttime,
    rrt_in_icu
FROM
    crrt_stg
WHERE
    row_num = 1;  -- 只选择每位患者最早的 RRT 判断
