-- 创建 DATETIME_SUB 函数，用于处理日期的减法
CREATE OR REPLACE FUNCTION DATETIME_SUB(datetime_val TIMESTAMP(3), intvl INTERVAL) 
RETURNS TIMESTAMP(3) AS $$
BEGIN
    RETURN datetime_val - intvl;
END; $$
LANGUAGE PLPGSQL;

-- 删除旧的结果表
DROP TABLE IF EXISTS aki_cr;

-- 创建新的结果表
CREATE TABLE aki_cr AS
WITH cr AS (
    -- 提取每个病人的肌酐检测数据，并计算其在 ICU 的肌酐值
    SELECT
        ie.subject_id,
        ie.hadm_id,
        ie.stay_id,
        le.charttime,
        le.valuenum AS creat,
        ie.intime,  -- 从icustays表获取入院时间
        ROW_NUMBER() OVER (PARTITION BY ie.subject_id, ie.hadm_id ORDER BY le.charttime) AS rn
    FROM mimiciv_icu.icustays ie
    LEFT JOIN mimiciv_hosp.labevents le
        ON ie.subject_id = le.subject_id
        AND le.itemid = 50912  -- 肌酐的itemid
        AND le.valuenum IS NOT NULL
        AND le.valuenum <= 150
        AND le.charttime >= ie.intime  -- 只提取ICU期间的肌酐数据
        AND le.charttime <= ie.outtime
),
cr_baseline AS (
    -- 获取每个病人在 ICU 入院后的前 7 天内的最低肌酐值作为基线肌酐值
    SELECT
        subject_id,  -- 添加 subject_id
        hadm_id,
        stay_id,
        creat AS baseline_creat,
        charttime AS baseline_time
    FROM (
        SELECT
            subject_id,  -- 添加 subject_id
            hadm_id,
            stay_id,
            creat,
            charttime,
            ROW_NUMBER() OVER (PARTITION BY hadm_id ORDER BY creat ASC) AS rn  -- 按照肌酐值升序排序
        FROM cr
        WHERE charttime >= intime  -- 基线时间窗口为 ICU 入院后的第一个 7 天
        AND charttime < intime + INTERVAL '7' DAY  -- 只考虑进入ICU后7天内的数据
    ) sub
    WHERE rn = 1  -- 选择最小肌酐值及其对应时间
),
aki_48hr AS (
    -- 获取每个病人在 48 小时内肌酐升高超过 0.3 时诊断为 AKI
    SELECT
        cr1.subject_id,  -- 添加 subject_id
        cr1.hadm_id,
        cr1.stay_id,
        cr1.charttime AS start_time,
        cr1.creat AS start_creat,
        cr2.charttime AS compare_time,
        cr2.creat AS compare_creat,
        (cr2.creat - cr1.creat) AS creat_diff,
        cr2.charttime AS aki_48hr_time
    FROM cr cr1
    JOIN cr cr2
        ON cr1.subject_id = cr2.subject_id
        AND cr1.hadm_id = cr2.hadm_id
        AND cr2.charttime > cr1.charttime  -- 确保比较的是晚于当前时间点的肌酐值
        AND cr2.charttime <= cr1.charttime + INTERVAL '48' HOUR  -- 在 48 小时内进行比较
    WHERE cr2.creat >= cr1.creat + 0.3  -- 肌酐值升高超过 0.3 时诊断为 AKI
),
aki_7day AS (
    -- 获取每个病人在 7 天内肌酐值升高超过基线的 1.5 倍的时间点
    SELECT
        cr1.subject_id,  -- 添加 subject_id
        cr1.hadm_id,
        cr1.stay_id,
        cr1.charttime AS start_time,
        cr1.creat AS start_creat,
        cr1.charttime AS compare_time,  -- 使用 cr1 的 charttime 进行比较
        cr1.creat AS compare_creat,    -- 使用 cr1 的 creat 进行比较
        (cr1.creat - rb.baseline_creat) AS creat_diff,
        cr1.charttime AS aki_7day_time
    FROM cr cr1
    JOIN cr_baseline rb
        ON cr1.hadm_id = rb.hadm_id  -- 引入基线数据进行对比
        AND cr1.stay_id = rb.stay_id
    WHERE cr1.creat >= 1.5 * rb.baseline_creat  -- 肌酐值超过基线的 1.5 倍时诊断为 AKI
        AND cr1.charttime > rb.baseline_time  -- 确保比较是在基线时间之后
        AND cr1.charttime <= rb.baseline_time + INTERVAL '7' DAY  -- 只在基线时间后的 7 天内比较
),
aki_diagnosis AS (
    -- 确定 AKI 诊断的时间，48 小时或 7 天内升高超过阈值时诊断为 AKI
    SELECT
        rb.subject_id,  -- 添加 subject_id
        rb.hadm_id,
        rb.stay_id,
        rb.baseline_time,
        rb.baseline_creat,
        aki_48.aki_48hr_time,
        aki_7.aki_7day_time,
        CASE
            WHEN aki_48.aki_48hr_time IS NOT NULL THEN 'AKI-Cr within 48hr'
            WHEN aki_7.aki_7day_time IS NOT NULL THEN 'AKI-Cr within 7day'
            ELSE 'No AKI'
        END AS aki_status,
        CASE
            WHEN aki_48.aki_48hr_time IS NOT NULL THEN aki_48.aki_48hr_time
            WHEN aki_7.aki_7day_time IS NOT NULL THEN aki_7.aki_7day_time
        END AS aki_timepoint
    FROM cr_baseline rb
    LEFT JOIN aki_48hr aki_48
        ON rb.hadm_id = aki_48.hadm_id
        AND rb.stay_id = aki_48.stay_id
    LEFT JOIN aki_7day aki_7
        ON rb.hadm_id = aki_7.hadm_id
        AND rb.stay_id = aki_7.stay_id
)

-- 修改最后的查询部分
SELECT
    hadm_id,
    stay_id,
    subject_id,
    baseline_time,
    baseline_creat,
    aki_timepoint AS charttime,
    aki_status
FROM (
    SELECT DISTINCT
        hadm_id,
        stay_id,    
        subject_id,
        baseline_time,
        baseline_creat,
        aki_timepoint,
        aki_status,
        ROW_NUMBER() OVER (
            PARTITION BY subject_id  -- 改为只按 subject_id 分组
            ORDER BY aki_timepoint   -- 按时间排序，获取最早的记录
        ) AS rn
    FROM aki_diagnosis
    WHERE aki_status != 'No AKI'    -- 只选择有 AKI 的记录
) sub
WHERE rn = 1  -- 只选取每个病人最早的 AKI 记录
ORDER BY subject_id;
