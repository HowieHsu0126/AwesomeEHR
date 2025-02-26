-- 创建 DATETIME_DIFF 函数，用于处理日期的差异
CREATE OR REPLACE FUNCTION DATETIME_DIFF(endtime timestamp(3), starttime timestamp(3), datepart text)
    RETURNS numeric
    AS $$
BEGIN
    RETURN EXTRACT(EPOCH FROM endtime - starttime) / CASE WHEN datepart = 'SECOND' THEN
        1.0
    WHEN datepart = 'MINUTE' THEN
        60.0
    WHEN datepart = 'HOUR' THEN
        3600.0
    WHEN datepart = 'DAY' THEN
        24 * 3600.0
    WHEN datepart = 'YEAR' THEN
        365.242 * 24 * 3600.0
    ELSE
        NULL
    END;
END;
$$
LANGUAGE PLPGSQL;

-- 删除旧的结果表
DROP TABLE IF EXISTS aki_uo;

-- 创建新的结果表
CREATE TABLE aki_uo AS
WITH uo_stg1 AS (
    SELECT
        ie.stay_id,
        uo.charttime,
        ie.subject_id,
        DATETIME_DIFF(charttime, intime, 'SECOND') AS seconds_since_admit,
        COALESCE(DATETIME_DIFF(charttime, LAG(charttime) OVER (PARTITION BY ie.stay_id ORDER BY charttime), 'SECOND') / 3600.0, 1) AS hours_since_previous_row,
        urineoutput
    FROM
        mimiciv_icu.icustays ie
        INNER JOIN mimiciv_derived.urine_output uo ON ie.stay_id = uo.stay_id
),
weight_avg AS (
    -- 计算每个患者的平均体重
    SELECT
        stay_id,
        AVG(weight) AS avg_weight
    FROM
        mimiciv_derived.weight_durations
    GROUP BY
        stay_id
),
uo_stg2 AS (
    SELECT
        stay_id,
        charttime,
        subject_id,
        hours_since_previous_row,
        urineoutput,
        SUM(urineoutput) OVER (PARTITION BY stay_id ORDER BY seconds_since_admit RANGE BETWEEN 21600 PRECEDING AND CURRENT ROW) AS urineoutput_6hr,
        SUM(hours_since_previous_row) OVER (PARTITION BY stay_id ORDER BY seconds_since_admit RANGE BETWEEN 21600 PRECEDING AND CURRENT ROW) AS uo_tm_6hr
    FROM
        uo_stg1
),
uo_aki AS (
    -- 基于 KDIGO 标准判断 AKI 状态
    SELECT
        ur.subject_id,
        ur.stay_id,
        ur.charttime,
        wa.avg_weight,
        ur.urineoutput_6hr,
        ur.uo_tm_6hr,
        ROUND(CAST((ur.urineoutput_6hr / wa.avg_weight / ur.uo_tm_6hr) AS numeric), 4) AS uo_rt_6hr,
        CASE WHEN ur.uo_tm_6hr >= 6
            AND (ur.urineoutput_6hr / wa.avg_weight / ur.uo_tm_6hr) < 0.5 THEN
            'AKI-UO'
        ELSE
            'No AKI'
        END AS aki_status,
        -- 记录 AKI 发生的最早时间点
        MIN(charttime) OVER (PARTITION BY ur.stay_id ORDER BY ur.charttime RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS aki_timepoint
    FROM
        uo_stg2 ur
        LEFT JOIN weight_avg wa ON ur.stay_id = wa.stay_id
    WHERE
        ur.uo_tm_6hr >= 6
        AND (ur.urineoutput_6hr / wa.avg_weight / ur.uo_tm_6hr) < 0.5
),
-- 选择每位患者的最早 AKI 判断
earliest_aki AS (
    SELECT
        subject_id,
        stay_id,
        aki_status,
        aki_timepoint,
        ROW_NUMBER() OVER (PARTITION BY subject_id ORDER BY aki_timepoint ASC) AS row_num
    FROM
        uo_aki
)
SELECT
    subject_id,
    stay_id,
    aki_status,
    aki_timepoint AS charttime
FROM
    earliest_aki
WHERE
    row_num = 1
ORDER BY subject_id;

-- 主要内容：基于KDIGO尿量标准判断AKI，
-- 计算6小时内的尿量输出率（ml/kg/h），当低于0.5时判定为AKI，
-- 记录每个患者最早的AKI发生时间
