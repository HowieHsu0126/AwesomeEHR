-- 删除旧的 RRT 结果表
DROP TABLE IF EXISTS icu_crrt;

CREATE TABLE icu_crrt AS
WITH crrt_stg AS (
    -- 获取所有 RRT 记录并标记是否为 ICU 前的 RRT
    SELECT 
        ie.subject_id,
        crrt.stay_id,
        crrt.charttime,
        CASE 
            WHEN crrt.charttime < ie.intime THEN TRUE 
            ELSE FALSE 
        END AS is_pre_icu_rrt,
        CASE 
            WHEN crrt.charttime >= ie.intime AND crrt.charttime <= ie.outtime THEN TRUE 
            ELSE FALSE 
        END AS is_icu_rrt,
        ROW_NUMBER() OVER (
            PARTITION BY ie.subject_id 
            ORDER BY crrt.charttime ASC
        ) AS row_num
    FROM
        mimiciv_derived.crrt crrt
        JOIN mimiciv_icu.icustays ie ON crrt.stay_id = ie.stay_id
    WHERE
        crrt.crrt_mode IS NOT NULL
),
-- 获取每个患者最早的 RRT 记录
first_rrt AS (
    SELECT 
        subject_id,
        stay_id,
        charttime,
        is_pre_icu_rrt,
        is_icu_rrt
    FROM crrt_stg
    WHERE row_num = 1
)
SELECT 
    subject_id,
    stay_id,
    charttime,
    is_pre_icu_rrt,
    is_icu_rrt
FROM first_rrt;

-- 主要内容：识别接受肾脏替代治疗(RRT)的患者，
-- 区分ICU入院前已存在RRT和ICU期间新发RRT，记录首次RRT时间
