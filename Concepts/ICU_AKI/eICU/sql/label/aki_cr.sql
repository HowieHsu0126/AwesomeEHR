-- 删除已有结果表
DROP TABLE IF EXISTS aki_cr;

-- 创建新的 AKI 结果表
CREATE TABLE aki_cr AS
WITH 
-- 1. 提取肌酐检测数据（按患者和时间排序）
creatinine_measurements AS (
    SELECT
        patientunitstayid,
        labresultoffset,
        labresult,
        ROW_NUMBER() OVER (PARTITION BY patientunitstayid ORDER BY labresultoffset ASC) AS rn
    FROM eicu_crd.lab
    WHERE labname = 'creatinine'
),
-- 2. 定义基线肌酐：ICU 入院后 7 天内最低的肌酐值
baseline_creatinine AS (
    SELECT
        patientunitstayid,
        MIN(labresult) AS baseline_creatinine,
        MIN(labresultoffset) AS baseline_creat_offset
    FROM creatinine_measurements
    WHERE labresultoffset BETWEEN 0 AND 10080  -- 7 天内（单位：分钟）
    GROUP BY patientunitstayid
),
-- 3. 基于 7 天标准：肌酐值达到基线的 1.5 倍（且必须在基线检测之后，且时间差不超过 7 天）
aki_criteria_7days AS (
    SELECT
        cm.patientunitstayid,
        cm.labresult,
        cm.labresultoffset,
        bc.baseline_creatinine,
        bc.baseline_creat_offset,
        CASE 
            WHEN cm.labresult >= 1.5 * bc.baseline_creatinine
                 AND cm.labresultoffset > bc.baseline_creat_offset
                 AND cm.labresultoffset <= bc.baseline_creat_offset + 10080  -- 7 天内
            THEN 1
            ELSE 0
        END AS is_aki_7days
    FROM creatinine_measurements cm
    JOIN baseline_creatinine bc 
         ON cm.patientunitstayid = bc.patientunitstayid
),
-- 4. 修改后的 48 小时标准：
--    对于每个检测点 cm1，寻找同一患者在 48 小时内（即 labresultoffset 在 cm1.labresultoffset 后 48 小时内）的后续检测 cm2，
--    如果 cm2 的肌酐值比 cm1 提高至少 0.3 mg/dL，则判定符合 48 小时 AKI 标准。
aki_criteria_48hrs AS (
    SELECT
        cm1.patientunitstayid,
        cm1.labresultoffset AS start_offset,
        cm1.labresult AS start_creatinine,
        cm2.labresultoffset AS compare_offset,
        cm2.labresult AS compare_creatinine,
        1 AS is_aki_48hrs
    FROM creatinine_measurements cm1
    JOIN creatinine_measurements cm2
         ON cm1.patientunitstayid = cm2.patientunitstayid
         AND cm2.labresultoffset > cm1.labresultoffset
         AND cm2.labresultoffset <= cm1.labresultoffset + 2880  -- 48 小时内（2880 分钟）
    WHERE cm2.labresult >= cm1.labresult + 0.3
),
-- 5. 对 7 天标准符合的记录，按患者取最早发生时间（labresultoffset 最小值）
aki_7days_agg AS (
    SELECT 
        patientunitstayid,
        MIN(labresultoffset) AS aki_7days_offset
    FROM aki_criteria_7days
    WHERE is_aki_7days = 1
    GROUP BY patientunitstayid
),
-- 6. 对 48 小时标准符合的记录，按患者取最早发生时间（使用 cm2 的 compare_offset，即确认时刻）
aki_48hrs_agg AS (
    SELECT 
        patientunitstayid,
        MIN(compare_offset) AS aki_48hrs_offset
    FROM aki_criteria_48hrs
    GROUP BY patientunitstayid
),
-- 7. 综合两种标准：取每个患者最早的 AKI 诊断时点
earliest_aki AS (
    SELECT
        COALESCE(a7.patientunitstayid, a48.patientunitstayid) AS patientunitstayid,
        a7.aki_7days_offset,
        a48.aki_48hrs_offset,
        CASE 
            WHEN a48.aki_48hrs_offset IS NOT NULL 
                 AND (a7.aki_7days_offset IS NULL OR a48.aki_48hrs_offset < a7.aki_7days_offset)
            THEN a48.aki_48hrs_offset
            ELSE a7.aki_7days_offset
        END AS earliest_offset,
        CASE 
            WHEN a7.patientunitstayid IS NOT NULL OR a48.patientunitstayid IS NOT NULL THEN 1
            ELSE 0
        END AS final_aki_diagnosis
    FROM aki_7days_agg a7
    FULL OUTER JOIN aki_48hrs_agg a48 
           ON a7.patientunitstayid = a48.patientunitstayid
)
-- 8. 输出最终被诊断为 AKI 的患者及其最早诊断时间（labresultoffset）
SELECT DISTINCT
    patientunitstayid,
    aki_7days_offset,
    aki_48hrs_offset,
    earliest_offset,
    final_aki_diagnosis
FROM earliest_aki
WHERE final_aki_diagnosis = 1
ORDER BY patientunitstayid;
